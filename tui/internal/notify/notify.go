// Package notify tells the outside world something happened: a desktop
// notification (notify-send, which every Linux desktop answers to) and a sound
// (a freedesktop theme sound through paplay/pw-play/aplay, or nothing).
package notify

import (
	"os"
	"os/exec"
	"path/filepath"
	"sync"
)

// Disabled turns every side effect off (tests, ENFO_QUIET=1).
var Disabled = os.Getenv("ENFO_QUIET") != ""

// Send posts a desktop notification, asynchronously. Errors are ignored: a
// machine without a notification daemon simply gets no popup.
func Send(title, body string, urgent bool) {
	if Disabled {
		return
	}
	path, err := exec.LookPath("notify-send")
	if err != nil {
		return
	}
	args := []string{"-a", "Enfo", "-i", "alarm-clock", "-h", "string:desktop-entry:enfo"}
	if urgent {
		args = append(args, "-u", "critical")
	}
	args = append(args, title, body)
	go func() { _ = exec.Command(path, args...).Run() }()
}

// Sound names.
const (
	SoundDone  = "complete"
	SoundAlarm = "alarm-clock-elapsed"
	SoundStart = "message"
)

var (
	player     string
	playerArgs []string
	once       sync.Once
	soundDirs  = []string{
		"/usr/share/sounds/freedesktop/stereo",
		"/usr/share/sounds/ocean/stereo",
		"/usr/share/sounds/Yaru/stereo",
		"/usr/share/sounds/gnome/default/alerts",
	}
)

func findPlayer() {
	for _, p := range [][]string{{"pw-play"}, {"paplay"}, {"aplay", "-q"}, {"play", "-q"}} {
		if path, err := exec.LookPath(p[0]); err == nil {
			player, playerArgs = path, p[1:]
			return
		}
	}
}

func soundFile(name string) string {
	for _, d := range soundDirs {
		for _, ext := range []string{".oga", ".ogg", ".wav"} {
			f := filepath.Join(d, name+ext)
			if _, err := os.Stat(f); err == nil {
				return f
			}
		}
	}
	return ""
}

// Play plays a theme sound by name. It reports whether it could; callers fall
// back to the terminal bell when it could not.
func Play(name string) bool {
	if Disabled {
		return true
	}
	once.Do(findPlayer)
	if player == "" {
		return false
	}
	f := soundFile(name)
	if f == "" {
		return false
	}
	go func() { _ = exec.Command(player, append(append([]string{}, playerArgs...), f)...).Run() }()
	return true
}
