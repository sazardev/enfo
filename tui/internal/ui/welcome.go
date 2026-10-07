package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/paginator"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/sazardev/enfo/tui/internal/visual"
)

// welcomePage is the first-run wizard. Every choice applies live (like the
// mobile app's onboarding): switch the language and the words change, move over
// a color and the whole interface re-tints around you.
type welcomePage struct {
	c     *Core
	step  int
	pg    paginator.Model
	sel   [welcomeSteps]int // cursor per step
	done  bool
	dial  visual.Visual
	canv  *braille.Canvas
	mark  *braille.Canvas
	t     float64
	tools map[string]bool
}

const welcomeSteps = 5

func init() {
	registerPage("welcome", func(c *Core, say func(string)) Mode { return newWelcome(c) })
}

func newWelcome(c *Core) *welcomePage {
	w := &welcomePage{c: c, tools: map[string]bool{}}
	w.pg = paginator.New(paginator.WithTotalPages(welcomeSteps))
	w.pg.Type = paginator.Dots
	w.pg.ActiveDot = "●"
	w.pg.InactiveDot = "○"
	for _, id := range c.Cfg.Modes {
		w.tools[id] = true
	}
	// start the cursors where the config already is
	for i, l := range i18n.Languages {
		if l.Code == i18n.Lang() {
			w.sel[0] = i
		}
	}
	for i, r := range rhythms {
		if r.work == c.Cfg.Work && r.rest == c.Cfg.Rest {
			w.sel[1] = i
		}
	}
	w.sel[2] = theme.Index(c.Cfg.Accent)
	for i, n := range visual.DialNames() {
		if n == c.Cfg.Dial {
			w.sel[3] = i
		}
	}
	w.dial = visual.NewDial(c.Cfg.Dial)
	return w
}

func (w *welcomePage) ID() string             { return "welcome" }
func (w *welcomePage) Done() bool             { return w.done }
func (w *welcomePage) Chromeless() bool       { return true }
func (w *welcomePage) Animated() bool         { return w.c.Cfg.Motion != "still" }
func (w *welcomePage) Frame(dt time.Duration) { w.t += dt.Seconds() }
func (w *welcomePage) Back() bool {
	// esc skips the wizard, keeping whatever was chosen so far
	w.finish()
	return true
}

func (w *welcomePage) Help() []key.Binding {
	return []key.Binding{
		kb("up|down|left|right|k|j|h|l", "↑↓←→", i18n.T("key.select")),
		kb("space", "space", i18n.T("welcome.toggle")),
		kb("enter|tab", "enter", i18n.T("welcome.next")),
		kb("shift+tab|backspace", "⌫", i18n.T("key.back")),
		kb("esc", "esc", i18n.T("welcome.skip")),
	}
}

func (w *welcomePage) finish() {
	c := w.c
	c.Cfg.Onboarded = true
	c.ApplyConfig()
	w.done = true
}

func (w *welcomePage) toolIDs() []string {
	var out []string
	for _, i := range Infos {
		if modeFactories[i.ID] != nil {
			out = append(out, i.ID)
		}
	}
	return out
}

func (w *welcomePage) count(step int) int {
	switch step {
	case 0:
		return len(i18n.Languages)
	case 1:
		return len(rhythms)
	case 2:
		return len(theme.Accents)
	case 3:
		return len(visual.Dials)
	case 4:
		return len(w.toolIDs())
	}
	return 1
}

// apply pushes the highlighted choice into the live configuration.
func (w *welcomePage) apply() {
	c := w.c
	switch w.step {
	case 0:
		c.Cfg.Lang = i18n.Languages[w.sel[0]].Code
	case 1:
		r := rhythms[w.sel[1]]
		c.Cfg.Work, c.Cfg.Rest, c.Cfg.Long = r.work, r.rest, r.long
	case 2:
		c.Cfg.Accent = theme.Accents[w.sel[2]].Name
	case 3:
		c.Cfg.Dial = visual.DialNames()[w.sel[3]]
		w.dial = visual.NewDial(c.Cfg.Dial)
	case 4:
		var modes []string
		for _, id := range w.toolIDs() {
			if w.tools[id] || id == "pomodoro" {
				modes = append(modes, id)
			}
		}
		c.Cfg.Modes = modes
	}
	c.ApplyConfig()
}

func (w *welcomePage) move(dx, dy int) {
	n := w.count(w.step)
	cur := w.sel[w.step]
	switch w.step {
	case 2: // swatch grid, 6 per row
		const cols = 8
		if dx != 0 {
			cur += dx
		}
		if dy != 0 {
			cur += dy * cols
		}
		cur = ((cur % n) + n) % n
	default:
		cur += dx + dy
		cur = ((cur % n) + n) % n
	}
	w.sel[w.step] = cur
	if w.step != 4 {
		w.apply()
	}
}

func (w *welcomePage) Update(msg tea.Msg) tea.Cmd {
	switch m := msg.(type) {
	case tea.KeyPressMsg:
		switch m.String() {
		case "up", "k":
			w.move(0, -1)
		case "down", "j":
			w.move(0, 1)
		case "left", "h":
			w.move(-1, 0)
		case "right", "l":
			w.move(1, 0)
		case "space":
			if w.step == 4 {
				id := w.toolIDs()[w.sel[4]]
				if id != "pomodoro" {
					w.tools[id] = !w.tools[id]
					w.apply()
				}
			}
		case "enter", "tab":
			w.apply()
			if w.step == welcomeSteps-1 {
				w.finish()
			} else {
				w.step++
				w.pg.Page = w.step
			}
		case "shift+tab", "backspace":
			if w.step > 0 {
				w.step--
				w.pg.Page = w.step
			}
		}
	}
	return nil
}

// ---------------------------------------------------------------- drawing

func (w *welcomePage) title() (string, string) {
	switch w.step {
	case 0:
		return i18n.T("welcome.lang"), i18n.T("welcome.lang.hint")
	case 1:
		return i18n.T("welcome.rhythm"), i18n.T("welcome.rhythm.hint")
	case 2:
		return i18n.T("welcome.accent"), i18n.T("welcome.accent.hint")
	case 3:
		return i18n.T("welcome.dial"), i18n.T("welcome.dial.hint")
	}
	return i18n.T("welcome.tools"), i18n.T("welcome.tools.hint")
}

func (w *welcomePage) View(width_, height int) string {
	c := w.c
	pal := c.Pal
	cw := clampi(width_-4, 20, 78)
	out := blank(width_, height)
	if width_ < 30 || height < 12 {
		// too small for the full card: a plain one-line prompt
		t, _ := w.title()
		line := bold(pal.Accent, "◔ enfo") + "  " + paint(pal.Text, t)
		out[height/2] = centerIn(line, width_)
		if height > 2 {
			out[height/2+1] = centerIn(paint(pal.Muted, "enter ▸  esc "+i18n.T("welcome.skip")), width_)
		}
		return join(out)
	}

	// the mark, built once and then breathing
	markRows := clampi(height/4, 3, 8)
	markCols := markRows * 2
	if w.mark == nil || w.mark.Cols != markCols {
		w.mark = braille.New(markCols, markRows)
	}
	w.mark.Clear()
	size := math.Min(float64(w.mark.W), float64(w.mark.H)) * 0.9
	visual.Mark(w.mark, float64(w.mark.W)/2, float64(w.mark.H)/2, size, 1, pal.Accent, pal.Bright, pal.Bg)
	markLines := w.mark.Lines()

	title, hint := w.title()
	var body []string
	switch w.step {
	case 0:
		body = w.listBody(cw, func(i int) (string, string) {
			l := i18n.Languages[i]
			return l.Name, strings.ToUpper(l.Code)
		}, i18n.T("welcome.lang.names"))
	case 1:
		body = w.listBody(cw, func(i int) (string, string) {
			r := rhythms[i]
			return i18n.T("pomo.preset." + r.id), fmt.Sprintf("%d / %d min", r.work, r.rest)
		}, "")
		body = append(body, "", centerIn(w.previewDial(cw, "25:00"), cw))
	case 2:
		body = w.swatches(cw)
	case 3:
		body = w.listBody(cw, func(i int) (string, string) { return visual.DialNames()[i], "" }, "")
		body = append(body, "")
		body = append(body, w.previewDialLines(cw)...)
	case 4:
		body = w.toolsBody(cw)
	}

	block := []string{}
	for _, l := range markLines {
		block = append(block, centerIn(l, cw))
	}
	block = append(block,
		centerIn(bold(pal.Text, title), cw),
		centerIn(paint(pal.Muted, hint), cw),
		"",
	)
	block = append(block, body...)
	block = append(block, "", centerIn(w.dots(), cw))
	block = append(block, centerIn(paint(pal.Muted, "enter ")+paint(pal.Text, w.nextLabel())+paint(pal.Faint, "   ·   ")+paint(pal.Muted, "esc ")+paint(pal.Text, i18n.T("welcome.skip")), cw))

	top := maxi(0, (height-len(block))/2)
	left := (width_ - cw) / 2
	for i, l := range block {
		if top+i < height {
			out[top+i] = padRight(spaces(left)+padRight(l, cw), width_)
		}
	}
	return join(out)
}

func (w *welcomePage) nextLabel() string {
	if w.step == welcomeSteps-1 {
		return i18n.T("welcome.start")
	}
	return i18n.T("welcome.next")
}

func (w *welcomePage) dots() string {
	pal := w.c.Pal
	var sb strings.Builder
	for i := 0; i < welcomeSteps; i++ {
		switch {
		case i == w.step:
			sb.WriteString(bold(pal.Accent, w.pg.ActiveDot))
		case i < w.step:
			sb.WriteString(paint(pal.Muted, w.pg.ActiveDot))
		default:
			sb.WriteString(paint(pal.Faint, w.pg.InactiveDot))
		}
		sb.WriteString(" ")
	}
	return strings.TrimRight(sb.String(), " ")
}

// listBody draws a vertical single-choice list.
func (w *welcomePage) listBody(cw int, item func(i int) (name, extra string), footer string) []string {
	pal := w.c.Pal
	n := w.count(w.step)
	var out []string
	for i := 0; i < n; i++ {
		name, extra := item(i)
		sel := i == w.sel[w.step]
		mark, nameS := "  ", paint(pal.Muted, name)
		if sel {
			mark, nameS = bold(pal.Accent, "▸ "), bold(pal.Text, name)
		}
		line := mark + nameS
		if extra != "" {
			line += "  " + paint(pal.Faint, extra)
		}
		out = append(out, centerIn(line, cw))
	}
	return out
}

func (w *welcomePage) swatches(cw int) []string {
	pal := w.c.Pal
	const cols = 8
	var out []string
	n := len(theme.Accents)
	for row := 0; row*cols < n; row++ {
		var sb strings.Builder
		for col := 0; col < cols; col++ {
			i := row*cols + col
			if i >= n {
				break
			}
			a := theme.Accents[i]
			if i == w.sel[2] {
				sb.WriteString(bold(pal.Text, "▐") + bold(a.RGB, "██") + bold(pal.Text, "▌"))
			} else {
				sb.WriteString(paint(a.RGB, " ██ "))
			}
			sb.WriteString(" ")
		}
		out = append(out, centerIn(sb.String(), cw))
		out = append(out, "")
	}
	name := theme.Accents[w.sel[2]].Name
	out = append(out, centerIn(bold(pal.Accent, name), cw))
	return out
}

func (w *welcomePage) toolsBody(cw int) []string {
	pal := w.c.Pal
	var out []string
	for i, id := range w.toolIDs() {
		on := w.tools[id] || id == "pomodoro"
		box := paint(pal.Faint, "○")
		if on {
			box = bold(pal.Accent, "●")
		}
		name := i18n.T("mode." + id)
		line := box + " " + paint(pal.Muted, name)
		if i == w.sel[4] {
			line = bold(pal.Accent, "▸ ") + box + " " + bold(pal.Text, name)
		} else {
			line = "  " + line
		}
		out = append(out, centerIn(line, cw))
	}
	return out
}

// previewDial is a tiny one-line stand-in (used where there is no room for art).
func (w *welcomePage) previewDial(cw int, text string) string {
	pal := w.c.Pal
	phase := math.Mod(w.t/10, 1)
	const n = 24
	var sb strings.Builder
	for i := 0; i < n; i++ {
		if float64(i)/n < phase {
			sb.WriteString(paint(pal.Accent, "⣿"))
		} else {
			sb.WriteString(paint(pal.Faint, "⣀"))
		}
	}
	return sb.String() + "  " + bold(pal.Text, text)
}

// previewDialLines draws the chosen face live in a small canvas.
func (w *welcomePage) previewDialLines(cw int) []string {
	c := w.c
	rows := 9
	cols := rows * 2
	if wantsFill(w.dial) {
		cols = 36
	}
	if w.canv == nil || w.canv.Cols != cols || w.canv.Rows != rows {
		w.canv = braille.New(cols, rows)
	} else {
		w.canv.Clear()
	}
	f := &visual.Frame{
		Progress: math.Mod(w.t/9, 1), Running: true, Time: w.t, Dt: c.Dt.Seconds(), Pal: c.Pal,
		Text: "25:00", Sub: i18n.T("phase.focus"), Font: braille.ParseFont(c.Cfg.Font), Still: c.Cfg.Motion == "still",
	}
	labels := w.dial.Draw(w.canv, f)
	lines := w.canv.Lines()
	overlayLabels(lines, labels)
	out := make([]string, len(lines))
	for i, l := range lines {
		out[i] = centerIn(l, cw)
	}
	return out
}

var _ = lipgloss.NewStyle
