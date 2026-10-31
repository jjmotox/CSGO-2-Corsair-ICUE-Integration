# CS2 Bomb Lights

Drives Corsair iCUE RGB lighting from Counter-Strike 2 game events. The headline feature is a C4 countdown that blinks on every bomb beep, using the beep schedule from the game's own code. It also reacts to hits, deaths, flashbangs, smokes, kills, headshots, round wins and defuses.

It is a single standalone Windows exe (C#, .NET Framework 4.8, no NuGet packages and no installer). It reads game state through Valve's official **Game State Integration** (GSI) and drives the lighting through Corsair's official **iCUE SDK v4**. It never touches game memory or files, apart from the one GSI config file it installs.

> Not affiliated with Valve or Corsair. Counter-Strike and iCUE are trademarks of their respective owners.

---

## Features

| Effect | Trigger (GSI field) | Look |
|---|---|---|
| Bomb countdown | `round.bomb = planted` / C4 leaving your inventory | Blink per C4 beep, in the configured color |
| Bomb defused | `round.bomb` `planted → defused` | Green burst |
| Hit flash | `player.state.health` drops | Red pulse scaled by damage |
| Death | `health → 0`, or spectating while the round is live | Red jolt, then grey while dead |
| Flashbang | `player.state.flashed` (0–255) | White, alpha = flash amount |
| Smoke | `player.state.smoked` (0–255) | Grey haze |
| Headshot | `player.state.round_killhs` increments | Gold ring from the device center |
| Kill | `round_kills` increments without a headshot | White ring |
| Hit marker | `player.state.round_totaldmg` increments without a kill | Short icy-white tick |
| Round won | `round.phase → over` and `win_team == your team` | Left-to-right sweep in team color |

Every effect except the countdown can be disabled with `--no-<name>`. When several happen at once they stack (see [Rendering](#rendering)).

---

## Quick start (users)

1. In iCUE, enable the **iCUE SDK** setting.
2. Get `iCUESDK_4.0.84.zip` from [CorsairOfficial/cue-sdk releases](https://github.com/CorsairOfficial/cue-sdk/releases). Leave it in Downloads or next to the exe; the program extracts `redist/x64/iCUESDK.x64_2019.dll` on first run.
3. Run `Test Lights.bat` to try each effect without CS2.
4. Launch CS2 **through `CS2BombLights.exe`**. It installs the GSI config, starts CS2 via `steam://rungameid/730`, and exits when CS2 closes.

The exe is unsigned, so SmartScreen will warn on first run. Use **More info → Run anyway**, or `Unblock-File`.

---

## Architecture

Everything lives in `src/CS2BombLights.cs` (~1,900 lines). It is one file on purpose, so the build is a single `csc` call.

```
 CS2 ──HTTP POST (GSI JSON)──▶ GsiServer ──▶ BombTracker ──▶ Icue (renderer) ──▶ iCUE SDK ──▶ LEDs
        127.0.0.1:3000          TCP, serial   state machine    5 ms timer,       P/Invoke
                                              + effect triggers layered frames
```

| Class | Responsibility |
|---|---|
| `Program` | Entry point, startup sequence, test mode, console close handling, single-instance mutex |
| `Options` | CLI parsing (accepts `--x`, `-X`, `/x`, `--x=v`, and the old PowerShell-style switches) |
| `GsiServer` | Minimal HTTP/1.1 server on `TcpListener(IPAddress.Loopback)` |
| `BombTracker` | Turns successive GSI snapshots into events (plant prediction, hits, kills, deaths, round end) |
| `Icue` | iCUE SDK P/Invoke wrapper, plus the frame renderer and all effect state |
| `Fx` | Enabled/disabled effect set |
| `SteamSetup` | Finds Steam via the registry, parses `libraryfolders.vdf`, and writes the GSI `.cfg` |
| `SdkLocator` / `MiniZip` | Finds the SDK DLL beside the exe, embedded in it, cached, or inside `iCUESDK*.zip` |
| `Game` | `cs2.exe` process detection and launching through Steam |
| `Json` | ~120-line recursive-descent JSON reader that produces `Dictionary<string, object>` |

### Why no HttpListener?

`HttpListener` goes through http.sys, which needs a URL ACL reservation or admin rights for many prefixes. A raw loopback `TcpListener` needs neither and can't be reached from the network. The server:

- reads headers, then exactly `Content-Length` bytes of body;
- answers `Expect: 100-continue` immediately;
- replies `200` with `Connection: close`, then processes the body;
- handles one connection at a time so updates are processed in the order CS2 sent them. GSI never has two POSTs in flight at once.

It deliberately does **not** set `SO_EXCLUSIVEADDRUSE`. With it, Windows keeps the port blocked through TIME_WAIT (up to 4 minutes) after exit, which breaks quick restarts.

### GSI config

The program writes `gamestate_integration_icue_bomb.cfg` into `<library>\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg`. The cfg is rewritten whenever its contents differ, so it always matches `--port`.

```
"uri"       "http://127.0.0.1:3000"
"timeout"   "5.0"
"buffer"    "0.0"     // don't batch events
"throttle"  "0.0"     // send every change immediately (GSI default is 1.0 s)
"heartbeat" "10.0"
"auth"  { "token" "icue-bomb-flash-7f3a9c" }
"data"  { provider, round, player_id, player_weapons, player_state }
```

Updates whose `auth.token` doesn't match are ignored. CS2 only reads GSI configs at startup, which is why launching CS2 through the program matters.

---

## Bomb timing

### Beep schedule

The interval between C4 beeps, taken from the leaked CS:GO source:

```
interval(t) = max(0.1 + 0.9 × (T − t) / T, 0.15)      t = seconds since plant, T = mp_c4timer (40)
```

That gives 99 beeps over 40 seconds. The renderer advances `_nextBeep` from the *planned* beep times rather than the time each tick actually ran, so timer jitter never builds up into drift. Each blink lasts `min(0.2 s, interval / 2)`. If a beep is shown late (the first one usually is), it still gets a full-length blink, clamped to end before the next beep. If the PC stalls, missed beeps are skipped rather than queued. `timeBeginPeriod(1)` is held while effects run, so Windows wakes the timer within about a millisecond instead of about 16 ms.

### Working around CS2's plant delay

For players (not spectators), CS2 deliberately reports `round.bomb = planted` after a short random delay, so GSI can't be used as an exact bomb timer. The player's own `weapons` list isn't delayed, so `BombTracker` predicts the plant itself:

1. The C4 is the `active` weapon for ≥ 2.5 s (planting takes 3 s).
2. The C4 then disappears from your weapons while `health != 0`.
3. Flashing starts immediately, timed from that moment.
4. When `round.bomb = planted` arrives, it is treated as confirmation, and the gap is recorded as CS2's delay.
5. If no confirmation arrives within 1.5 s, a watchdog timer cancels the flash: the C4 was dropped. A confirmation within 10 s still resumes the flash in sync with the predicted plant time.

Teammates' plants can only be detected from the delayed report. For those, the schedule starts at `secondsSincePlant = average measured delay` (or `--offset`, default 250 ms). Blinks from the second beep on line up with the audio.

`--only-mine` attributes a plant to you if you held the C4 in the previous update or lost it within the last 2 s.

---

## Rendering

`Icue` runs a single `System.Threading.Timer` at 5 ms while any effect is active and stops it when everything is idle. Each tick works out a color for every LED by alpha-compositing the layers in this order, bottom to top:

```
death → smoke → round won → defuse → bomb → hit marker → kill → hit → headshot → flashbang
```

- **Positions.** LED positions from `CorsairGetLedPositions` are normalized to 0–1 per device. Rings are drawn by distance from (0.5, 0.5), and the win sweep by `x`.
- **Change detection.** Each LED's last sent color is packed into a `uint`. A device only gets a `CorsairSetLedColors` call when something changed.
- **Rate limiting.** Bomb on/off edges are sent the moment they're due. Fades are capped at about 60 fps.
- **Layer priority.** The SDK layer sits at `CorsairSetLayerPriority(0)` with fully transparent colors while idle, so normal iCUE lighting shows. It jumps to 255 while any effect is active.
- **Shutdown.** Ctrl+C (`Console.CancelKeyPress`), closing the window (`SetConsoleCtrlHandler`, `CTRL_CLOSE_EVENT`), and normal exit all end with a transparent frame, priority 0, and `CorsairDisconnect`.

### iCUE SDK interop

The struct layouts and signatures match `iCUESDK.h` v4 (`CorsairDeviceInfo` with 128-byte ANSI strings, `CorsairLedColor {uint id; byte r,g,b,a}`, and so on). The DLL is loaded with `LoadLibrary(fullPath)` before the first `[DllImport]`, so it can live anywhere. Win32 error 126 is reported as a missing VC++ 2015–2022 x64 runtime.

---

## Building

The source is C# 5 and references only `mscorlib` and `System`.

**Windows** (uses the compiler that ships with .NET Framework; no Visual Studio needed):

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

**Linux / macOS** (Mono):

```sh
./build.sh        # needs mono-devel (mcs + 4.8-api reference assemblies)
```

Both write `bin/CS2BombLights.exe` (x64, about 95 KB) and copy the `.bat` helpers next to it. If `sdk/iCUESDK.x64_2019.dll` exists, it is embedded as a resource and extracted to `%LOCALAPPDATA%\CS2BombLights` at runtime. The Corsair DLL is not committed to this repo; see `.gitignore`.

---

## Testing

`test/` contains an end-to-end suite that runs the real exe under **Mono on Linux** against a **fake iCUE SDK**:

- `stub_icue.c` implements the iCUE v4 exports with the same struct layouts. It reports two devices, delivers the session-state callback from its own thread, and logs every `SetLedColors` and `SetLayerPriority` call with a millisecond timestamp.
- `run_tests.py` creates a fake Steam install (Mono registry plus `libraryfolders.vdf`), starts the exe with a `dllmap` pointing at the stub, sends crafted GSI JSON over HTTP, and checks the stub's log.

```sh
./build.sh && python3 test/run_tests.py                     # whole suite, about 3 min
python3 test/run_tests.py test_effects_from_cs2             # one group
```

The suite has 98 checks, covering:

- every blink measured against the beep formula over a full bomb (typical error: max ~3 ms, mean ~1 ms over 132 beeps), and pulse lengths;
- instant plant detection, drops, death mid-plant, late confirmation, and reuse of the measured delay;
- every effect's colors and fades, and the `--no-*` switches;
- `--test` for each effect and for `all`;
- HTTP robustness (junk requests, `Expect: 100-continue`, port reuse after exit);
- Ctrl+C in a real pty, and auto-exit when a fake `cs2` process ends;
- SDK extraction from a zip with a CRC check, and the failure paths (no iCUE, no SDK, port in use, no Steam, bad arguments).

**Not covered:** the real .NET Framework runtime on Windows, real Corsair hardware, and the Windows-only calls (`LoadLibrary`, the console close event, `timeBeginPeriod`, `steam://` launching). Those need testing by hand. `Test Lights.bat` and `Debug Mode.bat` exist for that.

---

## CLI

```
CS2BombLights.exe [options]

  --test [effect]    Play an effect without CS2 and exit: bomb (default), hit, death, flash,
                     smoke, headshot, kill, hitmarker, win, defuse, all
  --only-mine        Bomb countdown only for your own plants
  --color RRGGBB     Bomb blink color (default FF0000)
  --no-<effect>      Disable: hit, death, flash, smoke, headshot, kill, hitmarker, win, defuse
  --debug            Log the relevant GSI fields whenever they change
  --no-launch        Don't start CS2; wait for it
  --stay             Keep running after CS2 exits
  --offset <ms>      Fixed report delay for teammates' plants (default: measured, else 250)
  --bomb-timer <s>   mp_c4timer for community servers (default 40)
  --port <n>         Local GSI port (default 3000; the cfg is rewritten to match)
```

Exit codes: `0` success, `1` runtime failure (no iCUE, no SDK, port in use), `2` bad arguments.

---

## Known limitations

- GSI only sends enemy positions, footsteps, other players' health and the exact bomb timer to spectators, so none of those can drive effects while you're playing.
- The beep formula comes from CS:GO. CS2 changed the bomb sound for the last 10 seconds (October 2023 patch), so the end of the countdown may drift if the timing changed too.
- Holding the C4 out for 2.5+ s and then dropping it causes a flash of up to 1.5 s.
- `round_totaldmg` (hit markers) may not be sent by every CS2 build. `--debug` shows `dmg=-1` when it's missing.
- Fades rely on iCUE alpha-blending the SDK layer over its own lighting.

## Roadmap ideas

- A system-tray build (`/target:winexe`) with toast notifications.
- An ammo bar on the number row, a low-HP heartbeat, and burning (`player.state.burning`).
- A config file instead of shortcut arguments.

## License

Add a `LICENSE` file before publishing (MIT is a common choice for a small tool like this). The Corsair iCUE SDK is distributed under Corsair's own terms and is not included in this repository.
