package engine

import (
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

// KitchenTimer is one countdown in the kitchen. Like every engine it stores
// absolute instants, so it stays exact while hidden and after a restart.
type KitchenTimer struct {
	ID     int           `json:"id"`
	Label  string        `json:"label"`
	Total  time.Duration `json:"total"`
	Run    Run           `json:"run"` // idle | running | paused
	EndsAt time.Time     `json:"endsAt,omitempty"`
	Left   time.Duration `json:"left"`
	Start  time.Time     `json:"start,omitempty"`
	Done   bool          `json:"done,omitempty"`
	DoneAt time.Time     `json:"doneAt,omitempty"`
}

// Remaining is the time left at now.
func (t *KitchenTimer) Remaining(now time.Time) time.Duration {
	switch {
	case t.Done:
		return 0
	case t.Run == Running:
		return clampDur(t.EndsAt.Sub(now), 0)
	}
	return t.Left
}

// Progress is the elapsed share, 0..1.
func (t *KitchenTimer) Progress(now time.Time) float64 {
	if t.Done {
		return 1
	}
	if t.Total <= 0 {
		return 0
	}
	return min(max(1-float64(t.Remaining(now))/float64(t.Total), 0), 1)
}

// Kitchen is the set of timers.
type Kitchen struct {
	List   []*KitchenTimer `json:"list"`
	NextID int             `json:"nextId"`
}

// KitchenFinished reports a timer that reached zero.
type KitchenFinished struct {
	Timer KitchenTimer
	Late  bool // it ended while Enfo was closed
}

// Add creates a timer and starts it.
func (k *Kitchen) Add(label string, d time.Duration, now time.Time) *KitchenTimer {
	k.NextID++
	if label == "" {
		label = "#" + strconv.Itoa(k.NextID)
	}
	t := &KitchenTimer{ID: k.NextID, Label: label, Total: d, Left: d, Run: Running, EndsAt: now.Add(d), Start: now}
	k.List = append(k.List, t)
	return t
}

// Get finds a timer by id.
func (k *Kitchen) Get(id int) *KitchenTimer {
	for _, t := range k.List {
		if t.ID == id {
			return t
		}
	}
	return nil
}

// Delete removes a timer.
func (k *Kitchen) Delete(id int) {
	for i, t := range k.List {
		if t.ID == id {
			k.List = append(k.List[:i], k.List[i+1:]...)
			return
		}
	}
}

// Toggle pauses a running timer, resumes a paused one, starts an idle one.
func (k *Kitchen) Toggle(id int, now time.Time) {
	t := k.Get(id)
	if t == nil || t.Done {
		return
	}
	switch t.Run {
	case Running:
		t.Left = clampDur(t.EndsAt.Sub(now), 0)
		t.Run = Paused
	default:
		if t.Left <= 0 {
			return
		}
		if t.Run == Idle {
			t.Start = now
		}
		t.Run, t.EndsAt = Running, now.Add(t.Left)
	}
}

// Reset puts the timer back to its full length, stopped. It reports an event
// when a run in progress was abandoned.
func (k *Kitchen) Reset(id int, now time.Time) []Event {
	t := k.Get(id)
	if t == nil {
		return nil
	}
	var ev []Event
	if !t.Done && t.Run != Idle && !t.Start.IsZero() {
		if a := clampDur(t.Total-t.Remaining(now), 0); a >= 5*time.Second {
			ev = []Event{{Kind: "kitchen", Label: t.Label, Start: t.Start, Planned: t.Total, Actual: a}}
		}
	}
	t.Run, t.Left, t.EndsAt, t.Start, t.Done, t.DoneAt = Idle, t.Total, time.Time{}, time.Time{}, false, time.Time{}
	return ev
}

// AddTime lengthens (or shortens) a timer; a finished timer comes back to life.
func (k *Kitchen) AddTime(id int, d time.Duration, now time.Time) {
	t := k.Get(id)
	if t == nil {
		return
	}
	if t.Done {
		t.Done, t.DoneAt = false, time.Time{}
		t.Run, t.Left, t.Total, t.Start = Idle, 0, 0, now
		if d <= 0 {
			return
		}
		t.Total, t.Left = d, d
		t.Run, t.EndsAt = Running, now.Add(d)
		return
	}
	left := t.Remaining(now) + d
	if left < 5*time.Second {
		left = 5 * time.Second
	}
	cur := t.Remaining(now)
	t.Total += left - cur
	if t.Total < left {
		t.Total = left
	}
	if t.Run == Running {
		t.EndsAt = now.Add(left)
	} else {
		t.Left = left
	}
}

// Tick finishes what is due.
func (k *Kitchen) Tick(now time.Time) []KitchenFinished {
	var out []KitchenFinished
	for _, t := range k.List {
		if t.Done || t.Run != Running || now.Before(t.EndsAt) {
			continue
		}
		t.Done, t.DoneAt, t.Left, t.Run = true, t.EndsAt, 0, Idle
		out = append(out, KitchenFinished{Timer: *t, Late: now.Sub(t.EndsAt) > lateAfter})
	}
	return out
}

// Event is the history record of a finished timer.
func (f KitchenFinished) Event() Event {
	return Event{Kind: "kitchen", Label: f.Timer.Label, Start: f.Timer.Start, Planned: f.Timer.Total,
		Actual: f.Timer.Total, Completed: true, Late: f.Late}
}

// Order returns the timers in display order: running soonest first, then
// paused, then idle, then finished ones (newest first). Ties keep creation order.
func (k *Kitchen) Order(now time.Time) []*KitchenTimer {
	out := append([]*KitchenTimer(nil), k.List...)
	rank := func(t *KitchenTimer) int {
		switch {
		case t.Done:
			return 3
		case t.Run == Running:
			return 0
		case t.Run == Paused:
			return 1
		}
		return 2
	}
	sort.SliceStable(out, func(i, j int) bool {
		a, b := out[i], out[j]
		ra, rb := rank(a), rank(b)
		if ra != rb {
			return ra < rb
		}
		switch ra {
		case 0, 1:
			return a.Remaining(now) < b.Remaining(now)
		case 3:
			return a.DoneAt.After(b.DoneAt)
		}
		return false
	})
	return out
}

// Running counts timers that are counting down, and returns the soonest.
func (k *Kitchen) Running(now time.Time) (n int, soonest *KitchenTimer) {
	for _, t := range k.List {
		if t.Run == Running && !t.Done {
			n++
			if soonest == nil || t.Remaining(now) < soonest.Remaining(now) {
				soonest = t
			}
		}
	}
	return
}

var (
	kitchenHMS   = regexp.MustCompile(`^(?:(\d+(?:[.,]\d+)?)h)?(?:(\d+(?:[.,]\d+)?)m(?:in)?)?(?:(\d+(?:[.,]\d+)?)s(?:ec)?)?$`)
	kitchenHM    = regexp.MustCompile(`^(\d+)h(\d+)$`)
	kitchenColon = regexp.MustCompile(`^\d+(:\d+){1,2}$`)
	kitchenBare  = regexp.MustCompile(`^\d+(?:[.,]\d+)?$`)
)

func kitchenNum(s string) float64 {
	f, _ := strconv.ParseFloat(strings.Replace(s, ",", ".", 1), 64)
	return f
}

// KitchenDuration parses a liberal duration: "10m", "90s", "1h30", "1h30m",
// "5:30" (min:sec), "1:05:00", "1.5h", and a bare number meaning minutes.
func KitchenDuration(tok string) (time.Duration, bool) {
	tok = strings.ToLower(strings.TrimSpace(tok))
	if tok == "" {
		return 0, false
	}
	switch {
	case kitchenColon.MatchString(tok):
		parts := strings.Split(tok, ":")
		var n [3]int
		off := 3 - len(parts)
		for i, p := range parts {
			n[off+i], _ = strconv.Atoi(p)
		}
		if len(parts) == 2 { // m:s
			return time.Duration(n[1])*time.Minute + time.Duration(n[2])*time.Second, n[1]+n[2] > 0
		}
		d := time.Duration(n[0])*time.Hour + time.Duration(n[1])*time.Minute + time.Duration(n[2])*time.Second
		return d, d > 0
	case kitchenBare.MatchString(tok):
		d := time.Duration(kitchenNum(tok) * float64(time.Minute))
		return d, d > 0
	case kitchenHM.MatchString(tok):
		m := kitchenHM.FindStringSubmatch(tok)
		d := time.Duration(kitchenNum(m[1]))*time.Hour + time.Duration(kitchenNum(m[2]))*time.Minute
		return d, d > 0
	}
	m := kitchenHMS.FindStringSubmatch(tok)
	if m == nil {
		return 0, false
	}
	d := time.Duration(kitchenNum(m[1])*float64(time.Hour)) +
		time.Duration(kitchenNum(m[2])*float64(time.Minute)) +
		time.Duration(kitchenNum(m[3])*float64(time.Second))
	return d, d > 0
}

// KitchenParse splits "10m pasta" / "pasta 10m" / "1h30 roast" into a duration
// and a label. ok is false when no duration was found.
func KitchenParse(s string) (d time.Duration, label string, ok bool) {
	fields := strings.Fields(s)
	for i, f := range fields {
		if dd, good := KitchenDuration(f); good {
			rest := append(append([]string{}, fields[:i]...), fields[i+1:]...)
			return dd, strings.Join(rest, " "), true
		}
	}
	return 0, strings.Join(fields, " "), false
}
