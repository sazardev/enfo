# Renders demo/enfo.gif:   vhs demo/demo.tape   (from the tui/ directory, with `enfo` built to ./enfo or on PATH)
Output demo/enfo.gif
Set Shell "bash"
Set FontSize 15
Set Width 1400
Set Height 820
Set Padding 12
Set LineHeight 1.25
Set Framerate 30
Set PlaybackSpeed 1

Hide
Type "export ENFO_CONFIG_DIR=$(mktemp -d) ENFO_STATE_DIR=$(mktemp -d) ENFO_QUIET=1 COLORTERM=truecolor"
Enter
Type `echo '{"onboarded":true,"splash":true,"modes":["pomodoro","clock","timer","stopwatch","alarm","world","breathe","intervals"]}' > $ENFO_CONFIG_DIR/config.json`
Enter
Type "clear"
Enter
Show

Type "enfo"
Enter
Sleep 3s

# start a focus session and flip through the dials
Type " "
Sleep 2s
Type "d" Sleep 2s
Type "d" Sleep 2s
Type "d" Sleep 2s
Type "d" Sleep 2s
Type "d" Sleep 1500ms

# the other tools
Type "2" Sleep 3s
Type "d" Sleep 2s
Type "d" Sleep 2s
Type "6" Sleep 3s
Type "7" Sleep 4s
Type "d" Sleep 3s
Type "d" Sleep 3s
Type "3" Sleep 1500ms

Type "?" Sleep 2500ms
Type "q" Sleep 500ms
Type "q"
Sleep 500ms
