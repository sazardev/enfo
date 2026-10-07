package braille

import (
	"fmt"
	"os"
	"testing"
)

func TestGlyphs(t *testing.T) {
	if os.Getenv("GLYPHS") == "" {
		t.Skip()
	}
	c := New(60, 6)
	c.Text(FontLine, "23:10 9", 1, 1, 20, Solid(RGB{255, 255, 255}))
	fmt.Println(c.Plain())
}
