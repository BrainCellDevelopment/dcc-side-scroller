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
    "grub": "res://scenes/enemies/grub.tscn",
    "dingo": "res://scenes/enemies/dingo.tscn",
    "storm_shelter": "res://scenes/level/storm_shelter.tscn",
    "krakaren_lair": "res://scenes/level/krakaren_lair.tscn",
    "kobold_rider": "res://scenes/enemies/kobold_rider.tscn",
    "grub_storm": "res://scenes/level/grub_storm.tscn",
    "dogpound_lair": "res://scenes/level/dogpound_lair.tscn",
    "smoothie_bench": "res://scenes/props/smoothie_bench.tscn",
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


def grub(x, y=None):
    kit.add_enemy("grub", x, cur["y"] if y is None else y)


def clurichaun(x, y=None):
    kit.add_enemy("clurichaun", x, cur["y"] if y is None else y)


def kobold(x, y=None):
    kit.add_enemy("kobold_rider", x, cur["y"] if y is None else y)


def dingo(x, y=None):
    kit.add_enemy("dingo", x, cur["y"] if y is None else y)


def emit_critters(w):
    counts = {"grub": 0, "dingo": 0, "clurichaun": 0, "kobold_rider": 0}
    for e in kit.enemies:
        if e["kind"] in counts:
            counts[e["kind"]] += 1
            name = "%s%02d" % (e["kind"].capitalize(), counts[e["kind"]])
            if e["kind"] == "clurichaun":
                w.inst(name, "Goblins", "goblin", position=vec(e["x"], e["y"] - 2), variant="4")
            else:
                w.inst(name, "Goblins", e["kind"], position=vec(e["x"], e["y"] - 2))


def furnish(x0, x1, crates=()):
    for x in range(x0 + 120, x1, 240):
        kit.add_prop("prop_torch", x, FLOOR - 110)
    for x in crates:
        kit.add_prop("prop_crate", x0 + x, FLOOR)


def section_arrival(x0):
    # Floor 2 begins: white floors, cinderblock, orange lichen. Brindle Grub corridors (slow, harmless, in
    # clusters) with a Danger Dingo patrolling the long run, shelves to hop between.
    flat(448)
    cp(0, x0 + 96, 0)
    grub(x0 + 340)
    grub(x0 + 392)
    flat(320)
    shelf = kit.add_plat(x0 + 512, FLOOR - 80, 96, 16, CONCRETE, kind="upper", one_way=True)
    grub(shelf["x"] + 48, shelf["y"])
    grub(x0 + 600)
    pit(48)
    flat(352)
    block(x0 + 1120, 32, 32)
    dingo(x0 + 1000)
    grub(x0 + 1210)
    flat(432)
    dingo(x0 + 1500)
    furnish(x0, x0 + 1600, crates=(200, 980))
    kit.add_prop("prop_pipe_h", x0 + 700, FLOOR - 132, free=True)
    kit.add_prop("prop_grate", x0 + 1040, FLOOR - 64, free=True)
    kit.trig("BgArrival", "bg", "9", x0, x0 + 1600, FLOOR - 300, FLOOR + 120)


SHELTER = {}


def section_shelter(x0):
    # Storm-shelter safe room (storm_shelter.gd): the room instance owns the cots, TVs, mailbox, safe zone and
    # Mordecai the Bugaboo; this section lays the floor, the checkpoint and the heal trigger.
    flat(768)
    SHELTER["center"] = x0 + 384
    cp(1, x0 + 96, 1)
    kit.trig("Shelter", "heal", "", x0 + 32, x0 + 736, FLOOR - 120, FLOOR + 20)


def emit_shelter(w):
    w.inst("StormShelter", ".", "storm_shelter", position=vec(SHELTER["center"], FLOOR))


BENCH = {}
LAIR = {}


def section_clurichaun(x0):
    # Hillbilly Clurichauns with slingshots (their pebbles inflict the Taint) leading to the filling room, where
    # the bicycle blender makes the immunity smoothie the Krakaren fight needs.
    flat(384)
    cp(2, x0 + 96, 2)
    clurichaun(x0 + 300)
    pit(48)
    flat(320)
    shelf = kit.add_plat(x0 + 512, FLOOR - 80, 96, 16, CINDER, kind="upper", one_way=True)
    clurichaun(shelf["x"] + 48, shelf["y"])
    flat(384)
    block(x0 + 896, 32, 32)
    clurichaun(x0 + 1000)
    flat(400)
    clurichaun(x0 + 1240)
    BENCH["x"] = x0 + 1344
    furnish(x0, x0 + 1536, crates=(240, 1160))
    kit.trig("BgClurichaun", "bg", "9", x0, x0 + 1536, FLOOR - 300, FLOOR + 120)


def emit_bench(w):
    w.inst("SmoothieBench", ".", "smoothie_bench", position=vec(BENCH["x"], FLOOR))


def section_krakaren(x0):
    # Boss lair: the Krakaren Clone (krakaren_lair.gd builds the boss, lock and trigger). A 256 px lead-in with
    # the checkpoint, then a 640 px arena.
    flat(256)
    cp(3, x0 + 96, 3)
    flat(640)
    LAIR["center"] = x0 + 256 + 320
    kit.add_prop("prop_torch", x0 + 40, FLOOR - 110)
    kit.trig("BgKrakaren", "bg", "8", x0, x0 + 896, FLOOR - 300, FLOOR + 120)


def emit_lair(w):
    w.inst("KrakarenLair", ".", "krakaren_lair", position=vec(LAIR["center"], FLOOR))


STORM = {}
POUND = {}


def section_grubstorm(x0):
    # Janitor grubs swarm after the boss fight (grub_storm.gd spawns waves while the player crosses the zone;
    # pupae mounds ring the walls). A couple of kobold riders patrol the far end.
    flat(384)
    cp(4, x0 + 96, 4)
    pit(48)
    flat(320)
    flat(272)
    STORM["x"] = x0
    furnish(x0, x0 + 1024, crates=(500,))
    kit.trig("BgGrubStorm", "bg", "9", x0, x0 + 1024, FLOOR - 300, FLOOR + 120)


def emit_storm(w):
    w.inst("GrubStorm", ".", "grub_storm", position=vec(STORM["x"], FLOOR), zone_length="1024.0")


def section_dogpound(x0):
    # Kobold quadrant leading to the dog pound: kobold riders on dingoes, then Ralph's arena
    # (dogpound_lair.gd builds the boss, lock and trigger).
    flat(384)
    cp(5, x0 + 96, 5)
    kobold(x0 + 260)
    kit.add_plat(x0 + 192, FLOOR - 64, 96, 16, CINDER, kind="upper", one_way=True)
    flat(640)
    POUND["center"] = x0 + 384 + 320
    kobold(x0 + 420)
    kit.add_prop("prop_skull_sconce", x0 + 200, FLOOR - 118, free=True)
    kit.trig("BgDogPound", "bg", "8", x0, x0 + 1024, FLOOR - 300, FLOOR + 120)


def emit_pound(w):
    w.inst("DogPoundLair", ".", "dogpound_lair", position=vec(POUND["center"], FLOOR))


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
    emit_critters(w)
    emit_shelter(w)
    emit_bench(w)
    emit_lair(w)
    emit_storm(w)
    emit_pound(w)
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
