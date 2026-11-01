# PROJECT.md — Kaalchakra: The Drowned City

> A story-driven 3D time-shift adventure set in the Indus Valley.
> This document explains **what we are building, how it will actually get built, what I (AI) can do, and what will need real people and money.** Read this before `REQUIREMENTS.md`.

---

## 1. What the game is

A single-player, story-driven 3rd-person 3D adventure for **PC (Steam first)**. The player is **Evara**, a 24-year-old archaeologist who finds a copper wheel that lets her stand in the same place across three eras (1900 BCE, 2026, 2087) and carry knowledge between them to solve puzzles she cannot brute-force. ~5 hours, five chapters plus prologue and finale. Full story is in `kaalchakra-story-bible.md`.

Reference feel: the traversal and set-piece pacing of *Uncharted* / *Prince of Persia: The Sands of Time*, the melancholy of *Death Stranding*, grounded in real archaeology. The look you want — "attractive, high-end graphics" — is the single most demanding part of this project, and Section 4 is brutally honest about why.

---

## 2. The one thing to understand before anything else

**Gameplay is code. Graphics are craft.**

Code can be generated — by me, with you directing in plain English. Systems, puzzle logic, dialogue, save/load, the time-shift mechanic: all of that we can build together, and I can take it a long way.

**Graphics cannot be generated the same way.** A beautiful character or environment is *modelled, sculpted, textured, rigged, and animated by trained artists* in tools like Blender, ZBrush, Maya, and Substance Painter. There is no prompt that turns text into a production-ready, animated, riggable 3D hero character. AI can help artists (concept art, texture drafts, ideation), but it does not replace them. If you take one thing from this document: **the graphics you're excited about are a hiring/budget problem, not a coding problem.**

This is *good* news, actually — it means the expensive part is clearly separable, and everything else can start now, for free, with just us.

---

## 3. What I (AI / vibe coding) can build with you — starting today, at no cost

- **Playable prototypes of every core mechanic** in the browser or in a real engine: the three-era shift, the excavation minigame, the sluice/water puzzles, the "hide in the past, recover in the present" verb, stealth/disguise, timed escape sequences. This is how we prove the game is *fun* before anyone is paid.
- **All game systems and logic**: dialogue trees, branching choices, inventory, quest/state tracking, save and load, the phone-call-to-Sakshi hint system, puzzle rule-sets, checkpoints and failure/retry.
- **The engine project scaffold**: a working Godot project with folder structure, core scripts, a playable "greybox" level (rough geometry, no art) that a real team then dresses with art.
- **Story and design content**: full chapter scripts, dialogue, puzzle designs, level layouts, the tools/format your future writers and designers will fill in.
- **Placeholder / greybox art and simple stylized 3D** good enough to test gameplay — but not the final look. Harappan architecture is highly geometric (grid streets, standard brick ratios, stepped reservoirs), so much of the city greybox can be generated procedurally in Godot or via Blender Python.
- **Documentation, planning, pitch material, and the technical bridge** so that when you bring in artists and programmers, they can start immediately.

Realistically, with just you and me, we can reach a **vertical slice in greybox** — one chapter fully playable start to finish with real mechanics and placeholder visuals. That artifact is what you show to raise money or recruit a team.

---

## 4. What needs real humans and money (be realistic)

| Area | Who you need | Why AI can't do it |
|---|---|---|
| 3D characters, creatures, environments | 3D artists / environment artists | Modelling, sculpting, texturing is skilled manual craft |
| Rigging & animation | Riggers / animators | Every movement (walk, climb, dig, emote) is hand-built or mocap |
| Cinematics & set-piece direction | Technical artists / directors | Camera, staging, timing = human authorship |
| Music & sound design | Composer / sound designer | Licensable/AI drafts exist, but a signature score is a person |
| Voice acting | Actors / director | Performance is human (AI voice is a legal & quality risk) |
| High-end lighting, VFX, optimization | Technical artists | Deep engine expertise; performance tuning is iterative craft |
| Producing / QA / release | Producer, testers | Coordination and polish across a team |

**Team size reality for a ~5-hour, good-looking 3D game:** a focused small studio is roughly **8–20 people over 1.5–3 years**, or a very skilled tight team (4–6) over longer with a more stylized look. A single person cannot ship this at "latest games on the market" fidelity — but a single person *can* absolutely ship the prototype that gets the team funded.

**Rough money bands (very approximate, region-dependent):**
- Greybox vertical slice (us + maybe one freelance artist for one hero asset): **low — hundreds to low thousands of dollars**, mostly optional.
- A polished, marketable 5-hour 3D game: commonly **six figures and up** (USD) even for indies; in India, a lean experienced team can do meaningfully less, but it is still a serious budget.

**The cost-saving lever you control: art style.** A *stylized* look (think *Sable*, *Journey*, *RiME*) can look world-class at a fraction of photoreal cost, plays to a smaller team's strengths, and suits the Indus setting beautifully.

---

## 5. Engine choice — DECIDED: Godot 4

**Godot 4 (standard build, GDScript).** Free, open-source (MIT), no royalties or revenue share ever, no required splash screen or credit, exports to PC (and later mobile) from one project, and I can write GDScript directly.

Alternatives considered: **Unity** (free under $200k/yr revenue, then paid Pro seats; terms have changed before) and **Unreal** (5% royalty after $1M lifetime gross; pushes toward photoreal). Revisit Unreal only if a funded Phase 3 goes visually ambitious with a full team.

---

## 6. The realistic phase plan

**Phase 0 — Story & design.** ✅ Story bible, requirements, architecture, character brief, market positioning done. Engine decided.

**Phase 1 — Prototype the fun (weeks, free, us).** ← **we are here.** Build the core mechanics as playable greybox prototypes, starting with the three-era shift.

**Phase 2 — Greybox vertical slice (1–3 months, us + minimal help).** Chapter 2 playable end-to-end, real mechanics, placeholder art. **This unlocks funding, recruiting, or a publisher conversation.**

**Phase 3 — Team & art (needs money).** Artists, animator, composer. Replace greybox with the real look. Build remaining chapters.

**Phase 4 — Polish, QA, release.** Optimization, bug-fixing, Steam page, demo, launch.

**Phase 5 — Franchise.** Volume 2 (Egypt) reuses all systems built in v1.

---

## 7. What I need FROM YOU to keep moving

- **Decisions** (Section 8).
- **Direction & taste** — you are the creative lead; I generate, you judge.
- **Reference gathering** — screenshots/clips of games whose *look* and *feel* you want.
- **The money conversation, when ready.**
- **Time** — steady iteration beats a big burst.

What I do **not** need from you: any coding ability.

---

## 8. Decisions

**Decided:**
1. ~~Art style~~ → **stylized realism** (art bible still to lock).
2. ~~Engine~~ → **Godot 4**.
3. ~~First prototype target~~ → **the three-era shift** (greybox north gate + reservoir).
4. ~~Scope~~ → **build the vertical slice with AI first**, commission the Evara hero model from a freelancer, then decide on team.
5. ~~Sakshi~~ → **alive, on the phone.**

**Still open:** final title; art bible lock; Evara's canon face; Meera Easter egg; future-era playability. See `DECISIONS.md`.

---

## 9. Companion documents

- `kaalchakra-story-bible.md` — full narrative design.
- `REQUIREMENTS.md` — concrete feature and technical requirements.
- `ARCHITECTURE.md` — three-layer architecture and tool stack.
- `character-sketch-brief.md` — brief for concept artists.
- `MARKET-POSITIONING.md` — comps, pricing, revenue scenarios.
- `DECISIONS.md` — the decision log.
- *(future)* `ART-BIBLE.md`, `ENVIRONMENT-BRIEF.md`, `pitch-onepager.md`.

---

*PROJECT.md v1.1 — updated 2026-11-01 with decisions made since v1.0.*
