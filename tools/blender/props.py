#!/usr/bin/env python3
"""Props for all three eras, generated and exported as .glb.

    blender --background --python tools/blender/props.py

Job 2 item 4. Same rules as the kit: scripted, no third-party assets, low
poly, no UVs (stone.gdshader and the material palette do the surface work).

Round things are built from 10-12 sided cylinders on purpose. At phone
resolution and a 3rd-person distance that reads as round, and it costs a
fraction of a smooth one — this is the "stylized, not low-poly-faceted as a
style" line from ART-BIBLE.md §1: few polygons, but we do not celebrate it.
"""
import json
import math
import os

import bpy
import bmesh
from mathutils import Vector

SIZES = {}
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                       "game", "art", "props")


def box(bm, center, size, rot_z=0.0):
    verts = bmesh.ops.create_cube(bm, size=1.0)["verts"]
    bmesh.ops.scale(bm, vec=Vector(size), verts=verts)
    if rot_z:
        bmesh.ops.rotate(bm, verts=verts, cent=(0, 0, 0),
                         matrix=__import__("mathutils").Matrix.Rotation(rot_z, 3, "Z"))
    bmesh.ops.translate(bm, vec=Vector(center), verts=verts)
    return verts


def drum(bm, center, r_bottom, r_top, height, segments=10):
    """A tapered cylinder — pots, baskets, drone bodies, poles."""
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False,
                                segments=segments, radius1=r_bottom,
                                radius2=r_top, depth=height)
    bmesh.ops.translate(bm, vec=Vector(center), verts=res["verts"])
    return res["verts"]


def new_mesh(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    return bmesh.new(), name


def finish(bm, name):
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
    lo = [min(v.co[i] for v in mesh.vertices) for i in range(3)]
    hi = [max(v.co[i] for v in mesh.vertices) for i in range(3)]
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    SIZES[name] = {"size": [round(hi[0] - lo[0], 4), round(hi[2] - lo[2], 4),
                            round(hi[1] - lo[1], 4)],
                   "base_offset": round(lo[2], 4), "tris": tris}
    print("  %-18s %4d tris" % (name, tris))
    return tris


# --- 1900 BCE ------------------------------------------------------------

def pot_large():
    bm, n = new_mesh("pot_large")
    drum(bm, (0, 0, 0.30), 0.22, 0.34, 0.60, 12)   # swelling belly
    drum(bm, (0, 0, 0.66), 0.34, 0.16, 0.12, 12)   # shoulder
    drum(bm, (0, 0, 0.76), 0.14, 0.17, 0.08, 12)   # rim
    return finish(bm, n)


def pot_small():
    bm, n = new_mesh("pot_small")
    drum(bm, (0, 0, 0.17), 0.14, 0.20, 0.34, 10)
    drum(bm, (0, 0, 0.38), 0.20, 0.11, 0.08, 10)
    return finish(bm, n)


def basket():
    bm, n = new_mesh("basket")
    drum(bm, (0, 0, 0.16), 0.24, 0.30, 0.32, 10)
    drum(bm, (0, 0, 0.34), 0.31, 0.31, 0.04, 10)   # woven rim
    return finish(bm, n)


def grain_sack():
    bm, n = new_mesh("grain_sack")
    box(bm, (0, 0, 0.18), (0.42, 0.30, 0.36))
    box(bm, (0, 0, 0.40), (0.26, 0.20, 0.10))      # tied neck
    return finish(bm, n)


def handcart():
    bm, n = new_mesh("handcart")
    box(bm, (0, 0, 0.52), (1.10, 0.70, 0.22))      # bed
    for side in (-1, 1):
        box(bm, (0, side * 0.33, 0.70), (1.10, 0.05, 0.18))
    for side in (-1, 1):                           # wheels
        drum(bm, (0, side * 0.40, 0.34), 0.34, 0.34, 0.07, 12)
    box(bm, (0.78, 0, 0.56), (0.55, 0.06, 0.06))   # shaft
    return finish(bm, n)


# --- 2026 ----------------------------------------------------------------

def dig_tent():
    bm, n = new_mesh("dig_tent")
    box(bm, (0, 0, 1.05), (2.60, 2.20, 0.10))      # tarp roof
    for x in (-1.2, 1.2):
        for y in (-1.0, 1.0):
            box(bm, (x, y, 0.52), (0.07, 0.07, 1.05))
    box(bm, (0, 1.05, 0.70), (2.60, 0.06, 0.70))   # one side sheeted
    return finish(bm, n)


def field_crate():
    bm, n = new_mesh("field_crate")
    box(bm, (0, 0, 0.26), (0.72, 0.48, 0.52))
    box(bm, (0, 0, 0.54), (0.76, 0.52, 0.05))      # lid lip
    return finish(bm, n)


def survey_tripod():
    bm, n = new_mesh("survey_tripod")
    import mathutils
    for i in range(3):
        a = i * (2.0 * math.pi / 3.0)
        verts = bmesh.ops.create_cube(bm, size=1.0)["verts"]
        bmesh.ops.scale(bm, vec=Vector((0.035, 0.035, 1.30)), verts=verts)
        bmesh.ops.rotate(bm, verts=verts, cent=(0, 0, 0),
                         matrix=mathutils.Matrix.Rotation(0.22, 3, "Y"))
        bmesh.ops.rotate(bm, verts=verts, cent=(0, 0, 0),
                         matrix=mathutils.Matrix.Rotation(a, 3, "Z"))
        bmesh.ops.translate(bm, vec=Vector((0, 0, 0.65)), verts=verts)
    drum(bm, (0, 0, 1.36), 0.11, 0.09, 0.12, 8)    # instrument head
    return finish(bm, n)


def spoil_bucket():
    bm, n = new_mesh("spoil_bucket")
    drum(bm, (0, 0, 0.15), 0.16, 0.21, 0.30, 10)
    drum(bm, (0, 0, 0.31), 0.22, 0.22, 0.03, 10)
    return finish(bm, n)


# --- 2087 ----------------------------------------------------------------

def archive_drone():
    bm, n = new_mesh("archive_drone")
    drum(bm, (0, 0, 0), 0.26, 0.26, 0.14, 12)      # body
    drum(bm, (0, 0, 0.10), 0.13, 0.08, 0.08, 10)   # sensor dome
    for i in range(4):                             # fins
        a = i * (math.pi / 2.0)
        box(bm, (math.cos(a) * 0.30, math.sin(a) * 0.30, 0),
            (0.20, 0.05, 0.04), rot_z=a)
    return finish(bm, n)


def scan_pylon():
    bm, n = new_mesh("scan_pylon")
    drum(bm, (0, 0, 0.12), 0.26, 0.20, 0.24, 10)   # base
    drum(bm, (0, 0, 1.80), 0.07, 0.05, 3.40, 8)    # mast
    box(bm, (0, 0, 3.58), (0.30, 0.08, 0.22))      # emitter
    return finish(bm, n)


PROPS = [pot_large, pot_small, basket, grain_sack, handcart,
         dig_tent, field_crate, survey_tripod, spoil_bucket,
         archive_drone, scan_pylon]


def main():
    print("\nProps\n")
    total = sum(p() for p in PROPS)
    index = os.path.normpath(os.path.join(OUT_DIR, "prop_sizes.json"))
    with open(index, "w") as f:
        json.dump(SIZES, f, indent=2, sort_keys=True)
    print("\n  %d props, %d triangles total\n" % (len(PROPS), total))


if __name__ == "__main__":
    main()
