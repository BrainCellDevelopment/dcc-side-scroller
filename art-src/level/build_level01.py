#!/usr/bin/env python3
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = ROOT + "/dcc-side-scroller/scenes/level01.tscn"

WIDTH = 3200
FLOOR = 304
START_X = 3110
DOOR_X = 3160
STONE = 2

RES = [
    ("script", "Script", "res://scripts/levels/level01.gd"),
    ("background", "PackedScene", "res://scenes/level/background.tscn"),
    ("platform", "PackedScene", "res://scenes/level/platform.tscn"),
    ("goblin", "PackedScene", "res://scenes/enemies/goblin.tscn"),
    ("door", "PackedScene", "res://scenes/props/door.tscn"),
    ("torch", "PackedScene", "res://scenes/props/torch.tscn"),
    ("crate", "PackedScene", "res://scenes/props/crate.tscn"),
    ("player", "PackedScene", "res://scenes/player/player.tscn"),
    ("hud", "PackedScene", "res://scenes/ui/hud.tscn"),
]
PLATFORMS = [
    (0, FLOOR, WIDTH, 64, STONE),
    (2500, FLOOR - 40, 160, 16, STONE),
    (2200, FLOOR - 72, 140, 16, STONE),
    (1750, FLOOR - 40, 200, 16, STONE),
    (1350, FLOOR - 72, 160, 16, STONE),
    (900, FLOOR - 40, 180, 16, STONE),
    (520, FLOOR - 72, 150, 16, STONE),
]
GOBLINS = [2700, 2350, 1900, 1500, 1100, 700, 400]
TORCHES = list(range(3000, 100, -240))
CRATES = [2900, 2000, 1250, 600]

lines = []


def res(key):
    return 'ExtResource("%d_%s")' % ([r[0] for r in RES].index(key) + 1, key)


def node(name, parent=None, ntype=None, inst=None, **props):
    head = '[node name="%s"' % name
    if ntype:
        head += ' type="%s"' % ntype
    if parent:
        head += ' parent="%s"' % parent
    if inst:
        head += ' instance=%s' % res(inst)
    lines.append(head + "]")
    for k, v in props.items():
        lines.append("%s = %s" % (k, v))
    lines.append("")


def vec(x, y):
    return "Vector2(%s, %s)" % (x, y)


def body(name, x, y, shape_id):
    node(name, "Walls", "StaticBody2D", position=vec(x, y), collision_layer=1, collision_mask=0)
    node("CollisionShape2D", "Walls/" + name, "CollisionShape2D", shape='SubResource("%s")' % shape_id)


def area(name, x, y, shape_id, mask=2):
    node(name, "Triggers", "Area2D", position=vec(x, y), collision_layer=0, collision_mask=mask)
    node("CollisionShape2D", "Triggers/" + name, "CollisionShape2D", shape='SubResource("%s")' % shape_id)


node("Level01", None, "Node2D", script=res("script"))
node("Background", ".", None, "background", initial_style=2)
node("Deco", ".", "Node2D")
node("Platforms", ".", "Node2D")
node("Walls", ".", "Node2D")
node("Triggers", ".", "Node2D")
node("Doors", ".", "Node2D")
node("Goblins", ".", "Node2D")

for i, x in enumerate(TORCHES):
    node("T%02d" % i, "Deco", None, "torch", position=vec(x, FLOOR - 110))
for i, x in enumerate(CRATES):
    node("C%02d" % i, "Deco", None, "crate", position=vec(x, FLOOR))
for i, (x, y, w, h, s) in enumerate(PLATFORMS):
    node("P%03d" % i, "Platforms", None, "platform", position=vec(x, y), size=vec(w, h), style=s)
for i, x in enumerate(GOBLINS):
    node("G%02d" % i, "Goblins", None, "goblin", position=vec(x, FLOOR - 2))
node("EntryDoor", "Doors", None, "door", position=vec(DOOR_X, FLOOR), start_open="true",
     close_behind="true", close_side="-1.0", sealed_text='"Locked. No way back."')
body("LeftBound", -8, 54, "shape_wall")
body("RightBound", WIDTH + 8, 54, "shape_wall")
area("EndZone", 90, FLOOR - 50, "shape_end")
node("Player", ".", None, "player", position=vec(START_X, FLOOR - 2))
node("Camera2D", ".", "Camera2D", position=vec(START_X, 184), limit_left=0, limit_top=-116, limit_right=WIDTH, limit_bottom=364,
     limit_smoothed="true", position_smoothing_enabled="true", position_smoothing_speed=6.0)
node("HUD", ".", None, "hud")

head = ['[gd_scene load_steps=%d format=3]' % (len(RES) + 3), ""]
for i, (key, typ, path) in enumerate(RES):
    head.append('[ext_resource type="%s" path="%s" id="%d_%s"]' % (typ, path, i + 1, key))
head += ["",
         '[sub_resource type="RectangleShape2D" id="shape_wall"]', "size = Vector2(16, 720)", "",
         '[sub_resource type="RectangleShape2D" id="shape_end"]', "size = Vector2(40, 140)", ""]
with open(OUT, "w") as f:
    f.write("\n".join(head + lines))
print("wrote", OUT, len(PLATFORMS), "platforms", len(GOBLINS), "goblins")
