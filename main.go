// routerOs/main.go
package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// Define usage, help, and description
const (
    rootCmdUse        = "routerOs"
    rootCmdShort      = "RouterOS CLI Tool"
    rootCmdLong       = `RouterOS CLI Tool is a command-line utility for managing RouterOS devices.`
    rootCmdExample    = "routerOs [command] [flags]"
    rootCmdDescription = `RouterOS CLI Tool is a powerful command-line utility that provides various commands to interact with RouterOS devices. It includes subcommands like debugger and sdk to help you manage your RouterOS devices efficiently.`
)
func main() {
    
    rootCmd := &cobra.Command{
        Use:     rootCmdUse,
        Short:   rootCmdShort,
        Long:    rootCmdLong,
        Example: rootCmdExample,
        Run: func(cmd *cobra.Command, args []string) {
            // This is the main command (routerOs) logic.
            cmd.Help()
        },
    }

    // Add subcommands
    // rootCmd.AddCommand(routerOsDebugger.Command())
    // Add other subcommands as needed

    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}