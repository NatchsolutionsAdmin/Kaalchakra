#!/usr/bin/env python3
"""Synthesise placeholder music and sound effects for the cues the scripts ask for.

    python3 tools/placeholder_sfx.py

Crude on purpose — sine tones, filtered noise, a few envelopes. The point is to
hear WHEN something happens and judge pacing, not what it sounds like. Real
music and effects are a human job (R5.6).

Like the scratch voice, these are generated locally, git-ignored, and never
ship (decision #27).
"""
import math, pathlib, random, struct, wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
RATE = 44100
random.seed(7)  # same output every run, so nothing churns


def write(path: pathlib.Path, samples, gain=0.6):
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s / peak * gain)) * 32767))
                    for s in samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def n(seconds):
    return int(seconds * RATE)


def fade(buf, attack=0.02, release=0.2):
    a, r = n(attack), n(release)
    for i in range(min(a, len(buf))):
        buf[i] *= i / a
    for i in range(min(r, len(buf))):
        buf[len(buf) - 1 - i] *= i / r
    return buf


def tone(freq, dur, amp=1.0, vibrato=0.0):
    out = []
    for i in range(n(dur)):
        t = i / RATE
        f = freq * (1.0 + vibrato * math.sin(2 * math.pi * 5.0 * t))
        out.append(amp * math.sin(2 * math.pi * f * t))
    return out


def noise(dur, cutoff=0.25, amp=1.0):
    """White noise through a one-pole low-pass. cutoff 0..1, lower = duller."""
    out, prev = [], 0.0
    for _ in range(n(dur)):
        prev += cutoff * (random.uniform(-1, 1) - prev)
        out.append(prev * amp)
    return out


def mix(*layers):
    length = max(len(l) for l in layers)
    out = [0.0] * length
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return out


def swell(buf, period):
    for i in range(len(buf)):
        buf[i] *= 0.45 + 0.55 * (0.5 - 0.5 * math.cos(2 * math.pi * i / (period * RATE)))
    return buf


MUSIC = ROOT / "game/audio/music"
SFX = ROOT / "game/audio/sfx"

# --- music beds -----------------------------------------------------------
# A sparse high line over a drone — stands in for bansuri.
bansuri = [0.0] * n(12)
for start, f, d in [(0.4, 587, 1.6), (2.2, 523, 2.0), (4.6, 440, 2.0),
                    (7.0, 392, 1.8), (9.4, 523, 2.2)]:
    note = fade(tone(f, d, 0.5, vibrato=0.012), 0.12, 0.9)
    for i, v in enumerate(note):
        if start * RATE + i < len(bansuri):
            bansuri[int(start * RATE) + i] += v
write(MUSIC / "bansuri_sparse.wav",
      mix(bansuri, swell(tone(146.8, 12, 0.22), 6.0)), 0.5)

# Warm and low — the mother.
write(MUSIC / "sakshi_theme.wav",
      mix(swell(tone(196, 10, 0.5), 5.0), swell(tone(293.7, 10, 0.3), 7.0),
          swell(tone(98, 10, 0.4), 9.0)), 0.5)

# Something is coming.
build = mix(tone(73.4, 8, 0.6), tone(110, 8, 0.3), noise(8, 0.02, 0.25))
for i in range(len(build)):
    build[i] *= 0.15 + 0.85 * (i / len(build)) ** 1.6
write(MUSIC / "low_drone_build.wav", fade(build, 0.5, 0.4), 0.55)

# A city with people in it.
write(MUSIC / "dholarath_alive.wav",
      mix(swell(tone(220, 11, 0.35), 4.0), swell(tone(330, 11, 0.22), 5.5),
          swell(tone(110, 11, 0.4), 8.0), noise(11, 0.06, 0.18)), 0.5)

# --- effects --------------------------------------------------------------
def ping(freq, dur, decay):
    buf = tone(freq, dur, 1.0)
    for i in range(len(buf)):
        buf[i] *= math.exp(-decay * i / RATE)
    return buf

write(SFX / "trowel_on_pottery.wav", mix(ping(1850, 0.5, 14), ping(2600, 0.4, 20),
                                         fade(noise(0.06, 0.8, 0.5), 0.001, 0.05)), 0.7)
write(SFX / "brush_on_stone.wav", fade(noise(0.8, 0.5, 0.8), 0.12, 0.5), 0.45)
write(SFX / "stone_grinding.wav", fade(mix(noise(2.2, 0.035, 1.0), tone(58, 2.2, 0.35)),
                                       0.25, 0.7), 0.6)
write(SFX / "water_roar.wav", fade(mix(noise(6.0, 0.10, 1.0), noise(6.0, 0.015, 0.7)),
                                   0.8, 1.2), 0.65)
write(SFX / "low_hum_begin.wav", fade(mix(tone(55, 3.0, 0.8), tone(82.5, 3.0, 0.3),
                                          tone(110, 3.0, 0.15)), 1.2, 0.8), 0.6)
write(SFX / "phone_shutter.wav", fade(noise(0.09, 0.9, 1.0), 0.001, 0.07), 0.7)

dial = []
for f1, f2 in [(697, 1209), (770, 1336), (852, 1477)]:
    dial += fade(mix(tone(f1, 0.12, 0.5), tone(f2, 0.12, 0.5)), 0.005, 0.02)
    dial += [0.0] * n(0.07)
write(SFX / "phone_dial.wav", dial, 0.5)

count = len(list(MUSIC.glob('*.wav'))) + len(list(SFX.glob('*.wav')))
print(f"{count} placeholder cues written")
for f in sorted(list(MUSIC.glob('*.wav')) + list(SFX.glob('*.wav'))):
    print(f"   {f.relative_to(ROOT)}")
print("\nPlaceholder only. Never commit, never ship.")
