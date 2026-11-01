#!/usr/bin/env python3
"""Generate scratch voice for a dialogue scene using macOS's built-in speech.

    python3 tools/scratch_vo.py

Reads the recording sheet produced by `./dev vo` and writes one audio file per
line, named exactly as the game expects, into game/audio/voice/<scene>/.

This is PLACEHOLDER ONLY (decision #27). It exists so the pacing of a scene can
be judged before anyone is paid to record it. It is generated locally, it is
git-ignored, and it never ships — not in a build, not in a trailer.

The accents are wrong for every character. That is fine for timing; it is not
fine for anything anyone else sees.

Install more voices in System Settings > Accessibility > Spoken Content >
System Voice > Manage Voices. `Veena` (Indian English, female) is the one
worth adding — it would suit both Eva and Sakshi.
"""
import csv, pathlib, shutil, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHEET = ROOT / "game/data/dialogue/prologue_overburden.recording.csv"
OUT_ROOT = ROOT / "game/audio/voice"

# voice, words-per-minute. Chosen only to be distinguishable from each other.
# Prefer Veena for Eva and Sakshi once it is installed.
CAST = {
    "EVA":     ("Samantha", 180),
    "ISHITA":  ("Karen", 175),
    "SAKSHI":  ("Moira", 160),
    "VASUDHA": ("Tessa", 155),
    "WARDEN":  ("Daniel", 145),
    "RAKTIM":  ("Rishi", 165),
}
FALLBACK = ("Samantha", 175)


def installed_voices():
    out = subprocess.run(["say", "-v", "?"], capture_output=True, text=True).stdout
    return {line.split()[0] for line in out.splitlines() if line.strip()}


def main():
    if sys.platform != "darwin":
        sys.exit("This uses macOS's `say`. Run it on the Mac.")
    for tool in ("say", "afconvert"):
        if shutil.which(tool) is None:
            sys.exit(f"`{tool}` not found — it ships with macOS.")
    if not SHEET.exists():
        sys.exit(f"No recording sheet at {SHEET}. Run ./dev vo first.")

    have = installed_voices()
    missing_voices = {v for v, _ in CAST.values()} - have
    if missing_voices:
        print("not installed, falling back to %s: %s"
              % (FALLBACK[0], ", ".join(sorted(missing_voices))))

    tmp = ROOT / ".scratch_vo.aiff"
    made = 0
    per_speaker = {}
    with SHEET.open(newline="") as f:
        for row in csv.DictReader(f):
            rel = row["audio_file"]                    # scene/id.ogg
            text = row["line"].strip()
            if not text:
                continue
            speaker = row["speaker"]
            voice, rate = CAST.get(speaker, FALLBACK)
            if voice not in have:
                voice, rate = FALLBACK

            out = OUT_ROOT / rel
            out = out.with_suffix(".wav")              # `say` cannot write ogg
            out.parent.mkdir(parents=True, exist_ok=True)

            subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", str(tmp), text],
                           check=True)
            # Godot reads wav; `say` only writes aiff/caf.
            subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1",
                            str(tmp), str(out)], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            made += 1
            per_speaker[speaker] = per_speaker.get(speaker, 0) + 1
    tmp.unlink(missing_ok=True)

    print(f"\n{made} scratch lines written to {OUT_ROOT}")
    for who, n in sorted(per_speaker.items()):
        voice = CAST.get(who, FALLBACK)[0]
        print(f"   {who:<9} {n:>3}   {voice if voice in have else FALLBACK[0]}")
    print("\nPlaceholder only. Never commit, never ship, never put in a trailer.")


if __name__ == "__main__":
    main()
