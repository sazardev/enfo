package wake

import (
	"testing"
	"time"
)

func TestArgsRoundTrip(t *testing.T) {
	j := Job{At: time.Unix(1800000000, 0), Title: "Focus complete", Body: "Time for a 5m break", Sound: "complete", Repeat: 3, Urgent: true}
	a := j.Args()
	if a[0] != "wake" || a[1] != "--at" || a[2] != "1800000000" {
		t.Fatalf("args: %v", a)
	}
	want := map[string]bool{"--sound": false, "--repeat": false, "--urgent": false}
	for _, x := range a {
		if _, ok := want[x]; ok {
			want[x] = true
		}
	}
	for k, v := range want {
		if !v {
			t.Errorf("missing %s in %v", k, a)
		}
	}
}

func TestIsWakeArgs(t *testing.T) {
	if !isWakeArgs([]string{"/usr/bin/enfo", "wake", "--at", "1"}) {
		t.Fatal("should match")
	}
	if isWakeArgs([]string{"/usr/bin/enfo", "status"}) || isWakeArgs([]string{"sleep", "wake"}) {
		t.Fatal("false positive")
	}
}
