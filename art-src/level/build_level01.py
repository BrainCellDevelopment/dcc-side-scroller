#!/usr/bin/env python3
"""Level 1 generator. The level runs right to left.

Everything is authored in forward coordinates (u grows with the direction of play, the
door from the guildhall is at u=40) and levelkit mirrors it into world space on write:
world x = WIDTH - u. Lint runs on the forward data.

Add a section: append to the SECTIONS table and fill it in build(). Other Level 1
issues should put their content in their own section function to avoid merge conflicts.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import levelkit
from levelkit import Writer, vec, STONE

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PROJECT = ROOT + "/dcc-side-scroller"
OUT = PROJECT + "/scenes/level01.tscn"
CONTRACT2 = ROOT + "/docs/contract-art.md"
UID = "uid://dl1fndtn48xq"

FLOOR = 304
BOTTOM = 364
DOOR_U = 40
START_U = 96
BG_STYLE = 2
CAM_PAD = 320

RES = {
    "player": "res://scenes/player/player.tscn",
    "goblin": "res://scenes/enemies/goblin.tscn",
    "hud": "res://scenes/ui/hud.tscn",
    "platform": "res://scenes/level/platform.tscn",
    "spikes": "res://scenes/level/spikes.tscn",
    "killzone": "res://scenes/level/kill_zone.tscn",
    "checkpoint": "res://scenes/level/checkpoint.tscn",
    "background": "res://scenes/level/background.tscn",
    "prop_torch": "res://scenes/props/torch.tscn",
    "prop_crate": "res://scenes/props/crate.tscn",
    "door": "res://scenes/props/door.tscn",
}
EXISTING = ["player", "goblin", "hud"]

# idx, key (dev goto name), title shown on entry, gated (swing door at the entry edge), forward width
SECTIONS = [
    (0, "tunnel", "ARTERIAL TUNNEL", False, 1152),
    (1, "rats", "THE RATS' CORRIDOR", True, 960),
    (2, "saferoom", "SAFE ROOM", True, 768),
    (3, "hoarder", "THE HOARDER", True, 896),
    (4, "workshop", "GOBLIN WORKSHOP", False, 768),
    (5, "swine", "BALL OF SWINE", True, 1024),
    (6, "collapse", "THE COLLAPSE", True, 640),
]

kit = levelkit.Kit(PROJECT, CONTRACT2)
cur = kit.cur
flat, pit, block, cp, trig = kit.flat, kit.pit, kit.block, kit.cp, kit.trig
grunt, thrower = kit.grunt, kit.thrower

WIDTH = sum(s[4] for s in SECTIONS)
kit.mirror_w = WIDTH


def furnish(x0, x1, crates=()):
    for x in range(x0 + 120, x1, 240):
        kit.add_prop("prop_torch", x, FLOOR - 110)
    for x in crates:
        kit.add_prop("prop_crate", x0 + x, FLOOR)


def section_tunnel(x0):
    # Arterial tunnel and llama alley (#57). Stub: intro rock thrower on a shelf, a spike strip, a pit.
    flat(448)
    shelf = kit.add_plat(x0 + 288, FLOOR - 80, 64, 16, STONE, kind="upper")
    thrower(shelf["x"] + 32, shelf["y"])
    kit.enemies[-1]["name"] = "IntroThrower"
    grunt(x0 + 380)
    cp(0, x0 + 232, 0)
    flat(224, spk=[(96, 32)])
    pit(48)
    flat(432)
    grunt(x0 + 880)
    grunt(x0 + 1000)
    furnish(x0, x0 + 1152, crates=(160, 620))


def section_rats(x0):
    # Rats and Scatterers corridor (#58, #56). Stub: goblins stand in.
    flat(960)
    cp(1, x0 + 96, 1)
    grunt(x0 + 360)
    grunt(x0 + 560)
    grunt(x0 + 720)
    furnish(x0, x0 + 960, crates=(240,))


def section_saferoom(x0):
    # Fast-food safe room (#59). The only room whose checkpoint matters for the boss run.
    flat(768)
    cp(2, x0 + 96, 2)
    furnish(x0, x0 + 768)


def section_hoarder(x0):
    # Mid-boss: the Hoarder (#60, #51).
    flat(896)
    cp(3, x0 + 96, 3)
    furnish(x0, x0 + 896)


def section_workshop(x0):
    # Optional goblin workshop (#61, #55).
    flat(768)
    cp(4, x0 + 96, 4)
    thrower(x0 + 520)
    furnish(x0, x0 + 768, crates=(200,))


def section_swine(x0):
    # Final boss: Ball of Swine (#67, #51).
    flat(1024)
    cp(5, x0 + 96, 5)
    furnish(x0, x0 + 1024)


def section_collapse(x0):
    # Collapse beat and hand-off to Level 2 (#68). The end zone is the stub exit.
    flat(640)
    cp(6, x0 + 96, 6)
    furnish(x0, x0 + 640)
    trig("EndZone", "end", "", x0 + 640 - 100, x0 + 640 - 60, FLOOR - 120, FLOOR + 20)


BUILDERS = [section_tunnel, section_rats, section_saferoom, section_hoarder, section_workshop, section_swine, section_collapse]


def build():
    cur.update(x=0, y=FLOOR)
    kit.walls.append({"name": "RightBound", "x": -8, "y": FLOOR - 250, "kind": "wall"})
    last = len(SECTIONS) - 1
    for (idx, key, title, gated, width), builder in zip(SECTIONS, BUILDERS):
        kit.start_section(idx, key, BG_STYLE, title, STONE, BOTTOM, gate=gated)
        x0 = cur["x"]
        builder(x0)
        assert cur["x"] == x0 + width, (key, cur["x"], x0 + width)
        kit.end_section()
        s = kit.sections[-1]
        s["l"] = 0 if idx == 0 else x0 - CAM_PAD
        s["r"] = cur["x"] if idx == last else cur["x"] + CAM_PAD
    kit.walls.append({"name": "LeftBound", "x": WIDTH + 8, "y": FLOOR - 250, "kind": "wall"})


def write_tscn():
    w = Writer()
    w.ext_id("script")
    inst, raw = w.inst, w.raw
    w.node('[node name="Level01" type="Node2D"]\nscript = ExtResource("1_level")')
    inst("Background", ".", "background", initial_style=str(BG_STYLE))
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
    inst("EntryDoor", "Doors", "door", position=vec(kit.mx(DOOR_U), FLOOR), start_open="true",
         close_behind="true", close_side="-1.0", sealed_text='"Locked. No way back."')
    inst("Player", ".", "player", position=vec(kit.mx(START_U), FLOOR - 2))
    raw("Camera2D", "Camera2D", ".", [
        "position = %s" % vec(kit.mx(START_U), 184), "limit_left = 0", "limit_top = -116", "limit_right = %d" % WIDTH,
        "limit_bottom = %d" % BOTTOM, "limit_smoothed = true", "position_smoothing_enabled = true",
        "position_smoothing_speed = 6.0"])
    inst("HUD", ".", "hud")
    kit.emit_section_triggers(w, lambda s: {"key": s["name"], "gate": 1 if s["gate"] else 0,
                                            "edge": kit.mx(s["x0"]), "floor_y": FLOOR})
    text = w.render(RES, "res://scripts/levels/level01.gd", UID)
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
        print("section %d %-9s u %5d..%5d  world x %5d..%5d  limits l=%d r=%d  gate=%s  %r" %
              (s["idx"], s["name"], s["x0"], s["x1"], kit.mx(s["x1"]), kit.mx(s["x0"]),
               kit.mx(s["r"]), kit.mx(s["l"]), s["gate"], s["title"]))
    for n in notes:
        print("note:", n)
    print("wrote", OUT)
    print("ERRORS: %d" % len(errs))
    for e in errs:
        print("  -", e)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
