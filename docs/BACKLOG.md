# BACKLOG — what is not built yet

> Everything still missing, in the order I intend to build it, with the reason
> for the order. Derived from `REQUIREMENTS.md`, `LEVELS.md` and
> `WHO-DOES-WHAT.md`. Claude's column only — paid-human work is in
> `WHO-DOES-WHAT.md` §2.
>
> Updated 2026-11-01.

---

## Already built

Project and mobile setup · three-era switch · touch controls · character
controller with auto-climb and ledge pull-up · L1 and L2 built from a
generated Harappan kit with era erosion and props · masonry, water and
call shaders · per-era lighting and grading · Eva blocked out with a
procedural walk · dialogue system, format, parser, camera staging, hard cut,
title card · story flags, objectives, skills, contacts · three-era
decipherment with the sign index · Sakshi's hint calls · audio routing ·
UI palette and the Wheel dial · 136 automated checks, an end-to-end that
plays the Prologue, and the `./dev` tooling.

---

## The order, and why

### 1. Save, load, checkpoints, app lifecycle — R4.1, R4.2, CLAUDE.md §9
**First because everything after it has to be save-aware anyway.** Every system
I add from here has state; retrofitting saving later means touching all of
them twice. It is also a hard mobile requirement — a phone call arrives
mid-session and the game must come back exactly where it was. Cheap right now
because TimeShift, Story and Decipher already hand out plain dictionaries.

### 2. The excavation minigame — R2.4
The signature verb, currently a hold-to-dig placeholder. Swipe-to-brush, with
success and failure states, and it is the thing a player does most.

### 3. NPCs, then the trench-collapse rescue — R2.8
Vasudha and Ishita do not exist as characters at all. The rescue needs Ishita
present, a timer, and a fail-and-retry loop — it is the chapter's other half
and the first thing in the game you can lose. Needs 1 (checkpoints) done.

### 4. Chapter flow — R4.3
Something to run Prologue → Chapter 2 → next, rather than one scene I launch
by hand.

### 5. Main menu, pause, settings, accessibility — R6.1, R6.5
Including remappable controls, subtitle options, colourblind-safe cues. The
reduced-motion toggle already exists and is the only one.

### 6. Journal and codex — R6.4
The sign index is its first room. Quests, collectibles and lore go in beside it.

### 7. L3 the Dig Camp, then L6 the Knowledge-House — LEVELS.md
The two remaining locations the Chapter 2 slice needs.

### 8. Collectibles — R3.5
12 Keeper ledger entries, 5 Vasudha conversations, 3 WARDEN queries.

### 9. Choice consequences — R3.2
Flags are recorded; nothing reads them back yet.

### 10. Hindi subtitles and localisation plumbing — R3.7
Text is already in data files, which is most of the work. Needs the language
decision first.

### 11. Android export, on-device profiling, performance — R1.3, R7.5
Needs export templates installed. Everything so far is *claimed* to be within
mobile budget and nothing has been measured on a phone.

### 12. Later-chapter systems — R2.5, R2.6, R2.7, R2.9
Sluice and water-routing puzzles, disguise and social stealth, watchman
stealth, real skill progression. Chapters 1 and 3; not needed for the slice.

### 13. The banyan trick in full — R2.2
Objects hidden in one era recovered aged in another. Knowledge crosses eras
today; objects do not.

### 14. Anchored events — R2.3
The hook exists and always returns false. Chapter 3 needs it to mean something.

---

## Not in my column

Hero art, animation, music, voice, UI skin, concept art — `WHO-DOES-WHAT.md`
§2. And the five ◆ decisions in `ART-BIBLE.md`, which block environment work.
