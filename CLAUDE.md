# CLAUDE.md — Kaalchakra: The Drowned City

> This file is read automatically by Claude at the start of every session in this folder.
> It is the single source of truth for **who you're working with, what we're building, what's decided, and how to work.**
> Keep it current: when a decision is made, update `docs/DECISIONS.md` and the relevant line here.

---

## 1. Who you're working with

- **Prabhjot** is the creative lead and project owner. Strong on story, taste, photography and lighting instincts, marketing contacts.
- **Self-described weak spots:** game design craft, engine work (Godot/Unity), 3D structures/level geometry, 3D modeling. **Not a programmer.**
- **Your role:** carry the engine and code work almost entirely, and *teach as you go* — on this project, not with generic tutorials. Every engine concept gets explained the first time it appears, in plain words, tied to something in our game.
- Prabhjot directs and judges ("does this feel right?"). You build, explain, and offer clear choices. Don't ask him to write code. Do ask him to press Play, walk around, and react.
- Communication style: concise, plain English, no jargon without a one-line explanation. Short replies; lists only when comparing. When you finish something, tell him exactly what to click to see it.

## 2. What we're building

A single-player, story-driven, 3rd-person **3D time-shift adventure** set in the Indus Valley. **A mobile game for Android and iOS** (landscape, touch-first). ~5 hours: prologue + 5 chapters + finale, broken into short play sessions. A PC/Steam port stays possible later; Godot makes that cheap, but it is not the target.

- **Protagonist: Evara** — female, 24, Gen Z archaeologist. **One name, no surname.** Narrates to her phone camera; carries her late father's trowel.
- **The Kaalchakra:** an eight-spoked copper wheel that snaps between **three fixed "mornings" of the same place:**
  - **Past — 1900 BCE:** the city of **Dholarath** (fictionalized Dholavira) at its peak and edge of collapse.
  - **Present — 2026:** Evara's dig; HELIX corporation circling.
  - **Future — 2087:** the drowned, abandoned site, tended by WARDEN's Archive drones.
- **Core loop:** solve puzzles by moving *information or small objects* across eras (learn in past → dig in present; walk a passage in the past that's collapsed in the present; read a future scan; hide in past → recover aged in present = "the banyan trick").
- **Hard rule:** "anchored events" — mass-witnessed history can't be changed. You can't save the city. You can save a person, a text, an idea.
- Key cast: **Sakshi** (Evara's mother, retired archaeologist, alive, on the phone — hint system), **Vasudha** (past-era chief water engineer, mentor), **Councillor Raktim** (past antagonist, reasonable), **Ishita Vaid** (present site partner, skeptic), **Marcus Dhillon / HELIX** (present antagonist), **WARDEN** (future archive intelligence), **Nira** (child, Ch. 4).

Full detail: `docs/kaalchakra-story-bible.md`.

## 3. Decisions already made (don't re-litigate unless Prabhjot raises it)

| Area | Decision |
|---|---|
| Platform | **Mobile: Android + iOS** (decided 2026-11-01, replaces "PC/Steam first"). Landscape orientation. PC port optional later. |
| Engine | **Godot 4, standard build (not .NET), GDScript.** Chosen partly because it never takes a revenue share or requires a credit/splash. Use the **Mobile renderer**; fall back to Compatibility only if low-end Android testing demands it. |
| 3D tool | **Blender** (free, open-source). |
| Art direction | **Stylized realism** (*Sable*, *RiME*, *Journey* lane). Not photoreal. Not cartoon. Formal art bible still to be written. |
| Ownership | **No tools that take revenue share or require credits.** Check commercial-use terms of any AI tool (Suno, Meshy, Tripo, Midjourney…) before using its output; free tiers often forbid commercial use. Friends who contribute art/voice need a simple written agreement (ownership + credit). |
| Machines | **Develop on the Mac.** It's required anyway: iOS builds need a Mac with Xcode. Android builds also work from the Mac. Windows is optional now. If it's used, keep the *same Godot version* on both. **Test on real phones** (one iPhone, one mid-range Android) from the first prototype. |
| Stores | Google Play developer account (one-time fee) and Apple Developer Program (yearly fee). Needed only once we test on devices outside USB/TestFlight or publish. |
| Version control | **Git + GitHub**: `https://github.com/NatchsolutionsAdmin/Kaalchakra.git`. Git LFS for large art/audio. |
| Protagonist | Evara, female, 24, no surname. Sakshi alive (phone calls). |
| Price / business model | **Open — re-decide for mobile** (see §4). The $19.99 PC plan in `docs/MARKET-POSITIONING.md` no longer applies. |
| Vertical slice | Chapter 2, "The Index" (see `docs/REQUIREMENTS.md` §8). |
| Evara 3D model | To be commissioned from a freelance character artist (brief exists: `Evara_Character_Brief.docx`). Locked 2D Evara = `ComfyUI_00009`. Turnaround/expression/gear sheets exist. Put them in `art/characters/evara/`. |
| Future era | **2087 is fully walkable, no combat** (decided 2026-11-01). Decipherment's third step happens there. |
| Learning approach | Learn game design by **teardown → rebuild**: study how great games solve a problem, then rebuild that system in greybox. **Never** decompile/rip commercial game files (EULA/copyright risk, contaminates the project). |

## 4. Open decisions (raise these when relevant, one at a time)

1. Final game title: *Kaalchakra: The Drowned City* vs *Sindhu* vs *The Third Morning*.
2. Write and lock the art bible (palette: terracotta/ochre/dust + water-teal; era tints warm-gold past / neutral present / cold blue-grey future).
3. Canon face for Evara: polished turnaround sheets vs the grounded `ComfyUI_00009` face.
4. Meera (from the early 2D prototype) as a past-Keeper Easter egg in ledger collectibles — recommended yes.
5. Engine re-evaluation (Unreal) only if the vertical slice raises real money for a visually ambitious production — Phase 3, not now.
6. **Mobile business model:** premium paid up front, vs. **free download with Chapter 1 free and a one-time unlock for the full game** (common for mobile narrative games), vs. a subscription platform deal (Netflix Games, Apple Arcade, as Raji did on Netflix). Avoid aggressive free-to-play monetization; it doesn't fit a 5-hour story. Market doc must be redone for mobile.
7. **Minimum devices:** pick target low-end Android and oldest supported iPhone after the first device test.
8. **Evara 3D brief:** the commission brief's poly/texture targets were written for PC. Update them for mobile before hiring.

## 5. The immediate next step (start here if nothing else is asked)

**First prototype: a greybox of one Dholarath area with the three-era switch.**

1. Confirm Godot 4 is installed on the Mac and note the exact version (Help → About). Record it in `docs/DECISIONS.md`.
2. Create the Godot project inside `game/` (project name "Kaalchakra"). Renderer: **Mobile**. Orientation: **landscape**. Turn on "Emulate Touch From Mouse" so touch can be tested on the Mac.
3. Build in greybox (plain boxes, no art), **touch-first**:
   - The **north gate** and the **reservoir** below it, with a market street running east. Use real-feeling Harappan proportions: grid streets, stepped reservoir walls, a walled citadel edge.
   - **Evara** as a capsule: 3rd-person controller with an **on-screen virtual joystick** (left), **drag-to-orbit camera** (right side of screen), a jump/climb button, and auto-climb on low ledges. Keyboard/gamepad also work for desk testing.
   - **TimeShiftManager** (autoload): an **on-screen Wheel dial** (tap or swipe between the three eras) switches Past/Present/Future; keys 1/2/3 for desk testing. Each location has `Past`, `Present`, `Future` child nodes; only one visible/collidable at a time. Player position persists. Add a short shift transition (fade/flash) with a reduced-motion option.
   - Make each era *physically different*: e.g. a passage open in the past but collapsed in the present; water filling the reservoir in the past, dry in the present, flooded in the future.
   - One tiny cross-era puzzle to prove the loop: see something in the past (a sign marking a buried door) → find and dig it in the present.
4. Walk Prabhjot through: opening the project, pressing Play, moving, switching eras, and changing one value himself (e.g. Evara's speed) so he learns the editor.
5. **Get it running on a real phone** (Android via USB one-click deploy is the quickest first test; iOS via Xcode export). Check frame rate and how the controls feel with thumbs.
6. Commit and push to GitHub with a clear message.

Then: game teardowns that feed directly into our systems (see §8).

## 6. Project architecture (summary — full version in `docs/ARCHITECTURE.md`)

Three layers: **Foundation** (engine, Git, structure — you), **Game** (systems, mechanics, greybox — you, with Prabhjot directing), **Look** (art, animation, audio, voice — friends/freelancers, AI-assisted). Greybox means the game is playable before any art exists.

Planned systems (Godot autoloads/scenes): `TimeShiftManager`, `PersistenceManager` (banyan trick), `DialogueSystem`, `ChoiceTracker`, `PuzzleControllers` (excavation, sluice/water, decipherment), `SkillManager`, `QuestManager`, `SaveSystem`, `CheckpointManager` (fast diegetic retry, 30–60 s), `AudioManager`.

Content lives in **data files, not code** (dialogue, sign index, quests, items, localization) so non-coders can edit it.

## 7. Folder layout

```
Kaalchakra/
├── CLAUDE.md            ← this file
├── SESSION-PROMPT.md    ← paste-in starter prompt for a fresh session
├── README.md
├── docs/                ← design & planning docs (story bible, requirements, architecture, market, decisions)
├── game/                ← the Godot 4 project (create project.godot here)
├── art/                 ← source art: characters/evara, environments, reference
├── audio/               ← music, sfx, voice (source files)
└── research/teardowns/  ← game teardown notes (Titanfall 2, Dishonored 2, etc.)
```

## 8. Teardown shortlist (design study, legal sources only)

Sources: playing the games, gameplay footage, GDC talks, developer postmortems, open-source games. For each: structure & pacing → core verbs → how the system works → greybox rebuild in Godot → lessons for Kaalchakra. Save notes in `research/teardowns/`.

- *Titanfall 2* — "Effect and Cause" (two-era swap in the same space — closest to our core mechanic)
- *Dishonored 2* — "A Crack in the Slab" (era swapping inside stealth)
- *Prince of Persia: The Sands of Time* (time fantasy, traversal, fast failure/retry)
- *Uncharted 2 / 4* (set-piece pacing, chase/escape → our flood sequence)
- *Outer Wilds* / *Return of the Obra Dinn* (knowledge as progression)
- *Chants of Sennaar* / *Heaven's Vault* (decipherment)
- **Mobile references:** *Monument Valley* (touch-first puzzle spaces, short chapters), *Alto's Odyssey* (premium mobile polish), *Sky: Children of the Light* (3rd-person touch movement and camera in a stylized 3D world), *Genshin Impact* (3rd-person touch controls at high fidelity).

## 9. Mobile design rules (apply to every system)

- **Touch first.** Every action works with thumbs: virtual joystick, camera drag, big tap targets (at least ~44 pt), contextual action button instead of many buttons. Gamepad support is a bonus.
- **Short sessions.** Split chapters into 10–20 minute segments with natural stopping points. Autosave often; resume exactly where the player left off if the app is closed or a call comes in (handle app pause/resume).
- **Performance budget from day one.** Target a steady 30 fps on a mid-range Android phone that's a few years old, 60 fps where possible. Keep draw calls and polygon counts low, prefer baked lighting, keep the number of real-time shadows and transparent effects small, and watch for phone heat and battery drain. Profile on device, not just on the Mac.
- **Three eras = three versions of a location in memory.** Keep each era's version lightweight, or stream them, so switching stays instant without running out of memory.
- **Download size.** Keep the first download small; put later chapters in downloadable packs if needed.
- **Screens vary.** Support notches and safe areas, many aspect ratios, and tablets.
- **Stylized art matters even more on mobile.** It's the only realistic way to look high-end on a phone.
- **Puzzles suit touch:** brushing in the excavation minigame (swipe), dragging sluice gates, tracing signs in decipherment.

## 10. Working rules

- **Explain before you build, briefly.** One sentence on what you're about to do and why.
- **Teach in context.** First time a Godot concept appears (node, scene, autoload, signal, collision layer…), explain it in one or two plain lines.
- **Greybox first, art later.** Never block gameplay on art.
- **Small, playable steps.** After each step, tell Prabhjot exactly how to test it.
- **Commit often** with plain-English messages. Use Git LFS for `.blend`, `.fbx`, `.glb`, `.png`, `.wav`, etc. (configured in `.gitattributes`).
- **Cross-platform hygiene:** relative paths only, case-consistent filenames (Windows is case-insensitive, macOS often is too, Linux/Git aren't).
- **Respect the real culture.** Dholavira/Harappan details are researched from real archaeology, then fictionalized.
- **Honesty about scope.** AI builds systems and greybox; hero art, animation, voice and final lighting need people.
- **Ask before anything irreversible** (deleting files, force-pushing, changing licenses).
