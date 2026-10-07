package ui

import (
	"fmt"
	"strings"
	"time"

	"charm.land/bubbles/v2/key"
	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

type worldState int

const (
	worldBrowse worldState = iota
	worldPick
	worldConfirm
	worldPlan
)

// worldMode is the world clock: a day/night braille map, the list of cities
// with their local time, a card for the selected one, a city picker and a
// meeting planner.
type worldMode struct {
	c   *Core
	say func(string)

	state worldState
	sel   int
	top   int     // first visible list row
	ping  float64 // seconds since the selection last changed

	mapv   worldMapView
	locs   map[string]*time.Location
	cardCv *braille.Canvas

	// city picker
	input   textinput.Model
	pick    []engine.City
	pickSel int
	pickTop int

	// planner
	planHour int // UTC hour under the cursor

	// hit areas of the last View, relative to the body
	listX, listY, listW, listRows int
	mapX, mapY                    int
}

func init() {
	registerMode("world", func(c *Core, say func(string)) Mode { return newWorld(c, say) })
}

func newWorld(c *Core, say func(string)) *worldMode {
	return &worldMode{c: c, say: say, locs: map[string]*time.Location{}, ping: 9}
}

func (m *worldMode) ID() string { return "world" }

func (m *worldMode) Animated() bool { return m.c.Cfg.Motion != "still" }

func (m *worldMode) Capturing() bool { return m.state != worldBrowse }

func (m *worldMode) Frame(dt time.Duration) { m.ping += dt.Seconds() }

// ----------------------------------------------------------------- cities

func (m *worldMode) loc(c engine.City) *time.Location {
	if l, ok := m.locs[c.Zone]; ok {
		return l
	}
	l := c.Loc()
	m.locs[c.Zone] = l
	return l
}

// cities resolves the configured ids; unknown ones are skipped.
func (m *worldMode) cities() []engine.City {
	out := make([]engine.City, 0, len(m.c.Cfg.Cities))
	for _, id := range m.c.Cfg.Cities {
		if city, ok := engine.CityByID(id); ok {
			out = append(out, city)
		}
	}
	return out
}

func (m *worldMode) save(cs []engine.City) {
	ids := make([]string, len(cs))
	for i, c := range cs {
		ids[i] = c.ID
	}
	m.c.Cfg.Cities = ids
	m.c.ApplyConfig()
}

func (m *worldMode) clampSel(n int) {
	if m.sel >= n {
		m.sel = n - 1
	}
	if m.sel < 0 {
		m.sel = 0
	}
}

func (m *worldMode) setSel(i, n int) {
	if n == 0 {
		return
	}
	i = clampi(i, 0, n-1)
	if i != m.sel {
		m.sel = i
		m.ping = 0
	}
}

// ----------------------------------------------------------------- help

func (m *worldMode) Help() []key.Binding {
	switch m.state {
	case worldPick:
		return []key.Binding{
			kb("up|down", "↑↓", i18n.T("key.select")),
			kb("enter", "enter", i18n.T("world.add")),
			kb("esc", "esc", i18n.T("key.cancel")),
		}
	case worldConfirm:
		return []key.Binding{kb("y", "y", i18n.T("world.yes")), kb("n|esc", "n", i18n.T("world.no"))}
	case worldPlan:
		return []key.Binding{
			kb("left|right", "←→", i18n.T("world.hour")),
			kb("n", "n", i18n.T("world.now")),
			kb("esc|m", "esc", i18n.T("key.back")),
		}
	}
	return []key.Binding{
		kb("up|k|down|j", "↑↓", i18n.T("key.select")),
		kb("a", "a", i18n.T("world.add")),
		kb("x", "x", i18n.T("world.remove")),
		kb("J|K|alt+up|alt+down", "J/K", i18n.T("world.move")),
		kb("m", "m", i18n.T("world.plan")),
		kb("t", "t", "12/24h"),
	}
}

// ----------------------------------------------------------------- update

func (m *worldMode) Update(msg tea.Msg) tea.Cmd {
	switch m.state {
	case worldPick:
		return m.updatePick(msg)
	case worldConfirm:
		if k, ok := msg.(tea.KeyPressMsg); ok {
			switch k.String() {
			case "y", "Y", "enter":
				m.remove()
			default:
				m.state = worldBrowse
			}
		}
		return nil
	case worldPlan:
		return m.updatePlan(msg)
	}
	return m.updateBrowse(msg)
}

func (m *worldMode) updateBrowse(msg tea.Msg) tea.Cmd {
	cities := m.cities()
	n := len(cities)
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch {
		case matches(msg, kb("up|k", "", "")):
			m.setSel(m.sel-1, n)
		case matches(msg, kb("down|j", "", "")):
			m.setSel(m.sel+1, n)
		case matches(msg, kb("home", "", "")):
			m.setSel(0, n)
		case matches(msg, kb("end", "", "")):
			m.setSel(n-1, n)
		case matches(msg, kb("K|alt+up", "", "")):
			m.move(cities, -1)
		case matches(msg, kb("J|alt+down", "", "")):
			m.move(cities, 1)
		case matches(msg, kb("H", "", "")):
			m.move(cities, -m.sel)
		case matches(msg, kb("a", "", "")):
			m.openPicker()
		case matches(msg, kb("x", "", "")):
			if n <= 1 {
				m.say(i18n.T("world.last"))
			} else {
				m.state = worldConfirm
			}
		case matches(msg, kb("m", "", "")):
			m.state = worldPlan
			m.planHour = m.c.Now.UTC().Hour()
		case matches(msg, kb("t", "", "")):
			m.c.Cfg.Clock24 = !m.c.Cfg.Clock24
			m.c.ApplyConfig()
		}
	case tea.MouseClickMsg:
		if msg.Button != tea.MouseLeft {
			return nil
		}
		if msg.X >= m.listX && msg.X < m.listX+m.listW && msg.Y >= m.listY && msg.Y < m.listY+m.listRows {
			m.setSel(m.top+msg.Y-m.listY, n)
			return nil
		}
		// a click on the map selects the nearest city
		cx, cy := msg.X-m.mapX, msg.Y-m.mapY
		best, bd := -1, 1e9
		for _, mk := range m.mapv.marks {
			dx, dy := float64(mk.cx-cx)*2, float64(mk.cy-cy)*4
			if d := dx*dx + dy*dy; d < bd {
				best, bd = mk.idx, d
			}
		}
		if best >= 0 && bd <= 12*12 {
			m.setSel(best, n)
		}
	case tea.MouseWheelMsg:
		if msg.Button == tea.MouseWheelUp {
			m.setSel(m.sel-1, n)
		} else if msg.Button == tea.MouseWheelDown {
			m.setSel(m.sel+1, n)
		}
	}
	return nil
}

// move shifts the selected city by d places in the list.
func (m *worldMode) move(cities []engine.City, d int) {
	j := m.sel + d
	if d == 0 || j < 0 || j >= len(cities) {
		return
	}
	c := cities[m.sel]
	cities = append(cities[:m.sel], cities[m.sel+1:]...)
	cities = append(cities[:j], append([]engine.City{c}, cities[j:]...)...)
	m.sel = j
	m.save(cities)
}

func (m *worldMode) remove() {
	cities := m.cities()
	m.state = worldBrowse
	if len(cities) <= 1 || m.sel >= len(cities) {
		return
	}
	gone := cities[m.sel]
	cities = append(cities[:m.sel], cities[m.sel+1:]...)
	m.clampSel(len(cities))
	m.save(cities)
	m.say(i18n.T("world.removed", gone.Name(i18n.Lang())))
}

// ---------------------------------------------------------------- picker

func (m *worldMode) openPicker() {
	ti := textinput.New()
	ti.Prompt = "› "
	ti.Placeholder = i18n.T("world.add.search")
	ti.CharLimit = 40
	pal := m.c.Pal
	st := textinput.DefaultDarkStyles()
	st.Focused.Prompt = lipgloss.NewStyle().Foreground(pal.Accent).Bold(true)
	st.Focused.Text = lipgloss.NewStyle().Foreground(pal.Text)
	st.Focused.Placeholder = lipgloss.NewStyle().Foreground(pal.Muted)
	st.Cursor.Color = pal.Accent
	ti.SetStyles(st)
	ti.Focus()
	m.input = ti
	m.state = worldPick
	m.pickSel, m.pickTop = 0, 0
	m.refilter()
}

func (m *worldMode) refilter() {
	m.pick = worldFilter(m.input.Value(), i18n.Lang())
	m.pickSel, m.pickTop = 0, 0
}

func (m *worldMode) updatePick(msg tea.Msg) tea.Cmd {
	k, ok := msg.(tea.KeyPressMsg)
	if !ok {
		if w, isWheel := msg.(tea.MouseWheelMsg); isWheel {
			if w.Button == tea.MouseWheelUp {
				m.pickSel = clampi(m.pickSel-1, 0, maxi(len(m.pick)-1, 0))
			} else if w.Button == tea.MouseWheelDown {
				m.pickSel = clampi(m.pickSel+1, 0, maxi(len(m.pick)-1, 0))
			}
		}
		return nil
	}
	switch k.String() {
	case "esc":
		m.state = worldBrowse
		return nil
	case "up", "ctrl+p":
		m.pickSel = clampi(m.pickSel-1, 0, maxi(len(m.pick)-1, 0))
		return nil
	case "down", "ctrl+n":
		m.pickSel = clampi(m.pickSel+1, 0, maxi(len(m.pick)-1, 0))
		return nil
	case "pgup":
		m.pickSel = clampi(m.pickSel-8, 0, maxi(len(m.pick)-1, 0))
		return nil
	case "pgdown":
		m.pickSel = clampi(m.pickSel+8, 0, maxi(len(m.pick)-1, 0))
		return nil
	case "enter":
		if len(m.pick) == 0 {
			return nil
		}
		city := m.pick[m.pickSel]
		cities := m.cities()
		for i, c := range cities {
			if c.ID == city.ID {
				m.sel = i
				m.ping = 0
				m.state = worldBrowse
				m.say(i18n.T("world.exists", city.Name(i18n.Lang())))
				return nil
			}
		}
		cities = append(cities, city)
		m.save(cities)
		m.sel = len(cities) - 1
		m.ping = 0
		m.state = worldBrowse
		m.say(i18n.T("world.added", city.Name(i18n.Lang())))
		return nil
	}
	before := m.input.Value()
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	if m.input.Value() != before {
		m.refilter()
	}
	return cmd
}

// ---------------------------------------------------------------- planner

func (m *worldMode) updatePlan(msg tea.Msg) tea.Cmd {
	switch msg := msg.(type) {
	case tea.KeyPressMsg:
		switch msg.String() {
		case "esc", "m", "q", "enter":
			m.state = worldBrowse
		case "left", "h":
			m.planHour = (m.planHour + 23) % 24
		case "right", "l":
			m.planHour = (m.planHour + 1) % 24
		case "shift+left", "H":
			m.planHour = (m.planHour + 21) % 24
		case "shift+right", "L":
			m.planHour = (m.planHour + 3) % 24
		case "n", "home":
			m.planHour = m.c.Now.UTC().Hour()
		case "up", "k":
			m.setSel(m.sel-1, len(m.cities()))
		case "down", "j":
			m.setSel(m.sel+1, len(m.cities()))
		}
	case tea.MouseWheelMsg:
		if msg.Button == tea.MouseWheelUp {
			m.planHour = (m.planHour + 23) % 24
		} else if msg.Button == tea.MouseWheelDown {
			m.planHour = (m.planHour + 1) % 24
		}
	case tea.MouseClickMsg:
		if msg.Button == tea.MouseLeft && msg.X >= m.listX && msg.X < m.listX+m.listW {
			m.planHour = clampi((msg.X-m.listX)*24/maxi(m.listW, 1), 0, 23)
		}
	}
	return nil
}

// ------------------------------------------------------------------ view

func (m *worldMode) View(w, h int) string {
	if w < 1 || h < 1 {
		return ""
	}
	switch m.state {
	case worldPick:
		return join(fit(m.pickerView(w, h), w, h))
	case worldPlan:
		return join(fit(m.plannerView(w, h), w, h))
	}
	cities := m.cities()
	if len(cities) == 0 {
		msg := paint(m.c.Pal.Muted, i18n.T("world.empty"))
		return join(fit(centerBlock([]string{msg}, w, h), w, h))
	}
	m.clampSel(len(cities))
	m.listW = 0
	switch {
	case w >= 100 && h >= 20:
		return join(fit(m.wideView(cities, w, h), w, h))
	case w >= 40 && h >= 14:
		return join(fit(m.compactView(cities, w, h), w, h))
	}
	return join(fit(m.tinyView(cities, w, h), w, h))
}

func worldColsFor(rows int) int { return int(float64(rows) * 4 * 360 / (worldLatSpan * 2)) }

// mapBlock renders the map in cols x rows cells.
func (m *worldMode) mapBlock(cities []engine.City, cols, rows int) []string {
	if m.mapv.canvas == nil || m.mapv.cols != cols || m.mapv.rows != rows {
		m.mapv.rebuild(cols, rows)
	}
	c := m.c
	m.mapv.draw(c.Pal, c.Now, cities, m.sel, c.Anim, m.ping, c.Cfg.Motion == "still")
	return m.mapv.lines(c.Pal, cities, m.sel, i18n.Lang())
}

// sunStrip is the line under the map: where the sun is, and UTC.
func (m *worldMode) sunStrip(w int) string {
	pal := m.c.Pal
	lat, lon := engine.SubSolar(m.c.Now)
	s := paint(pal.Sun, "☼ ") + paint(pal.Muted, i18n.T("world.sunat", worldFmtLat(lat)+" "+worldFmtLon(lon))) +
		paint(pal.Faint, "  ·  ") + paint(pal.Muted, "UTC ") + paint(pal.Text, m.c.Now.UTC().Format("15:04"))
	return centerIn(s, w)
}

func (m *worldMode) wideView(cities []engine.City, w, h int) []string {
	panelW := clampi(w*34/100, 38, 52)
	panelW = mini(panelW, 46)
	areaW := w - panelW - 1
	rows := mini(h-1, worldIdealRows(areaW))
	cols := mini(areaW, worldColsFor(rows))
	rows = mini(rows, worldIdealRows(cols))
	if rows < 3 {
		rows = 3
	}
	block := m.mapBlock(cities, cols, rows)
	block = append(block, "", m.sunStrip(cols))
	left := blank(areaW, h)
	top := (h - len(block)) / 2
	if top < 0 {
		top = 0
	}
	lx := (areaW - cols) / 2
	for i, l := range block {
		if top+i < h {
			left[top+i] = padRight(spaces(lx)+l, areaW)
		}
	}
	m.mapX, m.mapY = lx, top

	// panel: list, then the card right under it; the pair is centered
	panelW = mini(panelW, 46)
	card := m.card(cities[m.sel], panelW, h)
	listH := mini(len(cities)+1, h-len(card)-1)
	if listH < 4 {
		card = card[:0]
		listH = h
	}
	listH = mini(listH, len(cities)+1)
	list := m.list(cities, panelW, listH, true)
	panel := list
	if len(card) > 0 {
		panel = append(panel, "")
		panel = append(panel, card...)
	}
	top = (h - len(panel)) / 2
	if top < 0 {
		top = 0
	}
	m.listX, m.listY, m.listW = areaW+1+(w-areaW-1-panelW), top+1, panelW
	m.listRows = mini(len(cities), listH-1)
	full := blank(panelW, h)
	for i, l := range panel {
		if top+i < h {
			full[top+i] = padRight(l, panelW)
		}
	}
	return hcat(left, blank(1, h), full)
}

func (m *worldMode) compactView(cities []engine.City, w, h int) []string {
	rows := mini(worldIdealRows(w), h*55/100)
	if rows < 4 {
		rows = 4
	}
	cols := mini(w, worldColsFor(rows))
	rows = mini(rows, worldIdealRows(cols))
	block := m.mapBlock(cities, cols, rows)
	out := make([]string, 0, h)
	for _, l := range block {
		out = append(out, centerIn(l, w))
	}
	m.mapX, m.mapY = (w-cols)/2, 0
	rest := h - len(out)
	if rest >= 4 && w >= 56 {
		out = append(out, centerIn(m.sunStrip(w), w))
		rest--
	}
	if w >= 76 && rest >= 8 {
		lw := w * 55 / 100
		cw := w - lw - 2
		list := m.list(cities, lw, rest, true)
		card := m.card(cities[m.sel], cw, rest)
		m.listX, m.listY, m.listW = 0, len(out)+1, lw
		m.listRows = mini(len(cities), rest-1)
		out = append(out, hcat(list, blank(2, rest), card)...)
	} else {
		m.listX, m.listY, m.listW = 0, len(out)+1, w
		m.listRows = mini(len(cities), rest-1)
		out = append(out, m.list(cities, w, rest, w >= 52)...)
	}
	return out
}

func (m *worldMode) tinyView(cities []engine.City, w, h int) []string {
	m.listX, m.listY, m.listW = 0, 0, w
	m.listRows = mini(len(cities), h)
	return m.list(cities, w, h, false)
}

// -------------------------------------------------------------- list rows

func worldFold(s string) string {
	s = strings.ToLower(s)
	r := strings.NewReplacer("á", "a", "à", "a", "ã", "a", "â", "a", "ä", "a", "é", "e", "è", "e", "ê", "e", "ë", "e",
		"í", "i", "ì", "i", "î", "i", "ï", "i", "ó", "o", "ò", "o", "õ", "o", "ô", "o", "ö", "o",
		"ú", "u", "ù", "u", "û", "u", "ü", "u", "ñ", "n", "ç", "c", "ý", "y", "_", " ", "/", " ")
	return r.Replace(s)
}

// worldFilter lists catalog cities matching q (accent- and language-blind),
// prefix matches first. An empty query lists everything by name.
func worldFilter(q, lang string) []engine.City {
	q = strings.TrimSpace(worldFold(q))
	type scored struct {
		c engine.City
		s int
		n string
	}
	var out []scored
	for _, c := range engine.Cities {
		en, es, id := worldFold(c.EN), worldFold(c.ES), worldFold(c.ID)
		score := 0
		switch {
		case q == "":
			score = 3
		case strings.HasPrefix(en, q) || strings.HasPrefix(es, q):
			score = 3
		case strings.Contains(en, q) || strings.Contains(es, q):
			score = 2
		case strings.Contains(id, q):
			score = 1
		}
		if score > 0 {
			out = append(out, scored{c, score, worldFold(c.Name(lang))})
		}
	}
	// stable insertion sort: score desc, then name
	for i := 1; i < len(out); i++ {
		for j := i; j > 0 && (out[j].s > out[j-1].s || out[j].s == out[j-1].s && out[j].n < out[j-1].n); j-- {
			out[j], out[j-1] = out[j-1], out[j]
		}
	}
	res := make([]engine.City, len(out))
	for i, o := range out {
		res[i] = o.c
	}
	return res
}

// worldTimeText is a clock reading in the user's 12/24h preference.
func (m *worldMode) timeText(t time.Time) string {
	if m.c.Cfg.Clock24 {
		return t.Format("15:04")
	}
	return t.Format("3:04 PM")
}

// worldOffset formats the difference between two UTC offsets: +3h, -5:30.
func worldOffset(diffSec int) string {
	if diffSec == 0 {
		return "·"
	}
	sign := "+"
	if diffSec < 0 {
		sign, diffSec = "-", -diffSec
	}
	hh, mm := diffSec/3600, diffSec%3600/60
	if mm == 0 {
		return fmt.Sprintf("%s%dh", sign, hh)
	}
	return fmt.Sprintf("%s%d:%02d", sign, hh, mm)
}

func (m *worldMode) skyIcon(c engine.City, t time.Time) string {
	pal := m.c.Pal
	sl, sn := engine.SubSolar(m.c.Now)
	alt := engine.SunAltitude(c.Lat, c.Lon, sl, sn)
	switch {
	case alt >= 6:
		return paint(pal.Sun, "☼")
	case alt <= -6:
		return paint(pal.Moon, "☾")
	case t.Hour() < 12:
		return paint(pal.Warn, "◐")
	}
	return paint(pal.Warn, "◑")
}

// list renders the cities, one per row, under a title row.
func (m *worldMode) list(cities []engine.City, w, h int, roomy bool) []string {
	pal := m.c.Pal
	lang := i18n.Lang()
	now := m.c.Now
	home := now.In(m.loc(cities[0]))
	_, homeOff := home.Zone()

	rows := h - 1
	showTitle := h >= 4
	if !showTitle {
		rows = h
	}
	if rows < 1 {
		rows = 1
	}
	// keep the selection in view
	if m.sel < m.top {
		m.top = m.sel
	}
	if m.sel >= m.top+rows {
		m.top = m.sel - rows + 1
	}
	if m.top > len(cities)-rows {
		m.top = maxi(len(cities)-rows, 0)
	}

	timew := 5
	if !m.c.Cfg.Clock24 {
		timew = 8
	}
	longest := 4
	for _, c := range cities {
		if x := width(c.Name(lang)); x > longest {
			longest = x
		}
	}
	var lines []string
	if showTitle {
		t := paint(pal.Muted, strings.ToUpper(i18n.T("world.cities")))
		if len(cities) > rows {
			t += paint(pal.Faint, fmt.Sprintf("  %d/%d", m.sel+1, len(cities)))
		}
		lines = append(lines, padRight(" "+t, w))
	}
	for i := m.top; i < len(cities) && i < m.top+rows; i++ {
		city := cities[i]
		t := now.In(m.loc(city))
		_, off := t.Zone()
		selected := i == m.sel

		prefix := "  "
		if selected {
			prefix = bold(pal.Accent, "▸ ")
		}
		icon := m.skyIcon(city, t)
		tag := ""
		if i == 0 {
			tag = paint(pal.Muted, "⌂")
		} else if roomy || w >= 30 {
			tag = paint(pal.Muted, worldOffset(off-homeOff))
		}
		day := ""
		if dd := worldDayDiff(t, home); dd != 0 && w >= 34 {
			day = paint(pal.Warn, fmt.Sprintf("%+dd", dd))
		}
		tw := width(tag)
		dw := 3
		if w < 34 {
			dw = 0
		}
		tagw := 6
		if w < 30 {
			tagw = 0
		}
		namew := w - 2 - 2 - timew - 1 - dw - tagw - 1
		if namew > longest+1 {
			namew = longest + 1
		}
		if namew < 4 {
			namew = 4
		}
		name := city.Name(lang)
		if r := []rune(name); len(r) > namew {
			name = string(r[:namew-1]) + "…"
		}
		nameS := paint(pal.Text, name)
		timeS := paint(pal.Text, m.timeText(t))
		if selected {
			nameS = bold(pal.Text, name)
			timeS = bold(pal.Bright, m.timeText(t))
		} else {
			nameS = paint(pal.Muted.Mix(pal.Text, 0.4), name)
			timeS = paint(pal.Muted.Mix(pal.Text, 0.55), m.timeText(t))
		}
		line := prefix + icon + " " + padRight(nameS, namew) + " " + padLeft(timeS, timew)
		if dw > 0 {
			line += " " + padRight(day, dw-0)
		}
		if tagw > 0 {
			line += " " + padLeft(tag, tagw-1)
		}
		_ = tw
		lines = append(lines, padRight(line, w))
	}
	if m.state == worldConfirm && m.sel >= m.top && m.sel < m.top+rows {
		idx := m.sel - m.top
		if showTitle {
			idx++
		}
		q := paint(pal.Warn, i18n.T("world.remove.confirm", cities[m.sel].Name(lang))) + paint(pal.Muted, "  y/n")
		lines[idx] = padRight(" "+q, w)
	}
	return lines
}

// worldDayDiff is how many calendar days t's date is ahead of ref's.
func worldDayDiff(t, ref time.Time) int {
	a := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
	b := time.Date(ref.Year(), ref.Month(), ref.Day(), 0, 0, 0, 0, time.UTC)
	return int(a.Sub(b).Hours() / 24)
}

// ------------------------------------------------------------------ card

func worldDateText(t time.Time) string {
	if i18n.Lang() == "es" {
		return spanishDate(t)
	}
	return t.Format("Mon 2 Jan")
}

func worldUTCText(off int) string {
	sign := "+"
	if off < 0 {
		sign, off = "-", -off
	}
	if off%3600 == 0 {
		return fmt.Sprintf("UTC%s%d", sign, off/3600)
	}
	return fmt.Sprintf("UTC%s%d:%02d", sign, off/3600, off%3600/60)
}

// card describes the selected city: big digits, date, zone, sun times. It
// returns at most maxH lines, dropping details first when space is short.
func (m *worldMode) card(city engine.City, w, maxH int) []string {
	pal := m.c.Pal
	lang := i18n.Lang()
	loc := m.loc(city)
	t := m.c.Now.In(loc)
	zone, off := t.Zone()
	sl, sn := engine.SubSolar(m.c.Now)
	alt := engine.SunAltitude(city.Lat, city.Lon, sl, sn)
	day := worldDayFactor(alt)

	head := bold(pal.Accent, strings.ToUpper(city.Name(lang)))
	ampm := ""
	text := t.Format("15:04")
	if !m.c.Cfg.Clock24 {
		text = t.Format("3:04")
		ampm = " " + t.Format("PM")
	}
	zoneLine := paint(pal.Muted, worldUTCText(off))
	if len(zone) > 0 && zone[0] != '+' && zone[0] != '-' {
		zoneLine = paint(pal.Muted, zone+" · "+worldUTCText(off))
	}
	if t.IsDST() {
		zoneLine += paint(pal.Warn, " · "+i18n.T("world.dst"))
	}
	dateLine := paint(pal.Text, worldDateText(t)+ampm)

	digitRows := 5
	switch {
	case maxH < 6:
		digitRows = 0
	case maxH < 9:
		digitRows = 3
	case maxH < 12:
		digitRows = 4
	}
	var lines []string
	lines = append(lines, " "+head)
	if digitRows > 0 {
		digits := m.cardDigits(text, w-2, digitRows, pal.Moon.Mix(pal.Text, day))
		for _, l := range digits {
			lines = append(lines, " "+l)
		}
		lines = append(lines, " "+dateLine)
	} else {
		lines = append(lines, " "+bold(pal.Text, m.timeText(t))+"  "+dateLine)
	}
	if maxH > len(lines) {
		lines = append(lines, " "+zoneLine)
	}
	if rise, set, polar := worldSunTimes(city.Lat, city.Lon, t); maxH > len(lines) {
		switch polar {
		case 1:
			lines = append(lines, " "+paint(pal.Sun, "☼ "+i18n.T("world.polar.day")))
		case -1:
			lines = append(lines, " "+paint(pal.Moon, "☾ "+i18n.T("world.polar.night")))
		default:
			lines = append(lines, " "+paint(pal.Sun, "☼ ")+paint(pal.Text, m.shortTime(rise))+
				paint(pal.Faint, "   ")+paint(pal.Moon, "☾ ")+paint(pal.Text, m.shortTime(set)))
			if maxH > len(lines) {
				d := set.Sub(rise)
				lines = append(lines, " "+paint(pal.Muted, i18n.T("world.daylight", fmt.Sprintf("%dh %02dm", int(d.Hours()), int(d.Minutes())%60))))
			}
		}
	}
	if len(lines) > maxH {
		lines = lines[:maxH]
	}
	return fit(lines, w, len(lines))
}

func (m *worldMode) shortTime(t time.Time) string {
	if m.c.Cfg.Clock24 {
		return t.Format("15:04")
	}
	return t.Format("3:04PM")
}

// cardDigits draws the time in big braille digits.
func (m *worldMode) cardDigits(text string, w, rows int, col braille.RGB) []string {
	if m.cardCv == nil || m.cardCv.Cols != w || m.cardCv.Rows != rows {
		m.cardCv = braille.New(w, rows)
	} else {
		m.cardCv.Clear()
	}
	cv := m.cardCv
	font := braille.ParseFont(m.c.Cfg.Font)
	h := font.FitHeight(text, cv.W-2, cv.H-2)
	if h < 6 {
		h = 6
	}
	cv.Text(font, text, 1, float64(cv.H-h)/2, h, braille.Solid(col))
	return cv.Lines()
}
