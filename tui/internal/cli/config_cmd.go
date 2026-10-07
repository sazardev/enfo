package cli

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"charm.land/huh/v2"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/spf13/cobra"
)

func newConfigCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Show, locate, edit or reset the configuration",
		Long: `Enfo keeps its settings in one JSON file (config.json), the live state of the
timers in state.json and the history in history.jsonl. Most settings are easier
to change inside Enfo (press ,), but the file can be edited by hand: unknown or
out-of-range values are repaired when it is read.`,
		Example: `  enfo config path
  enfo config show
  enfo config edit
  enfo config reset --yes`,
	}
	cmd.AddCommand(
		&cobra.Command{
			Use: "path", Short: "Print where Enfo keeps its files", Args: cobra.NoArgs,
			RunE: func(cmd *cobra.Command, args []string) error {
				st, err := openStore()
				if err != nil {
					return err
				}
				w := cmd.OutOrStdout()
				fmt.Fprintf(w, "config   %s\nstate    %s\nhistory  %s\nlog      %s\n", st.ConfigPath(), st.StatePath(), st.HistoryPath(), st.LogPath())
				return nil
			},
		},
		&cobra.Command{
			Use: "show", Short: "Print the effective configuration (defaults filled in)", Args: cobra.NoArgs,
			RunE: func(cmd *cobra.Command, args []string) error {
				st, err := openStore()
				if err != nil {
					return err
				}
				c, found := st.LoadConfig()
				b, _ := json.MarshalIndent(c, "", "  ")
				if !found {
					fmt.Fprintf(cmd.ErrOrStderr(), "# no config file yet (%s): showing the defaults\n", st.ConfigPath())
				}
				fmt.Fprintln(cmd.OutOrStdout(), string(b))
				return nil
			},
		},
		&cobra.Command{
			Use: "edit", Short: "Open the config file in $VISUAL / $EDITOR", Args: cobra.NoArgs,
			RunE: func(cmd *cobra.Command, args []string) error { return editConfig() },
		},
		newConfigReset(),
	)
	return cmd
}

func editor() []string {
	for _, k := range []string{"VISUAL", "EDITOR"} {
		if e := strings.Fields(os.Getenv(k)); len(e) > 0 {
			return e
		}
	}
	for _, e := range []string{"nano", "vim", "vi"} {
		if p, err := exec.LookPath(e); err == nil {
			return []string{p}
		}
	}
	return nil
}

func editConfig() error {
	st, err := openStore()
	if err != nil {
		return err
	}
	if _, err := os.Stat(st.ConfigPath()); errors.Is(err, os.ErrNotExist) {
		c, _ := st.LoadConfig() // defaults
		if err := st.SaveConfig(c); err != nil {
			return err
		}
	}
	ed := editor()
	if ed == nil {
		return fmt.Errorf("no editor found: set $EDITOR (config file: %s)", st.ConfigPath())
	}
	c := exec.Command(ed[0], append(ed[1:], st.ConfigPath())...)
	c.Stdin, c.Stdout, c.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := c.Run(); err != nil {
		return fmt.Errorf("editor: %w", err)
	}
	// make sure what was written still parses
	b, err := os.ReadFile(st.ConfigPath())
	if err == nil {
		var probe store.Config
		if json.Unmarshal(b, &probe) != nil {
			return fmt.Errorf("%s is not valid JSON any more — Enfo will ignore it and use the defaults until you fix it", st.ConfigPath())
		}
	}
	return nil
}

func newConfigReset() *cobra.Command {
	var yes, all bool
	cmd := &cobra.Command{
		Use:   "reset",
		Short: "Delete the configuration (and with --all the timers and the history)",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			st, err := openStore()
			if err != nil {
				return err
			}
			what := "Reset the settings to their defaults?"
			if all {
				what = "Erase settings, running timers, alarms AND the whole history?"
			}
			if !yes {
				ok := false
				if err := huh.NewConfirm().Title(what).Affirmative("Yes, reset").Negative("No").Value(&ok).Run(); err != nil {
					return err
				}
				if !ok {
					fmt.Fprintln(cmd.OutOrStdout(), "nothing changed")
					return nil
				}
			}
			if all {
				st.Reset()
			} else if err := os.Remove(st.ConfigPath()); err != nil && !errors.Is(err, os.ErrNotExist) {
				return err
			}
			fmt.Fprintln(cmd.OutOrStdout(), "done")
			return nil
		},
	}
	cmd.Flags().BoolVarP(&yes, "yes", "y", false, "do not ask")
	cmd.Flags().BoolVar(&all, "all", false, "also erase state.json and the history")
	return cmd
}
