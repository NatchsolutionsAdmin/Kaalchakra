#!/usr/bin/env python3
"""Builds the Harappan modular kit and exports it as .glb for Godot.

    blender --background --python tools/blender/harappan_kit.py

Job 2 of docs/AI-FIRST-PRODUCTION.md. Every piece is generated, so the kit can
be rebuilt from scratch after any change to proportions — nothing here is
hand-modelled and nothing is licensed from anyone.

DESIGN
------
Harappan building is grids and bricks, which is exactly what a script is good
at. Real Dholavira brick is a 1:2:4 ratio; ours is 0.4 x 0.2 x 0.1 m, and the
whole kit snaps to a 0.4 m grid (ART-BIBLE.md §8).

Surface brick detail is NOT modelled — stone.gdshader draws the courses from
world position, for free, with no UVs and no textures. What geometry adds that
a shader cannot is SILHOUETTE: every third course steps back 15 mm, so walls
catch light in bands and read as hand-laid rather than extruded. That is the
whole division of labour here, and it keeps pieces inside the 200-2k triangle
budget.

No UV unwrap for the same reason: the shader is world-space.
"""
import json
import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

# --- the module ---------------------------------------------------------
BRICK_L, BRICK_W, BRICK_H = 0.4, 0.2, 0.1
GRID = 0.4                 # everything snaps to this
COURSE = 0.2               # one visible course = two bricks
SETBACK_EVERY = 3          # courses between silhouette steps
SETBACK = 0.015
# Most of the height a worn piece may lose, so the visual top never strays far
# from the collision box Godot keeps at full size.
MAX_LOSS = 0.22

SIZES = {}
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                       "game", "art", "kit")


# --- bmesh helpers ------------------------------------------------------

def box(bm, center, size):
    """An axis-aligned box. Sizes are full extents, not half."""
    verts = bmesh.ops.create_cube(bm, size=1.0)["verts"]
    bmesh.ops.scale(bm, vec=Vector(size), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    return verts


def coursed_wall(bm, length, height, thickness, origin=(0.0, 0.0, 0.0),
                 wear=0.0, seed=1):
    """A wall built as a stack of courses, stepping back every few rows.

    `wear` 0 is newly built; higher values eat the wall from the top down,
    which is how masonry actually fails — rain takes the capping first, then
    works down. Courses near the top lose individual bricks before whole rows
    go.

    Loss is deliberately capped at MAX_LOSS of the height. The collision box
    in Godot is the full original size, so a wall that looked half gone would
    be a wall you could not see but could not walk through either.

    Blender is Z-up; Godot is Y-up. The glTF exporter converts, so build in
    Blender's convention and forget about it.
    """
    ox, oy, oz = origin
    rnd = random.Random(seed)
    rows = max(1, int(round(height / COURSE)))
    keep_rows = rows if wear <= 0.0 else max(1, int(round(rows * (1.0 - MAX_LOSS * wear))))

    for i in range(rows):
        inset = SETBACK * (i // SETBACK_EVERY)
        t = max(0.08, thickness - inset * 2.0)
        z = oz + COURSE * (i + 0.5)

        if i >= keep_rows:
            continue

        # How exposed this course is: the top ones are chewed, the base is not.
        exposure = 0.0 if keep_rows < 2 else (i / float(keep_rows - 1))
        chew = wear * exposure

        if chew < 0.25:
            box(bm, (ox, oy, z), (length, t, COURSE * 0.98))
            continue

        # Near the top, lay the course brick by brick and drop some of them.
        n = max(1, int(round(length / BRICK_L)))
        bl = length / n
        for b in range(n):
            if rnd.random() < chew * 0.55:
                continue
            x = ox - length * 0.5 + bl * (b + 0.5)
            jitter = (rnd.random() - 0.5) * 0.02 * chew
            drop = rnd.random() * 0.035 * chew
            box(bm, (x + jitter, oy, z - drop), (bl * 0.97, t, COURSE * 0.98))
    return rows


def new_mesh(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bm = bmesh.new()
    return bm, name


def finish(bm, name):
    """Weld, recalculate normals, make a flat-shaded object, export."""
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.shade_flat()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.normpath(os.path.join(OUT_DIR, name + ".glb"))
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                              export_apply=True, export_yup=True)
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    # Record the piece's real size so the level generator can scale it to fit
    # without anyone hardcoding a number that later drifts.
    lo = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
    hi = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
    # Blender is Z-up, Godot is Y-up: x -> x, z -> y, y -> z.
    SIZES[name] = {
        "size": [round(hi[0] - lo[0], 4), round(hi[2] - lo[2], 4), round(hi[1] - lo[1], 4)],
        "base_offset": round(lo[2], 4),
        "tris": tris,
    }
    print("  %-22s %5d tris  %s" % (name, tris, path))
    return tris


# --- the pieces ---------------------------------------------------------

def wall_straight():
    bm, n = new_mesh("wall_straight")
    coursed_wall(bm, 2.4, 2.4, 0.4)
    return finish(bm, n)


def wall_low():
    bm, n = new_mesh("wall_low")
    coursed_wall(bm, 2.4, 1.2, 0.4)
    # Capping course, slightly proud: a parapet needs a lip to read.
    box(bm, (0, 0, 1.2 + 0.06), (2.5, 0.48, 0.12))
    return finish(bm, n)


def wall_corner():
    bm, n = new_mesh("wall_corner")
    coursed_wall(bm, 2.4, 2.4, 0.4, origin=(0, 0, 0))
    # The returning leg, rotated by building it on the other axis.
    rows = int(round(2.4 / COURSE))
    for i in range(rows):
        inset = SETBACK * (i // SETBACK_EVERY)
        t = max(0.08, 0.4 - inset * 2.0)
        z = COURSE * (i + 0.5)
        box(bm, (1.0, 1.0, z), (t, 2.0, COURSE * 0.98))
    return finish(bm, n)


def doorway():
    bm, n = new_mesh("doorway")
    # Two piers and a lintel. Opening 1.2 x 2.0, which clears Eva at 1.75 m.
    for side in (-1, 1):
        coursed_wall(bm, 0.6, 2.0, 0.4, origin=(side * 0.9, 0, 0))
    box(bm, (0, 0, 2.0 + 0.15), (2.4, 0.46, 0.3))      # lintel
    box(bm, (0, 0, 2.0 + 0.38), (2.4, 0.42, 0.16))     # relieving course
    return finish(bm, n)


def stair_flight():
    bm, n = new_mesh("stair_flight")
    # 0.6 m risers, under the 0.7 m auto-climb so a thumb never taps jump
    # (ART-BIBLE.md §8 — a gameplay rule that overrides visual preference).
    rise, tread, width = 0.6, 0.8, 2.4
    for i in range(4):
        h = rise * (i + 1)
        box(bm, (0, -tread * i, h * 0.5), (width, tread, h))
    return finish(bm, n)


def reservoir_step():
    bm, n = new_mesh("reservoir_step")
    # One tread of the stepped basin, with a lipped nose.
    box(bm, (0, 0, 0.3), (2.4, 0.75, 0.6))
    box(bm, (0, -0.37, 0.57), (2.4, 0.12, 0.08))
    return finish(bm, n)


def drain_channel():
    bm, n = new_mesh("drain_channel")
    # A U-section run of covered drain — the thing Sakshi keeps telling Eva to
    # look at instead of the walls.
    box(bm, (-0.3, 0, 0.2), (0.2, 2.4, 0.4))
    box(bm, (0.3, 0, 0.2), (0.2, 2.4, 0.4))
    box(bm, (0, 0, 0.05), (0.8, 2.4, 0.1))
    for i in range(3):
        box(bm, (0, -0.8 + i * 0.8, 0.44), (0.9, 0.7, 0.08))  # capstones
    return finish(bm, n)


def pillar_base():
    bm, n = new_mesh("pillar_base")
    box(bm, (0, 0, 0.1), (1.0, 1.0, 0.2))
    box(bm, (0, 0, 0.3), (0.8, 0.8, 0.2))
    box(bm, (0, 0, 0.75), (0.5, 0.5, 0.7))
    return finish(bm, n)


def tower_section():
    bm, n = new_mesh("tower_section")
    # Stackable gate-tower block, battered slightly inward as real mud-brick
    # towers are.
    rows = int(round(2.4 / COURSE))
    for i in range(rows):
        shrink = i * 0.012
        z = COURSE * (i + 0.5)
        box(bm, (0, 0, z), (3.0 - shrink * 2, 3.0 - shrink * 2, COURSE * 0.98))
    return finish(bm, n)


def platform_edge():
    bm, n = new_mesh("platform_edge")
    box(bm, (0, 0, 0.15), (2.4, 1.2, 0.3))
    box(bm, (0, -0.5, 0.38), (2.4, 0.2, 0.16))
    return finish(bm, n)


def signboard_frame():
    bm, n = new_mesh("signboard_frame")
    # The ten-sign board above the north gate. Recesses only — the signs
    # themselves are separate so they can erode per era.
    box(bm, (0, 0, 0.9), (7.0, 0.3, 0.25))      # lower rail
    box(bm, (0, 0, 2.05), (7.0, 0.3, 0.25))     # upper rail
    for side in (-1, 1):
        box(bm, (side * 3.37, 0, 1.48), (0.26, 0.3, 1.4))
    box(bm, (0, 0.1, 1.48), (6.5, 0.1, 1.0))    # back panel
    return finish(bm, n)


# --- era variants -------------------------------------------------------
# Same pieces, chewed. 2026 has lost its capping to four thousand years of
# monsoon; 2087 has been underwater for sixty on top of that.
WEAR = {"eroded": 0.45, "collapsed": 0.8}


def worn_wall(suffix, wear):
    def build():
        bm, n = new_mesh("wall_straight_" + suffix)
        coursed_wall(bm, 2.4, 2.4, 0.4, wear=wear, seed=hash(suffix) & 0xffff)
        return finish(bm, n)
    return build


def worn_low(suffix, wear):
    def build():
        bm, n = new_mesh("wall_low_" + suffix)
        coursed_wall(bm, 2.4, 1.2, 0.4, wear=wear, seed=7 + len(suffix))
        if wear < 0.6:
            box(bm, (0, 0, 1.2 + 0.06), (2.2, 0.48, 0.12))  # capping, part gone
        return finish(bm, n)
    return build


def worn_tower(suffix, wear):
    def build():
        bm, n = new_mesh("tower_section_" + suffix)
        rnd = random.Random(31 + len(suffix))
        rows = int(round(2.4 / COURSE))
        keep = max(1, int(round(rows * (1.0 - MAX_LOSS * wear))))
        for i in range(keep):
            shrink = i * 0.012
            z = COURSE * (i + 0.5)
            side = 3.0 - shrink * 2
            if i / float(max(1, keep - 1)) > 0.55 and rnd.random() < wear * 0.5:
                # A corner gone from an upper course.
                box(bm, (-side * 0.15, 0, z), (side * 0.7, side, COURSE * 0.98))
            else:
                box(bm, (0, 0, z), (side, side, COURSE * 0.98))
        return finish(bm, n)
    return build


def worn_platform(suffix, wear):
    def build():
        bm, n = new_mesh("platform_edge_" + suffix)
        box(bm, (0, 0, 0.15), (2.4, 1.2, 0.3))
        if wear < 0.6:
            box(bm, (-0.3, -0.5, 0.38), (1.6, 0.2, 0.16))  # nosing, part lost
        return finish(bm, n)
    return build


PIECES = [wall_straight, wall_low, wall_corner, doorway, stair_flight,
          reservoir_step, drain_channel, pillar_base, tower_section,
          platform_edge, signboard_frame]
for _suffix, _wear in WEAR.items():
    PIECES += [worn_wall(_suffix, _wear), worn_low(_suffix, _wear),
               worn_tower(_suffix, _wear), worn_platform(_suffix, _wear)]


def main():
    print("\nHarappan kit — brick %gx%gx%g m, grid %g m\n" % (BRICK_L, BRICK_W, BRICK_H, GRID))
    total = 0
    for piece in PIECES:
        total += piece()
    index = os.path.normpath(os.path.join(OUT_DIR, "kit_sizes.json"))
    with open(index, "w") as f:
        json.dump(SIZES, f, indent=2, sort_keys=True)
    print("\n  %d pieces, %d triangles total" % (len(PIECES), total))
    print("  sizes written to %s\n" % index)


if __name__ == "__main__":
    main()
