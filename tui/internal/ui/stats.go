package ui

import (
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/paginator"
	"charm.land/bubbles/v2/viewport"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/theme"
)

func init() {
	registerPage("stats", func(c *Core, say func(string)) Mode { return newStatsPage(c, say) })
}

// the paged sections
const (
	statsOverview = iota
	statsHeat
	statsRhythm
	statsLog
	statsSections
)

var statsRanges = []int{7, 30, 90}

type statsRect struct{ x, y, w, h int }

func (r statsRect) in(x, y int) bool { return x >= r.x && x < r.x+r.w && y >= r.y && y < r.y+r.h }

// statsPage is the statistics dashboard: hero cards, a per-day bar chart, a
// heat map, the hours of the day, a breakdown by tool and the activity log.
// Wide terminals show it all at once; smaller ones page through sections.
type statsPage struct {
	c    *Core
	say  func(string)
	done bool

	rng  int // days in the selected range
	sec  int // current section when paged
	sel  int // selected day, 0 = today, 1 = yesterday ...
	t    float64
	data *statsData
	key  struct {
		n   int
		day time.Time
		rng int
	}
	pal theme.Palette

	vp    viewport.Model
	vpW   int
	vpH   int
	vpKey int
	cvs   map[string]*braille.Canvas
	pager paginator.Model

	// geometry of the last frame (body-relative), for the mouse
	chart struct {
		r                 statsRect
		cols, left, pitch int
		n                 int
	}
	heat struct {
		r     statsRect
		weeks int
		step  int
		first time.Time // Monday of the first week
		gridY int
	}
	chips []statsRect
	tabs  []statsRect
	logR  statsRect
	dash  bool
}

func newStatsPage(c *Core, say func(string)) *statsPage {
	s := &statsPage{c: c, say: say, rng: 30, cvs: map[string]*braille.Canvas{}, vp: viewport.New()}
	s.pager = paginator.New(paginator.WithTotalPages(statsSections))
	s.pager.Type = paginator.Dots
	s.pager.ActiveDot = "⣿ "
	s.pager.InactiveDot = "⠶ "
	if c.Cfg.Motion == "still" {
		s.t = 99
	}
	return s
}

func (s *statsPage) ID() string    { return "stats" }
func (s *statsPage) Done() bool    { return s.done }
func (s *statsPage) Title() string { return i18n.T("mode.stats") }

func (s *statsPage) Animated() bool { return s.t < 1.8 && s.c.Cfg.Motion != "still" }

func (s *statsPage) Frame(dt time.Duration) {
	if s.c.Cfg.Motion != "still" {
		s.t += dt.Seconds()
	}
}

func (s *statsPage) Help() []key.Binding {
	return []key.Binding{
		kb("left|right|h|l", "←→", i18n.T("stats.k.day")),
		kb("tab|shift+tab", "tab", i18n.T("stats.k.section")),
		kb("r", "r", i18n.T("stats.k.range")),
		kb("up|down|pgup|pgdown", "↑↓", i18n.T("stats.k.scroll")),
		kb("esc", "esc", i18n.T("key.back")),
	}
}

// refresh recomputes the numbers when the history, the day or the range moved.
func (s *statsPage) refresh() {
	c := s.c
	ev := c.Events()
	ghost := len(ev) == 0
	if ghost {
		ev = statsGhostEvents(c.Now)
	}
	day := time.Date(c.Now.Year(), c.Now.Month(), c.Now.Day(), 0, 0, 0, 0, c.Now.Location())
	if s.data != nil && s.key.n == len(ev) && s.key.day.Equal(day) && s.key.rng == s.rng && s.data.ghost == ghost {
		s.pal = c.Pal
		if ghost {
			s.pal = statsDim(c.Pal, 0.42)
		}
		return
	}
	s.key.n, s.key.day, s.key.rng = len(ev), day, s.rng
	s.data = statsCompute(ev, c.Now, s.rng, ghost)
	s.pal = c.Pal
	if ghost {
		s.pal = statsDim(c.Pal, 0.42)
	}
	s.vpKey = -1
}

func (s *statsPage) cv(name string, cols, rows int) *braille.Canvas {
	cv := s.cvs[name]
	if cv == nil {
		cv = braille.New(cols, rows)
		s.cvs[name] = cv
		return cv
	}
	cv.Resize(cols, rows)
	return cv
}

// grow eases 0..1 for the i-th item of a staggered entrance.
func (s *statsPage) grow(i int, per float64) float64 {
	if s.c.Cfg.Motion == "still" {
		return 1
	}
	return anim.OutCubic((s.t - float64(i)*per) / 0.65)
}

// count eases the hero numbers up from zero.
func (s *statsPage) count() float64 {
	if s.c.Cfg.Motion == "still" {
		return 1
	}
	return anim.OutCubic(s.t / 1.0)
}

func (s *statsPage) maxSel() int {
	if s.dash || s.sec == statsHeat {
		return statsWindow - 1
	}
	return maxi(s.rng, 7) - 1
}

func (s *statsPage) Update(msg tea.Msg) tea.Cmd {
	switch m := msg.(type) {
	case tea.KeyPressMsg:
		switch m.String() {
		case "left", "h":
			s.sel = clampi(s.sel+1, 0, s.maxSel())
		case "right", "l":
			s.sel = clampi(s.sel-1, 0, s.maxSel())
		case "up", "k":
			if !s.dash && s.sec == statsHeat {
				s.sel = clampi(s.sel+7, 0, s.maxSel())
			} else {
				s.vp.ScrollUp(1)
			}
		case "down", "j":
			if !s.dash && s.sec == statsHeat {
				s.sel = clampi(s.sel-7, 0, s.maxSel())
			} else {
				s.vp.ScrollDown(1)
			}
		case "pgup":
			s.vp.HalfPageUp()
		case "pgdown", "space":
			s.vp.HalfPageDown()
		case "home", "g":
			s.vp.GotoTop()
			s.sel = 0
		case "end", "G":
			s.vp.GotoBottom()
		case "tab":
			s.sec = (s.sec + 1) % statsSections
			s.replay()
		case "shift+tab":
			s.sec = (s.sec + statsSections - 1) % statsSections
			s.replay()
		case "r":
			for i, r := range statsRanges {
				if r == s.rng {
					s.rng = statsRanges[(i+1)%len(statsRanges)]
					break
				}
			}
			s.sel = clampi(s.sel, 0, s.maxSel())
			s.replay()
		case "7":
			s.setRange(7)
		case "3":
			s.setRange(30)
		case "9":
			s.setRange(90)
		}
	case tea.MouseWheelMsg:
		if m.Button == tea.MouseWheelUp {
			s.vp.ScrollUp(3)
		} else if m.Button == tea.MouseWheelDown {
			s.vp.ScrollDown(3)
		}
	case tea.MouseClickMsg:
		if m.Button != tea.MouseLeft {
			return nil
		}
		s.click(m.X, m.Y)
	}
	return nil
}

func (s *statsPage) setRange(d int) {
	s.rng = d
	s.sel = clampi(s.sel, 0, s.maxSel())
	s.replay()
}

func (s *statsPage) replay() {
	if s.c.Cfg.Motion != "still" {
		s.t = 0.15
	}
}

func (s *statsPage) click(x, y int) {
	for i, r := range s.chips {
		if r.in(x, y) {
			s.setRange(statsRanges[i])
			return
		}
	}
	if !s.dash {
		for i, r := range s.tabs {
			if r.in(x, y) {
				s.sec = i
				s.replay()
				return
			}
		}
	}
	if s.chart.n > 0 && s.chart.r.in(x, y) {
		bx := (x-s.chart.r.x)*2 - s.chart.left
		i := bx / maxi(s.chart.pitch, 1)
		if i >= 0 && i < s.chart.n {
			s.sel = s.chart.n - 1 - i
		}
		return
	}
	if s.heat.weeks > 0 && s.heat.r.in(x, y) {
		col := (x - s.heat.r.x) / maxi(s.heat.step, 1)
		row := y - s.heat.gridY
		if col >= 0 && col < s.heat.weeks && row >= 0 && row < 7 {
			day := s.heat.first.AddDate(0, 0, col*7+row)
			today := time.Date(s.c.Now.Year(), s.c.Now.Month(), s.c.Now.Day(), 0, 0, 0, 0, s.c.Now.Location())
			off := int(today.Sub(day).Hours()/24 + 0.5)
			if off >= 0 {
				s.sel = clampi(off, 0, s.maxSel())
			}
		}
	}
}

// ------------------------------------------------------------------- view

func (s *statsPage) View(w, h int) string {
	if w < 8 || h < 2 {
		return join(statsBlank(w, h))
	}
	s.refresh()
	if w < 24 || h < 6 {
		return s.tiny(w, h)
	}
	s.chips, s.tabs = s.chips[:0], s.tabs[:0]
	s.chart.n, s.heat.weeks = 0, 0
	s.dash = w >= 104 && h >= 36
	if !s.dash {
		s.sel = clampi(s.sel, 0, s.maxSel())
	}
	var body []string
	hdr := s.header(w)
	bodyH := h - 1
	switch {
	case s.dash:
		body = s.dashboard(w, bodyH)
	default:
		bodyH--
		body = s.paged(w, bodyH)
		body = append(body, s.footerDots(w))
	}
	lines := append([]string{hdr}, body...)
	lines = fit(lines, w, h)
	if s.data.ghost {
		lines = s.ghostOverlay(lines, w, h)
	}
	return join(lines)
}

func (s *statsPage) header(w int) string {
	pal := s.pal
	title := bold(pal.Accent, "▍") + bold(pal.Text, strings_upper(i18n.T("mode.stats")))
	// range chips on the right
	chips := ""
	cw := 0
	var rects []statsRect
	parts := make([]string, len(statsRanges))
	for i, r := range statsRanges {
		label := i18n.T("stats.range", r)
		if r == s.rng {
			parts[i] = bold(pal.Accent, "["+label+"]")
		} else {
			parts[i] = paint(pal.Muted, " "+label+" ")
		}
		cw += width(parts[i]) + 1
	}
	x := w - cw - 1
	for _, p := range parts {
		rects = append(rects, statsRect{x: x, y: 0, w: width(p), h: 1})
		chips += p + " "
		x += width(p) + 1
	}
	s.chips = rects
	line := padRight(" "+title, w-cw-1)
	// section tabs in the middle when paged
	if !s.dash {
		names := []string{"stats.sec.overview", "stats.sec.heat", "stats.sec.rhythm", "stats.sec.log"}
		tx := width(line) + 0
		_ = tx
		var tabs string
		col := 2 + width(title) + 3
		for i, n := range names {
			lb := i18n.T(n)
			var seg string
			if i == s.sec {
				seg = bold(pal.Text, " "+lb+" ")
			} else {
				seg = paint(pal.Muted, " "+lb+" ")
			}
			s.tabs = append(s.tabs, statsRect{x: col, y: 0, w: width(seg), h: 1})
			col += width(seg)
			tabs += seg
		}
		if col+cw < w {
			line = padRight(" "+title+"   "+tabs, w-cw-1)
		} else {
			s.tabs = nil
		}
	}
	return padRight(line+chips, w)
}

func (s *statsPage) footerDots(w int) string {
	s.pager.Page = s.sec
	return centerIn(s.pager.View(), w)
}

func strings_upper(s string) string {
	out := []rune(s)
	for i, r := range out {
		if r >= 'a' && r <= 'z' {
			out[i] = r - 32
		}
	}
	return string(out)
}

// dashboard lays everything out at once for big windows.
func (s *statsPage) dashboard(w, h int) []string {
	heroH := 4
	hero := s.hero(w, heroH)
	rest := h - heroH - 1
	midH := rest * 5 / 9
	botH := rest - midH - 1
	chartW := w * 56 / 100
	if chartW > w-62 {
		chartW = w - 62
	}
	heatW := w - chartW - 3
	chart := s.chartBlock(chartW, midH)
	s.chart.r.x, s.chart.r.y = 0+s.chart.r.x, 1+heroH+1+s.chart.r.y
	heatH := mini(midH, 12)
	heat := s.heatBlock(heatW, heatH)
	s.heat.r.x += chartW + 3
	s.heat.r.y += 1 + heroH + 1
	s.heat.gridY += 1 + heroH + 1
	if midH-heatH >= 5 {
		heat = append(heat, statsBlank(heatW, 1)...)
		heat = append(heat, s.weekdaysBlock(heatW, midH-heatH-1)...)
	}
	mid := hcat(chart, statsBlank(3, midH), fit(heat, heatW, midH))

	hw := w * 30 / 100
	kw := w * 33 / 100
	lw := w - hw - kw - 6
	hours := s.hoursBlock(hw, botH)
	kinds := s.kindsBlock(kw, botH)
	logb := s.logBlock(lw, botH)
	s.logR = statsRect{x: hw + kw + 6, y: 1 + heroH + 1 + midH + 1, w: lw, h: botH}
	bot := hcat(hours, statsBlank(3, botH), kinds, statsBlank(3, botH), logb)

	out := append([]string{}, hero...)
	out = append(out, statsBlank(w, 1)...)
	out = append(out, mid...)
	out = append(out, s.rule(w))
	out = append(out, bot...)
	return fit(out, w, h)
}

func (s *statsPage) rule(w int) string {
	return paint(s.pal.Faint, repeat("⣀", w))
}

func repeat(s string, n int) string {
	out := ""
	for i := 0; i < n; i++ {
		out += s
	}
	return out
}

// paged shows one section at a time, filling the body.
func (s *statsPage) paged(w, h int) []string {
	switch s.sec {
	case statsHeat:
		heatH := 12
		if h < heatH+4 {
			heatH = h
		}
		heat := s.heatBlock(w, heatH)
		s.heat.r.y++
		s.heat.gridY++
		out := append([]string{}, heat...)
		if h-heatH > 3 {
			wk := s.weekdaysBlock(w, h-heatH-1)
			out = append(out, statsBlank(w, 1)...)
			out = append(out, wk...)
		}
		return fit(out, w, h)
	case statsRhythm:
		if w >= 96 && h >= 8 {
			hw := w * 45 / 100
			hours := s.hoursBlock(hw, h)
			kinds := s.kindsBlock(w-hw-3, h)
			return fit(hcat(hours, statsBlank(3, h), kinds), w, h)
		}
		hh := h / 2
		hours := s.hoursBlock(w, hh)
		kinds := s.kindsBlock(w, h-hh)
		return fit(append(hours, kinds...), w, h)
	case statsLog:
		s.logR = statsRect{x: 0, y: 1, w: w, h: h}
		return fit(s.logBlock(w, h), w, h)
	}
	// overview
	heroH := 4
	if w < 60 {
		heroH = 8
	}
	if h < heroH+8 {
		heroH = maxi(h/3, 3)
	}
	hero := s.hero(w, heroH)
	chart := s.chartBlock(w, h-heroH-1)
	s.chart.r.y += 1 + heroH + 1
	out := append([]string{}, hero...)
	out = append(out, statsBlank(w, 1)...)
	out = append(out, chart...)
	return fit(out, w, h)
}

// ghostOverlay writes the invitation over the dimmed preview.
func (s *statsPage) ghostOverlay(lines []string, w, h int) []string {
	pal := s.c.Pal
	msg := []string{
		bold(pal.Text, i18n.T("stats.empty.title")),
		paint(pal.Muted, i18n.T("stats.empty.body")),
	}
	bw := 0
	for _, m := range msg {
		bw = maxi(bw, width(m))
	}
	bw = mini(bw+4, w-2)
	top := h/2 - 2
	if top < 1 {
		top = 1
	}
	for i, m := range msg {
		y := top + 1 + i
		if y >= len(lines) {
			break
		}
		row := spaces(bw)
		row = stamp(row, (bw-width(m))/2, m)
		lines[y] = stamp(lines[y], (w-bw)/2, row)
	}
	for _, y := range []int{top, top + 3} {
		if y >= 0 && y < len(lines) {
			lines[y] = stamp(lines[y], (w-bw)/2, paint(pal.Accent, repeat("⣀", bw)))
		}
	}
	return lines
}

// tiny is the page on a postage stamp: today's focus and the streak.
func (s *statsPage) tiny(w, h int) string {
	s.chips, s.tabs = nil, nil
	s.chart.n, s.heat.weeks = 0, 0
	pal := s.pal
	d := s.data.all
	lines := []string{
		bold(pal.Accent, statsDur(d.Today.Focus)),
		paint(pal.Muted, strings_upper(i18n.T("stats.card.today"))),
	}
	if d.Streak > 0 && h >= 4 {
		lines = append(lines, paint(pal.Warn, "🔥 "+itoa(d.Streak)))
	}
	out := statsBlank(w, h)
	top := (h - len(lines)) / 2
	for i, l := range lines {
		if top+i >= 0 && top+i < h {
			out[top+i] = centerIn(l, w)
		}
	}
	return join(out)
}
