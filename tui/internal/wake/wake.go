// Package wake keeps Enfo's promise after the terminal is closed: a tiny
// detached process (`enfo wake`) sleeps until an instant and then raises the
// desktop notification and the sound. The TUI hands running timers, Pomodoro
// phases and alarms to wakers when it quits, and kills them when it starts
// again (it rings them itself while it is open).
package wake

import (
	"context"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/notify"
)

// Job is what a waker does when its time comes.
type Job struct {
	At     time.Time
	Title  string
	Body   string
	Sound  string // notify.SoundDone, SoundAlarm ... ("" = none)
	Repeat int    // how many times the sound is played (default 1)
	Urgent bool
}

// Run sleeps until the job's instant (re-checking the wall clock so a laptop
// suspend does not make it late) and fires it.
// A cancelled context (SIGTERM from Cancel) ends it without firing.
func Run(ctx context.Context, j Job) {
	for {
		left := time.Until(j.At)
		if left <= 0 {
			break
		}
		if left > 5*time.Second {
			left = 5 * time.Second
		}
		select {
		case <-ctx.Done():
			return
		case <-time.After(left):
		}
	}
	notify.Send(j.Title, j.Body, j.Urgent)
	n := j.Repeat
	if n < 1 {
		n = 1
	}
	for i := 0; i < n && j.Sound != ""; i++ {
		if !notify.Play(j.Sound) {
			break
		}
		time.Sleep(1800 * time.Millisecond)
	}
	// notify.Send/Play run in goroutines: give them a moment to start
	time.Sleep(400 * time.Millisecond)
}

// Args renders the job as the argument list of `enfo wake`.
func (j Job) Args() []string {
	a := []string{"wake", "--at", strconv.FormatInt(j.At.Unix(), 10), "--title", j.Title, "--body", j.Body}
	if j.Sound != "" {
		a = append(a, "--sound", j.Sound)
	}
	if j.Repeat > 1 {
		a = append(a, "--repeat", strconv.Itoa(j.Repeat))
	}
	if j.Urgent {
		a = append(a, "--urgent")
	}
	return a
}

// Spawn starts a detached waker for the job and returns its PID. It does
// nothing (PID 0) when notifications are disabled or a waker for the same
// instant is already running.
func Spawn(exe string, j Job) (int, error) {
	if notify.Disabled {
		return 0, nil
	}
	if pid := find(j.At); pid > 0 {
		return pid, nil // already waiting for that instant: share it
	}
	if exe == "" {
		var err error
		if exe, err = os.Executable(); err != nil {
			return 0, err
		}
	}
	cmd := exec.Command(exe, j.Args()...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = nil, nil, nil
	detach(cmd)
	if err := cmd.Start(); err != nil {
		return 0, err
	}
	pid := cmd.Process.Pid
	_ = cmd.Process.Release()
	return pid, nil
}

// Cancel stops the wakers with the given PIDs. A PID is only signalled when it
// really is an `enfo wake` process (PIDs get reused).
func Cancel(pids []int) {
	for _, pid := range pids {
		if pid > 1 && isWaker(pid) {
			terminate(pid)
		}
	}
}

// Exists reports whether a waker for that instant is running.
func Exists(at time.Time) bool { return find(at) > 0 }

// Alive reports whether pid is a running `enfo wake` process.
func Alive(pid int) bool { return pid > 1 && isWaker(pid) }

func find(at time.Time) int {
	want := strconv.FormatInt(at.Unix(), 10)
	for _, w := range running() {
		for i, a := range w.args {
			if a == "--at" && i+1 < len(w.args) && w.args[i+1] == want {
				return w.pid
			}
		}
	}
	return 0
}

type proc struct {
	pid  int
	args []string
}

// running lists the `enfo wake` processes (Linux: /proc; elsewhere: none).
func running() []proc {
	ents, err := os.ReadDir("/proc")
	if err != nil {
		return nil
	}
	var out []proc
	for _, e := range ents {
		pid, err := strconv.Atoi(e.Name())
		if err != nil {
			continue
		}
		if args, ok := cmdline(pid); ok && isWakeArgs(args) {
			out = append(out, proc{pid, args})
		}
	}
	return out
}

func cmdline(pid int) ([]string, bool) {
	b, err := os.ReadFile("/proc/" + strconv.Itoa(pid) + "/cmdline")
	if err != nil || len(b) == 0 {
		return nil, false
	}
	return strings.Split(strings.TrimRight(string(b), "\x00"), "\x00"), true
}

// isWakeArgs: argv looks like `<...>enfo wake --at N ...`.
func isWakeArgs(args []string) bool {
	if len(args) < 2 {
		return false
	}
	return strings.Contains(args[0], "enfo") && args[1] == "wake"
}

func isWaker(pid int) bool {
	args, ok := cmdline(pid)
	return ok && isWakeArgs(args)
}
