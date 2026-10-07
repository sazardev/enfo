//go:build !unix

package wake

import "os/exec"

func detach(cmd *exec.Cmd) {}

func terminate(pid int) {}
