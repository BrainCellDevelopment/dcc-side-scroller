import numpy as np
from pxlib import *

SIZES = {}


def burnt_tree():
    cv = Cv(48, 80)
    trunk = poly(cv, [(14, 79), (18, 70), (20, 40), (19, 28), (29, 28), (28, 42), (30, 70), (35, 79)])
    paint(cv, trunk, CHAR, hl=2, sd=2)
    for (pts, w) in (([(20, 40), (11, 30), (7, 18), (8, 8)], 4), ([(26, 36), (35, 26), (38, 14)], 3), ([(10, 30), (4, 28)], 2), ([(35, 26), (42, 24)], 2), ([(24, 30), (22, 14), (25, 3)], 4), ([(8, 18), (14, 12)], 2), ([(37, 15), (32, 9)], 2)):
        paint(cv, line(cv, pts, w), CHAR, hl=1, sd=1)
    paint(cv, trunk, CHAR, hl=2, sd=2, ol=False)
    for x in (21, 24, 27):
        for y in range(34, 76, 7):
            flat(cv, rect(cv, x + (y % 3) - 1, y, x + (y % 3) - 1, y + 3), CHAR[0])
    for (x, y) in ((22, 45), (25, 52), (23, 60), (27, 38), (9, 20), (37, 20), (24, 12)):
        cv.px(x, y, FLAME_O)
        cv.px(x, y + 1, FLAME_R)
    for (x, y) in ((25, 45), (22, 58)):
        cv.px(x, y, FLAME_Y)
    flat(cv, rect(cv, 11, 78, 38, 79), CHAR[1])
    speckle(cv, cv.opaque(), CHAR[3], 0.06, 9)
    exterior_outline(cv)
    return cv


def bike_rack():
    cv = Cv(40, 24)
    flat(cv, rect(cv, 1, 21, 38, 22), STEEL[1], ol=True)
    for i, x in enumerate(range(5, 36, 8)):
        o = ell(cv, x - 3, 8 if i != 2 else 10, x + 3, 24)
        n = ell(cv, x - 1, 10 if i != 2 else 12, x + 1, 24)
        m = o & ~n
        m[22:, :] = False
        paint(cv, m, STEEL, hl=1, sd=1)
    paint(cv, ell(cv, 22, 6, 36, 20), CHAR, hl=1, sd=1)
    flat(cv, ell(cv, 25, 9, 33, 17), (0, 0, 0))
    cv.a[ell(cv, 25, 9, 33, 17)] = 0
    paint(cv, ell(cv, 25, 9, 33, 17) & ~ell(cv, 27, 11, 31, 15), STEEL, hl=1, sd=1)
    for a in range(0, 180, 45):
        t = np.radians(a)
        pts_line(cv, round(29 + np.cos(t) * 4), round(13 + np.sin(t) * 4), round(29 - np.cos(t) * 4), round(13 - np.sin(t) * 4), STEEL[2])
    speckle(cv, cv.opaque(), RUST[2], 0.12, 13)
    exterior_outline(cv)
    return cv


def moped():
    cv = Cv(40, 28)
    for (cx, cy) in ((9, 21), (31, 21)):
        paint(cv, ell(cv, cx - 6, cy - 6, cx + 6, cy + 6), [CHAR[0], CHAR[1], CHAR[2], CHAR[3], CHAR[4]], hl=2, sd=1)
        paint(cv, ell(cv, cx - 4, cy - 4, cx + 4, cy + 4), STEEL, hl=1, sd=1)
        paint(cv, ell(cv, cx - 1, cy - 1, cx + 1, cy + 1), BRASS, hl=0, sd=0, ol=False)
    paint(cv, rrect(cv, 3, 9, 19, 17), RUST, hl=1, sd=2)
    paint(cv, rect(cv, 18, 15, 29, 18), RUST, hl=1, sd=1)
    paint(cv, poly(cv, [(25, 19), (27, 8), (31, 8), (30, 19)]), RUST, hl=1, sd=1)
    paint(cv, rrect(cv, 5, 5, 17, 9), CHAR, hl=1, sd=1)
    pts_line(cv, 27, 6, 35, 5, STEEL[3])
    paint(cv, line(cv, [(27, 6), (35, 4)], 2), STEEL, hl=1, sd=1)
    paint(cv, ell(cv, 33, 6, 37, 10), BRASS, hl=1, sd=1)
    pts_line(cv, 35, 7, 36, 9, BONE[4])
    flat(cv, poly(cv, [(10, 11), (15, 11), (13, 16), (9, 15)]), RUST[1])
    paint(cv, line(cv, [(3, 22), (0, 25)], 2), STEEL, hl=0, sd=0)
    speckle(cv, cv.opaque(), CHAR[0], 0.10, 14)
    cv.px(14, 14, RUST[4])
    exterior_outline(cv)
    return cv


def rubble():
    cv = Cv(32, 16)
    parts = [
        ([(1, 15), (2, 10), (9, 8), (13, 15)], STONE),
        ([(9, 15), (10, 7), (14, 3), (20, 4), (23, 9), (22, 15)], STONE),
        ([(19, 15), (21, 10), (28, 8), (31, 15)], RUST),
        ([(12, 5), (15, 1), (19, 2), (18, 6)], RUST),
        ([(3, 10), (5, 6), (10, 6), (9, 10)], RUST),
        ([(24, 10), (26, 6), (30, 8)], STONE),
    ]
    for pts, ramp in parts:
        paint(cv, poly(cv, pts), ramp, hl=1, sd=1)
    for (x, y) in ((6, 9), (14, 8), (25, 12), (16, 4)):
        flat(cv, rect(cv, x, y, x + 2, y), (ramp_c := STONE[1]))
    pts_line(cv, 17, 3, 21, 0, STEEL[3])
    pts_line(cv, 24, 8, 28, 4, STEEL[2])
    pts_line(cv, 24, 7, 27, 3, STEEL[3])
    flat(cv, rect(cv, 0, 15, 31, 15), CHAR[1])
    speckle(cv, cv.opaque(), CHAR[0], 0.08, 6)
    exterior_outline(cv)
    return cv


def big_door():
    cv = Cv(96, 112)
    outer = rect(cv, 0, 28, 95, 111) | ell(cv, 0, 0, 95, 56)
    inner = rect(cv, 9, 30, 86, 105) | ell(cv, 9, 8, 86, 52)
    paint(cv, outer & ~inner, STONE, hl=1, sd=1)
    fr = outer & ~inner
    for y in range(34, 111, 10):
        flat(cv, rect(cv, 0, y, 8, y), STONE[1] if False else STONE[1])
        flat(cv, rect(cv, 87, y, 95, y), STONE[1])
    ys, xs = np.nonzero(fr & (np.arange(112)[:, None] < 30))
    for y, x in zip(ys, xs):
        if (x * 5 + y * 3) % 17 == 0:
            cv.px(x, y, STONE[1])
    for ang in np.linspace(np.radians(195), np.radians(345), 9):
        cx, cy = 47.5 + np.cos(ang) * 44, 30 + np.sin(ang) * 25
        cv.px(cx, cy, STONE[1])
        cv.px(cx + 1, cy, STONE[1])
    paint(cv, rect(cv, 42, 1, 53, 10), STONE, hl=1, sd=1)
    flat(cv, rect(cv, 46, 3, 49, 8), BRASS[2])
    cv.px(46, 3, BRASS[4])
    paint(cv, rect(cv, 0, 104, 95, 111), STONE, hl=1, sd=2)
    flat(cv, rect(cv, 4, 107, 91, 107), STONE[1])
    for lx, x0, x1 in ((0, 9, 47), (1, 48, 86)):
        leaf = inner & rect(cv, x0, 0, x1, 111) & ~rect(cv, 0, 104, 95, 111)
        paint(cv, leaf, WOOD, hl=1, sd=1, ol=False)
        for x in range(x0 + 6, x1, 6):
            flat(cv, rect(cv, x, 10, x, 103) & leaf, WOOD[1])
        for x in range(x0 + 3, x1, 6):
            flat(cv, rect(cv, x, 10, x, 103) & leaf, WOOD[3])
        for y in (46, 72, 96):
            band = leaf & rect(cv, x0, y, x1, y + 4)
            paint(cv, band, STEEL, hl=1, sd=1, ol=False)
            for x in range(x0 + 3, x1 - 1, 8):
                cv.px(x, y + 2, STEEL[4])
                cv.px(x, y + 3, STEEL[0])
        paint(cv, leaf & rect(cv, x0, 0, x1, 111) & ~rect(cv, 0, 0, 0, 0), WOOD, hl=0, sd=0, ol=False) if False else None
    flat(cv, rect(cv, 47, 14, 48, 103), CHAR[0])
    emb = ell(cv, 36, 50, 59, 73)
    paint(cv, emb, BRASS, hl=1, sd=2)
    flat(cv, ell(cv, 39, 53, 56, 70), BRASS[1])
    paint(cv, ell(cv, 41, 55, 54, 66), BONE, hl=1, sd=1)
    paint(cv, rect(cv, 44, 66, 51, 69), BONE, hl=1, sd=1)
    for ex in (43, 49):
        flat(cv, rect(cv, ex, 59, ex + 2, 61), CHAR[0])
    for tx in (45, 47, 49):
        cv.px(tx, 68, CHAR[0])
    for x in (36, 59):
        pass
    for rx in (40, 56):
        paint(cv, ell(cv, rx - 3, 80, rx + 3, 86), BRASS, hl=1, sd=1)
        flat(cv, ell(cv, rx - 1, 82, rx + 1, 84), WOOD[0])
    for (hx, y0, y1) in ((11, 46, 48), (84, 46, 48)):
        pass
    speckle(cv, cv.opaque(), CHAR[0], 0.015, 21)
    exterior_outline(cv)
    return cv


def rug():
    cv = Cv(112, 10)
    body = rect(cv, 4, 1, 107, 8)
    paint(cv, body, LEAT, hl=1, sd=1)
    flat(cv, rect(cv, 6, 3, 105, 6), LEAT[1])
    for x in range(8, 104, 2):
        cv.px(x, 2, BRASS[2] if (x // 2) % 2 else BRASS[3])
        cv.px(x, 7, BRASS[1])
    for x in range(16, 100, 14):
        d = poly(cv, [(x, 4), (x + 3, 3), (x + 6, 4), (x + 3, 6)])
        flat(cv, d, BRASS[2])
        cv.px(x + 3, 4, BRASS[4])
    for x in range(2, 112, 3):
        if x < 4 or x > 106:
            flat(cv, rect(cv, x if x < 50 else x, 2, x, 7), BONE[2])
    for y in range(2, 8, 2):
        flat(cv, rect(cv, 1, y, 3, y), BONE[2])
        flat(cv, rect(cv, 108, y, 110, y), BONE[2])
    flat(cv, rect(cv, 4, 9, 107, 9), LEAT[0])
    speckle(cv, body, LEAT[0], 0.06, 3)
    exterior_outline(cv)
    return cv


def crate_one(cv, x0, y0, w, h, broken=False):
    paint(cv, rect(cv, x0, y0, x0 + w - 1, y0 + h - 1), WOOD, hl=1, sd=1)
    paint(cv, rect(cv, x0, y0, x0 + 2, y0 + h - 1), WOOD, hl=1, sd=1, ol=False)
    paint(cv, rect(cv, x0 + w - 3, y0, x0 + w - 1, y0 + h - 1), WOOD, hl=1, sd=1, ol=False)
    paint(cv, rect(cv, x0, y0, x0 + w - 1, y0 + 2), WOOD, hl=1, sd=1, ol=False)
    paint(cv, rect(cv, x0, y0 + h - 3, x0 + w - 1, y0 + h - 1), WOOD, hl=1, sd=1, ol=False)
    pts_line(cv, x0 + 2, y0 + 2, x0 + w - 3, y0 + h - 3, WOOD[1])
    pts_line(cv, x0 + 2, y0 + 3, x0 + w - 4, y0 + h - 3, WOOD[1])
    pts_line(cv, x0 + w - 3, y0 + 2, x0 + 2, y0 + h - 3, WOOD[1])
    for (x, y) in ((x0 + 1, y0 + 1), (x0 + w - 2, y0 + 1), (x0 + 1, y0 + h - 2), (x0 + w - 2, y0 + h - 2)):
        cv.px(x, y, STEEL[3])
    if broken:
        flat(cv, poly(cv, [(x0 + 5, y0 + 4), (x0 + w - 6, y0 + 4), (x0 + w - 7, y0 + h - 5), (x0 + 6, y0 + h - 4)]), CHAR[0])
        pts_line(cv, x0 + 7, y0 + 5, x0 + 9, y0 + 9, WOOD[3])


def crate():
    cv = Cv(40, 32)
    crate_one(cv, 1, 16, 16, 16)
    crate_one(cv, 20, 18, 18, 14, broken=True)
    crate_one(cv, 8, 2, 16, 14)
    paint(cv, poly(cv, [(26, 12), (36, 6), (38, 9), (29, 17)]), WOOD, hl=1, sd=1)
    paint(cv, poly(cv, [(31, 26), (39, 24), (39, 27), (32, 28)]), WOOD, hl=1, sd=1)
    pts_line(cv, 3, 20, 13, 20, CLOTH[3])
    flat(cv, rect(cv, 10, 6, 14, 8), BONE[3])
    flat(cv, rect(cv, 11, 7, 13, 7), RUST[2])
    speckle(cv, cv.opaque(), CHAR[0], 0.08, 31)
    exterior_outline(cv)
    return cv


def sign_arrow():
    cv = Cv(32, 24)
    paint(cv, rect(cv, 14, 12, 17, 23), WOOD, hl=1, sd=1)
    paint(cv, poly(cv, [(1, 2), (23, 2), (30, 8), (23, 14), (1, 14)]), WOOD, hl=1, sd=1)
    flat(cv, poly(cv, [(4, 6), (17, 6), (17, 4), (25, 8), (17, 12), (17, 10), (4, 10)]), BONE[3])
    flat(cv, poly(cv, [(5, 7), (18, 7), (18, 6), (22, 8), (18, 10), (5, 9)]), RUST[2])
    for (x, y) in ((3, 4), (3, 12)):
        cv.px(x, y, STEEL[4])
    cv.px(15, 14, WOOD[0])
    speckle(cv, cv.opaque(), WOOD[1], 0.08, 4)
    exterior_outline(cv)
    return cv


def street_lamp():
    cv = Cv(40, 80)
    paint(cv, rect(cv, 11, 12, 14, 77), STEEL, hl=1, sd=2)
    paint(cv, rect(cv, 8, 72, 17, 77), CHAR, hl=1, sd=1)
    paint(cv, line(cv, [(13, 14), (13, 8), (21, 4), (30, 6)], 3), STEEL, hl=1, sd=2)
    paint(cv, poly(cv, [(25, 4), (37, 4), (36, 9), (26, 9)]), CHAR, hl=1, sd=1)
    flat(cv, rect(cv, 28, 8, 34, 9), BONE[1], ol=False)
    cv.px(30, 9, BONE[3])
    flat(cv, rect(cv, 10, 40, 15, 41), STEEL[0], ol=False)
    speckle(cv, cv.opaque(), RUST[2], 0.1, 5)
    exterior_outline(cv)
    return cv


def street_lamp_bent():
    cv = Cv(48, 72)
    paint(cv, rect(cv, 9, 40, 12, 71), STEEL, hl=1, sd=2)
    paint(cv, rect(cv, 6, 66, 15, 71), CHAR, hl=1, sd=1)
    paint(cv, poly(cv, [(8, 42), (13, 42), (17, 38), (12, 36)]), STEEL, hl=1, sd=1)
    paint(cv, line(cv, [(12, 39), (26, 28), (38, 22)], 3), STEEL, hl=1, sd=2)
    paint(cv, poly(cv, [(34, 17), (46, 21), (43, 27), (33, 24)]), CHAR, hl=1, sd=1)
    for (x, y) in ((8, 41), (14, 38)):
        cv.px(x, y, RUST[3])
    speckle(cv, cv.opaque(), RUST[2], 0.12, 6)
    exterior_outline(cv)
    return cv


def street_sign():
    cv = Cv(40, 60)
    paint(cv, rect(cv, 18, 8, 21, 59), STEEL, hl=1, sd=2)
    paint(cv, rect(cv, 15, 55, 24, 59), CHAR, hl=1, sd=1)
    paint(cv, rect(cv, 4, 4, 34, 13), GREEN, hl=1, sd=2)
    paint(cv, rect(cv, 10, 17, 37, 24), GREEN, hl=1, sd=2)
    for x in range(7, 31, 4):
        flat(cv, rect(cv, x, 7, x + 2, 9), BONE[3], ol=False)
    for x in range(13, 34, 4):
        flat(cv, rect(cv, x, 20, x + 2, 21), BONE[3], ol=False)
    flat(cv, rect(cv, 17, 14, 22, 16), STEEL[1], ol=False)
    speckle(cv, cv.opaque(), RUST[2], 0.08, 9)
    exterior_outline(cv)
    return cv


def stop_sign():
    cv = Cv(32, 56)
    paint(cv, rect(cv, 14, 20, 17, 55), STEEL, hl=1, sd=2)
    paint(cv, rect(cv, 11, 51, 20, 55), CHAR, hl=1, sd=1)
    paint(cv, poly(cv, [(10, 2), (21, 2), (28, 9), (28, 19), (21, 25), (10, 25), (3, 19), (3, 9)]), LEAT, hl=1, sd=2)
    flat(cv, rect(cv, 8, 12, 23, 15), BONE[3], ol=False)
    flat(cv, rect(cv, 9, 16, 22, 16), BONE[1], ol=False)
    for (x, y) in ((6, 9), (6, 18), (25, 9), (25, 18)):
        cv.px(x, y, STEEL[4])
    speckle(cv, cv.opaque(), CHAR[1], 0.1, 3)
    exterior_outline(cv)
    return cv


def stair_rail():
    cv = Cv(64, 24)
    paint(cv, rect(cv, 0, 3, 63, 5), STEEL, hl=1, sd=1)
    paint(cv, rect(cv, 0, 20, 63, 22), STEEL, hl=1, sd=1)
    for x in range(7, 60, 8):
        paint(cv, rect(cv, x, 6, x + 1, 19), STEEL, hl=1, sd=0)
        flat(cv, ell(cv, x - 1, 11, x + 2, 14), STEEL[2], ol=True)
    for x in (1, 61):
        paint(cv, rect(cv, x, 2, x + 1, 23), IRON if False else STEEL, hl=1, sd=1)
        paint(cv, ell(cv, x - 2, 0, x + 3, 4), BRASS, hl=1, sd=1)
    speckle(cv, cv.opaque(), RUST[2], 0.03, 8)
    return cv


def bed():
    cv = Cv(56, 28)
    for x in (4, 48):
        paint(cv, rect(cv, x, 22, x + 3, 27), WOOD, hl=1, sd=1)
    paint(cv, rect(cv, 2, 4, 9, 24), WOOD, hl=1, sd=1)
    paint(cv, rect(cv, 47, 12, 53, 24), WOOD, hl=1, sd=1)
    for x in (3, 7):
        flat(cv, rect(cv, x, 6, x, 22), WOOD[1])
    paint(cv, rect(cv, 9, 18, 47, 22), WOOD, hl=1, sd=1)
    paint(cv, rrect(cv, 9, 12, 46, 19), CLOTH, hl=1, sd=1)
    paint(cv, rrect(cv, 20, 9, 46, 17), NAVY, hl=1, sd=1)
    for x in range(24, 45, 5):
        pts_line(cv, x, 10, x + 2, 16, NAVY[1])
    paint(cv, rrect(cv, 10, 8, 20, 14), BONE, hl=1, sd=1)
    flat(cv, rect(cv, 22, 13, 25, 15), BRASS[2])
    flat(cv, rect(cv, 34, 11, 36, 13), RUST[2])
    for x in (3, 7):
        cv.px(x, 6, BRASS[3])
    paint(cv, ell(cv, 2, 2, 9, 5), WOOD, hl=1, sd=1)
    speckle(cv, cv.opaque(), CHAR[0], 0.05, 3)
    exterior_outline(cv)
    return cv


def desk():
    cv = Cv(48, 32)
    for x in (2, 41):
        paint(cv, rect(cv, x, 17, x + 4, 31), WOOD, hl=1, sd=1)
    paint(cv, rect(cv, 6, 20, 41, 30), WOOD, hl=1, sd=1)
    for (x0, x1) in ((8, 23), (25, 39)):
        paint(cv, rect(cv, x0, 22, x1, 28), WOOD, hl=1, sd=1)
        flat(cv, rect(cv, (x0 + x1) // 2 - 1, 25, (x0 + x1) // 2 + 1, 25), BRASS[3])
    paint(cv, rect(cv, 0, 14, 47, 18), WOOD, hl=1, sd=1)
    flat(cv, rect(cv, 1, 15, 46, 15), WOOD[3])
    paint(cv, rect(cv, 4, 10, 15, 13), BONE, hl=1, sd=1)
    paint(cv, rect(cv, 6, 8, 16, 11), CLOTH, hl=1, sd=1)
    pts_line(cv, 7, 9, 14, 9, CLOTH[1])
    paint(cv, rect(cv, 28, 6, 30, 13), BONE, hl=1, sd=1)
    cv.px(29, 4, FLAME_Y)
    cv.px(29, 5, FLAME_O)
    cv.px(29, 3, FLAME_O)
    paint(cv, rect(cv, 36, 9, 40, 13), STEEL, hl=1, sd=1)
    pts_line(cv, 38, 8, 42, 1, BONE[4])
    pts_line(cv, 39, 8, 43, 2, BONE[2])
    paint(cv, ell(cv, 19, 9, 25, 13), BONE, hl=1, sd=1)
    cv.px(21, 11, CHAR[0])
    cv.px(23, 11, CHAR[0])
    exterior_outline(cv)
    return cv


def bookshelf():
    cv = Cv(40, 56)
    paint(cv, rect(cv, 0, 0, 39, 55), WOOD, hl=1, sd=2)
    flat(cv, rect(cv, 3, 3, 36, 52), CHAR[0])
    flat(cv, rect(cv, 3, 3, 36, 4), CHAR[1])
    rs = np.random.RandomState(9)
    cols = [LEAT, NAVY, GREEN, BRASS, PURP, RUST, STEEL]
    for si, sy in enumerate((16, 31, 46)):
        x = 4
        lean = si == 1
        while x < 34:
            w = rs.randint(2, 5)
            h = rs.randint(8, 12)
            if x + w > 35:
                break
            ramp = cols[rs.randint(0, len(cols))]
            if lean and x > 26:
                paint(cv, poly(cv, [(x, sy), (x + w, sy), (x + w + 3, sy - h + 1), (x + 3, sy - h + 1)]), ramp, hl=1, sd=1)
                x += w + 3
                continue
            paint(cv, rect(cv, x, sy - h + 1, x + w - 1, sy), ramp, hl=1, sd=1)
            flat(cv, rect(cv, x, sy - h + 3, x + w - 1, sy - h + 3), BRASS[3])
            x += w + 0
        paint(cv, rect(cv, 2, sy + 1, 37, sy + 3), WOOD, hl=1, sd=1)
    paint(cv, ell(cv, 26, 22, 33, 28), BONE, hl=1, sd=1) if False else None
    paint(cv, ell(cv, 27, 3, 34, 9), BONE, hl=1, sd=1)
    cv.px(29, 6, CHAR[0])
    cv.px(32, 6, CHAR[0])
    paint(cv, rect(cv, 5, 36, 10, 44), STEEL, hl=1, sd=1) if False else None
    exterior_outline(cv)
    return cv


STATIC = {
    "burnt_tree": burnt_tree, "bike_rack": bike_rack, "moped": moped, "rubble": rubble, "big_door": big_door,
    "rug": rug, "crate": crate, "sign_arrow": sign_arrow, "street_lamp": street_lamp, "street_lamp_bent": street_lamp_bent, "street_sign": street_sign, "stop_sign": stop_sign, "stair_rail": stair_rail, "bed": bed, "desk": desk, "bookshelf": bookshelf,
}

if __name__ == "__main__":
    for n, fn in STATIC.items():
        cv = fn()
        save(cv.a, "props/%s.png" % n)
        preview(cv.a, n, 6)
        preview12(cv.a, n)
    print({n: STATIC[n]().a.shape[1::-1] for n in STATIC})
