package ui

import (
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/braille"
)

func TestStampDoesNotGrowAndKeepsWidth(t *testing.T) {
	line := strings.Repeat(paint(braille.RGB{R: 200, G: 100, B: 50}, "⣿⣿⣿⣿"), 20)
	w := ansi.StringWidth(line)
	for i := 0; i < 60; i++ {
		line = stamp(line, (i*7)%(w-6), bold(braille.RGB{R: 255}, "abc"))
	}
	if ansi.StringWidth(line) != w {
		t.Fatalf("width changed: %d != %d", ansi.StringWidth(line), w)
	}
	if len(line) > 20000 {
		t.Fatalf("line grew to %d bytes", len(line))
	}
}

func TestStampContent(t *testing.T) {
	line := paint(braille.RGB{R: 1, G: 2, B: 3}, "abcdefghij")
	got := stamp(line, 3, bold(braille.RGB{R: 9}, "XY"))
	if ansi.Strip(got) != "abcXYfghij" {
		t.Fatalf("got %q", ansi.Strip(got))
	}
	// wide glyph in the base is replaced cleanly
	got = stamp("a日b", 1, "X")
	if w := ansi.StringWidth(got); w != 4 {
		t.Fatalf("width %d: %q", w, got)
	}
	if got := ansi.Strip(stamp("hello", -2, "abcd")); got != "cdllo" {
		t.Fatalf("negative col: %q", got)
	}
	if got := ansi.Strip(stamp("hello", 3, "abcd")); got != "helab" {
		t.Fatalf("overhang: %q", got)
	}
}
