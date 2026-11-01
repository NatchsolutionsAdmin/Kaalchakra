# game/ — the Godot project

Open this folder in Godot 4.7.2 (`/Applications/Godot.app`) and press **Play** (▶, top right, or F5).

Or from the repo root, without typing paths:

```
./dev play       play the game
./dev prologue   read the Prologue script in-engine
./dev test       run the smoke test
./dev vo         regenerate the voice recording sheet
./dev shots      render reference screenshots
./dev edit       open the Godot editor
./dev doctor     check what is installed on this machine
```

This is a **mobile** game (Android + iOS, landscape). "Emulate Touch From Mouse"
is on, so dragging with the mouse on the Mac behaves exactly like a thumb.

## Controls — touch

| Thumb | Does |
|---|---|
| drag anywhere on the **left** half | walk (the joystick appears where you touch) |
| drag anywhere on the **right** half | look / orbit the camera |
| **JUMP** button | jump; in mid-air, catch a ledge above you |
| **action** button (bottom right) | interact — hold it to excavate |
| the **dial** (top right) | tap to open the Wheel, then tap an era — or swipe the dial |

Low steps are climbed automatically; you never tap jump on stairs.

## Controls — keyboard, for testing at the desk

W A S D move · Shift run · Space jump · E interact · 1 / 2 / 3 shift era ·
hold Q the Wheel · M reduced motion · R respawn

## What's in here

```
scenes/
  Main.tscn              the scene that runs — sky, sun, HUD, location, Eva
  player/Eva.tscn      the capsule + 3rd-person camera
  locations/NorthGate.tscn   the greybox, with Past / Present / Future children
  ui/ (built in code)    HUD and the touch controls
  dev/SmokeTest.tscn     dev-only test harness (not shipped)
scripts/
  autoload/              TimeShift, Interactions, Touch, Story, Dialogue, Audio
  dialogue/              the .dialogue parser
  world/                 Era (the shared vocabulary), EraRoot, EraLighting
  player/                movement, camera
  interact/              Interactable base, LoreMarker, DigSite
  ui/                    the HUD
materials/               flat greybox colours, one set per era
```

## The three-era switch, in one paragraph

`scenes/locations/NorthGate.tscn` has three children — `Past`, `Present`, `Future` —
each a complete copy of the same place. Only one is visible at a time. The other
two are still sitting there, but their geometry is on a **collision layer** Eva
isn't listening to, so she walks as if they don't exist. `TimeShiftManager`
announces the change, every `EraRoot` shows or hides itself, and Eva rebuilds
her collision mask. She never moves — the world changes around her.

## Things to try changing

Click **Eva** in the Scene panel (left) and look at the **Inspector** (right).
`Walk Speed`, `Run Speed`, `Jump Velocity`, `Auto Step Height` and
`Mantle Max Height` are all live —
change one, press Play, feel the difference. Nothing you do there can break the
project; `git checkout .` puts it back.

## Reading the Prologue in the game

```
/Applications/Godot.app/Contents/MacOS/Godot --path game scenes/dev/Prologue.tscn
```

Tap to advance; tap while text is typing to finish the line; choices are
buttons. The script is `data/dialogue/prologue_overburden.dialogue` — edit it in
TextEdit, run this again, and your words are in the game. No Godot required.

When the time comes to export a real build, `*.dialogue` has to be added to the
export filters, or the scripts get left out of the package.

## Sound

There is no audio in the game yet — no music, no effects, no voice. The system
is built and waiting; it plays whatever it finds and stays quiet about what it
cannot, so a missing file is never a crash.

Files are found **by name**, so adding sound needs no code and no Godot:

| The script says | Drop a file at |
|---|---|
| `@ music bansuri_sparse` | `game/audio/music/bansuri_sparse.ogg` |
| `@ sfx phone_dial` | `game/audio/sfx/phone_dial.ogg` |
| a spoken line with id `start_02` | `game/audio/voice/prologue_overburden/start_02.ogg` |

`.ogg`, `.wav` and `.mp3` all work; `.ogg` for anything that ships, because
download size matters on a phone.

Two folders, on purpose: `/audio` at the top of the repo is for **sources** —
full-quality WAVs, session files, anything an artist hands over. `game/audio`
is only what ships.

### What still needs recording

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game scenes/dev/VOManifest.tscn
```

Writes `data/dialogue/prologue_overburden.recording.csv` — one row per spoken
line, with the exact filename that line's audio must have. Open it in Numbers.
That is the script you hand a voice actor, and the checklist for what comes
back. Re-run it after any rewrite and diff the two to see what needs redoing.

Running the Prologue also prints every audio file it looked for and could not
find, which is the same list from the other direction.

## Before committing

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game scenes/dev/SmokeTest.tscn
```

It drives the era switch, the puzzle and the safety nets with no human, and
prints `SMOKE TEST PASSED` or a list of what broke.

## Building for a phone

Not set up yet. What's needed:

- **Export templates** — Godot: Editor → Manage Export Templates → Download (~1 GB).
- **Android** — the SDK is already on this Mac (`~/Library/Android/sdk`, build-tools
  36.1.0) and Java 17 is installed. Point Godot at both in Editor Settings →
  Export → Android, then plug in a phone with USB debugging on.
- **iOS** — needs **Xcode** from the Mac App Store, which isn't installed yet
  (only the Command Line Tools are). Godot exports an Xcode project; you build
  and sign it there.
