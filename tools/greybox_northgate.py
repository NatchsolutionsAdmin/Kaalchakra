#!/usr/bin/env python3
"""Generates game/scenes/locations/NorthGate.tscn — the greybox of Dholarath's
north gate, the stepped reservoir below it, and the market street running east,
in all three eras.

Run once to lay the geometry out numerically. After that the .tscn is the source
of truth: edit boxes in the Godot editor, not here. Re-running overwrites.

    python3 tools/greybox_northgate.py

Layout (Godot: Y up, -Z north, +X east). Harappan proportions, scaled down to
something walkable in about a minute:
  * north gate + city wall along z = -30, 6 m opening at x = 0
  * stepped reservoir sunk 7 m into the ground, x -16..6, z -22..-4
  * market street east along z = -13, buildings either side
  * citadel edge wall to the west at x = -23
"""
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game/scenes/locations/NorthGate.tscn"

# era tag -> (node name, Era.Id value, collision layer bit)
ERAS = [("past", "Past", 0, 2), ("present", "Present", 1, 4), ("future", "Future", 2, 8)]

MARKET_X = [12, 19, 26, 33, 40, 47]


def tone(tag, i):
    """Pick one of the era's four tones. Deterministic, so the look is stable
    across regenerations — a street of identical boxes reads as unfinished."""
    return [f"mat_{tag}", f"mat_{tag}_light", f"mat_{tag}_dark", f"mat_{tag}_accent"][i % 4]


def rng(seed):
    """Tiny deterministic generator. Scatter must be identical every run, or
    the .tscn churns in git for no reason."""
    state = seed

    def nxt(lo, hi):
        nonlocal state
        state = (1103515245 * state + 12345) % 2147483648
        return lo + (state / 2147483648.0) * (hi - lo)

    return nxt


def structure(tag):
    """Geometry that exists in every era: ground, the reservoir, the citadel edge."""
    base, acc = f"mat_{tag}", f"mat_{tag}_accent"
    out = [
        # Ground, built as four slabs around the reservoir footprint so the pit
        # is a real hole without needing CSG boolean subtraction.
        # Pushed far past the play space: with fog and the distant mesas, the
        # player never sees the edge of the world.
        ("GroundWest",  (-108, -0.5, -20), (184, 1, 400), base),
        ("GroundEast",  (123, -0.5, -20),  (234, 1, 400), base),
        ("GroundNorth", (-5, -0.5, -121),  (22, 1, 198),  base),
        ("GroundSouth", (-5, -0.5, 88),    (22, 1, 184),  base),
        # The great reservoir: floor at y = -7, sheer on three sides.
        ("BasinFloor",      (-5, -7.5, -13),     (22, 1, 18),   base),
        ("BasinWallWest",   (-15.25, -3.5, -13), (1.5, 7, 18),  acc),
        ("BasinWallEast",   (5.25, -3.5, -13),   (1.5, 7, 18),  acc),
        ("BasinWallSouth",  (-5, -3.5, -4.75),   (22, 7, 1.5),  acc),
    ]
    # Stepped descent on the north side — Dholavira's reservoirs are stepped.
    # 12 risers of 0.58 m: human-scale, and low enough that auto-climb carries
    # the whole flight. At 1.4 m a phone player had to jump every single step.
    rise = 7.0 / 12.0
    tread = 0.75
    for i in range(11):
        top = -rise * (i + 1)
        h = top + 7.0
        out.append((f"BasinStep{i:02d}",
                    (-5, -7.0 + h / 2.0, -22 + tread * i + tread / 2.0),
                    (20.5, h, tread), acc))
    # A stack of ledges east of the basin that teaches the two traversal verbs:
    # 1.1 m up onto A is a plain jump; A->B is 1.8 m and B->C is 2.0 m, both
    # above what she can jump, so they can only be taken by pulling up.
    out += [
        ("LedgeA", (8.5, 0.55, -20), (3, 1.1, 3), acc),
        ("LedgeB", (8.5, 1.45, -17), (3, 2.9, 3), acc),
        ("LedgeC", (8.5, 2.45, -14), (3, 4.9, 3), acc),
    ]
    return out


def market(tag, north_h, south_h, parapets=False):
    out = []
    for side, zc, heights, off in (("North", -21, north_h, 0), ("South", -5, south_h, 2)):
        for i, (x, h) in enumerate(zip(MARKET_X, heights)):
            out.append((f"Street{side}{i}", (x, h / 2.0, zc), (5, h, 6), tone(tag, i + off)))
            if parapets:
                # A lip on each roof. Costs one box and does more for the
                # skyline than any amount of texture would.
                out.append((f"Street{side}{i}Parapet", (x, h + 0.2, zc), (5.4, 0.4, 6.4),
                            tone(tag, i + off + 2)))
    return out


def horizon(tag):
    """A ring of low mesas framing the valley. Flat, desaturated, far away."""
    import math
    out = []
    mat = f"mat_hills_{tag}"
    for i in range(14):
        a = (i / 14.0) * math.tau + 0.35
        r = 190.0 + (i % 5) * 26.0
        x = 5.0 + math.cos(a) * r
        z = -20.0 + math.sin(a) * r
        h = 14.0 + (i % 4) * 9.0
        w = 46.0 + (i % 3) * 22.0
        d = 38.0 + (i % 5) * 16.0
        out.append((f"Mesa{i:02d}", (x, h / 2.0 - 1.0, z), (w, h, d), mat))
    return out


def citadel(tag):
    """The upper town behind the west wall: a raised mass with a stepped edge,
    so the skyline has something above the wall line."""
    out = [
        ("CitadelPlatform", (-40, 2.5, -15), (32, 5, 34), tone(tag, 2)),
        ("CitadelBlockA", (-34, 7.5, -22), (9, 5, 9), tone(tag, 0)),
        ("CitadelBlockB", (-44, 9.0, -12), (11, 8, 11), tone(tag, 1)),
        ("CitadelBlockC", (-30, 6.5, -6), (8, 3, 8), tone(tag, 3)),
    ]
    for i in range(3):
        out.append((f"CitadelStep{i}", (-23.5 + i * 0.9, 0.75 + i * 1.5, -15),
                    (1.8, 1.5 + i * 3.0, 34), tone(tag, i + 1)))
    return out


def scatter(tag, seed, count, lo, hi):
    """Rubble and drifts. Breaks up the flat ground without costing much."""
    nxt = rng(seed)
    out = []
    for i in range(count):
        # Keep the apron, the basin and the spawn point clear.
        while True:
            x = nxt(-20.0, 52.0)
            z = nxt(-34.0, 2.0)
            if not (-17.0 < x < 8.0 and -24.0 < z < -2.0) and abs(x) + abs(z + 26.0) > 7.0:
                break
        h = nxt(lo, hi)
        out.append((f"Debris{i:02d}", (x, h / 2.0 - 0.1, z),
                    (nxt(0.8, 2.6), h, nxt(0.8, 2.6)), tone(tag, i)))
    return out


def gate_past():
    return [
        ("GateWallWest", (-14.5, 3.5, -30), (23, 7, 2),   "mat_past"),
        ("GateWallEast", (18.5, 3.5, -30),  (31, 7, 2),   "mat_past"),
        ("GateTowerWest", (-4.5, 5, -30),   (3, 10, 4),   "mat_past_accent"),
        ("GateTowerEast", (4.5, 5, -30),    (3, 10, 4),   "mat_past_accent"),
        ("GateLintel", (0, 6.75, -30),      (6, 1.5, 2),  "mat_past_accent"),
        ("Signboard", (0, 8.4, -31.05),     (7, 1.6, 0.5), "mat_past_accent"),
    ] + [
        # The real Dholavira signboard carries ten signs. All ten are here in 1900 BCE.
        (f"Sign{i}", (-2.9 + i * 0.644, 8.4, -31.45), (0.4, 0.7, 0.2), "mat_marker")
        for i in range(10)
    ]


def gate_present():
    return [
        ("GateWallWest", (-14.5, 2.0, -30), (23, 4, 2),    "mat_present"),
        ("GateWallEast", (18.5, 2.25, -30), (31, 4.5, 2),  "mat_present"),
        ("GateTowerWest", (-4.5, 3, -30),   (3, 6, 4),     "mat_present_accent"),
        ("GateTowerEast", (4.5, 2.5, -30),  (3, 5, 4),     "mat_present_accent"),
        ("GateLintel", (0, 4.5, -30),       (6, 1, 2),     "mat_present_accent"),
        ("Signboard", (0, 5.6, -31.05),     (5.5, 1.2, 0.5), "mat_present_accent"),
        # Four thousand years of salt: seven of the ten signs are gone.
        ("Sign2", (-1.3, 5.6, -31.4), (0.35, 0.55, 0.2), "mat_marker"),
        ("Sign5", (0.4, 5.6, -31.4),  (0.35, 0.55, 0.2), "mat_marker"),
        ("Sign8", (1.8, 5.6, -31.4),  (0.35, 0.55, 0.2), "mat_marker"),
        # The gate itself has fallen in. This passage is open in 1900 BCE only.
        ("GateRubble", (0, 1.3, -30), (6, 2.6, 3), "mat_rubble"),
    ]


def gate_future():
    return [
        ("GateWallWest", (-14.5, 0.75, -30), (23, 1.5, 2), "mat_future"),
        ("GateWallEast", (18.5, 0.9, -30),   (31, 1.8, 2), "mat_future"),
        ("GateTowerWest", (-4.5, 1.5, -30),  (3, 3, 4),    "mat_future_accent"),
        ("GateTowerEast", (4.5, 1.1, -30),   (3, 2.2, 4),  "mat_future_accent"),
    ]


def extras_past():
    out = (gate_past()
           + market("past", [5, 8.5, 4.5, 9.5, 5.5, 7], [7, 4.5, 6.5, 5, 8.5, 4], parapets=True)
           + horizon("past") + citadel("past") + scatter("past", 11, 14, 0.3, 0.9))
    for i, x in enumerate([15, 22, 29, 36, 43]):
        z = -15 if i % 2 == 0 else -11
        out.append((f"Stall{i}", (x, 0.9, z), (2, 1.8, 2), "mat_past_accent"))
    return out


def extras_present():
    out = (gate_present()
           + market("present", [1.2, 1.9, 0.9, 1.6, 1.1, 1.7], [1.4, 0.9, 1.3, 1.0, 1.8, 0.8])
           + horizon("present") + citadel("present") + scatter("present", 29, 18, 0.2, 0.8))
    out += [
        ("SpoilHeapA", (-9, 0.6, -25),     (4, 1.2, 3),     "mat_present"),
        ("SpoilHeapB", (-13, 0.5, -27.5),  (3.5, 1, 3),     "mat_present"),
        ("HelixContainer", (11, 1.4, -26), (6, 2.8, 2.6),   "mat_helix"),
    ]
    for i, x in enumerate([-8, -4, 0, 4]):
        out.append((f"ScaffoldPole{i}", (x, 1.5, -22.6), (0.12, 3, 0.12), "mat_present_accent"))
    for i in range(6):
        out.append((f"SurveyPeg{i}", (-14 + i * 3.6, 0.6, -24), (0.1, 1.2, 0.1), "mat_marker"))
    return out


def extras_future():
    out = (gate_future()
           + market("future", [2.2, 3.4, 1.6, 2.9, 1.9, 3.1], [2.6, 1.7, 2.3, 1.8, 3.2, 1.4])
           + horizon("future") + citadel("future") + scatter("future", 47, 16, 0.2, 0.7))
    out += [
        ("SiltMoundA", (-9, -6.6, -12), (6, 0.8, 5), "mat_future"),
        ("SiltMoundB", (0, -6.75, -9),  (5, 0.5, 4), "mat_future"),
        ("DronePylonA", (-8, 3, -25),   (0.5, 6, 0.5), "mat_drone"),
        ("DronePylonB", (12, 3, -13),   (0.5, 6, 0.5), "mat_drone"),
        ("DronePylonC", (-20, 3, -10),  (0.5, 6, 0.5), "mat_drone"),
    ]
    return out


# --- the cross-era puzzle ------------------------------------------------
# Same x, twelve metres apart in z: the mark is on the apron in 1900 BCE, the
# chamber is under the basin floor in 2026. Learn it in one era, dig in another.
MARK_POS = (3, 0.1, -25)
DIG_POS = (3, -6.96, -13)

KEEPER_LINE = (
    "A slab cut flush with the pavement, and on it one sign she does know — "
    "the Keeper's mark. Beneath it, a measure: twelve paces south, under the "
    "floor of the great basin.  \"Four thousand years. Let's see if your "
    "masonry holds, whoever you were.\""
)
CHAMBER_LINE = (
    "The brush turns up a lintel, then a sealed stone face, then signs — "
    "and across the header, ten of them in a row she can finally read:\n\n"
    "WHAT THE WATER MUST NOT TAKE"
)
LOCKED_LINE = (
    "Silt, salt, and more silt. Nothing down here marks a spot. She needs to be "
    "told where to dig — and 2026 has nobody left who knows."
)
WARDEN_LINE = (
    "ARCHIVE NODE 11-DH. FLOOD BAND: PERMANENT. CATALOGUE STATUS: COMPLETE, "
    "UNCOLLECTED.  AWAITING KEEPER CREDENTIAL — SIXTY-ONE YEARS, FOUR MONTHS."
)


def esc(s):
    """Escape a string for a .tscn string literal."""
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def fmt(v):
    """Godot writes floats without a trailing .0 only for ints; keep it simple."""
    return ("%g" % v)


def xform(pos):
    return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % tuple(fmt(c) for c in pos)


def scale_xform(size, pos=(0, 0, 0)):
    """Transform that scales the shared unit cube to `size` at `pos`."""
    sx, sy, sz = (fmt(c) for c in size)
    return "Transform3D(%s, 0, 0, 0, %s, 0, 0, 0, %s, %s, %s, %s)" % (
        sx, sy, sz, *(fmt(c) for c in pos))


def vec3(s):
    return "Vector3(%s, %s, %s)" % tuple(fmt(c) for c in s)


def main():
    ext = {}        # path -> id
    sub = []        # (id, type, body)
    nodes = []

    def ext_id(path, rtype):
        if path not in ext:
            ext[path] = ("ext_%d" % (len(ext) + 1), rtype)
        return ext[path][0]

    def mat(key):
        return ext_id("res://materials/%s.tres" % key, "Material")

    nodes.append('[node name="NorthGate" type="Node3D"]\n')

    era_root_script = ext_id("res://scripts/world/era_root.gd", "Script")
    lore_script = ext_id("res://scripts/interact/lore_marker.gd", "Script")
    dig_script = ext_id("res://scripts/interact/dig_site.gd", "Script")

    sub.append(("SphereShape3D_reach", "SphereShape3D", "radius = 2.6\n"))
    # Every greybox box renders from this one mesh, scaled. One resource for the
    # whole level lets the renderer batch them, which CSG could never do.
    sub.append(("BoxMesh_unit", "BoxMesh", "size = %s\n" % vec3((1, 1, 1))))
    box_shapes = {}

    def shape_id(size):
        key = tuple(round(c, 4) for c in size)
        if key not in box_shapes:
            sid = "BoxShape3D_%d" % (len(box_shapes) + 1)
            box_shapes[key] = sid
            sub.append((sid, "BoxShape3D", "size = %s\n" % vec3(size)))
        return box_shapes[key]

    def emit_box(name, parent, pos, size, matkey, layer):
        """One solid greybox box: a static body with a mesh and a shape."""
        nodes.append(
            '[node name="%s" type="StaticBody3D" parent="%s"]\n'
            'transform = %s\n'
            'collision_layer = %d\n'
            'collision_mask = 0\n' % (name, parent, xform(pos), layer)
        )
        nodes.append(
            '[node name="Mesh" type="MeshInstance3D" parent="%s/%s"]\n'
            'transform = %s\n'
            'mesh = SubResource("BoxMesh_unit")\n'
            'material_override = ExtResource("%s")\n'
            % (parent, name, scale_xform(size), mat(matkey))
        )
        nodes.append(
            '[node name="Shape" type="CollisionShape3D" parent="%s/%s"]\n'
            'shape = SubResource("%s")\n' % (parent, name, shape_id(size))
        )

    def emit_decal(name, parent, pos, size, matkey):
        """Visual only — no collision, so it never becomes a lip to trip on."""
        nodes.append(
            '[node name="%s" type="MeshInstance3D" parent="%s"]\n'
            'transform = %s\n'
            'mesh = SubResource("BoxMesh_unit")\n'
            'material_override = ExtResource("%s")\n'
            % (name, parent, scale_xform(size, pos), mat(matkey))
        )

    for tag, era_name, era_value, layer in ERAS:
        nodes.append(
            '[node name="%s" type="Node3D" parent="."]\n'
            'script = ExtResource("%s")\n'
            'era_id = %d\n' % (era_name, era_root_script, era_value)
        )

        boxes = structure(tag) + {"past": extras_past, "present": extras_present,
                                  "future": extras_future}[tag]()
        for name, pos, size, matkey in boxes:
            emit_box(name, era_name, pos, size, matkey, layer)

        # Water. A plain MeshInstance3D, so Eva walks through it — swimming is
        # not a verb in this game yet.
        if tag == "past":
            nodes.append(
                '[node name="WaterOneThird" type="MeshInstance3D" parent="Past"]\n'
                'transform = %s\n'
                'mesh = SubResource("BoxMesh_unit")\n'
                'material_override = ExtResource("%s")\n'
                % (scale_xform((19, 0.2, 16.5), (-5, -4.67, -13.75)), mat("mat_water_past"))
            )
        if tag == "future":
            nodes.append(
                '[node name="FloodPlane" type="MeshInstance3D" parent="Future"]\n'
                'transform = %s\n'
                'mesh = SubResource("BoxMesh_unit")\n'
                'material_override = ExtResource("%s")\n'
                % (scale_xform((132, 0.2, 62), (5, 1.6, -20)), mat("mat_water_future"))
            )

    # --- PAST: the Keeper's mark (teaches the location) ---
    emit_decal("KeeperMarkSlab", "Past", MARK_POS, (2, 0.2, 2), "mat_marker")
    nodes.append(
        '[node name="KeeperMark" type="Area3D" parent="Past"]\n'
        'transform = %s\n'
        'script = ExtResource("%s")\n'
        'prompt = "Read the Keeper\'s mark"\n'
        'line = "%s"\n'
        'grants_knowledge = "keeper_mark"\n'
        % (xform((MARK_POS[0], MARK_POS[1] + 0.6, MARK_POS[2])), lore_script, esc(KEEPER_LINE))
    )
    nodes.append(
        '[node name="Reach" type="CollisionShape3D" parent="Past/KeeperMark"]\n'
        'shape = SubResource("SphereShape3D_reach")\n'
    )

    # --- PRESENT: the same spot, twelve paces south, under the basin floor ---
    emit_decal("DigPatch", "Present", DIG_POS, (2.4, 0.1, 2.4), "mat_dig")
    nodes.append(
        '[node name="ChamberHatch" type="MeshInstance3D" parent="Present"]\n'
        'transform = %s\n'
        'mesh = SubResource("BoxMesh_unit")\n'
        'material_override = ExtResource("%s")\n'
        'visible = false\n'
        % (scale_xform((2.2, 0.9, 2.2), (DIG_POS[0], DIG_POS[1] + 0.45, DIG_POS[2])),
           mat("mat_chamber"))
    )
    nodes.append(
        '[node name="DigSite" type="Area3D" parent="Present"]\n'
        'transform = %s\n'
        'script = ExtResource("%s")\n'
        'prompt = "Excavate"\n'
        'requires_knowledge = "keeper_mark"\n'
        'dig_seconds = 2.6\n'
        'grants_knowledge = "chamber_opened"\n'
        'line_locked = "%s"\n'
        'line_done = "%s"\n'
        'reveal_path = NodePath("../ChamberHatch")\n'
        % (xform((DIG_POS[0], DIG_POS[1] + 0.6, DIG_POS[2])), dig_script, esc(LOCKED_LINE), esc(CHAMBER_LINE))
    )
    nodes.append(
        '[node name="Reach" type="CollisionShape3D" parent="Present/DigSite"]\n'
        'shape = SubResource("SphereShape3D_reach")\n'
    )

    # --- FUTURE: WARDEN, for anyone who goes looking ---
    nodes.append(
        '[node name="WardenNode" type="Area3D" parent="Future"]\n'
        'transform = %s\n'
        'script = ExtResource("%s")\n'
        'prompt = "Query the archive node"\n'
        'line = "%s"\n'
        % (xform((-8, 1.2, -25)), lore_script, esc(WARDEN_LINE))
    )
    nodes.append(
        '[node name="Reach" type="CollisionShape3D" parent="Future/WardenNode"]\n'
        'shape = SubResource("SphereShape3D_reach")\n'
    )

    # --- assemble ---
    header_ext = "".join(
        '[ext_resource type="%s" path="%s" id="%s"]\n' % (rtype, path, rid)
        for path, (rid, rtype) in ext.items()
    )
    header_sub = "".join(
        '[sub_resource type="%s" id="%s"]\n%s\n' % (stype, sid, body) for sid, stype, body in sub
    )
    load_steps = len(ext) + len(sub) + 1
    text = (
        "; Greybox of Dholarath's north gate, reservoir and market street, in three eras.\n"
        "; Generated once by tools/greybox_northgate.py — this file is now the source of truth.\n"
        "[gd_scene load_steps=%d format=3]\n\n%s\n%s%s"
        % (load_steps, header_ext, header_sub, "\n".join(nodes))
    )
    OUT.write_text(text)
    boxes_total = sum(1 for n in nodes if "CSGBox3D" in n)
    print("wrote %s  (%d nodes, %d boxes, %d ext, %d sub)"
          % (OUT, len(nodes), boxes_total, len(ext), len(sub)))


if __name__ == "__main__":
    main()
