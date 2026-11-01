# AI-FIRST-PRODUCTION.md — doing the "paid humans" list with Claude

Goal: get the vertical slice (Chapter 2) looking good enough to pitch without
hiring anyone. Honest bar for each job: **Slice-ready** (fine for a pitch) or
**Placeholder** (works, but a person replaces it before launch).

Invoke with: *"Read docs/AI-FIRST-PRODUCTION.md and do job 2."*

---

## 0. How Claude works on art (read first)

Claude can't drag a mouse in Blender. It writes scripts that Blender and Godot
run. That's the whole trick.

- **Blender, headless:** `blender --background --python tools/blender/<script>.py`
  builds, edits and exports `.glb` models with no clicking.
- **Godot:** Claude writes `.gd` scripts, `.tscn` scenes, `.tres` materials and
  shaders as text files.
- **Audio:** `sox`, `ffmpeg`, and Python MIDI tools (`mido`, `pretty_midi`) plus
  free soundfonts render music and process sound.
- **Images / UI:** SVG and Python (Pillow) for icons, the Wheel dial, HUD frames.

**Prabhjot's setup (once):** Blender and Godot installed on the Mac; Claude Code
open in the repo folder; `blender` reachable from the terminal. Every script
lives in `tools/`, so every asset can be rebuilt by re-running it.

**Rules for Claude:**

- Only CC0 or clearly commercial-licensed sources. Record every outside asset in
  `docs/ASSET-LICENSES.md` (file, source URL, licence, date).
- Respect mobile budgets from `CLAUDE.md` §9: low poly, 1K textures, baked
  light, few transparencies.
- After each job, tell Prabhjot exactly what to open and press to see it.
- Things only Prabhjot can do (logins, payments, accepting terms) are **[YOU]**.

---

## Job 1 — Eva, the character → Placeholder, maybe slice-ready

The hardest one. Two routes; try A first.

**Route A — image-to-3D, then scripted cleanup**

1. **[YOU]** Upload the locked turnaround (`ComfyUI_00009` + sheets A/B) to an
   image-to-3D tool on a paid tier with commercial rights (Meshy, Tripo,
   Hunyuan3D or Rodin — check terms on the day, note them in
   `ASSET-LICENSES.md`). Download the `.glb`.
2. Claude writes `tools/blender/eva_cleanup.py`: import → QuadriFlow remesh to
   ~15k tris → separate hair/body/clothes where possible → auto UV → bake the
   original's colour + normal onto the clean mesh → 1K textures → export
   `art/characters/eva/eva_mobile.glb`.
3. **Trowel:** Claude models it from primitives in `tools/blender/trowel.py`
   (small hand trowel, brass blade, wood handle). Easy and slice-ready.
4. **[YOU]** Upload the cleaned mesh to Mixamo (free Adobe login) for auto-rig
   + animations (Job 3). Download FBX.
5. Claude converts and imports to Godot, attaches the trowel to a hand bone,
   runs a walk test on the phone.

**Route B — fallback if A looks bad:** a deliberately simple stylized Eva Claude
builds from shapes in Blender (Sky / Alto level detail: readable silhouette,
soft shapes, flat-ish colours, minimal face). Less "wow", but consistent and
clean.

**Acceptance:** 30 fps on the Android test phone; no tearing at shoulders/knees
in the walk. Facial expressions will be weak — the commission brief is still
the long-term answer.

---

## Job 2 — Environment kit (L1 + L2, three eras) → Slice-ready

The best fit for Claude. Harappan building is grids and bricks.

1. `tools/blender/harappan_kit.py` generates a modular kit on the real brick
   ratio **1:2:4**: wall straight/corner/T, stepped reservoir wall, doorway,
   drain channel, stairs, gate tower, pillar base, signboard frame, platform
   edge. Snap grid = one brick module.
2. **Era variants from the same pieces, by script:**
   - Past: crisp edges, plaster tops, warm-gold tint.
   - Present: eroded (noise displacement, missing top courses), trench cuts,
     dig props.
   - Future: waterline stain, algae, collapsed sections, cold blue-grey.
3. **Materials:** CC0 textures from ambientCG and Poly Haven (brick, sandstone,
   mud, sand), or Godot triplanar shaders with noise so no UV work is needed.
   Era tints follow the palette in `ART-BIBLE.md`.
4. **Props:** pots, carts, sacks, tents, drone, survey poles — scripted
   low-poly, or CC0 packs from Kenney / Quaternius restyled.
5. **Water:** one Godot water shader (still / flowing / flood levels).
6. **Lighting:** baked lightmaps per era + one directional sun; fog for the
   future.
7. Replace greybox boxes in L1 + L2 piece by piece, keeping the same
   measurements.

---

## Job 3 — Animation → Slice-ready for traversal, Placeholder for story beats

1. **[YOU]** From Mixamo, download for the rigged Eva: idle, walk, run, jump,
   fall, land, climb up ledge, crouch walk, kneel + dig loop, push/pull lever,
   look around, phone-to-camera talk, carry (for Nira).
2. Claude builds the Godot `AnimationTree` (blend walk↔run by speed, state
   machine for jump/climb/dig), adds foot IK so feet sit on steps, and
   retargets everything to one skeleton.
3. **Story beats:** built from Mixamo clips + head/look-at IK + camera work.
   Blend shapes do basic expressions. This is where it'll look most "AI". Keep
   camera wide on emotional beats; let the dialogue text carry them.

---

## Job 4 — Music → Placeholder → slice-ready with your ear

No generated-music licence risk: Claude composes instead.

1. Claude writes 5–8 cues as MIDI in Python (drone + bansuri-style melody +
   frame-drum patterns; ragas suited to mood — a calm morning raga for the
   past, sparse drones for the future).
2. Renders with free/commercial-OK soundfonts or sample libraries (list each in
   `ASSET-LICENSES.md`), mixes with `sox`.
3. Layered stems in Godot so music thins or swells per era and per tension.
4. **[YOU]** Listen and judge — taste is your job. Later a composer or a friend
   on a real bansuri replaces the lead lines.

---

## Job 5 — Sound design → Slice-ready

1. Sources: Freesound filtered to **CC0 only**, Kenney audio, Sonniss GDC
   bundles (royalty-free).
2. Claude designs the two signature sounds by layering + processing:
   - **The Wheel shift:** metallic ring + reversed water + low sub-drop.
   - **The flood:** layered water, debris, a rising rumble, ducking everything.
3. Ambience beds per era (market crowd / dig-site wind / drowned silence +
   drones).
4. Godot `AudioManager` with buses, era crossfades, footstep surfaces.

---

## Job 6 — Voice → Not needed for the slice

AI voice is ruled out (decision #27). Ship the slice **unvoiced**, with good
subtitles, character portraits, and small vocal "barks" (a sigh, a laugh)
recorded by **[YOU]**/friends on a phone. Many top mobile story games are
unvoiced (*Florence*, *Monument Valley*). A full cast is a funded-phase job.

---

## Job 7 — UI art → Slice-ready

1. Style: terracotta/ochre + water-teal; Indus-sign motifs (our invented
   script) as ornament.
2. The Wheel dial as SVG: eight copper spokes, three era stops, tap/swipe, glow
   on shift.
3. HUD, dialogue box, phone-call screen for Sakshi, journal, menus — Godot
   `Theme` resource + SVG icons, 44 pt touch targets, safe areas.
4. **[YOU]** react to two or three style options; Claude iterates.

---

## Job 8 — Concept art → Slice-ready

Claude writes image prompts per scene and era (Prabhjot runs ComfyUI). Use
locally-run open models with licences allowing commercial use and record them.
Concepts guide Job 2; they don't ship in the game.

---

## Order to run

1. **Job 2** (environment kit) — biggest visual jump, lowest risk.
2. **Job 7** (UI) — cheap and makes everything feel real.
3. **Job 1 Route A + Job 3** (Eva + Mixamo).
4. **Job 5**, then **Job 4**.
5. **Job 8** alongside, whenever needed.

---

## What this does NOT get you

A launch-quality hero Eva with a believable face, hand-polished story
animation, a signature score and a voice cast. The slice built this way is how
you raise the money for those. The commission brief
(`art/characters/eva/Eva_Character_Brief.docx`) stays ready for that day.
