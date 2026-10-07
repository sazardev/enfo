package ui

import (
	"fmt"
	"math"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func init() {
	registerMode("alarm", func(c *Core, say func(string)) Mode { return newAlarmMode(c, say) })
}

type alarmHitKind int

const (
	alarmHitRow alarmHitKind = iota
	alarmHitToggle
	alarmHitChip
	alarmHitHour
	alarmHitMin
)

type alarmHit struct {
	x0, y0, x1, y1 int // [x0,x1) x [y0,y1), body-relative cells
	kind           alarmHitKind
	idx            int
}

func (h alarmHit) has(x, y int) bool { return x >= h.x0 && x < h.x1 && y >= h.y0 && y < h.y1 }

type alarmMode struct {
	c   *Core
	say func(string)

	sel    int
	top    int
	ed     *alarmEditor
	del    bool // asking to delete the selected alarm
	knob   map[int]*anim.Spring
	cache  map[string][]string
	hits   []alarmHit
	cardCv *braille.Canvas
	artCv  *braille.Canvas
	rows   int // height of the big digits in the regular list (3 or 4)
}

func newAlarmMode(c *Core, say func(string)) *alarmMode {
	return &alarmMode{c: c, say: say, knob: map[int]*anim.Spring{}, cache: map[string][]string{}}
}

func (m *alarmMode) ID() string { return "alarm" }

func (m *alarmMode) list() []*engine.Alarm { return m.c.Alarms.List }

func (m *alarmMode) Capturing() bool { return m.ed != nil || m.del }

func (m *alarmMode) Animated() bool { return m.c.Cfg.Motion != "still" }

func (m *alarmMode) Title() string {
	if a, at := m.c.Alarms.Next(); a != nil {
		return iconAlarm + " " + at.In(m.c.Now.Location()).Format("15:04")
	}
	return ""
}

func (m *alarmMode) Help() []key.Binding {
	if m.del {
		return []key.Binding{kb("enter", "enter", i18n.T("key.confirm")), kb("esc", "esc", i18n.T("key.cancel"))}
	}
	if m.ed != nil {
		return []key.Binding{
			kb("left", "←→", i18n.T("alarm.k.field")),
			kb("up", "↑↓", i18n.T("alarm.k.change")),
			kb("space", "space", i18n.T("alarm.k.day")),
			kb("w", "w/e/a", i18n.T("alarm.k.days")),
			kb("enter", "enter", i18n.T("alarm.k.save")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	}
	return []key.Binding{
		kb("up|down|k|j", "↑↓", i18n.T("alarm.k.move")),
		kb("space", "space", i18n.T("alarm.k.toggle")),
		kb("n", "n", i18n.T("alarm.k.new")),
		kb("e|enter", "e", i18n.T("alarm.k.edit")),
		kb("x", "x", i18n.T("alarm.k.delete")),
	}
}

func (m *alarmMode) Frame(dt time.Duration) {
	for _, a := range m.list() {
		sp := m.knob[a.ID]
		if sp == nil {
			sp = anim.NewSpring(b2f(a.Enabled), 9, 0.6)
			m.knob[a.ID] = sp
		}
		sp.Target = b2f(a.Enabled)
		sp.Step(dt)
	}
}

func b2f(b bool) float64 {
	if b {
		return 1
	}
	return 0
}

func (m *alarmMode) clampSel() {
	n := len(m.list())
	if m.sel >= n {
		m.sel = n - 1
	}
	if m.sel < 0 {
		m.sel = 0
	}
}

// ---------------------------------------------------------------- formatting

// alarmDur is a countdown in plain units: 42 s, 12 min, 7 h 32 min, 2 d 3 h.
func alarmDur(d time.Duration) string {
	if d < 0 {
		d = 0
	}
	if d < time.Minute {
		return fmt.Sprintf("%d s", ceilSecs(d))
	}
	mins := int((d + 59*time.Second) / time.Minute)
	switch {
	case mins < 60:
		return fmt.Sprintf("%d min", mins)
	case mins < 24*60:
		if mins%60 == 0 {
			return fmt.Sprintf("%d h", mins/60)
		}
		return fmt.Sprintf("%d h %d min", mins/60, mins%60)
	}
	days, h := mins/(24*60), mins/60%24
	if h == 0 {
		return fmt.Sprintf("%d d", days)
	}
	return fmt.Sprintf("%d d %d h", days, h)
}

func alarmWeekdayName(wd time.Weekday) string {
	names := strings.Split(i18n.T("alarm.weekdays"), ",")
	if int(wd) < len(names) {
		return names[wd]
	}
	return ""
}

// alarmDaysText names the day sets that have a name.
func alarmDaysText(d engine.Days) (string, bool) {
	switch d {
	case 0:
		return i18n.T("alarm.once"), true
	case engine.Weekdays:
		return i18n.T("alarm.d.weekdays"), true
	case engine.Weekend:
		return i18n.T("alarm.d.weekend"), true
	case engine.Everyday:
		return i18n.T("alarm.d.everyday"), true
	}
	return "", false
}

// alarmChips writes the seven day letters; the ones that are on are bright.
func (m *alarmMode) alarmChips(d engine.Days, dim bool) string {
	pal := m.c.Pal
	letters := []rune(i18n.T("alarm.days"))
	var sb strings.Builder
	for i := 0; i < 7 && i < len(letters); i++ {
		if i > 0 {
			sb.WriteByte(' ')
		}
		ch := string(letters[i])
		switch {
		case d&(1<<uint(i)) != 0 && !dim:
			sb.WriteString(bold(pal.Accent, ch))
		case d&(1<<uint(i)) != 0:
			sb.WriteString(paint(pal.Muted, ch))
		default:
			sb.WriteString(paint(pal.Faint, ch))
		}
	}
	return sb.String()
}

// alarmWhen says how a day set reads in a row: the name, or the letters.
func (m *alarmMode) alarmWhen(a *engine.Alarm, dim bool) string {
	if t, ok := alarmDaysText(a.Days); ok {
		if dim {
			return paint(m.c.Pal.Faint, t)
		}
		return paint(m.c.Pal.Muted, t)
	}
	return m.alarmChips(a.Days, dim)
}

// alarmCountdown is the live "in 7 h 32 min" of one alarm, with its colour.
func (m *alarmMode) alarmCountdown(a *engine.Alarm) string {
	pal := m.c.Pal
	now := m.c.Now
	if !a.SnoozeAt.IsZero() && a.SnoozeAt.After(now) {
		return paint(pal.Warn, i18n.T("alarm.snoozed", alarmDur(a.SnoozeAt.Sub(now))))
	}
	if !a.Enabled || a.NextAt.IsZero() {
		return paint(pal.Faint, i18n.T("alarm.off"))
	}
	until := a.NextAt.Sub(now)
	col := pal.Muted
	if nx, _ := m.c.Alarms.Next(); nx != nil && nx.ID == a.ID {
		col = pal.Bright
		if until < time.Minute {
			col = pal.Accent
		}
	}
	return paint(col, i18n.T("alarm.in", alarmDur(until)))
}

func (m *alarmMode) label(a *engine.Alarm) string {
	if a.Label != "" {
		return a.Label
	}
	return i18n.T("alarm.default")
}

// alarmPreviewText is the editor's live "Rings tomorrow at 07:30 (in 14 h)".
func (m *alarmMode) alarmPreviewText(hour, min int, days engine.Days) string {
	now := m.c.Now
	a := engine.Alarm{Hour: hour, Min: min, Days: days}
	at := a.NextOccurrence(now)
	if at.IsZero() {
		return ""
	}
	tm := fmt.Sprintf("%02d:%02d", hour, min)
	in := alarmDur(at.Sub(now))
	y1, m1, d1 := now.Date()
	y2, m2, d2 := at.Date()
	switch {
	case y1 == y2 && m1 == m2 && d1 == d2:
		return i18n.T("alarm.preview.today", tm, in)
	case now.AddDate(0, 0, 1).Format("2006-01-02") == at.Format("2006-01-02"):
		return i18n.T("alarm.preview.tomorrow", tm, in)
	}
	return i18n.T("alarm.preview.day", tm, in, alarmWeekdayName(at.Weekday()))
}

// bigTime returns cached tall digits for an alarm time.
func (m *alarmMode) bigTime(hour, min, rows int, col braille.RGB) []string {
	k := fmt.Sprintf("%02d:%02d/%d/%v", hour, min, rows, col)
	if l, ok := m.cache[k]; ok {
		return l
	}
	if len(m.cache) > 200 {
		m.cache = map[string][]string{}
	}
	l := alarmBigTime(fmt.Sprintf("%02d:%02d", hour, min), rows, col)
	m.cache[k] = l
	return l
}

// ---------------------------------------------------------------- input

func (m *alarmMode) Update(msg tea.Msg) tea.Cmd {
	c := m.c
	if m.ed != nil {
		return m.updateEditor(msg)
	}
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		if m.del {
			switch msg.String() {
			case "enter", "y", "x":
				if m.sel < len(m.list()) {
					c.Alarms.Delete(m.list()[m.sel].ID)
					c.MarkDirty()
					m.say(i18n.T("alarm.deleted"))
					m.clampSel()
				}
			}
			m.del = false
			return nil
		}
		n := len(m.list())
		switch msg.String() {
		case "up", "k":
			m.sel--
		case "down", "j":
			m.sel++
		case "home":
			m.sel = 0
		case "end":
			m.sel = n - 1
		case "space":
			m.toggle(m.sel)
		case "n":
			m.ed = m.newEditor(nil)
		case "e", "enter":
			if n > 0 {
				m.clampSel()
				m.ed = m.newEditor(m.list()[m.sel])
			}
		case "x", "delete":
			if n > 0 {
				m.del = true
			}
		}
		m.clampSel()
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		for _, h := range m.hits {
			if !h.has(msg.X, msg.Y) {
				continue
			}
			switch h.kind {
			case alarmHitToggle:
				m.sel = h.idx
				m.toggle(h.idx)
			case alarmHitRow:
				if m.sel == h.idx {
					m.ed = m.newEditor(m.list()[h.idx])
				}
				m.sel = h.idx
			}
			break
		}
	case tea.MouseWheelMsg:
		switch msg.Button {
		case tea.MouseWheelUp:
			m.sel--
		case tea.MouseWheelDown:
			m.sel++
		}
		m.clampSel()
	}
	return nil
}

func (m *alarmMode) toggle(i int) {
	l := m.list()
	if i < 0 || i >= len(l) {
		return
	}
	m.c.Alarms.Toggle(l[i].ID, m.c.Now)
	m.c.MarkDirty()
	if a := l[i]; a.Enabled && !a.NextAt.IsZero() {
		m.say(i18n.T("alarm.on.toast", alarmDur(a.NextAt.Sub(m.c.Now))))
	} else {
		m.say(i18n.T("alarm.off.toast"))
	}
}

// ---------------------------------------------------------------- view

func (m *alarmMode) View(w, h int) string {
	if w < 1 || h < 1 {
		return join(blank(maxi(w, 0), maxi(h, 0)))
	}
	m.hits = m.hits[:0]
	wide := w >= 104 && h >= 18 && (len(m.list()) > 0 || m.ed != nil)
	cardW := 0
	listW := w
	if wide {
		cardW = clampi(w*30/100, 32, 44)
		listW = w - cardW - 2
	}
	var left []string
	if m.ed != nil {
		left = m.viewEditor(listW, h)
	} else {
		left = m.viewList(listW, h)
	}
	if !wide {
		return join(fit(left, w, h))
	}
	card := m.viewCard(cardW, h)
	return join(fit(hcat(fit(left, listW, h), blank(2, h), card), w, h))
}

type alarmDensity int

const (
	alarmTiny alarmDensity = iota
	alarmCompact
	alarmRegular
)

func alarmDensityFor(w, h int) alarmDensity {
	switch {
	case w < 40 || h < 9:
		return alarmTiny
	case w < 62 || h < 14:
		return alarmCompact
	}
	return alarmRegular
}

func (m *alarmMode) viewList(w, h int) []string {
	al := m.list()
	if len(al) == 0 {
		return m.viewEmpty(w, h)
	}
	m.clampSel()
	dens := alarmDensityFor(w, h)
	if dens == alarmRegular && w > 84 {
		w = 84 // rows stay readable on huge terminals
	} else if dens == alarmCompact && w > 64 {
		w = 64
	}
	rowH, gap, headerH := 1, 0, 0
	switch dens {
	case alarmCompact:
		rowH, gap, headerH = 2, 1, 2
		if h < 12 {
			headerH = 0
		}
	case alarmRegular:
		m.rows = 3
		if h >= 22 {
			m.rows = 4
		}
		rowH, gap, headerH = m.rows, 1, 2
	}
	step := rowH + gap
	visible := maxi((h-headerH+gap)/step, 1)
	if m.sel < m.top {
		m.top = m.sel
	}
	if m.sel >= m.top+visible {
		m.top = m.sel - visible + 1
	}
	m.top = clampi(m.top, 0, maxi(len(al)-visible, 0))

	var out []string
	if headerH > 0 {
		out = append(out, m.listHeader(w, m.top > 0, len(al)-(m.top+visible)), "")
	}
	for i := m.top; i < len(al) && i < m.top+visible; i++ {
		y := len(out)
		var rl []string
		switch dens {
		case alarmTiny:
			rl = []string{m.rowTiny(i, al[i], w)}
		case alarmCompact:
			rl = m.rowCompact(i, al[i], w)
		default:
			rl = m.rowRegular(i, al[i], w)
		}
		m.hits = append(m.hits,
			alarmHit{x0: w - 10, y0: y, x1: w, y1: y + rowH, kind: alarmHitToggle, idx: i},
			alarmHit{x0: 0, y0: y, x1: w, y1: y + rowH, kind: alarmHitRow, idx: i})
		out = append(out, rl...)
		for g := 0; g < gap; g++ {
			out = append(out, "")
		}
	}
	return out
}

func (m *alarmMode) listHeader(w int, more bool, below int) string {
	pal := m.c.Pal
	left := bold(pal.Muted, i18n.T("alarm.header")) + paint(pal.Faint, fmt.Sprintf(" · %d", len(m.list())))
	right := ""
	if below > 0 {
		right = paint(pal.Muted, "▼ "+i18n.T("alarm.more", below))
	} else if more {
		right = paint(pal.Muted, "▲")
	}
	if a, at := m.c.Alarms.Next(); a != nil && width(left)+width(right)+30 < w {
		left += paint(pal.Faint, "  ·  ") + paint(pal.Muted, i18n.T("alarm.in", alarmDur(at.Sub(m.c.Now))))
	}
	return padRight(" "+left, w-width(right)-1) + right + " "
}

func (m *alarmMode) isNext(a *engine.Alarm) bool {
	nx, _ := m.c.Alarms.Next()
	return nx != nil && nx.ID == a.ID
}

func (m *alarmMode) marker(i int) string {
	if i == m.sel {
		return paint(m.c.Pal.Accent, "▌")
	}
	return " "
}

func (m *alarmMode) timeColor(a *engine.Alarm, selected bool) braille.RGB {
	pal := m.c.Pal
	switch {
	case !a.Enabled:
		return pal.Faint.Mix(pal.Muted, 0.35)
	case m.isNext(a):
		return pal.Bright
	case selected:
		return pal.Text
	}
	return pal.Text.Mix(pal.Muted, 0.35)
}

func (m *alarmMode) toggleFor(a *engine.Alarm, rows int) []string {
	pos := b2f(a.Enabled)
	if sp := m.knob[a.ID]; sp != nil {
		pos = sp.Pos
	}
	return alarmToggle(pos, rows, m.c.Pal)
}

// rowTiny: one line: marker, time, on-dot, label.
func (m *alarmMode) rowTiny(i int, a *engine.Alarm, w int) string {
	pal := m.c.Pal
	dot := paint(pal.Faint, "○")
	if a.Enabled {
		dot = paint(pal.Accent, "●")
	}
	tm := fmt.Sprintf("%02d:%02d", a.Hour, a.Min)
	tcol := m.timeColor(a, i == m.sel)
	if m.del && i == m.sel {
		return padRight(m.marker(i)+" "+bold(pal.Bad, i18n.T("alarm.confirm", tm))+" "+paint(pal.Muted, "⏎/esc"), w)
	}
	line := m.marker(i) + " " + bold(tcol, tm) + " " + dot + " "
	rest := m.label(a)
	if i == m.sel {
		rest = bold(pal.Text, rest)
	} else {
		rest = paint(pal.Muted, rest)
	}
	line += rest
	if a.Enabled && w >= 34 {
		cd := m.alarmCountdown(a)
		if width(line)+width(cd)+2 < w {
			line = padRight(line, w-width(cd)-1) + cd + " "
		}
	}
	return padRight(line, w)
}

// rowCompact: two lines, text time.
func (m *alarmMode) rowCompact(i int, a *engine.Alarm, w int) []string {
	pal := m.c.Pal
	tm := fmt.Sprintf("%02d:%02d", a.Hour, a.Min)
	tcol := m.timeColor(a, i == m.sel)
	tog := m.toggleFor(a, 1)[0]
	lab := m.label(a)
	if i == m.sel {
		lab = bold(pal.Text, lab)
	} else {
		lab = paint(pal.Muted, lab)
	}
	l0 := m.marker(i) + " " + bold(tcol, tm) + "  " + lab
	l0 = padRight(l0, w-7) + tog + " "
	l1 := m.marker(i) + "       " + m.alarmWhen(a, !a.Enabled)
	cd := m.alarmCountdown(a)
	if width(l1)+width(cd)+3 < w {
		l1 = padRight(l1, w-width(cd)-1) + cd + " "
	}
	if m.del && i == m.sel {
		l1 = m.marker(i) + "       " + bold(pal.Bad, i18n.T("alarm.confirm", tm)) + " " + paint(pal.Muted, i18n.T("alarm.confirm.hint"))
	}
	return []string{padRight(l0, w), padRight(l1, w)}
}

// rowRegular: tall braille digits with label, days, countdown and a switch.
func (m *alarmMode) rowRegular(i int, a *engine.Alarm, w int) []string {
	pal := m.c.Pal
	n := m.rows
	tl := m.bigTime(a.Hour, a.Min, n, m.timeColor(a, i == m.sel))
	tw := width(tl[0])
	togW := 8
	infoW := maxi(w-2-tw-3-togW-2, 0)
	col := func(s string) []string {
		out := make([]string, n)
		for k := range out {
			out[k] = s
		}
		return out
	}
	mark := make([]string, n)
	for k := range mark {
		mark[k] = m.marker(i)
	}
	lab := m.label(a)
	if i == m.sel {
		lab = bold(pal.Text, lab)
	} else {
		lab = paint(pal.Muted, lab)
	}
	lines := []string{
		padRight(lab, infoW),
		padRight(m.alarmWhen(a, !a.Enabled), infoW),
		padRight(m.alarmCountdown(a), infoW),
	}
	if i == m.sel && m.del {
		lines[1] = padRight(bold(pal.Bad, i18n.T("alarm.confirm", fmt.Sprintf("%02d:%02d", a.Hour, a.Min))), infoW)
		lines[2] = padRight(paint(pal.Muted, i18n.T("alarm.confirm.hint")), infoW)
	}
	off := n - 3 // centre the three info lines against the digits
	info := make([]string, n)
	tog := make([]string, n)
	for k := 0; k < n; k++ {
		info[k], tog[k] = spaces(infoW), spaces(togW)
		if k-off >= 0 && k-off < 3 {
			info[k] = lines[k-off]
		}
	}
	t2 := m.toggleFor(a, 2)
	for k := 0; k < 2; k++ {
		if off+k < n {
			tog[off+k] = t2[k]
		}
	}
	if infoW < 8 {
		return hcat(mark, col(" "), tl)
	}
	return hcat(mark, col(" "), tl, col("   "), info, tog, col("  "))
}

// viewEmpty is the first-run screen: a ringing alarm clock and a hint.
func (m *alarmMode) viewEmpty(w, h int) []string {
	pal := m.c.Pal
	title := bold(pal.Text, i18n.T("alarm.empty.title"))
	hint := paint(pal.Muted, i18n.T("alarm.empty.hint"))
	art := h - 5
	if art < 4 || w < 20 {
		return centerBlock([]string{title, hint}, w, h)
	}
	rows := mini(art, 13)
	cols := rows * 2
	if cols > w-2 {
		cols = w - 2
		rows = cols / 2
	}
	if m.artCv == nil || m.artCv.Cols != cols || m.artCv.Rows != rows {
		m.artCv = braille.New(cols, rows)
	} else {
		m.artCv.Clear()
	}
	alarmClockCanvas(m.artCv, m.c.Pal, m.c.Anim, m.c.Cfg.Motion == "still")
	block := append([]string{}, m.artCv.Lines()...)
	block = append(block, "", centerIn(title, cols), centerIn(hint, cols))
	return centerBlock(block, w, h)
}

// viewCard is the wide layout's big "next alarm" panel with the bell.
func (m *alarmMode) viewCard(w, h int) []string {
	pal := m.c.Pal
	nx, at := m.c.Alarms.Next()
	rows := clampi(h*5/12, 4, 12)
	cols := rows * 2
	if cols > w {
		cols = w
		rows = cols / 2
	}
	if m.cardCv == nil || m.cardCv.Cols != cols || m.cardCv.Rows != rows {
		m.cardCv = braille.New(cols, rows)
	} else {
		m.cardCv.Clear()
	}
	var block []string
	if m.ed != nil {
		// preview of what is being edited
		alarmBellCanvas(m.cardCv, pal, 0.5, m.c.Anim, false, m.c.Cfg.Motion == "still", true)
		block = append(block, m.cardCv.Lines()...)
		block = append(block, "")
		tl := alarmBigTime(fmt.Sprintf("%02d:%02d", m.ed.hour, m.ed.min), 4, pal.Bright)
		block = append(block, tl...)
		block = append(block, "")
		for _, l := range strings.Split(ansi.Wrap(m.alarmPreviewText(m.ed.hour, m.ed.min, m.ed.days), w, ""), "\n") {
			block = append(block, paint(pal.Muted, l))
		}
		return centerBlock(alarmCenterAll(block, w), w, h)
	}
	if nx == nil {
		alarmBellCanvas(m.cardCv, pal, 0, m.c.Anim, false, m.c.Cfg.Motion == "still", false)
		block = append(block, m.cardCv.Lines()...)
		block = append(block, "", paint(pal.Muted, i18n.T("alarm.none.armed")))
		return centerBlock(alarmCenterAll(block, w), w, h)
	}
	until := at.Sub(m.c.Now)
	alarmBellCanvas(m.cardCv, pal, alarmIntensity(until), m.c.Anim, until < time.Minute, m.c.Cfg.Motion == "still", true)
	block = append(block, m.cardCv.Lines()...)
	block = append(block, "", bold(pal.Muted, i18n.T("alarm.next")))
	for _, l := range alarmBigTime(at.In(m.c.Now.Location()).Format("15:04"), 4, pal.Bright) {
		block = append(block, l)
	}
	block = append(block, "", paint(pal.Bright, i18n.T("alarm.in", alarmDur(until))))
	block = append(block, bold(pal.Text, m.label(nx)))
	if t, ok := alarmDaysText(nx.Days); ok {
		block = append(block, paint(pal.Muted, t))
	} else {
		block = append(block, m.alarmChips(nx.Days, false))
	}
	return centerBlock(alarmCenterAll(block, w), w, h)
}

// alarmCenterAll centres every line of a block on the same axis.
func alarmCenterAll(lines []string, w int) []string {
	out := make([]string, len(lines))
	for i, l := range lines {
		out[i] = centerIn(l, w)
	}
	return out
}

func alarmTrim(s string, w int) string {
	if width(s) <= w {
		return s
	}
	r := []rune(s)
	for len(r) > 0 && width(string(r)) > w-1 {
		r = r[:len(r)-1]
	}
	return string(r) + "…"
}

var _ = math.Pi
