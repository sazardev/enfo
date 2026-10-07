package engine

import "time"

// VersusState is where a two-player game stands.
type VersusState string

const (
	VersusSetup   VersusState = "setup"
	VersusRunning VersusState = "running"
	VersusPaused  VersusState = "paused"
	VersusFlag    VersusState = "flag" // someone ran out of time
)

// VersusGame is a chess-style clock with Fischer increment and simple delay.
// Left holds each player's time as of TurnStart (or as paused); the active
// player's clock is derived from the absolute TurnStart instant.
type VersusGame struct {
	Total   time.Duration    `json:"total"`
	Inc     time.Duration    `json:"inc"`
	Delay   time.Duration    `json:"delay"`
	State   VersusState      `json:"state"`
	Active  int              `json:"active"`
	Left    [2]time.Duration `json:"left"`
	Turn    time.Time        `json:"turn,omitempty"`
	Moves   [2]int           `json:"moves"`
	Flagged int              `json:"flagged"`
	Began   time.Time        `json:"began,omitempty"`
}

// NewVersus makes a game in setup.
func NewVersus(total, inc, delay time.Duration) *VersusGame {
	g := &VersusGame{Total: total, Inc: inc, Delay: delay, State: VersusSetup}
	g.Left = [2]time.Duration{total, total}
	return g
}

// Configure changes the time control (only in setup).
func (g *VersusGame) Configure(total, inc, delay time.Duration) {
	if g.State != VersusSetup {
		return
	}
	g.Total, g.Inc, g.Delay = total, inc, delay
	g.Left = [2]time.Duration{total, total}
}

// Remaining is a player's clock at now.
func (g *VersusGame) Remaining(p int, now time.Time) time.Duration {
	left := g.Left[p]
	if g.State == VersusRunning && p == g.Active {
		used := now.Sub(g.Turn) - g.Delay
		if used > 0 {
			left -= used
		}
	}
	return clampDur(left, 0)
}

// InDelay reports whether the active player is still inside the delay window
// (their clock is not moving yet) and how much of it is left.
func (g *VersusGame) InDelay(now time.Time) (bool, time.Duration) {
	if g.State != VersusRunning || g.Delay <= 0 {
		return false, 0
	}
	if d := g.Delay - now.Sub(g.Turn); d > 0 {
		return true, d
	}
	return false, 0
}

// Begin starts the game with the given player to move.
func (g *VersusGame) Begin(first int, now time.Time) {
	if g.State != VersusSetup {
		return
	}
	g.State, g.Active, g.Turn, g.Began = VersusRunning, first, now, now
}

// Press is a player hitting their button: it ends their turn (adding the
// increment) and starts the opponent's.
func (g *VersusGame) Press(now time.Time) {
	if g.State != VersusRunning {
		return
	}
	g.Left[g.Active] = g.Remaining(g.Active, now) + g.Inc
	g.Moves[g.Active]++
	g.Active = 1 - g.Active
	g.Turn = now
}

func (g *VersusGame) Pause(now time.Time) {
	if g.State != VersusRunning {
		return
	}
	g.Left[g.Active] = g.Remaining(g.Active, now)
	g.State = VersusPaused
}

func (g *VersusGame) Resume(now time.Time) {
	if g.State == VersusPaused {
		g.State, g.Turn = VersusRunning, now
	}
}

// Elapsed is the wall time since the game began (zero in setup).
func (g *VersusGame) Elapsed(now time.Time) time.Duration {
	if g.Began.IsZero() {
		return 0
	}
	return now.Sub(g.Began)
}

// Tick checks for a flag fall; it reports the loser once.
func (g *VersusGame) Tick(now time.Time) (flagged bool, player int) {
	if g.State != VersusRunning || g.Remaining(g.Active, now) > 0 {
		return false, 0
	}
	g.Left[g.Active] = 0
	g.Flagged, g.State = g.Active, VersusFlag
	return true, g.Flagged
}

// Reset returns to setup with the same time control; it reports a history
// event when a game had been played.
func (g *VersusGame) Reset(now time.Time, label string) []Event {
	var ev []Event
	if g.State != VersusSetup && !g.Began.IsZero() && g.Moves[0]+g.Moves[1] > 0 {
		ev = []Event{{Kind: "versus", Label: label, Start: g.Began, Actual: now.Sub(g.Began), Completed: g.State == VersusFlag}}
	}
	*g = *NewVersus(g.Total, g.Inc, g.Delay)
	return ev
}
