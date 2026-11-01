#!/usr/bin/env python3
"""Generates the environment materials in game/materials/ as ShaderMaterials.

    python3 tools/materials.py

Palette values come straight from docs/ART-BIBLE.md §3. Change them there,
change them here, re-run; the whole level repaints because every box already
points at these files.

Character materials are deliberately NOT generated here — Eva should not have
brick courses on her.
"""
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game/materials"
STONE = "res://shaders/stone.gdshader"
WATER = "res://shaders/water.gdshader"


def rgb(h):
    h = h.lstrip("#")
    return tuple(round(int(h[i:i + 2], 16) / 255.0, 4) for i in (0, 2, 4))


def col(h, a=1.0):
    r, g, b = rgb(h)
    return "Color(%s, %s, %s, %s)" % (r, g, b, a)


def write(name, shader, params):
    body = "".join("shader_parameter/%s = %s\n" % (k, v) for k, v in params.items())
    (OUT / (name + ".tres")).write_text(
        '[gd_resource type="ShaderMaterial" load_steps=2 format=3]\n\n'
        '[ext_resource type="Shader" path="%s" id="1"]\n\n'
        '[resource]\nshader = ExtResource("1")\n%s' % (shader, body)
    )


# ART-BIBLE.md §3 — shared palette, then each era's own key/shade.
ERAS = {
    # Past accent is warm lime plaster, not the salt-white dust tone — a
    # Harappan street should have no cold colour in it at all.
    "past":    dict(base="#B5633C", light="#C98A3C", dark="#8A5134", accent="#CBA067",
                    bleach="#E8C089", shade="#5E3A28", rough=0.94),
    "present": dict(base="#A89A86", light="#C4B9A4", dark="#7E7468", accent="#D8CBB0",
                    bleach="#EDE7DA", shade="#6A6459", rough=0.96),
    "future":  dict(base="#55646E", light="#6E808C", dark="#39454E", accent="#7C8D96",
                    bleach="#8FA5B2", shade="#1B2433", rough=0.88),
}
# Only 2026 shows a dry waterline on the basin — in 1900 BCE the water is
# still there, and in 2087 it is over the top of everything.
# 2026 shows the dry ring where the reservoir used to reach; 2087 shows
# algae at the surface of the water that is there now.
WATERLINE = {"past": None, "present": -4.6, "future": 1.6}
WATERLINE_TINT = {"present": "#6F6A52", "future": "#3F5F4A"}

for era, p in ERAS.items():
    for suffix, key in [("", "base"), ("_light", "light"), ("_dark", "dark"), ("_accent", "accent")]:
        params = {
            "base_color": col(p[key]),
            "sun_bleach": col(p["bleach"]),
            "ground_shade": col(p["shade"]),
            "roughness_value": p["rough"],
            "course_height": 0.24,
            "course_length": 0.4,
            "mortar_depth": 0.15 if era == "past" else (0.11 if era == "present" else 0.07),
            "patch_strength": 0.16 if era == "past" else 0.22,
        }
        if WATERLINE[era] is not None:
            params.update({
                "waterline_enabled": "true",
                "waterline_height": WATERLINE[era],
                "waterline_width": 0.5 if era == "present" else 0.9,
                "waterline_color": col(WATERLINE_TINT[era]),
            })
        write("mat_%s%s" % (era, suffix), STONE, params)

    # Distant mesas: no brick, no courses — they are landform, not building.
    write("mat_hills_%s" % era, STONE, {
        "base_color": col(p["dark"]),
        "sun_bleach": col(p["bleach"]),
        "ground_shade": col(p["shade"]),
        "roughness_value": 1.0,
        "mortar_depth": 0.0,
        "patch_scale": 0.02,
        "patch_strength": 0.3,
    })

# Rubble and spoil: stone, but unbonded.
write("mat_rubble", STONE, {
    "base_color": col("#6B6158"), "sun_bleach": col("#9A9084"),
    "ground_shade": col("#3A342E"), "roughness_value": 1.0,
    "mortar_depth": 0.0, "patch_scale": 0.9, "patch_strength": 0.45,
})

# Water: one shader, three settings (ART-BIBLE.md §9).
write("mat_water_past", WATER, {
    "shallow_color": col("#2E7A74"), "deep_color": col("#17403F"),
    "opacity": 0.74, "motion": 0.30, "sparkle": 0.45, "wave_height": 0.015,
})
write("mat_water_future", WATER, {
    # Dead water, not calm water: almost no motion, almost no sparkle.
    "shallow_color": col("#3E5A66"), "deep_color": col("#141E28"),
    "opacity": 0.80, "motion": 0.12, "sparkle": 0.06, "wave_height": 0.008,
    "roughness_value": 0.03,
})

print("wrote %d materials to %s" % (len(list(OUT.glob('mat_*.tres'))), OUT))
