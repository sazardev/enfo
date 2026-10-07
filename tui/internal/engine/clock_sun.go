package engine

import (
	"math"
	"time"
)

// ClockSunTimes returns sunrise and sunset (as instants) for the calendar day
// of t at a place, by the sunrise equation. polar is +1 when the sun never sets
// that day, -1 when it never rises, 0 normally (rise and set are then valid).
func ClockSunTimes(t time.Time, lat, lon float64) (rise, set time.Time, polar int) {
	y, m, d := t.Date()
	noon := time.Date(y, m, d, 12, 0, 0, 0, time.UTC)
	jd := float64(noon.UnixNano())/8.64e13 + 2440587.5
	rad := math.Pi / 180
	n := math.Round(jd - 2451545.0)
	js := n - lon/360 // lon is east-positive (the wiki formula: l_w, east positive)
	mean := math.Mod(357.5291+0.98560028*js, 360)
	mr := mean * rad
	c := 1.9148*math.Sin(mr) + 0.02*math.Sin(2*mr) + 0.0003*math.Sin(3*mr)
	lambda := math.Mod(mean+c+180+102.9372, 360) * rad
	transit := 2451545.0 + js + 0.0053*math.Sin(mr) - 0.0069*math.Sin(2*lambda)
	sinDec := math.Sin(lambda) * math.Sin(23.4397*rad)
	dec := math.Asin(sinDec)
	cosW := (math.Sin(-0.833*rad) - math.Sin(lat*rad)*sinDec) / (math.Cos(lat*rad) * math.Cos(dec))
	switch {
	case cosW >= 1:
		return time.Time{}, time.Time{}, -1
	case cosW <= -1:
		return time.Time{}, time.Time{}, 1
	}
	w := math.Acos(cosW) / rad
	toTime := func(j float64) time.Time {
		return time.Unix(0, int64((j-2440587.5)*8.64e13)).In(t.Location())
	}
	return toTime(transit - w/360), toTime(transit + w/360), 0
}

// ClockMoonPhase is the age of the moon in 0..1 (0 new, 0.5 full).
func ClockMoonPhase(t time.Time) float64 {
	const synodic = 29.530588853
	ref := time.Date(2000, 1, 6, 18, 14, 0, 0, time.UTC) // a new moon
	days := t.Sub(ref).Hours() / 24
	p := math.Mod(days/synodic, 1)
	if p < 0 {
		p++
	}
	return p
}
