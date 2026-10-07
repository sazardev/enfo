package ui

import (
	"encoding/csv"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// --------------------------------------------------------- dial preview

// dialPreview draws the chosen timer face, running, so the choice is seen
// before it is made.
func (s *settingsPage) dialPreview(w, h int) []string {
	if w < 12 || h < 4 {
		return blank(maxi(w, 0), maxi(h, 0))
	}
	c := s.c
	name := c.Cfg.Dial
	if s.pv == nil || s.pvName != name {
		s.pv, s.pvName = visual.NewDial(name), name
	}
	rows := mini(h, w/2)
	cols := rows * 2
	if wantsFill(s.pv) {
		cols, rows = mini(w, 80), mini(h, 24)
	}
	if rows < 4 || cols < 8 {
		return blank(w, h)
	}
	cv := s.cv("preview", cols, rows)
	still := c.Cfg.Motion == "still"
	f := &visual.Frame{
		Progress: 0.08 + 0.84*math.Mod(s.t/18, 1), Running: true, Time: s.t, Dt: s.dt,
		Pal: c.Pal, Text: "24:13", Sub: i18n.T("phase.focus"), Font: braille.ParseFont(c.Cfg.Font), Still: still,
	}
	if still {
		f.Progress = 0.37
	}
	labels := s.pv.Draw(cv, f)
	lines := cv.Lines()
	overlayLabels(lines, labels)
	out := blank(w, h)
	top, left := (h-rows)/2, (w-cols)/2
	for i, l := range lines {
		out[top+i] = padRight(spaces(left)+l, w)
	}
	return out
}

// ---------------------------------------------------------------- accent

func settingsAccentIndex(name string) int { return theme.Index(name) }

func (s *settingsPage) accentCols(w int) int {
	if w >= 96 {
		return 5
	}
	return clampi(w/13, 3, 8)
}

func (s *settingsPage) applyAccent() {
	n := s.c.Cfg
	n.Accent = theme.Accents[s.accentCur].Name
	s.applyCfg(n)
}

func (s *settingsPage) accentKey(m tea.KeyPressMsg) {
	cols := s.accentCols(s.w - 25)
	n := len(theme.Accents)
	switch m.String() {
	case "left", "h":
		s.accentCur = (s.accentCur + n - 1) % n
	case "right", "l":
		s.accentCur = (s.accentCur + 1) % n
	case "up", "k":
		s.accentCur = (s.accentCur - cols + n) % n
	case "down", "j":
		s.accentCur = (s.accentCur + cols) % n
	case "enter":
		s.leaveForm()
		return
	default:
		return
	}
	s.applyAccent()
}

// accentPeek is the closed-state view: just the current color and its tint.
func (s *settingsPage) accentPeek(w, h int) []string {
	pal := s.c.Pal
	cur := theme.Accents[s.accentCur]
	if i := theme.Index(s.c.Cfg.Accent); i >= 0 {
		cur = theme.Accents[i]
	}
	sw := paint(pal.Accent, repeat("⣿", 12))
	rows := []string{
		padRight(sw, w), padRight(sw, w),
		padRight(bold(pal.Text, cur.Name)+paint(pal.Muted, "  "+pal.Accent.Hex()), w),
		spaces(w),
		padRight(paint(pal.Rest, repeat("⣿", 12)), w),
		padRight(paint(pal.Muted, i18n.T("settings.accent.rest")), w),
		spaces(w), padRight(paint(pal.Faint, i18n.T("settings.peek.hint")), w),
	}
	return fit(rows, w, h)
}

func (s *settingsPage) accentView(w, h int) []string {
	pal := s.c.Pal
	cols := s.accentCols(w)
	cellW := 13
	gridW := cols * cellW
	var grid []string
	n := len(theme.Accents)
	for r := 0; r*cols < n; r++ {
		var a, b, name []string
		for i := r * cols; i < mini((r+1)*cols, n); i++ {
			ac := theme.Accents[i]
			sel := i == s.accentCur
			var top, bot string
			if sel {
				top, bot = repeat("⣿", 9), repeat("⣿", 9)
			} else {
				top, bot = repeat("⣤", 9), repeat("⠛", 9)
			}
			nm := ac.Name
			if sel {
				nm = "▸ " + nm
			} else {
				nm = "  " + nm
			}
			col := pal.Muted
			if sel {
				col = pal.Text
			}
			x := len(a) * cellW
			s.accentRects = append(s.accentRects, statsRect{x: s.paneX + x, y: 3 + len(grid), w: cellW, h: 4})
			a = append(a, padRight(" "+paint(ac.RGB, top), cellW))
			b = append(b, padRight(" "+paint(ac.RGB, bot), cellW))
			if sel {
				name = append(name, padRight(" "+bold(col, nm), cellW))
			} else {
				name = append(name, padRight(" "+paint(col, nm), cellW))
			}
		}
		grid = append(grid, strings.Join(a, ""), strings.Join(b, ""), strings.Join(name, ""), spaces(gridW))
	}
	if w >= 96 && w-gridW >= 30 {
		return fit(hcat(fit(grid, gridW, h), blank(3, h), s.accentPreview(w-gridW-3, h)), w, h)
	}
	if h-len(grid) >= 9 {
		return fit(append(grid, s.accentPreview(w, h-len(grid))...), w, h)
	}
	return fit(grid, w, h)
}

// accentPreview shows a focus dial and a rest dial in the chosen palette.
func (s *settingsPage) accentPreview(w, h int) []string {
	if w < 20 || h < 6 {
		return blank(maxi(w, 0), maxi(h, 0))
	}
	pal := s.c.Pal
	rows := mini(h-2, (w-2)/4)
	cols := rows * 2
	if rows < 4 {
		return blank(w, h)
	}
	still := s.c.Cfg.Motion == "still"
	mk := func(name string, rest bool, prog float64, text string) []string {
		cv := s.cv(name, cols, rows)
		f := &visual.Frame{Progress: prog, Running: true, Rest: rest, Time: s.t, Dt: s.dt, Pal: pal, Text: text, Font: braille.FontLine, Still: still}
		visual.Ring{}.Draw(cv, f)
		return cv.Lines()
	}
	a := mk("accA", false, 0.66, "17:02")
	b := mk("accB", true, 0.3, "03:30")
	label := func(col braille.RGB, t string) string { return centerIn(bold(col, t), cols) }
	left := append(append([]string{}, a...), label(pal.Accent, i18n.T("phase.focus")))
	right := append(append([]string{}, b...), label(pal.Rest, i18n.T("phase.rest")))
	block := hcat(left, blank(2, len(left)), right)
	out := blank(w, h)
	for i, l := range block {
		if i < h {
			out[i] = padRight(spaces(maxi((w-width(l))/2, 0))+l, w)
		}
	}
	return out
}

// ------------------------------------------------------------------ modes

type settingsModes struct {
	ids []string
	on  map[string]bool
	cur int
}

func newSettingsModes(c *Core) settingsModes {
	m := settingsModes{on: map[string]bool{}}
	seen := map[string]bool{}
	add := func(id string, on bool) {
		if seen[id] {
			return
		}
		seen[id] = true
		m.ids = append(m.ids, id)
		m.on[id] = on
	}
	for _, id := range c.Cfg.Modes {
		add(id, true)
	}
	for _, in := range Infos {
		if modeFactories[in.ID] != nil {
			add(in.ID, false)
		}
	}
	var rest []string
	for id := range modeFactories {
		if !seen[id] {
			rest = append(rest, id)
		}
	}
	sort.Strings(rest)
	for _, id := range rest {
		add(id, false)
	}
	return m
}

func (m *settingsModes) commit(s *settingsPage) {
	var out []string
	for _, id := range m.ids {
		if m.on[id] {
			out = append(out, id)
		}
	}
	if len(out) == 0 || !m.on["pomodoro"] {
		m.on["pomodoro"] = true
		out = nil
		for _, id := range m.ids {
			if m.on[id] {
				out = append(out, id)
			}
		}
	}
	n := s.c.Cfg
	n.Modes = out
	s.applyCfg(n)
}

func (m *settingsModes) toggle(s *settingsPage) {
	if m.cur < 0 || m.cur >= len(m.ids) {
		return
	}
	id := m.ids[m.cur]
	if id == "pomodoro" {
		s.flash(i18n.T("settings.modes.locked"))
		return
	}
	m.on[id] = !m.on[id]
	m.commit(s)
}

func (m *settingsModes) move(s *settingsPage, d int) {
	j := m.cur + d
	if j < 0 || j >= len(m.ids) {
		return
	}
	m.ids[m.cur], m.ids[j] = m.ids[j], m.ids[m.cur]
	m.cur = j
	m.commit(s)
}

func (s *settingsPage) modesKey(k tea.KeyPressMsg) {
	m := &s.modes
	switch k.String() {
	case "up", "k":
		m.cur = (m.cur + len(m.ids) - 1) % len(m.ids)
	case "down", "j":
		m.cur = (m.cur + 1) % len(m.ids)
	case "space", "enter", "x":
		m.toggle(s)
	case "shift+up", "K":
		m.move(s, -1)
	case "shift+down", "J":
		m.move(s, 1)
	}
}

func (s *settingsPage) modesView(w, h int) []string {
	pal := s.c.Pal
	m := &s.modes
	var out []string
	n := 0
	for i, id := range m.ids {
		on := m.on[id]
		box := paint(pal.Faint, "○")
		label := paint(pal.Muted, i18n.T("mode."+id))
		num := "  "
		if on {
			n++
			box = bold(pal.Accent, "◉")
			label = paint(pal.Text, i18n.T("mode."+id))
			num = paint(pal.Muted, itoa(n)+" ")
		}
		cur := "  "
		if i == m.cur {
			cur = bold(pal.Accent, "▸ ")
			label = bold(pal.Text, i18n.T("mode."+id))
		}
		note := ""
		if id == "pomodoro" {
			note = paint(pal.Faint, "  "+i18n.T("settings.modes.always"))
		}
		s.modeRects = append(s.modeRects, statsRect{x: s.paneX, y: 3 + len(out), w: w, h: 1})
		out = append(out, padRight(cur+box+" "+num+paint(pal.Muted, infoFor(id).Icon)+" "+label+note, w))
	}
	out = append(out, spaces(w), padRight(paint(pal.Faint, i18n.T("settings.modes.hint")), w))
	return fit(out, w, h)
}

// ------------------------------------------------------------------- data

func (s *settingsPage) dataRows() []struct{ title, desc string } {
	return []struct{ title, desc string }{
		{i18n.T("settings.data.export"), i18n.T("settings.data.export.d", settingsExportPath())},
		{i18n.T("settings.data.clear"), i18n.T("settings.data.clear.d", len(s.c.Events()))},
		{i18n.T("settings.data.reset"), i18n.T("settings.data.reset.d")},
	}
}

func settingsExportPath() string {
	home, err := os.UserHomeDir()
	if err != nil {
		home = "."
	}
	return filepath.Join(home, "enfo-history.csv")
}

func (s *settingsPage) dataKey(m tea.KeyPressMsg) {
	if s.confirm != 0 {
		switch m.String() {
		case "y", "Y", "enter":
			s.dataDo()
		case "n", "N":
			s.confirm = 0
		}
		return
	}
	switch m.String() {
	case "up", "k":
		s.dataCur = (s.dataCur + 2) % 3
	case "down", "j":
		s.dataCur = (s.dataCur + 1) % 3
	case "enter", "space":
		s.dataRun()
	}
}

func (s *settingsPage) dataRun() {
	switch s.dataCur {
	case 0:
		path := settingsExportPath()
		if err := settingsWriteCSV(path, s.c.Events()); err != nil {
			s.flash(err.Error())
			return
		}
		s.flash(i18n.T("settings.data.exported", path))
	case 1:
		s.confirm = 1
	case 2:
		s.confirm = 2
	}
}

// dataDo runs the destructive action that was confirmed inline.
func (s *settingsPage) dataDo() {
	switch s.confirm {
	case 1:
		_ = s.c.Store.ClearHistory()
		s.c.events = nil
		s.flash(i18n.T("settings.data.cleared"))
	case 2:
		d := store.DefaultConfig()
		d.Onboarded = s.c.Cfg.Onboarded
		s.c.Cfg = d
		s.c.ApplyConfig()
		s.loadVals()
		s.accentCur = settingsAccentIndex(s.c.Cfg.Accent)
		s.flash(i18n.T("settings.data.resetdone"))
	}
	s.confirm = 0
}

func settingsWriteCSV(path string, evs []engine.Event) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	w := csv.NewWriter(f)
	_ = w.Write([]string{"kind", "label", "start", "planned_seconds", "actual_seconds", "completed"})
	for _, e := range evs {
		_ = w.Write([]string{string(e.Kind), e.Label, e.Start.Format(time.RFC3339),
			strconv.Itoa(int(e.Planned / time.Second)), strconv.Itoa(int(e.Actual / time.Second)), strconv.FormatBool(e.Completed)})
	}
	w.Flush()
	return w.Error()
}

func (s *settingsPage) dataView(w, h int) []string {
	pal := s.c.Pal
	var out []string
	for i, r := range s.dataRows() {
		cur := "  "
		title := paint(pal.Text, r.title)
		if i == s.dataCur {
			cur = bold(pal.Accent, "▸ ")
			title = bold(pal.Text, r.title)
		}
		s.dataRects = append(s.dataRects, statsRect{x: s.paneX, y: 3 + len(out), w: w, h: 2})
		out = append(out, padRight(cur+title, w))
		if s.confirm == i && s.confirm != 0 {
			q := i18n.T("settings.data.sure")
			out = append(out, padRight("  "+bold(pal.Warn, q+"  ")+paint(pal.Text, "y ")+paint(pal.Muted, i18n.T("settings.yes")+"   ")+paint(pal.Text, "n ")+paint(pal.Muted, i18n.T("settings.no")), w))
		} else {
			out = append(out, padRight("  "+paint(pal.Muted, r.desc), w))
		}
		out = append(out, spaces(w))
	}
	out = append(out, padRight(" "+paint(pal.Faint, s.c.Store.ConfigPath()), w), padRight(" "+paint(pal.Faint, s.c.Store.StatePath()), w))
	if s.msg != "" {
		out = append(out, spaces(w), padRight(" "+paint(pal.Good, "✓ "+s.msg), w))
	}
	return fit(out, w, h)
}

// ------------------------------------------------------------------ about

func (s *settingsPage) aboutView(w, h int) []string {
	pal := s.c.Pal
	rows := mini(h, 12)
	cols := rows * 2
	if w < 56 {
		rows = mini(h/2, 8)
		cols = rows * 2
	}
	cv := s.cv("about", cols, maxi(rows, 4))
	// the logo builds itself, rests, and plays again
	phase := math.Mod(s.t, 8)
	t := anim.InOutSine(anim.Clamp01(phase / 2.6))
	if s.c.Cfg.Motion == "still" {
		t = 1
	}
	size := float64(minF(cv.W, cv.H)) * 0.9
	visual.Mark(cv, float64(cv.W)/2, float64(cv.H)/2, size, t, pal.Accent, pal.Bright, pal.Bg)
	mark := cv.Lines()

	info := []string{
		bold(pal.Text, "e n f o"),
		paint(pal.Muted, i18n.T("app.tagline")),
		"",
		paint(pal.Muted, i18n.T("settings.about.version")+"  ") + paint(pal.Text, SettingsVersion),
		paint(pal.Muted, i18n.T("settings.about.repo")+"  ") + paint(pal.Text, "github.com/sazarcode/enfo"),
		paint(pal.Muted, i18n.T("settings.about.config")+"  ") + paint(pal.Text, s.c.Store.ConfigPath()),
		paint(pal.Muted, i18n.T("settings.about.state")+"  ") + paint(pal.Text, s.c.Store.StatePath()),
		"",
		paint(pal.Muted, i18n.T("settings.about.made")),
		paint(pal.Accent, "Bubble Tea") + paint(pal.Faint, " · ") + paint(pal.Accent, "Lip Gloss") + paint(pal.Faint, " · ") + paint(pal.Accent, "Bubbles"),
		paint(pal.Accent, "Huh") + paint(pal.Faint, " · ") + paint(pal.Accent, "Glamour") + paint(pal.Faint, " · ") + paint(pal.Accent, "Harmonica") + paint(pal.Faint, " · ") + paint(pal.Accent, "Fang"),
		paint(pal.Muted, i18n.T("settings.about.braille")),
	}
	var out []string
	if w >= 56 {
		info = append([]string{""}, info...)
		out = hcat(mark, blank(3, len(mark)), info)
		for len(out) < h && len(info) > len(out) {
			out = append(out, spaces(w))
		}
	} else {
		for _, l := range mark {
			out = append(out, centerIn(l, w))
		}
		out = append(out, "")
		for _, l := range info[:2] {
			out = append(out, centerIn(l, w))
		}
		out = append(out, "")
		for _, l := range info[3:5] {
			out = append(out, centerIn(l, w))
		}
	}
	return fit(out, w, h)
}

// ------------------------------------------------------------- notifications

func (s *settingsPage) notifyTest() {
	notify.Send("Enfo", i18n.T("settings.test.body"), false)
	notify.Play(notify.SoundDone)
}

var _ = csv.NewWriter
var _ = strconv.Itoa
var _ = time.Now
