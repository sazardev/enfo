package engine

import (
	"os"
	"strings"
	"time"
	_ "time/tzdata" // real zones on any machine, DST included
)

// City is a place the world clock can show.
type City struct {
	ID       string // IANA-ish id, what is stored
	Zone     string // tz database zone
	EN, ES   string
	Lat, Lon float64
}

func (c City) Name(lang string) string {
	if lang == "es" && c.ES != "" {
		return c.ES
	}
	return c.EN
}

// Loc loads the city's time zone (UTC if unknown).
func (c City) Loc() *time.Location {
	if l, err := time.LoadLocation(c.Zone); err == nil {
		return l
	}
	return time.UTC
}

func city(id, en, es string, lat, lon float64) City {
	return City{ID: id, Zone: id, EN: en, ES: es, Lat: lat, Lon: lon}
}

// Cities is the catalog (the mobile app's list plus a few more).
var Cities = []City{
	city("America/New_York", "New York", "Nueva York", 40.71, -74.01),
	city("America/Los_Angeles", "Los Angeles", "Los Ángeles", 34.05, -118.24),
	{ID: "America/San_Francisco", Zone: "America/Los_Angeles", EN: "San Francisco", ES: "San Francisco", Lat: 37.77, Lon: -122.42},
	city("America/Chicago", "Chicago", "Chicago", 41.88, -87.63),
	city("America/Denver", "Denver", "Denver", 39.74, -104.99),
	city("America/Phoenix", "Phoenix", "Phoenix", 33.45, -112.07),
	city("America/Anchorage", "Anchorage", "Anchorage", 61.22, -149.90),
	city("Pacific/Honolulu", "Honolulu", "Honolulu", 21.31, -157.86),
	city("America/Toronto", "Toronto", "Toronto", 43.65, -79.38),
	city("America/Vancouver", "Vancouver", "Vancouver", 49.28, -123.12),
	{ID: "America/Miami", Zone: "America/New_York", EN: "Miami", ES: "Miami", Lat: 25.76, Lon: -80.19},
	city("America/Mexico_City", "Mexico City", "Ciudad de México", 19.43, -99.13),
	city("America/Guatemala", "Guatemala City", "Ciudad de Guatemala", 14.63, -90.51),
	city("America/Costa_Rica", "San José", "San José", 9.93, -84.08),
	city("America/Panama", "Panama City", "Ciudad de Panamá", 8.98, -79.52),
	city("America/Havana", "Havana", "La Habana", 23.11, -82.37),
	city("America/Santo_Domingo", "Santo Domingo", "Santo Domingo", 18.49, -69.93),
	city("America/Bogota", "Bogotá", "Bogotá", 4.71, -74.07),
	city("America/Lima", "Lima", "Lima", -12.05, -77.04),
	city("America/Caracas", "Caracas", "Caracas", 10.48, -66.90),
	city("America/Guayaquil", "Quito", "Quito", -0.18, -78.47),
	city("America/La_Paz", "La Paz", "La Paz", -16.49, -68.12),
	city("America/Santiago", "Santiago", "Santiago", -33.45, -70.67),
	city("America/Argentina/Buenos_Aires", "Buenos Aires", "Buenos Aires", -34.60, -58.38),
	city("America/Montevideo", "Montevideo", "Montevideo", -34.90, -56.16),
	city("America/Sao_Paulo", "São Paulo", "São Paulo", -23.55, -46.63),
	city("Europe/London", "London", "Londres", 51.51, -0.13),
	city("Europe/Dublin", "Dublin", "Dublín", 53.35, -6.26),
	city("Atlantic/Reykjavik", "Reykjavik", "Reikiavik", 64.15, -21.94),
	city("Europe/Lisbon", "Lisbon", "Lisboa", 38.72, -9.14),
	city("Europe/Madrid", "Madrid", "Madrid", 40.42, -3.70),
	city("Europe/Paris", "Paris", "París", 48.86, 2.35),
	city("Europe/Amsterdam", "Amsterdam", "Ámsterdam", 52.37, 4.90),
	city("Europe/Brussels", "Brussels", "Bruselas", 50.85, 4.35),
	city("Europe/Berlin", "Berlin", "Berlín", 52.52, 13.40),
	city("Europe/Zurich", "Zurich", "Zúrich", 47.38, 8.54),
	city("Europe/Rome", "Rome", "Roma", 41.90, 12.50),
	city("Europe/Vienna", "Vienna", "Viena", 48.21, 16.37),
	city("Europe/Prague", "Prague", "Praga", 50.08, 14.44),
	city("Europe/Warsaw", "Warsaw", "Varsovia", 52.23, 21.01),
	city("Europe/Stockholm", "Stockholm", "Estocolmo", 59.33, 18.07),
	city("Europe/Oslo", "Oslo", "Oslo", 59.91, 10.75),
	city("Europe/Helsinki", "Helsinki", "Helsinki", 60.17, 24.94),
	city("Europe/Athens", "Athens", "Atenas", 37.98, 23.73),
	city("Europe/Kyiv", "Kyiv", "Kiev", 50.45, 30.52),
	city("Europe/Istanbul", "Istanbul", "Estambul", 41.01, 28.98),
	city("Europe/Moscow", "Moscow", "Moscú", 55.76, 37.62),
	city("Africa/Casablanca", "Casablanca", "Casablanca", 33.57, -7.59),
	city("Africa/Lagos", "Lagos", "Lagos", 6.52, 3.38),
	city("Africa/Cairo", "Cairo", "El Cairo", 30.04, 31.24),
	city("Africa/Nairobi", "Nairobi", "Nairobi", -1.29, 36.82),
	city("Africa/Addis_Ababa", "Addis Ababa", "Adís Abeba", 9.03, 38.74),
	city("Africa/Johannesburg", "Johannesburg", "Johannesburgo", -26.20, 28.05),
	{ID: "Africa/Cape_Town", Zone: "Africa/Johannesburg", EN: "Cape Town", ES: "Ciudad del Cabo", Lat: -33.92, Lon: 18.42},
	city("Asia/Jerusalem", "Jerusalem", "Jerusalén", 31.77, 35.21),
	city("Asia/Riyadh", "Riyadh", "Riad", 24.71, 46.68),
	city("Asia/Tehran", "Tehran", "Teherán", 35.69, 51.39),
	city("Asia/Dubai", "Dubai", "Dubái", 25.20, 55.27),
	city("Asia/Karachi", "Karachi", "Karachi", 24.86, 67.01),
	city("Asia/Kolkata", "Delhi", "Delhi", 28.61, 77.21),
	{ID: "Asia/Mumbai", Zone: "Asia/Kolkata", EN: "Mumbai", ES: "Bombay", Lat: 19.08, Lon: 72.88},
	city("Asia/Colombo", "Colombo", "Colombo", 6.93, 79.86),
	city("Asia/Kathmandu", "Kathmandu", "Katmandú", 27.72, 85.32),
	city("Asia/Dhaka", "Dhaka", "Daca", 23.81, 90.41),
	city("Asia/Bangkok", "Bangkok", "Bangkok", 13.76, 100.50),
	{ID: "Asia/Hanoi", Zone: "Asia/Bangkok", EN: "Hanoi", ES: "Hanói", Lat: 21.03, Lon: 105.85},
	city("Asia/Jakarta", "Jakarta", "Yakarta", -6.21, 106.85),
	city("Asia/Kuala_Lumpur", "Kuala Lumpur", "Kuala Lumpur", 3.14, 101.69),
	city("Asia/Singapore", "Singapore", "Singapur", 1.35, 103.82),
	city("Asia/Hong_Kong", "Hong Kong", "Hong Kong", 22.32, 114.17),
	city("Asia/Shanghai", "Shanghai", "Shanghái", 31.23, 121.47),
	city("Asia/Taipei", "Taipei", "Taipéi", 25.03, 121.57),
	city("Asia/Manila", "Manila", "Manila", 14.60, 120.98),
	city("Asia/Seoul", "Seoul", "Seúl", 37.57, 126.98),
	city("Asia/Tokyo", "Tokyo", "Tokio", 35.68, 139.69),
	city("Australia/Perth", "Perth", "Perth", -31.95, 115.86),
	city("Australia/Sydney", "Sydney", "Sídney", -33.87, 151.21),
	city("Australia/Melbourne", "Melbourne", "Melbourne", -37.81, 144.96),
	city("Pacific/Auckland", "Auckland", "Auckland", -36.85, 174.76),
	city("Pacific/Fiji", "Suva", "Suva", -18.14, 178.44),
}

// CityByID finds a catalog city.
func CityByID(id string) (City, bool) {
	for _, c := range Cities {
		if c.ID == id {
			return c, true
		}
	}
	return City{}, false
}

// LocalZoneName returns the IANA name of the machine's zone if it can be told
// (TZ, then the /etc/localtime symlink), or "".
func LocalZoneName() string {
	if tz := os.Getenv("TZ"); tz != "" && tz != "Local" {
		return strings.TrimPrefix(tz, ":")
	}
	if p, err := os.Readlink("/etc/localtime"); err == nil {
		if i := strings.Index(p, "zoneinfo/"); i >= 0 {
			return p[i+len("zoneinfo/"):]
		}
	}
	if b, err := os.ReadFile("/etc/timezone"); err == nil {
		return strings.TrimSpace(string(b))
	}
	return ""
}

// LocalCity picks the catalog city that matches the machine's time zone.
func LocalCity() (City, bool) {
	z := LocalZoneName()
	if z == "" {
		return City{}, false
	}
	for _, c := range Cities {
		if c.ID == z {
			return c, true
		}
	}
	for _, c := range Cities {
		if c.Zone == z {
			return c, true
		}
	}
	return City{}, false
}

// DefaultCities are shown on a first run: home first, then a spread of the
// world's big clocks.
func DefaultCities() []string {
	out := []string{}
	if c, ok := LocalCity(); ok {
		out = append(out, c.ID)
	}
	for _, id := range []string{"America/New_York", "Europe/Madrid", "Europe/London", "Asia/Tokyo", "Australia/Sydney"} {
		dup := false
		for _, o := range out {
			if o == id {
				dup = true
			}
		}
		if !dup {
			out = append(out, id)
		}
	}
	return out
}
