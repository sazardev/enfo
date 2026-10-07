package engine

import (
	"math"
	"time"
)

// SubSolar returns the point on Earth where the sun is straight overhead.
// Accurate to well under a degree, which is plenty for a day/night map.
func SubSolar(t time.Time) (lat, lon float64) {
	jd := float64(t.UTC().UnixNano())/8.64e13 + 2440587.5
	d := jd - 2451545.0
	l := math.Mod(280.460+0.9856474*d, 360)
	g := (357.528 + 0.9856003*d) * math.Pi / 180
	lambda := (l + 1.915*math.Sin(g) + 0.020*math.Sin(2*g)) * math.Pi / 180
	eps := (23.439 - 0.0000004*d) * math.Pi / 180
	dec := math.Asin(math.Sin(eps) * math.Sin(lambda))
	ra := math.Atan2(math.Cos(eps)*math.Sin(lambda), math.Cos(lambda))
	gmst := math.Mod(280.46061837+360.98564736629*d, 360) * math.Pi / 180
	lon = ra - gmst
	for lon > math.Pi {
		lon -= 2 * math.Pi
	}
	for lon < -math.Pi {
		lon += 2 * math.Pi
	}
	return dec * 180 / math.Pi, lon * 180 / math.Pi
}

// SunAltitude returns the sun's height above the horizon (degrees, negative at
// night) for a place, given the sub-solar point.
func SunAltitude(lat, lon, sunLat, sunLon float64) float64 {
	p, d := lat*math.Pi/180, sunLat*math.Pi/180
	h := (lon - sunLon) * math.Pi / 180
	return math.Asin(math.Sin(p)*math.Sin(d)+math.Cos(p)*math.Cos(d)*math.Cos(h)) * 180 / math.Pi
}
