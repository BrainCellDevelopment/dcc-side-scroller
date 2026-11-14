#!/usr/bin/env python3
import os
import re
import sys
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PROJECT = ROOT + "/dcc-side-scroller"
OUT = PROJECT + "/scenes/level00.tscn"
MAP = ROOT + "/art-src/level/level00_map.png"
CONTRACT2 = ROOT + "/docs/contract-art.md"

RES = {
    "player": "res://scenes/player/player.tscn",
    "goblin": "res://scenes/enemies/goblin.tscn",
    "engineer": "res://scenes/enemies/engineer.tscn",
    "dozer": "res://scenes/enemies/dozer.tscn",
    "hud": "res://scenes/ui/hud.tscn",
    "lootbox": "res://scenes/props/loot_box.tscn",
    "platform": "res://scenes/level/platform.tscn",
    "spikes": "res://scenes/level/spikes.tscn",
    "killzone": "res://scenes/level/kill_zone.tscn",
    "checkpoint": "res://scenes/level/checkpoint.tscn",
    "background": "res://scenes/level/background.tscn",
}
for _k in ["torch", "lichen", "fire", "burnt_tree", "bike_rack", "moped", "rubble", "big_door", "rug", "fireplace",
           "bed", "desk", "bookshelf", "guildmaster", "stair_rail", "crate", "sign_arrow", "street_lamp", "street_lamp_bent", "street_sign", "stop_sign"]:
    RES["prop_" + _k] = "res://scenes/props/%s.tscn" % _k
RES["door"] = "res://scenes/props/door.tscn"
RES["mordecai"] = "res://scenes/props/mordecai.tscn"
EXISTING = ["player", "goblin", "engineer", "dozer", "hud", "lootbox"]

RUBBLE, IRON, STONE, WOOD = 0, 1, 2, 3
ARENA_W = 896
RUN_W = 416
JUMP_GAP = 64
STEP_UP = 48

plats = []
spikes = []
kills = []
cps = []
enemies = []
props = []
glow = []
trigs = []
walls = []
markers = []
doors = []
sections = []
routes = {"main": [], "upper": []}
labels = []
cur = {"x": 0, "y": 0, "gh": 64, "sec": 0, "style": RUBBLE}
pid = [0]


def snap_up(v, q=16):
    return int(-(-v // q) * q)


def add_plat(x, y, w, h, style, kind="route", one_way=False):
    pid[0] += 1
    p = {"id": "P%03d" % pid[0], "x": x, "y": y, "w": w, "h": h, "style": style, "kind": kind,
         "one_way": one_way, "sec": cur["sec"]}
    plats.append(p)
    return p


def add_spike(x, y, w, route):
    spikes.append({"x": x, "y": y, "w": w, "route": route, "sec": cur["sec"]})


def add_kill(x, y, w, h):
    kills.append({"x": x, "y": y, "w": w, "h": h})


PROP_W = {"prop_bike_rack": 40, "prop_moped": 40, "prop_rubble": 32, "prop_crate": 40, "prop_burnt_tree": 48,
          "prop_sign_arrow": 32, "prop_street_lamp": 40, "prop_street_lamp_bent": 48, "prop_street_sign": 40, "prop_stop_sign": 32, "prop_stair_rail": 64, "prop_fire": 32, "prop_big_door": 96}


def add_prop(key, x, y, free=False):
    props.append({"key": key, "x": x, "y": y, "free": free})


def add_enemy(kind, x, y):
    enemies.append({"kind": kind, "x": x, "y": y, "sec": cur["sec"]})


def grunt(x, y=None):
    add_enemy("grunt", x, cur["y"] if y is None else y)


def thrower(x, y=None):
    add_enemy("thrower", x, cur["y"] if y is None else y)


def cp(index, x, stage=0, y=None):
    cps.append({"index": index, "x": x, "y": cur["y"] if y is None else y, "stage": stage})


def trig(name, kind, arg, x0, x1, y0, y1, meta=None):
    trigs.append({"name": name, "kind": kind, "arg": arg, "x0": x0, "x1": x1, "y0": y0, "y1": y1,
                  "meta": meta or {}})


def hint(name, x0, x1, text, y=None):
    y = cur["y"] if y is None else y
    trig(name, "hint", text, x0, x1, y - 300, y + 120)


def secret(name, piece):
    trig(name, "ach", "secret_route", piece["x"] + 4, piece["x"] + piece["w"] - 4, piece["y"] - 50, piece["y"] - 2)


def ach(name, aid, x, y=None, w=32):
    y = cur["y"] if y is None else y
    trig(name, "ach", aid, x, x + w, y - 300, y + 120)


def flat(w, spk=(), style=None, h=None):
    p = add_plat(cur["x"], cur["y"], w, h or cur["gh"], cur["style"] if style is None else style)
    routes["main"].append(p["id"])
    for off, sw in spk:
        add_spike(cur["x"] + off, cur["y"], sw, True)
    cur["x"] += w
    return p


def block(x, w, h, style=None, y=None):
    top = (cur["y"] if y is None else y) - h
    return add_plat(x, top, w, h, cur["style"] if style is None else style, kind="obstacle")


def pit(w, fire=False):
    x, y = cur["x"], cur["y"]
    if fire:
        add_prop("prop_fire", x + w // 2, y + 60, free=True)
        add_kill(x, y + 40, w, 144)
    else:
        add_plat(x, y + 96, w, 16, STONE, kind="pitfloor")
        add_spike(x, y + 96, w, False)
        add_kill(x, y + 76, w, 108)
    cur["x"] += w


def start_section(idx, name, bg, title, style, bottom, top_off=420):
    cur["sec"] = idx
    cur["style"] = style
    cur["gh"] = max(64, snap_up(bottom - cur["y"]))
    sections.append({"idx": idx, "name": name, "x0": cur["x"], "bg": bg, "title": title, "bottom": bottom,
                     "top": cur["y"] - top_off, "y_start": cur["y"]})


def end_section():
    s = sections[-1]
    s["x1"] = cur["x"]


def branch(L, pieces):
    x, f = cur["x"], cur["y"]
    t = f + 64
    s1 = add_plat(x, f + 32, 32, 96, STONE, kind="route")
    trench = add_plat(x + 32, t, L, 64, STONE, kind="route")
    xe = x + 32 + L
    s3 = add_plat(xe, f + 32, 32, 96, STONE, kind="route")
    routes["main"] += [s1["id"], trench["id"], s3["id"]]
    ups = []
    px = x
    for gap, w, dy in pieces:
        p = add_plat(px + gap, f + dy, w, 16, STONE, kind="upper", one_way=True)
        ups.append(p)
        px = p["x"] + w
    cur["x"] = xe + 32
    return {"xb": x, "t": t, "xe": xe, "pieces": ups, "before": routes["main"][-4]}


def finish_upper(info):
    routes["upper"].append([info["before"]] + [p["id"] for p in info["pieces"]] + [routes["main"][-1]])


def build():
    # ---------------- Section 0: surface
    cur.update(x=0, y=304)
    walls.append({"name": "LeftBound", "x": -8, "y": 304 - 250, "kind": "wall"})
    start_section(0, "Surface", 0, "", RUBBLE, 364)
    a = flat(1120)
    block(592, 48, 32)
    block(1008, 32, 16)
    markers.append({"name": "PlayerStart", "x": 80, "y": 304})
    pit(48, fire=True)
    b = flat(1472, spk=[(352, 32)])
    grunt(1168 + 940)
    grunt(1168 + 1260)
    grunt(1168 + 1330)
    pit(48, fire=True)
    c = flat(816, spk=[(512, 48)])
    grunt(2688 + 260)
    grunt(2688 + 700)
    grunt(2688 + 745)
    pit(64, fire=True)
    d = flat(928)
    block(3744, 48, 16)
    block(3792, 48, 32)
    block(3840, 48, 16)
    grunt(3568 + 520)
    grunt(3568 + 580)
    cp(0, 4376, 0)
    hint("H_move", 0, 400, "A / D or arrows: move. Hold Shift to sprint")
    hint("H_jump", 440, 600, "Space: jump over it")
    hint("H_gap", 960, 1110, "Hold Space for a longer jump. Fire is not friendly.")
    hint("H_spikes", 1400, 1630, "Rebar hurts. Jump over the spikes.")
    hint("H_punch", 1780, 2020, "J: punch. Goblins take two hits.")
    hint("H_pair", 2300, 2520, "Two at once. Back up, then punch.")
    hint("H_combo", 2900, 3150, "Everything you learned, at the same time.")
    hint("H_crater", 4180, 4440, "The crater. Down you go.")
    ach("A_gap", "mind_gap", 1200)
    ach("A_rebar", "rebar", 1660)
    for x in (240, 960, 1850, 2600, 3400, 4200):
        add_prop("prop_sign_arrow", x, 304)
    for x in (320, 1070, 1700, 2350, 3050, 3650):
        add_prop("prop_fire", x, 304)
    for x in (150, 760, 1330, 2150, 2800, 3300, 3950):
        add_prop("prop_burnt_tree", x, 304)
    for x, k in ((520, "prop_street_lamp"), (1230, "prop_street_lamp_bent"), (2050, "prop_street_lamp"), (2760, "prop_street_lamp"),
                 (3480, "prop_street_lamp_bent"), (4260, "prop_street_lamp"), (460, "prop_street_sign"), (1590, "prop_stop_sign"),
                 (2420, "prop_street_sign"), (3180, "prop_stop_sign"), (3870, "prop_street_sign")):
        add_prop(k, x, 304)
    for x, k in ((380, "prop_moped"), (900, "prop_bike_rack"), (1450, "prop_rubble"), (1900, "prop_moped"),
                 (2480, "prop_bike_rack"), (3180, "prop_rubble"), (3600, "prop_bike_rack"), (4100, "prop_rubble"),
                 (4300, "prop_rubble"), (700, "prop_rubble"), (120, "prop_bike_rack")):
        add_prop(k, x, 304)
    glow.append((4496 - 150, 304))
    end_section()

    # ---------------- Section 1: staircase
    start_section(1, "Staircase", 1, "THE DESCENT", IRON, 972)
    cur["gh"] = 32
    y = 304
    plan = [("land", 288, 304), ("steps", 4), ("land", 384, 464), ("steps", 4), ("land", 448, 624),
            ("steps", 4), ("land", 384, 784), ("steps", 2), ("land", 192, 880)]
    ly = 304
    step_info = []
    for item in plan:
        if item[0] == "land":
            cur["y"] = item[2]
            p = flat(item[1], style=IRON, h=32)
            step_info.append(("land", p))
            ly = item[2]
        else:
            for i in range(item[1]):
                ly += 32
                cur["y"] = ly
                p = flat(128, style=IRON, h=16)
                step_info.append(("step", p))
    lands = [p for k, p in step_info if k == "land"]
    A, B, C, D, E1 = lands
    steps = [p for k, p in step_info if k == "step"]
    grunt(steps[1]["x"] + 64, steps[1]["y"])
    grunt(steps[3]["x"] + 64, steps[3]["y"])
    thrower(B["x"] + 330, B["y"])
    grunt(steps[5]["x"] + 64, steps[5]["y"])
    grunt(C["x"] + 190, C["y"])
    thrower(C["x"] + 400, C["y"])
    grunt(steps[8]["x"] + 64, steps[8]["y"])
    grunt(steps[10]["x"] + 64, steps[10]["y"])
    grunt(D["x"] + 140, D["y"])
    grunt(D["x"] + 220, D["y"])
    cp(1, C["x"] + 48, 0, C["y"])
    hint("H_stairs", A["x"], A["x"] + 280, "Down the stairs. Goblins want a word.", A["y"])
    hint("H_rocks", B["x"] + 40, B["x"] + 384, "Rocks incoming. Jump to dodge. The thrower has 2 HP.", B["y"])
    hint("H_ledge", E1["x"] - 120, E1["x"] + 140, "Spikes below. Jump the gap.", E1["y"])
    ach("A_crater", "crater", A["x"] + 16, A["y"])
    for p in lands:
        for rx in (p["x"] + 48, p["x"] + p["w"] - 48):
            add_prop("prop_stair_rail", rx, p["y"])
        add_prop("prop_torch", p["x"] + p["w"] // 2, p["y"] - 110)
    for p in steps:
        add_prop("prop_stair_rail", p["x"] + 64, p["y"])
    for p in steps[::2]:
        add_prop("prop_torch", p["x"] + 64, p["y"] - 120)
    pit(48)
    end_section()

    # ---------------- Section 2: entrance hall
    cur["y"] = 912
    start_section(2, "Entrance hall", 2, "ENTRANCE HALL", STONE, 972)
    x0 = cur["x"]
    flat(1200)
    cp(2, x0 + 48, 0)
    grunt(x0 + 640)
    grunt(x0 + 700)
    grunt(x0 + 760)
    ach("A_stairs", "stairs", x0 + 16)
    for i in range(6):
        add_prop("prop_torch", x0 + 120 + i * 200, 912 - 110)
    for i in range(3):
        add_prop("prop_lichen", x0 + 220 + i * 360, 912 - 60)
    add_prop("prop_crate", x0 + 480, 912)
    end_section()

    # ---------------- Section 3: tunnels
    start_section(3, "Tunnels", 2, "THE TUNNELS", STONE, 1036)
    t0 = cur["x"]
    # stretch A
    cp(3, cur["x"] + 48, 0)
    flat(336)
    pit(48)
    flat(192)
    grunt(cur["x"] - 80)
    p = flat(256)
    add_plat(p["x"] + 32, 912 - 96, 128, 48, STONE, kind="ceil")
    grunt(p["x"] + 96)
    flat(160)
    hint("H_fork", cur["x"] - 150, cur["x"] + 100, "Low road: busy. High road: tricky.")
    info = branch(576, [(64, 96, 0), (48, 96, 0), (48, 64, -32), (48, 64, -32), (32, 48, 0)])
    tr = info["t"]
    grunt(info["xb"] + 32 + 220, tr)
    grunt(info["xb"] + 32 + 400, tr)
    thrower(info["pieces"][1]["x"] + 64, info["pieces"][1]["y"])
    f_after = flat(224, spk=[(96, 32)])
    finish_upper(info)
    secret("A_secret", info["pieces"][3])
    flat(288)
    grunt(cur["x"] - 288 + 112)
    grunt(cur["x"] - 288 + 160)
    grunt(cur["x"] - 288 + 208)
    pit(64)
    p = flat(448)
    blk = block(p["x"] + 288, 96, 48)
    thrower(blk["x"] + 48, blk["y"])
    grunt(p["x"] + 100)
    # stretch B
    cp(4, cur["x"] + 48, 0)
    p = flat(320)
    grunt(p["x"] + 200)
    pit(64)
    flat(224, spk=[(80, 48)])
    room = flat(480)
    add_plat(room["x"], 912 - 96, 240, 48, STONE, kind="ceil")
    add_plat(room["x"] + 384, 912 - 96, 96, 48, STONE, kind="ceil")
    trig("T_ambush", "ambush", "%d,%d,%d,%d" % (room["x"] + 288, room["x"] + 320, room["x"] + 352, 912 - 300),
         room["x"] + 120, room["x"] + 152, 912 - 300, 912 + 60)
    flat(160)
    info = branch(704, [(64, 96, 0), (64, 64, -16), (32, 48, -48), (64, 64, -48), (48, 96, -16), (32, 64, 0)])
    tr = info["t"]
    grunt(info["xb"] + 32 + 180, tr)
    grunt(info["xb"] + 32 + 260, tr)
    lb = block(info["xb"] + 32 + 480, 96, 48, y=tr)
    thrower(lb["x"] + 48, lb["y"])
    thrower(info["pieces"][4]["x"] + 48, info["pieces"][4]["y"])
    p = flat(400, spk=[(64, 48)])
    finish_upper(info)
    secret("A_secret2", info["pieces"][2])
    blk = block(p["x"] + 224, 96, 48)
    thrower(blk["x"] + 48, blk["y"])
    grunt(p["x"] + 160)
    grunt(p["x"] + 330)
    pit(64)
    flat(192)
    # stretch C
    cp(5, cur["x"] + 48, 0)
    p = flat(256)
    grunt(p["x"] + 150)
    grunt(p["x"] + 210)
    pit(64)
    p = flat(160)
    blk = block(p["x"] + 48, 96, 48)
    thrower(blk["x"] + 48, blk["y"])
    info = branch(736, [(64, 80, -16), (64, 64, -32), (48, 48, -48), (64, 64, -48), (48, 64, -16), (64, 64, 0)])
    tr = info["t"]
    grunt(info["xb"] + 32 + 160, tr)
    grunt(info["xb"] + 32 + 230, tr)
    grunt(info["xb"] + 32 + 300, tr)
    lb = block(info["xb"] + 32 + 528, 96, 48, y=tr)
    thrower(lb["x"] + 48, lb["y"])
    thrower(info["pieces"][4]["x"] + 32, info["pieces"][4]["y"])
    g = flat(448, spk=[(64, 32), (160, 32), (256, 32), (352, 32)])
    finish_upper(info)
    secret("A_secret3", info["pieces"][3])
    gp = flat(576, spk=[(64, 48), (176, 48), (288, 48), (400, 48)])
    for off, h in ((112, 32), (224, 48), (336, 32), (448, 48)):
        block(gp["x"] + off, 64, h)
    ach("A_gauntlet", "gauntlet", gp["x"] + 528, w=48)
    p = flat(288)
    grunt(p["x"] + 112)
    grunt(p["x"] + 168)
    grunt(p["x"] + 224)
    p = flat(160)
    cp(6, p["x"] + 80, 0)
    t1 = cur["x"]
    for x in range(t0 + 120, t1, 240):
        add_prop("prop_torch", x, 912 - 110)
    for x in range(t0 + 240, t1, 240):
        add_prop("prop_lichen", x, 912 - 70)
    end_section()

    # ---------------- Section 4: engineer arena
    start_section(4, "Engineer arena", 2, "", STONE, 972)
    a0 = cur["x"]
    flat(704)
    add_plat(a0 + 192, 912 - 64, 96, 16, STONE, kind="deco")
    add_plat(a0 + 432, 912 - 64, 96, 16, STONE, kind="deco")
    walls.append({"name": "ArenaLeftWall", "x": a0, "y": 912 - 250, "kind": "arena"})
    walls.append({"name": "ArenaRightWall", "x": a0 + 704, "y": 912 - 250, "kind": "arena"})
    scroll0 = a0 + 30
    markers.append({"name": "ScrollStart", "x": scroll0, "y": 912})
    trig("T_arena", "arena", "", a0 + 128, a0 + 160, 912 - 300, 912 + 60)
    add_enemy("engineer", a0 + 540, 912)
    for x in (a0 + 100, a0 + 350, a0 + 600):
        add_prop("prop_torch", x, 912 - 110)
    props_banner = [a0 + 250, a0 + 480]
    end_section()

    # ---------------- Section 5: short run and dozer arena
    start_section(5, "Dozer arena", 2, "", STONE, 972)
    flat(RUN_W)
    arena_x = cur["x"]
    for x in (arena_x - 300, arena_x - 120):
        add_prop("prop_torch", x, 912 - 110)
    markers.append({"name": "DozerArena", "x": arena_x, "y": 912})
    cp(7, arena_x + 56, 1)
    flat(ARENA_W)
    markers.append({"name": "DozerLeft", "x": arena_x + 100, "y": 912})
    markers.append({"name": "DozerRight", "x": arena_x + ARENA_W - 26, "y": 912})
    walls.append({"name": "DozerWall", "x": arena_x + 24, "y": 912 - 250, "kind": "arena"})
    trig("T_dozer", "dozer", "", arena_x + 96, arena_x + 128, 912 - 300, 912 + 60)
    add_enemy("dozer", arena_x, 912)
    add_plat(arena_x + 272, 912 - 48, 112, 16, STONE, kind="refuge", one_way=True)
    add_plat(arena_x + 608, 912 - 48, 112, 16, STONE, kind="refuge", one_way=True)
    for x in (arena_x + 200, arena_x + 450, arena_x + 700):
        add_prop("prop_torch", x, 912 - 110)
    end_section()

    # ---------------- Section 6: guildhall
    start_section(6, "Guildhall", 3, "GUILDHALL", WOOD, 972)
    g0 = cur["x"]
    flat(896)
    cp(8, g0 + 56, 2)
    gx = g0 + 448
    markers.append({"name": "GuildCenter", "x": gx, "y": 912})
    doors.append({"name": "GuildEntryDoor", "x": g0 + 48, "y": 912, "locked": True, "range": 170,
                  "text": "Locked. Finish the dozer."})
    doors.append({"name": "GuildExitDoor", "x": gx + 402, "y": 912, "locked": True,
                  "text": "Locked. Talk to Mordecai and open your boxes."})
    walls.append({"name": "RightBound", "x": g0 + 904, "y": 912 - 250, "kind": "wall"})
    end_section()
    return {"gx": gx, "scroll0": scroll0, "a0": a0, "banner": props_banner}


GUILD = [
    ("prop_bookshelf", -310, 0), ("prop_bookshelf", -252, 0), ("prop_desk", -150, 0),
    ("prop_rug", 40, 0), ("prop_fireplace", 200, 0), ("prop_bed", 326, 0),
]


# ---------------------------------------------------------------- tscn writer
class Writer:
    def __init__(self):
        self.ext = {}
        self.sub = {}
        self.nodes = []

    def ext_id(self, key):
        if key not in self.ext:
            self.ext[key] = "%d_%s" % (len(self.ext) + 1, key.replace("prop_", "p_"))
        return self.ext[key]

    def shape(self, w, h):
        sid = "shape_%dx%d" % (round(w), round(h))
        self.sub[sid] = (round(w, 2), round(h, 2))
        return sid

    def node(self, text):
        self.nodes.append(text)


def fnum(v):
    if abs(v - round(v)) < 1e-6:
        return str(int(round(v)))
    return ("%.2f" % v).rstrip("0").rstrip(".")


def vec(x, y):
    return "Vector2(%s, %s)" % (fnum(x), fnum(y))


def qstr(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_tscn(info):
    w = Writer()
    w.ext_id("script")
    out = []

    def inst(name, parent, key, **props_):
        lines = ['[node name="%s" parent="%s" instance=ExtResource("%s")]' % (name, parent, w.ext_id(key))]
        for k, v in props_.items():
            lines.append("%s = %s" % (k, v))
        w.node("\n".join(lines))

    def raw(name, typ, parent, lines, groups=None):
        head = '[node name="%s" type="%s"' % (name, typ)
        if parent:
            head += ' parent="%s"' % parent
        if groups:
            head += " groups=[%s]" % ", ".join(qstr(g) for g in groups)
        head += "]"
        w.node("\n".join([head] + lines))

    w.node('[node name="Level00" type="Node2D"]\nscript = ExtResource("1_level")')
    inst("Background", ".", "background")
    raw("Deco", "Node2D", ".", ["z_index = -2"])  # z: bg -10 < props -2 < platforms -1 < actors 0 < fx 10
    raw("Platforms", "Node2D", ".", [])
    raw("Hazards", "Node2D", ".", [])
    raw("Checkpoints", "Node2D", ".", [])
    raw("Triggers", "Node2D", ".", [])
    raw("Walls", "Node2D", ".", [])
    raw("Markers", "Node2D", ".", [])
    raw("Doors", "Node2D", ".", ["z_index = -2"])
    raw("Goblins", "Node2D", ".", [])

    for i, d in enumerate(props):
        inst("D%03d" % i, "Deco", d["key"], position=vec(d["x"], d["y"]))
    for i, b in enumerate(info["banner"]):
        raw("Banner%d" % i, "Polygon2D", "Deco",
            ["position = %s" % vec(b, 912 - 150),
             "color = Color(0.55, 0.1, 0.12, 1)",
             "polygon = PackedVector2Array(-10, 0, 10, 0, 10, 56, 0, 46, -10, 56)"])
    for i, (gx0, gy0) in enumerate(glow):
        raw("Glow%d" % i, "Polygon2D", "Deco",
            ["position = %s" % vec(gx0, gy0), "color = Color(1, 0.55, 0.15, 0.2)",
             "polygon = PackedVector2Array(0, 0, 300, 0, 240, -120, 60, -120)"])
        raw("GlowCore%d" % i, "Polygon2D", "Deco",
            ["position = %s" % vec(gx0 + 70, gy0), "color = Color(1, 0.8, 0.4, 0.28)",
             "polygon = PackedVector2Array(0, 0, 160, 0, 130, -70, 30, -70)"])
    for p in plats:
        lines = ["position = %s" % vec(p["x"], p["y"]), "size = %s" % vec(p["w"], p["h"]),
                 "style = %d" % p["style"]]
        if p["one_way"]:
            lines.append("one_way = true")
        inst(p["id"], "Platforms", "platform", **{l.split(" = ")[0]: l.split(" = ")[1] for l in lines})
    for i, s in enumerate(spikes):
        inst("S%03d" % i, "Hazards", "spikes", position=vec(s["x"], s["y"]), width=fnum(s["w"]) + ".0")
    for i, k in enumerate(kills):
        inst("K%03d" % i, "Hazards", "killzone", position=vec(k["x"], k["y"]), size=vec(k["w"], k["h"]))
    for c in cps:
        inst("CP%d" % c["index"], "Checkpoints", "checkpoint", position=vec(c["x"], c["y"]),
             index=str(c["index"]), stage=str(c["stage"]))
    for i, t in enumerate(trigs):
        cx = (t["x0"] + t["x1"]) / 2
        cy = (t["y0"] + t["y1"]) / 2
        lines = ["position = %s" % vec(cx, cy), "collision_layer = 0", "collision_mask = 2",
                 "metadata/kind = %s" % qstr(t["kind"]), "metadata/arg = %s" % qstr(str(t["arg"]))]
        for k, v in t["meta"].items():
            lines.append("metadata/%s = %s" % (k, qstr(v) if isinstance(v, str) else str(v)))
        raw(t["name"], "Area2D", "Triggers", lines)
        raw("Shape", "CollisionShape2D", "Triggers/" + t["name"],
            ["shape = SubResource(\"%s\")" % w.shape(t["x1"] - t["x0"], t["y1"] - t["y0"])])
    for wl in walls:
        raw(wl["name"], "StaticBody2D", "Walls", ["position = %s" % vec(wl["x"], wl["y"]),
                                                  "collision_layer = 1", "collision_mask = 0"])
        lines = ['shape = SubResource("%s")' % w.shape(16, 720)]
        if wl["kind"] == "arena":
            lines.append("disabled = true")
        raw("CollisionShape2D", "CollisionShape2D", "Walls/" + wl["name"], lines)
    for m in markers:
        raw(m["name"], "Marker2D", "Markers", ["position = %s" % vec(m["x"], m["y"])])

    gi = 0
    for e in enemies:
        if e["kind"] in ("grunt", "thrower"):
            gi += 1
            extra = {"variant": "1"} if e["kind"] == "thrower" else {}
            inst("G%02d" % gi, "Goblins", "goblin", position=vec(e["x"], e["y"] - 2), **extra)
    eng = [e for e in enemies if e["kind"] == "engineer"][0]
    dz = [e for e in enemies if e["kind"] == "dozer"][0]
    inst("Engineer", ".", "engineer", position=vec(eng["x"], eng["y"] - 2), max_health="16")
    inst("Dozer", ".", "dozer", position=vec(dz["x"], dz["y"]))
    inst("Player", ".", "player", position=vec(80, 302))

    for d in doors:
        dp = {"position": vec(d["x"], d["y"]), "locked": "true" if d["locked"] else "false"}
        if d.get("open"):
            dp["start_open"] = "true"
        if d.get("range"):
            dp["auto_open_range"] = "%d.0" % d["range"]
        if d["text"]:
            dp["locked_text"] = qstr(d["text"])
        inst(d["name"], "Doors", "door", **dp)

    gx = info["gx"]
    raw("Guildhall", "Node2D", ".", ["position = %s" % vec(gx, 912)])
    for i, (k, x, y) in enumerate(GUILD):
        inst("G%d_%s" % (i, k.replace("prop_", "")), "Guildhall", k, position=vec(x, y), z_index="-2")
    inst("Mordecai", "Guildhall", "mordecai", position=vec(-100, 0))
    raw("ExitZone", "Area2D", "Guildhall", ["position = Vector2(402, -50)", "collision_layer = 0",
                                           "collision_mask = 2"])
    raw("CollisionShape2D", "CollisionShape2D", "Guildhall/ExitZone", ['shape = SubResource("%s")' % w.shape(24, 100)])
    raw("SafeZone", "Area2D", "Guildhall", ["position = Vector2(0, -60)", "collision_layer = 0",
                                           "collision_mask = 2"])
    raw("CollisionShape2D", "CollisionShape2D", "Guildhall/SafeZone", ['shape = SubResource("%s")' % w.shape(880, 140)])
    raw("LootBoxes", "Node2D", "Guildhall", [])
    inst("LootBoxBronze", "Guildhall/LootBoxes", "lootbox", position=vec(20, 0))
    inst("LootBoxSilver", "Guildhall/LootBoxes", "lootbox", position=vec(80, 0), tier=qstr("Silver"), slot="1")

    raw("Camera2D", "Camera2D", ".", [
        "position = Vector2(320, 184)", "limit_left = 0", "limit_top = -116", "limit_right = 4820",
        "limit_bottom = 364", "limit_smoothed = true", "position_smoothing_enabled = true",
        "position_smoothing_speed = 6.0"])
    inst("HUD", ".", "hud")

    # section triggers
    for s in sections:
        l = s["x0"] - 320
        r = s["x1"] + 320
        if s["idx"] == 0:
            l = 0
        if s["idx"] == 5:
            l = info["scroll0"]
            r = s["x1"]
        if s["idx"] == 6:
            r = s["x1"]
        s["l"], s["r"] = l, r
        meta = {"l": l, "r": r, "t": s["top"], "b": s["bottom"], "bg": s["bg"], "x0": s["x0"], "x1": s["x1"],
                "title": s["title"]}
        t = {"name": "Sec%d" % s["idx"], "kind": "section", "arg": str(s["idx"]), "x0": s["x0"], "x1": s["x1"],
             "y0": -400, "y1": 1500, "meta": meta}
        trigs.append(t)
        cx = (t["x0"] + t["x1"]) / 2
        cy = (t["y0"] + t["y1"]) / 2
        lines = ["position = %s" % vec(cx, cy), "collision_layer = 0", "collision_mask = 2",
                 'metadata/kind = "section"', 'metadata/arg = "%d"' % s["idx"]]
        for k, v in meta.items():
            lines.append("metadata/%s = %s" % (k, qstr(v) if isinstance(v, str) else str(v)))
        raw(t["name"], "Area2D", "Triggers", lines)
        raw("Shape", "CollisionShape2D", "Triggers/" + t["name"],
            ['shape = SubResource("%s")' % w.shape(t["x1"] - t["x0"], t["y1"] - t["y0"])])

    ext_lines = ['[ext_resource type="Script" path="res://scripts/levels/level00.gd" id="1_level"]']
    for key, eid in w.ext.items():
        if key == "script":
            continue
        ext_lines.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % (RES[key], eid))
    sub_lines = []
    for sid, (sw, sh) in w.sub.items():
        sub_lines.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = %s\n' % (sid, vec(sw, sh)))
    total = len(ext_lines) + len(sub_lines) + 1
    text = "[gd_scene load_steps=%d format=3 uid=\"uid://dsypb287qo2hi\"]\n\n" % total
    text += "\n".join(ext_lines) + "\n\n" + "\n".join(sub_lines) + "\n"
    text += "\n\n".join(w.nodes) + "\n"
    # camera and node text built before ids resolved: ensure Camera2D/other nodes ok
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write(text)
    return text, w


# ---------------------------------------------------------------- linter
def lint(text, w, info):
    errs = []
    notes = []

    ext_def = re.findall(r'^\[ext_resource [^\]]*id="([^"]+)"', text, re.M)
    sub_def = re.findall(r'^\[sub_resource [^\]]*id="([^"]+)"', text, re.M)
    ext_use = set(re.findall(r'ExtResource\("([^"]+)"\)', text))
    sub_use = set(re.findall(r'SubResource\("([^"]+)"\)', text))
    for i in ext_def:
        if i not in ext_use:
            errs.append("unused ext_resource " + i)
    for i in ext_use:
        if i not in ext_def:
            errs.append("undefined ExtResource " + i)
    for i in sub_def:
        if i not in sub_use:
            errs.append("unused sub_resource " + i)
    for i in sub_use:
        if i not in sub_def:
            errs.append("undefined SubResource " + i)
    if len(set(ext_def)) != len(ext_def) or len(set(sub_def)) != len(sub_def):
        errs.append("duplicate resource ids")
    m = re.match(r"\[gd_scene load_steps=(\d+) format=3( uid=\"[^\"]+\")?\]", text)
    if not m or int(m.group(1)) != len(ext_def) + len(sub_def) + 1:
        errs.append("load_steps wrong")
    if text.count("uid=") != 1:
        errs.append("unexpected uid")

    paths = set()
    sibs = {}
    for nm in re.finditer(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]*)")?', text, re.M):
        name, parent = nm.group(1), nm.group(2)
        if parent is None:
            paths.add(".")
            continue
        if parent != "." and parent not in paths:
            errs.append("missing parent %s for %s" % (parent, name))
        full = name if parent == "." else parent + "/" + name
        key = (parent, name)
        if key in sibs:
            errs.append("duplicate sibling %s/%s" % (parent, name))
        sibs[key] = 1
        paths.add(full)

    c2 = open(CONTRACT2).read()
    for key, path in RES.items():
        if key in EXISTING:
            if not os.path.exists(PROJECT + "/" + path[6:]):
                errs.append("missing existing scene " + path)
        else:
            base = os.path.basename(path)
            if base not in c2:
                errs.append("instanced path not in CONTRACT2: " + path)
            sub = "/".join(path.split("/")[-2:-1])
            if "scenes/" + sub + "/" not in c2:
                errs.append("folder not in CONTRACT2: " + path)

    for p in plats:
        for k in ("x", "y", "w", "h"):
            if p[k] % 16:
                errs.append("platform %s %s=%s not 16 aligned" % (p["id"], k, p[k]))
    for s in spikes:
        for k in ("x", "y", "w"):
            if s[k] % 16:
                errs.append("spikes at %s %s not aligned" % (s["x"], k))
    for c in cps:
        if c["y"] % 16 or c["x"] % 8:
            errs.append("checkpoint %d misaligned" % c["index"])
    for k in kills:
        for v in (k["x"], k["w"]):
            if v % 16:
                errs.append("kill zone misaligned %s" % k)

    pmap = {p["id"]: p for p in plats}

    def gap_check(a, b, label):
        gap = max(0, b["x"] - (a["x"] + a["w"]), a["x"] - (b["x"] + b["w"]))
        up = a["y"] - b["y"]
        if b["x"] < a["x"]:
            errs.append("%s: route goes backwards %s -> %s" % (label, a["id"], b["id"]))
        if up > STEP_UP:
            errs.append("%s: step up %d too high %s -> %s" % (label, up, a["id"], b["id"]))
        lim = JUMP_GAP
        if up > 32:
            lim = 32
        if gap > lim:
            errs.append("%s: gap %d > %d between %s (x=%d) and %s (x=%d)" % (label, gap, lim, a["id"], a["x"], b["id"], b["x"]))
        if gap > 0 and -up > 96:
            errs.append("%s: drop with gap too deep %s -> %s" % (label, a["id"], b["id"]))
        return gap, up

    main = [pmap[i] for i in routes["main"]]
    maxgap = maxup = 0
    for a, b in zip(main, main[1:]):
        g, u = gap_check(a, b, "main")
        maxgap, maxup = max(maxgap, g), max(maxup, u)
    for seg in routes["upper"]:
        pl = [pmap[i] for i in seg]
        for a, b in zip(pl, pl[1:]):
            gap_check(a, b, "upper")
    notes.append("main route: %d platforms, max gap %d, max step-up %d, upper segments %d" %
                 (len(main), maxgap, maxup, len(routes["upper"])))
    if main[0]["x"] != 0:
        errs.append("main route does not start at x=0")

    mains = set(routes["main"])
    for s in spikes:
        if not s["route"]:
            continue
        if s["w"] > 48:
            errs.append("route spike too wide at %d" % s["x"])
        host = [p for p in plats if p["id"] in mains and p["y"] == s["y"] and p["x"] <= s["x"] and
                s["x"] + s["w"] <= p["x"] + p["w"]]
        if not host:
            errs.append("route spike at %d has no platform" % s["x"])
            continue
        h = host[0]
        others = [o for o in spikes if o is not s and o["route"] and o["y"] == s["y"] and h["x"] <= o["x"] < h["x"] + h["w"]]
        left = s["x"] - max([h["x"]] + [o["x"] + o["w"] for o in others if o["x"] < s["x"]])
        right = min([h["x"] + h["w"]] + [o["x"] for o in others if o["x"] > s["x"]]) - (s["x"] + s["w"])
        if left < 32 or right < 32:
            errs.append("spike at %d flat before/after %d/%d < 32" % (s["x"], left, right))

    obs = [p for p in plats if p["kind"] == "obstacle"]
    for o in obs:
        if o["h"] > 48:
            errs.append("obstacle %s too tall" % o["id"])
        if not any(p["id"] in mains and p["x"] <= o["x"] and o["x"] + o["w"] <= p["x"] + p["w"] and
                   p["y"] <= o["y"] + o["h"] and o["y"] + o["h"] <= p["y"] + 0.1 for p in plats):
            errs.append("obstacle %s not sitting on a route platform" % o["id"])
        for s in spikes:
            if s["route"] and abs(s["y"] - (o["y"] + o["h"])) < 1 and o["x"] < s["x"] + s["w"] and s["x"] < o["x"] + o["w"]:
                errs.append("obstacle %s overlaps spikes" % o["id"])

    for r in main:
        for q in plats:
            if q is r or q["kind"] in ("obstacle", "pitfloor", "refuge"):
                continue
            ox = min(r["x"] + r["w"], q["x"] + q["w"]) - max(r["x"], q["x"])
            if ox <= 0:
                continue
            if q["kind"] == "ceil":
                clear = r["y"] - (q["y"] + q["h"])
                if 0 <= clear < 44:
                    errs.append("ceiling %s clearance %d < 44 over %s" % (q["id"], clear, r["id"]))
                continue
            if q["y"] < r["y"] and q["y"] + q["h"] > r["y"] - 40:
                errs.append("platform %s blocks walking box of %s" % (q["id"], r["id"]))
    for q in plats:
        if q["kind"] == "ceil":
            under = [r for r in main if min(r["x"] + r["w"], q["x"] + q["w"]) - max(r["x"], q["x"]) > 0]
            if not under:
                errs.append("ceiling %s has no floor" % q["id"])

    def support(x, y, tol=1):
        for p in plats:
            if p["kind"] in ("pitfloor", "ceil", "deco", "refuge"):
                continue
            if abs(p["y"] - y) <= tol and p["x"] + 8 <= x <= p["x"] + p["w"] - 8:
                return p
        return None

    for d in props:
        pw = PROP_W.get(d["key"])
        if pw is None or d["free"]:
            continue
        lo, hi = d["x"] - pw / 2, d["x"] + pw / 2
        iv = sorted((max(lo, q["x"]), min(hi, q["x"] + q["w"])) for q in plats
                    if q["kind"] not in ("pitfloor", "ceil", "deco", "refuge", "obstacle") and abs(q["y"] - d["y"]) <= 1
                    and q["x"] < hi and q["x"] + q["w"] > lo)
        cov, end = 0, lo
        for a, b in iv:
            a = max(a, end)
            if b > a:
                cov += b - a
                end = b
        if cov < pw * 0.9:
            errs.append("prop %s at (%d,%d) only %d%% supported" % (d["key"], d["x"], d["y"], 100 * cov // pw))

    for e in enemies:
        if e["kind"] == "dozer":
            continue
        if support(e["x"], e["y"]) is None:
            errs.append("enemy %s at (%d,%d) has no platform" % (e["kind"], e["x"], e["y"]))
    for c in cps:
        if support(c["x"], c["y"]) is None:
            errs.append("checkpoint %d has no platform" % c["index"])
    idxs = sorted(c["index"] for c in cps)
    if idxs != sorted(set(idxs)):
        errs.append("duplicate checkpoint index")
    for a, b in zip(sections, sections[1:]):
        if a["x1"] != b["x0"]:
            errs.append("sections %d/%d not contiguous" % (a["idx"], b["idx"]))
    for s in sections:
        if not (s["l"] <= s["x0"] and s["r"] >= s["x1"]):
            errs.append("section %d x not inside camera limits" % s["idx"])
        for p in plats:
            if s["x0"] <= p["x"] < s["x1"]:
                if p["y"] < s["top"]:
                    errs.append("platform %s above section %d top limit" % (p["id"], s["idx"]))
                if p["kind"] in ("route", "obstacle", "upper") and p["y"] > s["bottom"]:
                    errs.append("platform %s below section %d bottom limit" % (p["id"], s["idx"]))
        for e in enemies:
            if s["x0"] <= e["x"] < s["x1"] and not (s["top"] <= e["y"] <= s["bottom"]):
                errs.append("enemy outside limits in section %d" % s["idx"])
    for t in trigs:
        if t["kind"] in ("hint", "ach", "ambush", "arena", "dozer"):
            if not any(s["x0"] - 1 <= t["x0"] and t["x1"] <= s["x1"] + 1 for s in sections):
                errs.append("trigger %s spans sections" % t["name"])
    ids = [t["name"] for t in trigs]
    if len(ids) != len(set(ids)):
        errs.append("duplicate trigger names")
    notes.append("platforms %d spikes %d kill zones %d enemies %d checkpoints %d triggers %d props %d" %
                 (len(plats), len(spikes), len(kills), len([e for e in enemies if e['kind'] in ('grunt', 'thrower')]),
                  len(cps), len(trigs), len(props)))
    return errs, notes


# ---------------------------------------------------------------- map
def draw_map(info):
    scale = 0.6
    chunk = 2800
    total_w = sections[-1]["x1"]
    rows = []
    x = 0
    while x < total_w:
        rows.append((x, min(x + chunk, total_w)))
        x += chunk
    imgs = []
    for x0, x1 in rows:
        inx = [p for p in plats if p["x"] + p["w"] > x0 and p["x"] < x1 and p["kind"] in ("route", "obstacle", "upper", "ceil")]
        ytop = min(p["y"] for p in inx) - 200
        ybot = max(p["y"] for p in inx) + 90
        h = int((ybot - ytop) * scale) + 24
        img = Image.new("RGB", (int(chunk * scale) + 20, h), (24, 22, 30))
        d = ImageDraw.Draw(img)

        def tx(v):
            return (v - x0) * scale + 10

        def ty(v):
            return (v - ytop) * scale + 20

        for s in sections:
            if s["x1"] > x0 and s["x0"] < x1:
                sx = tx(max(s["x0"], x0))
                d.line([(sx, 0), (sx, h)], fill=(120, 120, 60))
                d.text((sx + 3, 2), "S%d %s" % (s["idx"], s["name"]), fill=(240, 240, 120))
        for t in trigs:
            if t["kind"] == "section" or not (x0 <= t["x0"] < x1):
                continue
            col = {"hint": (90, 90, 40), "ach": (60, 40, 110), "ambush": (170, 60, 20), "arena": (170, 20, 120), "dozer": (170, 20, 120)}[t["kind"]]
            d.rectangle([tx(t["x0"]), ty(t["y0"]), tx(t["x1"]), ty(t["y1"])], outline=col)
        for p in plats:
            if not (p["x"] + p["w"] > x0 and p["x"] < x1):
                continue
            col = {"route": (150, 150, 160), "obstacle": (180, 150, 110), "upper": (110, 190, 230),
                   "ceil": (110, 90, 90), "deco": (90, 100, 90), "refuge": (90, 100, 90), "pitfloor": (70, 70, 70)}[p["kind"]]
            d.rectangle([tx(p["x"]), ty(p["y"]), tx(p["x"] + p["w"]), ty(p["y"] + p["h"])], fill=col)
        for k in kills:
            if x0 <= k["x"] < x1:
                d.rectangle([tx(k["x"]), ty(k["y"]), tx(k["x"] + k["w"]), ty(k["y"] + 60)], fill=(120, 20, 20))
        for s in spikes:
            if x0 <= s["x"] < x1:
                d.polygon([(tx(s["x"]), ty(s["y"])), (tx(s["x"] + s["w"]), ty(s["y"])),
                           (tx(s["x"] + s["w"] / 2), ty(s["y"] - 16))], fill=(240, 60, 60))
        for e in enemies:
            if x0 <= e["x"] < x1:
                col = {"grunt": (60, 220, 90), "thrower": (255, 160, 40), "engineer": (200, 60, 255),
                       "dozer": (255, 255, 255)}[e["kind"]]
                d.ellipse([tx(e["x"]) - 4, ty(e["y"]) - 14, tx(e["x"]) + 4, ty(e["y"]) - 6], fill=col)
        for c in cps:
            if x0 <= c["x"] < x1:
                d.line([(tx(c["x"]), ty(c["y"])), (tx(c["x"]), ty(c["y"]) - 22)], fill=(0, 230, 230), width=2)
                d.rectangle([tx(c["x"]), ty(c["y"]) - 22, tx(c["x"]) + 8, ty(c["y"]) - 16], fill=(0, 230, 230))
                d.text((tx(c["x"]) + 10, ty(c["y"]) - 24), "CP%d/%d" % (c["index"], c["stage"]), fill=(0, 230, 230))
        for t in trigs:
            if t["kind"] == "ambush" and x0 <= t["x0"] < x1:
                d.text((tx(t["x0"]), ty(t["y0"])), "AMBUSH", fill=(255, 140, 60))
            if t["kind"] == "arena" and x0 <= t["x0"] < x1:
                d.text((tx(t["x0"]), ty(t["y0"])), "ARENA", fill=(255, 80, 200))
            if t["kind"] == "ach" and t["arg"] == "secret_route" and x0 <= t["x0"] < x1:
                d.text((tx(t["x0"]), ty(t["y0"] + 200)), "secret", fill=(180, 140, 255))
        imgs.append(img)
    H = sum(i.height for i in imgs) + 4 * len(imgs)
    out = Image.new("RGB", (imgs[0].width, H), (0, 0, 0))
    yy = 0
    for i in imgs:
        out.paste(i, (0, yy))
        yy += i.height + 4
    out.save(MAP)


def main():
    info = build()
    text, w = write_tscn(info)
    errs, notes = lint(text, w, info)
    draw_map(info)
    for s in sections:
        print("section %d %-15s x %6d..%6d  floor y %s  limits l=%d r=%d t=%d b=%d bg=%d" %
              (s["idx"], s["name"], s["x0"], s["x1"], s["y_start"], s["l"], s["r"], s["top"], s["bottom"], s["bg"]))
    for c in cps:
        print("checkpoint", c)
    for n in notes:
        print("note:", n)
    print("ERRORS: %d" % len(errs))
    for e in errs:
        print("  -", e)
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
