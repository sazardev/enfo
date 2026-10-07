package ui

import (
	"fmt"
	"sort"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/huh/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// settingsHuhTheme paints huh's fields with the app palette. huh asks for the
// styles on every render, so a live accent change re-colors the form at once.
func settingsHuhTheme(c *Core) huh.Theme {
	return huh.ThemeFunc(func(isDark bool) *huh.Styles {
		p := c.Pal
		t := huh.ThemeBase(isDark)
		focusBase := lipgloss.NewStyle().PaddingLeft(1).
			Border(lipgloss.Border{Left: "▎"}, false, false, false, true).BorderForeground(p.Accent)
		blurBase := lipgloss.NewStyle().PaddingLeft(1).
			Border(lipgloss.Border{Left: "▏"}, false, false, false, true).BorderForeground(p.Faint)
		t.FieldSeparator = lipgloss.NewStyle().SetString("\n")

		f := &t.Focused
		f.Base, f.Card = focusBase, focusBase
		f.Title = lipgloss.NewStyle().Foreground(p.Accent).Bold(true)
		f.NoteTitle = f.Title
		f.Description = lipgloss.NewStyle().Foreground(p.Muted)
		f.SelectSelector = lipgloss.NewStyle().Foreground(p.Accent).SetString("▸ ")
		f.Option = lipgloss.NewStyle().Foreground(p.Text)
		f.SelectedOption = lipgloss.NewStyle().Foreground(p.Accent).Bold(true)
		f.NextIndicator = lipgloss.NewStyle().Foreground(p.Accent).MarginLeft(1).SetString("›")
		f.PrevIndicator = lipgloss.NewStyle().Foreground(p.Accent).MarginRight(1).SetString("‹")
		f.FocusedButton = lipgloss.NewStyle().Padding(0, 2).MarginRight(1).Foreground(p.Bg).Background(p.Accent).Bold(true)
		f.BlurredButton = lipgloss.NewStyle().Padding(0, 2).MarginRight(1).Foreground(p.Text).Background(p.Bg.Mix(p.Text, 0.14))
		f.ErrorIndicator = lipgloss.NewStyle().Foreground(p.Bad).SetString(" *")
		f.ErrorMessage = lipgloss.NewStyle().Foreground(p.Bad).SetString(" *")
		f.SelectedPrefix = lipgloss.NewStyle().Foreground(p.Accent).SetString("◉ ")
		f.UnselectedPrefix = lipgloss.NewStyle().Foreground(p.Muted).SetString("○ ")
		f.UnselectedOption = lipgloss.NewStyle().Foreground(p.Text)
		f.TextInput.Cursor = lipgloss.NewStyle().Foreground(p.Accent)
		f.TextInput.Prompt = lipgloss.NewStyle().Foreground(p.Accent)
		f.TextInput.Placeholder = lipgloss.NewStyle().Foreground(p.Faint)
		f.TextInput.Text = lipgloss.NewStyle().Foreground(p.Text)

		t.Blurred = t.Focused
		b := &t.Blurred
		b.Base, b.Card = blurBase, blurBase
		b.Title = lipgloss.NewStyle().Foreground(p.Muted)
		b.NoteTitle = b.Title
		b.SelectedOption = lipgloss.NewStyle().Foreground(p.Text)
		b.Description = lipgloss.NewStyle().Foreground(p.Faint)
		b.NextIndicator = lipgloss.NewStyle()
		b.PrevIndicator = lipgloss.NewStyle()
		b.SelectSelector = lipgloss.NewStyle().SetString("  ")

		t.Group.Title = f.Title
		t.Group.Description = f.Description
		return t
	})
}

func settingsIntOpts(cur int, vals []int, label func(int) string) []huh.Option[int] {
	has := false
	for _, v := range vals {
		if v == cur {
			has = true
		}
	}
	if !has {
		vals = append(append([]int{}, vals...), cur)
		sort.Ints(vals)
	}
	opts := make([]huh.Option[int], len(vals))
	for i, v := range vals {
		opts[i] = huh.NewOption(label(v), v)
	}
	return opts
}

func settingsMin(n int) string { return fmt.Sprintf("%d min", n) }

// settingsToggle is an On/Off switch drawn like every other inline choice.
func settingsToggle(title, desc string, v *bool) settingsFld {
	return settingsSel(title, desc, v, []huh.Option[bool]{
		huh.NewOption(i18n.T("settings.on"), true), huh.NewOption(i18n.T("settings.off"), false)})
}

// settingsFld is a form field plus the description shown under the form while
// it has focus (huh would show every description at once, which is noisy).
type settingsFld struct {
	f    huh.Field
	desc string
}

func settingsSel[T comparable](title, desc string, v *T, opts []huh.Option[T]) settingsFld {
	return settingsFld{huh.NewSelect[T]().Title(title).Options(opts...).Value(v).Inline(true), desc}
}

func settingsStrOpts(ids []string, keyPrefix string) []huh.Option[string] {
	opts := make([]huh.Option[string], len(ids))
	for i, id := range ids {
		label := id
		if k := keyPrefix + id; i18n.Has("en", k) {
			label = i18n.T(k)
		}
		opts[i] = huh.NewOption(label, id)
	}
	return opts
}

// settingsClockDesigns are the clock faces the Clock mode offers.
var settingsClockDesigns = []string{"analog", "digital", "orbit", "binary", "sun"}

func (s *settingsPage) formWidth() int {
	w := s.w - 4
	if s.w >= 76 {
		w = s.w - 22 - 3
	}
	if s.sec == secLook || s.sec == secRhythm {
		w = mini(w, 44)
	}
	return clampi(w, 20, 64)
}

// buildForm makes the huh form for the open section (nil for custom ones).
func (s *settingsPage) buildForm() *huh.Form {
	v := &s.vals
	s.loadVals()
	var flds []settingsFld
	switch s.sec {
	case secRhythm:
		flds = []settingsFld{
			settingsSel(i18n.T("settings.work"), i18n.T("settings.work.d"), &v.work,
				settingsIntOpts(v.work, []int{10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 75, 90, 120}, settingsMin)),
			settingsSel(i18n.T("settings.rest"), i18n.T("settings.rest.d"), &v.rest,
				settingsIntOpts(v.rest, []int{1, 2, 3, 5, 7, 10, 15, 20}, settingsMin)),
			settingsSel(i18n.T("settings.long"), i18n.T("settings.long.d"), &v.long,
				settingsIntOpts(v.long, []int{10, 15, 20, 25, 30, 45, 60}, settingsMin)),
			settingsSel(i18n.T("settings.cycles"), i18n.T("settings.cycles.d"), &v.cycles,
				settingsIntOpts(v.cycles, []int{0, 2, 3, 4, 5, 6, 8}, settingsCycles)),
			settingsToggle(i18n.T("settings.auto"), i18n.T("settings.auto.d"), &v.auto),
		}
	case secLook:
		flds = []settingsFld{
			settingsSel(i18n.T("settings.theme"), i18n.T("settings.theme.d"), &v.theme,
				settingsStrOpts([]string{"auto", "dark", "light"}, "settings.theme.")),
			settingsSel(i18n.T("settings.dial"), i18n.T("settings.dial.d"), &v.dial,
				settingsStrOpts(visual.DialNames(), "settings.dial.")),
			settingsSel(i18n.T("settings.font"), i18n.T("settings.font.d"), &v.font,
				settingsStrOpts([]string{"line", "led", "seg"}, "settings.font.")),
			settingsSel(i18n.T("settings.motion"), i18n.T("settings.motion.d"), &v.motion,
				settingsStrOpts([]string{"full", "calm", "still"}, "settings.motion.")),
			settingsToggle(i18n.T("settings.stars"), i18n.T("settings.stars.d"), &v.stars),
			settingsToggle(i18n.T("settings.splash"), i18n.T("settings.splash.d"), &v.splash),
			settingsToggle(i18n.T("settings.mouse"), i18n.T("settings.mouse.d"), &v.mouse),
		}
	case secClock:
		flds = []settingsFld{
			settingsSel(i18n.T("settings.clock.design"), i18n.T("settings.clock.design.d"), &v.clockDesign,
				settingsStrOpts(settingsClockDesigns, "settings.clock.")),
			settingsToggle(i18n.T("settings.clock.24"), i18n.T("settings.clock.24.d"), &v.clock24),
			settingsToggle(i18n.T("settings.clock.sec"), i18n.T("settings.clock.sec.d"), &v.clockSec),
		}
	case secNotify:
		flds = []settingsFld{
			settingsToggle(i18n.T("settings.notify"), i18n.T("settings.notify.d"), &v.notify),
			settingsToggle(i18n.T("settings.sound"), i18n.T("settings.sound.d"), &v.sound),
			settingsToggle(i18n.T("settings.bell"), i18n.T("settings.bell.d"), &v.bell),
		}
	case secLang:
		opts := []huh.Option[string]{huh.NewOption(i18n.T("settings.lang.auto"), "auto")}
		for _, l := range i18n.Languages {
			opts = append(opts, huh.NewOption(l.Name, l.Code))
		}
		flds = []settingsFld{{huh.NewSelect[string]().Title(i18n.T("settings.lang")).Options(opts...).Value(&v.lang), i18n.T("settings.lang.d")}}
	default:
		return nil
	}
	fields := make([]huh.Field, len(flds))
	s.descs = s.descs[:0]
	for i, f := range flds {
		fields[i] = f.f
		s.descs = append(s.descs, f.desc)
	}
	s.fieldN, s.fieldI = len(fields), 0
	fh := clampi(3*len(fields)-1, 4, 60)
	return huh.NewForm(huh.NewGroup(fields...)).
		WithShowHelp(false).WithShowErrors(false).
		WithTheme(settingsHuhTheme(s.c)).
		WithWidth(s.formWidth()).WithHeight(fh)
}

// settingsRun executes a command the way the runtime would and returns the
// messages it produced. Slow commands (cursor blinks, timers) are dropped:
// huh's own focus moves are instant.
func settingsRun(cmd tea.Cmd, depth int) []tea.Msg {
	if cmd == nil || depth > 4 {
		return nil
	}
	ch := make(chan tea.Msg, 1)
	go func() { ch <- cmd() }()
	var msg tea.Msg
	select {
	case msg = <-ch:
	case <-time.After(20 * time.Millisecond):
		return nil
	}
	if batch, ok := msg.(tea.BatchMsg); ok {
		var out []tea.Msg
		for _, c := range batch {
			out = append(out, settingsRun(c, depth+1)...)
		}
		return out
	}
	if msg == nil {
		return nil
	}
	return []tea.Msg{msg}
}

// formKey feeds a key to the form and everything it asks for in return, then
// applies the values that changed.
func (s *settingsPage) formKey(m tea.KeyPressMsg) {
	if s.form == nil {
		return
	}
	// Inline choices change with left/right; up/down move between fields
	// (and wrap, instead of submitting the form at the last one).
	step := 0
	switch m.String() {
	case "down", "j", "tab":
		step = 1
	case "up", "k", "shift+tab":
		step = -1
	case "enter":
		if s.fieldI >= s.fieldN-1 {
			s.leaveForm()
			return
		}
		step = 1
	}
	if s.sec == secLang && (m.String() == "down" || m.String() == "up") {
		s.pump(m)
		return
	}
	if step != 0 {
		next := s.fieldI + step
		switch {
		case next >= s.fieldN:
			for i := 0; i < s.fieldN-1; i++ {
				s.pump(tea.KeyPressMsg{Code: tea.KeyTab, Mod: tea.ModShift})
			}
			s.fieldI = 0
		case next < 0:
			for i := 0; i < s.fieldN-1; i++ {
				s.pump(tea.KeyPressMsg{Code: tea.KeyTab})
			}
			s.fieldI = s.fieldN - 1
		default:
			if step > 0 {
				s.pump(tea.KeyPressMsg{Code: tea.KeyTab})
			} else {
				s.pump(tea.KeyPressMsg{Code: tea.KeyTab, Mod: tea.ModShift})
			}
			s.fieldI = next
		}
		return
	}
	s.pump(m)
}

func (s *settingsPage) pump(first tea.Msg) {
	queue := []tea.Msg{first}
	for i := 0; i < 40 && len(queue) > 0; i++ {
		msg := queue[0]
		queue = queue[1:]
		_, cmd := s.form.Update(msg)
		queue = append(queue, settingsRun(cmd, 0)...)
	}
	prevLang := s.c.Cfg.Lang
	s.sync()
	if s.sec == secLang && s.c.Cfg.Lang != prevLang {
		// the form's own titles are in the old language: rebuild it
		s.form = s.buildForm()
		if s.form != nil {
			s.form.Init()
		}
		return
	}
	if s.form != nil && (s.form.State == huh.StateCompleted || s.form.State == huh.StateAborted) {
		s.leaveForm()
	}
}

func (s *settingsPage) formView(w, h int) []string {
	if s.form == nil {
		return blank(w, h)
	}
	pal := s.c.Pal
	fw := s.formWidth()
	if fw > w {
		fw = w
	}
	s.form.WithWidth(fw).WithHeight(clampi(mini(h-4, 3*s.fieldN-1), 3, 60))
	form := splitLines(strings.TrimRight(s.form.View(), "\n"))
	for i := range form {
		form[i] = padRight(form[i], fw)
	}
	var extra []string
	if s.sec == secNotify {
		extra = append(extra, spaces(fw), padRight(" "+paint(pal.Muted, "t  ")+paint(pal.Text, i18n.T("settings.test.hint")), fw))
	}
	if s.fieldI < len(s.descs) {
		form = append(form, spaces(fw), padRight(" "+paint(pal.Muted, s.descs[s.fieldI]), fw))
	}
	form = append(form, extra...)
	if s.msg != "" && len(form) < h {
		form = append(form, padRight(" "+paint(pal.Good, "✓ "+s.msg), fw))
	}
	pw := w - fw - 3
	if (s.sec == secLook) && pw >= 24 {
		prev := s.dialPreview(pw, h)
		return fit(hcat(form, blank(3, h), prev), w, h)
	}
	if s.sec == secLook && h-len(form) >= 8 {
		return fit(append(form, s.dialPreview(w, h-len(form))...), w, h)
	}
	return fit(form, w, h)
}
