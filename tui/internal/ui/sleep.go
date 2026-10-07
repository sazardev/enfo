package ui

import (
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func init() {
	registerMode("sleep", func(c *Core, say func(string)) Mode { return newSleepMode(c, say) })
}

const (
	sleepCycle   = 90 * time.Minute
	sleepFallOff = 15 * time.Minute
	sleepWind    = 30 * time.Minute
)

// sleepCycles are the suggestions offered, best first.
var sleepCycles = [3]int{6, 5, 4}

type sleepFile struct {
	Wake int  `json:"wake"` // minutes after midnight
	Wind bool `json:"wind"`
	Mode int  `json:"mode"`
}

type sleepMode struct {
	c   *Core
	say func(string)

	path   string
	mode   int // 0 = I need to wake up at, 1 = I'm going to bed
	wake   int // minutes after midnight (mode 0)
	offset int // minutes from now (mode 1)
	opt    int
	wind   bool

	t      float64
	sweep  *anim.Spring
	canvas *braille.Canvas
	cards  []sleepRect
}

type sleepRect struct{ x, y, w, h int }

func newSleepMode(c *Core, say func(string)) *sleepMode {
	m := &sleepMode{c: c, say: say, wake: 7 * 60, wind: true,
		path: filepath.Join(c.Store.StateDir, "sleep.json"), sweep: anim.NewSpring(0, 4, 0.9)}
	m.sweep.Target = 1
	if b, err := os.ReadFile(m.path); err == nil {
		var f sleepFile
		if json.Unmarshal(b, &f) == nil && f.Wake >= 0 && f.Wake < 1440 {
			m.wake, m.wind = f.Wake, f.Wind
			if f.Mode == 0 || f.Mode == 1 {
				m.mode = f.Mode
			}
		}
	}
	return m
}

func (m *sleepMode) ID() string      { return "sleep" }
func (m *sleepMode) Animated() bool  { return m.c.Cfg.Motion != "still" }
func (m *sleepMode) Capturing() bool { return false }

func (m *sleepMode) save() {
	b, err := json.Marshal(sleepFile{Wake: m.wake, Wind: m.wind, Mode: m.mode})
	if err != nil {
		return
	}
	tmp := m.path + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, m.path)
	}
}

func (m *sleepMode) Frame(dt time.Duration) {
	m.t += dt.Seconds()
	if m.c.Cfg.Motion == "still" {
		m.sweep.Snap(1)
		return
	}
	m.sweep.Step(dt)
}

func (m *sleepMode) restart() { m.sweep.Pos, m.sweep.Vel, m.sweep.Target = 0.05, 0, 1 }

// ---------------------------------------------------------------- the plan

type sleepOption struct {
	cycles int
	bed    time.Time
	wake   time.Time
	total  time.Duration
}

// sleepPlan computes the three suggestions for a clock and the mode.
func sleepPlan(now time.Time, mode, wakeMin, offset int) (opts [3]sleepOption, anchor time.Time) {
	loc := now.Location()
	if mode == 0 {
		w := time.Date(now.Year(), now.Month(), now.Day(), wakeMin/60, wakeMin%60, 0, 0, loc)
		if !w.After(now) {
			w = w.AddDate(0, 0, 1)
		}
		for i, n := range sleepCycles {
			asleep := time.Duration(n) * sleepCycle
			opts[i] = sleepOption{cycles: n, wake: w, bed: w.Add(-asleep - sleepFallOff), total: asleep}
		}
		return opts, w
	}
	b := now.Truncate(time.Minute).Add(time.Duration(offset) * time.Minute)
	for i, n := range sleepCycles {
		asleep := time.Duration(n) * sleepCycle
		opts[i] = sleepOption{cycles: n, bed: b, wake: b.Add(sleepFallOff + asleep), total: asleep}
	}
	return opts, b
}

func (m *sleepMode) plan() ([3]sleepOption, time.Time) {
	return sleepPlan(m.c.Now, m.mode, m.wake, m.offset)
}

// ---------------------------------------------------------------- input

func (m *sleepMode) Help() []key.Binding {
	return []key.Binding{
		kb("up|down|k|j", "↑↓", i18n.T("sleep.min5")),
		kb("left|right|h|l", "←→", i18n.T("sleep.hour1")),
		kb("m", "m", i18n.T("sleep.mode")),
		kb("c", "c", i18n.T("sleep.option")),
		kb("w", "w", i18n.T("sleep.winddown")),
		kb("a|enter", "a", i18n.T("sleep.setalarm")),
	}
}

func (m *sleepMode) adjust(minutes int) {
	if m.mode == 0 {
		m.wake = ((m.wake+minutes)%1440 + 1440) % 1440
	} else {
		m.offset += minutes
		if m.offset < -12*60 {
			m.offset = -12 * 60
		}
		if m.offset > 12*60 {
			m.offset = 12 * 60
		}
	}
	m.restart()
	m.save()
}

func (m *sleepMode) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch msg.String() {
		case "up", "k", "+", "=":
			m.adjust(5)
		case "down", "j", "-", "_":
			m.adjust(-5)
		case "right", "l":
			m.adjust(60)
		case "left", "h":
			m.adjust(-60)
		case "m":
			m.mode = 1 - m.mode
			m.restart()
			m.save()
		case "c":
			m.opt = (m.opt + 1) % 3
			m.restart()
		case "w":
			if m.mode == 0 {
				m.wind = !m.wind
				m.save()
			}
		case "a", "enter":
			m.createAlarms()
		}
	case tea.MouseClickMsg:
		if msg.Button == tea.MouseLeft {
			for i, r := range m.cards {
				if msg.X >= r.x && msg.X < r.x+r.w && msg.Y >= r.y && msg.Y < r.y+r.h {
					if m.opt == i {
						m.createAlarms()
					}
					m.opt = i
					m.restart()
				}
			}
		}
	case tea.MouseWheelMsg:
		if msg.Button == tea.MouseWheelUp {
			m.adjust(5)
		} else if msg.Button == tea.MouseWheelDown {
			m.adjust(-5)
		}
	}
	return nil
}

// createAlarms sets the real alarm(s) for the chosen suggestion.
func (m *sleepMode) createAlarms() {
	opts, _ := m.plan()
	o := opts[m.opt]
	c := m.c
	made := 0
	add := func(at time.Time, label string) bool {
		for _, a := range c.Alarms.List {
			if a.Enabled && a.Days == 0 && a.Hour == at.Hour() && a.Min == at.Minute() && a.Label == label {
				return false
			}
		}
		c.Alarms.Add(engine.Alarm{Label: label, Hour: at.Hour(), Min: at.Minute(), Enabled: true}, c.Now)
		made++
		return true
	}
	wakeOK := add(o.wake, i18n.T("sleep.alarm.wake"))
	windText := ""
	if m.wind && m.mode == 0 {
		w := o.bed.Add(-sleepWind)
		if w.After(c.Now) {
			if add(w, i18n.T("sleep.alarm.wind")) {
				windText = " · " + i18n.T("sleep.alarm.wind.at", w.Format("15:04"))
			}
		}
	}
	c.MarkDirty()
	if made == 0 {
		m.say(i18n.T("sleep.already"))
		return
	}
	if !wakeOK {
		m.say(i18n.T("sleep.set.only", windText))
		return
	}
	m.say(i18n.T("sleep.set", o.wake.Format("15:04")) + windText)
}

// ---------------------------------------------------------------- view

func (m *sleepMode) View(w, h int) string {
	if w < 8 || h < 2 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	opts, anchor := m.plan()
	if m.opt >= len(opts) {
		m.opt = 0
	}
	c := m.c
	pal := c.Pal

	head := m.headLine(w, anchor)
	footer := m.footLine(w, opts[m.opt])

	// cards
	wideCards := w >= 66
	cardsH := 3
	if wideCards {
		cardsH = 5
	}
	avail := h - 2 // head + footer
	if avail < cardsH {
		cardsH = maxi(0, avail)
	}
	skyH := avail - cardsH - 1
	if skyH > 30 {
		skyH = 30
	}
	var lines []string
	lines = append(lines, head)
	m.cards = m.cards[:0]
	if skyH >= 6 && w >= 30 {
		lines = append(lines, m.sky(w, skyH, opts[m.opt], anchor)...)
		lines = append(lines, "")
	} else if skyH >= 0 && cardsH < avail {
		for i := 0; i < avail-cardsH; i++ {
			lines = append(lines, spaces(w))
		}
	}
	cardTop := len(lines)
	if wideCards && cardsH == 5 {
		lines = append(lines, m.cardRow(w, opts, cardTop)...)
	} else if cardsH > 0 {
		lines = append(lines, m.cardList(w, opts, cardTop, cardsH)...)
	}
	for len(lines) < h-1 {
		lines = append(lines, spaces(w))
	}
	lines = lines[:minI(len(lines), h-1)]
	lines = append(lines, footer)
	_ = pal
	return join(fit(lines, w, h))
}

func (m *sleepMode) headLine(w int, anchor time.Time) string {
	pal := m.c.Pal
	a := i18n.T("sleep.mode.wake", anchor.Format("15:04"))
	b := i18n.T("sleep.mode.bed", anchor.Format("15:04"))
	if m.mode == 0 {
		b = i18n.T("sleep.mode.bed.short")
	} else {
		a = i18n.T("sleep.mode.wake.short")
	}
	chip := func(on bool, s string) string {
		if on {
			return bold(pal.Accent, "● "+s)
		}
		return paint(pal.Muted, "○ "+s)
	}
	line := " " + chip(m.mode == 0, a) + paint(pal.Faint, "   ·   ") + chip(m.mode == 1, b)
	return padRight(ansi.Truncate(line, w, ""), w)
}

func (m *sleepMode) footLine(w int, o sleepOption) string {
	pal := m.c.Pal
	var s string
	if m.mode == 0 {
		box := "○"
		if m.wind {
			box = "●"
		}
		s = paint(pal.Muted, box+" "+i18n.T("sleep.wind.label", int(sleepWind.Minutes())))
	} else {
		off := ""
		if m.offset != 0 {
			off = " (" + signed(m.offset) + " min)"
		}
		s = paint(pal.Muted, i18n.T("sleep.fall", int(sleepFallOff.Minutes()))+off)
	}
	return padRight(" "+ansi.Truncate(s, w-2, "…"), w)
}

func signed(n int) string {
	if n > 0 {
		return "+" + itoa(n)
	}
	return itoa(n)
}

// cycle texts ---------------------------------------------------------------

func sleepHours(d time.Duration) string {
	h := d.Minutes() / 60
	if h == math.Trunc(h) {
		return itoa(int(h)) + " h"
	}
	return itoa(int(h)) + "½ h"
}

func (m *sleepMode) optTitle(o sleepOption) string {
	return i18n.T("sleep.cycles", o.cycles) + " · " + sleepHours(o.total)
}

func (m *sleepMode) optTag(o sleepOption) (string, bool) {
	if o.cycles >= 5 {
		return i18n.T("sleep.recommended"), true
	}
	return i18n.T("sleep.minimum"), false
}

// optWhen is the "in 3 h 20 min" line about the thing the user acts on: the
// bedtime when planning a wake-up, the wake-up when going to bed.
func (m *sleepMode) optWhen(o sleepOption) string {
	target := o.bed
	key := "sleep.bed.in"
	if m.mode == 1 {
		target, key = o.wake, "sleep.wake.in"
	}
	d := target.Sub(m.c.Now)
	if d <= 0 {
		return i18n.T("sleep.passed")
	}
	return i18n.T(key, eventLong(d))
}

// main time of an option: bedtime for a fixed wake-up, wake-up when going to bed
func (m *sleepMode) optTime(o sleepOption) time.Time {
	if m.mode == 0 {
		return o.bed
	}
	return o.wake
}

func (m *sleepMode) cardRow(w int, opts [3]sleepOption, top int) []string {
	pal := m.c.Pal
	cw := (w - 2) / 3
	var cols [][]string
	for i, o := range opts {
		sel := i == m.opt
		tag, rec := m.optTag(o)
		tagS := lipgloss.NewStyle().Foreground(pal.Muted).Render(tag)
		if rec {
			tagS = lipgloss.NewStyle().Foreground(pal.Good).Render("★ " + tag)
		}
		bc := pal.Faint
		timeCol := pal.Text
		if sel {
			bc, timeCol = pal.Accent, pal.Bright
		}
		inner := cw - 4
		body := lipgloss.JoinVertical(lipgloss.Left,
			lipgloss.NewStyle().Foreground(pal.Muted).Render(ansi.Truncate(m.optTitle(o), inner, "…")),
			lipgloss.NewStyle().Foreground(timeCol).Bold(true).Render(m.optTime(o).Format("15:04")+"  ")+tagS,
			lipgloss.NewStyle().Foreground(pal.Muted).Render(ansi.Truncate(m.optWhen(o), inner, "…")),
		)
		box := lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(bc).
			Padding(0, 1).Width(cw).Render(body)
		cols = append(cols, strings.Split(box, "\n"))
		m.cards = append(m.cards, sleepRect{x: i * (cw + 1), y: top, w: cw, h: len(cols[i])})
	}
	row := hcat(cols[0], blank(1, 5), cols[1], blank(1, 5), cols[2])
	return fit(row, w, 5)
}

func (m *sleepMode) cardList(w int, opts [3]sleepOption, top, h int) []string {
	pal := m.c.Pal
	out := make([]string, 0, h)
	for i, o := range opts {
		if i >= h {
			break
		}
		sel := i == m.opt
		_, rec := m.optTag(o)
		mark := "  "
		tm := paint(pal.Text, m.optTime(o).Format("15:04"))
		title := paint(pal.Muted, m.optTitle(o))
		if sel {
			mark = bold(pal.Accent, "▸ ")
			tm = bold(pal.Bright, m.optTime(o).Format("15:04"))
			title = paint(pal.Text, m.optTitle(o))
		}
		star := " "
		if rec {
			star = paint(pal.Good, "★")
		}
		line := mark + tm + " " + star + " " + title
		if w >= 54 {
			line += paint(pal.Muted, "  "+m.optWhen(o))
		}
		out = append(out, padRight(ansi.Truncate(line, w, "…"), w))
		m.cards = append(m.cards, sleepRect{x: 0, y: top + i, w: w, h: 1})
	}
	return out
}

// ---------------------------------------------------------------- the sky

func (m *sleepMode) sky(w, rows int, o sleepOption, anchor time.Time) []string {
	c := m.c
	pal := c.Pal
	cols := minI(w, 130)
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	cv := m.canvas
	still := c.Cfg.Motion == "still"
	W, H := float64(cv.W), float64(cv.H)

	// stars, denser toward the top
	nStars := int(W * H * 0.012)
	for i := 0; i < nStars; i++ {
		x := int(anim.Hash01(uint32(i*3+1)) * W)
		y := int(math.Pow(anim.Hash01(uint32(i*3+2)), 1.6) * H)
		k := 0.5
		if !still {
			k = 0.5 + 0.5*math.Sin(m.t*(0.4+anim.Hash01(uint32(i))*1.6)+anim.Hash01(uint32(i*3+3))*6.28)
		}
		cv.Set(x, y, pal.Bg.Mix(pal.Moon, 0.15+0.6*k*k))
	}

	// the moon, top right: a disc with a bite taken out of it, and a halo
	mr := math.Max(6, math.Min(H*0.2, W*0.07))
	mx, my := W-mr*2.6, mr*1.7
	if !still {
		my += math.Sin(m.t*0.5) * 1.5
	}
	for dy := -mr * 2.2; dy <= mr*2.2; dy++ {
		for dx := -mr * 2.2; dx <= mr*2.2; dx++ {
			d := math.Hypot(dx, dy)
			if d > mr*1.15 && d < mr*2.2 && (int(mx+dx)+int(my+dy))&3 == 0 {
				cv.Dot(mx+dx, my+dy, pal.Bg.Mix(pal.Moon, 0.12*(1-(d-mr*1.15)/(mr*1.05))))
			}
		}
	}
	cv.Disc(mx, my, mr, braille.Solid(pal.Moon.Lighten(0.25)))
	cv.EraseDisc(mx+mr*0.55, my-mr*0.25, mr*0.88)

	// the big time on the left
	th := int(math.Min(H*0.42, 26))
	if th >= 8 {
		tm := anchor.Format("15:04")
		font := braille.ParseFont(c.Cfg.Font)
		if font.TextWidth(tm, th) > int(W*0.5) {
			th = font.FitHeight(tm, int(W*0.5), th)
		}
		cv.Text(font, tm, 4, 3, th, braille.Solid(pal.Text))
	}

	// the night's hypnogram across the bottom
	m.hypnogram(cv, o)
	lines := cv.Lines()
	out := make([]string, rows)
	for i, l := range lines {
		out[i] = padRight(centerIn(l, w), w)
	}
	return out
}

// sleepDepth is how deep sleep is, 0 = awake/REM (top) .. 1 = deepest, at a
// point u (0..1) of cycle k out of n. Deep sleep fades across the night and
// REM grows, like the real thing.
func sleepDepth(k, n int, u float64) float64 {
	peak := 1.0
	if n > 1 {
		peak = 1 - 0.38*float64(k)/float64(n-1)
	}
	switch {
	case u < 0.12:
		return anim.Lerp(0.18, 0.55, anim.Smooth(u/0.12))
	case u < 0.45:
		return 0.55 + (peak-0.55)*math.Sin(math.Pi*(u-0.12)/0.33)
	case u < 0.68:
		return anim.Lerp(0.55, 0.16, anim.Smooth((u-0.45)/0.23))
	case u < 0.95:
		return 0.13 + 0.05*math.Sin((u-0.68)/0.27*math.Pi*3)
	}
	return anim.Lerp(0.15, 0.22, (u-0.95)/0.05)
}

func (m *sleepMode) hypnogram(cv *braille.Canvas, o sleepOption) {
	pal := m.c.Pal
	W, H := float64(cv.W), float64(cv.H)
	left, right := 4.0, W-4
	top, bot := H*0.5, H-3
	if bot-top < 8 {
		top = bot - 8
	}
	n := o.cycles
	total := float64(sleepFallOff+o.total) / float64(sleepCycle) // in cycles; includes the fall-asleep lead
	lead := float64(sleepFallOff) / float64(sleepCycle)
	reveal := left + (right-left)*anim.OutCubic(m.sweep.Pos)
	// baseline dotted line (awake level)
	for x := left; x <= right; x += 3 {
		cv.Dot(x, top, pal.Faint)
	}
	prevY := top
	for x := int(left); x <= int(right) && float64(x) <= reveal; x++ {
		pos := (float64(x) - left) / (right - left) * total // in cycles
		var s float64
		if pos < lead {
			s = 0.02 // falling asleep
		} else {
			t := pos - lead
			k := minI(int(t), n-1)
			s = sleepDepth(k, n, t-float64(k))
		}
		y := top + s*(bot-top)
		col := pal.Accent // REM
		switch {
		case s > 0.62:
			col = pal.Rest
		case s > 0.3:
			col = pal.Moon
		}
		if pos < lead {
			col = pal.Muted
		}
		// soft fill under the curve, brighter near the line
		for yy := int(y); yy < int(bot); yy += 2 {
			k := 1 - (float64(yy)-y)/(bot-top+1)
			if (x+yy)&1 == 0 {
				cv.Set(x, yy, pal.Bg.Mix(col, 0.08+0.3*k*k))
			}
		}
		cv.Line(float64(x), prevY, float64(x), y, 1.6, braille.Solid(col))
		prevY = y
	}
	// cycle boundaries and a marker at the head of the sweep
	for k := 0; k <= n; k++ {
		x := left + (right-left)*(lead+float64(k))/total
		if x <= reveal {
			for y := bot; y > bot-4; y-- {
				cv.Set(int(x), int(y), pal.Muted)
			}
		}
	}
	if reveal < right {
		cv.Disc(reveal, prevY, 2, braille.Solid(pal.Text))
	}
}
