"""Writes scenes/level/fastfood_room.tscn (#59): the SafeRoom kit dressed as a Polish fast-food restaurant.
Coordinates are room-local (origin = floor at the room centre, entry door on the right at +320).
Run: python3 art-src/floor1/make_fastfood_room.py
"""
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller"))
WIDTH = 640

# name, prop key, x, y, flip, z
DECOR = [
    ("Soda", "ff_soda", 272, 0, False, -1),
    ("Counter", "ff_counter", 196, 0, False, -1),
    ("Menu", "ff_menu", 196, -74, False, -2),
    ("Booth1", "ff_booth", 6, 0, False, -1),
    ("Booth2", "ff_booth", -34, 0, True, -1),
    ("Slide", "ff_slide", -80, 0, False, -1),
    ("Tower", "ff_playtower", -125, 0, False, -1),
    ("BallPit", "ff_ballpit", -190, 0, False, 1),
    ("Cubicle1", "ff_cubicle", -258, 0, False, -1),
    ("Cubicle2", "ff_cubicle", -306, 0, False, -1),
]
# name, x (left edge), y, w, h
PLAY_PLATFORMS = [("PlayDeck", -145, -72, 40, 6), ("PlayStep", -178, -38, 28, 6)]


def build():
    props = sorted({d[1] for d in DECOR})
    ids = {}
    out = ['[gd_scene load_steps=%d format=3]\n' % (7 + len(props))]
    base = [("Script", "res://scripts/level/safe_room.gd", "room"), ("PackedScene", "res://scenes/props/gate_door.tscn", "door"),
            ("PackedScene", "res://scenes/level/checkpoint.tscn", "cp"), ("PackedScene", "res://scenes/props/tally.tscn", "tally"),
            ("PackedScene", "res://scenes/level/platform.tscn", "plat")]
    for typ, path, key in base:
        ids[key] = "%s_%s" % (len(ids) + 1, key)
        out.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, path, ids[key]))
    for p in props:
        ids[p] = "%s_%s" % (len(ids) + 1, p)
        out.append('[ext_resource type="PackedScene" path="res://scenes/props/%s.tscn" id="%s"]' % (p, ids[p]))
    out[0] = '[gd_scene load_steps=%d format=3]\n' % (len(ids) + 1)
    out.append('')
    out.append('[node name="FastFoodRoom" type="Node2D"]\nscript = ExtResource("%s")\nwidth = %d.0\ncheckpoint_index = 2\nhall_depth = 56.0\n'
               'box_tiers = PackedStringArray("Bronze", "Silver")\nbox_kit = "floor1_room"\n' % (ids["room"], WIDTH))
    for n, p in (("Zone", "."), ("HallEntry", "."), ("HallExit", ".")):
        out.append('[node name="%s" type="Area2D" parent="%s"]\n' % (n, p))
        out.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="%s"]\n' % n)
    out.append('[node name="PropSlots" type="Node2D" parent="."]\n')
    for n, x, y in (("Back", 0, -40), ("Left", -150, 0), ("Mid", -40, 0), ("Right", 150, 0)):
        out.append('[node name="%s" type="Marker2D" parent="PropSlots"]\nposition = Vector2(%d, %d)\n' % (n, x, y))
    out.append('[node name="Dressing" type="Node2D" parent="."]\n')
    for n, key, x, y, flip, z in DECOR:
        line = '[node name="%s" parent="Dressing" instance=ExtResource("%s")]\nposition = Vector2(%d, %d)\nz_index = %d\n' % (n, ids[key], x, y, z)
        if flip:
            line += 'scale = Vector2(-1, 1)\n'
        out.append(line)
    for n, x, y, w, h in PLAY_PLATFORMS:
        out.append('[node name="%s" parent="." instance=ExtResource("%s")]\nposition = Vector2(%d, %d)\nsize = Vector2(%d, %d)\nstyle = 3\none_way = true\n'
                   % (n, ids["plat"], x, y, w, h))
    out.append('[node name="Checkpoint" parent="." instance=ExtResource("%s")]\nposition = Vector2(48, 0)\n' % ids["cp"])
    out.append('[node name="Caretaker" parent="." instance=ExtResource("%s")]\nposition = Vector2(104, 0)\n' % ids["tally"])
    out.append('[node name="BoxSpot" type="Marker2D" parent="."]\nposition = Vector2(20, -20)\n')
    out.append('[node name="EntryDoor" parent="." instance=ExtResource("%s")]\n' % ids["door"])
    out.append('[node name="ExitDoor" parent="." instance=ExtResource("%s")]\n' % ids["door"])
    return "\n".join(out)


if __name__ == "__main__":
    with open(os.path.join(ROOT, "scenes", "level", "fastfood_room.tscn"), "w") as f:
        f.write(build())
    print("wrote fastfood_room.tscn")
