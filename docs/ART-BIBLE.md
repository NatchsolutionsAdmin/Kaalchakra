# ART BIBLE — Kaalchakra: The Drowned City

> **DRAFT by Claude for Prabhjot to cut.** Places where the decision is the
> creative lead's are marked **◆ DECIDE**.
> This is the document every artist reads before they draw a line. Until it is
> locked, all environment work is guesswork — including my greybox lighting.
> Mobile: Android + iOS, Godot 4, landscape. Every rule here is shaped by that.

---

## 1. The one-sentence look

**Sun-bleached stone and still water, lit like a photograph, built from almost
nothing.**

The lane is **stylized realism** — *Sable*, *RiME*, *Journey*. Real proportions
and real materials, simplified: large clean surfaces, almost no surface noise,
and all the storytelling in light, silhouette and colour.

Not photoreal. Not cartoon. Not low-poly-faceted as a *style* (we use few
polygons, but we hide it, we don't celebrate it).

**Why this and not something prettier:** a phone cannot run detail, and a small
team cannot author it. Every game that looks expensive on mobile got there with
art direction, not polygon count. This document is that direction.

---

## 2. The three rules everything obeys

**1. Silhouette first.** Every object, character and building must read in pure
black. If you cannot tell what it is from its outline, redesign the shape
before you touch the texture.

**2. Light does the work, not texture.** Surfaces are large, matte and nearly
plain. Interest comes from how light rakes across them, where shadows fall and
what colour the bounce is. A wall with one strong shadow across it beats a wall
with a detailed texture, and costs a hundredth as much.

**3. Three mornings, three palettes, one place.** The player must know which
era they are in within one frame, from colour and light alone, before reading
any UI. Same geometry, three completely different photographs.

---

## 3. Palette

Core, shared across all eras:

| Role | Hex | Use |
|---|---|---|
| Terracotta | `#B5633C` | fired brick, the city's base note |
| Ochre | `#C98A3C` | sunlit faces, dust, rope, cloth |
| Dust | `#D8CBB0` | salt flat, plaster, the ground everywhere |
| Brick shadow | `#8A5134` | the shaded side of everything above |
| Salt white | `#EDE7DA` | the Rann, lime plaster, bone |
| **Water teal** | `#2E7A74` | **the signature accent — see §4** |
| Deep teal | `#17403F` | water in depth, shadowed channels |
| Copper | `#A8703F` | the Wheel, the trowel, tools, fittings |
| Indigo | `#1B2433` | night, deep interiors, the drowned future |

Per era, everything above is pushed through one of these:

| Era | Key light | Sky / horizon | Shadow | Saturation |
|---|---|---|---|---|
| **1900 BCE** | `#FFD28C` warm, low, long shadows | `#E6B478` | `#6B4A3A` warm, never grey | **up** — a living city |
| **2026** | `#FFF7EC` high, hard, bleaching | `#BEC8CC` | `#7A7A74` neutral | **down** — flat, documentary |
| **2087** | `#BCD4F0` weak, diffuse, overcast | `#5A6F80` | `#26323C` cold | **down hard** — colour has drained |

**◆ DECIDE:** these are my values, derived from the brief's "terracotta/ochre/
dust + water-teal". Adjust them and everything downstream follows.

---

## 4. Teal is load-bearing

Teal is the only cool colour in a warm world, and it means **water, and things
that survive water**. Use it deliberately and sparingly:

- the reservoir, the channels, the flood
- the patina on the Wheel and on Eva's trowel
- Eva's undershirt — she is dressed in the colour of the thing that took her
  family and the thing she is trying to carry knowledge through
- WARDEN's scan light in 2087

Do not use teal decoratively. If it is on screen, it should mean something.

---

## 5. Light

Lighting is the single biggest lever we have, so it gets the most rules.

- **Bake it.** Static geometry uses baked lightmaps, which is how phones get a
  rich look for free. Real-time lighting is reserved for the sun and for a
  handful of moving or era-swapped objects.
- **One key, one fill.** A directional sun plus a cool sky fill. Shadows must
  never go black — the fill is what keeps a greybox from looking like a
  prototype, and it is the first thing to check if a scene looks cheap.
- **Shadows are composition.** A doorway's shadow across a floor, a wall's
  shadow down a street. Place geometry so shadows fall where you want the eye.
- **Fog is distance.** Each era has its own fog colour and density. 2087 is the
  heaviest — but never so heavy the player cannot navigate. That was a real bug
  once already.
- **Interiors have their own source.** The chamber is underground; it needs a
  lamp, a work light or a drone glow, not borrowed sky.

---

## 6. Materials

Keep the whole game to a small, shared set. Fewer materials means fewer draw
calls, which is frame rate on a phone.

- **Roughness 0.8–1.0 for almost everything.** Stone, brick, plaster, cloth,
  silt. Nothing in this world is shiny except water, copper and glass.
- **Metallic only on copper and the drones.** Nowhere else.
- **No normal-map noise.** No pores, no fake bumps, no tiling detail that reads
  as mush at arm's length. Normals are for baked large forms only — a brick
  course, a carved sign.
- **Trim-sheet and atlas wherever possible.** One texture serving a whole kit.
- **Vertex colour for variation**, not extra textures: dirt at the base of
  walls, salt bloom, waterline staining.

---

## 7. Shape language

Each era has a geometric grammar an artist can follow without being told
twice:

- **1900 BCE Dholarath** — rectilinear, modular, confident. Everything is built
  from the brick module (§8). Right angles, stepped profiles, deep reveals,
  few curves. A city built by engineers who measured.
- **2026 the dig** — *temporary*. Scaffold poles, tarpaulin, plastic crates,
  surveyor's pegs, grid string. Thin, light, provisional objects sitting on top
  of something massive and permanent. The contrast is the point.
- **2087 drowned** — *softened and accreted*. The same forms, rounded by silt,
  furred with deposit, half-submerged. Add nothing new except the drones, which
  are the only clean hard edges left in the world.

Characters, from the sketch brief: Raktim heavy and rounded; Vasudha stable
verticals and clean lines; Eva angular and restless.

---

## 8. Scale and the brick module

Real Harappan brick is a 1 : 2 : 4 ratio, and Dholavira is built on it. We use
it as the unit for the whole past era:

- **Brick module = 0.1 × 0.2 × 0.4 m.**
- Wall thicknesses are whole multiples: 0.4, 0.8, 1.2 m.
- Doorway height 2.0–2.2 m; the north gate opening is deliberately larger.
- Eva is **1.75 m**. Every environment is checked against her, never against
  the camera. **◆ DECIDE** — confirm her height.
- Steps are 0.55–0.65 m risers at most, so she walks up without jumping. This
  is a *gameplay* constraint and it overrides visual preference.

Modular pieces snapping to this grid is what lets one kit build a city.

---

## 9. Water

The game is named for a flood. Water is a character.

- Flat, calm, almost mirror-still in 1900 BCE — a managed resource, an
  achievement.
- Absent in 2026. Its absence is the point: dry stone, salt rings, a waterline
  stain left on the basin wall at the height it used to reach.
- Everywhere in 2087, and *dead* — no sparkle, no movement, a lid over
  everything.
- **One shader, three settings.** Not three water systems.

---

## 10. The script and the signs

The Indus signs are a graphic system, not decoration. Treat them like
typography: consistent stroke weight, consistent sizing, carved with real depth
so raking light reveals them. They must be legible enough that a player can
recognise the same sign in three eras — fresh, eroded, and scanned — because
that recognition *is* the Chapter 2 puzzle.

**◆ DECIDE:** real Indus signs (researched, respectful) or an invented script
derived from them. `MARKET-POSITIONING.md` says invented.

---

## 11. Forbidden

Fast list for anyone joining:

- Photoreal textures, PBR scan data, surface noise
- Heavy alpha: foliage cards, hair stacks, particle curtains
- Real-time shadows on anything that could be baked
- More than a handful of materials per location
- Lens flares, chromatic aberration, heavy bloom
- Any asset whose tool's licence takes a revenue share or requires credit

---

## 12. Budgets (mobile, per decision #29)

| Asset | Triangles | Textures |
|---|---|---|
| Hero character, cutscene | 80k–150k | 2K–4K |
| Hero character, in-game | 8k–20k + LODs | 1K |
| NPC | 6k–12k | 1K |
| Hero environment piece | 3k–8k | 1K shared/atlas |
| Kit piece, prop | 200–2k | shared atlas |
| Whole location on screen | aim under 150k | few materials |

Compressed per platform: ASTC/ETC2 Android, PVRTC/ASTC iOS.

---

## 13. What to put on the reference board

Before anyone draws: Dholavira's actual excavations and reservoirs, the Rann of
Kutch salt flat, Harappan brickwork and drainage, monsoon light in Gujarat —
and for the lane, *Sable*, *RiME*, *Journey*, *Monument Valley*.

Real archaeology first, then stylize. Dholarath is fiction; the civilisation is
not.

---

## 14. Still to decide ◆

1. Palette values (§3) — mine are a starting point
2. Eva's confirmed height (§8)
3. Real Indus signs or an invented script (§10)
4. Whether 2087 keeps *any* warm colour, or none at all
5. Whether the past era is dawn specifically, or mid-morning

---

*ART-BIBLE.md v0 — draft, 2026-11-01. Not locked. Nothing here is more
important than the creative lead's eye; it exists so five people can share
that eye without being in the room.*
