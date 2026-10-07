package ui

import (
	"fmt"
	"strings"
	"time"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

// spark draws values as a braille sparkline (two columns per cell).
func spark(vals []float64, col, dim braille.RGB) string {
	mx := 0.0
	for _, v := range vals {
		if v > mx {
			mx = v
		}
	}
	// height 0..4 dots per column; left column dots 1,2,3,7 right 4,5,6,8
	left := []rune{0, 0x40, 0x44, 0x46, 0x47}
	right := []rune{0, 0x80, 0xA0, 0xB0, 0xB8}
	h := func(v float64) int {
		if mx == 0 || v <= 0 {
			return 0
		}
		n := int(v/mx*4 + 0.5)
		if n < 1 {
			n = 1
		}
		return n
	}
	var sb strings.Builder
	for i := 0; i < len(vals); i += 2 {
		a := h(vals[i])
		b := 0
		if i+1 < len(vals) {
			b = h(vals[i+1])
		}
		r := rune(0x2800) + left[a] + right[b]
		cc := col
		if a == 0 && b == 0 {
			cc = dim
			r = 0x2800 + 0x40 + 0x80
		}
		sb.WriteString(paint(cc, string(r)))
	}
	return sb.String()
}

// panel is the side column of the wide layout, composed with Lip Gloss.
func (m *pomodoroMode) panel(w, h int) []string {
	c := m.c
	p := c.Pomo
	pal := c.Pal
	phaseCol := pal.Phase(p.Phase.IsRest())

	section := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)
	val := lipgloss.NewStyle().Foreground(pal.Text)
	mut := lipgloss.NewStyle().Foreground(pal.Muted)
	title := lipgloss.NewStyle().Foreground(phaseCol).Bold(true)

	var rows []string
	phaseName := i18n.T("phase." + string(p.Phase))
	rows = append(rows, title.Render("● "+phaseName))
	if p.Cfg.Cycles > 0 {
		rows = append(rows, mut.Render(i18n.T("pomo.session", p.Done+1, p.Cfg.Cycles))+"  "+m.dots())
	} else {
		rows = append(rows, mut.Render(i18n.T("pomo.session.n", p.Done+1)))
	}
	switch p.Run {
	case engine.Running:
		rows = append(rows, mut.Render(i18n.T("pomo.ends", p.EndsAt.Format("15:04"))))
	case engine.Paused:
		rows = append(rows, lipgloss.NewStyle().Foreground(pal.Warn).Render(i18n.T("state.paused")))
	default:
		rows = append(rows, lipgloss.NewStyle().Foreground(phaseCol).Render(i18n.T("pomo.press")))
	}
	next := p.Phase
	_ = next
	rows = append(rows, "")

	// today
	sum := engine.Summarize(c.Events(), c.Now, 14)
	rows = append(rows, section.Render(strings.ToUpper(i18n.T("pomo.today"))))
	rows = append(rows, val.Render(fmtDur(sum.Today.Focus.Round(time.Minute)))+"  "+mut.Render(sessionsText(sum.Today.Sessions)))
	vals := make([]float64, 0, 14)
	for _, d := range sum.Days[len(sum.Days)-14:] {
		vals = append(vals, float64(d.Focus))
	}
	rows = append(rows, spark(vals, phaseCol, pal.Faint)+"  "+mut.Render(i18n.T("pomo.last", len(vals))+" "+fmtDur(sum.Total.Round(time.Minute))))
	if sum.Streak > 0 {
		s := i18n.T("pomo.streak.d", sum.Streak)
		if sum.Streak == 1 {
			s = i18n.T("pomo.streak.1")
		}
		rows = append(rows, mut.Render(i18n.T("pomo.streak")+"  ")+lipgloss.NewStyle().Foreground(pal.Warn).Render("✦ "+s))
	}
	rows = append(rows, "")

	// rhythm picker
	rows = append(rows, section.Render(strings.ToUpper(i18n.T("pomo.presets"))))
	cur, _ := m.currentRhythm()
	for _, r := range rhythms {
		name := i18n.T("pomo.preset." + r.id)
		line := fmt.Sprintf("%-10s %d/%d", name, r.work, r.rest)
		if r.id == cur {
			rows = append(rows, lipgloss.NewStyle().Foreground(pal.Accent).Bold(true).Render("▸ "+line))
		} else {
			rows = append(rows, mut.Render("  "+line))
		}
	}
	if cur == "custom" {
		line := fmt.Sprintf("%-10s %d/%d", i18n.T("pomo.preset.custom"), c.Cfg.Work, c.Cfg.Rest)
		rows = append(rows, lipgloss.NewStyle().Foreground(pal.Accent).Bold(true).Render("▸ "+line))
	}

	block := lipgloss.NewStyle().Width(w).Render(strings.Join(rows, "\n"))
	lines := strings.Split(block, "\n")
	// vertically centered
	out := blank(w, h)
	top := (h - len(lines)) / 2
	if top < 0 {
		top = 0
	}
	for i, l := range lines {
		if top+i < h {
			out[top+i] = padRight(l, w)
		}
	}
	return out
}

func sessionsText(n int) string {
	if n == 1 {
		return i18n.T("pomo.session.1")
	}
	return i18n.T("pomo.sessions", n)
}
