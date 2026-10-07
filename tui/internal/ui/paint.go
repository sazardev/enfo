package ui

import (
	"strconv"
	"strings"
	"unicode/utf8"

	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// paint colors a string with a truecolor foreground. Bubble Tea downsamples it
// for terminals with fewer colors, so RGB is always safe.
func paint(c braille.RGB, s string) string {
	if s == "" {
		return s
	}
	return sgr(c) + s + "\x1b[39m"
}

// bold paints and emboldens.
func bold(c braille.RGB, s string) string {
	if s == "" {
		return s
	}
	return "\x1b[1m" + sgr(c) + s + "\x1b[22;39m"
}

func faint(c braille.RGB, s string) string {
	if s == "" {
		return s
	}
	return "\x1b[2m" + sgr(c) + s + "\x1b[22;39m"
}

func sgr(c braille.RGB) string {
	return "\x1b[38;2;" + strconv.Itoa(int(c.R)) + ";" + strconv.Itoa(int(c.G)) + ";" + strconv.Itoa(int(c.B)) + "m"
}

func width(s string) int { return ansi.StringWidth(s) }

func spaces(n int) string {
	if n <= 0 {
		return ""
	}
	return strings.Repeat(" ", n)
}

// padRight pads (or cuts) s to exactly w cells.
func padRight(s string, w int) string {
	sw := width(s)
	switch {
	case sw < w:
		return s + spaces(w-sw)
	case sw > w:
		return ansi.Truncate(s, w, "")
	}
	return s
}

// padLeft right-aligns s in w cells.
func padLeft(s string, w int) string {
	sw := width(s)
	if sw >= w {
		return ansi.Truncate(s, w, "")
	}
	return spaces(w-sw) + s
}

// centerIn centers s in w cells.
func centerIn(s string, w int) string {
	sw := width(s)
	if sw >= w {
		return ansi.Truncate(s, w, "")
	}
	l := (w - sw) / 2
	return spaces(l) + s + spaces(w-sw-l)
}

// fit forces lines into exactly w x h cells (blank-padded, cut if larger).
func fit(lines []string, w, h int) []string {
	out := make([]string, h)
	for i := 0; i < h; i++ {
		if i < len(lines) {
			out[i] = padRight(lines[i], w)
		} else {
			out[i] = spaces(w)
		}
	}
	return out
}

// blank makes h empty lines of width w.
func blank(w, h int) []string {
	out := make([]string, h)
	for i := range out {
		out[i] = spaces(w)
	}
	return out
}

// centerBlock centers a block of lines inside a w x h area.
func centerBlock(lines []string, w, h int) []string {
	bw := 0
	for _, l := range lines {
		if x := width(l); x > bw {
			bw = x
		}
	}
	top := (h - len(lines)) / 2
	if top < 0 {
		top = 0
	}
	left := (w - bw) / 2
	if left < 0 {
		left = 0
	}
	out := blank(w, h)
	for i, l := range lines {
		if top+i >= h {
			break
		}
		out[top+i] = padRight(spaces(left)+l, w)
	}
	return out
}

// hcat puts blocks side by side; every block keeps its own width and the
// result is as tall as the tallest.
func hcat(blocks ...[]string) []string {
	h := 0
	ws := make([]int, len(blocks))
	for i, b := range blocks {
		if len(b) > h {
			h = len(b)
		}
		for _, l := range b {
			if x := width(l); x > ws[i] {
				ws[i] = x
			}
		}
	}
	out := make([]string, h)
	for y := 0; y < h; y++ {
		var sb strings.Builder
		for i, b := range blocks {
			if y < len(b) {
				sb.WriteString(padRight(b[y], ws[i]))
			} else {
				sb.WriteString(spaces(ws[i]))
			}
		}
		out[y] = sb.String()
	}
	return out
}

// ---- styled cells --------------------------------------------------------
//
// stamp works on a parsed row of cells instead of slicing the escape-coded
// string: slicing keeps every style sequence it skips, which doubles the
// string on each call.

type sgrState struct {
	fg, bg                              string // "38;2;r;g;b", "38;5;n", "" = default
	bold, faint, italic, underline, rev bool
}

func (s *sgrState) apply(params string) {
	if params == "" {
		*s = sgrState{}
		return
	}
	p := strings.Split(params, ";")
	for i := 0; i < len(p); i++ {
		switch p[i] {
		case "0", "":
			*s = sgrState{}
		case "1":
			s.bold = true
		case "2":
			s.faint = true
		case "3":
			s.italic = true
		case "4":
			s.underline = true
		case "7":
			s.rev = true
		case "22":
			s.bold, s.faint = false, false
		case "23":
			s.italic = false
		case "24":
			s.underline = false
		case "27":
			s.rev = false
		case "39":
			s.fg = ""
		case "49":
			s.bg = ""
		case "38", "48":
			n := 0
			if i+1 < len(p) {
				switch p[i+1] {
				case "2":
					n = 5
				case "5":
					n = 3
				}
			}
			if n == 0 || i+n > len(p)-1+1 {
				n = len(p) - i
			}
			end := i + n
			if end > len(p) {
				end = len(p)
			}
			code := strings.Join(p[i:end], ";")
			if p[i] == "38" {
				s.fg = code
			} else {
				s.bg = code
			}
			i = end - 1
		default:
			// 30-37, 90-97 and 40-47, 100-107: basic colors
			if v := p[i]; len(v) == 2 && (v[0] == '3' || v[0] == '9') {
				s.fg = v
			} else if len(v) >= 2 && (v[0] == '4' || v[:2] == "10") {
				s.bg = v
			}
		}
	}
}

func (s sgrState) sequence() string {
	if s == (sgrState{}) {
		return ""
	}
	var parts []string
	if s.bold {
		parts = append(parts, "1")
	}
	if s.faint {
		parts = append(parts, "2")
	}
	if s.italic {
		parts = append(parts, "3")
	}
	if s.underline {
		parts = append(parts, "4")
	}
	if s.rev {
		parts = append(parts, "7")
	}
	if s.fg != "" {
		parts = append(parts, s.fg)
	}
	if s.bg != "" {
		parts = append(parts, s.bg)
	}
	return "\x1b[" + strings.Join(parts, ";") + "m"
}

type styledCell struct {
	text string
	w    int
	st   sgrState
}

// parseCells splits an escape-coded line into cells with their style.
func parseCells(s string) []styledCell {
	var cells []styledCell
	var st sgrState
	for i := 0; i < len(s); {
		if s[i] == 0x1b && i+1 < len(s) && s[i+1] == '[' {
			j := i + 2
			for j < len(s) && (s[j] < 0x40 || s[j] > 0x7e) {
				j++
			}
			if j < len(s) && s[j] == 'm' {
				st.apply(s[i+2 : j])
			}
			i = j + 1
			continue
		}
		r, size := utf8.DecodeRuneInString(s[i:])
		i += size
		w := 1
		if r >= 0x300 {
			w = ansi.StringWidth(string(r))
		}
		if w == 0 && len(cells) > 0 {
			cells[len(cells)-1].text += string(r)
			continue
		}
		cells = append(cells, styledCell{text: string(r), w: w, st: st})
		if w == 2 {
			cells = append(cells, styledCell{w: 0, st: st}) // the wide glyph's second column
		}
	}
	return cells
}

func renderCells(cells []styledCell) string {
	var sb strings.Builder
	var cur sgrState
	for _, c := range cells {
		if c.w == 0 && c.text == "" {
			continue
		}
		if c.st != cur {
			if c.st == (sgrState{}) {
				sb.WriteString("\x1b[0m")
			} else {
				sb.WriteString("\x1b[0m" + c.st.sequence())
			}
			cur = c.st
		}
		sb.WriteString(c.text)
	}
	if cur != (sgrState{}) {
		sb.WriteString("\x1b[0m")
	}
	return sb.String()
}

// stamp writes text over a line at column col, keeping what is on either side.
func stamp(line string, col int, text string) string {
	base := parseCells(line)
	over := parseCells(text)
	if col < 0 {
		if -col >= len(over) {
			return line
		}
		over = over[-col:]
		col = 0
	}
	if col >= len(base) {
		return line
	}
	if col+len(over) > len(base) {
		over = over[:len(base)-col]
	}
	// do not leave half of a wide glyph behind
	if col > 0 && base[col].w == 0 && base[col].text == "" {
		base[col-1] = styledCell{text: " ", w: 1, st: base[col-1].st}
	}
	end := col + len(over)
	if end < len(base) && base[end].w == 0 && base[end].text == "" {
		base[end] = styledCell{text: " ", w: 1, st: base[end].st}
	}
	copy(base[col:], over)
	return renderCells(base)
}

// overlayLabels writes visual labels onto rendered canvas lines.
func overlayLabels(lines []string, labels []visual.Label) {
	for _, l := range labels {
		if l.Row < 0 || l.Row >= len(lines) {
			continue
		}
		txt := l.Text
		col := l.Col
		if l.Center {
			col -= width(txt) / 2
		}
		var s string
		if l.Bold {
			s = bold(l.Color, txt)
		} else {
			s = paint(l.Color, txt)
		}
		lines[l.Row] = stamp(lines[l.Row], col, s)
	}
}

func join(lines []string) string { return strings.Join(lines, "\n") }

func clampi(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

func maxi(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func mini(a, b int) int {
	if a < b {
		return a
	}
	return b
}
