package ui

import (
	"fmt"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
)

func init() {
	registerMode("event", func(c *Core, say func(string)) Mode { return newEventMode(c, say) })
}

const eventKind = engine.Kind("event")

type eventMode struct {
	c   *Core
	say func(string)
	st  *eventStore

	selID      int
	confirmDel int
	form       *eventForm

	canvas   *braille.Canvas
	shimmer  *anim.Particles
	confetti *anim.Particles
	t        float64
	pulse    float64
	burst    bool
	emit     float64

	// hit areas, relative to the body
	list struct{ x, y, w, rows, first int }
	hero struct{ x, y, w, h int }
	ids  []int // item ids by visible list row
}

func newEventMode(c *Core, say func(string)) *eventMode {
	m := &eventMode{c: c, say: say, st: eventOpen(c.Store.StateDir),
		shimmer: anim.NewParticles(11), confetti: anim.NewParticles(13)}
	m.shimmer.Gravity = -2
	if len(m.st.data.Items) > 0 {
		m.selID = eventSorted(m.st.data.Items, c.Now)[0].Item.ID
	}
	return m
}

func (m *eventMode) ID() string     { return "event" }
func (m *eventMode) Animated() bool { return m.c.Cfg.Motion != "still" }
func (m *eventMode) Capturing() bool {
	return m.form != nil || m.confirmDel != 0
}

// ---------------------------------------------------------------- background

func (m *eventMode) Step(now time.Time, dt time.Duration) []Announce {
	notes, changed := eventCheck(m.st.data.Items, now)
	if changed {
		m.st.save()
	}
	var out []Announce
	for _, n := range notes {
		if n.Arrived {
			m.pulse, m.burst = 1, true
			m.selID = n.Item.ID
			out = append(out, Announce{Kind: eventKind, Title: i18n.T("event.arrived", n.Item.Name),
				Body: eventDateText(n.Occurs, true)})
			m.c.Log(engine.Event{Kind: eventKind, Label: n.Item.Name, Start: n.Occurs, Completed: true})
		} else {
			out = append(out, Announce{Kind: eventKind, Title: i18n.T("event.reminder", n.Item.Name),
				Body: i18n.T("event.reminder.body", n.Occurs.Format("15:04"))})
		}
	}
	return out
}

func (m *eventMode) Runner() *Running {
	if len(m.st.data.Items) == 0 {
		return nil
	}
	vs := eventSorted(m.st.data.Items, m.c.Now)
	v := vs[0]
	if v.Arrived {
		return &Running{Icon: iconEvent, Text: i18n.T("event.now")}
	}
	if v.Past {
		return nil
	}
	if v.Left > 7*24*time.Hour {
		return nil
	}
	return &Running{Icon: iconEvent, Text: eventShort(v.Left)}
}

func (m *eventMode) Title() string {
	v, ok := m.selected()
	if !ok || v.Past {
		return ""
	}
	return iconEvent + " " + eventShort(v.Left) + " " + v.Item.Name
}

func (m *eventMode) Frame(dt time.Duration) {
	s := dt.Seconds()
	m.t += s
	if m.pulse > 0 {
		m.pulse = maxf(0, m.pulse-s/1.2)
	}
	m.shimmer.Step(s)
	m.confetti.Step(s)
	if m.canvas != nil && m.c.Cfg.Motion != "still" {
		m.emit += s
		for m.emit > 0.14 {
			m.emit -= 0.14
			r := float64(minI(m.canvas.W, m.canvas.H)) / 2 * 0.9
			a := m.shimmer.Rand() * 6.283
			x, y := braille.Polar(float64(m.canvas.W)/2, float64(m.canvas.H)/2, r*(0.8+0.3*m.shimmer.Rand()), a)
			main, _ := m.tintFor()
			m.shimmer.Emit(anim.Particle{X: x, Y: y, VX: (m.shimmer.Rand() - 0.5) * 3, VY: -6 - 6*m.shimmer.Rand(),
				Life: 2.2, Max: 2.2, Col: main, Size: 0.5, Drag: 0.2})
		}
	}
	if m.burst && m.canvas != nil {
		m.burst = false
		cx, cy := float64(m.canvas.W)/2, float64(m.canvas.H)/2
		p := m.c.Pal
		cols := []braille.RGB{p.Accent, p.Bright, p.Rest, p.RestHi, p.Sun, p.Text}
		for i := 0; i < 3; i++ {
			m.confetti.Burst(cx, cy, 60, float64(minI(m.canvas.W, m.canvas.H))*0.6, cols)
		}
	}
}

func maxf(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}

func minI(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func (m *eventMode) tintFor() (braille.RGB, braille.RGB) {
	idx := 0
	if v, ok := m.selected(); ok {
		idx = v.Item.Accent
	}
	return eventTint(m.c.Pal, idx)
}

func (m *eventMode) selected() (eventView, bool) {
	if it := m.st.find(m.selID); it != nil {
		return eventResolve(it, m.c.Now), true
	}
	return eventView{}, false
}

func (m *eventMode) Help() []key.Binding {
	if m.form != nil {
		return []key.Binding{
			kb("enter", "enter", i18n.T("event.save")),
			kb("tab", "tab", i18n.T("event.field")),
			kb("up|down", "↑↓", i18n.T("event.adjust")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	}
	if m.confirmDel != 0 {
		return []key.Binding{kb("y", "y", i18n.T("event.yes")), kb("n|esc", "n", i18n.T("event.no"))}
	}
	return []key.Binding{
		kb("up|k", "↑↓", i18n.T("key.select")),
		kb("n", "n", i18n.T("event.new")),
		kb("e|enter", "e", i18n.T("event.edit")),
		kb("x", "x", i18n.T("event.delete")),
		kb("c", "c", i18n.T("event.color")),
	}
}

// ---------------------------------------------------------------- input

func (m *eventMode) Update(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		if m.form != nil {
			return m.updateForm(msg)
		}
		if m.confirmDel != 0 {
			switch msg.String() {
			case "y", "Y", "enter":
				m.st.remove(m.confirmDel)
				m.st.save()
				m.confirmDel = 0
				m.selectNear()
			case "n", "N", "esc", "q":
				m.confirmDel = 0
			}
			return nil
		}
		switch msg.String() {
		case "up", "k":
			m.move(-1)
		case "down", "j":
			m.move(1)
		case "n":
			m.form = m.newForm(nil)
			return m.form.name.Focus()
		case "e", "enter":
			if v, ok := m.selected(); ok {
				m.form = m.newForm(v.Item)
				return m.form.name.Focus()
			}
		case "x", "delete":
			if _, ok := m.selected(); ok {
				m.confirmDel = m.selID
			}
		case "c":
			if it := m.st.find(m.selID); it != nil {
				it.Accent = (it.Accent + 1) % 6
				m.st.save()
			}
		}
	case tea.MouseClickMsg:
		if m.form != nil || m.confirmDel != 0 || msg.Button != tea.MouseLeft {
			return nil
		}
		l := m.list
		if msg.X >= l.x && msg.X < l.x+l.w && msg.Y >= l.y && msg.Y < l.y+l.rows {
			if i := msg.Y - l.y; i < len(m.ids) {
				m.selID = m.ids[i]
			}
		}
	case tea.MouseWheelMsg:
		if m.form != nil || m.confirmDel != 0 {
			return nil
		}
		if msg.Button == tea.MouseWheelUp {
			m.move(-1)
		} else if msg.Button == tea.MouseWheelDown {
			m.move(1)
		}
	}
	return nil
}

func (m *eventMode) move(d int) {
	vs := eventSorted(m.st.data.Items, m.c.Now)
	if len(vs) == 0 {
		return
	}
	idx := 0
	for i, v := range vs {
		if v.Item.ID == m.selID {
			idx = i
		}
	}
	idx = clampi(idx+d, 0, len(vs)-1)
	m.selID = vs[idx].Item.ID
}

func (m *eventMode) selectNear() {
	vs := eventSorted(m.st.data.Items, m.c.Now)
	if len(vs) == 0 {
		m.selID = 0
		return
	}
	m.selID = vs[0].Item.ID
}

// ---------------------------------------------------------------- the form

type eventForm struct {
	id     int // 0 = new
	name   textinput.Model
	at     time.Time
	yearly bool
	focus  int // 0 name, 1 year, 2 month, 3 day, 4 hour, 5 minute, 6 yearly
}

const eventFieldCount = 7

func (m *eventMode) newForm(it *eventItem) *eventForm {
	ti := textinput.New()
	ti.Prompt = ""
	ti.CharLimit = 40
	ti.SetVirtualCursor(true)
	st := ti.Styles()
	st.Cursor.Blink = false
	st.Focused.Text = st.Focused.Text.Foreground(m.c.Pal.Text)
	st.Focused.Placeholder = st.Focused.Placeholder.Foreground(m.c.Pal.Faint)
	st.Blurred.Text = st.Blurred.Text.Foreground(m.c.Pal.Text)
	st.Blurred.Placeholder = st.Blurred.Placeholder.Foreground(m.c.Pal.Faint)
	st.Cursor.Color = m.c.Pal.Accent
	ti.SetStyles(st)
	ti.Placeholder = i18n.T("event.name.hint")
	f := &eventForm{name: ti}
	now := m.c.Now
	if it != nil {
		f.id = it.ID
		f.name.SetValue(it.Name)
		f.at = it.At.In(now.Location())
		f.yearly = it.Yearly
	} else {
		d := now.AddDate(0, 0, 7)
		f.at = time.Date(d.Year(), d.Month(), d.Day(), 9, 0, 0, 0, now.Location())
	}
	return f
}

func (f *eventForm) setFocus(n int) tea.Cmd {
	n = ((n % eventFieldCount) + eventFieldCount) % eventFieldCount
	f.focus = n
	if n == 0 {
		return f.name.Focus()
	}
	f.name.Blur()
	return nil
}

// adjust moves one date/time field by delta (days clamp to the month).
func (f *eventForm) adjust(delta int) {
	t := f.at
	y, mo, d, h, mi := t.Year(), int(t.Month()), t.Day(), t.Hour(), t.Minute()
	switch f.focus {
	case 1:
		y = clampi(y+delta, 1971, 2100)
	case 2:
		mo = (mo-1+delta+120)%12 + 1
	case 3:
		dim := eventDaysInMonth(y, time.Month(mo))
		d = (d-1+delta+dim*40)%dim + 1
	case 4:
		h = (h + delta + 240) % 24
	case 5:
		mi = (mi + delta + 600) % 60
	case 6:
		f.yearly = !f.yearly
		return
	}
	if dim := eventDaysInMonth(y, time.Month(mo)); d > dim {
		d = dim
	}
	f.at = time.Date(y, time.Month(mo), d, h, mi, 0, 0, t.Location())
}

func (m *eventMode) updateForm(msg tea.KeyPressMsg) tea.Cmd {
	f := m.form
	switch s := msg.String(); s {
	case "esc":
		m.form = nil
		return nil
	case "ctrl+s":
		m.saveForm()
		return nil
	case "tab":
		return f.setFocus(f.focus + 1)
	case "shift+tab":
		return f.setFocus(f.focus - 1)
	}
	if f.focus == 0 {
		switch msg.String() {
		case "enter", "down":
			return f.setFocus(1)
		}
		var cmd tea.Cmd
		f.name, cmd = f.name.Update(msg)
		return cmd
	}
	switch msg.String() {
	case "enter":
		m.saveForm()
	case "up", "k", "+", "=":
		f.adjust(1)
	case "down", "j", "-", "_":
		f.adjust(-1)
	case "pgup":
		f.adjust(10)
	case "pgdown":
		f.adjust(-10)
	case "left", "h":
		return f.setFocus(f.focus - 1)
	case "right", "l":
		return f.setFocus(f.focus + 1)
	case "space":
		if f.focus == 6 {
			f.yearly = !f.yearly
		}
	case "y":
		if f.focus == 6 {
			f.yearly = true
		}
	case "n":
		if f.focus == 6 {
			f.yearly = false
		}
	}
	return nil
}

func (m *eventMode) saveForm() {
	f := m.form
	name := strings.TrimSpace(f.name.Value())
	if name == "" {
		name = i18n.T("event.default")
	}
	now := m.c.Now
	if f.id == 0 {
		id := m.st.add(eventItem{Name: name, At: f.at, Yearly: f.yearly, Created: now})
		it := m.st.find(id)
		it.Accent = id % 6
		m.selID = id
	} else if it := m.st.find(f.id); it != nil {
		changedDate := !it.At.Equal(f.at)
		it.Name, it.At, it.Yearly = name, f.at, f.yearly
		it.Reminded = time.Time{}
		if changedDate && !it.Created.Before(it.At) {
			it.Created = now
		}
		m.selID = it.ID
	}
	m.st.save()
	m.form = nil
	m.say(i18n.T("event.saved", name))
}

// ---------------------------------------------------------------- text helpers

var eventEsWeekday = [...]string{"domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"}

// eventDateText is "Saturday 25 Oct" (with the year when asked).
func eventDateText(t time.Time, withYear bool) string {
	var s string
	if i18n.Lang() == "es" {
		s = eventEsWeekday[t.Weekday()] + " " + itoa(t.Day()) + " " + esMonths[t.Month()-1]
		if withYear {
			s += " " + itoa(t.Year())
		}
		return s
	}
	s = t.Format("Monday 2 Jan")
	if withYear {
		s += t.Format(" 2006")
	}
	return s
}

// eventShort is the compact distance: 23d, 4h 12m, 12m, 45s.
func eventShort(d time.Duration) string {
	if d < 0 {
		d = -d
	}
	days, h, m, s := eventParts(d)
	switch {
	case days >= 2:
		return itoa(days) + "d"
	case days == 1:
		return "1d " + pad2(h) + "h"
	case h > 0:
		return itoa(h) + "h " + pad2(m) + "m"
	case m > 0:
		return itoa(m) + "m"
	}
	return itoa(s) + "s"
}

// eventLong is the spoken distance: 23 days, 3 days 4 h, 5 h 12 min.
func eventLong(d time.Duration) string {
	if d < 0 {
		d = -d
	}
	days, h, m, s := eventParts(d)
	var parts []string
	unit := func(n int, one, many string) string {
		if n == 1 {
			return i18n.T(one, n)
		}
		return i18n.T(many, n)
	}
	switch {
	case days >= 7:
		parts = append(parts, unit(days, "event.u.day", "event.u.days"))
	case days >= 1:
		parts = append(parts, unit(days, "event.u.day", "event.u.days"))
		if h > 0 {
			parts = append(parts, i18n.T("event.u.h", h))
		}
	case h > 0:
		parts = append(parts, i18n.T("event.u.h", h))
		if m > 0 {
			parts = append(parts, i18n.T("event.u.min", m))
		}
	case m > 0:
		parts = append(parts, i18n.T("event.u.min", m))
	default:
		parts = append(parts, i18n.T("event.u.s", s))
	}
	return strings.Join(parts, " ")
}

// eventCaption is the line under the hero: "in 23 days · Saturday 25 Oct".
func eventCaption(v eventView, now time.Time) string {
	date := eventDateText(v.Target, v.Target.Year() != now.Year() || v.Past)
	switch {
	case v.Arrived:
		return date
	case v.Past:
		return i18n.T("event.ago", eventLong(v.Left)) + " · " + date
	}
	return i18n.T("event.in", eventLong(v.Left)) + " · " + date
}

var _ = fmt.Sprint
var _ = notify.SoundDone
