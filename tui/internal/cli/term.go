package cli

import (
	"os"

	"github.com/charmbracelet/x/term"
)

// termSize returns the width of the terminal on stdout (0 when not a tty).
func termSize() int {
	w, _, err := term.GetSize(os.Stdout.Fd())
	if err != nil {
		return 0
	}
	return w
}

func termSizeFull() (w, h int, ok bool) {
	w, h, err := term.GetSize(os.Stdout.Fd())
	return w, h, err == nil
}
