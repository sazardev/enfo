package cli

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"charm.land/lipgloss/v2"
	"github.com/sazardev/enfo/tui/internal/braille"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/theme"
	"github.com/spf13/cobra"
)

type level int

const (
	lvlOK level = iota
	lvlWarn
	lvlFail
	lvlInfo
)

type check struct {
	name   string
	level  level
	detail string
	fix    string
}

func newDoctorCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "doctor",
		Short: "Check the terminal and the desktop integration",
		Long: `Runs a checklist: terminal size and colors, braille rendering, desktop
notifications, a sound player and sounds, the detected time zone and that
Enfo's files are readable and writable. Every problem comes with a fix for your
distribution (CachyOS/Arch, Ubuntu/Debian, Fedora).`,
		Example: "  enfo doctor",
		Args:    cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			checks := runChecks()
			lipgloss.Fprintln(cmd.OutOrStdout(), renderChecks(checks))
			for _, c := range checks {
				if c.level == lvlFail {
					return fmt.Errorf("some checks failed")
				}
			}
			return nil
		},
	}
}

type distro int

const (
	distroOther distro = iota
	distroArch
	distroDebian
	distroFedora
)

func detectDistro() distro {
	b, err := os.ReadFile("/etc/os-release")
	if err != nil {
		return distroOther
	}
	return distroFrom(string(b))
}

func distroFrom(osRelease string) distro {
	s := strings.ToLower(osRelease)
	has := func(words ...string) bool {
		for _, l := range strings.Split(s, "\n") {
			if !strings.HasPrefix(l, "id=") && !strings.HasPrefix(l, "id_like=") {
				continue
			}
			for _, w := range words {
				if strings.Contains(l, w) {
					return true
				}
			}
		}
		return false
	}
	switch {
	case has("arch", "cachyos", "endeavouros", "manjaro", "omarchy"):
		return distroArch
	case has("debian", "ubuntu", "mint", "pop"):
		return distroDebian
	case has("fedora", "rhel", "centos"):
		return distroFedora
	}
	return distroOther
}

func installHint(d distro, arch, deb, fed string) string {
	switch d {
	case distroArch:
		return "sudo pacman -S " + arch
	case distroDebian:
		return "sudo apt install " + deb
	case distroFedora:
		return "sudo dnf install " + fed
	}
	return "install " + arch + " (Arch) / " + deb + " (Debian, Ubuntu) / " + fed + " (Fedora)"
}

func runChecks() []check {
	d := detectDistro()
	var out []check

	// terminal
	if w, h, ok := termSizeFull(); ok {
		l := lvlOK
		det := fmt.Sprintf("%d×%d cells", w, h)
		var fix string
		if w < 80 || h < 24 {
			l, fix = lvlWarn, "Enfo works from 24×7 but looks best at 100×30 or more"
		}
		out = append(out, check{"terminal size", l, det, fix})
	} else {
		out = append(out, check{"terminal size", lvlInfo, "stdout is not a terminal", ""})
	}
	term, ct := os.Getenv("TERM"), os.Getenv("COLORTERM")
	switch {
	case ct == "truecolor" || ct == "24bit":
		out = append(out, check{"colors", lvlOK, "truecolor (" + term + ")", ""})
	case strings.Contains(term, "256color") || strings.Contains(term, "kitty") || strings.Contains(term, "ghostty") || strings.Contains(term, "alacritty"):
		out = append(out, check{"colors", lvlWarn, "256 colors (" + term + "); gradients will be coarser", "export COLORTERM=truecolor in your shell profile if your terminal supports it"})
	default:
		out = append(out, check{"colors", lvlFail, "TERM=" + term + " has no color support to speak of", "use a modern terminal (kitty, ghostty, alacritty, foot, wezterm, gnome-terminal) and TERM=xterm-256color"})
	}
	if strings.Contains(strings.ToLower(os.Getenv("LC_ALL")+os.Getenv("LANG")+os.Getenv("LC_CTYPE")), "utf") {
		out = append(out, check{"unicode", lvlOK, "UTF-8 locale", ""})
	} else {
		out = append(out, check{"unicode", lvlWarn, "no UTF-8 locale detected (LANG=" + os.Getenv("LANG") + ")", "export LANG=en_US.UTF-8 (or es_MX.UTF-8, C.UTF-8)"})
	}
	sample := paintHex(braille.Hex("cddc39"), "⣿⣷⣯⣟⡿⢿⣻⣽⣾⣶⣤⣀") + "  " + paintHex(braille.Hex("8b8b96"), "← continuous dots? if you see boxes or gaps, install a font with braille (Noto Sans Symbols 2, DejaVu Sans Mono, a Nerd Font)")
	out = append(out, check{"braille font", lvlInfo, sample, ""})

	// notifications and sound
	if p, err := exec.LookPath("notify-send"); err == nil {
		out = append(out, check{"notifications", lvlOK, p, ""})
	} else {
		out = append(out, check{"notifications", lvlWarn, "notify-send not found: no desktop popups when a phase ends", installHint(d, "libnotify", "libnotify-bin", "libnotify")})
	}
	if os.Getenv("WAYLAND_DISPLAY") == "" && os.Getenv("DISPLAY") == "" {
		out = append(out, check{"display", lvlInfo, "no graphical session detected (SSH or a console): notifications need one", ""})
	}
	player := ""
	for _, p := range []string{"pw-play", "paplay", "aplay", "play"} {
		if path, err := exec.LookPath(p); err == nil {
			player = path
			break
		}
	}
	if player != "" {
		out = append(out, check{"sound player", lvlOK, player, ""})
	} else {
		out = append(out, check{"sound player", lvlWarn, "no pw-play / paplay / aplay: Enfo falls back to the terminal bell", installHint(d, "libpulse", "pulseaudio-utils", "pulseaudio-utils")})
	}
	if f := findSound(); f != "" {
		out = append(out, check{"sounds", lvlOK, filepath.Dir(f), ""})
	} else {
		out = append(out, check{"sounds", lvlWarn, "freedesktop sound theme not found", installHint(d, "sound-theme-freedesktop", "sound-theme-freedesktop", "sound-theme-freedesktop")})
	}

	// time zone
	if c, ok := engine.LocalCity(); ok {
		out = append(out, check{"time zone", lvlOK, engine.LocalZoneName() + " → " + c.EN, ""})
	} else if z := engine.LocalZoneName(); z != "" {
		out = append(out, check{"time zone", lvlOK, z + " (not in Enfo's city list; the world clock works anyway)", ""})
	} else {
		out = append(out, check{"time zone", lvlWarn, "could not tell the zone name (using " + time.Now().Location().String() + ")", "timedatectl set-timezone America/Mexico_City (or your zone)"})
	}

	// files
	st, err := store.Open()
	if err != nil {
		return append(out, check{"data directories", lvlFail, err.Error(), "check permissions of $XDG_CONFIG_HOME and $XDG_STATE_HOME"})
	}
	for _, e := range []struct{ name, dir string }{{"config directory", st.ConfigDir}, {"state directory", st.StateDir}} {
		probe := filepath.Join(e.dir, ".doctor")
		if err := os.WriteFile(probe, []byte("ok"), 0o644); err != nil {
			out = append(out, check{e.name, lvlFail, e.dir + ": " + err.Error(), "chmod u+w " + e.dir})
			continue
		}
		os.Remove(probe)
		out = append(out, check{e.name, lvlOK, e.dir + " (writable)", ""})
	}
	out = append(out, jsonCheck("config.json", st.ConfigPath(), func(b []byte) error { var v store.Config; return json.Unmarshal(b, &v) }, "enfo config reset"))
	out = append(out, jsonCheck("state.json", st.StatePath(), func(b []byte) error { var v store.State; return json.Unmarshal(b, &v) }, "enfo config reset --all"))
	n := len(st.Events())
	out = append(out, check{"history", lvlOK, fmt.Sprintf("%d events", n), ""})
	return out
}

func jsonCheck(name, path string, parse func([]byte) error, fix string) check {
	b, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return check{name, lvlInfo, "not created yet (defaults in use)", ""}
		}
		return check{name, lvlFail, err.Error(), "chmod u+r " + path}
	}
	if err := parse(b); err != nil {
		return check{name, lvlFail, "does not parse: " + err.Error(), fix}
	}
	return check{name, lvlOK, path, ""}
}

func findSound() string {
	for _, d := range []string{"/usr/share/sounds/freedesktop/stereo", "/usr/share/sounds/ocean/stereo", "/usr/share/sounds/Yaru/stereo"} {
		for _, n := range []string{"complete.oga", "complete.ogg", "complete.wav"} {
			if _, err := os.Stat(filepath.Join(d, n)); err == nil {
				return filepath.Join(d, n)
			}
		}
	}
	return ""
}

func renderChecks(cs []check) string {
	pal := theme.New(theme.Resolve("lime"), braille.Hex("16141a"), true)
	icon := map[level]string{
		lvlOK:   lipgloss.NewStyle().Foreground(pal.Good).Render("✓"),
		lvlWarn: lipgloss.NewStyle().Foreground(pal.Warn).Render("!"),
		lvlFail: lipgloss.NewStyle().Foreground(pal.Bad).Render("✗"),
		lvlInfo: lipgloss.NewStyle().Foreground(pal.Muted).Render("•"),
	}
	name := lipgloss.NewStyle().Foreground(pal.Text).Bold(true).Width(18)
	muted := lipgloss.NewStyle().Foreground(pal.Muted)
	fixSt := lipgloss.NewStyle().Foreground(pal.Accent)
	var sb strings.Builder
	sb.WriteString(lipgloss.NewStyle().Foreground(pal.Accent).Bold(true).Render("◔ enfo doctor") + "\n\n")
	warn, fail := 0, 0
	for _, c := range cs {
		sb.WriteString(" " + icon[c.level] + " " + name.Render(c.name) + muted.Render(c.detail) + "\n")
		if c.fix != "" {
			sb.WriteString("     " + strings.Repeat(" ", 18) + fixSt.Render("→ "+c.fix) + "\n")
		}
		switch c.level {
		case lvlWarn:
			warn++
		case lvlFail:
			fail++
		}
	}
	sb.WriteString("\n")
	switch {
	case fail > 0:
		sb.WriteString(lipgloss.NewStyle().Foreground(pal.Bad).Render(fmt.Sprintf(" %d problem(s) to fix", fail)))
	case warn > 0:
		sb.WriteString(lipgloss.NewStyle().Foreground(pal.Warn).Render(fmt.Sprintf(" works, with %d thing(s) worth improving", warn)))
	default:
		sb.WriteString(lipgloss.NewStyle().Foreground(pal.Good).Render(" all good — enjoy the focus"))
	}
	return sb.String()
}
