package ui

import (
	"fmt"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

func init() {
	registerMode("clock", func(c *Core, say func(string)) Mode { return newClockMode(c, say) })
}

// clockMode is the always-on clock: five braille designs, a side panel when
// there is room.
type clockMode struct {
	c      *Core
	say    func(string)
	face   visual.ClockFace
	name   string
	canvas *braille.Canvas
	area   struct{ x, y, w, h int }
	last   *visual.ClockFrame

	// per-day cache of where we are on Earth and when the sun comes up
	sunKey   int
	sunRise  float64
	sunSet   float64
	sunReal  bool
	sunPolar int
	place    engine.City
	hasPlace bool
	placeSet bool
}

func newClockMode(c *Core, say func(string)) *clockMode {
	m := &clockMode{c: c, say: say}
	m.setFace(c.Cfg.ClockDesign)
	return m
}

func (m *clockMode) ID() string { return "clock" }

func (m *clockMode) setFace(name string) {
	ok := false
	for _, n := range visual.ClockFaceNames {
		if n == name {
			ok = true
		}
	}
	if !ok {
		name = "analog"
	}
	m.face = visual.NewClockFace(name)
	m.name = name
}

func (m *clockMode) Animated() bool {
	if m.c.Cfg.Motion == "still" {
		return false
	}
	if m.last == nil {
		return true
	}
	return m.face.Animated(m.last)
}

func (m *clockMode) Help() []key.Binding {
	return []key.Binding{
		kb("d|D", "d", i18n.T("clock.key.design")),
		kb("s", "s", i18n.T("clock.key.seconds")),
		kb("h", "h", i18n.T("clock.key.h24")),
	}
}

func (m *clockMode) Frame(dt time.Duration) {
	f := m.frame(dt.Seconds())
	m.face.Step(f)
	m.last = f
}

func (m *clockMode) cycle(d int) {
	idx := 0
	for i, n := range visual.ClockFaceNames {
		if n == m.name {
			idx = i
		}
	}
	n := len(visual.ClockFaceNames)
	name := visual.ClockFaceNames[(idx+d+n)%n]
	m.setFace(name)
	m.c.Cfg.ClockDesign = name
	m.c.ApplyConfig()
	if m.say != nil {
		m.say("◷ " + i18n.T("clock.design."+name))
	}
}

func (m *clockMode) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case matches(msg, kb("d", "", "")):
			m.cycle(1)
		case matches(msg, kb("D", "", "")):
			m.cycle(-1)
		case matches(msg, kb("s", "", "")):
			m.c.Cfg.ClockSeconds = !m.c.Cfg.ClockSeconds
			m.c.ApplyConfig()
		case matches(msg, kb("h", "", "")):
			m.c.Cfg.Clock24 = !m.c.Cfg.Clock24
			m.c.ApplyConfig()
		}
	case tea.MouseClickMsg:
		a := m.area
		if msg.Button == tea.MouseLeft && msg.X >= a.x && msg.X < a.x+a.w && msg.Y >= a.y && msg.Y < a.y+a.h {
			m.cycle(1)
		}
	case tea.MouseWheelMsg:
		if msg.Button == tea.MouseWheelUp {
			m.cycle(-1)
		} else if msg.Button == tea.MouseWheelDown {
			m.cycle(1)
		}
	}
	return nil
}

// ------------------------------------------------------------------ frame

func (m *clockMode) loadPlace() {
	if m.placeSet {
		return
	}
	m.placeSet = true
	m.place, m.hasPlace = engine.LocalCity()
}

// updateSun recomputes sunrise/sunset once per calendar day.
func (m *clockMode) updateSun(now time.Time) {
	m.loadPlace()
	key := now.Year()*1000 + now.YearDay()
	if key == m.sunKey {
		return
	}
	m.sunKey = key
	m.sunRise, m.sunSet, m.sunReal, m.sunPolar = 6, 18, false, 0
	if !m.hasPlace {
		return
	}
	rise, set, polar := engine.ClockSunTimes(now, m.place.Lat, m.place.Lon)
	m.sunPolar = polar
	if polar != 0 {
		m.sunReal = true
		return
	}
	hr := func(t time.Time) float64 {
		t = t.In(now.Location())
		return float64(t.Hour()) + float64(t.Minute())/60
	}
	m.sunRise, m.sunSet, m.sunReal = hr(rise), hr(set), true
}

func (m *clockMode) zoneName(now time.Time) string {
	m.loadPlace()
	if m.hasPlace {
		return m.place.Name(i18n.Lang())
	}
	abbr, off := now.Zone()
	sign := "+"
	if off < 0 {
		sign, off = "-", -off
	}
	return fmt.Sprintf("%s (UTC%s%d)", abbr, sign, off/3600)
}

func (m *clockMode) frame(dt float64) *visual.ClockFrame {
	c := m.c
	now := c.Now
	still := c.Cfg.Motion == "still"
	sub := 0.0
	if !still {
		sub = float64(now.Nanosecond()) / 1e9
	}
	m.updateSun(now)
	dayName := i18n.T(fmt.Sprintf("clock.day.%d", int(now.Weekday())))
	short := i18n.T(fmt.Sprintf("clock.dayshort.%d", int(now.Weekday())))
	month := i18n.T(fmt.Sprintf("clock.month.%d", int(now.Month())-1))
	return &visual.ClockFrame{
		Now: now, Sub: sub, Dt: dt, Time: c.Anim, Pal: c.Pal,
		Font:    braille.ParseFont(c.Cfg.Font),
		Seconds: c.Cfg.ClockSeconds, H24: c.Cfg.Clock24, Still: still,
		Date:      i18n.T("clock.date", dayName, now.Day(), month),
		DateShort: i18n.T("clock.date.short", short, now.Day()),
		Zone:      m.zoneName(now),
		Sunrise:   m.sunRise, Sunset: m.sunSet, SunReal: m.sunReal, Polar: m.sunPolar,
		MoonPhase: engine.ClockMoonPhase(now),
	}
}

// ------------------------------------------------------------------- view

func (m *clockMode) View(w, h int) string {
	if w < 4 || h < 1 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	f := m.frame(m.c.Dt.Seconds())
	m.last = f
	face := m.face
	tiny := h < 8 || w < 30
	if tiny {
		face = visual.NewClockFace("digital")
	}
	wide := w >= 100 && h >= 20 && !tiny
	panelW := 0
	if wide {
		panelW = clampi(w*30/100, 32, 44)
		f.Date, f.Zone = "", "" // the panel carries them
	}
	infoRows := 0
	if !wide && !tiny && h >= 15 && !visual.ClockFaceFills(m.name) {
		infoRows = 2
	}
	areaW, areaH := w-panelW, h-infoRows
	if wide {
		areaW -= 2
	}

	cols, rows := areaW, areaH
	if tiny || visual.ClockFaceFills(face.Name()) {
		cols, rows = mini(areaW, 160), mini(areaH, 46)
	} else {
		rows = mini(areaH, areaW/2)
		cols = rows * 2
	}
	if cols < 2 || rows < 1 {
		cols, rows = maxi(areaW, 1), maxi(areaH, 1)
	}
	if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
		m.canvas = braille.New(cols, rows)
	} else {
		m.canvas.Clear()
	}
	labels := face.Draw(m.canvas, f)
	lines := m.canvas.Lines()
	overlayLabels(lines, labels)

	top, left := (areaH-rows)/2, (areaW-cols)/2
	m.area.x, m.area.y, m.area.w, m.area.h = left, top, cols, rows
	dial := blank(areaW, areaH)
	for i, l := range lines {
		if top+i < areaH {
			dial[top+i] = padRight(spaces(left)+l, areaW)
		}
	}

	var body []string
	if wide {
		body = hcat(dial, blank(2, h), m.panel(f, panelW, h))
	} else {
		body = dial
		if infoRows > 0 {
			body = append(body, m.info(f, w)...)
		}
	}
	return join(fit(body, w, h))
}

func (m *clockMode) info(f *visual.ClockFrame, w int) []string {
	pal := m.c.Pal
	l1 := paint(pal.Muted, f.Date)
	l2 := paint(pal.Faint.Mix(pal.Muted, 0.5), f.Zone)
	if ap := f.AMPM(); ap != "" {
		l2 = bold(pal.Accent, ap) + "  " + l2
	}
	return []string{centerIn(l1, w), centerIn(l2, w)}
}

// panel is the side column of the wide layout.
func (m *clockMode) panel(f *visual.ClockFrame, w, h int) []string {
	c := m.c
	pal := c.Pal
	now := c.Now
	section := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)
	val := lipgloss.NewStyle().Foreground(pal.Text)
	mut := lipgloss.NewStyle().Foreground(pal.Muted)
	acc := lipgloss.NewStyle().Foreground(pal.Accent).Bold(true)

	dayName := i18n.T(fmt.Sprintf("clock.day.%d", int(now.Weekday())))
	month := i18n.T(fmt.Sprintf("clock.month.%d", int(now.Month())-1))
	_, wk := now.ISOWeek()
	timefmt := "15:04"
	if !c.Cfg.Clock24 {
		timefmt = "3:04 PM"
	}

	var rows []string
	rows = append(rows, acc.Render(strings.ToUpper(dayName)))
	rows = append(rows, val.Render(fmt.Sprintf("%d %s %d", now.Day(), month, now.Year())))
	rows = append(rows, mut.Render(i18n.T("clock.week", wk)+" · "+i18n.T("clock.doy", now.YearDay())))
	rows = append(rows, mut.Render("⊕ "+m.zoneName(now)))
	rows = append(rows, "")

	// sun and moon
	if m.sunReal && m.sunPolar == 0 {
		rows = append(rows, section.Render(i18n.T("clock.today")))
		rows = append(rows, lipgloss.NewStyle().Foreground(pal.Sun).Render("↑ ")+val.Render(clockHourText(m.sunRise, c.Cfg.Clock24))+
			"   "+lipgloss.NewStyle().Foreground(pal.Warn).Render("↓ ")+val.Render(clockHourText(m.sunSet, c.Cfg.Clock24)))
		lit := f.MoonPhase
		if lit > 0.5 {
			lit = 1 - lit
		}
		rows = append(rows, lipgloss.NewStyle().Foreground(pal.Moon).Render(clockMoonGlyph(f.MoonPhase)+" ")+mut.Render(i18n.T("clock.moon", int(lit*2*100+0.5))))
		rows = append(rows, "")
	}

	// next alarm
	rows = append(rows, section.Render(i18n.T("clock.next")))
	if a, at := c.Alarms.Next(); a != nil {
		line := val.Render(at.In(now.Location()).Format(timefmt)) + "  " + mut.Render(i18n.T("clock.alarm.in", fmtDur(at.Sub(now).Round(time.Minute))))
		rows = append(rows, line)
		if a.Label != "" {
			rows = append(rows, mut.Render(iconAlarm+" "+a.Label))
		}
	} else {
		rows = append(rows, mut.Render(i18n.T("clock.alarm.none")))
	}
	rows = append(rows, "")

	// a few world clocks
	var city []string
	_, offLocal := now.Zone()
	lang := i18n.Lang()
	for _, id := range c.Cfg.Cities {
		ct, ok := engine.CityByID(id)
		if !ok {
			continue
		}
		if m.hasPlace && ct.ID == m.place.ID {
			continue
		}
		t := now.In(ct.Loc())
		_, off := t.Zone()
		diff := (off - offLocal) / 3600
		dayMark := ""
		switch {
		case t.YearDay() != now.YearDay() && t.After(now):
			dayMark = " +1d"
		case t.YearDay() != now.YearDay():
			dayMark = " −1d"
		}
		name := ct.Name(lang)
		if r := []rune(name); len(r) > 14 {
			name = string(r[:13]) + "…"
		}
		city = append(city, fmt.Sprintf("%s %s %s",
			val.Render(fmt.Sprintf("%-14s", name)),
			lipgloss.NewStyle().Foreground(pal.Text).Bold(true).Render(t.Format(timefmt)),
			mut.Render(fmt.Sprintf("%+dh%s", diff, dayMark))))
		if len(city) == 3 {
			break
		}
	}
	if len(city) > 0 {
		rows = append(rows, section.Render(i18n.T("clock.world")))
		rows = append(rows, city...)
	}

	block := lipgloss.NewStyle().Width(w).Render(strings.Join(rows, "\n"))
	lines := strings.Split(block, "\n")
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

func clockHourText(h float64, h24 bool) string {
	hh := int(h)
	mm := int((h-float64(hh))*60 + 0.5)
	if mm == 60 {
		hh, mm = hh+1, 0
	}
	hh %= 24
	if h24 {
		return fmt.Sprintf("%02d:%02d", hh, mm)
	}
	ap := "AM"
	if hh >= 12 {
		ap = "PM"
	}
	hh %= 12
	if hh == 0 {
		hh = 12
	}
	return fmt.Sprintf("%d:%02d %s", hh, mm, ap)
}

// clockMoonGlyph picks a moon phase emoji-free glyph.
func clockMoonGlyph(p float64) string {
	switch {
	case p < 0.06 || p > 0.94:
		return "●"
	case p < 0.44:
		return "◗"
	case p < 0.56:
		return "○"
	}
	return "◖"
}
