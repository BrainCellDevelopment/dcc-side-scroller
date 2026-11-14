#!/usr/bin/env python3
"""Level 2 generator (Floor 2, "same but nastier"). The level runs left to right.

Authored in world coordinates (u == world x, no mirroring). Seven sections follow the trimmed Floor 2 arc in
docs/floor-2-plan.md. Each section function only lays out the floor, checkpoint, props and placeholder enemies;
later milestones replace the placeholders with the Floor 2 roster and wire the set pieces:

  0 arrival     Brindle Grub corridors (M2)
  1 shelter     storm-shelter safe room, Mordecai the Bugaboo, Second Chance mailbox (M2)
  2 clurichaun  moonshine quadrant (M3)
  3 krakaren    Krakaren Clone boss lair (M3)
  4 grubstorm   janitor-grub swarm (M4)
  5 dogpound    kobold quadrant and Ralph's dog pound (M4)
  6 stairwell   reward room and the stairs down (M5)

Run: python3 art-src/level/build_level02.py (prints ERRORS: 0 when the reachability lint passes).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import levelkit
from levelkit import Writer, vec

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PROJECT = ROOT + "/dcc-side-scroller"
OUT = PROJECT + "/scenes/level02.tscn"
UID = "uid://c4lv2nastyfl2"
CONTRACT2 = ROOT + "/docs/contract-art.md"

FLOOR = 304
BOTTOM = 364
START_U = 96
CAM_PAD = 320

# Floor 2 art kit: platform styles 7 cinder, 8 concrete, 9 slab; background styles 7 floor2, 8 artery, 9 corridor.
CINDER, CONCRETE, SLAB = 7, 8, 9
# section idx -> (background style, platform style)
LOOK = {0: (9, CONCRETE), 1: (7, CONCRETE), 2: (9, CINDER), 3: (8, CINDER), 4: (9, SLAB), 5: (8, CINDER), 6: (7, CONCRETE)}

RES = {
    "player": "res://scenes/player/player.tscn",
    "goblin": "res://scenes/enemies/goblin.tscn",
    "hud": "res://scenes/ui/hud.tscn",
    "platform": "res://scenes/level/platform.tscn",
    "spikes": "res://scenes/level/spikes.tscn",
    "killzone": "res://scenes/level/kill_zone.tscn",
    "checkpoint": "res://scenes/level/checkpoint.tscn",
    "background": "res://scenes/level/background.tscn",
    "prop_torch": "res://scenes/props/torch_bracket.tscn",
    "prop_crate": "res://scenes/props/crate.tscn",
    "prop_pipe_h": "res://scenes/props/pipe_h.tscn",
    "prop_grate": "res://scenes/props/grate.tscn",
    "prop_sign_hazard": "res://scenes/props/sign_hazard.tscn",
    "prop_skull_sconce": "res://scenes/props/skull_sconce.tscn",
}
EXISTING = list(RES)

# idx, key (dev goto name), title shown on entry, gated (swing door at the entry edge), forward width
SECTIONS = [
    (0, "arrival", "BRINDLE GRUB CORRIDORS", False, 1600),
    (1, "shelter", "STORM SHELTER", True, 768),
    (2, "clurichaun", "CLURICHAUN QUADRANT", True, 1536),
    (3, "krakaren", "KRAKAREN LAIR", True, 896),
    (4, "grubstorm", "GRUB STORM", True, 1024),
    (5, "dogpound", "DOG POUND", True, 1024),
    (6, "stairwell", "THE STAIRWELL", True, 640),
]

kit = levelkit.Kit(PROJECT, CONTRACT2)
cur = kit.cur
flat, pit, block, cp, trig = kit.flat, kit.pit, kit.block, kit.cp, kit.trig
grunt, thrower = kit.grunt, kit.thrower

WIDTH = sum(s[4] for s in SECTIONS)


def furnish(x0, x1, crates=()):
    for x in range(x0 + 120, x1, 240):
        kit.add_prop("prop_torch", x, FLOOR - 110)
    for x in crates:
        kit.add_prop("prop_crate", x0 + x, FLOOR)


def section_arrival(x0):
    # Floor 2 begins: white floors, cinderblock, orange lichen. Grub corridors with shelves to hop. Placeholder
    # grunts stand in for Brindle Grubs and Danger Dingoes until the Floor 2 roster lands.
    flat(448)
    cp(0, x0 + 96, 0)
    flat(320)
    shelf = kit.add_plat(x0 + 512, FLOOR - 80, 96, 16, CONCRETE, kind="upper", one_way=True)
    grunt(shelf["x"] + 48, shelf["y"])
    pit(48)
    flat(352)
    block(x0 + 1120, 32, 32)
    grunt(x0 + 1300)
    flat(432)
    grunt(x0 + 1500)
    furnish(x0, x0 + 1600, crates=(200, 980))
    kit.add_prop("prop_pipe_h", x0 + 700, FLOOR - 132, free=True)
    kit.add_prop("prop_grate", x0 + 1040, FLOOR - 64, free=True)
    kit.trig("BgArrival", "bg", "9", x0, x0 + 1600, FLOOR - 300, FLOOR + 120)


def section_shelter(x0):
    # Storm-shelter safe room: a concrete bunker. M1 lays the floor and the checkpoint; M2 adds the cots, the
    # mailbox, Mordecai the Bugaboo and the safe zone.
    flat(768)
    cp(1, x0 + 96, 1)
    kit.add_prop("prop_torch", x0 + 40, FLOOR - 110)
    kit.add_prop("prop_torch", x0 + 728, FLOOR - 110)
    kit.trig("Shelter", "heal", "", x0 + 32, x0 + 736, FLOOR - 120, FLOOR + 20)


def section_clurichaun(x0):
    # Hillbilly Clurichauns with slingshots around the moonshine filling room (M3).
    flat(384)
    cp(2, x0 + 96, 2)
    thrower(x0 + 300)
    pit(48)
    flat(320)
    shelf = kit.add_plat(x0 + 512, FLOOR - 80, 96, 16, CINDER, kind="upper", one_way=True)
    thrower(shelf["x"] + 48, shelf["y"])
    flat(384)
    block(x0 + 896, 32, 32)
    grunt(x0 + 1000)
    flat(400)
    thrower(x0 + 1400)
    furnish(x0, x0 + 1536, crates=(240, 1160))
    kit.trig("BgClurichaun", "bg", "9", x0, x0 + 1536, FLOOR - 300, FLOOR + 120)


def section_krakaren(x0):
    # Boss lair: the Krakaren Clone bursts through the cinderblock (M3). A flat arena for now.
    flat(256)
    cp(3, x0 + 96, 3)
    flat(640)
    furnish(x0, x0 + 896)
    kit.trig("BgKrakaren", "bg", "8", x0, x0 + 896, FLOOR - 300, FLOOR + 120)


def section_grubstorm(x0):
    # Janitor grubs swarm after the boss fight (M4).
    flat(384)
    cp(4, x0 + 96, 4)
    grunt(x0 + 280)
    pit(48)
    flat(320)
    grunt(x0 + 620)
    flat(272)
    furnish(x0, x0 + 1024, crates=(500,))
    kit.trig("BgGrubStorm", "bg", "9", x0, x0 + 1024, FLOOR - 300, FLOOR + 120)


def section_dogpound(x0):
    # Kobold quadrant leading to the dog pound and Ralph's arena (M4).
    flat(384)
    cp(5, x0 + 96, 5)
    thrower(x0 + 300)
    flat(320)
    kit.add_plat(x0 + 416, FLOOR - 64, 96, 16, CINDER, kind="upper", one_way=True)
    flat(320)
    furnish(x0, x0 + 1024, crates=(600,))
    kit.add_prop("prop_skull_sconce", x0 + 200, FLOOR - 118, free=True)
    kit.trig("BgDogPound", "bg", "8", x0, x0 + 1024, FLOOR - 300, FLOOR + 120)


def section_stairwell(x0):
    # Reward room and the stairs down (M5). The "end" trigger hands off to the next floor.
    flat(640)
    cp(6, x0 + 96, 6)
    furnish(x0, x0 + 640)
    kit.add_prop("prop_sign_hazard", x0 + 520, FLOOR)
    trig("EndZone", "end", "", x0 + 576, x0 + 616, FLOOR - 120, FLOOR + 20)
    kit.trig("BgStairwell", "bg", "7", x0, x0 + 640, FLOOR - 300, FLOOR + 120)


BUILDERS = [section_arrival, section_shelter, section_clurichaun, section_krakaren, section_grubstorm, section_dogpound, section_stairwell]


def build():
    cur.update(x=0, y=FLOOR)
    kit.walls.append({"name": "LeftBound", "x": -8, "y": FLOOR - 250, "kind": "wall"})
    last = len(SECTIONS) - 1
    for (idx, key, title, gated, width), builder in zip(SECTIONS, BUILDERS):
        kit.start_section(idx, key, LOOK[idx][0], title, LOOK[idx][1], BOTTOM, gate=gated)
        x0 = cur["x"]
        builder(x0)
        assert cur["x"] == x0 + width, (key, cur["x"], x0 + width)
        kit.end_section()
        s = kit.sections[-1]
        s["l"] = 0 if idx == 0 else x0 - CAM_PAD
        s["r"] = cur["x"] if idx == last else cur["x"] + CAM_PAD
    kit.walls.append({"name": "RightBound", "x": WIDTH + 8, "y": FLOOR - 250, "kind": "wall"})


def write_tscn():
    w = Writer()
    w.ext_id("script")
    inst, raw = w.inst, w.raw
    w.node('[node name="Level02" type="Node2D"]\nscript = ExtResource("1_level")')
    inst("Background", ".", "background", initial_style=str(LOOK[0][0]))
    raw("Deco", "Node2D", ".", ["z_index = -2"])
    raw("Platforms", "Node2D", ".", [])
    raw("Hazards", "Node2D", ".", [])
    raw("Checkpoints", "Node2D", ".", [])
    raw("Triggers", "Node2D", ".", [])
    raw("Walls", "Node2D", ".", [])
    raw("Doors", "Node2D", ".", [])
    raw("Goblins", "Node2D", ".", [])
    kit.emit_props(w)
    kit.emit_geometry(w)
    kit.emit_enemies(w)
    inst("Player", ".", "player", position=vec(START_U, FLOOR - 2))
    raw("Camera2D", "Camera2D", ".", [
        "position = %s" % vec(START_U, 184), "limit_left = 0", "limit_top = -116", "limit_right = %d" % WIDTH,
        "limit_bottom = %d" % BOTTOM, "limit_smoothed = true", "position_smoothing_enabled = true",
        "position_smoothing_speed = 6.0"])
    inst("HUD", ".", "hud")
    kit.emit_section_triggers(w, lambda s: {"key": s["name"], "gate": 1 if s["gate"] else 0,
                                            "edge": s["x0"], "floor_y": FLOOR})
    text = w.render(RES, "res://scripts/levels/level02.gd", UID)
    with open(OUT, "w") as f:
        f.write(text)
    return text


def main():
    build()
    text = write_tscn()
    errs, notes = kit.lint(text, RES, EXISTING)
    names = [s["name"] for s in kit.sections]
    if len(set(names)) != len(names):
        errs.append("duplicate section names")
    for s in kit.sections:
        if not any(c["index"] == s["idx"] for c in kit.cps):
            errs.append("section %s has no checkpoint with its index" % s["name"])
    for s in kit.sections:
        print("section %d %-10s x %5d..%5d  limits l=%d r=%d  gate=%s  %r" %
              (s["idx"], s["name"], s["x0"], s["x1"], s["l"], s["r"], s["gate"], s["title"]))
    for n in notes:
        print("note:", n)
    print("wrote", OUT)
    print("ERRORS: %d" % len(errs))
    for e in errs:
        print("  -", e)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
