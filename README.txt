CS2 Bomb Lights
===============
Flashes your Corsair iCUE lighting when the bomb is planted in Counter-Strike 2.
The lights blink once per C4 beep, using the beep spacing from the game's code:

    time between beeps = max(0.1 + 0.9 x time left / bomb timer, 0.15 s)

That's one blink a second at the plant, speeding up to about 6-7 a second at the
end (99 blinks over a 40-second bomb). Your normal lighting comes back when the
bomb is defused, explodes, or the round resets.

OTHER EFFECTS
  Hit flash      A red pulse when you take damage. Bigger hits flash harder.
  Death          A red jolt, then dim grey while you're dead. Clears on the
                 next round or when you're alive again.
  Flashbang      White, fading exactly as CS2 says your screen clears.
  Smoke          A grey haze while you're standing in a smoke.
  Headshot       A gold burst spreading out from the middle of the keyboard.
  Kill           A white burst for kills that aren't headshots.
  Hit marker     A short icy-white tick each time you damage someone without
                 killing them.
  Round won      A sweep across your keys in your team color (CT blue,
                 T orange). Nothing happens when you lose.
  Bomb defused   A green burst when the countdown stops.
  If several happen at once they stack. A flashbang shows on top of
  everything, and the bomb countdown shows over the round-end effects.

HOW FAST IT REACTS
  Your plants:      instantly. CS2 deliberately reports "bomb planted" to
                    players a moment late (about a quarter second) so it can't
                    be used as an exact bomb timer. So the program doesn't wait
                    for that report: it reacts the moment the C4 leaves your
                    hands, and uses CS2's report only to confirm.
  Teammates' plants: as soon as CS2 reports them, which is that quarter second
                    late. There's no way around that delay. From the second
                    beep on, the blinks are still lined up with the beeps,
                    using the delay measured on your own plants.

This is the PowerShell script from before, rebuilt as a normal Windows program.
It needs nothing extra installed: it runs on the .NET Framework that comes with
Windows 10 and 11.


FIRST-TIME SETUP
----------------
1. In iCUE, open Settings and turn on the iCUE SDK option.

2. Leave iCUESDK_4.0.84.zip in your Downloads folder (it was downloaded from
   Corsair's GitHub page), or put it next to CS2BombLights.exe. On first run the
   program pulls iCUESDK.x64_2019.dll out of the zip by itself. After that the
   zip can be deleted.

3. Double-click "Test Lights.bat". It opens a menu where you can play each
   effect (bomb countdown, hit, death, flashbang, smoke, headshot, kill, hit
   marker, round won, bomb defused) or all of them in a row. CS2 doesn't need to be running.

4. Close Aurora and the old PowerShell script if either is still running. Two
   programs controlling iCUE through the SDK at once will fight.


EVERY TIME YOU PLAY
-------------------
Start CS2 by double-clicking CS2BombLights.exe instead of pressing Play in Steam.
It will:
  - write the game-state config into CS2's cfg folder (it finds your Steam
    library by itself; this replaces the .cfg from the PowerShell version),
  - connect to iCUE,
  - start CS2 through Steam,
  - close by itself, and hand your lighting back to iCUE, when you quit CS2.

If CS2 is already open, the program attaches to it instead. Whenever the
program updates the config (first run, or after an update like this one),
CS2 needs a restart to read it. Starting CS2 through the program avoids that.

Tip: right-click CS2BombLights.exe > Send to > Desktop (create shortcut), then
pin that shortcut to Start or the taskbar. In the shortcut's Properties you can
set "Run" to Minimized if you don't want to see the window.


OPTIONS
-------
Add these after the exe name in the shortcut's Target box, for example:
  "C:\Games\CS2BombLights\CS2BombLights.exe" --only-mine --color FF6A00

  --only-mine       Only flash when YOU plant, not when a teammate does.
  --color FF6A00    Flash color as a hex code. Default FF0000 (red).
  --debug          Show what CS2 sends about you, to troubleshoot effects.
  --test hit        Play one effect without CS2, then exit: bomb (default), hit,
                    death, flash, smoke, headshot, kill, hitmarker, win,
                    defuse, or all.
  --no-hit          Turn an effect off. Also --no-death, --no-flash,
                    --no-smoke, --no-headshot, --no-kill, --no-hitmarker,
                    --no-win, --no-defuse.
  --no-launch       Don't start CS2, just wait for it.
  --stay            Keep running after CS2 closes.
  --port 3001       Use a different local port (default 3000). The CS2 config
                    is updated to match automatically.
  --offset 250      For teammates' plants only: how late CS2 reports them, in
                    milliseconds. Normally you don't need this, because it's
                    measured from your own plants (250 until your first plant).
                    Setting it fixes the value instead.
  --bomb-timer 40   Bomb timer in seconds, for community servers that change
                    mp_c4timer. Default 40.

The old PowerShell-style switches (-OnlyMyPlants, -Color, -Test) also work.


IF SOMETHING GOES WRONG
-----------------------
"Windows protected your PC"
    Windows warns about any new program downloaded from the internet that
    isn't signed. Click "More info" > "Run anyway". Or right-click the exe >
    Properties > tick "Unblock" > OK.

An effect works in Test Lights but not in a match
    Run "Debug Mode.bat" instead of the exe (it starts CS2 the same way).
    The window shows what CS2 sends about you: health, kills, headshots,
    flash and smoke amounts. If it says "state=MISSING", CS2 is still using
    an old config: close CS2 and start it again through the program.

"Could not connect to iCUE"
    Make sure iCUE is running and the iCUE SDK option is on in its settings.

"Could not load ... (Win32 error 126)"
    Install the Microsoft Visual C++ 2015-2022 x64 runtime:
    https://aka.ms/vs/17/release/vc_redist.x64.exe

"Could not find the iCUE SDK"
    Download iCUESDK_4.0.84.zip from
    https://github.com/CorsairOfficial/cue-sdk/releases and put it in Downloads
    or next to the exe.

"Could not listen on port 3000"
    Something else is using that port (the old PowerShell script, for
    example). Close it, or run with --port 3001.

Lights don't flash in a real match
    Restart CS2 once after the first run so it loads the config, and check
    that the window says "Listening for CS2".

Your own plant still shows a delay
    Check the window. After each of your plants it should say "You planted the
    bomb!" first and then "CS2 reported your plant ... ms after it happened". If
    it only says "Bomb planted by you!", the instant detection didn't kick in
    for that plant, and the lights waited for CS2's late report.

Brief flash when you drop the C4
    If you hold the C4 out for 2.5+ seconds and then drop it, that looks like a
    plant for a moment. The program cancels the flash after 1.5 seconds when
    CS2 doesn't confirm a plant.

A teammate's plant: the first blink is late
    Expected: CS2 reports other players' plants a moment late on purpose.


SAFETY
------
- CS2 sends updates through Game State Integration, Valve's own official
  feature. Nothing touches the game's memory or files other than the one
  config file, so it doesn't affect VAC.
- The program only listens on 127.0.0.1 (this PC), so nothing on your network
  can reach it, and it ignores updates that don't carry the config's token.
- It only writes two things: the .cfg in CS2's cfg folder and the extracted
  SDK DLL in %LOCALAPPDATA%\CS2BombLights.


UNINSTALL
---------
Delete CS2BombLights.exe, the %LOCALAPPDATA%\CS2BombLights folder, and
gamestate_integration_icue_bomb.cfg from
...\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg


The full source code is in the "source" folder.
