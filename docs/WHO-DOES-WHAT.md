# WHO DOES WHAT — Kaalchakra

> Three columns for the whole project: what Claude does (costs nothing but
> time), what needs a paid human (and why), and what only Prabhjot can do
> (costs nothing but cannot be delegated).
>
> Written 2026-11-01. Supersedes the [AI]/[HUMAN] tags in `REQUIREMENTS.md`,
> which were written for PC.

---

## The short version

| | Who | Cost |
|---|---|---|
| **Everything the game *does*** | Claude | time only |
| **Everything the game *looks and sounds like*** | hired people | money |
| **Every decision about what it *is*** | Prabhjot | judgement |

If it can be described in a file, Claude builds it. If it has to be *drawn,
sculpted, performed or composed*, a person does it. If it is a matter of taste
or commitment, Prabhjot decides it and nobody else can.

---

## 1. Claude — no money, just time

### Done
- Godot project, mobile renderer, landscape, build hygiene
- Three-era switch, collision-layer era separation, shift transitions
- Touch controls: floating joystick, drag camera, action/jump, the Wheel dial
- 3rd-person controller: walk/run, jump, auto-climb, ledge pull-up, respawn
- Greybox of L1 (north gate, reservoir, market street) and L2 (Trench 4 and
  the sealed chamber), all three eras
- Per-era lighting, colour grading, fog, horizon
- Eva blocked out from the approved sheets, with a procedural walk
- Dialogue system, `.dialogue` format, parser, branching, conditions, flags
- Story state: flags, objectives, skills, phone contacts
- Camera staging, hard cut, title card
- Audio routing: music/SFX/voice buses, file-by-name lookup, VO manifest tool
- 106-check automated test suite, `./dev` tooling, screenshot harness
- Drafts: Prologue script, art bible, level plan, this document

### Still to do
- Decipherment system (Chapter 2's spine)
- Excavation minigame proper — swipe-to-brush
- Sakshi phone-call hint system
- Save / load and checkpoints
- Water and sluice puzzles, stealth, timed set-pieces
- Quest log and journal, main menu, pause, settings, accessibility options
- Remaining locations in greybox (L3–L11)
- Localization plumbing, Hindi subtitle support
- Android and iOS export setup, on-device profiling, performance work
- Lightmap baking setup, LOD configuration, draw-call budgeting
- **Integrating every asset the artists deliver** — this is a real and ongoing
  job, not a formality

**Claude cannot:** model or sculpt, draw concept art, hand-animate, compose
music that ships, perform voice, art-direct final lighting, judge whether the
game is fun, or sign anything.

---

## 2. Paid humans — this is where money goes

Ordered by when you need them.

| # | Role | Deliverable | Why not Claude |
|---|---|---|---|
| 1 | **Character artist** | Eva: hero + mobile model, textured, rigged, Godot round-trip. Brief ready to send. | Sculpting and rigging a believable human is a craft. The result is in every frame for five hours. |
| 2 | **Environment artist** | One modular kit building L1 + L2 in three eras, to the brick module | Hero architecture and texture work. Claude's boxes are the measurements they build to. |
| 3 | **Animator** | Traversal set + story beats. Mixamo base, hand-polished | Claude's procedural walk is arithmetic. Weight and intention are hand work. |
| 4 | **Composer** | 5–8 cues for the slice | Generated music is not shippable and licences are a trap |
| 5 | **Sound designer** | Effects, ambience, the flood | Could be partly sourced CC0, but the flood and the Wheel need designing |
| 6 | **Voice cast** | Eva, Ishita, Sakshi, Vasudha for the slice | Decided: no AI voice ships (#27) |
| 7 | **UI artist** | Skin for HUD, Wheel, dialogue, menus | Claude implements it; someone has to design it |
| 8 | **Concept artist** *(optional)* | Environment concepts before the 3D | Cheaper to change a drawing than a model |

**Later, not now:** producer, QA across devices, marketing, community.

---

## 3. Prabhjot — nobody else can

### Decide (blocking real work)
- **The five ◆ in `ART-BIBLE.md`** — palette, Eva's height, real or invented
  script, whether 2087 keeps any warmth, dawn or mid-morning. *Blocks all
  environment art.*
- **Language plan** — English VO + Hindi subtitles is the recommendation; and
  what the 1900 BCE characters sound like
- **Business model** — premium, free Chapter 1 + unlock, or a platform deal
- **Minimum devices** — after the first phone test
- **Final title**
- Whether Meera is a ledger Easter egg

### Judge (only you)
- Does it feel right? Speed, camera, the weight of the shift, where a line
  drags. Claude cannot test this and no automated check ever will.
- Does Eva sound like Eva?
- Is the slice fun as grey boxes? **This is the gate on spending money.**

### Own (relationships and commitments)
- Hiring: shortlists, quotes, choosing people
- Written agreements before anyone contributes — ownership and credit
- Budget: how much, when, in what order
- Store accounts: Google Play, Apple Developer
- Marketing, S8UL, publishers or platform conversations
- Recovering or re-creating anything missing from the reference art

### Write
- The dialogue. Claude drafts so there is something to react to; the voice is
  yours. Eva is a character only you can hear.

---

## 4. The grey area — Claude drafts, a human finishes

| Thing | Claude does | Who finishes |
|---|---|---|
| Dialogue | A full draft in the right format | Prabhjot rewrites |
| Art bible, briefs, planning docs | Full drafts | Prabhjot locks |
| Level layout | Greybox at real scale with gameplay proven | Environment artist dresses |
| Animation | Procedural placeholder | Animator replaces |
| Audio | Placeholder generators, pipeline, naming | Composer and cast replace |
| Lighting | Competent technical setup and bakes | An artist directs the look |
| UI | Working implementation | UI artist skins |

---

## 5. What it means in practice

The slice can be **completely playable in greybox before any money is spent**.
That is the whole plan: Claude finishes Chapter 2's systems, Prabhjot plays it
and decides whether it is fun, and only then does anyone get hired.

If it is fun as grey boxes, art makes it beautiful.
If it is not, art makes it an expensive disappointment.

---

*WHO-DOES-WHAT.md v1 — 2026-11-01.*
