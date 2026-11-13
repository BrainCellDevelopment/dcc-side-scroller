import sys
import numpy as np
from PIL import Image
from pix import hx

OUT = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/tiles/"


class T:
    def __init__(self):
        self.a = np.zeros((16, 16, 4), dtype=np.uint8)

    def p(self, x, y, c):
        if 0 <= x < 16 and 0 <= y < 16:
            self.a[y, x] = hx(c) + (255,)

    def r(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)

    def l(self, pts, c):
        for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
            n = max(abs(x1 - x0), abs(y1 - y0), 1)
            for i in range(n + 1):
                self.p(round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n), c)

    def speckle(self, rng, cols, probs, y0=0, y1=15, x0=0, x1=15):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                v = rng.random()
                acc = 0
                for c, pr in zip(cols, probs):
                    acc += pr
                    if v < acc:
                        self.p(x, y, c)
                        break


def strip(tiles):
    img = np.zeros((16, 64, 4), dtype=np.uint8)
    for i, t in enumerate(tiles):
        img[:, i * 16:(i + 1) * 16] = t.a
    return Image.fromarray(img, "RGBA")


def edge_from(base, shades):
    t = T()
    t.a[:] = base.a
    for i, c in enumerate(shades):
        for y in range(16):
            t.p(i, y, c)
            t.p(15 - i, y, c)
    return t


def rubble():
    rng = np.random.default_rng(11)
    ol, d0, d1, d2, d3 = "#1b1226", "#242030", "#322e42", "#464259", "#5d5974"
    c0, c1, c2 = "#8a86a0", "#b3aec6", "#dcd8ea"
    con, conl = "#6c6782", "#8b87a2"
    rust, rust2 = "#8a4a2e", "#d08040"

    def asphalt(t, y0=0):
        t.r(0, y0, 15, 15, d1)
        t.speckle(rng, [d0, d2, d3], [0.08, 0.05, 0.01], y0=y0)

    cap = T()
    asphalt(cap, 5)
    cap.r(0, 0, 15, 0, c2)
    cap.r(0, 1, 15, 1, c1)
    cap.r(0, 2, 15, 2, c0)
    cap.r(0, 3, 15, 3, d3)
    cap.r(0, 4, 15, 4, d0)
    for x in (3, 10):
        cap.p(x, 0, c1)
    cap.p(6, 1, c0)
    cap.p(13, 2, d3)
    cap.r(9, 1, 12, 1, "#d6b04a")
    cap.p(8, 4, d3)
    cap.p(1, 4, d2)

    a = T()
    asphalt(a)
    a.l([(3, 1), (5, 4), (4, 7), (8, 10), (7, 14)], d0)
    a.l([(4, 1), (6, 4), (5, 7), (9, 10)], d2)
    a.p(12, 3, d3)
    a.p(13, 3, d3)
    a.r(11, 11, 13, 11, "#6a5a2c")

    b = T()
    asphalt(b)
    b.r(1, 1, 8, 7, con)
    b.l([(1, 1), (8, 1)], conl)
    b.l([(1, 1), (1, 7)], conl)
    b.r(1, 7, 8, 7, d3)
    b.r(8, 1, 8, 7, d3)
    b.l([(8, 7), (11, 9), (10, 12), (13, 15)], d0)
    b.r(4, 3, 5, 4, "#7a7592")
    b.l([(10, 2), (14, 5)], rust)
    b.p(14, 5, rust2)
    b.p(13, 4, "#b0623a")
    b.p(3, 11, rust2)
    b.p(4, 11, rust)
    b.p(3, 12, rust)
    b.p(5, 13, d3)
    b.p(6, 13, d3)

    e = edge_from(a, [ol, d0, "#2a2638", d1])
    return strip([cap, a, b, e])


def iron():
    rng = np.random.default_rng(5)
    ol, k0, k1, k2, k3 = "#12101c", "#0c0a14", "#1e2030", "#30344c", "#474c6c"
    h0, h1, h2 = "#6a7298", "#9aa2c8", "#d0d6f0"
    rust, rv = "#5a3226", "#8a4a32"

    def grate(t, ox, oy):
        t.r(0, 0, 15, 15, k1)
        for gy in range(0, 16, 4):
            t.r(0, gy, 15, gy, k3)
            t.r(0, gy + 3, 15, gy + 3, k0)
        for gy in range(0, 16, 4):
            for gx in range(0, 16, 4):
                x = (gx + ox + (2 if (gy // 4 + oy) % 2 else 0)) % 16
                for dx in (0, 1):
                    t.p((x + dx) % 16, gy + 1, k0)
                    t.p((x + dx) % 16, gy + 2, k0)
                t.p((x + 2) % 16, gy + 1, k2)
        return t

    cap = T()
    cap.r(0, 0, 15, 15, k2)
    cap.r(0, 0, 15, 0, h2)
    cap.r(0, 1, 15, 1, h1)
    cap.r(0, 2, 15, 2, h0)
    cap.r(0, 3, 15, 3, k3)
    cap.r(0, 4, 15, 4, k0)
    for x in range(0, 16, 4):
        cap.p(x, 3, k0)
        cap.p(x + 1, 3, h0)
        cap.p(x + 2, 3, k3)
        cap.p(x + 1, 4, k3)
    grate(cap, 0, 0)
    cap.r(0, 0, 15, 4, k2)
    cap.r(0, 0, 15, 0, h2)
    cap.r(0, 1, 15, 1, h1)
    cap.r(0, 2, 15, 2, h0)
    for x in range(0, 16, 4):
        cap.p(x, 3, k1)
        cap.p(x + 1, 3, k3)
        cap.p(x + 2, 3, k3)
        cap.p(x + 3, 3, k1)
        cap.p(x + 1, 4, k0)
        cap.p(x + 2, 4, k0)
    cap.p(7, 1, h2)
    cap.p(15, 1, h0)

    a = grate(T(), 0, 0)
    b = grate(T(), 2, 1)
    b.r(2, 3, 13, 12, k2)
    b.r(2, 3, 13, 3, h0)
    b.r(2, 12, 13, 12, k0)
    b.r(2, 3, 2, 12, h0)
    b.r(13, 3, 13, 12, k0)
    for (x, y) in ((4, 5), (11, 5), (4, 10), (11, 10)):
        b.p(x, y, k0)
        b.p(x - 1, y - 1, h1)
        b.p(x, y - 1, h0)
        b.p(x - 1, y, h0)
    b.p(7, 7, rust)
    b.p(8, 8, rv)
    b.p(6, 8, rust)
    e = edge_from(a, [ol, k0, k2, h0])
    for y in (2, 7, 12):
        e.p(2, y, h1)
        e.p(13, y, k0)
    return strip([cap, a, b, e])


def stone():
    rng = np.random.default_rng(23)
    ol, m, s0, s1, s2, s3 = "#12101f", "#1a1c2c", "#2b2f44", "#3b4260", "#505a7c", "#6b7799"
    cap_hi, cap_m = "#c0cae0", "#92a0be"
    mo0, mo1 = "#3d6b3a", "#74a846"

    def brick(t, x0, y0, x1, y1, tone):
        base = [s0, s1, s2][tone]
        t.r(x0, y0, x1, y1, base)
        t.r(x0, y0, x1, y0, [s1, s2, s3][tone])
        t.r(x0, y0, x0, y1, [s1, s2, s3][tone])
        t.r(x0, y1, x1, y1, [m, s0, s1][tone])
        t.r(x1, y0, x1, y1, [m, s0, s1][tone])
        t.p(x0, y1, [m, s0, s1][tone])
        for _ in range(2):
            t.p(int(rng.integers(x0 + 1, x1)), int(rng.integers(y0 + 1, y1)), [s0, s1, s2][int(rng.integers(0, 3))])

    def bricks(t, tones, flip=False):
        t.r(0, 0, 15, 15, m)
        brick(t, 1, 0, 7, 6, tones[0])
        brick(t, 9, 0, 15, 6, tones[1])
        brick(t, 0, 8, 3, 14, tones[2])
        brick(t, 5, 8, 11, 14, tones[3])
        brick(t, 13, 8, 15, 14, tones[0])
        return t

    cap = bricks(T(), [1, 1, 1, 1])
    cap.r(0, 0, 15, 15, s1)
    cap.speckle(rng, [s0, s2], [0.1, 0.1], y0=5)
    cap.r(0, 0, 15, 0, cap_hi)
    cap.r(0, 1, 15, 1, cap_m)
    cap.r(0, 2, 15, 2, "#7686a8")
    cap.r(0, 3, 15, 3, s2)
    cap.r(0, 4, 15, 4, m)
    cap.r(15, 0, 15, 4, m)
    cap.p(15, 0, "#8090b0")
    cap.p(7, 0, cap_m)
    cap.p(8, 0, cap_m)
    cap.p(2, 1, cap_hi)
    cap.p(11, 2, s3)
    cap.p(4, 4, s0)
    cap.p(3, 0, mo1)
    cap.p(4, 0, mo1)
    cap.p(4, 1, mo0)
    cap.p(3, 1, mo0)
    cap.p(5, 1, mo0)
    cap.p(12, 5, mo0)
    cap.p(12, 4, mo0)
    cap.p(1, 5, s0)
    cap.p(9, 6, s0)
    cap.p(10, 7, m)
    cap.l([(5, 5), (5, 6), (6, 7)], m)

    a = bricks(T(), [1, 2, 0, 1])
    a.p(3, 3, mo0)
    a.p(4, 3, mo1)
    a.p(4, 4, mo0)
    a.p(10, 12, mo0)
    a.p(11, 12, mo1)

    b = T()
    b.r(0, 0, 15, 15, m)
    brick(b, 1, 1, 14, 14, 1)
    b.r(2, 2, 13, 13, s1)
    b.speckle(rng, [s0, s2], [0.12, 0.1], 2, 13, 2, 13)
    b.l([(10, 3), (9, 6), (11, 8), (10, 12)], m)
    b.l([(11, 3), (10, 6), (12, 8)], s2)
    b.r(2, 11, 8, 13, mo0)
    b.p(3, 11, mo1)
    b.p(5, 11, mo1)
    b.p(6, 12, mo1)
    b.p(2, 12, mo1)
    b.p(7, 10, mo0)
    b.p(4, 10, mo0)
    b.p(2, 3, s3)
    b.p(3, 3, s3)

    e = edge_from(a, [ol, m, s0, s1])
    return strip([cap, a, b, e])


def wood():
    rng = np.random.default_rng(9)
    ol = "#1f1410"
    w0, w1, w2, w3, w4, w5 = "#3f2418", "#5b3420", "#7a4a2a", "#9c6236", "#c0844a", "#e4ac66"
    hi = "#f6d08a"
    nail, nailh = "#2a1a14", "#b8a080"

    def planks(t, tones, joints, knot=None):
        t.r(0, 0, 15, 15, w2)
        for i, y in enumerate((0, 5, 10)):
            base = [w2, w3, w2][(tones + i) % 3]
            t.r(0, y, 15, y + 3, base)
            t.r(0, y, 15, y, w4 if base == w3 else w3)
            t.r(0, y + 4, 15, y + 4, w0)
            for _ in range(3):
                gx = int(rng.integers(0, 12))
                t.r(gx, y + 1 + int(rng.integers(0, 3)), gx + int(rng.integers(2, 4)), y + 1 + int(rng.integers(0, 3)), w1 if base == w2 else w2)
        t.r(0, 15, 15, 15, w0)
        for (x, y) in joints:
            t.r(x, y, x, y + 3, w0)
            t.p(x + 1, y, w4)
            t.p(x - 1 if x > 0 else 15, y + 1, w1)
        return t

    cap = T()
    planks(cap, 0, [(6, 5), (13, 10)])
    cap.r(0, 0, 15, 0, hi)
    cap.r(0, 1, 15, 1, w5)
    cap.r(0, 2, 15, 2, w4)
    cap.r(0, 3, 15, 3, w3)
    cap.r(0, 4, 15, 4, w0)
    for x in (2, 9):
        cap.p(x, 0, w5)
    cap.p(5, 1, hi)
    cap.p(12, 2, w3)
    cap.p(14, 1, w4)
    cap.l([(3, 2), (4, 2), (5, 2)], w3)

    a = planks(T(), 1, [(3, 0), (10, 5), (7, 10)])
    for (x, y) in ((1, 1), (14, 6), (1, 11)):
        a.p(x, y + 1, nail)
        a.p(x, y, nailh)
    b = planks(T(), 2, [(12, 0), (4, 5), (11, 10)])
    b.r(6, 5, 9, 8, w1)
    b.p(7, 6, w0)
    b.p(8, 6, w0)
    b.p(7, 7, w2)
    b.p(6, 5, w3)
    e = edge_from(a, [ol, w0, w1, w2])
    return strip([cap, a, b, e])


def spikes():
    t = T()
    ol, d, m, l, h = "#14101e", "#3a3f5c", "#7a82a8", "#b8c0e0", "#f0f4ff"
    base = "#252838"
    t.r(0, 12, 15, 15, base)
    t.r(0, 12, 15, 12, "#4a506e")
    t.r(0, 15, 15, 15, ol)
    for x in (2, 6, 10, 14):
        t.p(x, 13, "#4a506e")
    for cx in (4, 12):
        for i in range(12):
            wd = i * 3 // 11
            hw = wd
            for dx in range(-hw, hw + 1):
                col = m
                if dx < 0:
                    col = l
                if dx == -hw:
                    col = h if i < 10 else l
                if dx == hw:
                    col = ol
                if dx == hw - 1 and hw > 1:
                    col = d
                t.p(cx + dx, i, col)
        t.p(cx, 0, h)
        t.p(cx, 1, l)
        t.r(cx - 3, 11, cx + 3, 11, ol)
    return t


if __name__ == "__main__":
    for name, fn in (("rubble", rubble), ("iron", iron), ("stone", stone), ("wood", wood)):
        fn().save(OUT + f"tiles_{name}.png")
    a = np.zeros((16, 16, 4), dtype=np.uint8)
    spikes_t = spikes()
    Image.fromarray(spikes_t.a, "RGBA").save(OUT + "spikes.png")
    print("ok")
