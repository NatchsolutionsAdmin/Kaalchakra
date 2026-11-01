# DECISIONS.md — Kaalchakra decision log

> Every decision that shapes the project, with the date and the reason. Newest at the bottom.
> Compiled 2026-11-01 from all earlier project chats.

| # | Date | Decision | Why |
|---|---|---|---|
| 1 | 2026-07 | Story-driven single-player 3D adventure, PC/Steam first (Windows), ~5 hours. *(Platform superseded by #18.)* | Narrative games are achievable for a small team; PC first, mobile port later. |
| 2 | 2026-07 | Setting: Indus Valley — Dholarath (fictionalized Dholavira), three eras: 1900 BCE / 2026 / 2087. | Unserved setting on Steam; real history as grounding is a marketing asset. |
| 3 | 2026-07 | Protagonist **Eva** — female, 24, Gen Z, **no surname**. | Creative lead's call; strengthens the Eva–Vasudha and mother–daughter threads. |
| 4 | 2026-07 | **Sakshi** = Eva's mother, retired archaeologist; kept **alive** (phone-call hint system). | Live phone dynamic; "journals-only" alternative still possible. |
| 5 | 2026-07 | Hard rule: anchored events — the city cannot be saved. | The game's thematic identity. |
| 6 | 2026-07 | Art direction lane: **stylized realism** (*Sable / RiME / Journey*), not photoreal. | Fits small-team budget; market data shows stylized lane rewards small teams. Formal art bible pending. |
| 7 | 2026-07 | Positioning: "Make it about the Indus Valley, make it in English, offer it in Hindi." Invented script for decipherment. | Global-first; Hindi as additive localization. |
| 8 | 2026-07 | Planning price **$19.99**. *(Withdrawn by #20.)* | Comps cluster $16.99–$24.99; ~5 h runtime. |
| 9 | 2026-07 | Vertical slice = **Chapter 2, "The Index"**. | Shows decipherment + three-era shift + rescue set piece. |
| 10 | 2026-07 | Character pipeline: 2D concept → turnaround → freelance 3D artist. Eva brief written (`Evara_Character_Brief.docx`); locked 2D = `ComfyUI_00009`. | 2D is cheap to change; freelancer handles Blender sculpt/retopo/rig. |
| 11 | 2026-10-31 | Learn design by **teardown → rebuild** (Titanfall 2, Dishonored 2, PoP Sands of Time, Uncharted, Outer Wilds, Chants of Sennaar). No decompiling commercial games. | Legal, and design is learned by observation. |
| 12 | 2026-10-31 | Claude carries engine/code work and teaches on our own project; Prabhjot directs. | Prabhjot's weak spots are engine work, level geometry and 3D modeling. |
| 13 | 2026-11-01 | Engine: **Godot 4, standard build, GDScript.** 3D: **Blender.** | No revenue share, no required credit/splash, open-source. |
| 14 | 2026-11-01 | No tools that take revenue share or require credits; verify AI-tool commercial terms; written agreements with friends who contribute. | Keep full ownership. |
| 15 | 2026-11-01 | **Start on Mac, move to Windows later**; same Godot version on both. *(Updated by #19.)* | Mac available now; Windows is ship target. |
| 16 | 2026-11-01 | Repo: `github.com/NatchsolutionsAdmin/Kaalchakra`, Git LFS for big assets. | Version history + easy Mac→Windows move. |
| 17 | 2026-11-01 | First prototype: greybox north gate + reservoir, capsule Eva, Past/Present/Future switch, one cross-era puzzle. | Proves the core loop (PROJECT.md decision #3). |
| 18 | 2026-11-01 | **Platform changed to mobile: Android + iOS** (landscape, touch-first). Replaces #1's "PC/Steam first". PC port optional later. | Creative lead's call. Fits S8UL's mobile-heavy audience and India's mobile-first market. |
| 19 | 2026-11-01 | Godot **Mobile renderer**; develop on the Mac (required for iOS builds); test on real phones from the first prototype. Windows move now optional (updates #15). | iOS export needs Xcode on a Mac. |
| 20 | 2026-11-01 | $19.99 PC price (#8) and PC market numbers **withdrawn**; mobile business model to be decided. | Mobile pricing and revenue work differently. |
| 21 | 2026-11-01 | **Godot version locked: 4.7.2.stable.official** (`ed1daf0bf`), at `/Applications/Godot.app`. Any second machine must use the same version — godotengine.org/download/archive. | Project files are version-sensitive; a mismatched editor can silently rewrite scenes. |
| 22 | 2026-11-01 | Era geometry is separated by **physics collision layer** (1 shared, 2 past, 3 present, 4 future), not by enabling/disabling nodes. The player's collision mask is rebuilt on every shift. | One line per shift, no per-node bookkeeping, and the two inactive eras cost nothing to walk through. |
| 23 | 2026-11-01 | Scene files written outside the Godot editor must use **`NodePath` exports resolved in `_ready()`**, never bare `Node` exports. | Only the editor writes the metadata that lets a bare `Node` export resolve on load; hand-written ones come back null, silently. |
| 24 | 2026-11-01 | **2087 is fully walkable, no combat.** Closes open decision #5. | The decipherment chain's third step is confirming a sign in WARDEN's future scans, which means standing there. |
| 25 | 2026-11-01 | Realistic/photoreal graphics ruled out again for mobile; the look comes from **lighting, silhouette and colour**, not polygon count. Greybox gets a directed look pass; hero art still waits for people and money. | Stylized is the only way to look high-end on a phone, and art on an unproven game is wasted money. |
| 26 | 2026-11-01 | **Protagonist renamed Eva** (was Evara). Still one name, no surname. | Creative lead's call. Note: the commission brief file is still `Evara_Character_Brief.docx` and should be renamed on disk. |
| 27 | 2026-11-01 | **AI voice is allowed for scratch/placeholder only**, never in anything released or shown publicly (no trailer, no demo, no store build). Real voice artists for the shipped game, per R5.7. Scratch audio lives in `audio/voice/scratch/` and is git-ignored. | Lets Prabhjot judge pacing and performance early without paying for sessions on lines that will change. Keeps the ownership rule intact. |

## To record next
- **Language plan:** English VO + Hindi subtitles, vs. full Hindi VO, vs. both (see the voice discussion, 2026-11-01)
- **What language the 1900 BCE characters speak**, and whether early incomprehension is a mechanic
- Mobile business model (premium / free Chapter 1 + unlock / platform deal)
- Minimum supported devices
- ~~Godot version installed on Mac~~ — recorded as decision #21: **4.7.2.stable**
- Final title
- Art bible lock
- Eva canon face
