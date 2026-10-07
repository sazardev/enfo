// Package store persists Enfo on disk: settings, the live state of every mode
// (so timers survive closing the terminal) and the append-only history.
package store

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
)

// Config is everything the user can change.
type Config struct {
	Lang   string `json:"lang"`   // auto, en, es
	Theme  string `json:"theme"`  // auto, dark, light
	Accent string `json:"accent"` // an accent name or #rrggbb

	Dial string `json:"dial"` // timer visual
	Font string `json:"font"` // line, led, seg

	Work     int  `json:"work"` // minutes
	Rest     int  `json:"rest"`
	Long     int  `json:"long"`
	Cycles   int  `json:"cycles"`
	AutoNext bool `json:"autoNext"`

	ClockDesign  string `json:"clockDesign"`
	Clock24      bool   `json:"clock24"`
	ClockSeconds bool   `json:"clockSeconds"`

	Splash bool   `json:"splash"`
	Motion string `json:"motion"` // full, calm, still
	Stars  bool   `json:"stars"`  // dust in the background
	Mouse  bool   `json:"mouse"`

	Notify bool `json:"notify"` // desktop notifications
	Sound  bool `json:"sound"`  // play a sound when something rings
	Bell   bool `json:"bell"`   // terminal bell

	Modes   []string `json:"modes"` // enabled modes, in order
	Start   string   `json:"start"` // mode to open (or "last")
	Cities  []string `json:"cities"`
	Presets []int    `json:"presets"` // timer presets, seconds
	Breathe string   `json:"breathe"`
	// BreatheVisual is the breathing animation (orb, flower, waves, box).
	BreatheVisual string `json:"breatheVisual"`

	Onboarded bool `json:"onboarded"`
}

// DefaultModes are the modes on by default.
var DefaultModes = []string{"pomodoro", "clock", "timer", "stopwatch", "alarm", "world", "breathe"}

func DefaultConfig() Config {
	return Config{
		Lang: "auto", Theme: "auto", Accent: "lime",
		Dial: "ring", Font: "line",
		Work: 25, Rest: 5, Long: 15, Cycles: 4, AutoNext: false,
		ClockDesign: "analog", Clock24: true, ClockSeconds: true,
		Splash: true, Motion: "full", Stars: true, Mouse: true,
		Notify: true, Sound: true, Bell: true,
		Modes: append([]string(nil), DefaultModes...), Start: "pomodoro",
		Cities:  engine.DefaultCities(),
		Presets: []int{60, 180, 300, 600, 900, 1800},
		Breathe: "box", BreatheVisual: "orb",
	}
}

// Pomodoro converts the stored minutes to the engine's config.
func (c Config) Pomodoro() engine.PomodoroConfig {
	return engine.PomodoroConfig{
		Work: time.Duration(c.Work) * time.Minute, Rest: time.Duration(c.Rest) * time.Minute,
		Long: time.Duration(c.Long) * time.Minute, Cycles: c.Cycles, AutoNext: c.AutoNext,
	}
}

// Normalize repairs anything missing or out of range, so a hand-edited or old
// file can never crash the UI.
func (c *Config) Normalize() {
	d := DefaultConfig()
	if c.Lang == "" {
		c.Lang = d.Lang
	}
	if c.Theme == "" {
		c.Theme = d.Theme
	}
	if c.Accent == "" {
		c.Accent = d.Accent
	}
	if c.Dial == "" {
		c.Dial = d.Dial
	}
	if c.Font == "" {
		c.Font = d.Font
	}
	c.Work = clampInt(c.Work, 1, 600, d.Work)
	c.Rest = clampInt(c.Rest, 1, 240, d.Rest)
	c.Long = clampInt(c.Long, 1, 240, d.Long)
	c.Cycles = clampInt(c.Cycles, 0, 12, d.Cycles)
	if c.ClockDesign == "" {
		c.ClockDesign = d.ClockDesign
	}
	if c.Motion != "full" && c.Motion != "calm" && c.Motion != "still" {
		c.Motion = d.Motion
	}
	if len(c.Modes) == 0 {
		c.Modes = d.Modes
	}
	if c.Start == "" {
		c.Start = d.Start
	}
	if len(c.Cities) == 0 {
		c.Cities = d.Cities
	}
	if len(c.Presets) == 0 {
		c.Presets = d.Presets
	}
	if c.BreatheVisual == "" {
		c.BreatheVisual = d.BreatheVisual
	}
	if c.Breathe == "" {
		c.Breathe = d.Breathe
	}
}

func clampInt(v, lo, hi, def int) int {
	if v < lo || v > hi {
		return def
	}
	return v
}

// State is the live state of the modes.
type State struct {
	Pomodoro  *engine.Pomodoro  `json:"pomodoro,omitempty"`
	Timer     *engine.Timer     `json:"timer,omitempty"`
	Stopwatch *engine.Stopwatch `json:"stopwatch,omitempty"`
	Alarms    engine.Alarms     `json:"alarms"`
	LastMode  string            `json:"lastMode,omitempty"`
	WakerPIDs []int             `json:"wakers,omitempty"`
	Saved     time.Time         `json:"saved"`
}

// Store is the on-disk home of Enfo.
type Store struct {
	ConfigDir string
	StateDir  string
}

// Open resolves the XDG directories (ENFO_CONFIG_DIR / ENFO_STATE_DIR win, for
// tests and portable installs) and creates them.
func Open() (*Store, error) {
	s := &Store{ConfigDir: os.Getenv("ENFO_CONFIG_DIR"), StateDir: os.Getenv("ENFO_STATE_DIR")}
	home, _ := os.UserHomeDir()
	if s.ConfigDir == "" {
		base := os.Getenv("XDG_CONFIG_HOME")
		if base == "" {
			base = filepath.Join(home, ".config")
		}
		s.ConfigDir = filepath.Join(base, "enfo")
	}
	if s.StateDir == "" {
		base := os.Getenv("XDG_STATE_HOME")
		if base == "" {
			base = filepath.Join(home, ".local", "state")
		}
		s.StateDir = filepath.Join(base, "enfo")
	}
	for _, d := range []string{s.ConfigDir, s.StateDir} {
		if err := os.MkdirAll(d, 0o755); err != nil {
			return nil, err
		}
	}
	return s, nil
}

func (s *Store) ConfigPath() string  { return filepath.Join(s.ConfigDir, "config.json") }
func (s *Store) StatePath() string   { return filepath.Join(s.StateDir, "state.json") }
func (s *Store) HistoryPath() string { return filepath.Join(s.StateDir, "history.jsonl") }
func (s *Store) LogPath() string     { return filepath.Join(s.StateDir, "enfo.log") }

func writeAtomic(path string, data []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// LoadConfig reads the config; a missing or broken file yields the defaults.
func (s *Store) LoadConfig() (Config, bool) {
	c := DefaultConfig()
	b, err := os.ReadFile(s.ConfigPath())
	if err != nil {
		return c, false
	}
	// start from the defaults so new settings appear on old files
	if err := json.Unmarshal(b, &c); err != nil {
		return DefaultConfig(), false
	}
	c.Normalize()
	return c, true
}

func (s *Store) SaveConfig(c Config) error {
	b, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}
	return writeAtomic(s.ConfigPath(), append(b, '\n'))
}

func (s *Store) LoadState() State {
	var st State
	b, err := os.ReadFile(s.StatePath())
	if err != nil {
		return st
	}
	if json.Unmarshal(b, &st) != nil {
		return State{}
	}
	return st
}

func (s *Store) SaveState(st State) error {
	st.Saved = time.Now()
	b, err := json.Marshal(st)
	if err != nil {
		return err
	}
	return writeAtomic(s.StatePath(), b)
}

// AppendEvents adds events to the history.
func (s *Store) AppendEvents(evs ...engine.Event) error {
	if len(evs) == 0 {
		return nil
	}
	f, err := os.OpenFile(s.HistoryPath(), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	for _, e := range evs {
		if err := enc.Encode(e); err != nil {
			return err
		}
	}
	return nil
}

// Events reads the whole history, skipping any line that does not parse.
func (s *Store) Events() []engine.Event {
	b, err := os.ReadFile(s.HistoryPath())
	if err != nil {
		return nil
	}
	var out []engine.Event
	start := 0
	for i := 0; i <= len(b); i++ {
		if i == len(b) || b[i] == '\n' {
			if i > start {
				var e engine.Event
				if json.Unmarshal(b[start:i], &e) == nil {
					out = append(out, e)
				}
			}
			start = i + 1
		}
	}
	return out
}

func (s *Store) ClearHistory() error {
	err := os.Remove(s.HistoryPath())
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	return err
}

// Reset removes settings, state and history.
func (s *Store) Reset() {
	for _, p := range []string{s.ConfigPath(), s.StatePath(), s.HistoryPath()} {
		_ = os.Remove(p)
	}
}
