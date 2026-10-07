package ui

import (
	"math"
	"time"
)

// worldSunTimes returns sunrise and sunset for a place on the local calendar
// day of `day` (NOAA sunrise equation). polar is +1 for the midnight sun, -1
// for polar night and 0 otherwise (in which case rise and set are valid).
func worldSunTimes(lat, lon float64, day time.Time) (rise, set time.Time, polar int) {
	loc := day.Location()
	noon := time.Date(day.Year(), day.Month(), day.Day(), 12, 0, 0, 0, loc)
	jd := float64(noon.UTC().UnixNano())/8.64e13 + 2440587.5
	n := math.Ceil(jd - 2451545.0 + 0.0008)
	jStar := n - lon/360
	rad := math.Pi / 180
	m := math.Mod(357.5291+0.98560028*jStar, 360)
	c := 1.9148*math.Sin(m*rad) + 0.02*math.Sin(2*m*rad) + 0.0003*math.Sin(3*m*rad)
	lambda := math.Mod(m+c+180+102.9372, 360)
	transit := 2451545.0 + jStar + 0.0053*math.Sin(m*rad) - 0.0069*math.Sin(2*lambda*rad)
	sinDec := math.Sin(lambda*rad) * math.Sin(23.4397*rad)
	cosDec := math.Sqrt(1 - sinDec*sinDec)
	cosH := (math.Sin(-0.833*rad) - math.Sin(lat*rad)*sinDec) / (math.Cos(lat*rad) * cosDec)
	switch {
	case cosH <= -1:
		return time.Time{}, time.Time{}, 1
	case cosH >= 1:
		return time.Time{}, time.Time{}, -1
	}
	h := math.Acos(cosH) / rad
	toTime := func(j float64) time.Time {
		sec := (j - 2440587.5) * 86400
		return time.Unix(int64(sec), int64((sec-math.Floor(sec))*1e9)).In(loc)
	}
	return toTime(transit - h/360), toTime(transit + h/360), 0
}
