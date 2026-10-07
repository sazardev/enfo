# Enfo TUI — project memory

Living notes for whoever (person or agent) works on `tui/` next: how it is put together, the decisions
that are not obvious from the code, the traps already hit, and what has **not** been verified. The
Flutter app has its own notes in the repo-root `MEMORY.md`; `README.md` here is the user-facing doc.

Current version: **0.1.0** (Makefile `VERSION`, PKGBUILD `pkgver`; the binary prints it with `enfo version`).
Released from the same repo as the app but versioned independently: tag `tui-vX.Y.Z`.

## 1. What it is

A terminal sibling of the Enfo app: Pomodoro, clock, timer, stopwatch, alarms, world clock, breathing
(core, on by default) plus intervals, kitchen, event, breaks, sleep, tracker, versus (extras, off by
default), stats and settings pages, a first-run welcome wizard, and a CLI. Everything is drawn with
braille dots, animated, responsive from 24x7 to huge terminals. Go module `github.com/sazardev/enfo/tui`,
Charm **v2** stack (`charm.land/bubbletea/v2`, `lipgloss/v2`, `bubbles/v2`, `huh/v2`, `fang/v2`,
`glamour/v2`, `wish/v2`, `log/v2`, plus `github.com/charmbracelet/harmonica`).

## 2. Layout

```
cmd/enfo            main: version/commit via ldflags (-X main.version=…), cobra + fang
internal/braille    Canvas (2x4 dots per cell, one RGB per cell), shapes, 3 big-digit fonts (line, led, seg)
internal/visual     timer faces (ring orbit hourglass liquid radar spiral bars), clock designs, Mark (logo), breathing
internal/engine     pure logic, timestamp-driven: pomodoro timer stopwatch alarm breathe sun cities stats intervals
                    kitchen versus breaks tracker clock_sun
internal/store      Config (config.json), State (state.json), history.jsonl; XDG dirs, atomic writes
internal/ui         Core (shared state) + App (root model) + one file group per mode/page
internal/worldmap   720x360 land mask (go:embed land.bin) + box-filter sampler; tools/genmap regenerates it
internal/i18n       en/es tables + help markdown; tests enforce completeness and that used keys exist
internal/cli        cobra commands: status stats config doctor wake serve + mode shortcuts
internal/wake       detached background waker (setsid) so notifications fire after the TUI is closed
internal/serve      `enfo serve`: the app over SSH (Wish), one store per key fingerprint
internal/notify     notify-send + freedesktop sounds (paplay/pw-play/aplay); ENFO_QUIET=1 disables
demo/demo.tape      VHS tape -> demo/enfo.gif (make demo);  docs/*.png are README screenshots
```

## 3. Decisions worth knowing

- **Nothing ticks.** Engines store absolute instants (`EndsAt`, `Started`, `NextAt`) and are asked what is
  true at `now`; exact while hidden, restart-proof, readable by `enfo status`. `Core.Step(now, dt)` runs every
  frame for every engine; whatever finished comes out as `Announce` and the App turns it into toast +
  desktop notification + sound (+ the full-screen ringer when `Ring`).
- **Catch-up:** things that finished while Enfo was closed are logged (`Event.Late`) and summarised in one
  "welcome back" toast, never rung one by one.
- **Frame loop:** one `tickMsg`; 30 fps while something animates (15 in `calm`, 10 in `still`), 10 fps otherwise,
  2 fps when the terminal lost focus. A 250x70 frame costs ~1-3 ms.
- **Modes register themselves** (`registerMode` / `registerPage` in `init()`); `Cfg.Modes` is the enabled list in
  tab order, digits 1-9 jump by *position*. A mode that must keep running while another tab is open implements
  `Background` (`Step`, `Runner`); `Capturer` tells the app that every key belongs to the mode (text input, editors).
  A mode opened by name (`enfo kitchen`) survives `reloadModes` even if switched off.
- **Config changes** go through `Core.ApplyConfig()` (re-theme, re-language, rhythm, tabs reload, file saved).
  The terminal background is queried once (`tea.BackgroundColorMsg`) and drives the palette's dark/light.
- **Colors:** one accent (24 named swatches, same family as the app); everything else derives in `theme.New`
  (rest hue = accent shifted +150°). A braille cell has one color, so gradients/glows/fades are per cell.
- **Splash:** plays on every open (animated logo, any key skips); configurable (`Settings → Look & motion`,
  `--no-splash`, `"splash": false` in config.json). First run goes splash → welcome wizard.
- **Chrome:** 2-row header (tabs + animated underline spring) + 1-row footer (bubbles/help + chips for timers
  running in other tabs). `f` zen hides both. Pages (stats, settings) replace the body; the welcome wizard is
  chromeless. Toasts/help are Lip Gloss layers composed over the screen.
- **Beep:** modes call `Core.Beep(name)`; the app converts the bell into `tea.Raw("\a")` (so it also works over SSH).
- **Wakers:** on quit the CLI hook spawns `enfo wake --at …` for the running phase/timer/alarms; the next start
  kills stale ones (PIDs in state.json). They only signal PIDs whose /proc cmdline looks like `enfo wake`.
- **i18n:** English + Spanish ("tú"); every mode adds `mode.<id>` and `help.mode.<id>` (the help overlay assembles
  the manual from the enabled modes). Add a language = a table file + a line in `Languages`.

## 4. Traps already hit

- **Emoji-presentation glyphs** (⏰ ⏱ ⏲ ⌚ 🔔 🔥) are measured narrow and drawn wide by many terminals and shear the
  layout; ambiguous-width ones (◍ ✎) also misbehaved. Icons are constants in `ui/mode.go` (`icon*`); the CLI's
  Waybar output may use emoji (Pango handles them).
- **`ansi.Cut` re-slicing grows strings exponentially** (every skipped SGR is kept). `ui.stamp` therefore re-parses the
  line into styled cells; do not chain `ansi.Cut` to overlay text.
- **`engine.Stopwatch` zero value has `Run == ""`**, not `Idle`: test `Running || Paused`, never `!= Idle`.
- **Cell aspect:** braille dots are square only when a cell is ~2x as tall as wide. VHS screenshots need
  `Set LineHeight 1.25` or circles look like ellipses; real terminals are usually 2.0-2.3.
- Times loaded from state.json can carry another zone; format with `.In(c.Now.Location())`.
- `huh` forms need their commands run by the host; app.go forwards unknown messages to the open page / capturing mode.
- Line-font glyphs `2` and `3` were wrong twice (open the glyph test: `GLYPHS=1 go test ./internal/braille -run Glyphs -v`).
- go.mod says `go 1.25`; the toolchain here was 1.27.

## 5. How to verify without a GUI

- `go test ./...` (render matrices 1x1..250x70 for every mode, engine logic, i18n, CLI parsers, wake, serve) and `go vet`.
- **VHS works** (vhs + ttyd + ffmpeg installed): write a tape (see `demo/demo.tape`), `Screenshot "x.png"`, read the PNG.
  Seed state with a state.json (running pomodoro) and `ENFO_CONFIG_DIR` / `ENFO_STATE_DIR` temp dirs.
- tmux smoke test: `tmux new-session -d -x 80 -y 24 ./enfo`, `send-keys`, `capture-pane -p`, `resize-window`.
  (tmux never answers the background-colour query, VHS/ttyd does: bugs in config reloads show only under VHS.)

## 6. Ways to extend

- **New mode:** `internal/engine/<id>.go` (timestamp-driven) + `internal/ui/<id>.go` with `registerMode`, i18n
  `mode.<id>`/`help.mode.<id>` in `en_<id>.go` + `es_<id>.go`, an entry in `Infos` (`mode.go`), tests (render matrix).
  Persist its own data as `<id>.json` in `Store.StateDir`; log history with `c.Log(engine.Event{Kind: engine.Kind("<id>")…})`.
- **New timer face:** a `Visual` in `internal/visual`, add it to `Dials`; it receives a `Frame` and a Canvas.
- **New accent:** add to `theme.Accents`.
- Prefix every package-level identifier with the mode's name (many modes share package `ui`).

## 7. NOT verified — check on a real machine

- How big/dense braille dots look in your terminal font (all screenshots are VHS/ttyd renders).
- Light-terminal palette (only unit-rendered), 16/256-color terminals (Bubble Tea downsamples; never looked at).
- Real sound + `notify-send` delivery, wakers surviving a real logout, `enfo serve` beyond one key login,
  macOS/BSD (`/proc`-based waker checks are Linux-only), Windows.
- Textinput cursor blink (works only where the app forwards the blink messages), mouse hit-areas on a live terminal.
- The Spanish copy was written by the model, never reviewed by a native speaker.
- Quiet hours for Breaks, per-hour stats in other time zones, polar-region sun times beyond the tested cases.
