package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// intervalsView is the data every drawing routine needs for one frame.
type intervalsView struct {
	plan  engine.IntervalsPlan
	pt    engine.IntervalsPoint
	idle  bool
	run   engine.Run
	col   braille.RGB // the mood color
	hi    braille.RGB
	still bool
}

func (m *intervalsMode) viewData() intervalsView {
	run := &m.f.Run
	v := intervalsView{plan: m.plan(), idle: !run.Active(), run: run.Run, still: m.c.Cfg.Motion == "still"}
	if !v.idle {
		v.plan = run.Plan
	}
	v.pt = v.plan.At(run.Elapsed(m.c.Now))
	v.col = m.mood()
	f := m.flash()
	v.col = v.col.Mix(braille.RGB{R: 255, G: 255, B: 255}, 0.25*f)
	v.hi = v.col.Lighten(0.4)
	return v
}

// phaseWord is the big word for the current state.
func (m *intervalsMode) phaseWord(v intervalsView) string {
	if v.idle {
		return m.presetName()
	}
	if v.pt.Done {
		return i18n.T("intervals.phase.ready")
	}
	return i18n.T("intervals.phase." + string(v.pt.Seg.Phase))
}

func (m *intervalsMode) digitsText(v intervalsView) string {
	if v.idle {
		return clockText(v.plan.Total())
	}
	return clockText(v.pt.Left)
}

func (m *intervalsMode) View(w, h int) string {
	m.hits = m.hits[:0]
	if w < 12 || h < 3 {
		return join(blank(w, h))
	}
	v := m.viewData()
	if h < 11 || w < 40 {
		return join(fit(m.tiny(w, h, v), w, h))
	}

	wordCol := v.col
	if !v.idle && v.run == engine.Paused && math.Mod(m.t, 1.4) > 0.9 {
		wordCol = m.c.Pal.Muted
	}
	word := m.phaseWord(v)
	maxWordH := clampi(h*4*24/100, 7, 56)
	p := intervalsWordSize(word, w*2*90/100, maxWordH)
	var top []string
	if p == 0 {
		top = []string{centerIn(bold(wordCol, strings.ToUpper(word)), w), spaces(w)}
	} else {
		rows := (7*p+3)/4 + 1
		if m.word == nil || m.word.Cols != w || m.word.Rows != rows {
			m.word = braille.New(w, rows)
		} else {
			m.word.Clear()
		}
		intervalsDrawWord(m.word, word, float64(m.word.W)/2, float64(m.word.H)/2, p, wordCol)
		top = append(m.word.Lines(), spaces(w))
	}
	mainH := h - len(top)
	if mainH < 4 {
		return join(fit(m.tiny(w, h, v), w, h))
	}

	var body []string
	wide := w >= 100 && h >= 24
	if wide {
		panelW := clampi(w*32/100, 34, 48)
		areaW := w - panelW - 2
		sc, left, topPad := m.sceneBlock(areaW, mainH, v)
		panel := m.panel(panelW, mainH, len(top), areaW+2, v)
		main := hcat(sc, blank(2, mainH), panel)
		m.hits = append(m.hits, intervalsHit{x: left, y: len(top) + topPad, w: m.sceneW(), h: m.sceneH(), field: -1})
		body = append(top, main...)
	} else {
		infoRows := 0
		switch {
		case mainH >= 18:
			infoRows = 4
		case mainH >= 14:
			infoRows = 3
		case mainH >= 10:
			infoRows = 2
		}
		sc, left, topPad := m.sceneBlock(w, mainH-infoRows, v)
		m.hits = append(m.hits, intervalsHit{x: left, y: len(top) + topPad, w: m.sceneW(), h: m.sceneH(), field: -1})
		body = append(top, sc...)
		if infoRows > 0 {
			body = append(body, m.info(w, infoRows, len(body), v)...)
		}
	}
	return join(fit(body, w, h))
}

func (m *intervalsMode) sceneW() int {
	if m.scene == nil {
		return 0
	}
	return m.scene.Cols
}

func (m *intervalsMode) sceneH() int {
	if m.scene == nil {
		return 0
	}
	return m.scene.Rows
}

// sceneBlock draws the ring scene centered in an aw x ah area. It returns the
// lines plus the left/top padding of the scene (for mouse hits).
func (m *intervalsMode) sceneBlock(aw, ah int, v intervalsView) ([]string, int, int) {
	rows := mini(ah, aw/2)
	cols := rows * 2
	if rows < 3 || cols < 6 {
		rows, cols = maxi(ah, 1), maxi(aw, 1)
	}
	if m.scene == nil || m.scene.Cols != cols || m.scene.Rows != rows {
		m.scene = braille.New(cols, rows)
	} else {
		m.scene.Clear()
	}
	labels := m.drawScene(m.scene, v)
	lines := m.scene.Lines()
	overlayLabels(lines, labels)
	top, left := (ah-rows)/2, (aw-cols)/2
	out := blank(aw, ah)
	for i, l := range lines {
		if top+i < ah {
			out[top+i] = padRight(spaces(left)+l, aw)
		}
	}
	return out, left, top
}

// ------------------------------------------------------------------- scene

func (m *intervalsMode) drawScene(c *braille.Canvas, v intervalsView) []visual.Label {
	pal := m.c.Pal
	W, H := float64(c.W), float64(c.H)
	cx, cy := W/2, H/2
	R := math.Min(W, H)/2 - 2
	if R < 6 {
		return nil
	}
	col, hi := v.col, v.hi
	pt := v.pt

	// the wash that sweeps outward at every phase change
	if f := m.flash(); f > 0 {
		maxR := math.Hypot(cx, cy)
		rad := (1-f)*maxR*1.05 + R*0.15
		th := R*0.35*f + 2
		for y := 0; y < c.H; y++ {
			for x := 0; x < c.W; x++ {
				d := math.Hypot(float64(x)-cx, float64(y)-cy)
				if math.Abs(d-rad) > th {
					continue
				}
				k := 1 - math.Abs(d-rad)/th
				if anim.Hash01(uint32(x*7919+y*104729)) < f*k*0.85 {
					c.Set(x, y, pal.Bg.Mix(hi, 0.25+0.55*f))
				}
			}
		}
	}

	total := v.pt.Total
	elapsedFrac := 0.0
	if total > 0 {
		elapsedFrac = float64(pt.Elapsed) / float64(total)
	}
	if v.idle {
		elapsedFrac = 0
	}

	// outer ring: the whole workout laid out, filling up as it is done
	ringR := R
	if R >= 26 {
		ot := clamp01to(R*0.035, 1.5, 3)
		m.timelineRing(c, cx, cy, R-ot/2, ot, v, elapsedFrac)
		ringR = R - ot - 4
	}
	th := clamp01to(R*0.07, 2, 6)
	R2 := ringR - th/2
	if R2 < 5 {
		return nil
	}

	// progress of the current segment: work drains, everything else fills
	frac := 1.0
	if !v.idle && !pt.Done {
		frac = pt.Progress()
		if pt.Seg.Phase == engine.IntervalsWork {
			frac = 1 - frac
		}
	}
	grad := braille.Gradient{col.Darken(0.42), col, hi}
	track := pal.Bg.Mix(col, 0.2)
	running := v.run == engine.Running

	var hx, hy float64
	haveHead := false
	if m.f.Style == "hex" {
		hx, hy, haveHead = intervalsHex(c, cx, cy, R2, th, frac, grad, track, hi)
	} else {
		c.Ring(cx, cy, R2, th, braille.Solid(track))
		if frac > 0.002 {
			end := frac * 2 * math.Pi
			c.Arc(cx, cy, R2, th, 0, end, true, func(x, y float64) braille.RGB {
				a := braille.Angle(cx, cy, x, y)
				if a > end+0.3 {
					a = 0
				}
				k := a / (2 * math.Pi)
				cc := grad.At(k)
				if d := end - a; d >= 0 && d < 0.5 {
					cc = cc.Mix(hi.Lighten(0.35), math.Pow(1-d/0.5, 1.6))
				}
				return cc
			})
			hx, hy = braille.Polar(cx, cy, R2, end)
			haveHead = true
		}
	}
	if haveHead && !v.idle {
		c.Disc(hx, hy, th*0.62, braille.Solid(hi.Lighten(0.55)))
	}

	// the last three seconds: a ripple per second and warm digits
	urgent := running && !pt.Done && pt.Seg.Len > 4*time.Second && pt.Left <= 3*time.Second
	warm := 0.0
	if urgent {
		fr := 1 - float64(pt.Left%time.Second)/float64(time.Second)
		if pt.Left%time.Second == 0 {
			fr = 0
		}
		warm = 1 - fr
		if !v.still {
			rr := R2 + th/2 + 2 + fr*(R-R2)*0.9
			c.Arc(cx, cy, rr, 1.4, 0, 2*math.Pi, false, braille.Solid(pal.Bg.Mix(pal.Warn, 1-fr)))
		}
	}

	// digits
	text := m.digitsText(v)
	font := braille.ParseFont(m.c.Cfg.Font)
	ri := R2 - th/2 - 4
	maxW, maxH := int(ri*1.8), int(ri*0.85)
	dh := font.FitHeight(text, maxW, maxH)
	if dh < 5 {
		dh = 5
	}
	dcy := cy - ri*0.08
	dw := font.TextWidth(text, dh)
	c.Erase(int(cx)-dw/2-2, int(dcy)-dh/2-2, dw+4, dh+4)
	dcol := pal.Text
	if urgent {
		dcol = pal.Text.Mix(pal.Warn, 0.4+0.55*warm)
	} else if !v.idle && v.run == engine.Paused && math.Mod(m.t, 1.4) > 0.9 {
		dcol = pal.Muted
	}
	c.TextCentered(font, text, cx, dcy, dh, braille.Solid(dcol))

	// caption under the digits
	var sub string
	switch {
	case v.idle:
		sub = m.summary()
	case v.run == engine.Paused:
		sub = i18n.T("state.paused")
	case pt.Seg.Round > 0:
		sub = i18n.T("intervals.round", pt.Seg.Round, pt.Rounds)
	}
	var labels []visual.Label
	if sub != "" {
		row := int(dcy+float64(dh)/2)/4 + 1
		if row < c.Rows {
			scol := col
			if v.run == engine.Paused {
				scol = pal.Muted
			}
			labels = append(labels, visual.Label{Col: int(cx) / 2, Row: row, Text: sub, Color: scol, Bold: true, Center: true})
		}
	}
	return labels
}

func clamp01to(v, lo, hi float64) float64 { return math.Max(lo, math.Min(hi, v)) }

// timelineRing paints every segment of the workout around a circle: bright up
// to the elapsed point, dim after it, with small gaps between segments.
func (m *intervalsMode) timelineRing(c *braille.Canvas, cx, cy, r, th float64, v intervalsView, elapsed float64) {
	pal := m.c.Pal
	segs := v.plan.Segments()
	total := v.plan.Total()
	if len(segs) == 0 || total <= 0 {
		return
	}
	type arc struct {
		a0, a1 float64
		col    braille.RGB
	}
	arcs := make([]arc, len(segs))
	for i, s := range segs {
		arcs[i] = arc{float64(s.Start) / float64(total), float64(s.End()) / float64(total), m.phaseColor(s.Phase)}
	}
	gap := 0.0
	if len(segs) <= 40 {
		gap = 1.3 / (2 * math.Pi * r) // ~1.3 dots
	}
	half := th / 2
	lo2, hi2 := (r-half)*(r-half), (r+half)*(r+half)
	x0, x1 := clampi(int(cx-r-half-1), 0, c.W-1), clampi(int(cx+r+half+1), 0, c.W-1)
	y0, y1 := clampi(int(cy-r-half-1), 0, c.H-1), clampi(int(cy+r+half+1), 0, c.H-1)
	for y := y0; y <= y1; y++ {
		for x := x0; x <= x1; x++ {
			dx, dy := float64(x)-cx, float64(y)-cy
			d2 := dx*dx + dy*dy
			if d2 < lo2 || d2 > hi2 {
				continue
			}
			u := braille.Angle(cx, cy, float64(x), float64(y)) / (2 * math.Pi)
			for i, a := range arcs {
				if u < a.a0 || u >= a.a1 {
					continue
				}
				if gap > 0 && (u-a.a0 < gap/2 || a.a1-u < gap/2) {
					break
				}
				cc := a.col
				switch {
				case u < elapsed:
					// done
				default:
					k := 0.3
					if segs[i].Phase.IsRest() {
						k = 0.18
					}
					if v.idle {
						k += 0.18
					}
					cc = pal.Bg.Mix(a.col, k)
				}
				c.Set(x, y, cc)
				break
			}
		}
	}
	if !v.idle && !v.pt.Done {
		ex, ey := braille.Polar(cx, cy, r, elapsed*2*math.Pi)
		c.Disc(ex, ey, th*0.9, braille.Solid(v.hi.Lighten(0.4)))
	}
}

// intervalsHex draws the hexagon face: a pointy-top hexagon whose perimeter is
// the segment's progress.
func intervalsHex(c *braille.Canvas, cx, cy, R, th, frac float64, grad braille.Gradient, track, hi braille.RGB) (float64, float64, bool) {
	pointAt := func(u float64) (float64, float64) {
		u = math.Mod(u, 1)
		if u < 0 {
			u += 1
		}
		side := u * 6
		i := int(side)
		t := side - float64(i)
		ax, ay := braille.Polar(cx, cy, R, float64(i)*math.Pi/3)
		bx, by := braille.Polar(cx, cy, R, float64(i+1)*math.Pi/3)
		return ax + (bx-ax)*t, ay + (by-ay)*t
	}
	perim := 6 * R
	steps := int(perim / 0.6)
	rad := th / 2
	for i := 0; i < steps; i++ {
		u := float64(i) / float64(steps)
		x, y := pointAt(u)
		if u <= frac {
			col := grad.At(u)
			if d := frac - u; d < 0.05 {
				col = col.Mix(hi.Lighten(0.35), 1-d/0.05)
			}
			c.Disc(x, y, rad, braille.Solid(col))
		} else {
			c.Disc(x, y, rad*0.75, braille.Solid(track))
		}
	}
	if frac <= 0.002 {
		return 0, 0, false
	}
	x, y := pointAt(frac)
	return x, y, true
}

// ------------------------------------------------------------------- ladder

// drawLadder paints one bar per round: done ones dim, the current one filling,
// the rest waiting. With a ramp the bars grow like a staircase.
func (m *intervalsMode) drawLadder(c *braille.Canvas, v intervalsView) {
	pal := m.c.Pal
	n := v.plan.Rounds
	W, H := c.W, c.H
	if n < 1 || W < 4 || H < 4 {
		return
	}
	pitch := clampi(W/n, 2, 10)
	vis := W / pitch
	if vis > n {
		vis = n
	}
	cur := 0 // round in progress (1-based), 0 = none yet
	switch {
	case v.idle:
		cur = 0
	case v.pt.Done || v.pt.Seg.Phase == engine.IntervalsCool:
		cur = n + 1
	case v.pt.Seg.Round > 0:
		cur = v.pt.Seg.Round
	}
	first := 1
	if vis < n {
		first = clampi(cur-vis/2, 1, n-vis+1)
	}
	barW := pitch - 1
	if pitch >= 5 {
		barW = pitch - 2
	}
	left := (W - vis*pitch) / 2
	maxWork := float64(v.plan.WorkAt(n))
	pulse := 0.8 + 0.2*math.Sin(m.t*6)
	if v.still {
		pulse = 1
	}
	for i := 0; i < vis; i++ {
		r := first + i
		bh := float64(H - 2)
		if v.plan.Ramp > 0 {
			bh = float64(H-2) * (0.3 + 0.7*float64(v.plan.WorkAt(r))/maxWork)
		}
		x := float64(left + i*pitch)
		y := float64(H-1) - bh
		rad := math.Min(float64(barW)/2, 2)
		switch {
		case r < cur:
			c.RoundRect(x, y, float64(barW), bh, rad, braille.Solid(pal.Bg.Mix(v.col, 0.62)))
		case r == cur:
			fill := 1.0
			if v.pt.Seg.Phase == engine.IntervalsWork {
				fill = v.pt.Progress()
			}
			c.RoundRect(x, y, float64(barW), bh, rad, braille.Solid(pal.Bg.Mix(v.col, 0.32)))
			fh := bh * fill
			if fh >= 1 {
				c.RoundRect(x, float64(H-1)-fh, float64(barW), fh, rad, braille.Solid(v.hi.Mix(v.col, 1-pulse)))
			}
		default:
			c.RoundRect(x, y, float64(barW), bh, rad, braille.Solid(pal.Bg.Mix(v.col, 0.3)))
		}
	}
}

func (m *intervalsMode) ladderLines(w, rows int, v intervalsView) []string {
	if m.ladder == nil || m.ladder.Cols != w || m.ladder.Rows != rows {
		m.ladder = braille.New(w, rows)
	} else {
		m.ladder.Clear()
	}
	m.drawLadder(m.ladder, v)
	return m.ladder.Lines()
}

// ------------------------------------------------------------------- text bits

// bar is a one-line braille progress bar.
func (m *intervalsMode) bar(w int, frac float64, col braille.RGB) string {
	pal := m.c.Pal
	if w < 1 {
		return ""
	}
	n := int(frac*float64(w) + 0.5)
	if n > w {
		n = w
	}
	return paint(col, strings.Repeat("⣿", n)) + paint(pal.Faint, strings.Repeat("⣀", w-n))
}

func (m *intervalsMode) nextText(v intervalsView) (string, braille.RGB) {
	pal := m.c.Pal
	if v.idle {
		return i18n.T("intervals.total", fmtDur(v.plan.Total())), pal.Muted
	}
	if v.pt.Next == nil {
		return i18n.T("intervals.last"), pal.Muted
	}
	n := v.pt.Next
	return i18n.T("intervals.next", i18n.T("intervals.phase."+string(n.Phase)), fmtDur(n.Len)), m.phaseColor(n.Phase)
}

func (m *intervalsMode) timesText(v intervalsView) string {
	if v.idle {
		return ""
	}
	left := v.pt.Total - v.pt.Elapsed
	s := clockText(v.pt.Elapsed) + " / " + clockText(v.pt.Total)
	if v.run == engine.Running {
		s += " · " + i18n.T("pomo.ends", m.c.Now.Add(left).Format("15:04"))
	}
	return s
}

// chips renders the plan fields as one row (compact layout) and records hits.
func (m *intervalsMode) chips(w, y int) string {
	pal := m.c.Pal
	var parts []string
	var ws []int
	for f := intervalsField(0); f < intervalsFields; f++ {
		txt := m.fieldLabel(f) + " " + m.fieldValue(f)
		parts = append(parts, txt)
		ws = append(ws, width(txt)+2)
	}
	total := 0
	for _, x := range ws {
		total += x + 1
	}
	if total-1 > w {
		// not everything fits: just the focused field with arrows
		txt := "‹ " + m.fieldLabel(m.focus) + " " + m.fieldValue(m.focus) + " ›"
		x := (w - width(txt)) / 2
		m.hits = append(m.hits, intervalsHit{x: maxi(x, 0), y: y, w: width(txt), h: 1, field: int(m.focus)})
		return centerIn(bold(pal.Accent, txt), w)
	}
	x := (w - (total - 1)) / 2
	var sb strings.Builder
	sb.WriteString(spaces(x))
	for i, txt := range parts {
		var chip string
		if intervalsField(i) == m.focus {
			chip = bold(pal.Accent, "["+txt+"]")
		} else {
			chip = paint(pal.Muted, " "+txt+" ")
		}
		m.hits = append(m.hits, intervalsHit{x: x, y: y, w: ws[i], h: 1, field: i})
		sb.WriteString(chip + " ")
		x += ws[i] + 1
	}
	return padRight(sb.String(), w)
}

// info is the strip under the scene in the compact layout.
func (m *intervalsMode) info(w, rows, y0 int, v intervalsView) []string {
	pal := m.c.Pal
	out := make([]string, 0, rows)
	if v.idle {
		out = append(out, m.chips(w, y0))
		out = append(out, centerIn(paint(pal.Muted, i18n.T("intervals.total", fmtDur(v.plan.Total()))+"  ·  ")+paint(v.col, i18n.T("pomo.press")), w))
		for len(out) < rows {
			if len(out) == 2 {
				out = append(out, centerIn(m.ladderLines(clampi(w/2, 8, 60), 1, v)[0], w))
			} else {
				out = append(out, spaces(w))
			}
		}
		return out[:rows]
	}
	nt, nc := m.nextText(v)
	out = append(out, centerIn(bold(nc, "▸ "+nt), w))
	times := m.timesText(v)
	if width(times)+10 > w {
		times = clockText(v.pt.Elapsed) + " / " + clockText(v.pt.Total)
	}
	bw := clampi(w-width(times)-4, 6, 60)
	barLine := m.bar(bw, float64(v.pt.Elapsed)/math.Max(float64(v.pt.Total), 1), v.col) + "  " + paint(pal.Muted, times)
	if rows == 2 {
		return append(out, centerIn(barLine, w))
	}
	lr := rows - 2
	lw := clampi(w-8, 8, 80)
	for _, l := range m.ladderLines(lw, lr, v) {
		out = append(out, centerIn(l, w))
	}
	out = append(out, centerIn(barLine, w))
	return out
}

// tiny is the layout for very small terminals: caption, digits, one line.
func (m *intervalsMode) tiny(w, h int, v intervalsView) []string {
	pal := m.c.Pal
	out := blank(w, h)
	word := strings.ToUpper(m.phaseWord(v))
	head := bold(v.col, word)
	if !v.idle && v.pt.Seg.Round > 0 {
		head += "  " + paint(pal.Muted, fmt.Sprintf("%d/%d", v.pt.Seg.Round, v.pt.Rounds))
	}
	out[0] = centerIn(head, w)
	if h >= 3 {
		rows := h - 2
		if m.scene == nil || m.scene.Cols != w || m.scene.Rows != rows {
			m.scene = braille.New(w, rows)
		} else {
			m.scene.Clear()
		}
		text := m.digitsText(v)
		font := braille.ParseFont(m.c.Cfg.Font)
		dh := font.FitHeight(text, m.scene.W-2, m.scene.H-2)
		dcol := pal.Text
		if v.run == engine.Paused {
			dcol = pal.Muted
		}
		if !v.idle && !v.pt.Done && v.run == engine.Running && v.pt.Left <= 3*time.Second && v.pt.Seg.Len > 4*time.Second {
			dcol = pal.Warn
		}
		m.scene.TextCentered(font, text, float64(m.scene.W)/2, float64(m.scene.H)/2, maxi(dh, 5), braille.Solid(dcol))
		for i, l := range m.scene.Lines() {
			if 1+i < h {
				out[1+i] = l
			}
		}
		m.hits = append(m.hits, intervalsHit{x: 0, y: 1, w: w, h: rows, field: -1})
		nt, nc := m.nextText(v)
		out[h-1] = centerIn(paint(nc, nt), w)
	}
	return out
}

// panel is the wide layout's side column, composed with Lip Gloss.
func (m *intervalsMode) panel(w, h, mainTop, x0 int, v intervalsView) []string {
	pal := m.c.Pal
	section := lipgloss.NewStyle().Foreground(pal.Muted).Bold(true)
	mut := lipgloss.NewStyle().Foreground(pal.Muted)
	txt := lipgloss.NewStyle().Foreground(pal.Text)
	acc := lipgloss.NewStyle().Foreground(pal.Accent).Bold(true)
	nt, nc := m.nextText(v)

	var rows []string
	fieldRow := map[int]int{}
	if v.idle {
		rows = append(rows, section.Render(strings.ToUpper(i18n.T("pomo.presets"))))
		for i := 0; i <= intervalsCustom; i++ {
			var name, sum string
			if i < len(engine.IntervalsPresets) {
				pp := engine.IntervalsPresets[i]
				name = i18n.T("intervals.preset." + pp.ID)
				sum = intervalsSum(pp.Plan)
			} else {
				name = i18n.T("intervals.preset.custom")
				sum = intervalsSum(m.f.Custom)
			}
			line := fmt.Sprintf("%-10s %s", name, sum)
			if i == m.f.Preset {
				rows = append(rows, acc.Render("▸ "+line))
			} else {
				rows = append(rows, mut.Render("  "+line))
			}
		}
		rows = append(rows, "", section.Render(strings.ToUpper(i18n.T("intervals.plan"))))
		for f := intervalsField(0); f < intervalsFields; f++ {
			fieldRow[len(rows)] = int(f)
			line := fmt.Sprintf("%-14s %s", m.fieldLabel(f), m.fieldValue(f))
			if f == m.focus {
				rows = append(rows, acc.Render("▸ "+line))
			} else {
				rows = append(rows, txt.Render("  ")+mut.Render(line))
			}
		}
		rows = append(rows, "", mut.Render(i18n.T("intervals.total", fmtDur(v.plan.Total()))), lipgloss.NewStyle().Foreground(v.col).Render(i18n.T("pomo.press")))
	} else {
		rows = append(rows, lipgloss.NewStyle().Foreground(nc).Bold(true).Render("▸ "+nt))
		if v.pt.Seg.Round > 0 {
			rows = append(rows, mut.Render(i18n.T("intervals.round", v.pt.Seg.Round, v.pt.Rounds)))
		} else {
			rows = append(rows, mut.Render(i18n.T("intervals.phase."+string(v.pt.Seg.Phase))))
		}
		rows = append(rows, "")
		ladder := m.ladderLines(w, 5, v)
		rows = append(rows, ladder...)
		rows = append(rows, "", m.bar(w, float64(v.pt.Elapsed)/math.Max(float64(v.pt.Total), 1), v.col))
		rows = append(rows, mut.Render(m.timesText(v)), "")
		rows = append(rows, section.Render(strings.ToUpper(i18n.T("intervals.plan"))), mut.Render(m.presetName()+" · "+m.summary()))
	}
	top := maxi(0, (h-len(rows))/2)
	out := blank(w, h)
	for i, r := range rows {
		if top+i < h {
			out[top+i] = padRight(r, w)
		}
	}
	for ri, f := range fieldRow {
		if top+ri < h {
			m.hits = append(m.hits, intervalsHit{x: x0, y: mainTop + top + ri, w: w, h: 1, field: f})
		}
	}
	return out
}

func intervalsSum(p engine.IntervalsPlan) string {
	if p.Rest <= 0 {
		return fmt.Sprintf("%s × %d", fmtDur(p.Work), p.Rounds)
	}
	return fmt.Sprintf("%s / %s × %d", fmtDur(p.Work), fmtDur(p.Rest), p.Rounds)
}
