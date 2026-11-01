# REQUIREMENTS.md — Kaalchakra: The Drowned City

> Concrete requirements derived from `PROJECT.md` and `kaalchakra-story-bible.md`.
> Each requirement is tagged with who can deliver it:
> **[AI]** = I can build this with you · **[HUMAN]** = needs hired specialists · **[BOTH]** = I scaffold, humans finish.

---

## 1. Platform & technical baseline

- **R1.1 [AI]** Target platform: PC (Windows first), Steam. Architecture must not block a later mobile port. Development starts on Mac; test on Windows before any release.
- **R1.2 [AI]** Engine: **Godot 4 (standard build, GDScript)** — one project, PC build.
- **R1.3 [BOTH]** Target hardware: run smoothly on a mid-range PC (stylized art = far wider reach).
- **R1.4 [AI]** Frame budget and save architecture designed in from the start (three-era state is non-trivial — see R4).
- **R1.5 [AI]** Version control (Git + LFS on GitHub) and a clean project structure from day one.

---

## 2. Core gameplay systems  *(the part we can build together)*

- **R2.1 [AI]** **Three-era time-shift.** Player toggles between Past (1900 BCE), Present (2026), Future (2087) at will (with story gating). The *same* location renders differently per era; player position persists across shifts.
- **R2.2 [AI]** **Cross-era persistence.** Objects/knowledge placed or learned in one era affect another (the "banyan trick": hide in past → recover aged in present; learn location in past → dig in present; read future scan → solve present).
- **R2.3 [AI]** **The "anchored events" rule.** Mass-witnessed history cannot be changed; the system must enforce and communicate this (it's the game's core dramatic constraint, not a bug).
- **R2.4 [AI]** **Excavation minigame.** Brush/scan/extract loop with success and failure states.
- **R2.5 [AI]** **Water/sluice puzzles.** Flow-routing puzzles using (real) Harappan hydraulics; multi-step, checkpointed.
- **R2.6 [AI]** **Disguise / social stealth.** Pass as a trader in the past; detection → ejection → retry.
- **R2.7 [AI]** **Stealth (watchmen).** Avoid capture in Chapter 3; capture → checkpoint retry.
- **R2.8 [AI]** **Timed set-pieces.** Trench-collapse rescue, flood escape, storm defense, the finale heist — each with fast, diegetic failure/retry (checkpoint within 30–60s).
- **R2.9 [AI]** **Skill progression.** Excavation, traversal, Harappan comprehension (Ch.2), water engineering (Ch.3), Wheel mastery — each unlocks new interactions.

---

## 3. Narrative & content systems  *(also buildable together)*

- **R3.1 [AI]** **Dialogue system** with branching, character portraits/labels, and choice consequences.
- **R3.2 [AI]** **Choice tracking** — decisions (e.g. tone with Vasudha) alter later content/endings.
- **R3.3 [AI]** **Sakshi phone-call hint system** — contextual mother-daughter calls that (a) advance emotion and (b) function as an optional decipherment hint mechanic.
- **R3.4 [AI]** **Decipherment mechanic** — learn a sign in one era, confirm across the other two; unlocks readable text and dialogue.
- **R3.5 [AI]** **Collectibles** — 12 Keeper "ledger entries," 5 Vasudha lore convos, 3 WARDEN queries (Vol.2 foreshadowing).
- **R3.6 [AI]** **Quest / objective tracking** and journal.
- **R3.7 [BOTH]** **Localization-ready** text (English first; structure supports Hindi/others later).

---

## 4. Save, state & flow

- **R4.1 [AI]** Save/load capturing full three-era world state, inventory, choices, quest progress, skills.
- **R4.2 [AI]** Checkpoint system tuned for the failure/retry design (Section R2.8).
- **R4.3 [AI]** Chapter/scene flow manager (prologue → 5 chapters → finale → post-credits hook).
- **R4.4 [AI]** ~5-hour main-path pacing with optional content that does not extend the critical path.

---

## 5. Visual & audio

> Friends cover the **[HUMAN]** craft. AI's role is to *accelerate* (blockouts, concept art, background props, music drafts), never to replace the hero work. AI 3D output still needs a human cleanup pass (retopology, UV, texture, rig) before it's engine-ready.

- **R5.1 [HUMAN + AI-assist]** Hero characters (Evara, Vasudha, Sakshi, Ishita, Raktim, Dhillon): friends/freelancers lead. AI may generate a *first blockout* from sketches, then artists retopologize, texture, rig, and animate. Evara commission brief: `Evara_Character_Brief.docx`.
- **R5.2 [HUMAN + AI-assist]** Three era-versions of the location: environment art human-led. AI 3D good for **background props** (generate individually). Hero architecture (the reservoir, signboard, north gate) stays human-led.
- **R5.3 [HUMAN + AI-assist]** Animation: auto-rig fine for minor characters and testing; hero key-animation is hand/mocap.
- **R5.4 [HUMAN]** Lighting, VFX (water, dust, the shift transition), optimization.
- **R5.5 [HUMAN]** Cinematics / cutscene direction.
- **R5.6 [AI-DRAFT + HUMAN]** **Music:** I write audio-design briefs + prompts per scene (bansuri, sitar, frame drums, low drones for the drowned future). *Use a tier with commercial rights.*
- **R5.7 [HUMAN]** Voice acting: friends. (AI voice avoided.)
- **R5.8 [AI]** Greybox / placeholder versions of everything so gameplay is testable before final art.
- **R5.9 [AI-DRAFT + HUMAN]** **Concept art / mood boards:** I write image-gen prompts; friends sketch from or past them.

**Ownership:** verify commercial-use terms of every AI tool before its output enters the game; keep a note of tool + plan. Written agreements with every contributor.

---

## 6. UI / UX  *(buildable together)*

- **R6.1 [AI]** Main menu, pause, settings (graphics/audio/controls/accessibility).
- **R6.2 [AI]** In-game HUD: era indicator, objective, interaction prompts, inventory.
- **R6.3 [AI]** The Wheel interface for switching eras.
- **R6.4 [AI]** Journal / codex for lore and collectibles.
- **R6.5 [AI]** Accessibility baseline: remappable controls, subtitles, colorblind-safe cues, reduced-motion option for the shift effect.
- **R6.7 [BOTH]** Final UI art/skin.

---

## 7. Production & release

- **R7.1 [HUMAN]** Producer / project management once a team exists.
- **R7.2 [HUMAN]** QA and playtesting across hardware.
- **R7.3 [BOTH]** Steam page, store assets, trailer, demo build.
- **R7.4 [HUMAN]** Marketing / community, launch, post-launch support (S8UL contact for India reach).
- **R7.5 [AI]** Build pipeline and packaging setup.

---

## 8. The vertical slice — minimum requirements to prove the game

- **VS.1 [AI]** Chapter 2, "The Index," playable start to finish.
- **VS.2 [AI]** Working three-era shift in that chapter's location.
- **VS.3 [AI]** At least two core mechanics live (decipherment + the trench-collapse rescue).
- **VS.4 [AI]** Real dialogue, choices, and the Sakshi call system.
- **VS.5 [AI]** Save/load and failure/retry working.
- **VS.6 [BOTH]** At least **one** hero asset at near-final quality (Evara or the reservoir).
- **VS.7 [AI]** Everything else greybox.

**If the vertical slice is fun with placeholder art, the game works.**

---

## 9. Priority order

1. **Prototype** the three-era shift + one puzzle. **[AI]** ← current
2. **Vertical slice** (Section 8). **[AI]**, plus one hero asset **[HUMAN]**.
3. **Art bible + team** decisions and hiring. **[HUMAN/you]**
4. **Full production** of remaining chapters. **[BOTH]**
5. **Polish & release.** **[BOTH/HUMAN]**

---

*REQUIREMENTS.md v1.1 — Godot locked; updated 2026-11-01.*
