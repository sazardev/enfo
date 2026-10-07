package cli

import (
	"fmt"
	"time"

	"github.com/sazardev/enfo/tui/internal/wake"
	"github.com/spf13/cobra"
)

func newWakeCmd() *cobra.Command {
	var at int64
	var title, body, sound string
	var repeat int
	var urgent bool
	cmd := &cobra.Command{
		Use:    "wake",
		Short:  "Background waker: notify at an instant, then exit (used internally)",
		Hidden: true,
		Long: `Sleeps until the given Unix time and then raises a desktop notification and
plays a sound. Enfo starts these detached when you quit with a Pomodoro phase,
timer or alarm still pending, and stops them again the next time it opens.`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			if at <= 0 {
				return fmt.Errorf("--at <unix seconds> is required")
			}
			wake.Run(cmd.Context(), wake.Job{At: time.Unix(at, 0), Title: title, Body: body, Sound: sound, Repeat: repeat, Urgent: urgent})
			return nil
		},
	}
	f := cmd.Flags()
	f.Int64Var(&at, "at", 0, "Unix time (seconds) to fire at")
	f.StringVar(&title, "title", "Enfo", "notification title")
	f.StringVar(&body, "body", "", "notification body")
	f.StringVar(&sound, "sound", "", "freedesktop sound name (complete, alarm-clock-elapsed ...)")
	f.IntVar(&repeat, "repeat", 1, "times to play the sound")
	f.BoolVar(&urgent, "urgent", false, "critical urgency")
	return cmd
}
