package engine

import "time"

// StatsKind is the totals of one kind of event.
type StatsKind struct {
	Kind      Kind
	Count     int
	Completed int
	Dur       time.Duration
}

// StatsHourly spreads the focused time of the last `days` days over the 24
// hours of the day (a session crossing an hour boundary is split).
func StatsHourly(events []Event, now time.Time, days int) [24]time.Duration {
	var out [24]time.Duration
	from := dayStart(now).AddDate(0, 0, -(days - 1))
	for _, e := range events {
		if e.Kind != KindFocus || e.Actual <= 0 {
			continue
		}
		start := e.Start.In(now.Location())
		if start.Before(from) {
			continue
		}
		left := e.Actual
		t := start
		for left > 0 {
			next := t.Truncate(time.Hour).Add(time.Hour)
			chunk := next.Sub(t)
			if chunk > left {
				chunk = left
			}
			out[t.Hour()] += chunk
			left -= chunk
			t = next
		}
	}
	return out
}

// StatsBestHour returns the hour with the most focus (and false if none).
func StatsBestHour(h [24]time.Duration) (int, bool) {
	best, ok := 0, false
	var mx time.Duration
	for i, d := range h {
		if d > mx {
			best, mx, ok = i, d, true
		}
	}
	return best, ok
}

// StatsWeekdays totals focus per weekday (index 0 = Monday) over `days` days.
func StatsWeekdays(events []Event, now time.Time, days int) [7]time.Duration {
	var out [7]time.Duration
	from := dayStart(now).AddDate(0, 0, -(days - 1))
	for _, e := range events {
		if e.Kind != KindFocus {
			continue
		}
		s := e.Start.In(now.Location())
		if s.Before(from) {
			continue
		}
		out[(int(s.Weekday())+6)%7] += e.Actual
	}
	return out
}

// StatsKinds totals every kind of event over the last `days` days, in a
// stable order.
func StatsKinds(events []Event, now time.Time, days int) []StatsKind {
	order := []Kind{KindFocus, KindRest, KindLong, KindTimer, KindStopwatch, KindAlarm, KindBreathe}
	idx := map[Kind]int{}
	out := make([]StatsKind, len(order))
	for i, k := range order {
		idx[k] = i
		out[i].Kind = k
	}
	from := dayStart(now).AddDate(0, 0, -(days - 1))
	for _, e := range events {
		if e.Start.In(now.Location()).Before(from) {
			continue
		}
		i, ok := idx[e.Kind]
		if !ok {
			continue
		}
		out[i].Count++
		out[i].Dur += e.Actual
		if e.Completed {
			out[i].Completed++
		}
	}
	return out
}

// StatsCompletion is the share of focus sessions that were finished (0..1);
// ok is false when there are none.
func StatsCompletion(s Summary) (float64, bool) {
	n := s.Sessions + s.Abandoned
	if n == 0 {
		return 0, false
	}
	return float64(s.Sessions) / float64(n), true
}

// StatsDayAt returns the day stat for a date within a summary (ok false when
// the date is outside its window).
func StatsDayAt(s Summary, day time.Time) (DayStat, bool) {
	d := dayStart(day)
	for _, ds := range s.Days {
		if ds.Day.Equal(d) {
			return ds, true
		}
	}
	return DayStat{}, false
}
