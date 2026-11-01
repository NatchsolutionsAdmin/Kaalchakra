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
import math
import os
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

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                       "game", "art", "kit")


# --- bmesh helpers ------------------------------------------------------

def box(bm, center, size):
    """An axis-aligned box. Sizes are full extents, not half."""
    verts = bmesh.ops.create_cube(bm, size=1.0)["verts"]
    bmesh.ops.scale(bm, vec=Vector(size), verts=verts)
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    return verts


def coursed_wall(bm, length, height, thickness, origin=(0.0, 0.0, 0.0)):
    """A wall built as a stack of courses, stepping back every few rows.

    Blender is Z-up; Godot is Y-up. The glTF exporter converts, so build in
    Blender's convention and forget about it.
    """
    ox, oy, oz = origin
    rows = max(1, int(round(height / COURSE)))
    for i in range(rows):
        inset = SETBACK * (i // SETBACK_EVERY)
        t = max(0.08, thickness - inset * 2.0)
        z = oz + COURSE * (i + 0.5)
        box(bm, (ox, oy, z), (length, t, COURSE * 0.98))
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


PIECES = [wall_straight, wall_low, wall_corner, doorway, stair_flight,
          reservoir_step, drain_channel, pillar_base, tower_section,
          platform_edge, signboard_frame]


def main():
    print("\nHarappan kit — brick %gx%gx%g m, grid %g m\n" % (BRICK_L, BRICK_W, BRICK_H, GRID))
    total = 0
    for piece in PIECES:
        total += piece()
    print("\n  %d pieces, %d triangles total\n" % (len(PIECES), total))


if __name__ == "__main__":
    main()
