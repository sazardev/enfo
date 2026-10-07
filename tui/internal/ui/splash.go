package ui

import (
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// splash is the opening animation: the logo draws itself, the wordmark types
// in. Any key skips it.
type splash struct {
	born   time.Time
	canvas *braille.Canvas
}

const splashLen = 2300 * time.Millisecond

func newSplash(now time.Time) *splash { return &splash{born: now} }

func (s *splash) progress(now time.Time) float64 {
	return float64(now.Sub(s.born)) / float64(splashLen)
}

func (s *splash) done(now time.Time) bool { return now.Sub(s.born) >= splashLen }

func (s *splash) View(a *App, w, h int) []string {
	pal := a.core.Pal
	p := anim.Clamp01(s.progress(a.core.Now))
	markCols := mini(w, mini(h*2, 36))
	markRows := markCols / 2
	if markRows > h-5 {
		markRows = maxi(h-5, 4)
		markCols = markRows * 2
	}
	if s.canvas == nil || s.canvas.Cols != markCols || s.canvas.Rows != markRows {
		s.canvas = braille.New(markCols, markRows)
	} else {
		s.canvas.Clear()
	}
	c := s.canvas
	size := float64(minF(c.W, c.H)) * 0.92
	visual.Mark(c, float64(c.W)/2, float64(c.H)/2, size, anim.InOutSine(anim.Window(p, 0, 0.78)), pal.Accent, pal.Bright, pal.Bg)
	mark := c.Lines()

	// wordmark types in after the mark lands
	word := "e n f o"
	n := int(anim.Window(p, 0.7, 0.88) * float64(len([]rune(word))))
	shown := string([]rune(word)[:n])
	tag := i18n.T("app.tagline")
	tn := int(anim.Window(p, 0.82, 1) * float64(len([]rune(tag))))
	tagShown := string([]rune(tag)[:tn])

	block := make([]string, 0, markRows+3)
	for _, l := range mark {
		block = append(block, centerIn(l, w))
	}
	block = append(block, "", centerIn(bold(pal.Text, shown), w), centerIn(paint(pal.Muted, tagShown), w))
	out := blank(w, h)
	top := (h - len(block)) / 2
	if top < 0 {
		top = 0
	}
	for i, l := range block {
		if top+i < h {
			out[top+i] = l
		}
	}
	return out
}

func minF(a, b int) int {
	if a < b {
		return a
	}
	return b
}

var _ = strings.Repeat
