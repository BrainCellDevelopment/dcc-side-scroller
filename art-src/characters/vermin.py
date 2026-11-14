"""Floor 1 vermin sheets: rat and Scatterer (#58). Original art, drawn procedurally with PIL.

Frames are 32x32, feet on the bottom row, creature faces right (the Visual node flips it).
rat.png rows:       idle(2) walk(4) windup(2) attack(2) die(4)
grub.png rows:      idle(2) walk(4) die(3)  (Floor 2 Brindle Grub)
dingo.png rows:     idle(2) walk(4) windup(2) attack(2) die(3)  (Floor 2 Danger Dingo)
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


CREAM = (234, 222, 178, 255)
CREAM_D = (196, 176, 126, 255)
CREAM_L = (252, 246, 214, 255)
GRUB_DK = (120, 96, 70, 255)
DOG = (156, 122, 84, 255)
DOG_D = (104, 78, 54, 255)
DOG_L = (196, 164, 118, 255)
PAINT = (246, 242, 232, 255)
INK = (24, 16, 22, 255)


def grub(kind, i):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "die":
        if i == 0:
            ell(d, (4, 20, 28, 31), CREAM)
            ell(d, (6, 20, 24, 26), CREAM_L)
            d.point([(23, 24), (25, 24)], fill=INK)
        elif i == 1:
            ell(d, (1, 26, 31, 31), GOO)
            ell(d, (5, 25, 27, 30), CREAM)
            for (x, y) in [(3, 22), (28, 21), (16, 19), (9, 18)]:
                d.point([(x, y), (x, y + 1)], fill=GOO)
        else:
            ell(d, (0, 28, 32, 32), (226, 214, 150, 170))
            d.line([(8, 29), (14, 29)], fill=CREAM_D, width=1)
        outline(img)
        return img
    hump = 0
    bob = 0
    if kind == "idle":
        bob = (0, 1)[i]
    else:
        hump = i
    # body: six fuzzy segments, a hump travelling tail to head while walking
    for n in range(6):
        cx = 6 + n * 4
        lift = 0
        if kind == "walk":
            lift = 3 if (n - hump) % 4 == 0 else (1 if (n - hump) % 4 == 1 else 0)
        top = 20 - lift + bob
        ell(d, (cx - 3, top, cx + 4, 30), CREAM if n % 2 == 0 else CREAM_D)
        d.point([(cx, top + 1), (cx + 1, top)], fill=CREAM_L)
    # head
    ell(d, (25, 19 + bob, 31, 30), CREAM_D)
    d.point([(28, 23 + bob), (29, 23 + bob)], fill=INK)
    d.line([(27, 26 + bob), (30, 27 + bob)], fill=GRUB_DK, width=1)
    # fuzz
    for x in (8, 14, 20):
        d.point([(x, 19 + bob), (x + 2, 18 + bob)], fill=CREAM_L)
    outline(img)
    return img


def dingo(kind, i):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "die":
        if i == 0:
            ell(d, (3, 18, 26, 30), DOG)
            ell(d, (20, 17, 31, 27), DOG_L)
            d.line([(23, 21), (26, 24)], fill=INK, width=1)
            d.line([(26, 21), (23, 24)], fill=INK, width=1)
            d.line([(4, 26), (0, 24)], fill=DOG_D, width=1)
        elif i == 1:
            ell(d, (2, 23, 29, 31), DOG)
            ell(d, (21, 22, 31, 30), DOG_L)
            d.line([(25, 25), (28, 28)], fill=INK, width=1)
            d.line([(28, 25), (25, 28)], fill=INK, width=1)
        else:
            ell(d, (1, 27, 31, 31), DOG_D)
            ell(d, (22, 26, 31, 31), DOG_L)
        outline(img)
        return img
    bob = 0
    legs = (0, 0, 0, 0)
    lunge = 0
    crouch = 0
    mouth = False
    if kind == "idle":
        bob = (0, 1)[i]
    elif kind == "walk":
        bob = (0, -1, 0, -1)[i]
        legs = ((-3, 3, 3, -3), (0, 0, 0, 0), (3, -3, -3, 3), (0, 0, 0, 0))[i]
    elif kind == "windup":
        crouch = (2, 3)[i]
        lunge = (-2, -3)[i]
        mouth = i == 1
    elif kind == "attack":
        lunge = (2, 3)[i]
        mouth = True
    ox = lunge
    top = bob + crouch
    # tail
    d.line([(5 + ox, 20 + top), (1 + ox, 16 + top)], fill=DOG_D, width=2)
    # back legs
    d.line([(8 + ox + legs[0], 25 + top), (8 + ox + legs[0], 30)], fill=DOG_D, width=2)
    d.line([(12 + ox + legs[1], 25 + top), (12 + ox + legs[1], 30)], fill=DOG_D, width=2)
    # body
    ell(d, (4 + ox, 17 + top, 22 + ox, 27 + top), DOG)
    ell(d, (6 + ox, 17 + top, 20 + ox, 21 + top), DOG_D)
    ell(d, (7 + ox, 23 + top, 19 + ox, 27 + top), DOG_L)
    # front legs
    d.line([(17 + ox + legs[2], 25 + top), (17 + ox + legs[2], 30)], fill=DOG, width=2)
    d.line([(21 + ox + legs[3], 25 + top), (21 + ox + legs[3], 30)], fill=DOG, width=2)
    # head and snout with corpse paint
    ell(d, (19 + ox, 14 + top, 28 + ox, 24 + top), DOG)
    d.polygon([(25 + ox, 18 + top), (31 + ox, 21 + top), (31 + ox, 24 + top), (25 + ox, 24 + top)], fill=DOG_L)
    ell(d, (20 + ox, 15 + top, 27 + ox, 22 + top), PAINT)
    d.rectangle((22 + ox, 17 + top, 25 + ox, 19 + top), fill=INK)
    d.point([(25 + ox, 18 + top)], fill=RED)
    d.line([(21 + ox, 21 + top), (26 + ox, 21 + top)], fill=INK, width=1)
    # ear
    d.polygon([(19 + ox, 14 + top), (21 + ox, 9 + top), (24 + ox, 14 + top)], fill=DOG_D)
    # nose and fangs
    d.point([(31 + ox, 21 + top)], fill=INK)
    if mouth:
        d.polygon([(26 + ox, 23 + top), (31 + ox, 23 + top), (28 + ox, 27 + top)], fill=(60, 20, 34, 255))
        d.point([(27 + ox, 23 + top), (30 + ox, 23 + top)], fill=WHITE)
    else:
        d.point([(28 + ox, 25 + top), (30 + ox, 25 + top)], fill=WHITE)
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
    sheet([("idle", 2), ("walk", 4), ("die", 3)], grub, "grub.png")
    sheet([("idle", 2), ("walk", 4), ("windup", 2), ("attack", 2), ("die", 3)], dingo, "dingo.png")
