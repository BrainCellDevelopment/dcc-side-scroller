"""Floor 1 vermin sheets: rat and Scatterer (#58). Original art, drawn procedurally with PIL.

Frames are 32x32, feet on the bottom row, creature faces right (the Visual node flips it).
rat.png rows:       idle(2) walk(4) windup(2) attack(2) die(4)
scatterer.png rows: idle(2) walk(4) die(3)
Run: python3 art-src/characters/vermin.py
"""
import os

from PIL import Image, ImageDraw

OUT = "#1b1226"
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "characters"))

FUR = (122, 104, 98, 255)
FUR_D = (78, 64, 64, 255)
FUR_L = (172, 154, 142, 255)
PINK = (228, 146, 156, 255)
RED = (255, 72, 60, 255)
WHITE = (255, 250, 240, 255)
LIQ = (124, 176, 178, 255)
LIQ_L = (190, 226, 224, 255)
CRUST = (190, 128, 62, 255)
CRUST_L = (232, 184, 106, 255)
CRUST_D = (122, 76, 36, 255)
ROACH = (84, 48, 28, 255)
GOO = (226, 214, 150, 255)


def outline(img):
    px = img.load()
    w, h = img.size
    mark = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != (0, 0, 0, 0):
                        mark.append((x, y))
                        break
    col = tuple(int(OUT[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
    for x, y in mark:
        px[x, y] = col


def ell(d, box, fill):
    d.ellipse(box, fill=fill)


def rat(kind, i):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bob = 0
    lx = 0
    legs = (0, 0, 0, 0)
    mouth = False
    if kind == "idle":
        bob = (0, 1)[i]
    elif kind == "walk":
        bob = (0, -1, 0, -1)[i]
        legs = ((-2, 2, 2, -2), (0, 0, 0, 0), (2, -2, -2, 2), (0, 0, 0, 0))[i]
    elif kind == "windup":
        lx = (-2, -3)[i]
        bob = (1, 2)[i]
        mouth = i == 1
    elif kind == "attack":
        lx = (0, 1)[i]
        mouth = True
    if kind == "die":
        return rat_die(i)
    gy = 30
    ox = lx
    # tail
    tail = [(7 + ox, 26 + bob), (4 + ox, 27 + bob), (2 + ox, 25 + bob), (1 + ox, 22 + bob)]
    d.line(tail, fill=PINK, width=1)
    # back legs
    d.line([(10 + ox + legs[0], 27 + bob), (10 + ox + legs[0], gy)], fill=FUR_D, width=2)
    d.line([(15 + ox + legs[1], 27 + bob), (15 + ox + legs[1], gy)], fill=FUR_D, width=2)
    # body
    ell(d, (6 + ox, 19 + bob, 23 + ox, 29 + bob), FUR)
    ell(d, (8 + ox, 24 + bob, 21 + ox, 29 + bob), FUR_L)
    ell(d, (7 + ox, 19 + bob, 18 + ox, 23 + bob), FUR_D)
    # front legs
    d.line([(19 + ox + legs[2], 27 + bob), (19 + ox + legs[2], gy)], fill=FUR, width=2)
    d.line([(22 + ox + legs[3], 27 + bob), (22 + ox + legs[3], gy)], fill=FUR, width=2)
    d.point([(19 + ox + legs[2], gy), (22 + ox + legs[3], gy)], fill=PINK)
    # head and snout
    ell(d, (19 + ox, 18 + bob, 27 + ox, 27 + bob), FUR)
    d.polygon([(25 + ox, 20 + bob), (31 + ox, 25 + bob), (25 + ox, 27 + bob)], fill=FUR)
    # ear
    ell(d, (19 + ox, 14 + bob, 24 + ox, 20 + bob), FUR_D)
    ell(d, (20 + ox, 15 + bob, 23 + ox, 19 + bob), PINK)
    # eye, nose, whiskers, teeth
    d.point([(24 + ox, 21 + bob), (25 + ox, 21 + bob)], fill=RED)
    d.point([(31 + ox, 25 + bob), (30 + ox, 25 + bob)], fill=PINK)
    d.line([(28 + ox, 24 + bob), (31 + ox, 22 + bob)], fill=FUR_L, width=1)
    if mouth:
        d.polygon([(25 + ox, 26 + bob), (30 + ox, 26 + bob), (27 + ox, 29 + bob)], fill=(60, 20, 34, 255))
        d.point([(26 + ox, 26 + bob), (29 + ox, 26 + bob)], fill=WHITE)
    else:
        d.point([(27 + ox, 27 + bob)], fill=WHITE)
    outline(img)
    return img


def rat_die(i):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if i == 0:
        # swelling like a water balloon
        ell(d, (4, 9, 28, 31), LIQ)
        ell(d, (7, 12, 16, 19), LIQ_L)
        d.polygon([(25, 14), (30, 18), (25, 20)], fill=FUR)
        d.point([(23, 16), (24, 16)], fill=RED)
        d.line([(5, 24), (1, 24), (0, 21)], fill=PINK, width=1)
    elif i == 1:
        # pop: droplets in every direction
        for (x, y, r) in [(16, 20, 4), (8, 14, 2), (24, 12, 2), (4, 24, 2), (28, 24, 2), (14, 8, 2), (20, 6, 1), (2, 16, 1), (30, 17, 1)]:
            ell(d, (x - r, y - r, x + r, y + r), LIQ)
        d.point([(16, 19), (8, 13), (24, 11)], fill=LIQ_L)
        d.polygon([(13, 24), (19, 24), (16, 28)], fill=FUR)
        d.line([(10, 22), (7, 19)], fill=PINK, width=1)
    elif i == 2:
        ell(d, (3, 25, 29, 31), LIQ)
        for (x, y) in [(6, 20), (25, 19), (15, 16), (11, 22), (21, 22)]:
            d.point([(x, y), (x, y + 1)], fill=LIQ)
        d.polygon([(14, 25), (19, 25), (17, 28)], fill=FUR)
        d.point([(9, 27), (22, 27)], fill=LIQ_L)
    else:
        ell(d, (2, 27, 30, 31), (160, 200, 200, 190))
        d.point([(9, 29), (20, 29)], fill=LIQ_L)
    outline(img)
    return img


def scatterer(kind, i):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "die":
        if i == 0:
            ell(d, (3, 22, 29, 31), CRUST)
            ell(d, (6, 22, 25, 27), CRUST_L)
            d.line([(5, 26), (9, 22)], fill=ROACH, width=1)
            d.line([(24, 22), (28, 26)], fill=ROACH, width=1)
        elif i == 1:
            ell(d, (1, 26, 31, 31), GOO)
            ell(d, (6, 25, 23, 30), CRUST)
            d.line([(4, 27), (1, 24)], fill=ROACH, width=1)
            d.line([(27, 27), (30, 24)], fill=ROACH, width=1)
        else:
            ell(d, (0, 28, 32, 32), (226, 214, 150, 170))
            d.line([(8, 29), (14, 29)], fill=CRUST_D, width=1)
            d.line([(18, 29), (24, 29)], fill=CRUST_D, width=1)
        outline(img)
        return img
    bob = 0
    legs = (0, 0, 0)
    feel = 0
    if kind == "idle":
        feel = (0, 1)[i]
        bob = (0, 0)[i]
    else:
        bob = (0, -1, 0, -1)[i]
        legs = ((-2, 2, -2), (0, 0, 0), (2, -2, 2), (0, 0, 0))[i]
        feel = (0, 1, 0, 1)[i]
    # legs (three pairs, tripod gait)
    for n, bx in enumerate((10, 15, 20)):
        d.line([(bx + legs[n], 27 + bob), (bx + legs[n] - 1, 30)], fill=ROACH, width=1)
        d.line([(bx + 2 + legs[n], 27 + bob), (bx + 3 + legs[n], 31)], fill=ROACH, width=1)
    # loaf body
    ell(d, (4, 15 + bob, 26, 28 + bob), CRUST)
    ell(d, (6, 15 + bob, 24, 23 + bob), CRUST_L)
    ell(d, (4, 24 + bob, 26, 28 + bob), CRUST_D)
    for sx in (9, 14, 19):
        d.line([(sx, 17 + bob), (sx + 2, 22 + bob)], fill=CRUST_D, width=1)
    # head
    ell(d, (24, 20 + bob, 30, 27 + bob), ROACH)
    d.point([(28, 22 + bob), (29, 22 + bob)], fill=WHITE)
    d.point([(29, 22 + bob)], fill=(20, 10, 10, 255))
    # antennae
    d.line([(28, 20 + bob), (30, 16 - feel), (31, 13 - feel)], fill=ROACH, width=1)
    d.line([(26, 20 + bob), (27, 16 + feel), (29, 12 + feel)], fill=ROACH, width=1)
    outline(img)
    return img


def sheet(rows, fn, name):
    w = 4 * 32
    h = len(rows) * 32
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for r, (kind, n) in enumerate(rows):
        for c in range(n):
            out.paste(fn(kind, c), (c * 32, r * 32))
    path = os.path.join(DEST, name)
    out.save(path)
    print("wrote", path, out.size)


if __name__ == "__main__":
    sheet([("idle", 2), ("walk", 4), ("windup", 2), ("attack", 2), ("die", 4)], rat, "rat.png")
    sheet([("idle", 2), ("walk", 4), ("die", 3)], scatterer, "scatterer.png")
