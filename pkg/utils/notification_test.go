package utils

import (
	"reflect"
	"testing"

	sdcpb "github.com/iptecharch/sdc-protos/sdcpb"
	"github.com/openconfig/gnmi/proto/gnmi"
)

func TestFromGNMIPath(t *testing.T) {
	type args struct {
		pre *gnmi.Path
		p   *gnmi.Path
	}
	tests := []struct {
		name string
		args args
		want *sdcpb.Path
	}{
		{
			name: "simple",
			args: args{
				// pre: &gnmi.Path{},
				p: &gnmi.Path{
					Elem: []*gnmi.PathElem{
						{Name: "foo"},
					},
				},
			},
			want: &sdcpb.Path{
				Elem: []*sdcpb.PathElem{
					{Name: "foo"},
				},
			},
		},
		{
			name: "two pe",
			args: args{
				// pre: &gnmi.Path{},
				p: &gnmi.Path{
					Elem: []*gnmi.PathElem{
						{Name: "foo"},
						{Name: "bar"},
					},
				},
			},
			want: &sdcpb.Path{
				Elem: []*sdcpb.PathElem{
					{Name: "foo"},
					{Name: "bar"},
				},
			},
		},
		{
			name: "two pe - key",
			args: args{
				// pre: &gnmi.Path{},
				p: &gnmi.Path{
					Elem: []*gnmi.PathElem{
						{Name: "foo", Key: map[string]string{"k": "v"}},
						{Name: "bar"},
					},
				},
			},
			want: &sdcpb.Path{
				Elem: []*sdcpb.PathElem{
					{Name: "foo", Key: map[string]string{"k": "v"}},
					{Name: "bar"},
				},
			},
		},
		{
			name: "two pe - 2 keys",
			args: args{
				// pre: &gnmi.Path{},
				p: &gnmi.Path{
					Elem: []*gnmi.PathElem{
						{Name: "foo", Key: map[string]string{"k1": "v1", "k2": "v2"}},
						{Name: "bar"},
					},
				},
			},
			want: &sdcpb.Path{
				Elem: []*sdcpb.PathElem{
					{Name: "foo", Key: map[string]string{"k1": "v1", "k2": "v2"}},
					{Name: "bar"},
				},
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := FromGNMIPath(tt.args.pre, tt.args.p); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("FromGNMIPath() = %v, want %v", got, tt.want)
			}
		})
	}
}
