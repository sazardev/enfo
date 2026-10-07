package cli

import (
	"encoding/json"
	"fmt"
	"strings"
	"text/template"
	"time"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/theme"
)

// Item is one running thing (a Pomodoro phase, a timer, the stopwatch, an alarm).
type Item struct {
	Mode         string     `json:"mode"`            // pomodoro, timer, stopwatch, alarm
	Phase        string     `json:"phase,omitempty"` // focus, rest, long
	State        string     `json:"state"`           // running, paused, finished, armed
	Label        string     `json:"label,omitempty"`
	Icon         string     `json:"icon"`
	Text         string     `json:"text"` // "24:13"
	RemainingSec int        `json:"remainingSec"`
	TotalSec     int        `json:"totalSec,omitempty"`
	ElapsedSec   int        `json:"elapsedSec,omitempty"`
	Progress     float64    `json:"progress"`
	EndsAt       *time.Time `json:"endsAt,omitempty"`
}

// Snapshot is what `enfo status` knows, computed from the absolute timestamps
// in state.json at the moment it is asked.
type Snapshot struct {
	Now       time.Time  `json:"now"`
	Mode      string     `json:"mode"` // the most relevant mode, or "idle"
	Phase     string     `json:"phase,omitempty"`
	State     string     `json:"state"` // running, paused, finished, armed, idle
	Class     string     `json:"class"` // for Waybar / styling
	Icon      string     `json:"icon"`
	Text      string     `json:"text"` // the one-liner, e.g. "● focus 24:13"
	Tooltip   string     `json:"tooltip"`
	Remaining int        `json:"remainingSec"`
	Total     int        `json:"totalSec,omitempty"`
	Progress  float64    `json:"progress"`
	EndsAt    *time.Time `json:"endsAt,omitempty"`
	Items     []Item     `json:"items"`
	NextAlarm *AlarmInfo `json:"nextAlarm,omitempty"`
	Today     TodayInfo  `json:"today"`
	Color     string     `json:"color"` // hex of the mode's color (accent or rest)
}

// AlarmInfo is the next alarm to ring.
type AlarmInfo struct {
	ID    int       `json:"id"`
	Label string    `json:"label,omitempty"`
	At    time.Time `json:"at"`
	InSec int       `json:"inSec"`
	Time  string    `json:"time"`
}

// TodayInfo summarises today's focus.
type TodayInfo struct {
	FocusMin int `json:"focusMin"`
	Sessions int `json:"sessions"`
	Streak   int `json:"streak"`
}

func clock(sec int) string {
	if sec < 0 {
		sec = 0
	}
	h, m, s := sec/3600, sec%3600/60, sec%60
	if h > 0 {
		return fmt.Sprintf("%d:%02d:%02d", h, m, s)
	}
	return fmt.Sprintf("%02d:%02d", m, s)
}

func ceilSec(d time.Duration) int {
	if d < 0 {
		return 0
	}
	return int((d + time.Second - 1) / time.Second)
}

func phaseName(p engine.Phase) string { return strings.ToLower(i18n.T("phase." + string(p))) }

func ago(d time.Duration) string {
	d = d.Round(time.Second)
	switch {
	case d < time.Minute:
		return fmt.Sprintf("%ds", int(d/time.Second))
	case d < time.Hour:
		return fmt.Sprintf("%dm", int(d/time.Minute))
	}
	return fmt.Sprintf("%dh%02dm", int(d/time.Hour), int(d%time.Hour/time.Minute))
}

// BuildSnapshot computes the status from a loaded store at instant now. It
// never mutates anything on disk.
func BuildSnapshot(st *store.Store, now time.Time) Snapshot {
	cfg, _ := st.LoadConfig()
	i18n.Set(cfg.Lang)
	state := st.LoadState()
	pal := theme.New(theme.Resolve(cfg.Accent), braille.Hex("16141a"), true)

	s := Snapshot{Now: now, Mode: "idle", State: "idle", Class: "idle", Icon: "○", Items: []Item{}, Color: pal.Accent.Hex()}

	// Pomodoro
	if p := state.Pomodoro; p != nil && p.Run != engine.Idle {
		it := Item{Mode: "pomodoro", Phase: string(p.Phase), Progress: p.Progress(now), TotalSec: int(p.Total / time.Second)}
		name := phaseName(p.Phase)
		switch {
		case p.Run == engine.Running && !now.Before(p.EndsAt):
			it.State, it.Icon = "finished", "✓"
			it.RemainingSec, it.Progress = 0, 1
			it.Text = name + " " + i18n.T("state.done")
			it.Text = strings.ToLower(it.Text)
			e := p.EndsAt
			it.EndsAt = &e
			it.Label = fmt.Sprintf("ended %s ago", ago(now.Sub(p.EndsAt)))
		case p.Run == engine.Paused:
			it.State, it.Icon = "paused", "⏸"
			it.RemainingSec = ceilSec(p.Left)
			it.Text = fmt.Sprintf("%s %s", name, clock(it.RemainingSec))
		default:
			it.State, it.Icon = "running", "●"
			it.RemainingSec = ceilSec(p.Remaining(now))
			it.Text = fmt.Sprintf("%s %s", name, clock(it.RemainingSec))
			e := p.EndsAt
			it.EndsAt = &e
		}
		it.ElapsedSec = it.TotalSec - it.RemainingSec
		s.Items = append(s.Items, it)
	}
	// Timer
	if t := state.Timer; t != nil && t.Run != engine.Idle {
		it := Item{Mode: "timer", Label: t.Label, Progress: t.Progress(now), TotalSec: int(t.Total / time.Second)}
		switch {
		case t.Run == engine.Running && !now.Before(t.EndsAt):
			it.State, it.Icon, it.Progress = "finished", "✓", 1
			it.Text = "timer " + strings.ToLower(i18n.T("state.done"))
			e := t.EndsAt
			it.EndsAt = &e
		case t.Run == engine.Paused:
			it.State, it.Icon = "paused", "⏸"
			it.RemainingSec = ceilSec(t.Left)
			it.Text = "⏲ " + clock(it.RemainingSec)
		default:
			it.State, it.Icon = "running", "⏲"
			it.RemainingSec = ceilSec(t.Remaining(now))
			it.Text = "⏲ " + clock(it.RemainingSec)
			e := t.EndsAt
			it.EndsAt = &e
		}
		it.ElapsedSec = it.TotalSec - it.RemainingSec
		s.Items = append(s.Items, it)
	}
	// Stopwatch
	if w := state.Stopwatch; w != nil && (w.Run == engine.Running || w.Run == engine.Paused) {
		el := w.Elapsed(now)
		it := Item{Mode: "stopwatch", ElapsedSec: int(el / time.Second), Text: "⏱ " + clock(int(el/time.Second))}
		it.State, it.Icon = "running", "⏱"
		if w.Run == engine.Paused {
			it.State, it.Icon = "paused", "⏸"
		}
		s.Items = append(s.Items, it)
	}
	// Alarms
	if a, at := state.Alarms.Next(); a != nil {
		in := at.Sub(now)
		if in < 0 {
			in = 0
		}
		s.NextAlarm = &AlarmInfo{ID: a.ID, Label: a.Label, At: at, InSec: int(in / time.Second), Time: at.In(now.Location()).Format("15:04")}
	}

	// today
	sum := engine.Summarize(st.Events(), now, 14)
	s.Today = TodayInfo{FocusMin: int(sum.Today.Focus.Minutes()), Sessions: sum.Today.Sessions, Streak: sum.Streak}

	// headline: the first item wins (pomodoro > timer > stopwatch), else the
	// next alarm if it is near, else idle.
	if len(s.Items) > 0 {
		h := s.Items[0]
		s.Mode, s.Phase, s.State, s.Icon, s.Remaining, s.Total, s.Progress, s.EndsAt = h.Mode, h.Phase, h.State, h.Icon, h.RemainingSec, h.TotalSec, h.Progress, h.EndsAt
		s.Text = h.Icon + " " + h.Text
		if h.Mode != "pomodoro" {
			s.Text = h.Text
			if h.Mode == "timer" && h.State == "finished" {
				s.Text = h.Icon + " " + h.Text
			}
		}
		s.Class = h.Mode
		switch {
		case h.State == "finished":
			s.Class = "done"
		case h.State == "paused":
			s.Class = "paused"
		case h.Mode == "pomodoro":
			s.Class = h.Phase
			if h.Phase == string(engine.Rest) || h.Phase == string(engine.Long) {
				s.Color = pal.Rest.Hex()
			}
		}
		if h.Mode == "timer" {
			s.Color = pal.Rest.Hex()
		}
	} else if s.NextAlarm != nil && s.NextAlarm.InSec < 12*3600 {
		s.Mode, s.State, s.Class, s.Icon = "alarm", "armed", "alarm", "⏰"
		s.Remaining = s.NextAlarm.InSec
		e := s.NextAlarm.At
		s.EndsAt = &e
		s.Text = "⏰ " + s.NextAlarm.Time
	} else {
		s.Text = "idle"
	}
	s.Tooltip = tooltip(s)
	return s
}

func tooltip(s Snapshot) string {
	var l []string
	for _, it := range s.Items {
		line := fmt.Sprintf("%s %s", it.Icon, it.Text)
		switch it.State {
		case "paused":
			line += " (" + strings.ToLower(i18n.T("state.paused")) + ")"
		case "finished":
			if it.Label != "" {
				line += " — " + it.Label
			}
		case "running":
			if it.EndsAt != nil {
				line += " → " + it.EndsAt.Local().Format("15:04")
			}
		}
		if it.Mode == "timer" && it.Label != "" && it.State != "finished" {
			line += " · " + it.Label
		}
		l = append(l, line)
	}
	if s.NextAlarm != nil {
		line := "⏰ " + s.NextAlarm.Time
		if s.NextAlarm.Label != "" {
			line += " " + s.NextAlarm.Label
		}
		l = append(l, line)
	}
	if len(l) == 0 {
		l = append(l, "idle")
	}
	l = append(l, fmt.Sprintf("%s: %dm · %s", strings.ToLower(i18n.T("pomo.today")), s.Today.FocusMin, strings.ToLower(sessionsText(s.Today.Sessions))))
	return strings.Join(l, "\n")
}

func sessionsText(n int) string {
	if n == 1 {
		return i18n.T("pomo.session.1")
	}
	return i18n.T("pomo.sessions", n)
}

// ---------------------------------------------------------------- formats

// WaybarJSON is the object a Waybar custom module (return-type json) reads.
type WaybarJSON struct {
	Text       string `json:"text"`
	Alt        string `json:"alt"`
	Tooltip    string `json:"tooltip"`
	Class      string `json:"class"`
	Percentage int    `json:"percentage"`
}

func (s Snapshot) Waybar() WaybarJSON {
	text := s.Text
	if s.State == "idle" {
		text = "○" // the module stays; style `.idle` in Waybar CSS to dim or hide it
	}
	return WaybarJSON{
		Text: escapeMarkup(text), Alt: s.Mode, Tooltip: escapeMarkup(s.Tooltip), Class: s.Class,
		Percentage: int(s.Progress*100 + 0.5),
	}
}

func escapeMarkup(s string) string {
	return strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;").Replace(s)
}

// Polybar wraps the text in a color tag.
func (s Snapshot) Polybar() string { return "%{F" + s.Color + "}" + s.Text + "%{F-}" }

// Tmux wraps the text in a tmux style.
func (s Snapshot) Tmux() string { return "#[fg=" + s.Color + "]" + s.Text + "#[default]" }

func (s Snapshot) JSON() (string, error) {
	b, err := json.MarshalIndent(s, "", "  ")
	return string(b), err
}

// Render applies a Go template (fields of Snapshot: .Text .Mode .Phase .State
// .Remaining .Progress ...).
func (s Snapshot) Render(format string) (string, error) {
	t, err := template.New("status").Parse(format)
	if err != nil {
		return "", err
	}
	var sb strings.Builder
	if err := t.Execute(&sb, s); err != nil {
		return "", err
	}
	return sb.String(), nil
}
