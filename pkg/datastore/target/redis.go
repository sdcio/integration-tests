package target

import (
	"context"

	sdcpb "github.com/iptecharch/sdc-protos/sdcpb"
	log "github.com/sirupsen/logrus"

	"github.com/iptecharch/data-server/pkg/config"
)

type redisTarget struct{}

func newRedisTarget(ctx context.Context, cfg *config.SBI) (*redisTarget, error) {
	return &redisTarget{}, nil
}

func (t *redisTarget) Get(ctx context.Context, req *sdcpb.GetDataRequest) (*sdcpb.GetDataResponse, error) {
	return nil, nil
}
func (t *redisTarget) Set(ctx context.Context, req *sdcpb.SetDataRequest) (*sdcpb.SetDataResponse, error) {
	return nil, nil
}
func (t *redisTarget) Subscribe() {}
func (t *redisTarget) Sync(ctx context.Context, syncConfig *config.Sync, syncCh chan *SyncUpdate) {
	<-ctx.Done()
	log.Infof("sync stopped: %v", ctx.Err())
}

func (t *redisTarget) Close() {}
