import numpy as np
from pxlib import *

W_ = (255, 250, 214)
Y_ = (255, 220, 96)
O_ = (246, 140, 48)
R_ = (200, 64, 56)
D_ = (112, 38, 64)


def ray(cv, cx, cy, ang, r0, r1, c, w=1):
    x0 = cx + np.cos(ang) * r0
    y0 = cy + np.sin(ang) * r0
    x1 = cx + np.cos(ang) * r1
    y1 = cy + np.sin(ang) * r1
    flat(cv, line(cv, [(round(x0), round(y0)), (round(x1), round(y1))], w), c)


def disc(cv, cx, cy, r, c):
    flat(cv, ell(cv, cx - r, cy - r, cx + r, cy + r), c)


def hit_spark():
    fr = []
    for k in range(4):
        cv = Cv(24, 24)
        cx, cy = 11.5, 11.5
        if k == 0:
            disc(cv, 11, 11, 6, O_)
            disc(cv, 11, 11, 5, Y_)
            disc(cv, 11, 11, 3, W_)
            for i in range(4):
                ray(cv, 11, 11, i * np.pi / 2 + np.pi / 4, 6, 9, Y_)
        elif k == 1:
            for i in range(8):
                a = i * np.pi / 4
                ln = 11 if i % 2 == 0 else 8
                ray(cv, 11, 11, a, 3, ln, Y_ if i % 2 else W_)
                ray(cv, 11, 11, a + 0.1, 5, ln - 2, O_)
            disc(cv, 11, 11, 3, W_)
            disc(cv, 11, 11, 1, (255, 255, 255))
        elif k == 2:
            for i in range(8):
                a = i * np.pi / 4 + 0.2
                ray(cv, 11, 11, a, 6, 10, Y_ if i % 2 else O_)
            disc(cv, 11, 11, 2, W_)
            for (dx, dy) in ((-9, 2), (8, -4), (3, 9), (-4, -9)):
                cv.px(11 + dx, 11 + dy, Y_)
        else:
            for i in range(8):
                a = i * np.pi / 4 + 0.35
                r = 9 + (i % 2)
                cv.px(11 + np.cos(a) * r, 11 + np.sin(a) * r, O_ if i % 2 else R_)
            cv.px(11, 11, Y_)
            cv.px(10, 11, O_)
            cv.px(11, 10, O_)
        fr.append(cv)
    return fr


def puff(cv, blobs, ramp, olc):
    m = np.zeros((cv.h, cv.w), bool)
    for (x, y, r) in blobs:
        m |= ell(cv, x - r, y - r, x + r, y + r)
    paint(cv, m, ramp, hl=2, sd=2, ol=True, olc=olc)
    return m


def dust():
    ramp = [(92, 70, 74), (128, 100, 98), (176, 146, 128), (214, 188, 156), (240, 220, 186)]
    olc = (70, 48, 62)
    seq = [
        [(8, 11, 2), (6, 12, 1)],
        [(6, 11, 3), (10, 10, 3), (8, 8, 2)],
        [(4, 11, 3), (9, 9, 4), (12, 11, 3)],
        [(3, 11, 2), (8, 7, 3), (13, 10, 3)],
        [(3, 12, 1), (7, 7, 2), (13, 8, 2)],
    ]
    fr = []
    for k, bl in enumerate(seq):
        cv = Cv(16, 16)
        m = puff(cv, bl, ramp, olc)
        if k >= 3:
            erode(cv, 0.25 if k == 3 else 0.5, 50 + k)
        fr.append(cv)
    return fr


def erode(cv, p, seed):
    rs = np.random.RandomState(seed)
    o = cv.opaque()
    holes = rs.rand(cv.h, cv.w) < p
    cv.a[o & holes] = 0


def steam():
    ramp = [(150, 164, 196), (190, 204, 226), (226, 236, 248), (246, 250, 255), (255, 255, 255)]
    olc = (96, 104, 150)
    seq = [
        [(12, 19, 2), (10, 20, 2), (14, 20, 2)],
        [(9, 18, 3), (13, 16, 3), (16, 19, 2), (12, 20, 2)],
        [(8, 15, 3), (13, 12, 4), (17, 16, 3), (11, 18, 3), (15, 19, 2)],
        [(7, 12, 3), (12, 9, 4), (17, 11, 3), (10, 15, 3), (15, 15, 3), (19, 15, 2)],
        [(6, 9, 3), (11, 6, 3), (17, 8, 3), (9, 12, 2), (15, 12, 3), (20, 12, 2)],
        [(6, 6, 2), (11, 4, 2), (17, 6, 2), (14, 9, 2)],
    ]
    pr = [0, 0, 0, 0.1, 0.3, 0.55]
    fr = []
    for k, bl in enumerate(seq):
        cv = Cv(24, 24)
        puff(cv, bl, ramp, olc)
        if pr[k] > 0:
            erode(cv, pr[k], 30 + k)
        fr.append(cv)
    return fr


def explosion():
    rs = np.random.RandomState(7)
    base = [(0, 0, 14), (-12, 6, 9), (12, 5, 10), (-5, -10, 9), (8, -11, 8), (-15, -3, 6), (16, -4, 6), (0, 12, 8)]
    cols = [(255, 250, 214), (255, 214, 80), (246, 128, 40), (190, 52, 56), (96, 38, 66), (58, 46, 72)]
    fr = []
    for k in range(8):
        cv = Cv(64, 64)
        grow = [0.25, 0.55, 0.85, 1.0, 1.0, 0.95, 0.85, 0.75][k]
        cx, cy = 32, 38 - (k * 1.6)
        m = np.zeros((64, 64), bool)
        for (dx, dy, r) in base:
            rr = max(2, int(r * grow))
            x = cx + dx * grow
            y = cy + dy * grow - (k * 0.7 if dy < 0 else 0)
            m |= ell(cv, int(x - rr), int(y - rr), int(x + rr), int(y + rr))
        ys, xs = np.nonzero(m)
        if len(xs) == 0:
            fr.append(cv)
            continue
        hot = [1.0, 0.95, 0.8, 0.55, 0.3, 0.1, -1, -1][k]
        for y, x in zip(ys, xs):
            d = np.hypot(x - cx, (y - cy) * 1.0) / 22.0
            d = d / max(0.3, grow)
            t = d + (0.15 if y > cy else -0.05) + (1 - hot) * 0.9
            if k >= 5:
                t = 4.0
            if t < 0.22:
                c = cols[0]
            elif t < 0.45:
                c = cols[1]
            elif t < 0.75:
                c = cols[2]
            elif t < 1.1:
                c = cols[3]
            elif t < 3.0:
                c = cols[4]
            else:
                c = cols[5]
            cv.px(x, y, c)
        if k >= 4:
            erode(cv, [0.18, 0.3, 0.5, 0.65][k - 4], 90 + k)
        edge = dil(cv.opaque()) & ~cv.opaque()
        cv.a[edge] = (74, 28, 56, 255) if k < 5 else (44, 34, 58, 255)
        if k < 7:
            for i in range(10):
                ang = rs.rand() * 6.283
                rad = 22 + rs.rand() * 8 * grow
                if k >= 1 and k <= 5:
                    cv.px(cx + np.cos(ang) * rad * (0.6 + 0.1 * k), cy + np.sin(ang) * rad * (0.6 + 0.1 * k) + k, (255, 214, 80) if i % 2 else (246, 128, 40))
        fr.append(cv)
    return fr


if __name__ == "__main__":
    for name, fr in (("hit_spark", hit_spark()), ("dust", dust()), ("steam_puff", steam()), ("explosion", explosion())):
        arr = sheet([fr])
        save(arr, "fx/%s.png" % name)
        preview(arr, name, 6 if name != "explosion" else 4)
        preview12(arr, name)
