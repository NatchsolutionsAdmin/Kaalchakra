# DECISIONS.md — Kaalchakra decision log

> Every decision that shapes the project, with the date and the reason. Newest at the bottom.
> Compiled 2026-11-01 from all earlier project chats.

| # | Date | Decision | Why |
|---|---|---|---|
| 1 | 2026-07 | Story-driven single-player 3D adventure, PC/Steam first (Windows), ~5 hours. | Narrative games are achievable for a small team; PC first, mobile port later. |
| 2 | 2026-07 | Setting: Indus Valley — Dholarath (fictionalized Dholavira), three eras: 1900 BCE / 2026 / 2087. | Unserved setting on Steam; real history as grounding is a marketing asset. |
| 3 | 2026-07 | Protagonist **Evara** — female, 24, Gen Z, **no surname**. | Creative lead's call; strengthens the Evara–Vasudha and mother–daughter threads. |
| 4 | 2026-07 | **Sakshi** = Evara's mother, retired archaeologist; kept **alive** (phone-call hint system). | Live phone dynamic; "journals-only" alternative still possible. |
| 5 | 2026-07 | Hard rule: anchored events — the city cannot be saved. | The game's thematic identity. |
| 6 | 2026-07 | Art direction lane: **stylized realism** (*Sable / RiME / Journey*), not photoreal. | Fits small-team budget; market data shows stylized lane rewards small teams. Formal art bible pending. |
| 7 | 2026-07 | Positioning: "Make it about the Indus Valley, make it in English, offer it in Hindi." Invented script for decipherment. | Global-first; Hindi as additive localization. |
| 8 | 2026-07 | Planning price **$19.99**. | Comps cluster $16.99–$24.99; ~5 h runtime. |
| 9 | 2026-07 | Vertical slice = **Chapter 2, "The Index"**. | Shows decipherment + three-era shift + rescue set piece. |
| 10 | 2026-07 | Character pipeline: 2D concept → turnaround → freelance 3D artist. Evara brief written (`Evara_Character_Brief.docx`); locked 2D = `ComfyUI_00009`. | 2D is cheap to change; freelancer handles Blender sculpt/retopo/rig. |
| 11 | 2026-10-31 | Learn design by **teardown → rebuild** (Titanfall 2, Dishonored 2, PoP Sands of Time, Uncharted, Outer Wilds, Chants of Sennaar). No decompiling commercial games. | Legal, and design is learned by observation. |
| 12 | 2026-10-31 | Claude carries engine/code work and teaches on our own project; Prabhjot directs. | Prabhjot's weak spots are engine work, level geometry and 3D modeling. |
| 13 | 2026-11-01 | Engine: **Godot 4, standard build, GDScript.** 3D: **Blender.** | No revenue share, no required credit/splash, open-source. |
| 14 | 2026-11-01 | No tools that take revenue share or require credits; verify AI-tool commercial terms; written agreements with friends who contribute. | Keep full ownership. |
| 15 | 2026-11-01 | **Start on Mac, move to Windows later**; same Godot version on both. | Mac available now; Windows is ship target. |
| 16 | 2026-11-01 | Repo: `github.com/NatchsolutionsAdmin/Kaalchakra`, Git LFS for big assets. | Version history + easy Mac→Windows move. |
| 17 | 2026-11-01 | First prototype: greybox north gate + reservoir, capsule Evara, Past/Present/Future switch, one cross-era puzzle. | Proves the core loop (PROJECT.md decision #3). |
| 18 | 2026-11-01 | **Godot version locked: 4.7.2.stable.official** (`ed1daf0bf`), installed at `/Applications/Godot.app` on the Mac. Use the *same* version on Windows — download it from godotengine.org/download/archive. | Project files are version-sensitive; a mismatched editor can silently rewrite scenes. |
| 19 | 2026-11-01 | Era geometry is separated by **physics collision layer** (1 shared, 2 past, 3 present, 4 future), not by enabling/disabling nodes. The player's collision mask is rebuilt on every shift. | One line per shift, no per-node bookkeeping, and inactive eras cost nothing to walk through. |
| 20 | 2026-11-01 | Scene files written outside the Godot editor must use **`NodePath` exports resolved in `_ready()`**, never bare `Node` exports. | Only the editor writes the metadata that lets a bare `Node` export resolve on load; hand-written ones come back null, silently. |

## To record next
- ~~Godot version installed on Mac~~ — recorded as decision #18: **4.7.2.stable**
- Final title
- Art bible lock
- Evara canon face
