package ui

import (
	"fmt"
	"strings"

	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

// Cursor positions along the editor's ribbon.
const (
	alarmPosHour  = 0
	alarmPosMin   = 1
	alarmPosDay0  = 2 // ..8 are the seven days
	alarmPosLabel = 9
	alarmPosCount = 10
)

type alarmEditor struct {
	id        int // 0 = a new alarm
	hour, min int
	days      engine.Days
	pos       int
	label     textinput.Model
}

func (m *alarmMode) newEditor(a *engine.Alarm) *alarmEditor {
	e := &alarmEditor{}
	if a != nil {
		e.id, e.hour, e.min, e.days = a.ID, a.Hour, a.Min, a.Days
	} else {
		e.hour, e.min = (m.c.Now.Hour()+1)%24, 0
	}
	pal := m.c.Pal
	st := textinput.DefaultStyles(pal.Dark)
	txt := lipgloss.NewStyle().Foreground(pal.Text)
	st.Focused.Text, st.Blurred.Text = txt, lipgloss.NewStyle().Foreground(pal.Muted)
	st.Focused.Placeholder = lipgloss.NewStyle().Foreground(pal.Faint)
	st.Blurred.Placeholder = lipgloss.NewStyle().Foreground(pal.Faint)
	st.Focused.Prompt, st.Blurred.Prompt = lipgloss.NewStyle(), lipgloss.NewStyle()
	st.Cursor.Color = pal.Accent
	st.Cursor.Blink = false
	e.label = textinput.New()
	e.label.SetStyles(st)
	e.label.Prompt = ""
	e.label.Placeholder = i18n.T("alarm.label.hint")
	e.label.CharLimit = 28
	e.label.SetWidth(24)
	if a != nil {
		e.label.SetValue(a.Label)
	}
	return e
}

func (e *alarmEditor) focus(pos int) {
	e.pos = clampi(pos, 0, alarmPosCount-1)
	if e.pos == alarmPosLabel {
		e.label.Focus()
		e.label.CursorEnd()
	} else {
		e.label.Blur()
	}
}

func (e *alarmEditor) bump(delta int) {
	switch e.pos {
	case alarmPosHour:
		e.hour = ((e.hour+delta)%24 + 24) % 24
	case alarmPosMin:
		e.min = ((e.min+delta)%60 + 60) % 60
	}
}

func (e *alarmEditor) typeDigit(d int) {
	switch e.pos {
	case alarmPosHour:
		v := (e.hour%10)*10 + d
		if v > 23 {
			v = d
		}
		e.hour = v
	case alarmPosMin:
		v := (e.min%10)*10 + d
		if v > 59 {
			v = d
		}
		e.min = v
	}
}

func (m *alarmMode) updateEditor(msg tea.Msg) tea.Cmd {
	e := m.ed
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		s := msg.String()
		switch s {
		case "enter":
			m.saveEditor()
			return nil
		case "esc":
			m.ed = nil
			return nil
		case "tab":
			e.focus((e.pos + 1) % alarmPosCount)
			return nil
		case "shift+tab":
			e.focus((e.pos - 1 + alarmPosCount) % alarmPosCount)
			return nil
		}
		if e.pos == alarmPosLabel {
			switch {
			case s == "up" || (s == "left" && e.label.Position() == 0):
				e.focus(alarmPosCount - 2)
			default:
				e.label, _ = e.label.Update(msg)
			}
			return nil
		}
		switch s {
		case "left", "h":
			e.focus(e.pos - 1)
		case "right", "l":
			e.focus(e.pos + 1)
		case "up", "k", "+", "=":
			e.bump(1)
		case "down", "j", "-", "_":
			e.bump(-1)
		case "shift+up", "K":
			e.bump(map[bool]int{true: 5, false: 3}[e.pos == alarmPosMin])
		case "shift+down", "J":
			e.bump(-map[bool]int{true: 5, false: 3}[e.pos == alarmPosMin])
		case "space":
			if e.pos >= alarmPosDay0 && e.pos < alarmPosLabel {
				e.days = e.days.Toggle(e.pos - alarmPosDay0)
			}
		case "w":
			e.days = engine.Weekdays
		case "e":
			e.days = engine.Weekend
		case "a":
			e.days = engine.Everyday
		case "o":
			e.days = 0
		default:
			if len(s) == 1 && s[0] >= '0' && s[0] <= '9' {
				e.typeDigit(int(s[0] - '0'))
			}
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		for _, h := range m.hits {
			if !h.has(msg.X, msg.Y) {
				continue
			}
			switch h.kind {
			case alarmHitHour:
				e.focus(alarmPosHour)
			case alarmHitMin:
				e.focus(alarmPosMin)
			case alarmHitChip:
				e.days = e.days.Toggle(h.idx)
				e.focus(alarmPosDay0 + h.idx)
			}
			break
		}
	case tea.MouseWheelMsg:
		d := 1
		if msg.Button == tea.MouseWheelDown {
			d = -1
		} else if msg.Button != tea.MouseWheelUp {
			return nil
		}
		for _, h := range m.hits {
			if h.has(msg.X, msg.Y) && (h.kind == alarmHitHour || h.kind == alarmHitMin) {
				if h.kind == alarmHitHour {
					e.focus(alarmPosHour)
				} else {
					e.focus(alarmPosMin)
				}
				e.bump(d)
			}
		}
	}
	return nil
}

func (m *alarmMode) saveEditor() {
	e := m.ed
	c := m.c
	a := engine.Alarm{
		ID: e.id, Label: strings.TrimSpace(e.label.Value()),
		Hour: e.hour, Min: e.min, Days: e.days, Enabled: true,
	}
	var saved *engine.Alarm
	if e.id == 0 {
		saved = c.Alarms.Add(a, c.Now)
	} else {
		c.Alarms.Update(a, c.Now)
		saved = c.Alarms.Get(e.id)
	}
	c.MarkDirty()
	for i, x := range c.Alarms.List {
		if saved != nil && x.ID == saved.ID {
			m.sel = i
		}
	}
	if saved != nil && !saved.NextAt.IsZero() {
		m.say(i18n.T("alarm.saved", alarmDur(saved.NextAt.Sub(c.Now))))
	}
	m.ed = nil
}

// ---------------------------------------------------------------- view

func alarmBg(bg braille.RGB, s string) string {
	return "\x1b[48;2;" + rgbCSV(bg) + "m" + s + "\x1b[49m"
}

// chipsLine draws the day chips of the editor; hits are recorded for the mouse.
func (m *alarmMode) editorChips(x0, y int, tight bool) string {
	e := m.ed
	pal := m.c.Pal
	letters := []rune(i18n.T("alarm.days"))
	var sb strings.Builder
	x := x0
	for i := 0; i < 7 && i < len(letters); i++ {
		on := e.days&(1<<uint(i)) != 0
		cur := e.pos == alarmPosDay0+i
		ch := string(letters[i])
		var chip string
		switch {
		case on:
			chip = alarmBg(pal.Accent, "\x1b[1m"+sgr(pal.Bg)+" "+ch+" \x1b[22m")
		default:
			chip = paint(pal.Muted, " "+ch+" ")
		}
		adv := 5
		switch {
		case tight && cur:
			chip = bold(pal.Bright, "[") + paint(pal.Text, ch) + bold(pal.Bright, "]")
			if on {
				chip = bold(pal.Accent, "["+ch+"]")
			}
			adv = 3
		case tight:
			adv = 3
		case cur:
			l, r := bold(pal.Bright, "["), bold(pal.Bright, "]")
			chip = l + chip + r
		default:
			chip = " " + chip + " "
		}
		m.hits = append(m.hits, alarmHit{x0: x, y0: y, x1: x + adv, y1: y + 1, kind: alarmHitChip, idx: i})
		sb.WriteString(chip)
		x += adv
	}
	return sb.String()
}

func (m *alarmMode) viewEditor(w, h int) []string {
	e := m.ed
	pal := m.c.Pal
	title := i18n.T("alarm.title.edit")
	if e.id == 0 {
		title = i18n.T("alarm.title.new")
	}
	preview := paint(pal.Muted, alarmTrim(m.alarmPreviewText(e.hour, e.min, e.days), w-2))

	// tier by height: tall digits with neighbours, tall digits, text only
	rows := 0
	neighbours := false
	switch {
	case h >= 18 && w >= 46:
		rows, neighbours = 5, true
	case h >= 14 && w >= 36:
		rows = 3
	}

	var lines []string
	pushC := func(s string) { lines = append(lines, centerIn(s, w)) }
	hourCol, minCol := pal.Text, pal.Text
	if e.pos == alarmPosHour {
		hourCol = pal.Bright
	}
	if e.pos == alarmPosMin {
		minCol = pal.Bright
	}

	pushC(bold(pal.Accent, title))
	lines = append(lines, "")
	if rows > 0 {
		hl := alarmBigTime(fmt.Sprintf("%02d", e.hour), rows, hourCol)
		ml := alarmBigTime(fmt.Sprintf("%02d", e.min), rows, minCol)
		cl := alarmBigTime(":", rows, pal.Muted)
		hw, mw, cw := width(hl[0]), width(ml[0]), width(cl[0])
		total := hw + cw + mw + 2
		left := (w - total) / 2
		if neighbours {
			up := paint(pal.Faint, fmt.Sprintf("%02d", (e.hour+23)%24))
			upm := paint(pal.Faint, fmt.Sprintf("%02d", (e.min+59)%60))
			lines = append(lines, spaces(left)+centerIn(up, hw)+spaces(cw+2)+centerIn(upm, mw))
		}
		y0 := len(lines)
		for r := 0; r < rows; r++ {
			lines = append(lines, spaces(left)+hl[r]+" "+cl[r]+" "+ml[r])
		}
		m.hits = append(m.hits,
			alarmHit{x0: left, y0: y0, x1: left + hw, y1: y0 + rows, kind: alarmHitHour},
			alarmHit{x0: left + hw + cw + 2, y0: y0, x1: left + total, y1: y0 + rows, kind: alarmHitMin})
		// the focus mark under the active group
		under := spaces(left)
		bar := func(n int, on bool) string {
			if on {
				return paint(pal.Accent, strings.Repeat("⣀", n))
			}
			return spaces(n)
		}
		under += bar(hw, e.pos == alarmPosHour) + spaces(cw+2) + bar(mw, e.pos == alarmPosMin)
		lines = append(lines, under)
		if neighbours {
			dn := paint(pal.Faint, fmt.Sprintf("%02d", (e.hour+1)%24))
			dnm := paint(pal.Faint, fmt.Sprintf("%02d", (e.min+1)%60))
			lines = append(lines, spaces(left)+centerIn(dn, hw)+spaces(cw+2)+centerIn(dnm, mw))
		}
	} else {
		hs, ms := fmt.Sprintf("%02d", e.hour), fmt.Sprintf("%02d", e.min)
		mark := func(s string, on bool) string {
			if on {
				return bold(pal.Accent, "["+s+"]")
			}
			return bold(pal.Text, " "+s+" ")
		}
		t := mark(hs, e.pos == alarmPosHour) + paint(pal.Muted, " : ") + mark(ms, e.pos == alarmPosMin)
		left := (w - width(t)) / 2
		y0 := len(lines)
		lines = append(lines, spaces(left)+t)
		m.hits = append(m.hits,
			alarmHit{x0: left, y0: y0, x1: left + 4, y1: y0 + 1, kind: alarmHitHour},
			alarmHit{x0: left + 7, y0: y0, x1: left + 11, y1: y0 + 1, kind: alarmHitMin})
	}
	if rows > 0 {
		lines = append(lines, "")
	}

	// days
	tight := w < 7*5
	chipsW := 7 * 5
	if tight {
		chipsW = 7 * 3
	}
	if w >= 7*3 {
		x0 := (w - chipsW) / 2
		chips := m.editorChips(x0, len(lines), tight)
		lines = append(lines, spaces(x0)+chips)
		if t, ok := alarmDaysText(e.days); ok && rows > 0 {
			lines = append(lines, centerIn(paint(pal.Muted, t), w))
		}
		if rows > 0 {
			lines = append(lines, "")
		}
	}

	// label
	e.label.SetWidth(clampi(w-14, 6, 28))
	lcol := pal.Muted
	if e.pos == alarmPosLabel {
		lcol = pal.Bright
	}
	lab := paint(lcol, i18n.T("alarm.label")+" ") + e.label.View()
	lines = append(lines, centerIn(lab, w))
	if rows > 0 {
		lines = append(lines, "")
	}
	lines = append(lines, centerIn(preview, w))

	// vertical centring (hits were recorded relative to `lines`)
	top := (h - len(lines)) / 2
	if top < 0 {
		top = 0
	}
	for i := range m.hits {
		m.hits[i].y0 += top
		m.hits[i].y1 += top
	}
	out := blank(w, h)
	for i, l := range lines {
		if top+i < h {
			out[top+i] = padRight(l, w)
		}
	}
	return out
}
