package ui

import (
	"fmt"
	"os"
	"regexp"
	"strings"
	"testing"

	tea "charm.land/bubbletea/v2"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

func settingsOpen(t *testing.T, sec int) (*settingsPage, *Core) {
	c := statsTestCore(t, true)
	c.Cfg.Motion = "still"
	p := newSettingsPage(c, func(string) {})
	p.View(120, 36)
	p.sec = sec
	p.enter()
	return p, c
}

func TestSettingsRenderSizes(t *testing.T) {
	c := statsTestCore(t, true)
	for _, motion := range []string{"full", "still"} {
		c.Cfg.Motion = motion
		p := newSettingsPage(c, func(string) {})
		for _, sz := range [][2]int{{1, 1}, {5, 2}, {19, 6}, {24, 7}, {30, 9}, {40, 12}, {59, 20}, {75, 24}, {76, 24}, {80, 24}, {100, 30}, {120, 40}, {160, 50}, {250, 70}, {97, 13}, {200, 20}} {
			for sec := 0; sec < secCount; sec++ {
				for _, in := range []bool{false, true} {
					p.sec = sec
					p.inForm = false
					p.View(sz[0], sz[1])
					if in {
						p.enter()
					}
					p.t = 3
					statsCheck(t, fmt.Sprintf("settings sec=%d in=%v", sec, in), p.View(sz[0], sz[1]), sz[0], sz[1])
				}
			}
		}
	}
}

func TestSettingsLiveRhythm(t *testing.T) {
	p, c := settingsOpen(t, secRhythm)
	if p.form == nil {
		t.Fatal("no form")
	}
	if c.Cfg.Work != 25 {
		t.Fatalf("work %d", c.Cfg.Work)
	}
	p.Update(statsKeyPress("right")) // inline select moves to the next option
	if c.Cfg.Work != 30 {
		t.Fatalf("work after right = %d", c.Cfg.Work)
	}
	if c.Pomo.Cfg.Work.Minutes() != 30 {
		t.Fatalf("engine not updated: %v", c.Pomo.Cfg.Work)
	}
	// tab moves to the next field, then change rest
	p.Update(statsKeyPress("tab"))
	p.Update(statsKeyPress("right"))
	if c.Cfg.Rest != 7 {
		t.Fatalf("rest = %d", c.Cfg.Rest)
	}
	if c.Cfg.Work != 30 {
		t.Fatal("work must keep its value")
	}
}

func TestSettingsAccentLive(t *testing.T) {
	p, c := settingsOpen(t, secAccent)
	before := c.Pal.Accent
	p.Update(statsKeyPress("right"))
	if c.Cfg.Accent != "lightgreen" || c.Pal.Accent == before {
		t.Fatalf("accent %q %v", c.Cfg.Accent, c.Pal.Accent)
	}
	gen := c.cfgGen
	p.Update(statsKeyPress("down"))
	if c.cfgGen == gen {
		t.Fatal("config generation should bump so the app reloads")
	}
}

func TestSettingsLanguageLive(t *testing.T) {
	p, c := settingsOpen(t, secLang)
	defer i18n.Set("en")
	// options: auto, en, es
	for i := 0; i < 3 && c.Cfg.Lang != "es"; i++ {
		p.Update(statsKeyPress("down"))
	}
	if c.Cfg.Lang != "es" || i18n.Lang() != "es" {
		t.Fatalf("lang %q / %q", c.Cfg.Lang, i18n.Lang())
	}
}

func TestSettingsModes(t *testing.T) {
	registerMode("zz_test", func(c *Core, say func(string)) Mode { return newPomodoro(c, say) })
	defer delete(modeFactories, "zz_test")
	p, c := settingsOpen(t, secModes)
	// pomodoro cannot be turned off
	p.modes.cur = 0
	p.Update(statsKeyPress("space"))
	found := false
	for _, id := range c.Cfg.Modes {
		if id == "pomodoro" {
			found = true
		}
	}
	if !found {
		t.Fatal("pomodoro was removed")
	}
	// enable the extra mode
	for i, id := range p.modes.ids {
		if id == "zz_test" {
			p.modes.cur = i
		}
	}
	p.Update(statsKeyPress("space"))
	if c.Cfg.Modes[len(c.Cfg.Modes)-1] != "zz_test" {
		t.Fatalf("modes %v", c.Cfg.Modes)
	}
}

func TestSettingsDataConfirm(t *testing.T) {
	p, c := settingsOpen(t, secData)
	n := len(c.Events())
	if n == 0 {
		t.Fatal("expected seeded history")
	}
	p.dataCur = 1
	p.Update(statsKeyPress("enter"))
	if p.confirm != 1 || len(c.Events()) != n {
		t.Fatal("clear must ask first")
	}
	p.Update(statsKeyPress("n"))
	if p.confirm != 0 || len(c.Events()) != n {
		t.Fatal("n must cancel")
	}
	p.Update(statsKeyPress("enter"))
	p.Update(statsKeyPress("y"))
	if len(c.Events()) != 0 {
		t.Fatal("history not cleared")
	}
	// reset settings
	c.Cfg.Work = 50
	p.dataCur = 2
	p.Update(statsKeyPress("enter"))
	p.Update(statsKeyPress("y"))
	if c.Cfg.Work != 25 {
		t.Fatalf("work after reset %d", c.Cfg.Work)
	}
}

func TestSettingsBack(t *testing.T) {
	p, _ := settingsOpen(t, secLook)
	if !p.Back() || p.inForm {
		t.Fatal("back should leave the form")
	}
	if p.Back() {
		t.Fatal("back on the nav should let the app close the page")
	}
}

func TestSettingsCSV(t *testing.T) {
	c := statsTestCore(t, true)
	path := t.TempDir() + "/h.csv"
	if err := settingsWriteCSV(path, c.Events()); err != nil {
		t.Fatal(err)
	}
	b, _ := os.ReadFile(path)
	if len(b) < 50 {
		t.Fatal("csv empty")
	}
}

// Every i18n key used by the stats and settings pages exists in both languages.
func TestStatsSettingsKeys(t *testing.T) {
	re := regexp.MustCompile(`T\("([a-z0-9.]+)"`)
	var keys []string
	for _, f := range []string{"stats.go", "stats_data.go", "stats_widgets.go", "settings.go", "settings_forms.go", "settings_custom.go"} {
		b, err := os.ReadFile(f)
		if err != nil {
			t.Fatal(err)
		}
		for _, m := range re.FindAllStringSubmatch(string(b), -1) {
			if !strings.HasSuffix(m[1], ".") { // prefixes of built keys
				keys = append(keys, m[1])
			}
		}
	}
	// keys built from a prefix
	for _, sec := range settingsSections {
		keys = append(keys, sec.key, sec.key+".d")
	}
	for _, k := range []string{"theme.auto", "theme.dark", "theme.light", "motion.full", "motion.calm", "motion.still", "font.line", "font.led", "font.seg",
		"dial.ring", "dial.orbit", "dial.hourglass", "dial.liquid", "dial.radar", "dial.spiral", "dial.bars",
		"clock.analog", "clock.digital", "clock.orbit", "clock.binary", "clock.sun"} {
		keys = append(keys, "settings."+k)
	}
	for _, k := range []string{"focus", "rest", "long", "timer", "stopwatch", "alarm", "breathe"} {
		keys = append(keys, "stats.kind."+k)
	}
	for _, lang := range []string{"en", "es"} {
		for _, k := range keys {
			if !i18n.Has(lang, k) && !(lang == "es" && k == "x") {
				t.Errorf("missing %s key %q", lang, k)
			}
		}
	}
}

func TestSettingsPreview(t *testing.T) {
	if os.Getenv("SPREVIEW") == "" {
		t.Skip()
	}
	var w, h, sec int
	fmt.Sscanf(os.Getenv("SPREVIEW"), "%dx%dx%d", &w, &h, &sec)
	p, _ := settingsOpen(t, sec)
	p.View(w, h)
	fmt.Println(statsAnsiStrip(p.View(w, h)))
}

var _ tea.Msg
