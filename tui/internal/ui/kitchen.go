package ui

import (
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/theme"
)

func init() {
	registerMode("kitchen", func(c *Core, say func(string)) Mode { return newKitchen(c, say) })
}

// kitchenPresets are the quick durations offered while adding a timer.
var kitchenPresets = []time.Duration{
	time.Minute, 3 * time.Minute, 5 * time.Minute, 10 * time.Minute,
	15 * time.Minute, 30 * time.Minute, 45 * time.Minute, time.Hour,
}

type kitchenSlot struct {
	id         int
	x, y, w, h int
}

type kitchenChip struct{ x, w, idx int }

type kitchenMode struct {
	c   *Core
	say func(string)
	k   engine.Kitchen
	now time.Time

	sel     int // selected timer id (0 = none)
	adding  bool
	confirm bool
	input   textinput.Model
	chip    int // selected preset while adding, -1 none

	prog   map[int]*anim.Spring
	mx, my *anim.Spring // selection marker
	mInit  bool
	scroll int

	canvas *braille.Canvas
	slots  []kitchenSlot
	chips  []kitchenChip
	chipY  int
	body   struct{ w, h int }
	cols   int
	markH  int
}

func newKitchen(c *Core, say func(string)) *kitchenMode {
	m := &kitchenMode{c: c, say: say, now: c.Now, chip: -1,
		prog: map[int]*anim.Spring{}, mx: anim.NewSpring(0, 9, 0.8), my: anim.NewSpring(0, 9, 0.8)}
	m.input = textinput.New()
	m.input.SetVirtualCursor(true)
	m.input.CharLimit = 60
	m.load()
	// whatever finished while we were away is logged, never rung
	for _, f := range m.k.Tick(c.Now) {
		c.Log(f.Event())
		m.save()
	}
	if o := m.k.Order(c.Now); len(o) > 0 {
		m.sel = o[0].ID
	}
	return m
}

func (m *kitchenMode) path() string { return filepath.Join(m.c.Store.StateDir, "kitchen.json") }

func (m *kitchenMode) load() {
	if b, err := os.ReadFile(m.path()); err == nil {
		var k engine.Kitchen
		if json.Unmarshal(b, &k) == nil {
			m.k = k
		}
	}
}

func (m *kitchenMode) save() {
	b, err := json.Marshal(&m.k)
	if err != nil {
		return
	}
	tmp := m.path() + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, m.path())
	}
}

func (m *kitchenMode) ID() string { return "kitchen" }

// ------------------------------------------------------------ Background

func (m *kitchenMode) Step(now time.Time, dt time.Duration) []Announce {
	m.now = now
	fin := m.k.Tick(now)
	if len(fin) == 0 {
		return nil
	}
	var out []Announce
	for _, f := range fin {
		m.c.Log(f.Event())
		if f.Late {
			continue
		}
		out = append(out, Announce{Kind: "kitchen", Title: f.Timer.Label, Body: i18n.T("kitchen.done.body"), Ring: true})
	}
	m.save()
	return out
}

func (m *kitchenMode) Runner() *Running {
	n, t := m.k.Running(m.now)
	if n == 0 {
		return nil
	}
	txt := clockText(t.Remaining(m.now))
	if n > 1 {
		txt += " " + i18n.T("kitchen.more", n-1)
	}
	return &Running{Mode: "kitchen", Icon: iconKitchen, Text: txt}
}

func (m *kitchenMode) Title() string {
	n, t := m.k.Running(m.now)
	if n == 0 {
		return ""
	}
	return iconKitchen + " " + clockText(t.Remaining(m.now)) + " " + t.Label
}

func (m *kitchenMode) Capturing() bool { return m.adding || m.confirm }
func (m *kitchenMode) Animated() bool  { return m.c.Cfg.Motion != "still" }

func (m *kitchenMode) Help() []key.Binding {
	switch {
	case m.adding:
		return []key.Binding{
			kb("enter", "enter", i18n.T("key.confirm")),
			kb("left|right", "←→", i18n.T("kitchen.input.presets")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	case m.confirm:
		return []key.Binding{kb("y", "y", i18n.T("key.confirm")), kb("n", "n", i18n.T("key.cancel"))}
	}
	return []key.Binding{
		kb("n", "n", i18n.T("kitchen.add")),
		kb("up|down", "↑↓", i18n.T("kitchen.select")),
		kb("space", "space", i18n.T("kitchen.toggle")),
		kb("r", "r", i18n.T("kitchen.reset")),
		kb("+|-", "+/-", i18n.T("kitchen.time")),
		kb("x", "x", i18n.T("kitchen.delete")),
	}
}

// ------------------------------------------------------------------ input

func (m *kitchenMode) order() []*engine.KitchenTimer { return m.k.Order(m.now) }

func (m *kitchenMode) selected() *engine.KitchenTimer {
	if t := m.k.Get(m.sel); t != nil {
		return t
	}
	if o := m.order(); len(o) > 0 {
		m.sel = o[0].ID
		return o[0]
	}
	return nil
}

func (m *kitchenMode) moveSel(d int) {
	o := m.order()
	if len(o) == 0 {
		return
	}
	idx := 0
	for i, t := range o {
		if t.ID == m.sel {
			idx = i
		}
	}
	idx = clampi(idx+d, 0, len(o)-1)
	m.sel = o[idx].ID
}

func (m *kitchenMode) openInput() tea.Cmd {
	m.adding, m.chip = true, -1
	m.input.SetValue("")
	m.input.Prompt = ""
	m.input.Placeholder = i18n.T("kitchen.input.place")
	pal := m.c.Pal
	st := m.input.Styles()
	st.Focused.Text = lipgloss.NewStyle().Foreground(pal.Text)
	st.Focused.Placeholder = lipgloss.NewStyle().Foreground(pal.Faint)
	st.Focused.Prompt = lipgloss.NewStyle().Foreground(pal.Accent)
	st.Cursor.Blink = false
	st.Cursor.Color = pal.Accent
	m.input.SetStyles(st)
	return m.input.Focus()
}

func (m *kitchenMode) submit() {
	val := strings.TrimSpace(m.input.Value())
	d, label, ok := engine.KitchenParse(val)
	if !ok {
		if m.chip >= 0 {
			d, label, ok = kitchenPresets[m.chip], val, true
		} else if val == "" {
			m.adding = false
			return
		} else {
			m.say(i18n.T("kitchen.invalid"))
			return
		}
	}
	if label == "" {
		label = i18n.T("kitchen.default") + " " + strconv.Itoa(m.k.NextID+1)
	}
	t := m.k.Add(label, d, m.now)
	m.sel = t.ID
	m.adding = false
	m.input.Blur()
	m.save()
	m.say(i18n.T("kitchen.added", label+" · "+fmtDur(d)))
}

func (m *kitchenMode) Update(msg tea.Msg) tea.Cmd {
	now := m.now
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		s := msg.String()
		if m.adding {
			switch s {
			case "esc":
				m.adding = false
				m.input.Blur()
			case "enter":
				m.submit()
			case "tab", "down":
				m.chip = (m.chip + 1) % len(kitchenPresets)
			case "shift+tab", "up":
				m.chip = (m.chip - 1 + len(kitchenPresets)) % len(kitchenPresets)
			case "left", "right":
				if m.input.Value() == "" || m.chip >= 0 && strings.TrimSpace(m.input.Value()) == "" {
					d := 1
					if s == "left" {
						d = -1
					}
					if m.chip < 0 {
						m.chip = 3
					} else {
						m.chip = (m.chip + d + len(kitchenPresets)) % len(kitchenPresets)
					}
				} else {
					var cmd tea.Cmd
					m.input, cmd = m.input.Update(msg)
					return cmd
				}
			default:
				var cmd tea.Cmd
				m.input, cmd = m.input.Update(msg)
				return cmd
			}
			return nil
		}
		if m.confirm {
			if s == "y" || s == "s" || s == "enter" {
				if t := m.selected(); t != nil {
					m.moveSel(-1)
					m.k.Delete(t.ID)
					if m.sel == t.ID {
						m.sel = 0
					}
					m.save()
				}
			}
			m.confirm = false
			return nil
		}
		t := m.selected()
		switch s {
		case "n", "a":
			return m.openInput()
		case "up", "k":
			if m.cols > 1 {
				m.moveSel(-m.cols)
			} else {
				m.moveSel(-1)
			}
		case "down", "j":
			if m.cols > 1 {
				m.moveSel(m.cols)
			} else {
				m.moveSel(1)
			}
		case "left", "h":
			m.moveSel(-1)
		case "right", "l":
			m.moveSel(1)
		case "space", "enter":
			if t != nil {
				if t.Done {
					m.k.Reset(t.ID, now)
				}
				m.k.Toggle(t.ID, now)
				m.save()
			}
		case "r":
			if t != nil {
				m.c.Log(m.k.Reset(t.ID, now)...)
				m.save()
			}
		case "+", "=":
			if t != nil {
				m.k.AddTime(t.ID, time.Minute, now)
				m.save()
			}
		case "-", "_":
			if t != nil {
				m.k.AddTime(t.ID, -time.Minute, now)
				m.save()
			}
		case "x", "delete":
			if t != nil {
				m.confirm = true
			}
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		if m.adding {
			if msg.Y == m.chipY {
				for _, ch := range m.chips {
					if msg.X >= ch.x && msg.X < ch.x+ch.w {
						m.chip = ch.idx
					}
				}
			}
			return nil
		}
		for _, sl := range m.slots {
			if msg.X >= sl.x && msg.X < sl.x+sl.w && msg.Y >= sl.y && msg.Y < sl.y+sl.h {
				if m.sel == sl.id {
					if t := m.k.Get(sl.id); t != nil {
						if t.Done {
							m.k.Reset(t.ID, now)
						}
						m.k.Toggle(t.ID, now)
						m.save()
					}
				}
				m.sel = sl.id
			}
		}
	case tea.MouseWheelMsg:
		if m.adding {
			return nil
		}
		if msg.Button == tea.MouseWheelUp {
			m.moveSel(-1)
		} else if msg.Button == tea.MouseWheelDown {
			m.moveSel(1)
		}
	}
	return nil
}

func (m *kitchenMode) Frame(dt time.Duration) {
	m.now = m.c.Now
	for _, t := range m.k.List {
		sp := m.prog[t.ID]
		if sp == nil {
			sp = anim.NewSpring(t.Progress(m.now), 6, 1)
			m.prog[t.ID] = sp
		}
		sp.Target = t.Progress(m.now)
		sp.Step(dt)
	}
	for id := range m.prog {
		if m.k.Get(id) == nil {
			delete(m.prog, id)
		}
	}
	m.mx.Step(dt)
	m.my.Step(dt)
}

// -------------------------------------------------------------------- view

func (m *kitchenMode) stateColor(t *engine.KitchenTimer) (digits, bar braille.RGB) {
	pal := m.c.Pal
	left := t.Remaining(m.now)
	switch {
	case t.Done:
		if int(m.c.Anim*2.5)%2 == 0 {
			return pal.Good, pal.Good
		}
		return pal.Text, pal.Good.Lighten(0.4)
	case t.Run == engine.Paused || t.Run == engine.Idle:
		return pal.Muted, pal.Muted.Mix(pal.Bg, 0.3)
	case left <= 10*time.Second:
		k := 0.5 + 0.5*math.Sin(m.c.Anim*2*math.Pi*1.6)
		if m.c.Cfg.Motion == "still" {
			k = 1
		}
		return pal.Warn.Mix(pal.Bad, k*0.7), pal.Warn.Mix(pal.Bad, k*0.5)
	}
	return pal.Text, pal.Accent
}

func (m *kitchenMode) View(w, h int) string {
	if w < 4 || h < 1 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	m.body.w, m.body.h = w, h
	pal := m.c.Pal
	order := m.order()
	m.slots, m.chips = m.slots[:0], m.chips[:0]

	// header and bottom bar
	top := 0
	if h >= 8 {
		top = 1
	}
	bottom := 0
	switch {
	case m.adding:
		bottom = 2
	case m.confirm:
		bottom = 1
	}
	if h-top-bottom < 1 {
		top, bottom = 0, 0
	}
	areaH := h - top - bottom

	var out []string
	if len(order) == 0 && !m.adding {
		out = m.emptyView(w, areaH)
	} else {
		out = m.cards(w, areaH, order)
	}
	// compose: header + area + bottom
	lines := make([]string, 0, h)
	if top == 1 {
		lines = append(lines, m.header(w, order))
	}
	lines = append(lines, out...)
	switch {
	case m.adding:
		lines = append(lines, m.inputLines(w)...)
		m.chipY = len(lines) - 1
	case m.confirm:
		lbl := ""
		if t := m.selected(); t != nil {
			lbl = t.Label
		}
		lines = append(lines, centerIn(paint(pal.Warn, i18n.T("kitchen.confirm", lbl)), w))
	}
	return join(fit(lines, w, h))
}

func (m *kitchenMode) header(w int, order []*engine.KitchenTimer) string {
	pal := m.c.Pal
	n, _ := m.k.Running(m.now)
	cnt := i18n.T("kitchen.count", len(order))
	if len(order) == 1 {
		cnt = i18n.T("kitchen.count.1")
	}
	left := " " + bold(pal.Accent, iconKitchen+" "+i18n.T("kitchen.title")) + paint(pal.Faint, "  ·  ") + paint(pal.Muted, cnt)
	if n > 0 {
		left += paint(pal.Faint, "  ·  ") + paint(pal.Accent, i18n.T("kitchen.running", n))
	}
	return padRight(left, w)
}

func (m *kitchenMode) inputLines(w int) []string {
	pal := m.c.Pal
	m.input.SetWidth(clampi(w-24, 10, 50))
	line1 := " " + bold(pal.Accent, i18n.T("kitchen.input.prompt")+"▸ ") + m.input.View()
	// chips
	var sb strings.Builder
	x := 1
	sb.WriteString(" ")
	for i, d := range kitchenPresets {
		lab := " " + kitchenShortDur(d) + " "
		if i == m.chip {
			sb.WriteString(bold(pal.Bg, "\x1b[48;2;"+rgbCSV(pal.Accent)+"m"+lab+"\x1b[49m"))
		} else {
			sb.WriteString(paint(pal.Muted, lab))
		}
		m.chips = append(m.chips, kitchenChip{x: x, w: width(lab), idx: i})
		x += width(lab)
		sb.WriteString(" ")
		x++
	}
	chips := sb.String()
	return []string{padRight(line1, w), padRight(chips, w)}
}

func kitchenShortDur(d time.Duration) string {
	if d%time.Hour == 0 {
		return strconv.Itoa(int(d/time.Hour)) + "h"
	}
	return strconv.Itoa(int(d/time.Minute)) + "m"
}

func (m *kitchenMode) kcols(w, n int) int {
	cols := 1
	switch {
	case w >= 112:
		cols = 3
	case w >= 68:
		cols = 2
	}
	if n < cols {
		cols = maxi(n, 1)
	}
	return cols
}

// cards lays out and draws the timer cards in the area.
func (m *kitchenMode) cards(w, h int, order []*engine.KitchenTimer) []string {
	pal := m.c.Pal
	n := len(order)
	if n == 0 {
		return blank(w, h)
	}
	cols := m.kcols(w, n)
	m.cols = cols
	rows := (n + cols - 1) / cols
	cardH := clampi(h/rows, 1, 17)
	visRows := maxi(h/cardH, 1)
	selRow := 0
	for i, t := range order {
		if t.ID == m.sel {
			selRow = i / cols
		}
	}
	if rows > visRows {
		m.scroll = clampi(m.scroll, selRow-visRows+1, selRow)
		m.scroll = clampi(m.scroll, 0, rows-visRows)
	} else {
		m.scroll = 0
	}
	shown := mini(rows, visRows)
	top := (h - shown*cardH) / 2
	if rows > visRows {
		top = 0
	}
	gap := 2
	cardW := (w - (cols-1)*gap) / cols

	if m.canvas == nil || m.canvas.Cols != w || m.canvas.Rows != h {
		m.canvas = braille.New(w, h)
	} else {
		m.canvas.Clear()
	}
	cv := m.canvas
	type textOp struct {
		row, col int
		s        string
	}
	var texts []textOp

	for i, t := range order {
		row, col := i/cols-m.scroll, i%cols
		if row < 0 || row >= visRows {
			continue
		}
		x, y := col*(cardW+gap), top+row*cardH
		m.slots = append(m.slots, kitchenSlot{id: t.ID, x: x, y: y + m.topOffset(), w: cardW, h: cardH})
		isSel := t.ID == m.sel
		digCol, barCol := m.stateColor(t)
		sp := m.prog[t.ID]
		p := t.Progress(m.now)
		if sp != nil {
			p = kitchenClamp01(sp.Pos)
		}
		if t.Done {
			p = 1
		}
		inX := x + 2
		inW := cardW - 2
		if inW < 4 {
			continue
		}
		// state caption (right)
		var cap string
		switch {
		case t.Done:
			cap = bold(digCol, i18n.T("kitchen.done"))
		case t.Run == engine.Paused:
			cap = paint(pal.Muted, i18n.T("kitchen.paused"))
		case t.Run == engine.Idle:
			cap = paint(pal.Muted, i18n.T("kitchen.ready"))
		default:
			cap = paint(pal.Muted, i18n.T("kitchen.ends", t.EndsAt.Format("15:04")))
		}
		lblStyle := func(s string) string {
			if isSel {
				return bold(pal.Text, s)
			}
			return paint(pal.Muted, s)
		}
		timeTxt := clockText(t.Remaining(m.now))
		label := kitchenTruncate(t.Label, maxi(inW-width(timeTxt)-2, 4))

		markH, markYOff := 1, 0
		switch {
		case cardH >= 7: // big: label, braille digits, bar
			digRows := clampi(cardH-3, 4, 14)
			dh := braille.ParseFont(m.c.Cfg.Font)
			hDots := dh.FitHeight(timeTxt, inW*2-4, digRows*4-2)
			if hDots < 6 {
				hDots = 6
			}
			used := (hDots + 3) / 4 // rows the digits really take
			contentH := 1 + used + 1 + 1
			markH = contentH
			y0 := y + maxi((cardH-contentH)/2, 0)
			markYOff = y0 - y
			texts = append(texts, textOp{y0, inX, lblStyle(kitchenTruncate(t.Label, maxi(inW-width(cap)-2, 4)))})
			if inW-width(cap)-width(t.Label) >= 2 {
				texts = append(texts, textOp{y0, inX + inW - width(cap), cap})
			}
			cv.Text(dh, timeTxt, float64(inX*2), float64((y0+1)*4+1), hDots, braille.Solid(digCol))
			kitchenBar(cv, inX*2, (inX+inW)*2-2, (y0+1+used)*4, p, barCol, m.c.Pal, t.Run == engine.Running && !t.Done, m.c.Cfg.Motion != "still", m.c.Anim)
		case cardH >= 5: // mid
			markH = 5
			texts = append(texts, textOp{y, inX, lblStyle(kitchenTruncate(t.Label, maxi(inW-width(cap)-2, 4)))})
			if inW-width(cap)-width(t.Label) >= 2 {
				texts = append(texts, textOp{y, inX + inW - width(cap), cap})
			}
			dh := braille.ParseFont(m.c.Cfg.Font)
			hDots := dh.FitHeight(timeTxt, inW*2-4, 3*4-1)
			cv.Text(dh, timeTxt, float64(inX*2), float64((y+1)*4), maxi(hDots, 6), braille.Solid(digCol))
			kitchenBar(cv, inX*2, (inX+inW)*2-2, (y+4)*4, p, barCol, m.c.Pal, t.Run == engine.Running && !t.Done, m.c.Cfg.Motion != "still", m.c.Anim)
		case cardH >= 3: // small: label + time on one row, bar below
			markH = 2
			texts = append(texts, textOp{y, inX, lblStyle(label) + "  " + bold(digCol, timeTxt)})
			if inW >= width(label)+width(timeTxt)+width(cap)+6 {
				texts = append(texts, textOp{y, inX + inW - width(cap), cap})
			}
			kitchenBar(cv, inX*2, (inX+inW)*2-2, (y+1)*4, p, barCol, m.c.Pal, t.Run == engine.Running && !t.Done, m.c.Cfg.Motion != "still", m.c.Anim)
		default: // line: "label  time  ▃▃▃▃░░░"
			head := lblStyle(kitchenTruncate(t.Label, maxi(inW/3, 3))) + "  " + bold(digCol, timeTxt) + "  "
			hw := width(head)
			texts = append(texts, textOp{y, inX, head})
			if inW-hw >= 6 {
				kitchenBar(cv, (inX+hw)*2, (inX+inW)*2-2, y*4, p, barCol, m.c.Pal, false, false, m.c.Anim)
			}
		}
		// selection marker target
		if isSel {
			m.markTarget(float64(x), float64(y+markYOff), markH)
		}
	}

	lines := cv.Lines()
	for _, op := range texts {
		if op.row >= 0 && op.row < len(lines) {
			lines[op.row] = stamp(lines[op.row], op.col, op.s)
		}
	}
	// the marker: a bar that springs from card to card
	mxp, myp := int(math.Round(m.mx.Pos)), int(math.Round(m.my.Pos))
	mh := maxi(m.markH, 1)
	for r := 0; r < mh; r++ {
		if yy := myp + r; yy >= 0 && yy < len(lines) && mxp >= 0 && mxp < w {
			lines[yy] = stamp(lines[yy], mxp, bold(pal.Accent, "▌"))
		}
	}
	// scroll hints
	if m.scroll > 0 && len(lines) > 0 {
		lines[0] = stamp(lines[0], w-2, paint(pal.Muted, "▲"))
	}
	if rows > visRows && m.scroll < rows-visRows && len(lines) > 0 {
		lines[len(lines)-1] = stamp(lines[len(lines)-1], w-2, paint(pal.Muted, "▼"))
	}
	return lines
}

func kitchenBoolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

func kitchenClamp01(v float64) float64 {
	return math.Max(0, math.Min(1, v))
}

// topOffset is the header row (mouse hit rectangles are body relative).
func (m *kitchenMode) topOffset() int {
	if m.body.h >= 8 {
		return 1
	}
	return 0
}

func (m *kitchenMode) markTarget(x, y float64, h int) {
	m.markH = h
	m.mx.Target, m.my.Target = x, y
	if !m.mInit {
		m.mx.Snap(x)
		m.my.Snap(y)
		m.mInit = true
	}
}

func kitchenTruncate(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	if n <= 1 {
		return string(r[:maxi(n, 0)])
	}
	return string(r[:n-1]) + "…"
}

// kitchenBar draws a progress bar on the dot row y: a thin dotted track, a
// gradient fill and (while running) a glowing head.
func kitchenBar(cv *braille.Canvas, x0, x1, y int, p float64, col braille.RGB, pal theme.Palette, head, anim bool, t float64) {
	if x1 <= x0 {
		return
	}
	track := pal.Bg.Mix(col, 0.22)
	length := float64(x1 - x0)
	fill := p * length
	grad := braille.Gradient{col.Darken(0.35), col, col.Lighten(0.35)}
	for x := x0; x <= x1; x++ {
		cv.Set(x, y+2, track)
	}
	for x := x0; x < x0+int(fill+0.5); x++ {
		k := float64(x-x0) / math.Max(length, 1)
		c := grad.At(k)
		cv.Set(x, y+1, c)
		cv.Set(x, y+2, c)
		cv.Set(x, y+3, c.Darken(0.15))
	}
	if head && fill > 1 {
		hx := float64(x0) + fill
		r := 2.0
		if anim {
			r += 0.6 * math.Sin(t*5)
		}
		cv.Disc(hx, float64(y)+2, r, braille.Solid(col.Lighten(0.55)))
	}
}

// emptyView is a pot with rising steam and a hint.
func (m *kitchenMode) emptyView(w, h int) []string {
	pal := m.c.Pal
	rows := clampi(h-3, 0, 12)
	var lines []string
	if rows >= 4 && w >= 20 {
		cols := clampi(rows*3, 12, w)
		if m.canvas == nil || m.canvas.Cols != cols || m.canvas.Rows != rows {
			m.canvas = braille.New(cols, rows)
		} else {
			m.canvas.Clear()
		}
		c := m.canvas
		W, H := float64(c.W), float64(c.H)
		cx := W / 2
		bodyW, bodyH := math.Min(W*0.5, H*1.3), H*0.34
		by := H - bodyH - 2
		col := pal.Muted
		c.RoundRect(cx-bodyW/2, by, bodyW, bodyH, bodyH*0.3, braille.Solid(col.Mix(pal.Bg, 0.35)))
		c.Line(cx-bodyW/2-3, by+bodyH*0.3, cx-bodyW/2-1, by+bodyH*0.3, 2, braille.Solid(col))
		c.Line(cx+bodyW/2+1, by+bodyH*0.3, cx+bodyW/2+3, by+bodyH*0.3, 2, braille.Solid(col))
		c.Line(cx-bodyW/2-1, by-1, cx+bodyW/2+1, by-1, 2, braille.Solid(col))
		c.Disc(cx, by-3, 1.6, braille.Solid(pal.Accent))
		// steam
		t := m.c.Anim
		if m.c.Cfg.Motion == "still" {
			t = 0.6
		}
		for i := 0; i < 3; i++ {
			sx := cx + float64(i-1)*bodyW*0.28
			for k := 0; k < 26; k++ {
				ph := math.Mod(t*0.35+float64(i)*0.31+float64(k)/26*0.55, 1)
				y := by - 6 - ph*(by-8)
				x := sx + math.Sin(ph*7+float64(i)*2+t)*3.5*ph
				a := math.Sin(ph * math.Pi)
				c.Dot(x, y, pal.Bg.Mix(pal.Accent.Lighten(0.2), 0.12+0.5*a))
			}
		}
		for _, l := range c.Lines() {
			lines = append(lines, centerIn(l, w))
		}
	}
	lines = append(lines, "", centerIn(bold(pal.Text, i18n.T("kitchen.empty")), w), centerIn(paint(pal.Muted, i18n.T("kitchen.empty.hint")), w))
	out := blank(w, h)
	topRow := maxi((h-len(lines))/2, 0)
	for i, l := range lines {
		if topRow+i < h {
			out[topRow+i] = l
		}
	}
	return out
}
