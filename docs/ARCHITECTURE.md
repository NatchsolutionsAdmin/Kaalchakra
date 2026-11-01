# ARCHITECTURE & TECH STACK — Kaalchakra: The Drowned City

> How the game is built under the hood, and the tools at each layer.
> Companion to `PROJECT.md` and `REQUIREMENTS.md`. Written so a non-coder can hold the shape in their head.

---

## 1. The mental model: three layers

Think of the game as a stack of three layers. Each is built by different people with different tools. Keeping them separate is what lets your friends and me work in parallel without stepping on each other.

```
   ┌─────────────────────────────────────────────┐
   │  LAYER 3 — THE LOOK  (your friends + AI-assist)│
   │  models, textures, animation, environments,    │
   │  lighting, VFX, music, voice                   │
   └─────────────────────────────────────────────┘
                       ▲ dresses
   ┌─────────────────────────────────────────────┐
   │  LAYER 2 — THE GAME  (me + you directing)      │
   │  the engine project: scenes, mechanics,        │
   │  the time-shift system, puzzles, save/load     │
   └─────────────────────────────────────────────┘
                       ▲ runs on
   ┌─────────────────────────────────────────────┐
   │  LAYER 1 — THE FOUNDATION  (me, set up once)   │
   │  engine, version control, project structure,   │
   │  build pipeline                                │
   └─────────────────────────────────────────────┘
```

The key idea: **Layer 2 is built with greybox placeholders, so it works before Layer 3 exists.** Your friends' art drops in on top when it's ready. Nothing waits on anything.

---

## 2. The engine (Layer 1 foundation)

**Decided: Godot 4, standard build, GDScript, Mobile renderer.** Free, open-source, no royalties ever, one project exports to **Android and iOS** (PC later if wanted). The Godot project lives in `game/` in this repo.

**Mobile build chain:**
- **Android:** Godot's Android export (Android SDK + Java JDK). One-click deploy to a phone over USB for quick tests; Android App Bundle (.aab) for Google Play.
- **iOS:** Godot exports an Xcode project → build and sign in **Xcode on the Mac** → TestFlight for testing → App Store. Needs an Apple Developer account for device testing beyond basics and for release.
- **Input:** touch first (virtual joystick, camera drag, action button, Wheel dial); keyboard/gamepad for desk testing.
- **Performance:** Mobile renderer, baked lighting where possible, low draw calls, LODs, texture compression per platform, quality presets. Profile on real phones.
- **Lifecycle:** handle app pause/resume; autosave on pause.

---

## 3. How the game is structured inside the engine (Layer 2)

### 3.1 The scene structure
Godot organizes everything into "scenes" (reusable building blocks). Ours:
- **A Location scene** holds one place. Crucially it contains *three versions* of that place as sub-scenes: `Past`, `Present`, `Future`. Only one is visible at a time.
- **The Player scene** (Evara) persists across all three — same position, the world changes around her.
- **UI scenes** layer on top: HUD, the Wheel selector, dialogue box, journal.

### 3.2 The systems (the actual "game")
| System | What it does | Talks to |
|---|---|---|
| **TimeShiftManager** | The heart. Swaps Past/Present/Future, keeps player position, enforces the "anchored events" rule | everything |
| **PersistenceManager** | The "banyan trick" — remembers objects hidden in one era so they appear (aged) in another | TimeShiftManager, Save |
| **DialogueSystem** | Branching conversations, choices, character portraits | ChoiceTracker, Save |
| **ChoiceTracker** | Remembers decisions so they change later scenes/endings | Save |
| **PuzzleControllers** | One per puzzle type: excavation, sluice/water, decipherment | Skills, Save |
| **SkillManager** | Unlocks abilities per chapter (language, water engineering) | Puzzles, Dialogue |
| **QuestManager** | Tracks objectives, updates the journal | Save |
| **SaveSystem** | Writes the full three-era world state to disk, reloads it | all of the above |
| **CheckpointManager** | Fast diegetic respawns for the failure/retry design | SaveSystem |
| **AudioManager** | Plays music/SFX per scene and era | scenes |

These are the **[AI]** items from `REQUIREMENTS.md`. I build them as plain logic first, tested in greybox, before any art exists.

### 3.3 The data (kept separate from code — this matters)
Story content lives in **data files, not code**, so writers and designers (and you) can edit it without programming:
- Dialogue → structured text files (e.g. the Ink scripting language, or JSON)
- Signs/decipherment → a data table (sign → meaning → which era confirms it)
- Quests, collectibles, item definitions → data tables
- Localization → a translation table (English now, Hindi/others later)

---

## 4. The look (Layer 3) — tools per job

| Job | Human tool | AI-assist (accelerator) |
|---|---|---|
| Concept art / mood boards | pencil, Krita (free), Clip Studio, Procreate | Midjourney/Flux etc. (check commercial terms) |
| Character sculpt/model | Blender (free), ZBrush | Rodin/Meshy/Hunyuan3D for a first blockout from a sketch |
| Environment modelling | Blender | Tripo for background props (individually) |
| Texturing | Substance Painter, Blender | AI PBR textures, then cleanup |
| Rigging | Blender, Mixamo (free auto-rig) | Meshy/Tripo auto-rig for minor characters |
| Animation | Blender, mocap | auto-anim presets for testing only |
| Music | a DAW (Reaper, GarageBand) to polish | Suno/Udio for drafts (paid tier for commercial rights) |
| Voice | any recording setup | — (your friends; AI voice avoided) |

**Mobile asset budgets:** all models, textures and effects must fit phone limits (lower polygon counts, smaller and fewer textures, few transparent effects). Give every artist mobile targets up front; the Evara commission brief's PC targets need updating before hiring.

**The one habit that keeps AI 3D usable:** always run a "quad remesh" cleanup pass on any AI-generated mesh before it enters Godot.

**Always test the round-trip early:** make one model, clean it, import it into Godot, confirm it works — *before* generating a whole library.

**Ownership rule:** before any AI-made asset goes into the game, check that tool's current commercial-use terms and note which plan was used. Free tiers often forbid commercial use or require credit.

---

## 5. How work flows between us (the pipeline)

```
  YOU (creative lead)
      │ direction, taste, decisions
      ▼
  ME ──────────────► builds Layer 1 + Layer 2 in greybox
      │                (engine, systems, mechanics, placeholder art)
      │
      │ hands art specs, character sheets, prompts
      ▼
  FRIENDS ─────────► build Layer 3 (art, models, animation, voice)
      │                AI-assisted where it saves time
      ▼
  ME ──────────────► drops finished art into the working game
      ▼
  PLAYABLE BUILD
```

---

## 6. Version control & collaboration

- **Git** + **GitHub**: `https://github.com/NatchsolutionsAdmin/Kaalchakra.git`
- **Git LFS** for big art/audio files (configured in `.gitattributes`; run `git lfs install` once per machine).
- A shared drive for raw art source files and reference if they get too big for the repo.
- **Develop on the Mac** (needed for iOS). If a Windows PC is added later: same Godot version on both; relative paths only; consistent filename case.

---

## 7. The build order

1. **Art bible** (1 page) — lock the visual style. *(you + me + friends)*
2. **Character sheets** — ✅ brief done; Evara turnaround done. *(me → friends)*
3. **Foundation** — Godot project, Git, folder structure. *(me)* ← next
4. **Prototype** — three-era shift playable in greybox. *(me)* ← next
5. **Environment concepts** — each era's location. *(friends, from my level layouts)*
6. **Greybox vertical slice** — Chapter 2. *(me)*
7. **First hero asset** — Evara via freelancer. *(freelancer + AI-assist)*
8. **Art replaces greybox**, chapter by chapter. *(friends → me integrates)*
9. **Music, VFX, polish, QA, release.** *(everyone)*

---

*ARCHITECTURE v1.1 — Godot decided; updated 2026-11-01.*
