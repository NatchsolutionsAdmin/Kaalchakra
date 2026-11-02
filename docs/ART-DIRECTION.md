# Art direction — the numbers

Source: `Kaalchakra_Illustrated_Art_Direction_Review.pdf` (external review, 2026-11-02),
read in full and adopted. Where that document and `ART-BIBLE.md` disagree, **this file wins**;
the art bible keeps the prose and the story reasoning.

This file is deliberately all numbers. It exists so that a value in the engine can be
checked against a value on a page, by anyone, without taste entering into it.

---

## 0. The one sentence

> One place, three eras, one steady camera, and a Wheel that changes not just the image
> but what the player understands.

And the brand rule underneath it:

> **Eight positions. Three accessible. Five absent. One forbidden movement.**

## 1. The verdict we are acting on

The review's finding was **not** "it needs textures". It was:

> Missing textures are not the primary obstacle; **focal hierarchy is.**

Everything in the frame currently has equal visual emphasis. That is why it reads as
junior work. Fixing it is lighting, composition and camera — all free, all ours, no
commissions required.

Pass criteria for the three-era benchmark (`./dev shots`):

1. Era recognisable **without the HUD**.
2. Focal point found **within two seconds**.
3. Unmistakably the **same location** in all three.

## 2. Camera (review §07)

| Parameter | Value |
|---|---|
| Vertical FOV, exploration | 50–55° (we use **52°**) |
| Follow distance, exterior | 3.2–4.2 m (we use **3.8 m**) |
| Follow distance, interior | 2.0–2.8 m (we use **2.4 m**) |
| Eva's share of screen width | 45–50% |
| Eva's feet | 83–89% of image height |
| Position smoothing | 0.15–0.25 s (we use **0.18 s**) |
| Directional look-ahead | 0.4–0.8 m (we use **0.6 m**) |

Depth must read in three layers: **foreground → Eva → destination.** Focal architecture
sits on the thirds. Controls are anchored to the safe area; framing is checked at
**19.5:9** and **4:3**.

## 3. Lighting recipes (review §08)

| Parameter | 1900 BCE | 2026 | 2087 |
|---|---|---|---|
| Time | 07:10 | 11:35 | 08:20 overcast |
| Key elevation | 17–23° | 65–75° | weak sky key |
| Key colour | `#FFD49B` | `#FFF4E3` | `#CAD6DF` |
| Fill colour | `#8F92A2` | `#B8C4C8` | `#647B86` |
| Key-to-fill | 3:1 – 4:1 | 2.5:1 – 3:1 | 1.3:1 – 1.8:1 |
| Fog | light dusty gold | very light dust | layered blue-grey |
| Shadows | long & legible | short & precise | soft & subdued |
| **Primary risk** | all-orange wash | clipped whites | crushed blacks |

Ratios are *rendered luminance contrast*, not Godot energy values — they are a thing to
look at, not a number to type. For a hero gate image, grazing sunlight **30–45° off
camera**.

**Critical correction to the art bible:** teal is not "the only cool colour". Teal is the
only *saturated cool narrative accent*. Indigo shadows, blue-grey fog and neutral cold
water are required for 2087. No global orange or blue tint may do the work that material
and light should be doing.

## 4. Colour roles (review §14)

| Role | Hex / opacity | Function |
|---|---|---|
| Primary surface | `#1B2433` @ 90–95% | Dialogue, archive |
| Light text | `#EDE7DA` | Primary text |
| Secondary text | `#D8CBB0` @ 75–85% | Labels |
| Copper | `#A8703F` | Wheel, active focus |
| Ochre | `#C98A3C` | Discovery emphasis |
| Teal | `#2E7A74` | **Water and survival only** |
| Disabled | `#D8CBB0` @ 35–45% | Unavailable state |
| Danger | `#B5633C` | Destructive actions |
| Thin border | `#D8CBB0` @ 22–30% | Panel structure |

Teal is **not** a generic selection colour. Selection and focus use copper or salt.

## 5. Type and shape tokens (review §13)

Sizes are given at a 1280×720 design resolution and scale from there.

| Role | Font | Size | Weight / note |
|---|---|---|---|
| Title | Marcellus | 64 | 400, +3px letterspace |
| Chapter | Marcellus | 36 | 400, +1px |
| Panel title | Marcellus | 27 | 400 |
| Dialogue | Manrope | 21 | 400, 1.40 leading |
| Menu | Manrope | 20 | 600 |
| Button | Manrope | 18 | 600 |
| Body | Manrope | 18 | 400, 1.45 leading |
| Evidence | Manrope | 17 | 400 |
| Label | Manrope | 15 | 700, +1px |
| Metadata | Manrope | 14 | 500 |

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 16, 24, 32, 48 |
| HUD edge | 32px + device safe-area inset |
| Panel radius | 6px; dialogue/document 4px |
| Control radius | 8px; no giant rounded cards |
| Tap target | 56×56 design px ideal; platform minimums still apply |
| Content column | up to ~560px, with text scale / reflow |

Marcellus and Manrope are **SIL OFL** — commercial use, no revenue share, no required
game credit. Keep the licence file alongside the font files. *(Not yet downloaded; the
engine uses role-based fonts so they drop in without touching layout code.)*

## 6. Interface (review §11, §12)

The HUD is: a **compact Wheel at top-right**, a **temporary location caption**, movement
and action controls that **fade after inactivity**, and objective text shown **on demand
or on change**. Debug-style information is hidden entirely. Touch targets exceed ~56×56
design px. Safe area respected on all sides.

### Context matrix

| Element | Explore | Puzzle | Dialogue / cutscene |
|---|---|---|---|
| Wheel | small | visible if allowed | hidden |
| Joystick | touch / idle fade | hidden | hidden |
| Action | near interactable | puzzle contextual | hidden |
| Location | on entry | usually hidden | hidden |
| Journal | secondary access | available | usually hidden |

Dialogue is a **document grammar**, not a generic opaque strip: near-opaque indigo
surface, thin copper rule, Manrope body, Marcellus only for major headings.
The sign index compares one observation in three columns — **intact / eroded / archive
scan**. Water-teal appears only on preservation or archival evidence.
**Never use fake Indus glyphs as generic interface buttons.**

## 7. Identity (review §03)

Dark indigo field, warm copper mark, **exactly eight spokes, three prominent and five
subdued**. The mark is drawn in code (`scripts/ui/kaalchakra_mark.gd`) so the app icon,
the title screen and the HUD dial are the same geometry and cannot drift.

| Context | Rule |
|---|---|
| Favicon / app icon | mark only, no wordmark |
| Title | mark + wordmark + subtitle |
| HUD | mark only, small, three detents legible |
| Chapter | mark as a quiet rule, not a badge |
| Finale | the first previously forbidden detent engages |

Rejected: Greek-key meander borders (that ornament is Greek, not Harappan), gold
high-fantasy badge treatments, free-spinning wheels.

## 8. Era shift — "The World Remembers" (review §16)

Replaces the white flash. Camera and Eva stay spatially coherent; **materials, forms,
shadow direction and atmosphere** change around them. The Wheel moves to a **detent** —
it never reads as a free-spinning selector.

| Time | Visual | Sound |
|---|---|---|
| 0–120 ms | Eva engages the selected stop | copper click |
| 120–300 ms | controlled radial light band, fine distortion | dry mechanism resonance |
| 300–620 ms | era-root swap / spatial reveal across a fixed image | layered change in ambience |
| 620–780 ms | new light, water and material settle | destination ambience enters |
| 780–900 ms | camera / Wheel return to controlled stillness | final mechanical stop |

Reduced motion replaces this with a crossfade and a short audio cue.
For the finale, the fourth detent **physically resists, creaks, then engages** — no
explosion.

## 9. Title screen (review §15)

At 1280×720: title near **x=88, y=150**; menu near **x=96, y=325**. The right
**55–60%** is reserved for the live gate/reservoir and the physical Wheel in
foreground/silhouette. The menu is an **editorial vertical list**; only **Continue** is
emphasised, and only when a save exists. The Wheel does not rotate continuously.

| Motion | Target |
|---|---|
| Live camera | 0.5–1° apparent drift over 10–15 s, no obvious loop |
| Dust and water | very sparse, slow, low-cost |
| Focus indicator | 150–200 ms translation and fade |
| Title entrance | 600–900 ms quiet reveal |
| Wheel | mostly still; tiny mechanical settle only |

## 10. Audio (review §17)

> The absence of audio is a larger experience gap than missing texture polish.

| Situation | Direction |
|---|---|
| Wheel | identity-defining layered copper detent, pressure, low sympathetic resonance |
| 1900 BCE | inhabited domestic life, distant people, tools, cloth, water movement |
| 2026 | dry wind, tent/tarp, subdued generator, excavation equipment, gravel footsteps |
| 2087 | water, muted structural tones, drone hum, **intentional silence** |
| Evidence discovery | material-specific affirmative cue, not a cheerful jingle |
| Dialogue UI | sparse confirmations, small per-character accents, not electronic chatter |

Commission a small **signature sound vocabulary** before any extensive soundtrack.

## 11. Eva — model contract (review §09, §10)

Keep: practical field shirt, rolled sleeves, teal layer, functional pants and boots,
tied-back hair, grounded face. Improve before commissioning: stronger third-person
asymmetry, readable pack silhouette, a recognisable field tool on one side, one subtle
narrative detail. A hint of teal must stay visible in normal rear-view play.
**Do not enlarge the Wheel into fantasy equipment worn on her back.**

| Deliverable | Scope |
|---|---|
| Mesh | 12–18k gameplay triangles; no 150k cutscene version |
| Texture | 1K material atlases where possible, tested on device |
| Hair | solid stylized clumps, minimal alpha |
| Rig | reusable humanoid skeleton; face poses for concern, curiosity, grief, resolve |
| Animations | idle, walk, run, stop/pivot, crouch, examine, reach, Wheel engage |
| Validation | Godot 4.7 import, skinning, LOD/material, phone-scale silhouette |

NOW (free, ours): tune head-to-body mass, shoulder width, limb proportions, foot
placement and backpack scale on the primitive blockout.
LATER (paid): pay for **rig quality and authored motion before mesh complexity** — the
same actor is on screen for roughly five hours.

## 12. Spend order (review §18)

| Priority | Commission | Deliverable |
|---|---|---|
| 1 | Three matched environment keyframes | identical North Gate / Reservoir composition in three eras, annotated for form, lighting, materials and modular kit |
| 2 | Eva hero model + rig + motion | 12–18k game-ready, reusable rig, textures, locomotion and interaction, Godot-tested |
| 3 | Hero copper Wheel + core sound | mechanically plausible eight-spoke asset, 3 stops, inaccessible detents, wear states, close-up animation, sound brief |

Illustrative split: keyframes 25%, Eva and core animation 45%, Wheel and sound 30%.
**Do not buy the full building kit before the keyframes are approved.**

## 13. The missing-image principle (review §19)

Absence is the principal storytelling material. Eight water-control markers in an
inhabited scene; three remnants in the excavation; a short drone reconstruction in the
flooded era. Used **selectively** where architectural meaning supports it — never
sprinkled on every structure.

> A locked shot of a gap between two walls becomes a doorway when the player sees the
> past. The camera never moves; the player supplies the missing information.

That recognition is more specific to Kaalchakra than any portal effect.

## 14. Reference lessons (review §18)

- **RiME** — monumental simple architecture through controlled lighting and framing.
- **Sable** — economical silhouettes, quiet negative space, restrained world density.
- **Journey** — tiny human figure against consequential architectural scale.
- **Arrival** — a graphic-language system with narrative weight, not decorative glyph spam.
- **Outer Wilds** — knowledge itself feels like progression.
