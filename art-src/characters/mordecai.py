import math
import os
from pxl import Canvas, sheet, preview, count_colors, tf

OUTDIR = os.environ.get("DCC_ASSETS", "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/characters")
PV = os.environ.get("DCC_PREVIEW", os.path.join(os.path.dirname(os.path.abspath(__file__)), "_pv"))
FW, FH = 32, 40

FUR = ("#d9cfc6", "#b8aaa2", "#8f7f7c", "#62535e")
PINK = ("#ffd6d6", "#f4a3ae", "#d7788c", "#a05070")
ROBE = ("#a46ac8", "#8450aa", "#613a86", "#42265f")
GOLD = ("#fff2a8", "#ffd23f", "#e0a01c", "#a8681c")
WOOD = ("#d49a62", "#a8683c", "#774430")
EYE = "#1b1226"
WHITE = "#ffffff"
WHISK = "#efe8e2"
MOUTH = "#6a2a40"


def bez(p, t):
    a = (1 - t) ** 3
    b = 3 * (1 - t) ** 2 * t
    c = 3 * (1 - t) * t * t
    d = t ** 3
    return (a * p[0][0] + b * p[1][0] + c * p[2][0] + d * p[3][0], a * p[0][1] + b * p[1][1] + c * p[2][1] + d * p[3][1])


def frame(bob=0, tail=0, blink=False, mouth=0, whisk=0, hand=0, ear=0):
    c = Canvas(FW, FH)
    by = bob
    tp = [(7, 35), (2, 37 + tail * 0.4), (1 + tail, 30), (3 + tail, 26 - abs(tail))]
    tm = c.capsule(bez(tp, 0), bez(tp, 0.2), 1.3, 1.2)
    for i in range(1, 12):
        tm |= c.capsule(bez(tp, (i - 1) / 12 * 1.0 + 0.0), bez(tp, i / 12), 1.3 - i * 0.05, 1.3 - (i + 1) * 0.05)
    c.stamp(tm, PINK)

    staff = c.box(25, 14, 27, 39)
    c.stamp(staff, WOOD)
    c.stamp(c.disc(26, 13, 2.2), GOLD)

    for fx in (9, 18):
        foot = c.ell(fx + 1, 38.2, 3.4, 1.8)
        c.stamp(foot, PINK)

    body = c.poly([(10, 15 + by), (15, 14 + by), (20, 17 + by), (21, 26), (24, 38), (6, 38), (8, 28), (8, 20 + by)])
    body |= c.ell(11, 18 + by, 4.5, 4.5)
    c.stamp(body, ROBE)
    hem = c.box(5, 36, 26, 39) & body
    c.fill(hem, GOLD[2])
    c.fill(c.box(5, 36, 26, 37) & body, GOLD[1])
    front = c.box(20, 22, 22, 38) & body
    c.fill(front, GOLD[2])
    belt = c.box(8, 27, 22, 29) & body
    c.fill(belt, GOLD[2])
    c.fill(c.box(8, 27, 22, 28) & body, GOLD[1])
    c.dot(19, 27, GOLD[0]); c.dot(19, 28, GOLD[0])
    c.fill(c.box(12, 21 + by, 14, 24 + by) & body, ROBE[3]) if False else None
    for y in range(22, 36, 3):
        c.dot(14, y, ROBE[3]); c.dot(15, y + 1, ROBE[3])

    hx, hy = 18, 12 + by * 1.0
    far_ear = c.disc(hx - 4.2, hy - 5.2 - ear, 3.0)
    c.stamp(far_ear, FUR)
    c.fill(c.disc(hx - 4.2, hy - 5.0 - ear, 1.6) & far_ear, PINK[2])
    head = c.ell(hx, hy, 5.4, 4.8)
    snout = c.poly([(hx + 2, hy - 2.6), (hx + 8.6, hy + 1.4), (hx + 8.6, hy + 3.2), (hx + 2, hy + 4.4)])
    snout |= c.disc(hx + 8.8, hy + 2.2, 1.6)
    m = head | snout
    c.stamp(m, FUR)
    c.fill(c.poly([(hx + 3, hy + 1.6), (hx + 9, hy + 2.6), (hx + 9, hy + 3.6), (hx + 3, hy + 4.2)]) & m, FUR[0])
    c.fill(c.disc(hx + 9.6, hy + 2.2, 1.5), PINK[2])
    c.dot(hx + 9, hy + 1.4, PINK[0])
    near_ear = c.disc(hx - 0.6, hy - 6.0 - ear, 3.5)
    c.stamp(near_ear, FUR)
    c.fill(c.disc(hx - 0.6, hy - 5.8 - ear, 2.0) & near_ear, PINK[1])
    c.fill(c.disc(hx - 0.2, hy - 5.4 - ear, 1.0) & near_ear, PINK[2])
    if mouth:
        c.fill(c.box(int(hx + 4), int(hy + 4), int(hx + 9), int(hy + 4 + mouth)), MOUTH)
        c.dot(hx + 8, hy + 4, WHITE); c.dot(hx + 8, hy + 5, WHITE) if mouth > 1 else None
        if mouth > 1:
            c.dot(hx + 6, hy + 5, PINK[2])
    else:
        c.dot(hx + 7.4, hy + 4.4, WHITE); c.dot(hx + 7.4, hy + 5.4, WHITE)
        c.fill(c.box(int(hx + 3), int(hy + 4), int(hx + 8), int(hy + 5)), FUR[3])
    if blink:
        c.fill(c.box(int(hx + 3), int(hy - 0.5), int(hx + 6), int(hy + 0.5)), EYE)
    else:
        c.fill(c.box(int(hx + 3), int(hy - 1.5), int(hx + 6), int(hy + 1.5)), EYE)
        c.dot(hx + 3.5, hy - 1, WHITE)
    c.fill(c.box(int(hx + 2), int(hy - 3.2), int(hx + 7), int(hy - 2.2)), FUR[3])
    c.dot(hx + 7, hy - 2.5, FUR[3])
    w = whisk
    for k, (dy, dd) in enumerate(((1, -3), (3, 0), (5, 3))):
        x0, y0 = hx + 8.5, hy + 3 + (k - 1) * 0.8
        for i in range(1, 7):
            c.dot(x0 + i, y0 + dd * i / 6.0 + w * (1 if k != 1 else -1) * i / 8.0, WHISK)

    arm = [(16, 20 + by), (23, 26 - hand * 2)] if hand else [(16, 20 + by), (21, 27)]
    sl = c.capsule(arm[0], arm[1], 2.4, 2.2)
    c.stamp(sl, ROBE)
    c.fill(c.disc(arm[1][0] - 0.6, arm[1][1] - 0.4, 1.8) & sl & ~c.disc(arm[1][0], arm[1][1], 1.0), ROBE[3]) if False else None
    c.fill(c.disc(arm[0][0] + (arm[1][0] - arm[0][0]) * 0.85, arm[0][1] + (arm[1][1] - arm[0][1]) * 0.85, 1.4) & sl, GOLD[2])
    hd = c.disc(arm[1][0] + 1, arm[1][1], 1.9)
    c.stamp(hd, PINK)
    c.dot(arm[1][0] + 2.5, arm[1][1] - 0.5, PINK[3])
    c.dot(arm[1][0] + 2.5, arm[1][1] + 0.5, PINK[3])
    return c


def idle():
    return [
        frame(bob=0, tail=0, whisk=0),
        frame(bob=0.0, tail=1, whisk=1, ear=0),
        frame(bob=1, tail=2, blink=True, whisk=0),
        frame(bob=1, tail=1, whisk=-1),
    ]


def talk():
    return [
        frame(bob=0, tail=0, mouth=2, hand=1, whisk=1),
        frame(bob=0, tail=1, mouth=1, hand=2, whisk=-1),
        frame(bob=1, tail=2, mouth=2, hand=1, whisk=1, ear=1),
        frame(bob=0, tail=1, mouth=0, hand=0, whisk=-1),
    ]


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    os.makedirs(PV, exist_ok=True)
    s = sheet([idle(), talk()], FW, FH, 4)
    s.save(os.path.join(OUTDIR, "mordecai.png"))
    preview(s, os.path.join(PV, "mordecai.png"), 8, fw=FW, fh=FH)
    print(s.size, count_colors(s))
