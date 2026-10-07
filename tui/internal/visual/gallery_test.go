package visual

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/theme"
)

func testFrame(p float64) *Frame {
	pal := theme.New(theme.Resolve("lime"), braille.Hex("101014"), true)
	return &Frame{Progress: p, Running: true, Time: 3.3, Dt: 1.0 / 30, Pal: pal, Text: "24:13", Sub: "FOCUS", Font: braille.FontLine}
}

func render(v Visual, cols, rows int, p float64) string {
	c := braille.New(cols, rows)
	f := testFrame(p)
	labels := v.Draw(c, f)
	lines := strings.Split(c.Plain(), "\n")
	for _, l := range labels {
		r := []rune(lines[l.Row])
		col := l.Col
		if l.Center {
			col -= len([]rune(l.Text)) / 2
		}
		for i, ch := range l.Text {
			if col+i >= 0 && col+i < len(r) {
				r[col+i] = ch
			}
		}
		lines[l.Row] = string(r)
	}
	return strings.Join(lines, "\n")
}

func TestGallery(t *testing.T) {
	if os.Getenv("GALLERY") == "" {
		t.Skip("set GALLERY=1 to print")
	}
	for _, d := range Dials {
		v := d()
		fmt.Printf("=== %s\n%s\n", v.Name(), render(v, 56, 22, 0.37))
	}
}
