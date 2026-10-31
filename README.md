Here’s everything CS2 Bomb Lights v1.6 does.

Lighting effects

Effect	What you see	When
Bomb countdown	Blinks in your chosen color (red by default), once per C4 beep	Bomb planted
Bomb defused	The countdown stops and a green burst plays	Bomb defused
Bomb exploded	The countdown stops and normal lighting comes back	Bomb explodes
Hit flash	A red pulse; bigger hits flash harder	You take damage
Death	A red jolt, then dim grey while you’re dead	You die; clears next round
Flashbang	White that fades as your screen clears	You get flashed
Smoke	A grey haze	You’re standing in a smoke
Headshot	A gold burst spreading from the middle of the keyboard	Headshot kill
Kill	A white burst spreading from the middle	Kill that isn’t a headshot
Hit marker	A short icy-white tick, brighter for bigger hits	You damage someone without killing them
Round won	A sweep across your keys in your team color (CT blue, T orange)	Your team wins the round
When several effects happen at once, they stack. A flashbang shows on top of everything, and the bomb countdown shows over the round-end effects.
In menus, between maps, and when nothing is happening, your normal iCUE lighting shows.

Bomb timing

The blinks follow the C4 beep formula you found, from one beep a second down to about 6–7 a second, with no drift over the 40 seconds.
When you plant, the lights start the moment the C4 leaves your hands, skipping the delay CS2 adds to its plant report.
For teammates’ plants, the program shifts the blinks to line up with the beeps, using the delay it measured on your own plants.
If you drop the C4 after holding it out for a while, the lights may flash briefly; they cancel within 1.5 seconds.
If CS2 stops sending updates mid-countdown, the flashing stops on its own after 45 seconds.

Setup it handles for you

Finds CS2 in any of your Steam libraries and writes the game-state config CS2 needs.
Pulls the Corsair SDK file out of the iCUE SDK zip in your Downloads folder, or next to the exe.
Starts CS2 through Steam if it isn’t already running.
Closes itself and hands your lighting back to iCUE when you quit CS2.
Puts your lighting back to normal when you close the window or press Ctrl+C.
Won’t run twice at the same time.

Included files

CS2BombLights.exe, the program. Nothing else to install.
Test Lights.bat, a menu that plays each effect, or all of them, without CS2.
Debug Mode.bat, which starts the program and shows what CS2 sends about you: health, kills, headshots, damage, flash and smoke.
README.txt with setup, options and troubleshooting, plus the full source code.

Options

Add these to the shortcut’s Target box.

Option	What it does
--only-mine	The bomb countdown only plays for your own plants, not teammates’
--color FF6A00	Bomb flash color as a hex code
--no-hit, --no-death, --no-flash, --no-smoke, --no-headshot, --no-kill, --no-hitmarker, --no-win, --no-defuse	Turn individual effects off
--test <effect>	Play one effect, or all, without CS2
--debug	Show what CS2 sends about you
--no-launch	Don’t start CS2; wait for it instead
--stay	Keep running after CS2 closes
--offset 250	Fixed delay to assume for teammates’ plants, in milliseconds
--bomb-timer 40	Bomb timer in seconds, for servers that change it
--port 3001	Use a different local port if 3000 is taken

Built-in warnings

iCUE isn’t running or its SDK setting is off.
The Corsair SDK file is missing, or the Visual C++ runtime it needs isn’t installed.
The port is already in use.
CS2 isn’t sending your health and kill data, with a prompt to restart CS2 through the program.
CS2 couldn’t be found, in which case it saves the config next to the exe for you to copy over.

The program only listens on your own PC and only accepts updates carrying its own config’s token. It reads what CS2 already sends through Valve’s official game-state feature and never touches the game itself.

Still open

Kills, headshots and hits not lighting up in real matches: run Debug Mode.bat and check the output.
Hit markers need CS2 to send a damage number. If Debug Mode shows dmg=-1, CS2 doesn’t send it and hit markers won’t work.
The fades assume iCUE blends partly transparent colors smoothly. If they look like hard on/off switches, tell me and I’ll change how they’re drawn.
I haven’t built the no-window system-tray version I offered earlier. Say the word if you want it.




Task #2
Task #3
Task #4
Task #5
Switch the flash timing to the C4 beep formula
Verify every pulse against the formula
Rebuild and deliver the updated zip
Cut the plant-to-lights delay
Retest and redeliver v1.2
Detect your own plant instantly
Test the instant detection and redeliver v1.3
Add the new lighting effects
Add a per-effect test mode and a test menu
Test everything and deliver v1.4
CS2BombLights.zip
Closing tab
Web search
4 searches
Downloaded CS2BombL
