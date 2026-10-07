// Command enfo is the Enfo terminal app: a Pomodoro, clock, timer, stopwatch,
// alarms, world clock and breathing guide drawn in braille.
package main

import (
	"os"
	"runtime/debug"

	"github.com/sazardev/enfo/tui/internal/cli"
)

// Set at build time: -ldflags "-X main.version=1.0.0 -X main.commit=abc123".
var (
	version = "dev"
	commit  = ""
)

func main() {
	if commit == "" {
		if bi, ok := debug.ReadBuildInfo(); ok {
			for _, s := range bi.Settings {
				if s.Key == "vcs.revision" && len(s.Value) >= 7 {
					commit = s.Value[:7]
				}
			}
		}
	}
	if err := cli.Execute(version, commit); err != nil {
		os.Exit(1)
	}
}
