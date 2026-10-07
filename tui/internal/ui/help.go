package ui

import (
	"strings"

	"charm.land/bubbles/v2/viewport"
	tea "charm.land/bubbletea/v2"
	"charm.land/glamour/v2"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

// helpOverlay is the full manual: Markdown rendered by Glamour inside a
// scrollable Viewport, in a rounded panel over the current mode.
type helpOverlay struct {
	vp     viewport.Model
	w, h   int
	dark   bool
	loaded bool
}

func newHelp() *helpOverlay { return &helpOverlay{} }

func (hp *helpOverlay) layout(a *App, w, h int) {
	bw := clampi(w-8, 40, 96)
	bh := clampi(h-4, 8, 40)
	if hp.loaded && hp.w == bw && hp.h == bh && hp.dark == a.core.Pal.Dark {
		return
	}
	hp.w, hp.h, hp.dark, hp.loaded = bw, bh, a.core.Pal.Dark, true
	style := "dark"
	if !a.core.Pal.Dark {
		style = "light"
	}
	r, err := glamour.NewTermRenderer(glamour.WithStandardStyle(style), glamour.WithWordWrap(bw-6))
	md := i18n.T("help.md")
	for _, id := range a.order {
		if k := "help.mode." + id; i18n.Has("en", k) {
			md += "\n" + i18n.T(k)
		}
	}
	out := md
	if err == nil {
		if s, e := r.Render(md); e == nil {
			out = s
		}
	}
	hp.vp = viewport.New(viewport.WithWidth(bw-4), viewport.WithHeight(bh-4))
	hp.vp.SetContent(strings.TrimRight(out, "\n"))
}

func (hp *helpOverlay) update(msg tea.Msg) (closed bool) {
	switch m := msg.(type) {
	case tea.KeyPressMsg:
		switch m.String() {
		case "esc", "q", "?", "enter":
			return true
		case "down", "j":
			hp.vp.ScrollDown(1)
		case "up", "k":
			hp.vp.ScrollUp(1)
		case "pgdown", "space", "ctrl+d":
			hp.vp.HalfPageDown()
		case "pgup", "ctrl+u":
			hp.vp.HalfPageUp()
		case "home", "g":
			hp.vp.GotoTop()
		case "end", "G":
			hp.vp.GotoBottom()
		}
	case tea.MouseWheelMsg:
		if m.Button == tea.MouseWheelUp {
			hp.vp.ScrollUp(3)
		} else if m.Button == tea.MouseWheelDown {
			hp.vp.ScrollDown(3)
		}
	case tea.MouseClickMsg:
		return true
	}
	return false
}

func (hp *helpOverlay) layer(a *App, w, h int) *lipgloss.Layer {
	hp.layout(a, w, h)
	pal := a.core.Pal
	pct := int(hp.vp.ScrollPercent() * 100)
	foot := lipgloss.NewStyle().Foreground(pal.Muted).Render("↑↓ scroll · esc " + i18n.T("key.back") + " · " + itoa(pct) + "%")
	title := lipgloss.NewStyle().Bold(true).Foreground(pal.Accent).Render("◔ " + i18n.T("mode.help"))
	box := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(pal.Accent).
		Padding(0, 1).
		Render(title + "\n" + hp.vp.View() + "\n" + foot)
	bw, bh := lipgloss.Width(box), lipgloss.Height(box)
	return lipgloss.NewLayer(box).X((w - bw) / 2).Y((h - bh) / 2).Z(10)
}
