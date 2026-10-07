package i18n

import (
	"strings"
	"testing"
)

func TestClockKeysInBothLanguages(t *testing.T) {
	for k := range en {
		if strings.HasPrefix(k, "clock.") || k == "help.mode.clock" {
			if _, ok := es[k]; !ok {
				t.Errorf("es is missing %s", k)
			}
		}
	}
	for k := range es {
		if strings.HasPrefix(k, "clock.") || k == "help.mode.clock" {
			if _, ok := en[k]; !ok {
				t.Errorf("en is missing %s", k)
			}
		}
	}
	for i := 0; i < 7; i++ {
		if en["clock.day."+string(rune('0'+i))] == "" || es["clock.dayshort."+string(rune('0'+i))] == "" {
			t.Errorf("weekday %d incomplete", i)
		}
	}
}
