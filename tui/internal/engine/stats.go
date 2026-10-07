package engine

import (
	"sort"
	"time"
)

// DayStat is one calendar day of focus.
type DayStat struct {
	Day      time.Time
	Focus    time.Duration
	Sessions int // completed focus sessions
}

// Summary is what the stats screen shows.
type Summary struct {
	Days      []DayStat // oldest first, one entry per day in the window
	Today     DayStat
	Week      time.Duration // last 7 days
	Total     time.Duration // everything in the window
	Sessions  int           // completed focus sessions in the window
	Abandoned int
	Streak    int // consecutive days with focus, ending today (or yesterday)
	BestDay   DayStat
	AvgPerDay time.Duration // over days with focus
	ByKind    map[Kind]time.Duration
	TimerRuns int
	Stopwatch time.Duration
}

func dayStart(t time.Time) time.Time {
	y, m, d := t.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, t.Location())
}

// Summarize folds the event log into per-day numbers for the last `days` days.
func Summarize(events []Event, now time.Time, days int) Summary {
	if days < 7 {
		days = 7
	}
	today := dayStart(now)
	s := Summary{ByKind: map[Kind]time.Duration{}}
	idx := map[time.Time]int{}
	for i := days - 1; i >= 0; i-- {
		d := today.AddDate(0, 0, -i)
		idx[d] = len(s.Days)
		s.Days = append(s.Days, DayStat{Day: d})
	}
	for _, e := range events {
		d := dayStart(e.Start.In(now.Location()))
		i, ok := idx[d]
		if !ok {
			continue
		}
		s.ByKind[e.Kind] += e.Actual
		switch e.Kind {
		case KindFocus:
			s.Days[i].Focus += e.Actual
			s.Total += e.Actual
			if e.Completed {
				s.Days[i].Sessions++
				s.Sessions++
			} else {
				s.Abandoned++
			}
		case KindTimer:
			s.TimerRuns++
		case KindStopwatch:
			s.Stopwatch += e.Actual
		}
	}
	s.Today = s.Days[len(s.Days)-1]
	for i := len(s.Days) - 7; i < len(s.Days); i++ {
		s.Week += s.Days[i].Focus
	}
	active := 0
	for _, d := range s.Days {
		if d.Focus > 0 {
			active++
			if d.Focus > s.BestDay.Focus {
				s.BestDay = d
			}
		}
	}
	if active > 0 {
		s.AvgPerDay = s.Total / time.Duration(active)
	}
	// streak: back from today (a quiet today does not break yesterday's run)
	i := len(s.Days) - 1
	if s.Days[i].Focus == 0 {
		i--
	}
	for ; i >= 0 && s.Days[i].Focus > 0; i-- {
		s.Streak++
	}
	return s
}

// Level buckets a day's focus into 0..4 for a heat map.
func (d DayStat) Level() int {
	switch m := d.Focus.Minutes(); {
	case m <= 0:
		return 0
	case m < 30:
		return 1
	case m < 90:
		return 2
	case m < 180:
		return 3
	}
	return 4
}

// Recent returns the last n events, newest first.
func Recent(events []Event, n int) []Event {
	out := append([]Event(nil), events...)
	sort.SliceStable(out, func(i, j int) bool { return out[i].Start.After(out[j].Start) })
	if len(out) > n {
		out = out[:n]
	}
	return out
}
