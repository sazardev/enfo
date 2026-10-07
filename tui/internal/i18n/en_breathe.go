package i18n

func init() {
	for k, v := range map[string]string{
		"breathe.inhale":           "INHALE",
		"breathe.exhale":           "EXHALE",
		"breathe.hold.full":        "HOLD",
		"breathe.hold.empty":       "HOLD",
		"breathe.start":            "begin",
		"breathe.stop":             "stop",
		"breathe.pattern":          "rhythm",
		"breathe.style":            "style",
		"breathe.goal":             "goal",
		"breathe.free":             "free session",
		"breathe.goal.is":          "goal: %s",
		"breathe.breath":           "breath %d",
		"breathe.press":            "press space to begin",
		"breathe.done":             "Session complete",
		"breathe.done.body":        "%s · %d breaths. Well done",
		"breathe.pattern.box":      "Box",
		"breathe.pattern.478":      "Relax",
		"breathe.pattern.coherent": "Coherent",
		"breathe.pattern.calm":     "Calm",
		"breathe.style.orb":        "orb",
		"breathe.style.flower":     "flower",
		"breathe.style.waves":      "waves",
		"breathe.style.box":        "box",
		"help.mode.breathe":        helpBreatheEN,
	} {
		en[k] = v
	}
}

const helpBreatheEN = `## Breathe

Follow the shape: it grows as you breathe in, rests while you hold, and settles as you breathe out.

| Key | Action |
| --- | --- |
| ` + "`space`" + ` | begin / stop the session |
| ` + "`p`" + ` | next rhythm: box 4-4-4-4, relax 4-7-8, coherent 5-5, calm 4-6 |
| ` + "`d`" + ` | next visual: orb, flower, waves, box |
| ` + "`+`" + ` ` + "`-`" + ` | session goal: free, 1, 3, 5, 10 minutes |

Sessions of 30 seconds or more are saved to your history. Press ` + "`f`" + ` for zen: just the art.
`
