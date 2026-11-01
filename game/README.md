# game/ — the Godot project

Open this folder in Godot 4.7.2 (`/Applications/Godot.app`) and press **Play** (▶, top right, or F5).

## Controls

| Key | Does |
|---|---|
| W A S D | move (relative to the camera) |
| mouse | look / orbit |
| Shift | run |
| Space | jump — or pull yourself up onto a ledge you're facing |
| E | interact (hold, where the bar appears) |
| 1 / 2 / 3 | shift to Past / Present / Future |
| hold Q | the Wheel (shows all three mornings) |
| M | reduced-motion toggle (skips the shift fade) |
| R | respawn at the start |
| Esc | release the mouse |

## What's in here

```
scenes/
  Main.tscn              the scene that runs — sky, sun, HUD, location, Evara
  player/Evara.tscn      the capsule + 3rd-person camera
  locations/NorthGate.tscn   the greybox, with Past / Present / Future children
  dev/SmokeTest.tscn     dev-only test harness (not shipped)
scripts/
  autoload/              TimeShiftManager, Interactions — one copy, global
  world/                 Era (the shared vocabulary), EraRoot, EraLighting
  player/                movement, camera
  interact/              Interactable base, LoreMarker, DigSite
  ui/                    the HUD
materials/               flat greybox colours, one set per era
```

## The three-era switch, in one paragraph

`scenes/locations/NorthGate.tscn` has three children — `Past`, `Present`, `Future` —
each a complete copy of the same place. Only one is visible at a time. The other
two are still sitting there, but their geometry is on a **collision layer** Evara
isn't listening to, so she walks as if they don't exist. `TimeShiftManager`
announces the change, every `EraRoot` shows or hides itself, and Evara rebuilds
her collision mask. She never moves — the world changes around her.

## Things to try changing

Click **Evara** in the Scene panel (left) and look at the **Inspector** (right).
`Walk Speed`, `Run Speed`, `Jump Velocity` and `Mantle Max Height` are all live —
change one, press Play, feel the difference. Nothing you do there can break the
project; `git checkout .` puts it back.

## Before committing

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game scenes/dev/SmokeTest.tscn
```

It drives the era switch, the puzzle and the safety nets with no human, and
prints `SMOKE TEST PASSED` or a list of what broke.
