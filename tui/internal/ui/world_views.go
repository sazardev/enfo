package ui

import (
	"fmt"
	"strings"
	"time"

	"github.com/sazardev/enfo/tui/internal/engine"
	"github.com/sazardev/enfo/tui/internal/i18n"
)

// pickerView is the "add a city" screen: a search field over a live list.
func (m *worldMode) pickerView(w, h int) []string {
	pal := m.c.Pal
	lang := i18n.Lang()
	pw := clampi(w-4, 20, 64)
	m.input.SetWidth(maxi(pw-6, 4))

	rows := clampi(h-6, 1, 14)
	if m.pickSel < m.pickTop {
		m.pickTop = m.pickSel
	}
	if m.pickSel >= m.pickTop+rows {
		m.pickTop = m.pickSel - rows + 1
	}

	have := map[string]bool{}
	for _, id := range m.c.Cfg.Cities {
		have[id] = true
	}

	block := []string{
		bold(pal.Accent, "✦ "+i18n.T("world.add.title")) + paint(pal.Faint, fmt.Sprintf("  %d", len(m.pick))),
		m.input.View(),
		paint(pal.Faint, strings.Repeat("⣀", pw)),
	}
	if len(m.pick) == 0 {
		block = append(block, paint(pal.Muted, i18n.T("world.add.none")))
	}
	now := m.c.Now
	for i := m.pickTop; i < len(m.pick) && i < m.pickTop+rows; i++ {
		c := m.pick[i]
		t := now.In(m.loc(c))
		name := c.Name(lang)
		timeS := m.timeText(t)
		zonew := pw - 2 - 2 - width(timeS) - 2
		namew := mini(zonew, 22)
		if namew < 4 {
			namew = 4
		}
		if r := []rune(name); len(r) > namew {
			name = string(r[:namew-1]) + "…"
		}
		mark := "  "
		if have[c.ID] {
			mark = paint(pal.Good, "✓ ")
		}
		line := ""
		zone := paint(pal.Faint, c.ID)
		if i == m.pickSel {
			line = bold(pal.Accent, "▸ ") + mark + bold(pal.Text, padRight(name, namew)) + " " + padRight(zone, maxi(zonew-namew-1, 0))
			line += " " + bold(pal.Bright, timeS)
		} else {
			line = "  " + mark + paint(pal.Muted.Mix(pal.Text, 0.4), padRight(name, namew)) + " " + padRight(zone, maxi(zonew-namew-1, 0))
			line += " " + paint(pal.Muted, timeS)
		}
		block = append(block, padRight(line, pw))
	}
	block = append(block, "", paint(pal.Faint, i18n.T("world.add.hint")))
	return centerBlock(block, w, h)
}

// plannerView compares the working hours of every city on one 24 h strip.
func (m *worldMode) plannerView(w, h int) []string {
	pal := m.c.Pal
	lang := i18n.Lang()
	cities := m.cities()
	if len(cities) == 0 {
		return blank(w, h)
	}
	m.clampSel(len(cities))
	now := m.c.Now.UTC()
	day := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	curUTC := day.Add(time.Duration(m.planHour) * time.Hour)

	nameW := 8
	for _, c := range cities {
		if x := width(c.Name(lang)); x > nameW {
			nameW = x
		}
	}
	nameW = mini(nameW, 16)
	timeW := 8
	avail := w - 2 - nameW - 1 - timeW - 2
	cellW := clampi(avail/24, 1, 4)
	narrow := avail < 24
	stripW := 24 * cellW

	local := func(c engine.City, u int) time.Time {
		return day.Add(time.Duration(u) * time.Hour).In(m.loc(c))
	}
	working := func(c engine.City, u int) bool { hr := local(c, u).Hour(); return hr >= 9 && hr < 18 }
	awake := func(c engine.City, u int) bool { hr := local(c, u).Hour(); return hr >= 7 && hr < 22 }

	var lines []string
	title := bold(pal.Accent, "✦ "+i18n.T("world.plan.title"))
	right := paint(pal.Muted, "UTC ") + bold(pal.Text, fmt.Sprintf("%02d:00", m.planHour))
	lines = append(lines, " "+title+spaces(maxi(w-2-width(title)-width(right), 1))+right)
	lines = append(lines, "")

	stripX := 2 + nameW + 1
	m.listX, m.listY, m.listW = stripX, 0, stripW
	if !narrow {
		// hour labels and the cursor marker
		lab := []rune(spaces(stripW + 4))
		step := 3
		if cellW < 2 {
			step = 6
		}
		for u := 0; u < 24; u += step {
			for i, r := range fmt.Sprintf("%02d", u) {
				if p := u*cellW + i; p < len(lab) {
					lab[p] = r
				}
			}
		}
		lines = append(lines, spaces(stripX)+paint(pal.Muted, string(lab)))
		cur := []rune(spaces(stripW + 2))
		if p := m.planHour*cellW + cellW/2; p < len(cur) {
			cur[p] = '▾'
		}
		lines = append(lines, spaces(stripX)+bold(pal.Accent, string(cur)))
	}

	// rows (scroll so the selection stays visible)
	room := h - len(lines) - 4
	if room < 1 {
		room = 1
	}
	first := 0
	if m.sel >= room {
		first = m.sel - room + 1
	}
	for i := first; i < len(cities) && i < first+room; i++ {
		c := cities[i]
		sel := i == m.sel
		lt := local(c, m.planHour)
		// the local time at the cursor, with the minutes of the real offset
		lc := curUTC.In(m.loc(c))
		timeS := m.timeText(lc)
		name := c.Name(lang)
		if r := []rune(name); len(r) > nameW {
			name = string(r[:nameW-1]) + "…"
		}
		var nameS string
		if sel {
			nameS = bold(pal.Accent, "▸ ") + bold(pal.Text, padRight(name, nameW))
		} else {
			nameS = "  " + paint(pal.Muted.Mix(pal.Text, 0.4), padRight(name, nameW))
		}
		if narrow {
			lines = append(lines, padRight(" "+nameS+" "+paint(pal.Text, timeS), w))
			continue
		}
		var sb strings.Builder
		for u := 0; u < 24; u++ {
			var ch string
			var col = pal.Faint
			switch {
			case working(c, u):
				ch, col = "⣿", pal.Accent
				if sel {
					col = pal.Bright
				}
			case awake(c, u):
				ch, col = "⣤", pal.Muted
			default:
				ch, col = "⠒", pal.Faint
			}
			if u == m.planHour {
				col = pal.Text
			}
			sb.WriteString(paint(col, strings.Repeat(ch, cellW)))
		}
		icon := paint(pal.Moon, "☾")
		if hr := lt.Hour(); hr >= 7 && hr < 19 {
			icon = paint(pal.Sun, "☼")
		}
		tcol := pal.Muted.Mix(pal.Text, 0.55)
		if sel {
			tcol = pal.Bright
		}
		lines = append(lines, padRight(" "+nameS+" "+sb.String()+"  "+icon+" "+paint(tcol, timeS), w))
	}

	if !narrow {
		// overlap row
		var sb strings.Builder
		best, bestLen, runStart, runLen := -1, 0, 0, 0
		for u := 0; u < 48; u++ { // wrap once to catch runs across midnight
			all := true
			for _, c := range cities {
				if !working(c, u%24) {
					all = false
					break
				}
			}
			if all {
				if runLen == 0 {
					runStart = u
				}
				runLen++
				if runLen > bestLen && runLen <= 24 {
					best, bestLen = runStart, runLen
				}
			} else {
				runLen = 0
			}
		}
		for u := 0; u < 24; u++ {
			allWork, allAwake := true, true
			for _, c := range cities {
				allWork = allWork && working(c, u)
				allAwake = allAwake && awake(c, u)
			}
			ch, col := "⠒", pal.Faint
			switch {
			case allWork:
				ch, col = "⣿", pal.Good
			case allAwake:
				ch, col = "⣤", pal.Warn
			}
			if u == m.planHour {
				col = pal.Text
			}
			sb.WriteString(paint(col, strings.Repeat(ch, cellW)))
		}
		lines = append(lines, "")
		lab := paint(pal.Good, padRight("✦ "+i18n.T("world.plan.overlap"), 2+nameW))
		lines = append(lines, padRight(" "+lab+" "+sb.String(), w))
		home := cities[0]
		var summary string
		if bestLen > 0 {
			a := day.Add(time.Duration(best) * time.Hour).In(m.loc(home))
			b := a.Add(time.Duration(bestLen) * time.Hour)
			summary = paint(pal.Good, i18n.T("world.plan.best", m.shortTime(a), m.shortTime(b), home.Name(lang)))
		} else {
			summary = paint(pal.Warn, i18n.T("world.plan.none"))
		}
		legend := paint(pal.Accent, "⣿ ") + paint(pal.Muted, i18n.T("world.work")) + "   " +
			paint(pal.Muted, "⣤ "+i18n.T("world.awake")) + "   " + paint(pal.Faint, "⠒ "+i18n.T("world.sleep"))
		lines = append(lines, padRight(" "+spaces(2+nameW)+" "+summary, w))
		lines = append(lines, padRight(" "+spaces(2+nameW)+" "+legend, w))
	}
	return centerBlock(lines, w, h)
}
