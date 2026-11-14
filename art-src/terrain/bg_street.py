import numpy as np
from pix import Art, hx
from bgkit import *

H = 360
SKY = ["#0a0720", "#130c32", "#1f1042", "#34154f", "#561a58", "#8a2457", "#c03a4a", "#e8683a"]
FIRE = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]
GROUND = "#190e2a"


def lamp(a, x, gy, h, col, lit=None, bent=False, arm=1, rim=None):
    w = 2 if h < 60 else (3 if h < 120 else 4)
    top = gy - h
    if bent:
        kx = x + w // 2
        ky = gy - int(h * 0.55)
        a.rect(x, ky, x + w - 1, gy, col)
        tip = (kx + int(h * 0.42) * arm, ky - int(h * 0.32))
        a.line([(kx, ky), tip], col, w)
        hx_, hy_ = tip
        a.poly([(hx_ - 3, hy_ - 1), (hx_ + 5, hy_ - 2), (hx_ + 4, hy_ + 3), (hx_ - 2, hy_ + 3)], col)
        a.rect(x - 1, gy - max(3, h // 22), x + w, gy, col)
        return
    a.rect(x, top + 3, x + w - 1, gy, col)
    a.rect(x - 1, gy - max(3, h // 22), x + w, gy, col)
    cx = x + w // 2
    reach = max(8, int(h * 0.2)) * arm
    a.line([(cx, top + 4), (cx, top + 1), (cx + reach // 2, top - 1), (cx + reach, top + 3)], col, max(1, w - 1))
    hw = max(3, w + 1)
    a.poly([(cx + reach - hw, top + 2), (cx + reach + hw, top + 2), (cx + reach + hw - 1, top + 2 + max(2, hw - 1)), (cx + reach - hw + 1, top + 2 + max(2, hw - 1))], col)
    if lit:
        a.px(cx + reach, top + 3 + max(2, hw - 1), lit)
        if hw > 3:
            a.px(cx + reach - 1, top + 3 + max(2, hw - 1), lit)
    if rim:
        a.rect(x, top + 6, x, gy - 4, rim)


def sign_post(a, x, gy, h, col, face, kind="blade", lean=0, rim=None):
    w = 2 if h < 60 else 3
    tx = x + lean
    a.line([(x + w // 2, gy), (tx + w // 2, gy - h)], col, w)
    a.rect(x - 1, gy - 3, x + w, gy, col)
    if kind == "stop":
        r = max(5, h // 5)
        cx, cy = tx + w // 2, gy - h - r + 2
        a.poly([(cx - r // 2, cy - r), (cx + r // 2, cy - r), (cx + r, cy - r // 2), (cx + r, cy + r // 2), (cx + r // 2, cy + r), (cx - r // 2, cy + r), (cx - r, cy + r // 2), (cx - r, cy - r // 2)], col)
        a.rect(cx - r + 2, cy - 1, cx + r - 2, cy + 1, face)
    else:
        bw = max(12, h // 3)
        bh = max(4, h // 11)
        by = gy - h
        a.rect(tx - bw // 2 + w // 2, by, tx + bw // 2 + w // 2, by + bh, col)
        a.rect(tx - bw // 2 + w // 2 + 1, by + 1, tx + bw // 2 + w // 2 - 1, by + bh - 1, face)
        a.rect(tx - 2, by + bh + 3, tx + w + 3, by + bh + 3 + bh - 2, col)
        a.rect(tx - 1, by + bh + 4, tx + w + 2, by + bh + 2 + bh - 2, face)


def rubble_pile(a, x, gy, w, h, col, rng, rim=None):
    pts = [(x, gy)]
    n = max(3, w // 5)
    for i in range(1, n):
        t = i / n
        pts.append((x + int(w * t), gy - int(h * (0.35 + 0.65 * np.sin(np.pi * t)) * (0.6 + 0.4 * rng.random()))))
    pts.append((x + w, gy))
    a.poly(pts, col)
    for _ in range(max(1, w // 14)):
        rx = x + int(rng.integers(2, max(3, w - 2)))
        a.line([(rx, gy - int(h * 0.5)), (rx + int(rng.integers(-4, 5)), gy - h - int(rng.integers(3, 9)))], col)


def far():
    rng = np.random.default_rng(100)
    a = Art(640, H, base=SKY[0])
    a.hband(8, 256, SKY, sharp=2.5)
    a.rect(0, 256, 640, H, GROUND)
    a.rect(0, 256, 640, 258, "#2a1238")
    stars(a, rng, 70, 130, ["#e6e0ff", "#9d90d8", "#6a5ca8"])
    a.glow(110, 62, 34, "#b8a8ff", 0.0)
    m = a.mask("ellipse", 78, 30, 142, 94)
    a.stipple(m, "#3a2468", 0.28)
    m = a.mask("ellipse", 92, 44, 128, 80)
    a.stipple(m, "#4e3484", 0.35)
    a.ellipse(96, 48, 124, 76, "#e9e3cf")
    a.poly([(98, 56), (106, 50), (112, 52), (104, 60)], "#f6f1e0")
    a.ellipse(110, 56, 124, 76, "#cfc4ba")
    a.ellipse(97, 49, 118, 70, "#e9e3cf")
    for (cx, cy, r) in ((105, 62, 3), (100, 56, 2), (112, 55, 2)):
        a.ellipse(cx - r, cy - r, cx + r, cy + r, "#c9bfb4")
    low = "#241238"
    x = -10
    while x < 640:
        w = int(rng.integers(18, 46))
        rubble_pile(a, x, 258, w, int(rng.integers(4, 10)), low, rng)
        x += w + int(rng.integers(14, 60))
    for lx, hh, bent, lit in ((40, 34, False, None), (150, 30, True, None), (265, 36, False, "#ffb347"), (390, 31, False, None), (480, 33, True, None), (580, 35, False, None)):
        lamp(a, lx, 258, hh, "#2b1642", lit=lit, bent=bent, arm=1 if lx % 2 else -1)
    for sx, hh, kind in ((95, 22, "blade"), (205, 20, "stop"), (330, 24, "blade"), (440, 21, "stop"), (535, 23, "blade")):
        sign_post(a, sx, 258, hh, "#2b1642", "#3d1e55", kind=kind, lean=int(rng.integers(-2, 3)))
    for fx in (70, 300, 520):
        flame(a, fx, 258, 10, 3, ["#8a2457", "#c03a4a", "#e8683a", "#ffb347"])
    for gx, gy, r in ((70, 252, 70), (300, 252, 80), (520, 252, 70)):
        a.glow(gx, gy, r, "#ff8a3a", 0.4, ry=r * 0.45)
    a.rim_top("#7a2a5a", only=np.zeros((H, 640), bool))
    used = SKY + ["#2b1642", "#3d1e55", "#241238", "#ffb347", "#8a2457", "#c03a4a", "#e8683a", "#e6e0ff", "#9d90d8", "#6a5ca8", "#e9e3cf", "#f6f1e0", "#c9bfb4", "#cfc4ba", "#3a2468", "#4e3484", GROUND, "#2a1238"]
    pal = glow_palette(used, ["#ff8a3a"], (0.2, 0.4))
    return a.finish(pal)


def mid():
    rng = np.random.default_rng(200)
    W = 960
    a = Art(W, H)
    body, face, lit_c = "#1a0f2e", "#26153f", "#ffa23c"
    gy = 322
    fires = []
    x = 20
    while x < W - 60:
        w = int(rng.integers(30, 80))
        h = int(rng.integers(8, 26))
        rubble_pile(a, x, gy + 2, w, h, body, rng)
        a.rect(x + 2, gy - 2, x + w // 3, gy + 2, face)
        if rng.random() < 0.55:
            fires.append((x + w // 2, gy - h + 4))
        x += w + int(rng.integers(40, 110))
    for lx, hh, bent, lit, arm in ((60, 92, False, None, 1), (250, 84, True, None, 1), (410, 96, False, lit_c, -1), (560, 88, False, None, 1), (790, 90, True, None, -1), (900, 86, False, lit_c, 1)):
        lamp(a, lx, gy + 2, hh, "#12091f", lit=lit, bent=bent, arm=arm, rim="#26153f")
    for sx, hh, kind, ln in ((170, 56, "blade", 1), (330, 50, "stop", -2), (480, 58, "blade", -1), (700, 52, "stop", 2), (850, 55, "blade", 0)):
        sign_post(a, sx, gy + 2, hh, "#12091f", "#2a1646", kind=kind, lean=ln)
    for (fx, fy) in fires:
        smoke(a, fx, fy - 6, rng, 10, "#34224a", drift=3.2, r0=5, grow=1.7, cov0=0.7)
    for (fx, fy) in fires:
        flame(a, fx, fy + 6, int(rng.integers(16, 26)), 5, FIRE, lean=1)
        a.glow(fx, fy - 2, 56, "#ff8a3a", 0.4, halo="#7a2a4a", ry=42)
    ground(a, 322, "#150b26", "#5a2646", rng, bumps=18, bump_h=8)
    cx0 = 640
    pts = [(cx0 + i, 322 + int(26 * (1 - ((i - 80) / 80.0) ** 2))) for i in range(0, 161, 4)]
    a.poly([(cx0, 322)] + pts + [(cx0 + 160, 322)], "#6a1e46")
    a.poly([(cx0 + 12, 326)] + [(px, py - 2) for px, py in pts[3:-3]] + [(cx0 + 148, 326)], "#c03a4a")
    a.poly([(cx0 + 32, 332)] + [(px, py - 4) for px, py in pts[6:-6]] + [(cx0 + 128, 332)], "#f06a2a")
    a.rect(cx0 + 60, 346, cx0 + 100, 346, "#ffb347")
    a.glow(cx0 + 80, 336, 90, "#ff8a3a", 0.5, halo="#7a2a4a", ry=50)
    a.rect(0, 336, W, H, "#150b26")
    for rx in (cx0 - 8, cx0 + 156):
        a.poly([(rx, 322), (rx + 8, 314), (rx + 14, 322)], "#26153f")
    for rx in (cx0 + 6, cx0 + 140):
        a.line([(rx, 322), (rx + 4, 306)], "#0f0820")
        a.line([(rx + 3, 322), (rx + 9, 308)], "#0f0820")
    pal = glow_palette([body, face, "#150b26", "#0f0820", "#26153f", "#5a2646"], ["#ff8a3a"], (0.18, 0.36, 0.6)) + [hx(c) for c in FIRE + ["#ffa23c", "#e8683a", "#6a1e46", "#c03a4a", "#f06a2a", "#12091f", "#2a1646", "#34224a", "#7a2a4a", "#ffb347"]]
    return a.finish(pal)


def near():
    rng = np.random.default_rng(300)
    W = 960
    a = Art(W, H)
    dk, rim = "#0d0816", "#4a2038"
    ground(a, 340, dk, rim, rng, bumps=26, bump_h=14, bump_w=(20, 60))
    for lx, hh, bent, lit, arm in ((90, 196, False, None, 1), (470, 188, True, None, 1), (820, 200, False, "#ffb347", -1)):
        lamp(a, lx, 340, hh, dk, lit=lit, bent=bent, arm=arm, rim="#2a1428")
    sign_post(a, 290, 340, 120, dk, "#2a1a38", kind="blade", lean=3)
    sign_post(a, 650, 340, 72, dk, "#3a1a30", kind="stop", lean=-5)
    a.line([(700, 340), (742, 332)], dk, 3)
    for (rx, ry) in ((200, 340), (560, 340), (730, 340), (905, 340)):
        for k in range(4):
            a.line([(rx + k * 4, ry), (rx + k * 4 + int(rng.integers(-5, 6)), ry - int(rng.integers(20, 44)))], dk)
        a.poly([(rx - 10, ry), (rx - 4, ry - 12), (rx + 8, ry - 14), (rx + 22, ry)], dk)
    a.rim_top(rim)
    a.glow(150, 330, 160, "#ff8a3a", 0.18, halo="#3a1a34", ry=60)
    pal = glow_palette([dk, rim, "#2a1428", "#1c1028", "#2a1a38", "#6a2a38"], ["#ff8a3a"], (0.2, 0.4)) + [hx(c) for c in ("#3a1a30", "#ffb347")]
    return a.finish(pal)
