package server

import (
	"context"
	"time"

	sdcpb "github.com/iptecharch/sdc-protos/sdcpb"
	log "github.com/sirupsen/logrus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/iptecharch/data-server/pkg/config"
	"github.com/iptecharch/data-server/pkg/datastore"
)

// datastore
func (s *Server) ListDataStore(ctx context.Context, req *sdcpb.ListDataStoreRequest) (*sdcpb.ListDataStoreResponse, error) {
	log.Debug("Received ListDataStoreRequest")

	s.md.RLock()
	defer s.md.RUnlock()
	numDs := len(s.datastores)
	rs := make([]*sdcpb.GetDataStoreResponse, 0, numDs)
	for _, ds := range s.datastores {
		r, err := s.datastoreToRsp(ctx, ds)
		if err != nil {
			return nil, err
		}
		rs = append(rs, r)
	}
	return &sdcpb.ListDataStoreResponse{
		Datastores: rs,
	}, nil
}

func (s *Server) GetDataStore(ctx context.Context, req *sdcpb.GetDataStoreRequest) (*sdcpb.GetDataStoreResponse, error) {
	log.Debugf("Received GetDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing datastore name attribute")
	}
	s.md.RLock()
	defer s.md.RUnlock()
	ds, ok := s.datastores[name]
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
	}
	return s.datastoreToRsp(ctx, ds)
}

func (s *Server) CreateDataStore(ctx context.Context, req *sdcpb.CreateDataStoreRequest) (*sdcpb.CreateDataStoreResponse, error) {
	log.Debugf("Received CreateDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing datastore name attribute")
	}
	switch {
	// create candidate
	case req.GetSchema() == nil && req.GetDatastore() != nil:
		s.md.RLock()
		defer s.md.RUnlock()
		ds, ok := s.datastores[name]
		if !ok {
			return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
		}
		switch req.GetDatastore().GetType() {
		case sdcpb.Type_CANDIDATE:
			err := ds.CreateCandidate(ctx, req.GetDatastore())
			if err != nil {
				return nil, status.Errorf(codes.Internal, "%v", err)
			}
			return &sdcpb.CreateDataStoreResponse{}, nil
		default:
			return nil, status.Errorf(codes.InvalidArgument, "schema required for MAIN datastore creation")
		}
		// create main
	case req.GetSchema() != nil:
		s.md.Lock()
		defer s.md.Unlock()
		if _, ok := s.datastores[name]; ok {
			return nil, status.Errorf(codes.InvalidArgument, "datastore %s already exists", name)
		}
		sbi := &config.SBI{
			Type:                   req.GetTarget().GetType(),
			Address:                req.GetTarget().GetAddress(),
			IncludeNS:              req.GetTarget().GetIncludeNs(),
			OperationWithNamespace: req.GetTarget().GetOperationWithNs(),
			UseOperationRemove:     req.GetTarget().GetUseOperationRemove(),
		}
		if req.GetTarget().GetTls() != nil {
			sbi.TLS = &config.TLS{
				CA:         req.GetTarget().GetTls().GetCa(),
				Cert:       req.GetTarget().GetTls().GetCert(),
				Key:        req.GetTarget().GetTls().GetKey(),
				SkipVerify: req.GetTarget().GetTls().GetSkipVerify(),
			}
		}
		if req.GetTarget().GetCredentials() != nil {
			sbi.Credentials = &config.Creds{
				Username: req.GetTarget().GetCredentials().GetUsername(),
				Password: req.GetTarget().GetCredentials().GetPassword(),
				Token:    req.GetTarget().GetCredentials().GetToken(),
			}
		}
		dsConfig := &config.DatastoreConfig{
			Name: name,
			Schema: &config.SchemaConfig{
				Name:    req.GetSchema().GetName(),
				Vendor:  req.GetSchema().GetVendor(),
				Version: req.GetSchema().GetVersion(),
			},
			SBI: sbi,
		}
		if req.GetSync() != nil {
			dsConfig.Sync = &config.Sync{
				Validate:     req.GetSync().GetValidate(),
				Buffer:       req.GetSync().GetBuffer(),
				WriteWorkers: req.GetSync().GetWriteWorkers(),
				Config:       make([]*config.SyncProtocol, 0, len(req.GetSync().GetConfig())),
			}
			for _, pSync := range req.GetSync().GetConfig() {
				gnSyncConfig := &config.SyncProtocol{
					Protocol: pSync.GetProtocol(),
					Name:     pSync.GetName(),
					Paths:    pSync.GetPath(),
					Interval: time.Duration(pSync.GetInterval()),
				}
				switch pSync.Protocol {
				case "gnmi":
					gnSyncConfig.Mode = "on-change"
					switch pSync.GetMode() {
					case sdcpb.SyncMode_SM_ON_CHANGE:
					case sdcpb.SyncMode_SM_SAMPLE:
						gnSyncConfig.Mode = "sample"
					case sdcpb.SyncMode_SM_ONCE:
						gnSyncConfig.Mode = "once"
					}
					gnSyncConfig.Encoding = pSync.GetEncoding()
				case "netconf":
				default:
					return nil, status.Errorf(codes.InvalidArgument, "unknown sync protocol: %q", pSync.Protocol)
				}
				dsConfig.Sync.Config = append(dsConfig.Sync.Config, gnSyncConfig)
			}
		}
		err := dsConfig.ValidateSetDefaults()
		if err != nil {
			return nil, status.Errorf(codes.InvalidArgument, "invalid datastore config: %v", err)
		}
		s.datastores[req.GetName()] = datastore.New(
			s.ctx,
			dsConfig,
			s.schemaClient,
			s.cacheClient,
			s.gnmiOpts...)
		return &sdcpb.CreateDataStoreResponse{}, nil
	default:
		return nil, status.Errorf(codes.InvalidArgument, "schema or datastore must be set")
	}
}

func (s *Server) DeleteDataStore(ctx context.Context, req *sdcpb.DeleteDataStoreRequest) (*sdcpb.DeleteDataStoreResponse, error) {
	log.Debugf("Received DeleteDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing datastore name attribute")
	}
	s.md.Lock()
	defer s.md.Unlock()
	ds, ok := s.datastores[name]
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
	}

	switch {
	case req.GetDatastore() == nil:
		err := ds.Stop()
		if err != nil {
			log.Errorf("failed to stop datastore %s: %v", name, err)
		}
		delete(s.datastores, name)
		log.Infof("deleted main %s", name)
		return &sdcpb.DeleteDataStoreResponse{}, nil
	default:
		switch req.GetDatastore().GetType() {
		case *sdcpb.Type_CANDIDATE.Enum():
			ds.DeleteCandidate(ctx, req.GetDatastore().GetName())
			log.Infof("datastore %s deleted candidate %s", name, req.GetDatastore().GetName())
		case *sdcpb.Type_MAIN.Enum():
			err := ds.Stop()
			if err != nil {
				log.Errorf("failed to stop datastore %s: %v", name, err)
			}
			delete(s.datastores, name)
			log.Infof("deleted main %s", name)
		}
		return &sdcpb.DeleteDataStoreResponse{}, nil
	}
}

func (s *Server) Commit(ctx context.Context, req *sdcpb.CommitRequest) (*sdcpb.CommitResponse, error) {
	log.Debugf("Received CommitDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing datastore name attribute")
	}
	s.md.RLock()
	defer s.md.RUnlock()
	ds, ok := s.datastores[name]
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
	}
	err := ds.Commit(ctx, req)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &sdcpb.CommitResponse{}, nil
}

func (s *Server) Rebase(ctx context.Context, req *sdcpb.RebaseRequest) (*sdcpb.RebaseResponse, error) {
	log.Debugf("Received RebaseDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing name attribute")
	}
	s.md.RLock()
	defer s.md.RUnlock()
	ds, ok := s.datastores[name]
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
	}
	err := ds.Rebase(ctx, req)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &sdcpb.RebaseResponse{}, nil
}

func (s *Server) Discard(ctx context.Context, req *sdcpb.DiscardRequest) (*sdcpb.DiscardResponse, error) {
	log.Debugf("Received DiscardDataStoreRequest: %v", req)
	name := req.GetName()
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "missing name attribute")
	}
	s.md.RLock()
	defer s.md.RUnlock()
	ds, ok := s.datastores[name]
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "unknown datastore %s", name)
	}
	err := ds.Discard(ctx, req)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "%v", err)
	}
	return &sdcpb.DiscardResponse{}, nil
}

//

func (s *Server) datastoreToRsp(ctx context.Context, ds *datastore.Datastore) (*sdcpb.GetDataStoreResponse, error) {
	cands, err := ds.Candidates(ctx)
	if err != nil {
		return nil, err
	}
	rsp := &sdcpb.GetDataStoreResponse{
		Name:      ds.Config().Name,
		Datastore: make([]*sdcpb.DataStore, 0, len(cands)+1),
	}
	rsp.Datastore = append(rsp.Datastore,
		&sdcpb.DataStore{
			Type: *sdcpb.Type_MAIN.Enum().Enum(),
			Name: ds.Config().Name,
		},
	)
	rsp.Datastore = append(rsp.Datastore, cands...)
	rsp.Target = &sdcpb.Target{
		Type:    ds.Config().SBI.Type,
		Address: ds.Config().SBI.Address,
		// Tls: &sdcpb.TLS{
		// 	Ca:         ds.Config().SBI.TLS.CA,
		// 	Cert:       ds.Config().SBI.TLS.Cert,
		// 	Key:        ds.Config().SBI.TLS.Key,
		// 	SkipVerify: ds.Config().SBI.TLS.SkipVerify,
		// },
		// Credentials: &sdcpb.Credentials{},
	}
	rsp.Schema = &sdcpb.Schema{
		Name:    ds.Config().Schema.Name,
		Vendor:  ds.Config().Schema.Vendor,
		Version: ds.Config().Schema.Version,
	}
	// for _, cand := range cands {
	// 	rsp.Datastore = append(rsp.Datastore,
	// 		&sdcpb.DataStore{
	// 			Type: *sdcpb.Type_CANDIDATE.Enum(),
	// 			Name: cand,
	// 		},
	// 	)
	// }
	return rsp, nil
}
