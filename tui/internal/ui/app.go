package ui

import (
	"time"

	"charm.land/bubbles/v2/help"
	"charm.land/bubbles/v2/key"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"
	"github.com/charmbracelet/x/ansi"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
	"github.com/sazardev/enfo/tui/internal/store"
)

type tickMsg time.Time

// App is the root Bubble Tea model.
type App struct {
	core *Core
	ids  map[string]Mode
	// enabled modes in display order, and the one on screen
	order   []string
	current string

	hdr  *header
	help help.Model

	w, h     int
	toasts   []*toast
	trans    *transition
	last     []string // last rendered body, for transitions
	zen      bool
	blurred  bool
	ring     *ringer
	rings    []*ringer
	splash   *splash
	manual   *helpOverlay
	showHelp bool
	quitting bool
	page     Mode // an open page (stats, settings), or nil
	pageID   string
	cfgGen   int

	lastTick time.Time
	nextBell time.Time
	opts     Options
}

// Options are the launch parameters (from the command line).
type Options struct {
	Mode     string // open this mode ("" = the configured one)
	NoSplash bool
	Now      func() time.Time // test hook
	// Setup runs once after the core is loaded and before the first frame
	// (the command line uses it to start a timer, set a rhythm ...).
	Setup func(*Core)
	// OnQuit runs when the user quits, after the state was saved (the command
	// line uses it to hand running timers to a background waker).
	OnQuit func(*Core)
}

// New builds the app from disk state.
func New(st *store.Store, opts Options) *App {
	now := time.Now()
	if opts.Now != nil {
		now = opts.Now()
	}
	core := NewCore(st, now)
	if opts.Setup != nil {
		opts.Setup(core)
	}
	a := &App{core: core, ids: map[string]Mode{}, hdr: newHeader(), help: help.New(), opts: opts, lastTick: now}
	a.initModes()
	start := core.Cfg.Start
	if opts.Mode != "" {
		start = opts.Mode
	}
	if start == "last" {
		start = st.LoadState().LastMode
	}
	a.current = a.order[0]
	for _, id := range a.order {
		if id == start {
			a.current = id
		}
	}
	if core.Cfg.Splash && !opts.NoSplash && opts.Mode == "" {
		a.splash = newSplash(now)
	}
	a.applyHelpStyles()
	if !core.Cfg.Onboarded && opts.Mode == "" && pageFactories["welcome"] != nil {
		a.openPage("welcome")
	}
	return a
}

func (a *App) applyHelpStyles() {
	pal := a.core.Pal
	k := lipgloss.NewStyle().Foreground(pal.Text)
	d := lipgloss.NewStyle().Foreground(pal.Muted)
	s := lipgloss.NewStyle().Foreground(pal.Faint)
	a.help.Styles = help.Styles{
		ShortKey: k, ShortDesc: d, ShortSeparator: s, Ellipsis: s,
		FullKey: k, FullDesc: d, FullSeparator: s,
	}
	a.help.ShortSeparator = "  ·  "
}

func (a *App) initModes() {
	say := func(s string) { a.say(s) }
	a.order = nil
	seen := map[string]bool{}
	for _, id := range a.core.Cfg.Modes {
		f := modeFactories[id]
		if f == nil || seen[id] {
			continue
		}
		seen[id] = true
		if a.ids[id] == nil {
			a.ids[id] = f(a.core, say)
		}
		a.order = append(a.order, id)
	}
	// a mode opened by name (enfo kitchen) stays even when switched off
	if id := a.opts.Mode; id != "" && !seen[id] && modeFactories[id] != nil {
		if a.ids[id] == nil {
			a.ids[id] = modeFactories[id](a.core, say)
		}
		a.order = append(a.order, id)
	}
	if len(a.order) == 0 {
		a.ids["pomodoro"] = modeFactories["pomodoro"](a.core, say)
		a.order = []string{"pomodoro"}
	}
	a.cfgGen = a.core.cfgGen
}

// reloadModes applies a changed configuration (modes on/off or reordered).
func (a *App) reloadModes() {
	a.initModes()
	if a.ids[a.current] == nil || !contains(a.order, a.current) {
		a.current = a.order[0]
	}
	a.applyHelpStyles()
	a.manual = nil
}

func contains(l []string, s string) bool {
	for _, x := range l {
		if x == s {
			return true
		}
	}
	return false
}

func (a *App) mode() Mode { return a.ids[a.current] }

// active is what has the screen: the open page, else the current mode.
func (a *App) active() Mode {
	if a.page != nil {
		return a.page
	}
	return a.mode()
}

// chromeless reports whether the open page wants the whole screen.
func (a *App) chromeless() bool {
	if c, ok := a.page.(interface{ Chromeless() bool }); ok {
		return c.Chromeless()
	}
	return false
}

func (a *App) capturing() bool {
	if c, ok := a.active().(Capturer); ok {
		return c.Capturing()
	}
	return false
}

func (a *App) openPage(id string) {
	f := pageFactories[id]
	if f == nil {
		return
	}
	a.page, a.pageID = f(a.core, func(s string) { a.say(s) }), id
}

// runners is every running thing: the core's timers plus background modes.
func (a *App) runners() []Running {
	out := a.core.Runners()
	for _, id := range a.order {
		if bg, ok := a.ids[id].(Background); ok {
			if r := bg.Runner(); r != nil {
				if r.Mode == "" {
					r.Mode = id
				}
				out = append(out, *r)
			}
		}
	}
	return out
}

func (a *App) runningIn(id string) bool {
	for _, r := range a.runners() {
		if r.Mode == id && !r.Paused {
			return true
		}
	}
	return false
}

// ---------------------------------------------------------------- tea.Model

func (a *App) Init() tea.Cmd {
	return tea.Batch(a.tick(), tea.RequestBackgroundColor)
}

func (a *App) interval() time.Duration {
	if a.blurred {
		return 500 * time.Millisecond
	}
	if a.splash != nil || a.ring != nil || a.trans != nil || len(a.toasts) > 0 {
		return 33 * time.Millisecond
	}
	if m := a.active(); m != nil && m.Animated() {
		switch a.core.Cfg.Motion {
		case "calm":
			return 66 * time.Millisecond
		case "still":
			return 100 * time.Millisecond
		}
		return 33 * time.Millisecond
	}
	return 100 * time.Millisecond
}

func (a *App) tick() tea.Cmd {
	return tea.Tick(a.interval(), func(t time.Time) tea.Msg { return tickMsg(t) })
}

func (a *App) now() time.Time {
	if a.opts.Now != nil {
		return a.opts.Now()
	}
	return time.Now()
}

func (a *App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		a.w, a.h = msg.Width, msg.Height
		a.core.W, a.core.H = msg.Width, msg.Height
		return a, nil

	case tea.BackgroundColorMsg:
		a.setBackground(msg)
		return a, nil

	case tea.FocusMsg:
		a.blurred = false
		return a, nil
	case tea.BlurMsg:
		a.blurred = true
		return a, nil

	case tickMsg:
		return a, a.onTick(time.Time(msg))

	case tea.KeyPressMsg:
		return a, a.onKey(msg)

	case tea.MouseMsg:
		return a, a.onMouse(msg)
	}
	// anything else (cursor blinks, spinners, form commands) belongs to
	// whatever has the screen
	if a.ring == nil && a.splash == nil {
		if m := a.active(); m != nil && (a.page != nil || a.capturing()) {
			return a, m.Update(msg)
		}
	}
	return a, nil
}

func (a *App) setBackground(msg tea.BackgroundColorMsg) {
	a.core.bg = braille.FromColor(msg.Color)
	a.core.dark = msg.IsDark()
	a.core.ApplyConfig()
}

func (a *App) onTick(now time.Time) tea.Cmd {
	dt := now.Sub(a.lastTick)
	if dt > 250*time.Millisecond {
		dt = 250 * time.Millisecond
	}
	a.lastTick = now
	a.core.Step(now, dt)
	if a.core.cfgGen != a.cfgGen {
		a.reloadModes()
	}

	var cmds []tea.Cmd
	for _, an := range a.core.Announcements() {
		cmds = append(cmds, a.announce(an)...)
	}
	for _, id := range a.order {
		if bg, ok := a.ids[id].(Background); ok {
			for _, an := range bg.Step(now, dt) {
				cmds = append(cmds, a.announce(an)...)
			}
		}
	}
	if a.core.bell {
		a.core.bell = false
		cmds = append(cmds, tea.Raw("\a"))
	}
	a.stepToasts(dt)
	a.hdr.sx.Step(dt)
	a.hdr.sw.Step(dt)
	if a.trans != nil {
		a.trans.step(dt)
		if a.trans.done() {
			a.trans = nil
		}
	}
	if a.splash != nil && a.splash.done(now) {
		a.splash = nil
	}
	if a.ring != nil {
		if a.ring.expired(now) {
			a.nextRing()
		} else if now.After(a.nextBell) {
			a.nextBell = now.Add(1400 * time.Millisecond)
			if a.ring.ann.Kind != engine.KindAlarm && a.ring.ann.Kind != engine.KindTimer {
				a.nextBell = now.Add(ringTimeout) // gentle: one chime, not a siren
			}
			cmds = append(cmds, a.ringCue()...)
		}
	}
	if a.page != nil {
		a.page.Frame(dt)
		if p, ok := a.page.(Page); ok && p.Done() {
			a.page = nil
		}
	} else if m := a.mode(); m != nil {
		m.Frame(dt)
	}
	cmds = append(cmds, a.tick())
	return tea.Batch(cmds...)
}

func (a *App) ringCue() []tea.Cmd {
	var cmds []tea.Cmd
	name := notifySound(a.ring)
	if a.core.Sound(name) {
		cmds = append(cmds, tea.Raw("\a"))
	}
	return cmds
}

func notifySound(r *ringer) string {
	if r != nil && r.kind() == "alarm" {
		return notify.SoundAlarm
	}
	return notify.SoundDone
}

// announce reacts to something finishing: toast, notification, sound, effects.
func (a *App) announce(an Announce) []tea.Cmd {
	var cmds []tea.Cmd
	pal := a.core.Pal
	col := pal.Accent
	if an.Rest {
		col = pal.Rest
	}
	if an.Kind == "timer" {
		col = pal.Rest
	}
	a.pushToast(an.Title, an.Body, col, 6*time.Second)
	if an.Away {
		return nil
	}
	if a.core.Cfg.Notify {
		notify.Send(an.Title, an.Body, an.Ring)
	}
	if an.Ring {
		r := newRinger(an, a.core.Now)
		if a.ring == nil {
			a.ring = r
			a.nextBell = time.Time{}
		} else {
			a.rings = append(a.rings, r)
		}
		return cmds
	}
	if a.core.Sound(notify.SoundDone) {
		cmds = append(cmds, tea.Raw("\a"))
	}
	for _, m := range a.ids {
		if c, ok := m.(Announcer); ok {
			c.Celebrate(an)
		}
	}
	return cmds
}

func (a *App) nextRing() {
	a.ring = nil
	if len(a.rings) > 0 {
		a.ring, a.rings = a.rings[0], a.rings[1:]
		a.nextBell = time.Time{}
	}
}

// ---------------------------------------------------------------- input

var (
	keyNext = key.NewBinding(key.WithKeys("tab", "]", "alt+right"))
	keyPrev = key.NewBinding(key.WithKeys("shift+tab", "[", "alt+left"))
	keyHelp = key.NewBinding(key.WithKeys("?", "f1"))
	keyZen  = key.NewBinding(key.WithKeys("f", "f11"))
	keyQuit = key.NewBinding(key.WithKeys("q", "ctrl+c"))
)

func (a *App) onKey(msg tea.KeyPressMsg) tea.Cmd {
	if msg.String() == "ctrl+c" {
		return a.quit()
	}
	if a.splash != nil {
		a.splash = nil
		return nil
	}
	if a.ring != nil {
		if a.ring.handle(a, msg) {
			a.nextRing()
		}
		return nil
	}
	if a.showHelp {
		if a.manual != nil && a.manual.update(msg) {
			a.showHelp = false
		}
		return nil
	}
	if a.capturing() {
		return a.active().Update(msg)
	}
	if a.page != nil {
		switch {
		case key.Matches(msg, keyHelp):
			a.showHelp = true
			return nil
		case msg.String() == "q" || msg.String() == "esc":
			if pc, ok := a.page.(interface{ Back() bool }); ok && pc.Back() {
				return nil
			}
			a.page = nil
			return nil
		}
		return a.page.Update(msg)
	}
	switch {
	case key.Matches(msg, keyQuit):
		return a.quit()
	case msg.String() == "g" && pageFactories["stats"] != nil:
		a.openPage("stats")
		return nil
	case msg.String() == "," && pageFactories["settings"] != nil:
		a.openPage("settings")
		return nil
	case key.Matches(msg, keyHelp):
		a.showHelp = true
		return nil
	case key.Matches(msg, keyNext):
		a.cycle(1)
		return nil
	case key.Matches(msg, keyPrev):
		a.cycle(-1)
		return nil
	case key.Matches(msg, keyZen):
		a.zen = !a.zen
		return nil
	case msg.String() == "esc" && a.zen:
		a.zen = false
		return nil
	}
	// number keys jump to a mode
	if s := msg.String(); len(s) == 1 && s[0] >= '1' && s[0] <= '9' {
		if i := int(s[0] - '1'); i < len(a.order) {
			a.switchTo(a.order[i])
			return nil
		}
	}
	if m := a.mode(); m != nil {
		return m.Update(msg)
	}
	return nil
}

func (a *App) onMouse(msg tea.MouseMsg) tea.Cmd {
	if !a.core.Cfg.Mouse {
		return nil
	}
	if a.splash != nil {
		a.splash = nil
		return nil
	}
	if a.ring != nil {
		if a.ring.handle(a, msg) {
			a.nextRing()
		}
		return nil
	}
	if a.showHelp {
		if a.manual != nil && a.manual.update(msg) {
			a.showHelp = false
		}
		return nil
	}
	mo := msg.Mouse()
	bodyTop := 2
	if a.zen || a.chromeless() {
		bodyTop = 0
	}
	if click, ok := msg.(tea.MouseClickMsg); ok && click.Button == tea.MouseLeft && mo.Y < 2 && !a.zen && !a.capturing() {
		if id, hit := a.hdr.hit(mo.X); hit {
			a.page = nil
			a.switchTo(id)
		}
		return nil
	}
	if m := a.active(); m != nil && mo.Y >= bodyTop {
		rel := adjustMouse(msg, 0, bodyTop)
		return m.Update(rel)
	}
	return nil
}

func adjustMouse(msg tea.MouseMsg, dx, dy int) tea.Msg {
	switch m := msg.(type) {
	case tea.MouseClickMsg:
		m.X -= dx
		m.Y -= dy
		return m
	case tea.MouseReleaseMsg:
		m.X -= dx
		m.Y -= dy
		return m
	case tea.MouseWheelMsg:
		m.X -= dx
		m.Y -= dy
		return m
	case tea.MouseMotionMsg:
		m.X -= dx
		m.Y -= dy
		return m
	}
	return msg
}

func (a *App) cycle(d int) {
	idx := 0
	for i, id := range a.order {
		if id == a.current {
			idx = i
		}
	}
	a.switchTo(a.order[(idx+d+len(a.order))%len(a.order)])
}

func (a *App) switchTo(id string) {
	a.page = nil
	if id == a.current || a.ids[id] == nil {
		return
	}
	from, to := -1, -1
	for i, o := range a.order {
		if o == a.current {
			from = i
		}
		if o == id {
			to = i
		}
	}
	dir := 1
	if to < from {
		dir = -1
	}
	if a.last != nil && a.core.Cfg.Motion != "still" {
		a.trans = newTransition(a.last, dir)
	}
	a.current = id
}

func (a *App) quit() tea.Cmd {
	a.quitting = true
	a.core.LastMode = a.current
	a.core.Save()
	if a.opts.OnQuit != nil {
		a.opts.OnQuit(a.core)
	}
	return tea.Quit
}

// ---------------------------------------------------------------- view

const minW, minH = 24, 7

func (a *App) View() tea.View {
	var content string
	switch {
	case a.w == 0 || a.h == 0:
		content = ""
	case a.w < minW || a.h < minH:
		content = centerTinyMessage(a)
	default:
		content = a.compose()
	}
	v := tea.NewView(content)
	v.AltScreen = true
	if a.core.Cfg.Mouse {
		v.MouseMode = tea.MouseModeCellMotion
	}
	v.ReportFocus = true
	v.WindowTitle = a.title()
	if p := a.core.Pomo; p.Active() && a.core.Cfg.Notify {
		state := tea.ProgressBarDefault
		if p.Run == engine.Paused {
			state = tea.ProgressBarWarning
		}
		v.ProgressBar = tea.NewProgressBar(state, int(p.Progress(a.core.Now)*100))
	}
	return v
}

func (a *App) title() string {
	if t, ok := a.active().(Titled); ok {
		if s := t.Title(); s != "" {
			return s + " — enfo"
		}
	}
	return "enfo"
}

func centerTinyMessage(a *App) string {
	msg := i18n.T("too.small")
	if width(msg) > a.w {
		msg = i18n.T("too.small.short")
	}
	lines := blank(a.w, a.h)
	if a.h > 0 {
		lines[a.h/2] = centerIn(ansi.Truncate(msg, a.w, ""), a.w)
	}
	return join(lines)
}

func (a *App) compose() string {
	w, h := a.w, a.h
	pal := a.core.Pal

	if a.splash != nil {
		return join(fit(a.splash.View(a, w, h), w, h))
	}
	if a.ring != nil {
		base := a.ring.View(a, w, h)
		return a.withOverlays(join(fit(base, w, h)))
	}

	headerH, footerH := 2, 1
	if a.zen || a.chromeless() {
		headerH, footerH = 0, 0
	}
	bodyH := h - headerH - footerH
	body := a.renderBody(w, bodyH)
	a.last = body

	var lines []string
	bare := a.zen || a.chromeless()
	if !bare {
		lines = append(lines, a.hdr.View(a, w)...)
	}
	lines = append(lines, body...)
	if !bare {
		lines = append(lines, a.footer(w))
	}
	_ = pal
	return a.withOverlays(join(fit(lines, w, h)))
}

func (a *App) renderBody(w, h int) []string {
	m := a.active()
	if m == nil {
		return blank(w, h)
	}
	cur := fit(splitLines(m.View(w, h)), w, h)
	if a.trans != nil {
		return a.trans.compose(cur, w)
	}
	return cur
}

func splitLines(s string) []string {
	var out []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			out = append(out, s[start:i])
			start = i + 1
		}
	}
	return append(out, s[start:])
}

// withOverlays layers toasts and the help panel over the screen.
func (a *App) withOverlays(base string) string {
	layers := a.toastLayers(a.w)
	if a.showHelp {
		if a.manual == nil {
			a.manual = newHelp()
		}
		layers = append(layers, a.manual.layer(a, a.w, a.h))
	}
	if len(layers) == 0 {
		return base
	}
	all := append([]*lipgloss.Layer{lipgloss.NewLayer(base).Z(0)}, layers...)
	return lipgloss.NewCompositor(all...).Render()
}

// footer is the key help on the left and the running timers on the right.
func (a *App) footer(w int) string {
	pal := a.core.Pal
	var chips []string
	for _, r := range a.runners() {
		if r.Mode == a.current && a.page == nil {
			continue
		}
		col := pal.Accent
		if r.Rest {
			col = pal.Rest
		}
		if r.Paused {
			col = pal.Muted
		}
		chips = append(chips, paint(col, r.Icon+" ")+paint(pal.Text, r.Text))
	}
	right := ""
	for i, c := range chips {
		if i > 0 {
			right += paint(pal.Faint, "  ·  ")
		}
		right += c
	}
	rw := width(right)
	left := ""
	if m := a.active(); m != nil {
		binds := append([]key.Binding{}, m.Help()...)
		if !a.capturing() {
			binds = append(binds,
				key.NewBinding(key.WithKeys("?"), key.WithHelp("?", i18n.T("key.help"))),
				key.NewBinding(key.WithKeys("q"), key.WithHelp("q", i18n.T("key.quit"))),
			)
		}
		avail := w - 2
		if rw > 0 {
			avail -= rw + 2
		}
		a.help.SetWidth(avail)
		left = a.help.ShortHelpView(binds)
	}
	line := " " + padRight(left, w-2-rw) + right + " "
	if rw == 0 {
		line = " " + padRight(left, w-1)
	}
	return padRight(line, w)
}

// ---------------------------------------------------------------- transition

type transition struct {
	old []string
	dir int
	sp  *anim.Spring
}

func newTransition(old []string, dir int) *transition {
	t := &transition{old: old, dir: dir, sp: anim.NewSpring(0, 5.5, 1)}
	t.sp.Target = 1
	return t
}

func (t *transition) step(dt time.Duration) { t.sp.Step(dt) }

func (t *transition) done() bool { return t.sp.Pos > 0.995 && t.sp.Settled() || t.sp.Pos > 0.999 }

// compose slides between the old frame and the new one.
func (t *transition) compose(cur []string, w int) []string {
	p := anim.Clamp01(t.sp.Pos)
	off := int(p*float64(w) + 0.5)
	out := make([]string, len(cur))
	for i := range cur {
		o := ""
		if i < len(t.old) {
			o = padRight(t.old[i], w)
		} else {
			o = spaces(w)
		}
		n := padRight(cur[i], w)
		if t.dir > 0 {
			out[i] = ansi.Cut(o, off, w) + ansi.Cut(n, 0, off)
		} else {
			out[i] = ansi.Cut(n, w-off, w) + ansi.Cut(o, 0, w-off)
		}
	}
	return out
}
