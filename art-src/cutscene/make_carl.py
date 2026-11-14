import math
import os
import numpy as np
from PIL import Image
from pxl import tf, sheet, preview, count_colors
import carl_rig as K

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
PV = os.path.join(HERE, "_preview")
FW, FH, COLS = 64, 56, 8
CIG = "#f4eee4"
EMBER = "#ff8a2a"
SMOKE = ("#c8c4d8", "#9a96b4")


def lst(**kw):
    return kw


def cig(c, p, ha, tip_dx, tip_dy):
    x, y = ha
    for i in range(4):
        t = i / 3.0
        c.dot(x + tip_dx * t, y + tip_dy * t, CIG)
    c.dot(x + tip_dx * 1.15, y + tip_dy * 1.15, EMBER)
    c.dot(x + tip_dx * 1.15, y + tip_dy * 1.15 - 1, "#ffd27a") if p.get("ember_up") else None


def smoke(c, x, y, n, drift=1.0):
    for i in range(n):
        c.dot(x + math.sin(i * 1.3) * drift + i * 0.3, y - i * 2.4, SMOKE[i % 2])
        if i % 2 == 0:
            c.dot(x + math.sin(i * 1.3) * drift + i * 0.3 + 1, y - i * 2.4, SMOKE[1])


SIT = dict(lean=-0.1, hip=(20.4, 40.6), eyes="squint", brow="tired", mouth="line", head_off=(1.6, 0.0),
           legs={"a": (11.0, 0, 1.55, 0.0), "b": (8.0, 0, 1.5, 0.0)}, fist=(2.6, 2.4), sway=-0.4)


def sit_a():
    p = dict(SIT, arms={"a": (4.5, 5.5), "b": (5.0, 3.0)}, bend=(1, 1))
    p["draw"] = lambda c, an: (cig(c, p, an["ha"], 2.0, -4.0), smoke(c, an["ha"][0] + 2.4, an["ha"][1] - 6, 5))
    return p


def sit_b():
    p = dict(SIT, arms={"a": (0, 0), "b": (5.0, 3.0)}, bend=(1, 1), lean=-0.14, breath=1.0)
    p["mouth"] = "line"
    p["mouth_hand"] = True
    p["draw"] = lambda c, an: (cig(c, p, an["ha"], 3.5, -1.0), smoke(c, an["ha"][0] + 4, an["ha"][1] - 3, 4))
    return p


def run_frames():
    L = 0.24
    steps = [
        (40.6, (8.0, 0.5, 1.02), (-8.0, 2.4, 1.05), (-5.0, 4.0), (6.4, 0.6)),
        (41.6, (3.0, 0, 1.25), (-7.0, 6.0, 1.3), (-3.6, 5.6), (4.6, 2.6)),
        (39.8, (-2.0, 0, 1.04), (3.0, 6.0, 1.5), (0.6, 6.4), (1.0, 5.0)),
    ]
    fr = []
    for near, far in (("a", "b"), ("b", "a")):
        for hy, down, up, back, fwd in steps:
            fr.append(lst(lean=L, hip=(23.6, hy), legs={near: down, far: up}, arms={far: back, near: fwd}))
    for f in fr:
        f.update(eyes="wide", brow="up", mouth="open", fist=(2.6, 2.5), head_off=(2.0, 0.0), sway=1.6)
    return fr


STAND = lst(lean=0.04, hip=(23.4, 41.4), eyes="open", brow="tired", mouth="line", sway=0.0,
            arms={"a": (1.6, 6.4), "b": (2.0, 6.0)}, legs={"a": (-4.0, 0, 1.03), "b": (4.0, 0, 1.06)}, fist=(2.6, 2.4),
            head_off=(1.4, 0.0), bend=(1, 1))
SHOCK = lst(lean=-0.02, hip=(23.4, 41.2), eyes="wide", brow="up", mouth="open", sway=-1.0, head_rot=-0.5,
            head_off=(0.4, 0.4), arms={"a": (5.0, 3.0), "b": (6.0, 2.0)}, legs={"a": (-5.0, 0, 1.04), "b": (5.0, 0, 1.06)},
            fist=(2.6, 2.4), bend=(1, 1))
STAGGER = lst(lean=-0.34, hip=(22.6, 40.8), legs={"a": (-7.0, 0, 1.04), "b": (4.0, 2.4, 1.3, 0.3)},
              arms={"a": (-4.0, 5.0), "b": (7.0, -2.0)}, eyes="squint", brow="hurt", mouth="open",
              fist=(2.7, 2.5), head_rot=-0.25, head_off=(1.0, 0.0), sway=-2.0, bend=(-1, 1))


def render(p):
    c, an = K.build_carl(p)
    if p.get("mouth_hand"):
        m = tf(an["H"][0], an["H"][1], an["ang"] + p.get("head_rot", 0.0), 5.2, 4.2)
        sh = an["S"]
        sa = (sh[0] - an["rt"][0] * 3.2 - an["u"][0] * 1.8, sh[1] - an["rt"][1] * 3.2 - an["u"][1] * 1.8)
        p2 = dict(p)
        p2["arms"] = dict(p["arms"], a=(m[0] - sa[0] - 1.5, m[1] - sa[1] + 0.5))
        p2["bend"] = (1, 1)
        c, an = K.build_carl(p2)
    if "draw" in p:
        p["draw"](c, an)
    return c


def build():
    rows = [[sit_a(), sit_b()], [STAND], run_frames(), [SHOCK], [STAGGER]]
    out = Image.new("RGBA", (FW * COLS, FH * len(rows)), (0, 0, 0, 0))
    for r, row in enumerate(rows):
        for i, p in enumerate(row):
            c = render(p)
            im = Image.fromarray(c.a, "RGBA").crop((0, 8, 64, 64))
            out.paste(im, (i * FW, r * FH))
    return out


if __name__ == "__main__":
    img = build()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PV, exist_ok=True)
    img.save(os.path.join(OUT, "cutscene_carl.png"))
    preview(img, os.path.join(PV, "carl.png"), 4, fw=FW, fh=FH)
    print(img.size, count_colors(img))
