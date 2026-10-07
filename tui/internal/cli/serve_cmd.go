package cli

import (
	"fmt"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/serve"
	"github.com/spf13/cobra"
)

func newServeCmd() *cobra.Command {
	var addr, hostKey string
	cmd := &cobra.Command{
		Use:   "serve",
		Short: "Run Enfo over SSH, so anyone can ssh in to a Pomodoro",
		Long: `Starts an SSH server (Charm Wish) where every connection runs its own Enfo, with
its own settings, timers and history, remembered by the user's public key (any
key is accepted; clients without one are refused). Desktop notifications and
sounds are off for these sessions — they would ring on the server — but the
terminal bell works.

There is no further authentication: put it behind a firewall or a VPN, or bind
it to localhost and tunnel.`,
		Example: `  enfo serve --addr 127.0.0.1:2222
  ssh -p 2222 localhost
  ssh -t -p 2222 me@myserver`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			st, err := openStore()
			if err != nil {
				return err
			}
			fmt.Fprintln(cmd.ErrOrStderr(), lipgloss.NewStyle().Bold(true).Render("◔ enfo over ssh")+"  "+addr)
			return serve.Run(cmd.Context(), serve.Options{Addr: addr, HostKey: hostKey, StateDir: st.StateDir})
		},
	}
	cmd.Flags().StringVar(&addr, "addr", ":2222", "address to listen on")
	cmd.Flags().StringVar(&hostKey, "host-key", "", "SSH host key file (created if missing; default <state>/ssh/host_ed25519)")
	return cmd
}
