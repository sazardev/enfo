//go:build unix

package wake

import (
	"os/exec"
	"syscall"
)

// detach puts the child in its own session so closing the terminal (SIGHUP)
// does not reach it.
func detach(cmd *exec.Cmd) { cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true} }

func terminate(pid int) { _ = syscall.Kill(pid, syscall.SIGTERM) }
