package cli

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"charm.land/lipgloss/v2"
	"charm.land/lipgloss/v2/table"
	"charm.land/lipgloss/v2/tree"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/spf13/cobra"
)

// StatsJSON is the machine-readable form of `enfo stats`.
type StatsJSON struct {
	Days         int       `json:"days"`
	TodayMin     int       `json:"todayMin"`
	WeekMin      int       `json:"weekMin"`
	TotalMin     int       `json:"totalMin"`
	Sessions     int       `json:"sessions"`
	Abandoned    int       `json:"abandoned"`
	Completion   float64   `json:"completion"`
	Streak       int       `json:"streak"`
	AvgMin       int       `json:"avgMinPerActiveDay"`
	BestDay      string    `json:"bestDay,omitempty"`
	BestDayMin   int       `json:"bestDayMin"`
	TimerRuns    int       `json:"timerRuns"`
	StopwatchMin int       `json:"stopwatchMin"`
	PerDay       []DayJSON `json:"perDay"`
}

// DayJSON is one day of focus.
type DayJSON struct {
	Date     string `json:"date"`
	FocusMin int    `json:"focusMin"`
	Sessions int    `json:"sessions"`
}

func statsJSON(sum engine.Summary, days int) StatsJSON {
	j := StatsJSON{
		Days: days, TodayMin: int(sum.Today.Focus.Minutes()), WeekMin: int(sum.Week.Minutes()),
		TotalMin: int(sum.Total.Minutes()), Sessions: sum.Sessions, Abandoned: sum.Abandoned,
		Streak: sum.Streak, AvgMin: int(sum.AvgPerDay.Minutes()), BestDayMin: int(sum.BestDay.Focus.Minutes()),
		TimerRuns: sum.TimerRuns, StopwatchMin: int(sum.Stopwatch.Minutes()),
	}
	if t := sum.Sessions + sum.Abandoned; t > 0 {
		j.Completion = float64(sum.Sessions) / float64(t)
	}
	if !sum.BestDay.Day.IsZero() {
		j.BestDay = sum.BestDay.Day.Format("2006-01-02")
	}
	for _, d := range sum.Days {
		j.PerDay = append(j.PerDay, DayJSON{d.Day.Format("2006-01-02"), int(d.Focus.Minutes()), d.Sessions})
	}
	return j
}

func newStatsCmd() *cobra.Command {
	var days int
	var asJSON bool
	cmd := &cobra.Command{
		Use:   "stats",
		Short: "Print your focus statistics as a styled dashboard",
		Long: `Prints today, the week, your streak, completed sessions, a braille bar chart of the
last days, a calendar heat map of the last 16 weeks and where your time went.
Non-interactive: for the interactive version press g inside Enfo.`,
		Example: `  enfo stats
  enfo stats --days 30
  enfo stats --json | jq .streak`,
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			if days < 7 || days > 365 {
				return fmt.Errorf("--days must be between 7 and 365")
			}
			st, err := openStore()
			if err != nil {
				return err
			}
			now := time.Now()
			events := st.Events()
			sum := engine.Summarize(events, now, days)
			if asJSON {
				b, _ := json.MarshalIndent(statsJSON(sum, days), "", "  ")
				fmt.Fprintln(cmd.OutOrStdout(), string(b))
				return nil
			}
			cfg, _ := st.LoadConfig()
			i18n.Set(cfg.Lang)
			w := termWidth()
			lipgloss.Fprintln(cmd.OutOrStdout(), renderStats(st, events, now, days, w))
			return nil
		},
	}
	cmd.Flags().IntVarP(&days, "days", "d", 14, "days in the chart and totals (7-365)")
	cmd.Flags().BoolVar(&asJSON, "json", false, "machine-readable JSON")
	return cmd
}

func rgbStr(c braille.RGB) string { return c.Hex() }

func humanMin(d time.Duration) string {
	m := int(d.Round(time.Minute) / time.Minute)
	if m >= 60 {
		if m%60 == 0 {
			return fmt.Sprintf("%dh", m/60)
		}
		return fmt.Sprintf("%dh %02dm", m/60, m%60)
	}
	return fmt.Sprintf("%dm", m)
}

// barChart draws the per-day focus as braille columns (2 cells per day).
func barChart(sum engine.Summary, pal theme.Palette, width int) []string {
	n := len(sum.Days)
	perDay := 2
	for n*perDay > width-2 && perDay > 1 {
		perDay--
	}
	days := sum.Days
	if n*perDay > width-2 { // still too wide: show the most recent
		n = (width - 2) / perDay
		days = days[len(days)-n:]
	}
	rows := 4
	c := braille.New(n*perDay, rows)
	var mx time.Duration
	for _, d := range days {
		if d.Focus > mx {
			mx = d.Focus
		}
	}
	grad := braille.Gradient{pal.Accent.Darken(0.35), pal.Accent, pal.Bright}
	for i, d := range days {
		x0 := i * perDay * 2
		bw := perDay*2 - 1
		if bw < 1 {
			bw = 1
		}
		h := 1 // a quiet day keeps a baseline dot
		col := pal.Faint
		if mx > 0 && d.Focus > 0 {
			h = int(float64(d.Focus)/float64(mx)*float64(c.H-1) + 1.5)
			col = grad.At(float64(d.Focus) / float64(mx))
		}
		if d.Day.Weekday() == time.Saturday || d.Day.Weekday() == time.Sunday {
			col = col.Mix(pal.Rest, 0.25)
		}
		c.Rect(x0, c.H-h, bw, h, braille.Solid(col))
	}
	lines := c.Lines()
	// weekday initials under each day
	var lab strings.Builder
	initials := []string{"S", "M", "T", "W", "T", "F", "S"}
	if i18n.Lang() == "es" {
		initials = []string{"D", "L", "M", "X", "J", "V", "S"}
	}
	for _, d := range days {
		s := initials[d.Day.Weekday()]
		col := pal.Muted
		if d.Day.Equal(sum.Today.Day) {
			col = pal.Accent
		}
		lab.WriteString("\x1b[38;2;" + fmt.Sprint(col.R) + ";" + fmt.Sprint(col.G) + ";" + fmt.Sprint(col.B) + "m" + s + strings.Repeat(" ", perDay-1) + "\x1b[39m")
	}
	return append(lines, lab.String())
}

// heatmap draws the last `weeks` weeks as a calendar (rows = weekdays).
func heatmap(events []engine.Event, now time.Time, weeks int, pal theme.Palette) []string {
	sum := engine.Summarize(events, now, weeks*7+7)
	// align the last column to the current week (Monday first)
	today := sum.Days[len(sum.Days)-1].Day
	offset := (int(today.Weekday()) + 6) % 7 // 0 = Monday
	byDay := map[time.Time]engine.DayStat{}
	for _, d := range sum.Days {
		byDay[d.Day] = d
	}
	shade := []braille.RGB{pal.Faint.Mix(pal.Bg, 0.3), pal.Accent.Darken(0.55), pal.Accent.Darken(0.25), pal.Accent, pal.Bright.Lighten(0.2)}
	names := []string{"M", " ", "W", " ", "F", " ", "S"}
	if i18n.Lang() == "es" {
		names = []string{"L", " ", "M", " ", "V", " ", "D"}
	}
	var lines []string
	for r := 0; r < 7; r++ {
		var sb strings.Builder
		sb.WriteString(paintHex(pal.Muted, names[r]) + " ")
		for w := weeks - 1; w >= 0; w-- {
			day := today.AddDate(0, 0, -(offset-r)-7*w)
			if day.After(today) {
				sb.WriteString("  ")
				continue
			}
			d, ok := byDay[day]
			lvl := 0
			if ok {
				lvl = d.Level()
			}
			glyph := "⣿"
			if lvl == 0 {
				glyph = "⠶"
			}
			sb.WriteString(paintHex(shade[lvl], glyph) + " ")
		}
		lines = append(lines, sb.String())
	}
	return lines
}

func paintHex(c braille.RGB, s string) string {
	return fmt.Sprintf("\x1b[38;2;%d;%d;%dm%s\x1b[39m", c.R, c.G, c.B, s)
}

func renderStats(st *store.Store, events []engine.Event, now time.Time, days, width int) string {
	cfg, _ := st.LoadConfig()
	pal := theme.New(theme.Resolve(cfg.Accent), braille.Hex("16141a"), true)
	sum := engine.Summarize(events, now, days)
	if width > 100 {
		width = 100
	}
	if width < 40 {
		width = 40
	}
	accent := lipgloss.NewStyle().Foreground(pal.Accent).Bold(true)
	muted := lipgloss.NewStyle().Foreground(pal.Muted)
	title := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)

	var out []string
	out = append(out, accent.Render("◔ enfo")+muted.Render("  ·  "+i18n.T("mode.stats")+" · "+fmt.Sprintf("%d days", days)))
	out = append(out, "")

	// cards
	completion := "–"
	if t := sum.Sessions + sum.Abandoned; t > 0 {
		completion = fmt.Sprintf("%d%%", int(float64(sum.Sessions)/float64(t)*100+0.5))
	}
	streak := fmt.Sprintf("%d", sum.Streak)
	cards := table.New().
		Border(lipgloss.RoundedBorder()).
		BorderStyle(lipgloss.NewStyle().Foreground(pal.Faint)).
		Headers(strings.ToUpper(i18n.T("pomo.today")), "7 "+strings.ToUpper(i18n.T("pomo.streak.d", 0)[2:]), strings.ToUpper(i18n.T("pomo.streak")), strings.ToUpper(strings.TrimSpace(i18n.T("pomo.sessions", 0)[2:])), "✓").
		Row(humanMin(sum.Today.Focus), humanMin(sum.Week), streak, fmt.Sprint(sum.Sessions), completion).
		StyleFunc(func(row, col int) lipgloss.Style {
			s := lipgloss.NewStyle().Padding(0, 2).Align(lipgloss.Center)
			if row == table.HeaderRow {
				return s.Foreground(pal.Muted).Bold(true)
			}
			return s.Foreground(pal.Text).Bold(true)
		})
	out = append(out, cards.String(), "")

	// chart
	out = append(out, title.Render(strings.ToUpper(i18n.T("pomo.last", days)))+muted.Render("  "+humanMin(sum.Total)))
	for _, l := range barChart(sum, pal, width) {
		out = append(out, l)
	}
	out = append(out, "")

	// heatmap
	weeks := 16
	if width < 60 {
		weeks = 8
	}
	out = append(out, title.Render(strings.ToUpper(fmt.Sprintf("%d weeks", weeks))))
	out = append(out, heatmap(events, now, weeks, pal)...)
	out = append(out, "")

	// where the time went
	names := map[engine.Kind]string{
		engine.KindFocus: "focus", engine.KindRest: "rest", engine.KindLong: "long rest",
		engine.KindTimer: "timer", engine.KindStopwatch: "stopwatch", engine.KindAlarm: "alarms", engine.KindBreathe: "breathe",
	}
	root := tree.Root(title.Render(strings.ToUpper("time")))
	any := false
	for _, k := range []engine.Kind{engine.KindFocus, engine.KindRest, engine.KindLong, engine.KindTimer, engine.KindStopwatch, engine.KindBreathe} {
		if d := sum.ByKind[k]; d > 0 {
			any = true
			root.Child(" " + lipgloss.NewStyle().Foreground(pal.Text).Render(fmt.Sprintf("%-10s", names[k])) + muted.Render(humanMin(d)))
		}
	}
	if !any {
		root.Child(muted.Render("nothing yet — press space in the Pomodoro"))
	}
	root.EnumeratorStyle(lipgloss.NewStyle().Foreground(pal.Faint))
	out = append(out, root.String())
	if sum.BestDay.Focus > 0 {
		out = append(out, "", muted.Render(fmt.Sprintf("best day %s · %s   avg %s on active days",
			sum.BestDay.Day.Format("Mon 2 Jan"), humanMin(sum.BestDay.Focus), humanMin(sum.AvgPerDay))))
	}
	return strings.Join(out, "\n")
}
