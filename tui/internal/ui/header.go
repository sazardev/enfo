package ui

import (
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

type tabRect struct {
	x, w int
	mode string
}

type header struct {
	rects []tabRect
	sx    *anim.Spring // underline start
	sw    *anim.Spring // underline width
	init  bool
}

func newHeader() *header {
	return &header{sx: anim.NewSpring(0, 7, 0.78), sw: anim.NewSpring(0, 7, 0.78)}
}

func (h *header) hit(x int) (string, bool) {
	for _, r := range h.rects {
		if x >= r.x && x < r.x+r.w {
			return r.mode, true
		}
	}
	return "", false
}

// layout decides how the tabs are written so they always fit: full names,
// then short names, then just icons.
func (h *header) layout(a *App, w int) (labels []string, widths []int) {
	// pass 0: every tab with its name; pass 1: only the current tab keeps its
	// name (the others shrink to number + icon); pass 2: icons only.
	for pass := 0; pass < 3; pass++ {
		labels, widths = nil, nil
		total := 0
		for i, id := range a.order {
			info := infoFor(id)
			name := i18n.T("mode." + id)
			var s string
			switch {
			case pass == 0 || (pass == 1 && id == a.current):
				s = " " + itoa(i+1) + " " + name + " "
			case pass == 1:
				s = " " + itoa(i+1) + info.Icon + " "
			default:
				s = " " + info.Icon + " "
			}
			if a.ids[id] != nil && a.runningIn(id) {
				s += "•"
			}
			labels = append(labels, s)
			widths = append(widths, width(s))
			total += widths[i]
		}
		if total+14 <= w {
			return
		}
	}
	return
}

// View renders the two header rows.
func (h *header) View(a *App, w int) []string {
	pal := a.core.Pal
	labels, widths := h.layout(a, w)

	brand := bold(pal.Accent, "◔ ") + bold(pal.Text, "enfo")
	brandW := width(brand)
	x := brandW + 3
	h.rects = h.rects[:0]
	var tabs strings.Builder
	var curX, curW int
	for i, id := range a.order {
		label := labels[i]
		r := tabRect{x: x, w: widths[i], mode: id}
		h.rects = append(h.rects, r)
		if id == a.current {
			curX, curW = r.x, r.w
			tabs.WriteString(bold(pal.Accent, label))
		} else {
			tabs.WriteString(paint(pal.Muted, label))
		}
		x += widths[i]
	}
	// right side: date and time
	now := a.core.Now
	clock := paint(pal.Muted, now.Format("Mon 2 Jan")) + "  " + bold(pal.Text, now.Format("15:04"))
	if i18n.Lang() == "es" {
		clock = paint(pal.Muted, spanishDate(now)) + "  " + bold(pal.Text, now.Format("15:04"))
	}
	row0 := brand + "   " + tabs.String()
	if width(row0)+width(clock)+2 <= w {
		row0 = padRight(row0, w-width(clock)-1) + clock + " "
	}

	// the underline: a faint rule with a bright span that springs to the tab
	if !h.init {
		h.sx.Snap(float64(curX))
		h.sw.Snap(float64(curW))
		h.init = true
	}
	h.sx.Target, h.sw.Target = float64(curX), float64(curW)
	ux, uw := int(h.sx.Pos+0.5), int(h.sw.Pos+0.5)
	var rule strings.Builder
	rule.WriteString(paint(pal.Faint, ""))
	faintRule := "\x1b[38;2;" + rgbCSV(pal.Faint) + "m"
	brightRule := "\x1b[38;2;" + rgbCSV(pal.Accent) + "m"
	for i := 0; i < w; i++ {
		switch {
		case i >= ux && i < ux+uw:
			rule.WriteString(brightRule + "⣤")
		default:
			rule.WriteString(faintRule + "⣀")
		}
	}
	rule.WriteString("\x1b[39m")
	return []string{row0, rule.String()}
}

func rgbCSV(c braille.RGB) string {
	return itoa(int(c.R)) + ";" + itoa(int(c.G)) + ";" + itoa(int(c.B))
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [12]byte
	i := len(b)
	neg := n < 0
	if neg {
		n = -n
	}
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		b[i] = '-'
	}
	return string(b[i:])
}

var esDays = [...]string{"dom", "lun", "mar", "mié", "jue", "vie", "sáb"}
var esMonths = [...]string{"ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"}

func spanishDate(t time.Time) string {
	return esDays[t.Weekday()] + " " + itoa(t.Day()) + " " + esMonths[t.Month()-1]
}
