"""Safe room #1 dressing (#59): a Polish-style fast-food restaurant, blue and white, with a play structure.

Static decor sheets to dcc-side-scroller/assets/props/ff_*.png plus their scenes in scenes/props/.
Run: python3 art-src/floor1/gen_props_fastfood.py   (needs pillow and numpy)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "props"))
import pxlib  # noqa: E402
from pxlib import Cv, rect, ell, poly, line, paint, flat, speckle, exterior_outline, save, R, WOOD, BRASS, CHAR  # noqa: E402

pxlib.OL = (12, 10, 24)
BLUE = R("#101a40", "#1f3a78", "#2f5cb0", "#5e92dc", "#a6c8f4")
WHITE = R("#4a5070", "#8f98b8", "#c8d0e4", "#eef2fa", "#ffffff")
RED = R("#401018", "#7a1e2c", "#b83a40", "#e06a58", "#f8a090")
YEL = R("#5a3a10", "#a8741c", "#e0a830", "#f8d860", "#fff4a8")
GRN = R("#10382a", "#1c6a48", "#38a860", "#78d880", "#c0f4b0")
STEEL = R("#2a2c40", "#4a5068", "#7c849c", "#b0b8cc", "#e4e8f4")

PROPS = {}


def prop(name, w, h, origin="bottom"):
    def deco(fn):
        PROPS[name] = (fn, w, h, origin)
        return fn
    return deco


@prop("ff_counter", 96, 40)
def counter():
    cv = Cv(96, 40)
    paint(cv, rect(cv, 1, 14, 94, 38), BLUE, hl=1, sd=2)
    for x in range(5, 92, 10):
        flat(cv, rect(cv, x, 18, x + 4, 34), BLUE[1])
        flat(cv, rect(cv, x, 18, x + 4, 19), BLUE[3])
    paint(cv, rect(cv, 0, 10, 95, 15), WHITE, hl=1, sd=1)
    paint(cv, rect(cv, 6, 1, 28, 10), STEEL, hl=1, sd=1)
    paint(cv, rect(cv, 9, 3, 25, 8), BLUE, hl=1, sd=1)
    flat(cv, rect(cv, 12, 5, 22, 5), WHITE[3])
    paint(cv, rect(cv, 48, 4, 58, 10), RED, hl=1, sd=1)
    paint(cv, rect(cv, 66, 6, 88, 10), YEL, hl=1, sd=1)
    for x in (70, 76, 82):
        flat(cv, rect(cv, x, 7, x + 1, 9), YEL[1])
    exterior_outline(cv)
    return cv


@prop("ff_booth", 44, 34)
def booth():
    cv = Cv(44, 34)
    paint(cv, rect(cv, 1, 4, 8, 28), BLUE, hl=1, sd=1)
    paint(cv, rect(cv, 35, 4, 42, 28), BLUE, hl=1, sd=1)
    paint(cv, rect(cv, 6, 20, 37, 28), WHITE, hl=1, sd=1)
    paint(cv, rect(cv, 4, 29, 39, 33), BLUE, hl=1, sd=1)
    paint(cv, rect(cv, 12, 14, 31, 17), WOOD, hl=1, sd=1)
    paint(cv, rect(cv, 20, 17, 23, 21), STEEL, hl=1, sd=1)
    paint(cv, rect(cv, 15, 10, 19, 13), RED, hl=1, sd=1)
    paint(cv, ell(cv, 24, 11, 29, 13), YEL, hl=1, sd=1)
    exterior_outline(cv)
    return cv


@prop("ff_slide", 72, 64)
def slide():
    cv = Cv(72, 64)
    paint(cv, rect(cv, 4, 4, 10, 63), YEL, hl=1, sd=1)
    paint(cv, rect(cv, 0, 2, 22, 7), RED, hl=1, sd=1)
    for y in range(14, 60, 8):
        flat(cv, rect(cv, 5, y, 9, y + 1), YEL[1])
    paint(cv, poly(cv, [(20, 8), (24, 8), (68, 58), (68, 63), (62, 63), (20, 14)]), BLUE, hl=1, sd=1)
    paint(cv, poly(cv, [(22, 10), (24, 10), (64, 58), (62, 59)]), WHITE, hl=0, sd=0, ol=False)
    paint(cv, rect(cv, 11, 8, 13, 63), RED, hl=1, sd=1)
    exterior_outline(cv)
    return cv


@prop("ff_ballpit", 72, 24)
def ballpit():
    cv = Cv(72, 24)
    paint(cv, rect(cv, 1, 8, 70, 22), BLUE, hl=1, sd=2)
    paint(cv, rect(cv, 0, 6, 71, 9), WHITE, hl=1, sd=1)
    cols = (RED, YEL, GRN, BLUE, WHITE)
    for i, (x, y) in enumerate([(6, 6), (14, 3), (22, 6), (30, 2), (38, 5), (46, 3), (54, 6), (62, 3), (10, 9), (26, 9), (42, 9), (58, 9), (66, 8)]):
        paint(cv, ell(cv, x - 4, y - 3, x + 4, y + 5), cols[i % 5], hl=1, sd=1)
    exterior_outline(cv)
    return cv


@prop("ff_soda", 28, 52)
def soda():
    cv = Cv(28, 52)
    paint(cv, rect(cv, 1, 1, 26, 50), RED, hl=1, sd=2)
    paint(cv, rect(cv, 4, 4, 23, 14), WHITE, hl=1, sd=1)
    flat(cv, ell(cv, 9, 5, 18, 13), RED[2])
    flat(cv, ell(cv, 12, 8, 15, 11), WHITE[3])
    for i, c in enumerate((BLUE, GRN, YEL, WHITE, STEEL)):
        paint(cv, rect(cv, 5, 17 + i * 5, 12, 20 + i * 5), c, hl=1, sd=1)
        flat(cv, rect(cv, 15, 18 + i * 5, 22, 18 + i * 5), STEEL[3])
    paint(cv, rect(cv, 6, 42, 21, 48), CHAR, hl=1, sd=1)
    flat(cv, rect(cv, 8, 44, 19, 44), STEEL[2])
    exterior_outline(cv)
    return cv


@prop("ff_cubicle", 48, 56)
def cubicle():
    cv = Cv(48, 56)
    paint(cv, rect(cv, 1, 2, 46, 54), WHITE, hl=1, sd=2)
    paint(cv, rect(cv, 1, 2, 46, 7), BLUE, hl=1, sd=1)
    paint(cv, rect(cv, 6, 24, 41, 52), BLUE, hl=1, sd=2)
    paint(cv, rect(cv, 8, 38, 39, 46), WHITE, hl=1, sd=1)
    paint(cv, rect(cv, 8, 34, 18, 39), WHITE, hl=1, sd=1)
    flat(cv, rect(cv, 20, 40, 39, 46), BLUE[3])
    paint(cv, rect(cv, 18, 10, 29, 17), YEL, hl=1, sd=1)
    flat(cv, rect(cv, 22, 12, 25, 14), YEL[4])
    exterior_outline(cv)
    return cv


@prop("ff_menu", 56, 24, "center")
def menu():
    cv = Cv(56, 24)
    paint(cv, rect(cv, 1, 1, 54, 22), BLUE, hl=1, sd=1)
    for i in range(3):
        y = 4 + i * 6
        flat(cv, rect(cv, 5, y, 30 - i * 3, y + 1), WHITE[3])
        flat(cv, rect(cv, 40, y, 50, y + 1), YEL[3])
    exterior_outline(cv)
    return cv


@prop("ff_playtower", 40, 80)
def playtower():
    cv = Cv(40, 80)
    for x in (3, 32):
        paint(cv, rect(cv, x, 6, x + 4, 79), RED, hl=1, sd=1)
    paint(cv, rect(cv, 0, 0, 39, 5), BLUE, hl=1, sd=1)
    paint(cv, rect(cv, 4, 40, 35, 46), YEL, hl=1, sd=1)
    for y in (14, 24, 34):
        flat(cv, rect(cv, 8, y, 31, y + 1), WHITE[2])
    paint(cv, rect(cv, 4, 60, 35, 64), GRN, hl=1, sd=1)
    exterior_outline(cv)
    return cv


def scene(name, node, w, h, origin):
    off = (-w / 2.0, -h / 2.0) if origin == "center" else (-w / 2.0, -float(h))
    return ('[gd_scene load_steps=2 format=3]\n\n'
            '[ext_resource type="Texture2D" path="res://assets/props/%s.png" id="1_tex"]\n\n'
            '[node name="%s" type="Node2D"]\n\n'
            '[node name="Sprite" type="Sprite2D" parent="."]\ntexture = ExtResource("1_tex")\ncentered = false\n'
            'offset = Vector2(%s, %s)\n' % (name, node, off[0], off[1]))


if __name__ == "__main__":
    root = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller"))
    for name, (fn, w, h, origin) in PROPS.items():
        cv = fn()
        assert (cv.w, cv.h) == (w, h), name
        save(cv.a, "props/%s.png" % name)
        node = "".join(p.capitalize() for p in name.split("_"))
        with open(os.path.join(root, "scenes", "props", name + ".tscn"), "w") as f:
            f.write(scene(name, node, w, h, origin))
    print("wrote", len(PROPS), "props")
