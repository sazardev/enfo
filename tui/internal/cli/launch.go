package cli

import (
	"fmt"
	"os"
	"time"

	tea "charm.land/bubbletea/v2"
	"charm.land/log/v2"
	"github.com/charmbracelet/colorprofile"
	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
	"github.com/sazardev/enfo/tui/internal/notify"
	"github.com/sazardev/enfo/tui/internal/store"
	"github.com/sazardev/enfo/tui/internal/ui"
	"github.com/sazardev/enfo/tui/internal/wake"
)

// launchOpts is everything a command can ask of the TUI before it opens.
type launchOpts struct {
	mode     string
	noSplash bool
	accent   string
	lang     string
	setup    []func(*ui.Core) // command-specific actions (start a timer ...)
}

// openStore opens the on-disk store (honouring --config-dir / --state-dir,
// which were exported as the ENFO_* environment by the root command).
func openStore() (*store.Store, error) {
	st, err := store.Open()
	if err != nil {
		return nil, fmt.Errorf("can't open Enfo's data directories: %w", err)
	}
	return st, nil
}

// launch runs the TUI.
func launch(lo launchOpts) error {
	st, err := openStore()
	if err != nil {
		return err
	}
	if os.Getenv("ENFO_DEBUG") != "" {
		if f, err := tea.LogToFile(st.LogPath(), "enfo"); err == nil {
			defer f.Close()
			log.SetColorProfile(colorprofile.NoTTY)
			log.SetOutput(f) // tea.LogToFile only redirects the standard logger
			log.SetLevel(log.DebugLevel)
			log.Debug("enfo starting", "mode", lo.mode, "state", st.StateDir)
		}
	}
	opts := ui.Options{
		Mode:     lo.mode,
		NoSplash: lo.noSplash,
		Setup: func(c *ui.Core) {
			cancelStaleWakers(c)
			if lo.accent != "" || lo.lang != "" {
				if lo.accent != "" {
					c.Cfg.Accent = lo.accent
				}
				if lo.lang != "" {
					c.Cfg.Lang = lo.lang
				}
				c.ApplyConfig()
				i18n.Set(c.Cfg.Lang)
			}
			for _, f := range lo.setup {
				f(c)
			}
		},
		OnQuit: handOverToWakers,
	}
	p := tea.NewProgram(ui.New(st, opts))
	if _, err := p.Run(); err != nil {
		return fmt.Errorf("enfo: %w", err)
	}
	return nil
}

// cancelStaleWakers kills the background wakers a previous run left behind:
// while Enfo is open it rings by itself.
func cancelStaleWakers(c *ui.Core) {
	s := c.Store.LoadState()
	if len(s.WakerPIDs) > 0 {
		wake.Cancel(s.WakerPIDs)
		log.Debug("cancelled stale wakers", "pids", s.WakerPIDs)
	}
}

// wakeJobs lists what must still ring after the TUI is gone: the running
// Pomodoro phase (and, with auto-next, the phases chained after it), a running
// timer, and the alarms due within a day.
func wakeJobs(c *ui.Core, now time.Time) []wake.Job {
	var jobs []wake.Job
	if p := c.Pomo; p.Run == engine.Running && p.EndsAt.After(now) {
		cp := *p
		for i := 0; i < 4 && cp.Run == engine.Running; i++ {
			end := cp.EndsAt
			var title, body string
			switch cp.Phase {
			case engine.Focus:
				title = i18n.T("done.focus")
			default:
				title = i18n.T("done.rest")
				body = i18n.T("done.rest.body")
			}
			next := nextPhase(&cp)
			if cp.Phase == engine.Focus {
				if next == engine.Long {
					body = i18n.T("done.focus.long", fmtDur(cp.Cfg.Long))
				} else {
					body = i18n.T("done.focus.rest", fmtDur(cp.Cfg.Rest))
				}
			}
			jobs = append(jobs, wake.Job{At: end, Title: title, Body: body, Sound: notify.SoundDone})
			if !cp.Cfg.AutoNext {
				break
			}
			cp.Tick(end.Add(time.Millisecond)) // advance to the chained phase
		}
	}
	if t := c.Timer; t.Run == engine.Running && t.EndsAt.After(now) {
		body := fmtDur(t.Total)
		if t.Label != "" {
			body = t.Label + " · " + body
		}
		jobs = append(jobs, wake.Job{At: t.EndsAt, Title: i18n.T("done.timer"), Body: body, Sound: notify.SoundAlarm, Repeat: 3, Urgent: true})
	}
	for _, a := range c.Alarms.List {
		for _, at := range []time.Time{a.NextAt, a.SnoozeAt} {
			if at.IsZero() || !at.After(now) || at.Sub(now) > 24*time.Hour || (at == a.NextAt && !a.Enabled) {
				continue
			}
			title := a.Label
			if title == "" {
				title = i18n.T("alarm.default")
			}
			jobs = append(jobs, wake.Job{At: at, Title: title, Body: fmt.Sprintf("%02d:%02d", a.Hour, a.Min), Sound: notify.SoundAlarm, Repeat: 4, Urgent: true})
		}
	}
	return jobs
}

// nextPhase mirrors engine's phase order (the engine keeps it private).
func nextPhase(p *engine.Pomodoro) engine.Phase {
	if p.Phase == engine.Focus {
		if p.Cfg.Cycles > 0 && p.Done+1 >= p.Cfg.Cycles {
			return engine.Long
		}
		return engine.Rest
	}
	return engine.Focus
}

// handOverToWakers runs when the TUI quits: it spawns detached wakers for
// everything still pending and records their PIDs in the state file.
func handOverToWakers(c *ui.Core) { handOver(c, nil) }

// handOver spawns the wakers and records their PIDs, keeping the still-running
// ones from prev.
func handOver(c *ui.Core, prev []int) {
	if notify.Disabled || !c.Cfg.Notify {
		return
	}
	now := time.Now()
	var pids []int
	for _, p := range prev {
		if wake.Alive(p) {
			pids = append(pids, p)
		}
	}
	for _, j := range wakeJobs(c, now) {
		pid, err := wake.Spawn("", j)
		if err != nil {
			log.Error("spawn waker", "err", err)
			continue
		}
		if pid > 0 && !containsInt(pids, pid) {
			pids = append(pids, pid)
		}
	}
	if len(pids) == 0 {
		return
	}
	s := c.Store.LoadState()
	s.WakerPIDs = pids
	_ = c.Store.SaveState(s)
}

func fmtDur(d time.Duration) string {
	s := int(d.Round(time.Second) / time.Second)
	h, m, sec := s/3600, s%3600/60, s%60
	switch {
	case h > 0 && m > 0:
		return fmt.Sprintf("%dh %02dm", h, m)
	case h > 0:
		return fmt.Sprintf("%dh", h)
	case m > 0 && sec > 0:
		return fmt.Sprintf("%dm %02ds", m, sec)
	case m > 0:
		return fmt.Sprintf("%dm", m)
	}
	return fmt.Sprintf("%ds", sec)
}

func containsInt(l []int, v int) bool {
	for _, x := range l {
		if x == v {
			return true
		}
	}
	return false
}
