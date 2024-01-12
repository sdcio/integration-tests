/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"

	sdcpb "github.com/iptecharch/sdc-protos/sdcpb"
	"github.com/olekukonko/tablewriter"
	"github.com/spf13/cobra"
	"google.golang.org/protobuf/encoding/prototext"
)

// datastoreGetCmd represents the get command
var datastoreGetCmd = &cobra.Command{
	Use:          "get",
	Short:        "show datastore details",
	SilenceUsage: true,
	RunE: func(cmd *cobra.Command, _ []string) error {
		ctx, cancel := context.WithCancel(cmd.Context())
		defer cancel()
		dataClient, err := createDataClient(ctx, addr)
		if err != nil {
			return err
		}
		req := &sdcpb.GetDataStoreRequest{
			Name: datastoreName,
		}
		fmt.Println("request:")
		fmt.Println(prototext.Format(req))
		rsp, err := dataClient.GetDataStore(ctx, req)
		if err != nil {
			return err
		}
		fmt.Println("response:")
		fmt.Println(prototext.Format(rsp))
		printDataStoreTable(rsp)
		return nil
	},
}

func init() {
	datastoreCmd.AddCommand(datastoreGetCmd)
}

func printDataStoreTable(rsp *sdcpb.GetDataStoreResponse) {
	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"Name", "Schema", "Candidate(s)", "SBI", "Address"})
	table.SetAlignment(tablewriter.ALIGN_LEFT)
	table.SetAutoFormatHeaders(false)
	table.SetAutoWrapText(false)
	table.AppendBulk(toTableData(rsp))
	table.Render()
}

func toTableData(rsp *sdcpb.GetDataStoreResponse) [][]string {
	candidates := make([]string, 0, len(rsp.GetDatastore()))
	for _, ds := range rsp.GetDatastore() {
		if ds.GetType() == sdcpb.Type_MAIN {
			continue
		}
		candidateName := "- " + ds.GetName()
		if ds.Owner != "" {
			candidateName += "/" + ds.Owner
		}
		if ds.Priority != 0 {
			candidateName += "/" + strconv.Itoa(int(ds.Priority))
		}
		candidates = append(candidates, candidateName)
	}
	return [][]string{
		{
			rsp.GetName(),
			fmt.Sprintf("%s/%s/%s", rsp.GetSchema().GetName(), rsp.GetSchema().GetVendor(), rsp.GetSchema().GetVersion()),
			strings.Join(candidates, "\n"),
			rsp.GetTarget().GetType(),
			rsp.GetTarget().GetAddress(),
		},
	}
}
