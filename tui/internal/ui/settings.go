package ui

import (
	"os"
	"reflect"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/huh/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// SettingsVersion is shown on the About section; main may overwrite it.
var SettingsVersion = "dev"

func init() {
	registerPage("settings", func(c *Core, say func(string)) Mode { return newSettingsPage(c, say) })
}

// the sections, in nav order
const (
	secRhythm = iota
	secAccent
	secLook
	secClock
	secModes
	secNotify
	secLang
	secData
	secAbout
	secCount
)

type settingsNav struct {
	icon string
	key  string
}

var settingsSections = [secCount]settingsNav{
	secRhythm: {"◔", "settings.sec.rhythm"},
	secAccent: {"◉", "settings.sec.accent"},
	secLook:   {"✦", "settings.sec.look"},
	secClock:  {"◷", "settings.sec.clock"},
	secModes:  {"▤", "settings.sec.modes"},
	secNotify: {"♪", "settings.sec.notify"},
	secLang:   {"∞", "settings.sec.lang"},
	secData:   {"▣", "settings.sec.data"},
	secAbout:  {"❋", "settings.sec.about"},
}

// settingsVals are the values the huh forms edit; sync copies the visible
// section's fields to the config as they change.
type settingsVals struct {
	work, rest, long, cycles int
	auto                     bool
	theme, dial, font        string
	motion                   string
	stars, splash, mouse     bool
	clockDesign              string
	clock24, clockSec        bool
	notify, sound, bell      bool
	lang                     string
}

type settingsPage struct {
	c    *Core
	say  func(string)
	done bool
	t    float64
	dt   float64

	sec    int
	inForm bool
	form   *huh.Form
	fieldN int // fields in the open form, and the focused one
	fieldI int
	descs  []string
	vals   settingsVals
	w, h   int

	// custom sections
	accentCur int
	modes     settingsModes
	dataCur   int
	confirm   int // 0 none, 1 clear history, 2 reset settings
	msg       string
	msgAt     float64

	cvs    map[string]*braille.Canvas
	pv     visual.Visual
	pvName string

	// geometry for the mouse (body-relative)
	navRects    []statsRect
	accentRects []statsRect
	modeRects   []statsRect
	dataRects   []statsRect
	paneX       int
}

func newSettingsPage(c *Core, say func(string)) *settingsPage {
	s := &settingsPage{c: c, say: say, cvs: map[string]*braille.Canvas{}}
	s.loadVals()
	s.accentCur = settingsAccentIndex(c.Cfg.Accent)
	s.modes = newSettingsModes(c)
	return s
}

func (s *settingsPage) ID() string    { return "settings" }
func (s *settingsPage) Done() bool    { return s.done }
func (s *settingsPage) Title() string { return i18n.T("mode.settings") }

func (s *settingsPage) Animated() bool {
	if s.c.Cfg.Motion == "still" {
		return false
	}
	return s.sec == secLook || s.sec == secAccent || s.sec == secAbout || s.msg != ""
}

func (s *settingsPage) Frame(dt time.Duration) {
	s.dt = dt.Seconds()
	if s.c.Cfg.Motion != "still" || s.sec == secAbout {
		s.t += s.dt
	}
	if s.msg != "" && s.t-s.msgAt > 3 {
		s.msg = ""
	}
}

func (s *settingsPage) Capturing() bool { return false }

// Back leaves the form (or a pending confirmation) instead of closing the page.
func (s *settingsPage) Back() bool {
	if s.confirm != 0 {
		s.confirm = 0
		return true
	}
	if s.inForm {
		s.leaveForm()
		return true
	}
	return false
}

func (s *settingsPage) Help() []key.Binding {
	if !s.inForm {
		return []key.Binding{
			kb("up|down|k|j", "↑↓", i18n.T("settings.k.section")),
			kb("enter|right|l|tab", "enter", i18n.T("settings.k.open")),
			kb("esc", "esc", i18n.T("key.back")),
		}
	}
	switch s.sec {
	case secAccent:
		return []key.Binding{kb("left|right|up|down", "←↑↓→", i18n.T("settings.k.pick")), kb("enter|esc", "enter", i18n.T("key.back"))}
	case secModes:
		return []key.Binding{
			kb("up|down", "↑↓", i18n.T("settings.k.pick")), kb("space", "space", i18n.T("settings.k.toggle")),
			kb("shift+up|shift+down|K|J", "⇧↑↓", i18n.T("settings.k.move")), kb("esc", "esc", i18n.T("key.back")),
		}
	case secData:
		return []key.Binding{kb("up|down", "↑↓", i18n.T("settings.k.pick")), kb("enter", "enter", i18n.T("settings.k.run")), kb("esc", "esc", i18n.T("key.back"))}
	case secAbout:
		return []key.Binding{kb("esc", "esc", i18n.T("key.back"))}
	case secNotify:
		return []key.Binding{kb("up|down|tab", "↑↓", i18n.T("settings.k.field")), kb("left|right", "←→", i18n.T("settings.k.change")), kb("t", "t", i18n.T("settings.k.test")), kb("esc", "esc", i18n.T("key.back"))}
	}
	return []key.Binding{kb("tab|shift+tab", "tab", i18n.T("settings.k.field")), kb("left|right|up|down", "←→", i18n.T("settings.k.change")), kb("esc", "esc", i18n.T("key.back"))}
}

func (s *settingsPage) loadVals() {
	c := s.c.Cfg
	s.vals = settingsVals{
		work: c.Work, rest: c.Rest, long: c.Long, cycles: c.Cycles, auto: c.AutoNext,
		theme: c.Theme, dial: c.Dial, font: c.Font, motion: c.Motion,
		stars: c.Stars, splash: c.Splash, mouse: c.Mouse,
		clockDesign: c.ClockDesign, clock24: c.Clock24, clockSec: c.ClockSeconds,
		notify: c.Notify, sound: c.Sound, bell: c.Bell, lang: c.Lang,
	}
}

// sync copies the edited section's values into the config and applies it.
func (s *settingsPage) sync() {
	n := s.c.Cfg
	v := s.vals
	switch s.sec {
	case secRhythm:
		n.Work, n.Rest, n.Long, n.Cycles, n.AutoNext = v.work, v.rest, v.long, v.cycles, v.auto
	case secLook:
		n.Theme, n.Dial, n.Font, n.Motion = v.theme, v.dial, v.font, v.motion
		n.Stars, n.Splash, n.Mouse = v.stars, v.splash, v.mouse
	case secClock:
		n.ClockDesign, n.Clock24, n.ClockSeconds = v.clockDesign, v.clock24, v.clockSec
	case secNotify:
		n.Notify, n.Sound, n.Bell = v.notify, v.sound, v.bell
	case secLang:
		n.Lang = v.lang
	}
	s.applyCfg(n)
}

func (s *settingsPage) applyCfg(n store.Config) {
	if reflect.DeepEqual(n, s.c.Cfg) {
		return
	}
	s.c.Cfg = n
	s.c.ApplyConfig()
}

func (s *settingsPage) flash(text string) {
	s.msg, s.msgAt = text, s.t
	if s.say != nil {
		s.say(text)
	}
}

func (s *settingsPage) cv(name string, cols, rows int) *braille.Canvas {
	cv := s.cvs[name]
	if cv == nil {
		cv = braille.New(cols, rows)
		s.cvs[name] = cv
		return cv
	}
	cv.Resize(cols, rows)
	return cv
}

// ------------------------------------------------------------------ input

func (s *settingsPage) enter() {
	s.inForm = true
	s.confirm = 0
	s.form = s.buildForm()
	if s.form != nil {
		s.form.Init()
		s.form.Update(tea.BackgroundColorMsg{Color: s.c.Pal.Bg})
	}
	switch s.sec {
	case secAccent:
		s.accentCur = settingsAccentIndex(s.c.Cfg.Accent)
	case secModes:
		s.modes = newSettingsModes(s.c)
	case secAbout:
		s.t = 0
	}
}

func (s *settingsPage) leaveForm() {
	s.inForm = false
	s.form = nil
	s.confirm = 0
}

func (s *settingsPage) Update(msg tea.Msg) tea.Cmd {
	switch m := msg.(type) {
	case tea.MouseClickMsg:
		if m.Button == tea.MouseLeft {
			s.click(m.X, m.Y)
		}
		return nil
	case tea.MouseWheelMsg:
		k := tea.KeyPressMsg{Code: tea.KeyDown}
		if m.Button == tea.MouseWheelUp {
			k = tea.KeyPressMsg{Code: tea.KeyUp}
		}
		return s.Update(k)
	case tea.KeyPressMsg:
		if !s.inForm {
			return s.navKey(m)
		}
		switch s.sec {
		case secAccent:
			s.accentKey(m)
		case secModes:
			s.modesKey(m)
		case secData:
			s.dataKey(m)
		case secAbout:
			if m.String() == "enter" {
				s.leaveForm()
			}
		default:
			if s.sec == secNotify && m.String() == "t" {
				s.testNotify()
				return nil
			}
			s.formKey(m)
		}
	}
	return nil
}

func (s *settingsPage) navKey(m tea.KeyPressMsg) tea.Cmd {
	switch m.String() {
	case "up", "k":
		s.sec = (s.sec + secCount - 1) % secCount
	case "down", "j":
		s.sec = (s.sec + 1) % secCount
	case "home", "g":
		s.sec = 0
	case "end", "G":
		s.sec = secCount - 1
	case "enter", "right", "l", "tab", "space":
		s.enter()
	}
	return nil
}

func (s *settingsPage) click(x, y int) {
	if !s.inForm || s.w < 76 {
		for i, r := range s.navRects {
			if r.in(x, y) {
				if s.sec == i && !s.inForm {
					s.enter()
				} else {
					s.sec = i
					if s.inForm {
						s.leaveForm()
						s.enter()
					}
				}
				return
			}
		}
	} else {
		for i, r := range s.navRects {
			if r.in(x, y) {
				s.leaveForm()
				s.sec = i
				s.enter()
				return
			}
		}
	}
	if !s.inForm {
		return
	}
	switch s.sec {
	case secAccent:
		for i, r := range s.accentRects {
			if r.in(x, y) {
				s.accentCur = i
				s.applyAccent()
				return
			}
		}
	case secModes:
		for i, r := range s.modeRects {
			if r.in(x, y) {
				s.modes.cur = i
				s.modes.toggle(s)
				return
			}
		}
	case secData:
		for i, r := range s.dataRects {
			if r.in(x, y) {
				s.dataCur = i
				s.dataRun()
				return
			}
		}
	}
}

// ------------------------------------------------------------------- view

func (s *settingsPage) View(w, h int) string {
	s.w, s.h = w, h
	s.navRects = s.navRects[:0]
	s.accentRects, s.modeRects, s.dataRects = s.accentRects[:0], s.modeRects[:0], s.dataRects[:0]
	if w < 20 || h < 5 {
		return s.tiny(w, h)
	}
	wide := w >= 76
	var lines []string
	switch {
	case wide:
		navW := 22
		nav := s.navView(navW, h)
		pane := s.paneView(w-navW-3, h)
		s.paneX = navW + 3
		lines = hcat(nav, sepLines(s.c.Pal.Faint, h), pane)
	case s.inForm:
		s.paneX = 0
		lines = s.paneView(w, h)
	default:
		s.paneX = 0
		lines = s.navView(w, h)
	}
	return join(fit(lines, w, h))
}

func sepLines(col braille.RGB, h int) []string {
	out := make([]string, h)
	for i := range out {
		out[i] = paint(col, " ⢸ ")
	}
	return out
}

func (s *settingsPage) tiny(w, h int) string {
	pal := s.c.Pal
	out := blank(maxi(w, 0), maxi(h, 0))
	if h > 0 && w > 0 {
		out[h/2] = centerIn(bold(pal.Accent, "⚙ "+i18n.T("mode.settings")), w)
	}
	return join(out)
}

// navView is the section list.
func (s *settingsPage) navView(w, h int) []string {
	pal := s.c.Pal
	out := []string{padRight(" "+bold(pal.Accent, "▍")+bold(pal.Text, strings.ToUpper(i18n.T("mode.settings"))), w), spaces(w)}
	for i, sec := range settingsSections {
		label := i18n.T(sec.key)
		var line string
		if i == s.sec {
			bar := bold(pal.Accent, "▎")
			col := pal.Text
			if s.inForm && w >= 76 {
				col = pal.Muted
			}
			line = bar + " " + paint(pal.Accent, sec.icon) + " " + bold(col, label)
		} else {
			line = " " + " " + paint(pal.Muted, sec.icon) + " " + paint(pal.Muted, label)
		}
		s.navRects = append(s.navRects, statsRect{x: 0, y: len(out), w: w, h: 1})
		out = append(out, padRight(line, w))
	}
	if s.msg != "" && h > len(out)+2 {
		out = append(out, spaces(w), padRight(" "+paint(pal.Good, "✓ "+s.msg), w))
	}
	return fit(out, w, h)
}

// paneView draws the open (or hovered) section.
func (s *settingsPage) paneView(w, h int) []string {
	pal := s.c.Pal
	sec := settingsSections[s.sec]
	title := bold(pal.Accent, sec.icon+"  ") + bold(pal.Text, i18n.T(sec.key))
	desc := paint(pal.Muted, i18n.T(sec.key+".d"))
	head := []string{padRight(title, w), padRight(desc, w), spaces(w)}
	bodyH := h - len(head)
	var body []string
	if !s.inForm {
		body = s.peek(w, bodyH)
	} else {
		body = s.sectionBody(w, bodyH)
	}
	return fit(append(head, body...), w, h)
}

func (s *settingsPage) sectionBody(w, h int) []string {
	switch s.sec {
	case secAccent:
		return s.accentView(w, h)
	case secModes:
		return s.modesView(w, h)
	case secData:
		return s.dataView(w, h)
	case secAbout:
		return s.aboutView(w, h)
	}
	return s.formView(w, h)
}

// peek is what the pane shows while the nav has focus: a quiet summary.
func (s *settingsPage) peek(w, h int) []string {
	pal := s.c.Pal
	cfg := s.c.Cfg
	var rows []string
	add := func(k, v string) {
		rows = append(rows, padRight(paint(pal.Muted, padRight(i18n.T(k), 22))+paint(pal.Text, v), w))
	}
	switch s.sec {
	case secRhythm:
		add("settings.work", itoa(cfg.Work)+" min")
		add("settings.rest", itoa(cfg.Rest)+" min")
		add("settings.long", itoa(cfg.Long)+" min")
		add("settings.cycles", settingsCycles(cfg.Cycles))
		add("settings.auto", settingsOnOff(cfg.AutoNext))
	case secAccent:
		return s.accentPeek(w, h)
	case secLook:
		add("settings.theme", i18n.T("settings.theme."+cfg.Theme))
		add("settings.dial", cfg.Dial)
		add("settings.font", cfg.Font)
		add("settings.motion", i18n.T("settings.motion."+cfg.Motion))
		add("settings.stars", settingsOnOff(cfg.Stars))
		add("settings.splash", settingsOnOff(cfg.Splash))
		add("settings.mouse", settingsOnOff(cfg.Mouse))
		rows = append(rows, spaces(w))
		rows = append(rows, s.dialPreview(w, h-len(rows))...)
	case secClock:
		add("settings.clock.design", settingsClockName(cfg.ClockDesign))
		add("settings.clock.24", settingsOnOff(cfg.Clock24))
		add("settings.clock.sec", settingsOnOff(cfg.ClockSeconds))
	case secModes:
		var names []string
		for _, id := range cfg.Modes {
			names = append(names, i18n.T("mode."+id))
		}
		rows = append(rows, padRight(paint(pal.Text, strings.Join(names, " · ")), w))
	case secNotify:
		add("settings.notify", settingsOnOff(cfg.Notify))
		add("settings.sound", settingsOnOff(cfg.Sound))
		add("settings.bell", settingsOnOff(cfg.Bell))
	case secLang:
		add("settings.lang", settingsLangName(i18n.Lang())+" ("+cfg.Lang+")")
	case secData:
		rows = append(rows, padRight(paint(pal.Muted, s.c.Store.ConfigPath()), w), padRight(paint(pal.Muted, s.c.Store.StatePath()), w))
	case secAbout:
		return s.aboutView(w, h)
	}
	rows = append(rows, spaces(w), padRight(paint(pal.Faint, i18n.T("settings.peek.hint")), w))
	return fit(rows, w, h)
}

func settingsOnOff(b bool) string {
	if b {
		return i18n.T("settings.on")
	}
	return i18n.T("settings.off")
}

func settingsCycles(n int) string {
	if n == 0 {
		return i18n.T("settings.cycles.off")
	}
	return itoa(n)
}

func settingsLangName(code string) string {
	for _, l := range i18n.Languages {
		if l.Code == code {
			return l.Name
		}
	}
	return code
}

func settingsClockName(id string) string {
	if k := "settings.clock." + id; i18n.Has("en", k) {
		return i18n.T(k)
	}
	return id
}

// ---------------------------------------------------------------- actions

func (s *settingsPage) testNotify() {
	s.notifyTest()
	s.flash(i18n.T("settings.tested"))
}

var _ = os.Getenv
