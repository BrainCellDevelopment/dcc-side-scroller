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
from levelkit import Writer, vec, STONE, fnum
import section_rats

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PROJECT = ROOT + "/dcc-side-scroller"
OUT = PROJECT + "/scenes/level01.tscn"
CONTRACT2 = ROOT + "/docs/contract-art.md"
UID = "uid://dl1fndtn48xq"

FLOOR = 304
BOTTOM = 364
DOOR_U = 40
START_U = 96
CAM_PAD = 320

# Floor 1 art kit (#49): background styles 4 tunnel, 5 artery, 6 corridor; platform styles 4 brick, 5 wet stone, 6 plank.
BRICK, WETSTONE, PLANK = 4, 5, 6
# section idx -> (background style, platform style)
LOOK = {0: (5, BRICK), 1: (6, WETSTONE), 2: (4, PLANK), 3: (6, BRICK), 4: (4, PLANK), 5: (5, BRICK), 6: (4, WETSTONE)}
BG_STYLE = LOOK[0][0]

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
    "door": "res://scenes/props/door.tscn",
}
RES.update({
    "llama": "res://scenes/enemies/llama.tscn",
    "lava_puddle": "res://scenes/level/lava_puddle.tscn",
    "prop_spray_arrow": "res://scenes/props/spray_arrow.tscn",
    "prop_sign_arrow_brick": "res://scenes/props/sign_arrow_brick.tscn",
    "prop_skull_sconce": "res://scenes/props/skull_sconce.tscn",
    "prop_lichen_floor": "res://scenes/props/lichen_floor.tscn",
    "prop_lichen_wall": "res://scenes/props/lichen_wall.tscn",
    "prop_sign_hazard": "res://scenes/props/sign_hazard.tscn",
    "prop_spray_x": "res://scenes/props/spray_x.tscn",
    "prop_grate": "res://scenes/props/grate.tscn",
    "prop_pipe_h": "res://scenes/props/pipe_h.tscn",
    "fastfood_room": "res://scenes/level/fastfood_room.tscn",
    "swine_arena": "res://scenes/level/swine_arena.tscn",
})
RES.update(section_rats.RES)
EXISTING = ["player", "goblin", "hud"] + list(section_rats.RES)

# idx, key (dev goto name), title shown on entry, gated (swing door at the entry edge), forward width
SECTIONS = [
    (0, "tunnel", "ARTERIAL TUNNEL", False, 1888),
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


PUDDLES = []


def llama(x, dormant=False, name=None):
    kit.add_enemy("llama", x, cur["y"], dormant=dormant, name=name)


def puddle(x, w=32):
    PUDDLES.append((x, w))


def section_tunnel(x0):
    # Arterial tunnel and llama alleys (#57): guild exit and torch-lit artery with the painted arrows, the
    # intro thrower and the missile practice, then the alleys. Checkpoint 0 sits at the mouth of the alleys.
    flat(448)
    shelf = kit.add_plat(x0 + 288, FLOOR - 80, 64, 16, BRICK, kind="upper")
    thrower(shelf["x"] + 32, shelf["y"])
    kit.enemies[-1]["name"] = "IntroThrower"
    flat(224, spk=[(96, 32)])
    pit(48)
    flat(176)
    cp(0, x0 + 784, 0)
    kit.trig("BgArtery", "bg", "5", x0, x0 + 720, FLOOR - 300, FLOOR + 120)
    kit.trig("BgAlley", "bg", "4", x0 + 720, x0 + 1888, FLOOR - 300, FLOOR + 120)
    # alley 1: a sleeping llama that Donut's missile wakes
    flat(320)
    kit.hint("HintSleepingLlama", x0 + 900, x0 + 1060, "A sleeping llama. Press K and let Donut say hello")
    puddle(x0 + 992)
    llama(x0 + 1130, dormant=True, name="SleepingLlama")
    # alley 2: an awake llama behind a cover block
    flat(352)
    kit.block(x0 + 1296, 32, 32)
    puddle(x0 + 1352)
    llama(x0 + 1480)
    # alley 3: a grunt among the spit puddles
    flat(320, spk=[(48, 32)])
    puddle(x0 + 1672)
    grunt(x0 + 1780)
    furnish(x0, x0 + 1888, crates=(160, 620))
    decorate_llama_alley(x0)


def decorate_llama_alley(x0):
    for u in (140, 520, 700):
        kit.add_prop("prop_spray_arrow", x0 + u, FLOOR - 58, free=True)
    kit.add_prop("prop_sign_arrow_brick", x0 + 440, FLOOR)
    kit.add_prop("prop_skull_sconce", x0 + 340, FLOOR - 118, free=True)
    kit.add_prop("prop_skull_sconce", x0 + 620, FLOOR - 118, free=True)
    kit.add_prop("prop_sign_hazard", x0 + 830, FLOOR)
    kit.add_prop("prop_spray_x", x0 + 1250, FLOOR - 56, free=True)
    kit.add_prop("prop_grate", x0 + 1010, FLOOR - 64, free=True)
    kit.add_prop("prop_pipe_h", x0 + 1530, FLOOR - 132, free=True)
    for u in (880, 1180, 1420, 1700):
        kit.add_prop("prop_lichen_floor", x0 + u, FLOOR, free=True)
    kit.add_prop("prop_lichen_wall", x0 + 1090, FLOOR, free=True)


def emit_llama_alley(w):
    gi = 0
    for e in kit.enemies:
        if e["kind"] != "llama":
            continue
        gi += 1
        extra = {"dormant": "true"} if e.get("dormant") else {}
        w.inst(e.get("name") or "Llama%d" % gi, "Goblins", "llama", position=vec(kit.mx(e["x"]), e["y"] - 2), **extra)
    for i, (x, pw) in enumerate(PUDDLES):
        w.inst("Puddle%d" % i, "Hazards", "lava_puddle", position=vec(kit.mspan(x, pw), FLOOR), width=fnum(pw) + ".0")


def section_rats_corridor(x0):
    # Rats and Scatterers corridor (#58, #56): layout, enemies and doors live in section_rats.py.
    section_rats.build(kit, x0, FLOOR, furnish)


SAFEROOM = {}


def section_saferoom(x0):
    # Fast-food safe room (#59): the SafeRoom kit dressed as a Polish fast-food restaurant with a playground, Tally
    # and two loot boxes. The room instance (scenes/level/fastfood_room.tscn) owns its doors, zone, checkpoint and
    # props; this section only lays the floor and puts the room in the middle. The level checkpoint sits under the
    # room's own one (hidden) so goto and respawn land in the room.
    flat(768)
    SAFEROOM["center"] = x0 + 384
    cp(2, x0 + 384 - 48, 2)
    kit.add_prop("prop_torch", x0 + 40, FLOOR - 110)
    kit.add_prop("prop_torch", x0 + 728, FLOOR - 110)


def emit_saferoom(w):
    w.inst("FastFoodRoom", ".", "fastfood_room", position=vec(kit.mx(SAFEROOM["center"]), FLOOR))


def saferoom_fixup(text):
    # the room draws its own checkpoint; the level one stays as the respawn and goto anchor but is hidden
    return text.replace('[node name="CP2" parent="Checkpoints" instance=ExtResource("%s")]\n' % CP_ID(text),
                        '[node name="CP2" parent="Checkpoints" instance=ExtResource("%s")]\nvisible = false\n' % CP_ID(text), 1)


def CP_ID(text):
    import re
    return re.search(r'\[ext_resource [^\]]*checkpoint.tscn" id="([^"]+)"', text).group(1)


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


SWINE = {}
SWINE_LEAD = 160
SWINE_ARENA_W = 704


def section_swine(x0):
    # Final boss: Ball of Swine (#67, #51). A 160 px lead-in with the checkpoint, the 704 px arena
    # with two extra one-way lanes (48 px apart), then 160 px of stair corridor behind a forcefield.
    # swine_arena.gd builds the boss, fortress, hazards and locks at runtime around SWINE["center"].
    flat(1024)
    cp(5, x0 + 96, 5)
    ax0 = x0 + SWINE_LEAD
    for lane in (1, 2):
        kit.add_plat(ax0, FLOOR - 48 * lane, SWINE_ARENA_W, 16, WETSTONE, kind="refuge", one_way=True)
    SWINE["center"] = ax0 + SWINE_ARENA_W // 2
    kit.hint("HintSwine", x0 + 40, x0 + 136, "Nothing hurts it while it rolls. Find a way to stop it")
    for x in (120, 1000):
        kit.add_prop("prop_torch", x0 + x, FLOOR - 110)
    kit.add_prop("prop_sign_hazard", x0 + 24, FLOOR)


def emit_swine(w):
    w.inst("SwineArena", ".", "swine_arena", position=vec(kit.mx(SWINE["center"]), FLOOR))


def section_collapse(x0):
    # Collapse beat and hand-off to Level 2 (#68). The end zone is the stub exit.
    flat(640)
    cp(6, x0 + 96, 6)
    furnish(x0, x0 + 640)
    trig("EndZone", "end", "", x0 + 640 - 100, x0 + 640 - 60, FLOOR - 120, FLOOR + 20)


BUILDERS = [section_tunnel, section_rats_corridor, section_saferoom, section_hoarder, section_workshop, section_swine, section_collapse]


def build():
    cur.update(x=0, y=FLOOR)
    kit.walls.append({"name": "RightBound", "x": -8, "y": FLOOR - 250, "kind": "wall"})
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
    emit_llama_alley(w)
    section_rats.emit(kit, w)
    emit_saferoom(w)
    emit_swine(w)
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
    text = saferoom_fixup(w.render(RES, "res://scripts/levels/level01.gd", UID))
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
