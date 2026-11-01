#!/usr/bin/env python3
"""Generates game/scenes/player/Eva.tscn — Eva as a blocked-out figure.

    python3 tools/eva_greybox.py

Still greybox: boxes, no sculpt, no rig, no skin weights. But it has a front
and a back, a head you can frame, and limbs that move, which a capsule does
not — and you cannot stage a close-up on a capsule.

The real Eva is a commission (REQUIREMENTS R5.1). When that model arrives it
replaces the Model subtree and nothing else changes: the body, the collision
capsule, the camera and every script stay exactly as they are.

Proportions for a 1.75 m woman, feet at y = 0:
    ankle 0.06   knee 0.46   hip 0.92   shoulder 1.42   head centre 1.60
"""
import math
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game/scenes/player/Eva.tscn"

SKIN, CLOTH, DARK, HAIR, EYE = "ext_skin", "ext_cloth", "ext_dark", "ext_hair", "ext_eye"
TROUSER, TEAL, BOOT = "ext_trouser", "ext_teal", "ext_boot"
COPPER, PATINA, PEARL = "ext_copper", "ext_patina", "ext_pearl"
MATS = {
    SKIN: "res://materials/mat_eva.tres",
    CLOTH: "res://materials/mat_eva_cloth.tres",
    DARK: "res://materials/mat_eva_dark.tres",
    HAIR: "res://materials/mat_eva_hair.tres",
    EYE: "res://materials/mat_eva_eye.tres",
    TROUSER: "res://materials/mat_eva_trouser.tres",
    TEAL: "res://materials/mat_eva_teal.tres",
    BOOT: "res://materials/mat_eva_boot.tres",
    COPPER: "res://materials/mat_eva_copper.tres",
    PATINA: "res://materials/mat_eva_patina.tres",
    PEARL: "res://materials/mat_eva_pearl.tres",
}

lines = []


def fmt(v):
    return "%g" % v


def node(name, ntype, parent, pos=(0, 0, 0), extra=""):
    lines.append(
        '[node name="%s" type="%s" parent="%s"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\n%s'
        % (name, ntype, parent, ", ".join(fmt(c) for c in pos), extra)
    )


def part(name, parent, pos, size, mat, roll=0.0):
    """One box of the body: the shared unit cube, scaled, optionally rolled
    about Z so a strap can lie diagonally across the chest."""
    r = math.radians(roll)
    c, sn = math.cos(r), math.sin(r)
    sx, sy, sz = size
    basis = [sx * c, sx * sn, 0.0, -sy * sn, sy * c, 0.0, 0.0, 0.0, sz]
    lines.append(
        '[node name="%s" type="MeshInstance3D" parent="%s"]\n'
        'transform = Transform3D(%s, %s)\n'
        'mesh = SubResource("BoxMesh_unit")\n'
        'material_override = ExtResource("%s")\n'
        % (name, parent, ", ".join(fmt(v) for v in basis),
           ", ".join(fmt(v) for v in pos), mat)
    )


def limb(side, sign):
    """Arm and leg for one side. Joints are empty nodes so the rig script can
    rotate them; the meshes hang below each joint."""
    # arm: shoulder -> elbow -> wrist
    node("Shoulder" + side, "Node3D", "Model/Hips/Spine", (sign * 0.21, 0.34, 0))
    part("UpperArm" + side, "Model/Hips/Spine/Shoulder" + side,
         (0, -0.13, 0), (0.095, 0.28, 0.105), CLOTH)
    # Sleeves rolled to the elbow over a teal undershirt — the cuff is the
    # only teal on the arm and it is on every reference sheet.
    part("Cuff" + side, "Model/Hips/Spine/Shoulder" + side,
         (0, -0.265, 0), (0.10, 0.045, 0.11), TEAL)
    node("Elbow" + side, "Node3D", "Model/Hips/Spine/Shoulder" + side, (0, -0.28, 0))
    part("Forearm" + side, "Model/Hips/Spine/Shoulder%s/Elbow%s" % (side, side),
         (0, -0.13, 0), (0.085, 0.26, 0.095), SKIN)
    part("Hand" + side, "Model/Hips/Spine/Shoulder%s/Elbow%s" % (side, side),
         (0, -0.30, 0), (0.08, 0.10, 0.06), SKIN)
    # Black watch on one wrist, leather cuff on the other.
    part("Wrist" + side, "Model/Hips/Spine/Shoulder%s/Elbow%s" % (side, side),
         (0, -0.235, 0), (0.095, 0.05, 0.075), EYE if side == "R" else DARK)
    # leg: hip -> knee -> ankle
    node("Hip" + side, "Node3D", "Model/Hips", (sign * 0.095, 0, 0))
    part("Thigh" + side, "Model/Hips/Hip" + side, (0, -0.23, 0), (0.145, 0.46, 0.155), TROUSER)
    node("Knee" + side, "Node3D", "Model/Hips/Hip" + side, (0, -0.46, 0))
    part("Shin" + side, "Model/Hips/Hip%s/Knee%s" % (side, side),
         (0, -0.21, 0), (0.12, 0.42, 0.13), TROUSER)
    # Trousers rolled at the ankle, then boots.
    part("Turnup" + side, "Model/Hips/Hip%s/Knee%s" % (side, side),
         (0, -0.40, 0), (0.135, 0.07, 0.145), CLOTH)
    part("Boot" + side, "Model/Hips/Hip%s/Knee%s" % (side, side),
         (0, -0.44, -0.03), (0.135, 0.14, 0.25), BOOT)


def main():
    ext = "".join('[ext_resource type="%s" path="%s" id="%s"]\n'
                  % ("Script" if p.endswith(".gd") else "Material", p, i)
                  for i, p in [
                      ("ext_body", "res://scripts/player/eva.gd"),
                      ("ext_cam", "res://scripts/player/camera_rig.gd"),
                      ("ext_rig", "res://scripts/player/eva_rig.gd"),
                  ] + list(MATS.items()))

    sub = (
        '[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_body"]\n'
        'radius = 0.35\nheight = 1.8\n\n'
        '[sub_resource type="BoxMesh" id="BoxMesh_unit"]\n'
        'size = Vector3(1, 1, 1)\n\n'
    )

    lines.append(
        '[node name="Eva" type="CharacterBody3D"]\n'
        'collision_layer = 16\ncollision_mask = 5\n'
        'script = ExtResource("ext_body")\n'
    )
    lines.append(
        '[node name="Shape" type="CollisionShape3D" parent="."]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)\n'
        'shape = SubResource("CapsuleShape3D_body")\n'
    )

    # Model faces +Z (south) by default, matching the old capsule.
    lines.append(
        '[node name="Model" type="Node3D" parent="."]\n'
        'transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0)\n'
        'script = ExtResource("ext_rig")\n'
    )

    node("Hips", "Node3D", "Model", (0, 0.92, 0))
    part("Pelvis", "Model/Hips", (0, -0.04, 0), (0.30, 0.20, 0.20), TROUSER)
    part("Belt", "Model/Hips", (0, 0.055, 0), (0.315, 0.065, 0.215), DARK)
    part("BeltPouch", "Model/Hips", (-0.145, -0.03, -0.045), (0.075, 0.12, 0.09), DARK)
    part("ThighRig", "Model/Hips", (0.125, -0.13, -0.035), (0.07, 0.11, 0.085), DARK)

    # Her father's hand trowel, stowed on the belt. ~22 cm: a pointing trowel
    # you scrape soil with, NOT the long shovel the reference sheets draw —
    # the brief supersedes the sheets on this one point (decision #31).
    part("TrowelHandle", "Model/Hips", (-0.175, -0.015, 0.055), (0.03, 0.09, 0.03), PATINA)
    part("TrowelFerrule", "Model/Hips", (-0.175, -0.065, 0.055), (0.026, 0.02, 0.026), COPPER)
    part("TrowelBlade", "Model/Hips", (-0.175, -0.125, 0.055), (0.055, 0.105, 0.012), COPPER)
    node("Spine", "Node3D", "Model/Hips", (0, 0.06, 0))
    part("Chest", "Model/Hips/Spine", (0, 0.20, 0), (0.355, 0.42, 0.21), CLOTH)
    # Teal collared undershirt, showing at the open neck.
    part("Undershirt", "Model/Hips/Spine", (0, 0.335, -0.09), (0.16, 0.14, 0.05), TEAL)
    part("Hood", "Model/Hips/Spine", (0, 0.37, 0.085), (0.26, 0.15, 0.10), CLOTH)
    part("Pearls", "Model/Hips/Spine", (0, 0.375, -0.10), (0.135, 0.028, 0.045), PEARL)
    # Cross-body harness: right shoulder down to left hip.
    part("Harness", "Model/Hips/Spine", (0, 0.19, -0.11), (0.075, 0.52, 0.03), DARK, roll=22.0)
    part("HarnessBack", "Model/Hips/Spine", (0, 0.19, 0.11), (0.075, 0.52, 0.03), DARK, roll=-22.0)
    part("SleeveBadge", "Model/Hips/Spine", (0.195, 0.27, -0.06), (0.03, 0.055, 0.055), COPPER)

    part("Backpack", "Model/Hips/Spine", (0, 0.19, 0.175), (0.255, 0.33, 0.135), DARK)
    part("PackFlap", "Model/Hips/Spine", (0, 0.31, 0.19), (0.255, 0.11, 0.115), BOOT)



    node("Head", "Node3D", "Model/Hips/Spine", (0, 0.46, 0))
    part("Skull", "Model/Hips/Spine/Head", (0, 0.11, 0), (0.185, 0.235, 0.21), SKIN)
    part("Hair", "Model/Hips/Spine/Head", (0, 0.155, 0.028), (0.195, 0.175, 0.135), HAIR)
    part("Bun", "Model/Hips/Spine/Head", (0, 0.145, 0.108), (0.10, 0.10, 0.075), HAIR)
    # A front. This is the whole reason the capsule had to go.
    part("Brow", "Model/Hips/Spine/Head", (0, 0.165, -0.10), (0.175, 0.025, 0.02), HAIR)
    part("EyeL", "Model/Hips/Spine/Head", (-0.045, 0.125, -0.099), (0.035, 0.022, 0.015), EYE)
    part("EyeR", "Model/Hips/Spine/Head", (0.045, 0.125, -0.099), (0.035, 0.022, 0.015), EYE)
    part("Nose", "Model/Hips/Spine/Head", (0, 0.095, -0.112), (0.032, 0.055, 0.035), SKIN)
    part("Jaw", "Model/Hips/Spine/Head", (0, 0.015, -0.015), (0.155, 0.075, 0.185), SKIN)

    for side, sign in (("L", -1), ("R", 1)):
        limb(side, sign)

    lines.append(
        '[node name="WallCast" type="RayCast3D" parent="Model"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)\n'
        'target_position = Vector3(0, 0, -0.72)\ncollision_mask = 5\n'
    )
    lines.append(
        '[node name="LedgeCast" type="RayCast3D" parent="Model"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.05, -0.62)\n'
        'target_position = Vector3(0, -2, 0)\ncollision_mask = 5\n'
    )
    lines.append(
        '[node name="StepWallCast" type="RayCast3D" parent="Model"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)\n'
        'target_position = Vector3(0, 0, -0.55)\ncollision_mask = 5\n'
    )
    lines.append(
        '[node name="StepCast" type="RayCast3D" parent="Model"]\n'
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, -0.5)\n'
        'target_position = Vector3(0, -0.98, 0)\ncollision_mask = 5\n'
    )
    lines.append(
        '[node name="CameraPivot" type="Node3D" parent="."]\n'
        'transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0)\n'
        'script = ExtResource("ext_cam")\n'
    )
    lines.append(
        '[node name="SpringArm3D" type="SpringArm3D" parent="CameraPivot"]\n'
        'transform = Transform3D(1, 0, 0, 0, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0)\n'
        'spring_length = 4.6\nmargin = 0.25\ncollision_mask = 5\n'
    )
    lines.append(
        '[node name="Camera3D" type="Camera3D" parent="CameraPivot/SpringArm3D"]\n'
        'fov = 72.0\nfar = 600.0\n'
    )

    steps = len(MATS) + 3 + 2 + 1
    OUT.write_text(
        "; Eva — blocked out in boxes. Generated by tools/eva_greybox.py.\n"
        "; The real model is a commission (R5.1); it replaces the Model subtree\n"
        "; and nothing else about this scene changes.\n"
        "[gd_scene load_steps=%d format=3]\n\n%s\n%s%s"
        % (steps, ext, sub, "\n".join(lines))
    )
    print("wrote %s (%d nodes)" % (OUT, len(lines)))


if __name__ == "__main__":
    main()
