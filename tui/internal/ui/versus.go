package ui

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func init() {
	registerMode("versus", func(c *Core, say func(string)) Mode { return newVersus(c, say) })
}

// versusPreset is a time control: minutes per player + increment seconds.
type versusPreset struct{ min, inc int }

var versusPresets = []versusPreset{{1, 0}, {3, 2}, {5, 0}, {10, 0}, {15, 10}, {30, 0}}

const versusCustom = 6 // index of the custom entry (after the presets)

// versusSetup is what the user chose; it is persisted.
type versusSetup struct {
	Preset int  `json:"preset"`
	Min    int  `json:"min"`   // custom minutes
	Inc    int  `json:"inc"`   // custom increment, seconds
	Delay  int  `json:"delay"` // delay seconds (any preset)
	First  int  `json:"first"` // player that moves first
	Flip   bool `json:"flip"`  // top half rotated 180 degrees
}

type versusFile struct {
	Setup versusSetup        `json:"setup"`
	Game  *engine.VersusGame `json:"game,omitempty"`
}

type versusMode struct {
	c   *Core
	say func(string)
	now time.Time
	g   *engine.VersusGame
	set versusSetup

	editing bool
	field   int // 0 minutes, 1 increment, 2 delay

	canvas [2]*braille.Canvas
	rot    *braille.Canvas
	hit    [2]struct{ x, y, w, h int }
	chips  []kitchenChip
	chipY  int
}

func newVersus(c *Core, say func(string)) *versusMode {
	m := &versusMode{c: c, say: say, now: c.Now, set: versusSetup{Preset: 2, Min: 5, Inc: 0}}
	if b, err := os.ReadFile(m.path()); err == nil {
		var f versusFile
		if json.Unmarshal(b, &f) == nil {
			m.set = f.Setup
			m.g = f.Game
		}
	}
	m.set.Preset = clampi(m.set.Preset, 0, versusCustom)
	m.set.Min = clampi(m.set.Min, 1, 180)
	m.set.Inc = clampi(m.set.Inc, 0, 60)
	m.set.Delay = clampi(m.set.Delay, 0, 60)
	m.set.First = clampi(m.set.First, 0, 1)
	if m.g == nil {
		total, inc := m.control()
		m.g = engine.NewVersus(total, inc, time.Duration(m.set.Delay)*time.Second)
	}
	// a game that ran out while we were away is logged, not rung
	if f, _ := m.g.Tick(c.Now); f {
		m.logGame(c.Now)
		m.save()
	}
	return m
}

func (m *versusMode) path() string { return filepath.Join(m.c.Store.StateDir, "versus.json") }

func (m *versusMode) save() {
	b, err := json.Marshal(versusFile{Setup: m.set, Game: m.g})
	if err != nil {
		return
	}
	tmp := m.path() + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, m.path())
	}
}

// control returns the chosen time control.
func (m *versusMode) control() (total, inc time.Duration) {
	if m.set.Preset < len(versusPresets) {
		p := versusPresets[m.set.Preset]
		return time.Duration(p.min) * time.Minute, time.Duration(p.inc) * time.Second
	}
	return time.Duration(m.set.Min) * time.Minute, time.Duration(m.set.Inc) * time.Second
}

func (m *versusMode) label() string {
	total, inc := m.g.Total, m.g.Inc
	s := fmt.Sprintf("%d+%d", int(total.Minutes()), int(inc.Seconds()))
	if m.g.Delay > 0 {
		s += fmt.Sprintf(" d%d", int(m.g.Delay.Seconds()))
	}
	return s
}

func (m *versusMode) apply() {
	total, inc := m.control()
	m.g.Configure(total, inc, time.Duration(m.set.Delay)*time.Second)
	m.save()
}

func (m *versusMode) logGame(now time.Time) {
	m.c.Log(engine.Event{Kind: "versus", Label: m.label(), Start: m.g.Began, Actual: now.Sub(m.g.Began), Completed: true})
}

func (m *versusMode) ID() string { return "versus" }

func (m *versusMode) Capturing() bool { return m.editing }

func (m *versusMode) Animated() bool { return m.c.Cfg.Motion != "still" }

// -------------------------------------------------------------- Background

func (m *versusMode) Step(now time.Time, dt time.Duration) []Announce {
	m.now = now
	if f, p := m.g.Tick(now); f {
		m.logGame(now)
		m.save()
		return []Announce{{
			Kind: "versus", Title: i18n.T("versus.flag"), Body: i18n.T("versus.flag.body", p+1), Ring: true,
		}}
	}
	return nil
}

func (m *versusMode) Runner() *Running {
	switch m.g.State {
	case engine.VersusRunning:
		return &Running{Mode: "versus", Icon: versusIcon, Text: clockText(m.g.Remaining(m.g.Active, m.now))}
	case engine.VersusPaused:
		return &Running{Mode: "versus", Icon: versusIcon, Text: clockText(m.g.Remaining(m.g.Active, m.now)), Paused: true}
	}
	return nil
}

// versusIcon is the tab icon (a single-width, text-presentation glyph).
const versusIcon = "⇄"

func (m *versusMode) Title() string {
	if m.g.State == engine.VersusRunning || m.g.State == engine.VersusPaused {
		return fmt.Sprintf("%s %s | %s", versusIcon, clockText(m.g.Remaining(0, m.now)), clockText(m.g.Remaining(1, m.now)))
	}
	return ""
}

func (m *versusMode) Help() []key.Binding {
	g := m.g
	switch {
	case m.editing:
		return []key.Binding{
			kb("left|right", "←→", i18n.T("versus.field")),
			kb("up|down|+|-", "↑↓", i18n.T("versus.adjust")),
			kb("enter|esc", "enter", i18n.T("versus.done")),
		}
	case g.State == engine.VersusSetup:
		return []key.Binding{
			kb("space|enter", "space", i18n.T("versus.start")),
			kb("left|right", "←→", i18n.T("versus.preset")),
			kb("e", "e", i18n.T("versus.edit")),
			kb("s", "s", i18n.T("versus.first")),
			kb("v", "v", i18n.T("versus.flip")),
		}
	case g.State == engine.VersusRunning:
		return []key.Binding{
			kb("space|enter", "space", i18n.T("versus.switch")),
			kb("p", "p", i18n.T("versus.pause")),
			kb("v", "v", i18n.T("versus.flip")),
			kb("r", "r", i18n.T("versus.reset")),
		}
	case g.State == engine.VersusPaused:
		return []key.Binding{
			kb("space|enter|p", "space", i18n.T("versus.resume")),
			kb("v", "v", i18n.T("versus.flip")),
			kb("r", "r", i18n.T("versus.reset")),
		}
	}
	return []key.Binding{kb("space|enter|r", "space", i18n.T("versus.reset"))}
}

// ------------------------------------------------------------------ input

func (m *versusMode) reset() {
	m.c.Log(m.g.Reset(m.now, m.label())...)
	m.save()
}

func (m *versusMode) press() {
	g := m.g
	switch g.State {
	case engine.VersusSetup:
		g.Begin(m.set.First, m.now)
	case engine.VersusRunning:
		g.Press(m.now)
	case engine.VersusPaused:
		g.Resume(m.now)
	case engine.VersusFlag:
		m.reset()
		return
	}
	m.save()
}

func (m *versusMode) Update(msg tea.Msg) tea.Cmd {
	g := m.g
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		s := msg.String()
		if m.editing {
			switch s {
			case "enter", "esc", "e":
				m.editing = false
			case "left", "h":
				m.field = (m.field + 2) % 3
			case "right", "l":
				m.field = (m.field + 1) % 3
			case "up", "k", "+", "=":
				m.adjust(1)
			case "down", "j", "-", "_":
				m.adjust(-1)
			}
			return nil
		}
		switch s {
		case "space", "enter":
			m.press()
		case "p":
			if g.State == engine.VersusRunning {
				g.Pause(m.now)
				m.save()
			} else if g.State == engine.VersusPaused {
				g.Resume(m.now)
				m.save()
			}
		case "r":
			if g.State != engine.VersusSetup {
				m.reset()
			}
		case "v":
			m.set.Flip = !m.set.Flip
			m.save()
		case "left", "h":
			if g.State == engine.VersusSetup {
				m.set.Preset = (m.set.Preset + versusCustom) % (versusCustom + 1)
				m.apply()
			}
		case "right", "l":
			if g.State == engine.VersusSetup {
				m.set.Preset = (m.set.Preset + 1) % (versusCustom + 1)
				m.apply()
			}
		case "e":
			if g.State == engine.VersusSetup {
				m.editing = true
				if m.set.Preset < versusCustom {
					p := versusPresets[m.set.Preset]
					m.set.Min, m.set.Inc, m.set.Preset = p.min, p.inc, versusCustom
					m.apply()
				}
			}
		case "s":
			if g.State == engine.VersusSetup {
				m.set.First = 1 - m.set.First
				m.save()
			}
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		if g.State == engine.VersusSetup {
			if msg.Y == m.chipY {
				for _, ch := range m.chips {
					if msg.X >= ch.x && msg.X < ch.x+ch.w {
						m.set.Preset = ch.idx
						m.apply()
						return nil
					}
				}
			}
			m.press()
			return nil
		}
		for p := 0; p < 2; p++ {
			r := m.hit[p]
			if msg.X >= r.x && msg.X < r.x+r.w && msg.Y >= r.y && msg.Y < r.y+r.h {
				switch g.State {
				case engine.VersusRunning:
					if p == g.Active {
						m.press()
					}
				default:
					m.press()
				}
			}
		}
	}
	return nil
}

func (m *versusMode) adjust(d int) {
	m.set.Preset = versusCustom
	switch m.field {
	case 0:
		step := 1
		if m.set.Min >= 20 {
			step = 5
		}
		m.set.Min = clampi(m.set.Min+d*step, 1, 180)
	case 1:
		m.set.Inc = clampi(m.set.Inc+d, 0, 60)
	case 2:
		m.set.Delay = clampi(m.set.Delay+d, 0, 60)
	}
	m.apply()
}

func (m *versusMode) Frame(dt time.Duration) { m.now = m.c.Now }

// -------------------------------------------------------------------- view

func versusText(d time.Duration, h int) string {
	if d < 20*time.Second && d > 0 {
		t := int(d / (100 * time.Millisecond))
		return fmt.Sprintf("%d.%d", t/10, t%10)
	}
	s := ceilSecs(d)
	hh, mm, ss := s/3600, s%3600/60, s%60
	if hh > 0 {
		return fmt.Sprintf("%d:%02d:%02d", hh, mm, ss)
	}
	return fmt.Sprintf("%02d:%02d", mm, ss)
}

func (m *versusMode) playerColor(p int) braille.RGB {
	if p == 0 {
		return m.c.Pal.Accent
	}
	return m.c.Pal.Rest
}

func (m *versusMode) View(w, h int) string {
	if w < 1 || h < 1 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	if m.g.State == engine.VersusSetup {
		return join(fit(m.setupView(w, h), w, h))
	}
	if h < 7 || w < 20 {
		return join(fit(m.tinyView(w, h), w, h))
	}
	// arrangement: halves stacked, or side by side on very wide terminals
	side := w >= int(2.6*float64(h)) && w >= 60
	var rects [2][4]int // x y w h per player
	if side {
		hw := w / 2
		rects[0] = [4]int{0, 0, hw, h}
		rects[1] = [4]int{hw, 0, w - hw, h}
	} else {
		th := h / 2
		rects[1] = [4]int{0, 0, w, th}
		rects[0] = [4]int{0, th, w, h - th}
	}
	var halves [2][]string
	for p := 0; p < 2; p++ {
		r := rects[p]
		m.hit[p] = struct{ x, y, w, h int }{r[0], r[1], r[2], r[3]}
		flip := !side && p == 1 && m.set.Flip
		halves[p] = m.half(p, r[2], r[3], flip)
	}
	var lines []string
	if side {
		lines = hcat(halves[0], halves[1])
	} else {
		lines = append(append(lines, halves[1]...), halves[0]...)
	}
	return join(fit(lines, w, h))
}

func (m *versusMode) tinyView(w, h int) []string {
	pal := m.c.Pal
	g := m.g
	mk := func(p int) string {
		col := m.playerColor(p)
		txt := clockText(g.Remaining(p, m.now))
		if g.State == engine.VersusFlag && g.Flagged == p {
			return bold(pal.Bad, fmt.Sprintf("%d ", p+1)+txt)
		}
		if g.State == engine.VersusRunning && g.Active == p {
			return bold(col, "▶ "+fmt.Sprintf("%d ", p+1)) + bold(pal.Text, txt)
		}
		return paint(pal.Muted, "  "+fmt.Sprintf("%d ", p+1)+txt)
	}
	out := blank(w, h)
	if h > 0 {
		out[h/2] = centerIn(mk(1)+paint(pal.Faint, "  │  ")+mk(0), w)
	}
	m.hit = [2]struct{ x, y, w, h int }{{0, 0, w / 2, h}, {w / 2, 0, w - w/2, h}}
	return out
}

// half draws one player's side of the board.
func (m *versusMode) half(p, cols, rows int, flip bool) []string {
	pal := m.c.Pal
	g := m.g
	now := m.now
	if m.canvas[p] == nil || m.canvas[p].Cols != cols || m.canvas[p].Rows != rows {
		m.canvas[p] = braille.New(cols, rows)
	} else {
		m.canvas[p].Clear()
	}
	c := m.canvas[p]
	W, H := float64(c.W), float64(c.H)
	still := m.c.Cfg.Motion == "still"
	anim := m.c.Anim
	col := m.playerColor(p)
	hi := col.Lighten(0.4)

	running := g.State == engine.VersusRunning
	active := running && g.Active == p
	paused := g.State == engine.VersusPaused
	flag := g.State == engine.VersusFlag
	lost := flag && g.Flagged == p
	won := flag && g.Flagged != p
	left := g.Remaining(p, now)

	// state-driven colors
	frame := col
	switch {
	case lost:
		frame = pal.Bad
	case won:
		frame = pal.Good
	}
	digits := pal.Muted
	switch {
	case lost:
		digits = pal.Bad
		if int(anim*3)%2 == 0 && !still {
			digits = pal.Bad.Lighten(0.45)
		}
	case won:
		digits = pal.Good
	case active || paused && g.Active == p:
		digits = pal.Text
		if left <= 20*time.Second {
			digits = pal.Warn
		}
		if left <= 10*time.Second && !still {
			k := 0.5 + 0.5*math.Sin(anim*2*math.Pi*1.8)
			digits = pal.Warn.Mix(pal.Bad, k)
		} else if left <= 10*time.Second {
			digits = pal.Bad
		}
		if paused {
			digits = pal.Muted.Lighten(0.2)
		}
	}

	// a soft wash behind the active (or decided) half
	lit := active || flag
	if lit {
		density := 0.035
		if !still {
			density += 0.02 * (0.5 + 0.5*math.Sin(anim*2))
		}
		wash := pal.Bg.Mix(frame, 0.2)
		for y := 0; y < c.H; y++ {
			for x := 0; x < c.W; x++ {
				if versusHash01(x*7919+y*104729+p*31) < density {
					c.Set(x, y, wash)
				}
			}
		}
	}

	// border: a dotted frame; on the active half a comet runs around it
	inset := 2.0
	bw, bh := W-2*inset, H-2*inset
	if bw > 8 && bh > 8 {
		perim := 2 * (bw + bh)
		head := math.Mod(anim*perim/4.2, perim)
		if still {
			head = perim * 0.12
		}
		step := 3.0
		if lit {
			step = 2.0
		}
		for s := 0.0; s < perim; s += step {
			x, y := versusPerimeter(s, bw, bh)
			x, y = x+inset, y+inset
			base := pal.Bg.Mix(frame, 0.16)
			if lit {
				d := math.Mod(head-s+perim, perim)
				tail := perim * 0.28
				k := 0.0
				if d < tail {
					k = math.Pow(1-d/tail, 1.8)
				}
				base = pal.Bg.Mix(frame, 0.3).Mix(hi, k)
				if flag {
					base = pal.Bg.Mix(frame, 0.8)
				}
			}
			c.Dot(x, y, base)
		}
	}

	// the clock
	text := versusText(left, 0)
	if lost {
		text = "00:00"
	}
	font := braille.ParseFont(m.c.Cfg.Font)
	maxH := int(H * 0.56)
	fh := font.FitHeight(text, int(W*0.84), maxH)
	if fh < 5 {
		fh = 5
	}
	cy := H * 0.46
	if H < 28 {
		cy = H * 0.5
	}
	c.TextCentered(font, text, W/2, cy, fh, braille.Solid(digits))

	// delay window: a thin bar draining under the digits
	if in, dl := g.InDelay(now); in && g.Active == p {
		bwid := W * 0.4
		fillw := bwid * float64(dl) / float64(g.Delay)
		y := cy + float64(fh)/2 + 4
		c.Line(W/2-bwid/2, y, W/2+bwid/2, y, 1, braille.Solid(pal.Bg.Mix(pal.Muted, 0.4)))
		c.Line(W/2-fillw/2, y, W/2+fillw/2, y, 1.6, braille.Solid(hi))
	}

	// moves (as braille digits so the half still reads when rotated)
	if H >= 28 {
		mh := clampi(int(H*0.12), 6, 14)
		mt := fmt.Sprintf("%d", g.Moves[p])
		c.TextCentered(braille.FontLine, mt, W/2, H*0.79, mh, braille.Solid(pal.Muted))
	}
	// player number in the corner
	if H >= 20 && W >= 40 {
		c.Text(braille.FontLine, fmt.Sprintf("%d", p+1), 8, 8, clampi(int(H*0.14), 6, 16), braille.Solid(col))
	}
	// pause icon (two bars)
	if paused {
		bx, by := W-14, 8.0
		c.RoundRect(bx, by, 3, 10, 1.4, braille.Solid(pal.Warn))
		c.RoundRect(bx+6, by, 3, 10, 1.4, braille.Solid(pal.Warn))
	}
	// whose turn: a small triangle marker when it fits
	if active && W >= 40 && H >= 20 {
		tx, ty := W-14.0, H-14.0
		for i := 0; i < 8; i++ {
			c.Line(tx+float64(i)*0.0, ty+float64(i), tx+8-float64(i), ty+float64(i), 1, braille.Solid(hi))
		}
	}

	if flip {
		c = m.rotate(c)
	}
	lines := c.Lines()
	if !flip {
		m.overlay(lines, p, cols, rows, lost, won, paused, active)
	}
	return lines
}

// overlay stamps captions (plain text) onto an unrotated half.
func (m *versusMode) overlay(lines []string, p, cols, rows int, lost, won, paused, active bool) {
	pal := m.c.Pal
	if rows < 6 {
		return
	}
	var txt string
	var col braille.RGB
	switch {
	case lost:
		txt, col = i18n.T("versus.flag"), pal.Bad
	case won:
		txt, col = i18n.T("versus.over"), pal.Good
	case paused:
		txt, col = i18n.T("versus.paused"), pal.Warn
	}
	if txt != "" {
		r := rows - 2
		if r >= 0 && r < len(lines) {
			lines[r] = stamp(lines[r], (cols-width(txt))/2, bold(col, txt))
		}
	}
	if rows >= 10 && cols >= 30 && m.g.Moves[p] > 0 {
		lbl := paint(pal.Faint, i18n.T("versus.moves"))
		r := int(float64(rows)*0.79) + 2
		if r >= 0 && r < len(lines) && r < rows-1 {
			lines[r] = stamp(lines[r], (cols-width(lbl))/2, lbl)
		}
	}
}

// rotate turns a canvas 180 degrees (for the player sitting opposite).
func (m *versusMode) rotate(c *braille.Canvas) *braille.Canvas {
	if m.rot == nil || m.rot.Cols != c.Cols || m.rot.Rows != c.Rows {
		m.rot = braille.New(c.Cols, c.Rows)
	} else {
		m.rot.Clear()
	}
	for y := 0; y < c.H; y++ {
		for x := 0; x < c.W; x++ {
			if c.Has(x, y) {
				m.rot.Set(c.W-1-x, c.H-1-y, c.CellColor(x/2, y/4))
			}
		}
	}
	return m.rot
}

func versusHash01(k int) float64 {
	u := uint32(k)*2654435761 + 97
	u ^= u >> 15
	u *= 2246822519
	u ^= u >> 13
	return float64(u&0xffff) / 65535
}

// versusPerimeter maps a distance along a w x h rectangle's outline to a dot.
func versusPerimeter(s, w, h float64) (x, y float64) {
	switch {
	case s < w:
		return s, 0
	case s < w+h:
		return w, s - w
	case s < 2*w+h:
		return w - (s - w - h), h
	}
	return 0, h - (s - 2*w - h)
}

// ------------------------------------------------------------------ setup

func (m *versusMode) setupView(w, h int) []string {
	pal := m.c.Pal
	total, inc := m.control()
	out := blank(w, h)
	m.chips = m.chips[:0]
	m.chipY = -1
	m.hit = [2]struct{ x, y, w, h int }{}

	title := bold(pal.Accent, versusIcon+" "+strings.ToUpper(i18n.T("versus.setup")))
	timeTxt := fmt.Sprintf("%02d:00", int(total.Minutes()))
	if total >= time.Hour {
		timeTxt = fmt.Sprintf("%d:%02d:00", int(total.Hours()), int(total.Minutes())%60)
	}
	incTxt := paint(pal.Muted, fmt.Sprintf("+%s", i18n.T("versus.secs", int(inc.Seconds()))+" "+i18n.T("versus.inc")))
	if inc == 0 {
		incTxt = paint(pal.Muted, i18n.T("versus.inc")+" "+i18n.T("versus.none"))
	}
	delay := int(m.g.Delay.Seconds())
	delTxt := paint(pal.Muted, i18n.T("versus.delay")+" "+i18n.T("versus.none"))
	if delay > 0 {
		delTxt = paint(pal.Muted, i18n.T("versus.delay")+" "+i18n.T("versus.secs", delay))
	}
	summary := incTxt + paint(pal.Faint, "   ·   ") + delTxt

	// chips row
	var cs strings.Builder
	x := 0
	for i := 0; i <= versusCustom; i++ {
		var lab string
		if i < versusCustom {
			lab = fmt.Sprintf(" %d+%d ", versusPresets[i].min, versusPresets[i].inc)
		} else {
			lab = " " + i18n.T("versus.custom") + " "
		}
		if i == m.set.Preset {
			cs.WriteString(bold(pal.Bg, "\x1b[48;2;"+rgbCSV(pal.Accent)+"m"+lab+"\x1b[49m"))
		} else {
			cs.WriteString(paint(pal.Muted, lab))
		}
		m.chips = append(m.chips, kitchenChip{x: x, w: width(lab), idx: i})
		x += width(lab)
		cs.WriteString(" ")
		x++
	}
	chips := cs.String()
	if width(chips) > w {
		// no room for every chip: show only the selected one
		chips = bold(pal.Accent, "◂ "+m.chipName()+" ▸")
		m.chips = nil
	}

	// who starts + hint
	starts := bold(m.playerColor(m.set.First), "▶ "+i18n.T("versus.starts", m.set.First+1))
	hint := paint(pal.Muted, i18n.T("versus.press"))

	var editLine string
	if m.editing {
		field := func(i int, name, val string) string {
			s := name + " " + val
			if i == m.field {
				return bold(pal.Accent, "◂ "+s+" ▸")
			}
			return paint(pal.Muted, "  "+s+"  ")
		}
		editLine = field(0, i18n.T("versus.minutes"), fmt.Sprintf("%d", m.set.Min)) + field(1, i18n.T("versus.inc"), i18n.T("versus.secs", m.set.Inc)) + field(2, i18n.T("versus.delay"), i18n.T("versus.secs", m.set.Delay))
	}

	// reserve text rows, give the rest to the digits
	textRows := 6
	if editLine != "" {
		textRows++
	}
	digRows := clampi(h-textRows, 0, 14)
	var block []string
	if h >= 9 {
		block = append(block, centerIn(title, w), "")
	}
	if digRows >= 3 {
		cols := w
		if m.canvas[0] == nil || m.canvas[0].Cols != cols || m.canvas[0].Rows != digRows {
			m.canvas[0] = braille.New(cols, digRows)
		} else {
			m.canvas[0].Clear()
		}
		cv := m.canvas[0]
		font := braille.ParseFont(m.c.Cfg.Font)
		fh := font.FitHeight(timeTxt, int(float64(cv.W)*0.7), cv.H-2)
		g := braille.Gradient{pal.Accent, pal.Bright}
		cv.TextCentered(font, timeTxt, float64(cv.W)/2, float64(cv.H)/2, fh, func(x, y float64) braille.RGB {
			return g.At(x / float64(cv.W))
		})
		block = append(block, cv.Lines()...)
	} else {
		block = append(block, centerIn(bold(pal.Text, timeTxt), w))
	}
	block = append(block, centerIn(summary, w))
	if editLine != "" {
		block = append(block, centerIn(editLine, w))
	}
	block = append(block, "", centerIn(chips, w))
	chipRowIdx := len(block) - 1
	block = append(block, "", centerIn(starts+paint(pal.Faint, "   ·   ")+hint, w))

	top := maxi((h-len(block))/2, 0)
	for i, l := range block {
		if top+i < h {
			out[top+i] = l
		}
	}
	if m.chips != nil {
		m.chipY = top + chipRowIdx
		off := (w - width(chips)) / 2
		for i := range m.chips {
			m.chips[i].x += off
		}
	}
	return out
}

func (m *versusMode) chipName() string {
	if m.set.Preset < versusCustom {
		p := versusPresets[m.set.Preset]
		return fmt.Sprintf("%d+%d", p.min, p.inc)
	}
	return i18n.T("versus.custom")
}
