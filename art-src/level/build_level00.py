#!/usr/bin/env python3
import os
import re
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import levelkit
from levelkit import Writer, fnum, vec, qstr, RUBBLE, IRON, STONE, WOOD, JUMP_GAP, STEP_UP, PROP_W

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
RES["door"] = "res://scenes/props/gate_door.tscn"
RES["mordecai"] = "res://scenes/props/mordecai.tscn"
EXISTING = ["player", "goblin", "engineer", "dozer", "hud", "lootbox"]


ARENA_W = 896
RUN_W = 416

kit = levelkit.Kit(PROJECT, CONTRACT2)
plats, spikes, kills, cps = kit.plats, kit.spikes, kit.kills, kit.cps
enemies, props, trigs, walls = kit.enemies, kit.props, kit.trigs, kit.walls
markers, doors, sections, routes, cur = kit.markers, kit.doors, kit.sections, kit.routes, kit.cur
glow = []
add_plat, add_spike, add_kill, add_prop, add_enemy = kit.add_plat, kit.add_spike, kit.add_kill, kit.add_prop, kit.add_enemy
grunt, thrower, cp, trig, hint, secret, ach = kit.grunt, kit.thrower, kit.cp, kit.trig, kit.hint, kit.secret, kit.ach
flat, block, pit, start_section, end_section = kit.flat, kit.block, kit.pit, kit.start_section, kit.end_section
branch, finish_upper = kit.branch, kit.finish_upper


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
    cp(8, g0 + 168, 2)
    gx = g0 + 448
    markers.append({"name": "GuildCenter", "x": gx, "y": 912})
    doors.append({"name": "GuildEntryDoor", "x": g0 + 48, "y": 912, "locked": True, "range": 170,
                  "text": "Locked. Finish the dozer.", "close_behind": True,
                  "sealed": "Locked. Talk to Mordecai and open your boxes."})
    walls.append({"name": "RightBound", "x": g0 + 904, "y": 912 - 250, "kind": "wall"})
    end_section()
    return {"gx": gx, "scroll0": scroll0, "a0": a0, "banner": props_banner}


GUILD = [
    ("prop_bookshelf", -310, 0), ("prop_bookshelf", -252, 0), ("prop_desk", -150, 0),
    ("prop_rug", 40, 0), ("prop_fireplace", 200, 0), ("prop_bed", 326, 0),
]



def write_tscn(info):
    w = Writer()
    w.ext_id("script")
    inst, raw = w.inst, w.raw

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

    kit.emit_props(w)
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
    kit.emit_geometry(w)
    kit.emit_enemies(w)
    eng = [e for e in enemies if e["kind"] == "engineer"][0]
    dz = [e for e in enemies if e["kind"] == "dozer"][0]
    inst("Engineer", ".", "engineer", position=vec(eng["x"], eng["y"] - 2), max_health="16")
    inst("Dozer", ".", "dozer", position=vec(dz["x"], dz["y"]))
    inst("Player", ".", "player", position=vec(80, 302))

    for d in doors:
        dp = {"position": vec(d["x"], d["y"]), "locked": "true" if d["locked"] else "false"}
        if d.get("range"):
            dp["auto_open_range"] = "%d.0" % d["range"]
        if d["text"]:
            dp["locked_text"] = qstr(d["text"])
        if d.get("close_behind"):
            dp["close_behind"] = "true"
            dp["sealed_text"] = qstr(d["sealed"])
        inst(d["name"], "Doors", "door", **dp)

    gx = info["gx"]
    raw("Guildhall", "Node2D", ".", ["position = %s" % vec(gx, 912)])
    for i, (k, x, y) in enumerate(GUILD):
        inst("G%d_%s" % (i, k.replace("prop_", "")), "Guildhall", k, position=vec(x, y), z_index="-2")
    inst("Mordecai", "Guildhall", "mordecai", position=vec(-100, 0))
    raw("ExitZone", "Area2D", "Guildhall", ["position = Vector2(-398, -50)", "collision_layer = 0",
                                           "collision_mask = 2"])
    raw("CollisionShape2D", "CollisionShape2D", "Guildhall/ExitZone", ['shape = SubResource("%s")' % w.shape(24, 100)])
    raw("SafeZone", "Area2D", "Guildhall", ["position = Vector2(0, -60)", "collision_layer = 0",
                                           "collision_mask = 2"])
    raw("CollisionShape2D", "CollisionShape2D", "Guildhall/SafeZone", ['shape = SubResource("%s")' % w.shape(880, 140)])
    raw("LootBoxes", "Node2D", "Guildhall", [])
    inst("LootBoxBronze", "Guildhall/LootBoxes", "lootbox", position=vec(20, 0))
    inst("LootBoxLegendary", "Guildhall/LootBoxes", "lootbox", position=vec(80, 0), tier=qstr("Legendary"), slot="1")

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
    kit.emit_section_triggers(w)

    text = w.render(RES, "res://scripts/levels/level00.gd", "uid://dsypb287qo2hi")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write(text)
    return text, w


def lint(text, w, info):
    return kit.lint(text, RES, EXISTING)



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