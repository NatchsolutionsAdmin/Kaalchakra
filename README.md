# Kaalchakra: The Drowned City

A stylized, story-driven 3D time-shift adventure set in the Indus Valley. An archaeologist named Eva finds a copper wheel that lets her stand in the same city across three eras (1900 BCE, 2026, 2087) and carry knowledge between them.

- **Engine:** Godot 4 (GDScript)
- **Platform:** Mobile — Android and iOS
- **Status:** Phase 0 → Phase 1 (design done, first greybox prototype next)

## Where things are

| Folder | What's in it |
|---|---|
| `CLAUDE.md` | Working brief for Claude sessions (read automatically) |
| `SESSION-PROMPT.md` | Starter prompt to paste into a new session |
| `docs/` | Story bible, project plan, requirements, architecture, market positioning, decision log, character brief |
| `game/` | The Godot project |
| `art/` | Source art (characters, environments, reference) |
| `audio/` | Music, SFX, voice source files |
| `research/teardowns/` | Notes from studying how other games solve design problems |

## Opening the game

1. Install Godot 4 (standard build) from https://godotengine.org/download
2. Open Godot → **Import** → select `game/project.godot`
3. Press **Play** (▶, top right)

---

© Prabhjot / Natch Solutions. All rights reserved.

## Running it locally

```
./dev            list everything it can do
./dev play       play the game
./dev prologue   read the Prologue script in-engine
./dev test       run the smoke test
./dev vo         regenerate the voice recording sheet
./dev doctor     check this machine: Godot, Git LFS, phone build tools
```

`./dev doctor` is the one to run on a new machine, or when something stops
working — it says what is installed and what is missing.
