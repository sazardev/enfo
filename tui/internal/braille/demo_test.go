package braille

import (
	"fmt"
	"math"
	"testing"
)

func TestDemo(t *testing.T) {
	for _, f := range []Font{FontLine, FontLED, FontSeg} {
		c := New(44, 5)
		c.Text(f, "12:08", 1, 1, 18, Solid(RGB{255, 255, 255}))
		fmt.Println(f, "\n"+c.Plain())
	}
	c := New(40, 18)
	cx, cy := float64(c.W)/2, float64(c.H)/2
	c.Ring(cx, cy, 30, 3, Solid(RGB{50, 50, 50}))
	c.Arc(cx, cy, 30, 3, 0, 1.6*math.Pi, true, Solid(RGB{255, 255, 255}))
	c.TextCentered(FontLine, "25:00", cx, cy, 14, Solid(RGB{255, 255, 255}))
	fmt.Println(c.Plain())
}
