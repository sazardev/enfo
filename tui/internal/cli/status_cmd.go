package cli

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/spf13/cobra"
)

func newStatusCmd() *cobra.Command {
	var asJSON, waybar, polybar, tmux, watch bool
	var format string
	cmd := &cobra.Command{
		Use:   "status",
		Short: "Print what Enfo is running right now (for prompts and status bars)",
		Long: `Prints the state of Enfo without opening the interface. The remaining time is
computed from the absolute timestamps in the state file at the moment you ask, so
it is exact even if Enfo has been closed for hours. A phase that already ended
says so ("✓ focus done").

The headline is the most relevant thing: the Pomodoro, else the timer, else the
stopwatch, else the next alarm (if it is within 12 hours), else "idle".

Formats: plain text (default), --json (everything), --waybar (a JSON object for a
Waybar custom module), --polybar and --tmux (text with color codes), --format
(a Go template over the JSON fields, e.g. '{{.Icon}} {{.Remaining}}s'), and
--watch (refreshes every second in the terminal).`,
		Example: `  enfo status
  enfo status --json | jq .remainingSec
  enfo status --format '{{.State}} {{.Progress}}'

  # Waybar (~/.config/waybar/config.jsonc), e.g. on Omarchy:
  #   "custom/enfo": {
  #     "exec": "enfo status --waybar",
  #     "return-type": "json",
  #     "interval": 1,
  #     "on-click": "xdg-terminal-exec enfo",
  #     "format": "{}"
  #   }
  # and in style.css:  #custom-enfo.focus { color: #cddc39; }  #custom-enfo.idle { opacity: .4; }

  # tmux (~/.tmux.conf):
  #   set -g status-interval 1
  #   set -g status-right '#(enfo status --tmux) %H:%M'

  # polybar:
  #   [module/enfo]
  #   type = custom/script
  #   exec = enfo status --polybar
  #   interval = 1`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			n := 0
			for _, b := range []bool{asJSON, waybar, polybar, tmux, format != "", watch} {
				if b {
					n++
				}
			}
			if n > 1 {
				return fmt.Errorf("choose one of --json, --waybar, --polybar, --tmux, --format, --watch")
			}
			st, err := openStore()
			if err != nil {
				return err
			}
			out := cmd.OutOrStdout()
			one := func() error {
				s := BuildSnapshot(st, time.Now())
				return printSnapshot(out, s, asJSON, waybar, polybar, tmux, format)
			}
			if !watch {
				return one()
			}
			return watchStatus(cmd.Context(), out, func() Snapshot { return BuildSnapshot(st, time.Now()) })
		},
	}
	f := cmd.Flags()
	f.BoolVar(&asJSON, "json", false, "machine-readable JSON")
	f.BoolVar(&waybar, "waybar", false, "JSON for a Waybar custom module (text, tooltip, class, percentage)")
	f.BoolVar(&polybar, "polybar", false, "text with a Polybar color tag")
	f.BoolVar(&tmux, "tmux", false, "text with a tmux color style")
	f.StringVar(&format, "format", "", "a Go template over the fields of --json")
	f.BoolVar(&watch, "watch", false, "refresh every second until interrupted")
	return cmd
}

func printSnapshot(out io.Writer, s Snapshot, asJSON, waybar, polybar, tmux bool, format string) error {
	switch {
	case asJSON:
		j, err := s.JSON()
		if err != nil {
			return err
		}
		fmt.Fprintln(out, j)
	case waybar:
		b, err := json.Marshal(s.Waybar())
		if err != nil {
			return err
		}
		fmt.Fprintln(out, string(b))
	case polybar:
		fmt.Fprintln(out, s.Polybar())
	case tmux:
		fmt.Fprintln(out, s.Tmux())
	case format != "":
		r, err := s.Render(format)
		if err != nil {
			return fmt.Errorf("--format: %w", err)
		}
		fmt.Fprintln(out, r)
	default:
		fmt.Fprintln(out, s.Text)
	}
	return nil
}

func hexColor(h string) braille.RGB { return braille.Hex(h) }

// styledStatus is the --watch rendering: a headline, a braille progress bar
// and the details.
func styledStatus(s Snapshot, width int) string {
	col := hexColor(s.Color)
	head := lipgloss.NewStyle().Bold(true).Foreground(col).Render(s.Text)
	muted := lipgloss.NewStyle().Foreground(braille.Hex("8b8b96"))
	bar := ""
	if s.Total > 0 || s.State == "finished" {
		w := width - 4
		if w > 60 {
			w = 60
		}
		if w < 10 {
			w = 10
		}
		fill := int(s.Progress*float64(w) + 0.5)
		on := lipgloss.NewStyle().Foreground(col)
		off := lipgloss.NewStyle().Foreground(braille.Hex("3a3a44"))
		for i := 0; i < w; i++ {
			if i < fill {
				bar += on.Render("⣿")
			} else {
				bar += off.Render("⣀")
			}
		}
		bar += muted.Render(fmt.Sprintf("  %d%%", int(s.Progress*100+0.5)))
	}
	out := head + "\n"
	if bar != "" {
		out += bar + "\n"
	}
	out += "\n" + muted.Render(s.Tooltip) + "\n"
	return out
}

func watchStatus(ctx context.Context, out io.Writer, get func() Snapshot) error {
	if ctx == nil {
		ctx = context.Background()
	}
	t := time.NewTicker(time.Second)
	defer t.Stop()
	w := termWidth()
	for {
		s := get()
		fmt.Fprint(out, "\x1b[H\x1b[2J")
		lipgloss.Fprint(out, styledStatus(s, w))
		select {
		case <-ctx.Done():
			return nil
		case <-t.C:
		}
	}
}

func termWidth() int {
	if w := termSize(); w > 0 {
		return w
	}
	if os.Getenv("COLUMNS") != "" {
		var n int
		fmt.Sscan(os.Getenv("COLUMNS"), &n)
		if n > 0 {
			return n
		}
	}
	return 80
}
