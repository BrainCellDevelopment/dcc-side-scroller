"""Floor 1 platform tiles: red brick, wet stone, plank.

Same 64x16 strip layout as the other tile sheets (cap, body A, body B, edge),
consumed by scripts/level/platform.gd (styles 4 Brick, 5 WetStone, 6 Plank).
Run: python3 art-src/floor1/gen_tiles_floor1.py
"""
import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "terrain"))
sys.path.insert(0, HERE)
from gen_tiles import T, strip, edge_from  # noqa: E402
import palette as P  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "tiles")) + "/"
B, L, T_, N, W, PL = P.BRICK, P.LICHEN, P.TORCH, P.BONE, P.WET, P.PLANK


def moss_cap(t, xs, rng):
    """Lichen sitting on top of the cap rows (rows 0..2), never floating."""
    for x in xs:
        t.p(x, 0, L[3])
        t.p(x + 1, 0, L[2])
        t.p(x, 1, L[2])
        t.p(x + 1, 1, L[1])
        t.p(x - 1, 1, L[1])
        t.p(x, 2, L[1])


def brick():
    rng = np.random.default_rng(101)
    m = B[0]
    tones = [B[2], B[3], B[4]]
    hi = [B[3], B[4], B[5]]
    lo = [B[1], B[2], B[3]]

    def one(t, x0, y0, x1, y1, tone):
        t.r(x0, y0, x1, y1, tones[tone])
        t.r(x0, y0, x1, y0, hi[tone])
        t.r(x0, y0, x0, y1, hi[tone])
        t.r(x0, y1, x1, y1, lo[tone])
        t.r(x1, y0, x1, y1, lo[tone])
        for _ in range(2):
            t.p(int(rng.integers(x0 + 1, x1)), int(rng.integers(y0 + 1, y1)), tones[int(rng.integers(0, 3))])

    def wall(tn):
        t = T()
        t.r(0, 0, 15, 15, m)
        one(t, 1, 0, 7, 6, tn[0])
        one(t, 9, 0, 15, 6, tn[1])
        one(t, 0, 8, 3, 14, tn[2])
        one(t, 5, 8, 11, 14, tn[3])
        one(t, 13, 8, 15, 14, tn[0])
        return t

    cap = wall([1, 1, 1, 1])
    cap.r(0, 0, 15, 15, B[3])
    cap.speckle(rng, [B[2], B[4]], [0.1, 0.1], y0=5)
    for x in range(16):
        cap.p(x, 0, B[5] if x % 5 else N[0])
        cap.p(x, 1, B[4])
        cap.p(x, 2, B[3])
        cap.p(x, 3, B[2])
        cap.p(x, 4, m)
    cap.l([(5, 5), (5, 6), (6, 7)], m)
    cap.l([(11, 5), (11, 6), (10, 8)], m)
    moss_cap(cap, (3, 11), rng)

    a = wall([1, 2, 0, 1])
    for (x, y) in ((3, 3), (4, 4), (10, 12)):
        a.p(x, y, L[1])
    a.p(4, 3, L[2])
    a.p(11, 12, L[2])
    a.p(12, 12, L[1])

    b = T()
    b.r(0, 0, 15, 15, m)
    one(b, 1, 1, 14, 14, 1)
    b.r(2, 2, 13, 13, B[2])
    b.speckle(rng, [B[1], B[3]], [0.12, 0.1], 2, 13, 2, 13)
    b.l([(10, 3), (9, 6), (11, 8), (10, 12)], m)
    b.r(2, 11, 8, 13, B[1])
    for (x, y, c) in ((3, 12, L[2]), (5, 12, L[3]), (6, 13, L[2]), (2, 13, L[1]), (7, 12, L[1])):
        b.p(x, y, c)
    # a bone-white chip
    b.r(11, 4, 12, 4, N[2])
    b.p(11, 5, N[1])

    e = edge_from(a, [P.OUTLINE, m, B[1], B[2]])
    return strip([cap, a, b, e])


def wetstone():
    rng = np.random.default_rng(202)
    d, s0, s1, s2, s3 = W[0], W[1], W[2], W[3], W[4]
    m = "#0c1216"

    def block(t, x0, y0, x1, y1, tone):
        base = [s0, s1, s2][tone]
        t.r(x0, y0, x1, y1, base)
        t.r(x0, y0, x1, y0, [s1, s2, s3][tone])
        t.r(x0, y0, x0, y1, [s1, s2, s3][tone])
        t.r(x0, y1, x1, y1, [d, s0, s1][tone])
        t.r(x1, y0, x1, y1, [d, s0, s1][tone])
        t.p(x0, y0, base)
        t.p(x1, y1, m)

    def wall(tn):
        t = T()
        t.r(0, 0, 15, 15, m)
        block(t, 0, 0, 9, 7, tn[0])
        block(t, 11, 0, 15, 7, tn[1])
        block(t, 0, 9, 4, 15, tn[2])
        block(t, 6, 9, 15, 15, tn[3])
        return t

    cap = wall([1, 1, 1, 1])
    cap.r(0, 0, 15, 15, s1)
    cap.speckle(rng, [s0, s2], [0.1, 0.1], y0=5)
    cap.r(0, 0, 15, 0, s3)
    cap.r(0, 1, 15, 1, s2)
    cap.r(0, 2, 15, 2, s1)
    cap.r(0, 3, 15, 3, s0)
    cap.r(0, 4, 15, 4, m)
    for x in (2, 3, 4, 9, 10, 13):
        cap.p(x, 0, W[4])
    cap.p(3, 1, "#cfe8e0")
    cap.p(10, 1, "#cfe8e0")
    cap.l([(6, 5), (6, 7), (5, 9)], m)
    cap.l([(12, 5), (12, 6), (13, 8)], m)
    moss_cap(cap, (7, 14), rng)

    a = wall([1, 0, 2, 1])
    # wet streaks
    for x in (4, 12):
        for y in range(2, 8):
            a.p(x, y, W[0] if y % 3 else W[1])
    a.p(5, 3, L[1])
    a.p(5, 4, L[2])

    b = T()
    b.r(0, 0, 15, 15, m)
    block(b, 1, 1, 14, 14, 1)
    b.r(2, 2, 13, 13, s1)
    b.speckle(rng, [s0, s2], [0.14, 0.12], 2, 13, 2, 13)
    b.l([(4, 3), (5, 6), (4, 9), (5, 13)], d)
    b.l([(5, 3), (6, 6)], s2)
    b.r(8, 11, 13, 13, s0)
    for (x, y, c) in ((9, 12, L[2]), (10, 12, L[3]), (11, 13, L[2]), (12, 12, L[1])):
        b.p(x, y, c)

    e = edge_from(a, [P.OUTLINE, m, d, s0])
    return strip([cap, a, b, e])


def plank():
    rng = np.random.default_rng(303)
    g = "#120a08"
    w0, w1, w2, w3, w4 = PL

    def boards(t, tones, joints, nails=True):
        t.r(0, 0, 15, 15, g)
        ys = [(0, 4), (5, 9), (10, 14)]
        for (y0, y1), tn, jx in zip(ys, tones, joints):
            base = [w1, w2, w3][tn]
            t.r(0, y0, 15, y1, base)
            t.r(0, y0, 15, y0, [w2, w3, w4][tn])
            t.r(0, y1, 15, y1, [w0, w1, w2][tn])
            for gx in range(int(rng.integers(0, 6)), 16, 7):
                t.p(gx, y0 + 2, [w0, w1, w2][tn])
                t.p(gx + 1, y0 + 2, [w0, w1, w2][tn])
            t.r(jx, y0, jx, y1, g)
            if nails:
                t.p(jx + 2, y0 + 2, w4)
                t.p(jx - 2 if jx >= 2 else jx + 8, y0 + 2, w4)
        t.r(0, 15, 15, 15, g)

    cap = T()
    boards(cap, [1, 1, 1], [4, 11, 7])
    cap.r(0, 0, 15, 0, w4)
    cap.r(0, 1, 15, 1, w3)
    cap.r(0, 2, 15, 2, w2)
    cap.r(0, 3, 15, 3, w1)
    cap.r(0, 4, 15, 4, g)
    cap.p(3, 0, N[2])
    cap.p(9, 0, w4)
    moss_cap(cap, (6,), rng)
    for x in range(16):
        cap.p(x, 0, w4 if (x % 6) else N[1])

    a = T()
    boards(a, [1, 0, 2], [3, 9, 6])
    for (x, y) in ((2, 1), (12, 6), (5, 11)):
        a.p(x, y, w0)

    b = T()
    boards(b, [2, 1, 0], [10, 2, 12])
    b.r(4, 6, 6, 8, w0)
    b.p(5, 7, w1)
    b.p(2, 13, L[2])
    b.p(3, 13, L[1])
    b.p(4, 14, L[2])

    e = edge_from(a, [P.OUTLINE, g, w0, w1])
    return strip([cap, a, b, e])


STYLES = {"brick": brick, "wetstone": wetstone, "plank": plank}

if __name__ == "__main__":
    for name, fn in STYLES.items():
        fn().save(OUT + "tiles_%s.png" % name)
    print("ok")
