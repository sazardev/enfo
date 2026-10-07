package cli

import (
	"fmt"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/ui"
	"github.com/spf13/cobra"
)

func modeCmd(rf *rootFlags, id, short, long, example string) *cobra.Command {
	return &cobra.Command{
		Use:     id,
		Short:   short,
		Long:    long,
		Example: example,
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return launch(rf.opts(id))
		},
	}
}

func newClockCmd(rf *rootFlags) *cobra.Command {
	return modeCmd(rf, "clock", "Open the clock (analog, digital, orbit, binary, sun)",
		"Opens Enfo on the Clock mode even if you switched it off in Settings.", "  enfo clock")
}

func newWorldCmd(rf *rootFlags) *cobra.Command {
	return modeCmd(rf, "world", "Open the world clock with the day/night map",
		"Opens Enfo on the World clock: a braille map with the live day/night terminator and your cities.", "  enfo world")
}

func newBreatheCmd(rf *rootFlags) *cobra.Command {
	return modeCmd(rf, "breathe", "Open the breathing guide (box, 4-7-8, coherent, calm)",
		"Opens Enfo on the Breathe mode, a guided breathing orb.", "  enfo breathe")
}

func newPomodoroCmd(rf *rootFlags) *cobra.Command {
	var work, rest, long, cycles int
	var auto, start bool
	cmd := &cobra.Command{
		Use:   "pomodoro",
		Short: "Open the Pomodoro, optionally with another rhythm and started",
		Long: `Opens Enfo on the Pomodoro. The rhythm flags change the saved rhythm (minutes);
a phase already in progress keeps its length. With --start the current phase
begins at once (or resumes if it was paused).`,
		Example: `  enfo pomodoro
  enfo pomodoro --work 50 --rest 10 --start
  enfo pomodoro --work 90 --rest 20 --long 30 --cycles 3`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			f := cmd.Flags()
			lo := rf.opts("pomodoro")
			lo.setup = append(lo.setup, func(c *ui.Core) {
				changed := false
				for _, e := range []struct {
					name string
					dst  *int
					v    int
				}{{"work", &c.Cfg.Work, work}, {"rest", &c.Cfg.Rest, rest}, {"long", &c.Cfg.Long, long}, {"cycles", &c.Cfg.Cycles, cycles}} {
					if f.Changed(e.name) {
						*e.dst, changed = e.v, true
					}
				}
				if f.Changed("auto") {
					c.Cfg.AutoNext, changed = auto, true
				}
				if changed {
					c.ApplyConfig()
				}
				if start {
					now := time.Now()
					if c.Pomo.Run != engine.Running {
						c.Pomo.Start(now)
						c.MarkDirty()
					}
				}
			})
			return launch(lo)
		},
	}
	f := cmd.Flags()
	f.IntVarP(&work, "work", "w", 25, "focus length in minutes")
	f.IntVarP(&rest, "rest", "r", 5, "rest length in minutes")
	f.IntVarP(&long, "long", "l", 15, "long rest length in minutes")
	f.IntVarP(&cycles, "cycles", "c", 4, "focus sessions before a long rest (0 = never)")
	f.BoolVar(&auto, "auto", false, "start the next phase by itself")
	f.BoolVarP(&start, "start", "s", false, "start (or resume) the phase now")
	return cmd
}

func newTimerCmd(rf *rootFlags) *cobra.Command {
	var start bool
	var label string
	cmd := &cobra.Command{
		Use:   "timer [duration]",
		Short: "Open the timer, optionally set to a duration and started",
		Long: `Opens Enfo on the Timer. A duration sets the countdown (only if no timer is
running; a running one is replaced when you also pass --start). Durations accept
Go syntax (90s, 25m, 1h30m), the shorthand 1h30, m:ss / h:mm:ss, or a bare
number of minutes (5 = five minutes, 1.5 = ninety seconds).`,
		Example: `  enfo timer                  open the timer
  enfo timer 10m --start      ten minutes, running
  enfo timer 1h30 --label "deep work" --start
  enfo timer 90s -s`,
		Args: cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			var d time.Duration
			if len(args) == 1 {
				var err error
				if d, err = ParseDuration(args[0]); err != nil {
					return err
				}
			}
			lo := rf.opts("timer")
			lo.setup = append(lo.setup, func(c *ui.Core) {
				now := time.Now()
				if d > 0 {
					if c.Timer.Run != engine.Idle && start {
						c.Log(c.Timer.Reset(now)...)
					}
					c.Timer.Set(d, label)
				} else if label != "" && c.Timer.Run == engine.Idle {
					c.Timer.Set(c.Timer.Total, label)
				}
				if start && c.Timer.Run != engine.Running {
					c.Timer.Begin(now)
				}
				c.MarkDirty()
			})
			return launch(lo)
		},
	}
	cmd.Flags().BoolVarP(&start, "start", "s", false, "start the countdown now")
	cmd.Flags().StringVar(&label, "label", "", "a name for this timer (shown when it rings)")
	return cmd
}

func newStopwatchCmd(rf *rootFlags) *cobra.Command {
	var start bool
	cmd := &cobra.Command{
		Use:     "stopwatch",
		Short:   "Open the stopwatch, optionally started",
		Long:    "Opens Enfo on the Stopwatch. With --start it begins counting (a stopwatch that is already running is left alone).",
		Example: "  enfo stopwatch --start",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			lo := rf.opts("stopwatch")
			lo.setup = append(lo.setup, func(c *ui.Core) {
				if start && c.SW.Run != engine.Running {
					c.SW.Toggle(time.Now())
					c.MarkDirty()
				}
			})
			return launch(lo)
		},
	}
	cmd.Flags().BoolVarP(&start, "start", "s", false, "start counting now")
	return cmd
}

// ---------------------------------------------------------------------- alarm

func newAlarmCmd(rf *rootFlags) *cobra.Command {
	cmd := modeCmd(rf, "alarm", "Open the alarms; `alarm add` and `alarm list` work without it",
		"Opens Enfo on the Alarm mode.", "  enfo alarm\n  enfo alarm add 07:30 --days weekdays --label \"stand-up\"\n  enfo alarm list")
	cmd.AddCommand(newAlarmAdd(rf), newAlarmList())
	return cmd
}

func newAlarmAdd(rf *rootFlags) *cobra.Command {
	var days, label string
	var quiet bool
	cmd := &cobra.Command{
		Use:   "add <time>",
		Short: "Add an alarm (and open Enfo, or just save it with -q)",
		Long: `Adds an alarm at a time of day (07:30, 7:30pm, 19). Without --days it rings once,
at the next occurrence. --days takes mon,tue,... or ranges (mon-fri), or
weekdays / weekend / daily; Spanish day names work too.

With -q/--quiet the alarm is saved without opening the interface; start Enfo
(or keep it open) so it can ring — when Enfo is closed a background waker
raises the notification for alarms due in the next 24 hours.`,
		Example: `  enfo alarm add 07:30
  enfo alarm add 6:45am --days mon-fri --label "gym"
  enfo alarm add 22:00 --days daily -q`,
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			h, m, err := ParseClock(args[0])
			if err != nil {
				return err
			}
			d, err := ParseDays(days)
			if err != nil {
				return err
			}
			a := engine.Alarm{Hour: h, Min: m, Days: d, Label: label, Enabled: true}
			if quiet {
				st, err := openStore()
				if err != nil {
					return err
				}
				prev := st.LoadState().WakerPIDs
				c := ui.NewCore(st, time.Now())
				na := c.Alarms.Add(a, time.Now())
				c.Save()
				handOver(c, prev)
				fmt.Fprintf(cmd.OutOrStdout(), "⏰ %02d:%02d %s%s — next ring %s\n", h, m, DaysLabel(d), labelSuffix(label), na.NextAt.Format("Mon 2 Jan 15:04"))
				return nil
			}
			lo := rf.opts("alarm")
			lo.setup = append(lo.setup, func(c *ui.Core) {
				c.Alarms.Add(a, time.Now())
				c.MarkDirty()
			})
			return launch(lo)
		},
	}
	cmd.Flags().StringVar(&days, "days", "", "weekdays: mon,wed | mon-fri | weekdays | weekend | daily (default: once)")
	cmd.Flags().StringVar(&label, "label", "", "a name for the alarm")
	cmd.Flags().BoolVarP(&quiet, "quiet", "q", false, "save the alarm without opening the interface")
	return cmd
}

func labelSuffix(l string) string {
	if l == "" {
		return ""
	}
	return " “" + l + "”"
}

func newAlarmList() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List the alarms",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			st, err := openStore()
			if err != nil {
				return err
			}
			s := st.LoadState()
			if len(s.Alarms.List) == 0 {
				fmt.Fprintln(cmd.OutOrStdout(), "no alarms (enfo alarm add 07:30)")
				return nil
			}
			var sb strings.Builder
			for _, a := range s.Alarms.List {
				on := "on "
				if !a.Enabled {
					on = "off"
				}
				next := ""
				if a.Enabled && !a.NextAt.IsZero() {
					next = "  next " + a.NextAt.Format("Mon 2 Jan 15:04")
				}
				fmt.Fprintf(&sb, "%s  %02d:%02d  %-9s%s%s\n", on, a.Hour, a.Min, DaysLabel(a.Days), labelSuffix(a.Label), next)
			}
			fmt.Fprint(cmd.OutOrStdout(), sb.String())
			return nil
		},
	}
}
