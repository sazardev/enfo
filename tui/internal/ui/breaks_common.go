package ui

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	"charm.land/bubbles/v2/textinput"
	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
)

// breaksLoadJSON reads path into v; a missing or broken file leaves v alone and
// reports false.
func breaksLoadJSON(path string, v any) bool {
	b, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	return json.Unmarshal(b, v) == nil
}

// breaksSaveJSON writes v atomically (temp file + rename).
func breaksSaveJSON(path string, v any) {
	b, err := json.Marshal(v)
	if err != nil {
		return
	}
	_ = os.MkdirAll(filepath.Dir(path), 0o755)
	tmp := path + ".tmp"
	if os.WriteFile(tmp, b, 0o644) == nil {
		_ = os.Rename(tmp, path)
	}
}

// breaksInput builds a text field in the app's colors. The cursor does not
// blink (blink messages never reach a mode), it is a steady block.
func breaksInput(c *Core, placeholder string, limit, width int) textinput.Model {
	ti := textinput.New()
	ti.Prompt = ""
	ti.Placeholder = placeholder
	ti.CharLimit = limit
	ti.SetWidth(width)
	pal := c.Pal
	st := ti.Styles()
	st.Focused.Text = lipgloss.NewStyle().Foreground(pal.Text)
	st.Focused.Placeholder = lipgloss.NewStyle().Foreground(pal.Faint)
	st.Blurred.Text = lipgloss.NewStyle().Foreground(pal.Muted)
	st.Blurred.Placeholder = lipgloss.NewStyle().Foreground(pal.Faint)
	st.Cursor.Color = pal.Accent
	st.Cursor.Blink = false
	ti.SetStyles(st)
	return ti
}

// breaksFmtLeft formats a countdown: "now", "45s", "12:03" or "1h 05m".
func breaksFmtLeft(d time.Duration) string {
	if d <= 0 {
		return "00:00"
	}
	s := ceilSecs(d)
	switch {
	case s >= 3600:
		return itoa(s/3600) + "h " + breaksPad2(s%3600/60) + "m"
	default:
		return breaksPad2(s/60) + ":" + breaksPad2(s%60)
	}
}

func breaksPad2(n int) string {
	if n < 10 {
		return "0" + itoa(n)
	}
	return itoa(n)
}

// breaksHue is the n-th color of the app's hue wheel for the palette.
func breaksHue(pal braille.RGB, n int) braille.RGB {
	return pal.Shift(float64(n) * 47)
}
