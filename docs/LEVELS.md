# LEVELS.md — the stages of Kaalchakra

> Every place the game needs built, what happens there, and in which of the
> three mornings it exists. Derived from `kaalchakra-story-bible.md` §5.
> This is the build list for Layer 2 (greybox) and the brief for Layer 3 (art).
> Status is honest: most of this does not exist yet.

---

## 1. The idea that keeps this small

**A location is built once and revisited.** Each one holds three versions of
the same ground — `Past` / `Present` / `Future` — and the story walks back
through the same places at different points in the game. Dholarath's north
gate appears in the Prologue, Chapter 1, Chapter 4 and the Finale; it is one
level, not four.

That is the whole reason a five-hour game is achievable here: **nine locations,
not forty.** It is also why the time mechanic is cheap — the expensive thing
in any game is new space, and we re-light and re-dress the same space instead.

A phone has limited memory, so three versions of one place must each stay
light (CLAUDE.md §9). Keep era variants to dressing and damage where possible;
only change the actual walkable shape where the story needs it.

---

## 2. The locations

| # | Location | Eras | Used in | What it is for | Status |
|---|---|---|---|---|---|
| L1 | **North Gate & Great Reservoir** | all 3 | Prologue, Ch1, Ch4, Finale | The signature space. The ten-sign signboard, the stepped reservoir, the market street east. Teaches the Wheel. | **greybox exists** |
| L2 | **Trench 4 & the Sealed Chamber** | all 3 | Prologue, Ch2, Ch4, Ch5 | The dig. Where the Wheel is found and where the manifest wall is read. Small, interior, lit from inside — the game's first "room". | **greybox exists** |
| L3 | **The Dig Camp** | present | Prologue, Ch2, Ch4 | Tents, generator, Ishita's scanning rig, the track out. Hub for 2026; HELIX parks here in Ch2. | not started |
| L4 | **Vasudha's Water-House** | past (ruin in present) | Ch1, Ch3 | Her workshop: hydraulic models, flood-timing tables, the plumb line. Where the three-era rule is explained. | not started |
| L5 | **The Lower City** | all 3 | Ch1, Ch3, Ch4 | Housing terraces below the citadel. The disguise/social-stealth streets, and the district that drowns in Ch4. | not started |
| L6 | **The Knowledge-House** | all 3 | Ch2, Ch4, Ch5 | The archive the index points at. Tablets, oral record-keepers, measured models. Becomes WARDEN's founding cache. The decipherment chapter lives here. | not started |
| L7 | **The Council Chamber** | past | Ch1, Ch3 | Raktim's floor. Vasudha's proposal is buried here; Eva is exposed here. | not started |
| L8 | **The Sluice Network** | past | Ch3 | The reservoir system from the inside — gates, channels, settling tanks. The water-routing puzzle chapter. | not started |
| L9 | **The Docks & Causeway** | past | Ch3, Ch4 | Trade frontage, and the flood-escape route with Nira. | not started |
| L10 | **WARDEN's Deep Archive** | future | Ch4, Ch5 | Below the drowned site. The Keeper's ledger and the hardest puzzle chain. | not started |
| L11 | **Cairo Vault** | — | post-credits | Ten seconds. A crate, a hum, black. | not started |

Eleven locations, of which the vertical slice (Chapter 2) needs **four**:
L1, L2, L3 and L6.

---

## 3. Build order

Driven by `REQUIREMENTS.md` §9 — prove the slice, then widen.

1. ~~**L2 Trench 4 & the Sealed Chamber**~~ — greybox done.
2. **L3 The Dig Camp** ← current — gives 2026 somewhere to be besides a hole.
3. **L6 The Knowledge-House** — the decipherment chapter; the slice's core.
4. **L4 Vasudha's Water-House** — the past-era anchor, and Ch1's destination.
5. Everything else, chapter by chapter.

---

## 4. What a location is made of

Each one ships as a scene with the same shape, so they are interchangeable
and nothing special-cases:

```
Location.tscn
├── Past     (EraRoot, era_id = PAST)      geometry, props, interactables
├── Present  (EraRoot, era_id = PRESENT)
├── Future   (EraRoot, era_id = FUTURE)
└── Markers  (spawn points, camera targets, trigger volumes)
```

Rules that keep them cheap and consistent:

- **Collision stays simple.** Boxes and capsules, never the art mesh.
- **Each era on its own physics layer** (2 / 3 / 4), so the other two cost
  nothing to walk through (decision #22).
- **Shared geometry is shared.** If a wall is identical in two eras, it is the
  same mesh resource with a different material, not two models.
- **Named camera targets**, so the dialogue script can say
  `@ camera push_in sealed_door` and a writer never touches a transform.
- **Spawn markers per era**, so a shift never drops Eva inside a wall.

---

## 5. Per-era differences: what is worth changing

Changing the walkable shape between eras is the expensive option and the one
that makes the mechanic sing. Use it deliberately:

| Cheap (do freely) | Expensive (do where it matters) |
|---|---|
| Material and colour | A passage open in one era, collapsed in another |
| Lighting and fog | Water level changing what is reachable |
| Props added or removed | Floor heights, new rooms |
| Damage and erosion variants | Anything that needs its own collision |

L1 already does one of each: the gate is open in 1900 BCE and rubble-choked in
2026, and the reservoir is a third full, dry, then over the top.

---

*LEVELS.md v1 — 2026-11-01. L1 and L2 are greybox; everything else is unbuilt.*
