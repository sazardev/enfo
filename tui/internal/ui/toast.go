package ui

import (
	"time"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/anim"
	"github.com/sazardev/enfo/tui/internal/braille"
)

type toast struct {
	title, body string
	color       braille.RGB
	born        time.Time
	life        time.Duration
	slide       *anim.Spring // 1 = off-screen, 0 = in place
}

const toastLife = 4 * time.Second

func (a *App) pushToast(title, body string, col braille.RGB, life time.Duration) {
	t := &toast{title: title, body: body, color: col, born: a.core.Now, life: life, slide: anim.NewSpring(1, 8, 0.7)}
	t.slide.Target = 0
	a.toasts = append(a.toasts, t)
	if len(a.toasts) > 3 {
		a.toasts = a.toasts[len(a.toasts)-3:]
	}
}

// Say shows a one-line toast.
func (a *App) say(text string) {
	a.pushToast(text, "", a.core.Pal.Accent, 2200*time.Millisecond)
}

func (a *App) stepToasts(dt time.Duration) {
	live := a.toasts[:0]
	for _, t := range a.toasts {
		age := a.core.Now.Sub(t.born)
		if age > t.life {
			t.slide.Target = 1
			if t.slide.Pos > 0.98 {
				continue
			}
		}
		t.slide.Step(dt)
		live = append(live, t)
	}
	a.toasts = live
}

// render returns the layers (content, x, y) of the toast stack.
func (a *App) toastLayers(w int) []*lipgloss.Layer {
	var layers []*lipgloss.Layer
	y := 2
	for _, t := range a.toasts {
		st := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(t.color).
			Padding(0, 1).
			Foreground(a.core.Pal.Text)
		text := lipgloss.NewStyle().Bold(true).Foreground(t.color).Render(t.title)
		if t.body != "" {
			text += "\n" + lipgloss.NewStyle().Foreground(a.core.Pal.Muted).Render(t.body)
		}
		box := st.Render(text)
		bw, bh := lipgloss.Width(box), lipgloss.Height(box)
		x := w - bw - 1 + int(t.slide.Pos*float64(bw+2))
		layers = append(layers, lipgloss.NewLayer(box).X(x).Y(y).Z(5))
		y += bh
	}
	return layers
}
