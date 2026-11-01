# Session prompt — paste this into a new Claude session

Use this when you start Claude in the Kaalchakra folder (Claude desktop app with the folder connected, or Claude Code). `CLAUDE.md` is read automatically, but pasting this makes sure the session starts in the right place.

---

```
You're working with me (Prabhjot) on Kaalchakra: The Drowned City — a stylized 3D
time-shift adventure set in the Indus Valley, built in Godot 4 (standard, GDScript)
as a MOBILE game for Android and iOS (landscape, touch controls).

Before anything else, read these files in this folder:
1. CLAUDE.md — who I am, what's decided, how to work with me
2. docs/DECISIONS.md — the decision log
3. docs/kaalchakra-story-bible.md — the story
4. docs/ARCHITECTURE.md and docs/REQUIREMENTS.md — systems and scope

Important about me: I'm not a programmer, and my weak spots are game design craft,
engine work and 3D. You carry the engine and code work and teach me as we go, on our
own game. Keep explanations short and plain. After every step, tell me exactly what
to click to see it working.

I'm developing on a Mac (needed for iOS builds). The GitHub repo is
https://github.com/NatchsolutionsAdmin/Kaalchakra.git

Today's goal: the first greybox prototype from CLAUDE.md §5 — the north gate and
reservoir of Dholarath, Evara as a capsule with touch controls (virtual joystick +
camera drag), and a Past / Present / Future switch on an on-screen Wheel dial, with
one tiny cross-era puzzle. Use Godot's Mobile renderer, and get it running on a
real phone as soon as it works on the Mac.

Start by checking which Godot version I have installed, then set up the project in
game/. Tell me in one sentence what you're about to do before each step.
```
