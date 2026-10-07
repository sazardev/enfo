// Package cli is Enfo's command line: the TUI launcher and its shortcuts plus
// the commands that never open it (status, stats, config, doctor ...).
package cli

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"charm.land/fang/v2"
	"github.com/spf13/cobra"
)

// Build info, set by the main package (ldflags).
var (
	Version = "dev"
	Commit  = ""
)

type rootFlags struct {
	configDir, stateDir string
	mode                string
	noSplash            bool
	accent, lang        string
}

// Execute builds the command tree and runs it with Fang (styled help and
// errors, --version, man page and shell completions).
func Execute(version, commit string) error {
	Version, Commit = version, commit
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	return fang.Execute(ctx, NewRoot(),
		fang.WithVersion(version),
		fang.WithCommit(commit),
		fang.WithNotifySignal(os.Interrupt, syscall.SIGTERM),
	)
}

// NewRoot builds the `enfo` command.
func NewRoot() *cobra.Command {
	rf := &rootFlags{}
	root := &cobra.Command{
		Use:   "enfo",
		Short: "Focus, in the terminal — Pomodoro, clock, timer, stopwatch, alarms, world clock and breathing",
		Long: `Enfo is a clock and timer toolbox for the terminal, drawn with braille dots:
a Pomodoro with animated dials, a clock, a timer, a stopwatch, alarms, a world
clock with a live day/night map and a breathing guide.

Running ` + "`enfo`" + ` opens the full-screen interface. Every timer stores absolute
times, so it keeps exact time while you are in another mode — and even after
you quit: a tiny background waker (` + "`enfo wake`" + `) still raises the desktop
notification when your Pomodoro phase, timer or alarm is due.

The other commands never open the interface: they are for scripts, status bars
and quick checks.`,
		Example: `  enfo                      open Enfo on your start mode
  enfo timer 10m --start    open the timer and start 10 minutes
  enfo pomodoro --start     start a focus session right away
  enfo alarm add 07:30 --days weekdays -q
  enfo status               one line for your prompt or status bar
  enfo stats                your focus dashboard
  enfo doctor               check the terminal and the desktop integration`,
		Args:          cobra.NoArgs,
		SilenceUsage:  true,
		SilenceErrors: true,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			if rf.configDir != "" {
				os.Setenv("ENFO_CONFIG_DIR", rf.configDir)
			}
			if rf.stateDir != "" {
				os.Setenv("ENFO_STATE_DIR", rf.stateDir)
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			return launch(rf.opts(rf.mode))
		},
	}
	pf := root.PersistentFlags()
	pf.StringVar(&rf.configDir, "config-dir", "", "configuration directory (default $XDG_CONFIG_HOME/enfo; env ENFO_CONFIG_DIR)")
	pf.StringVar(&rf.stateDir, "state-dir", "", "state and history directory (default $XDG_STATE_HOME/enfo; env ENFO_STATE_DIR)")
	pf.BoolVar(&rf.noSplash, "no-splash", false, "skip the opening animation")
	pf.StringVar(&rf.accent, "accent", "", "accent color: a name (lime, sky, rose ...) or #rrggbb; saved in the config")
	pf.StringVar(&rf.lang, "lang", "", "interface language: auto, en or es; saved in the config")
	root.Flags().StringVarP(&rf.mode, "mode", "m", "", "open this mode: pomodoro, clock, timer, stopwatch, alarm, world, breathe")

	root.AddCommand(
		newPomodoroCmd(rf), newClockCmd(rf), newTimerCmd(rf), newStopwatchCmd(rf),
		newAlarmCmd(rf), newWorldCmd(rf), newBreatheCmd(rf),
		newStatusCmd(), newStatsCmd(), newConfigCmd(), newDoctorCmd(),
		newWakeCmd(), newServeCmd(), newVersionCmd(),
	)
	return root
}

func (rf *rootFlags) opts(mode string) launchOpts {
	return launchOpts{mode: mode, noSplash: rf.noSplash, accent: rf.accent, lang: rf.lang}
}

func newVersionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print the version and build information",
		Args:  cobra.NoArgs,
		Run: func(cmd *cobra.Command, args []string) {
			c := Commit
			if c == "" {
				c = "unknown"
			}
			fmt.Fprintf(cmd.OutOrStdout(), "enfo %s (commit %s)\n", Version, c)
		},
	}
}
