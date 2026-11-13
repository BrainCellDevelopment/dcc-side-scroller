import numpy as np
from pix import Art, hx
from bgkit import *

H = 360
SKY = ["#0a0720", "#130c32", "#1f1042", "#34154f", "#561a58", "#8a2457", "#c03a4a", "#e8683a"]
FIRE = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]
GROUND = "#190e2a"


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
    a.ellipse(96, 48, 124, 76, "#e9e3cf")
    a.poly([(98, 56), (106, 50), (112, 52), (104, 60)], "#f6f1e0")
    for (cx, cy, r) in ((112, 62, 3), (104, 68, 2), (117, 55, 2)):
        a.ellipse(cx - r, cy - r, cx + r, cy + r, "#c9bfb4")
    a.ellipse(110, 56, 124, 76, "#cfc4ba")
    a.ellipse(97, 49, 118, 70, "#e9e3cf")
    for (cx, cy, r) in ((105, 62, 3), (100, 56, 2), (112, 55, 2)):
        a.ellipse(cx - r, cy - r, cx + r, cy + r, "#c9bfb4")
    cols = ["#2b1642", "#33194a"]
    x = -10
    while x < 640:
        w = int(rng.integers(14, 34))
        top = int(rng.integers(170, 225))
        ruin(a, x, w, top, 262, cols[int(rng.integers(0, 2))], "#3d1e55", rng, "#ffb347", "#241238", "#3a1c58", lit_p=0.06, cell=(8, 10), jitter=14, face_w=0.3)
        x += w + int(rng.integers(0, 6))
    for fx in (60, 250, 420, 560):
        flame(a, fx, 214, 14, 4, ["#8a2457", "#c03a4a", "#e8683a", "#ffb347"])
    a.rim_top("#7a2a5a", only=np.zeros((H, 640), bool))
    for gx, gy, r in ((70, 230, 90), (260, 235, 120), (430, 232, 100), (570, 238, 90)):
        a.glow(gx, gy, r, "#ff8a3a", 0.42, ry=r * 0.7)
    pal = glow_palette(SKY + ["#2b1642", "#33194a", "#3d1e55", "#241238", "#ffb347", "#8a2457", "#c03a4a", "#e8683a", "#e6e0ff", "#9d90d8", "#6a5ca8", "#e9e3cf", "#f6f1e0", "#c9bfb4", "#cfc4ba", "#3a2468", "#4e3484", GROUND, "#2a1238"], ["#ff8a3a"], (0.2, 0.4))
    return a.finish(pal)


def mid():
    rng = np.random.default_rng(200)
    W = 960
    a = Art(W, H)
    body, face = "#1a0f2e", "#26153f"
    spots = []
    x = 0
    while x < W - 20:
        w = int(rng.integers(44, 96))
        if x + w > W:
            w = W - x
        top = int(rng.integers(165, 270))
        ruin(a, x, w, top, 340, body, face, rng, "#ffa23c", "#0f0820", "#2a1646", lit_p=0.045, jitter=34)
        spots.append((x, w, top))
        x += w + int(rng.integers(-4, 26))
    for (x, w, top) in spots:
        for _ in range(int(rng.integers(1, 4))):
            rx = x + int(rng.integers(3, max(4, w - 3)))
            a.line([(rx, top + 2), (rx + int(rng.integers(-3, 4)), top - int(rng.integers(6, 16)))], "#12091f")
    fires = [(spots[i][0] + spots[i][1] // 2, spots[i][2] + 4) for i in (1, 3, 5, 7, 9) if i < len(spots)]
    for (fx, fy) in fires:
        smoke(a, fx, fy - 18, rng, 11, "#34224a", drift=3.2, r0=5, grow=1.7, cov0=0.7)
    for (fx, fy) in fires:
        flame(a, fx, fy + 3, int(rng.integers(20, 30)), 6, FIRE, lean=1)
        a.glow(fx, fy - 6, 60, "#ff8a3a", 0.4, halo="#7a2a4a", ry=48)
    ground(a, 322, "#150b26", "#5a2646", rng, bumps=26, bump_h=14)
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
    pal = glow_palette([body, face, "#150b26", "#0f0820", "#26153f", "#5a2646"], ["#ff8a3a"], (0.18, 0.36, 0.6)) + [hx(c) for c in FIRE + ["#ffa23c", "#e8683a", "#6a1e46", "#c03a4a", "#f06a2a", "#12091f"]]
    img = a.finish(pal)
    return img


def near():
    rng = np.random.default_rng(300)
    W = 960
    a = Art(W, H)
    dk, rim = "#0d0816", "#4a2038"
    ground(a, 340, dk, rim, rng, bumps=30, bump_h=18, bump_w=(20, 60))
    px_ = [90, 470, 820]
    for x in px_:
        a.rect(x, 150, x + 4, 340, dk)
        a.rect(x - 14, 160, x + 18, 163, dk)
        a.rect(x - 10, 176, x + 14, 178, dk)
        a.rect(x - 1, 150, x - 1, 340, "#2a1428")
    for i in range(len(px_)):
        x0 = px_[i] + 18
        x1 = px_[(i + 1) % len(px_)] - 14 + (W if i == len(px_) - 1 else 0)
        catenary(a, x0, 162, x1, 162, 22, dk)
        catenary(a, x0, 177, x1, 177, 18, dk)
        catenary(a, x0, 163, x1, 163, 22, dk)
    lamp = 300
    a.rect(lamp, 120, lamp + 3, 340, dk)
    a.line([(lamp + 2, 122), (lamp + 18, 118), (lamp + 30, 126)], dk, 3)
    a.poly([(lamp + 24, 128), (lamp + 38, 128), (lamp + 36, 136), (lamp + 26, 136)], dk)
    a.px(lamp + 29, 134, "#6a2a38")
    a.px(lamp + 33, 134, "#6a2a38")
    cx = 640
    a.poly([(cx, 340), (cx + 6, 316), (cx + 22, 304), (cx + 48, 302), (cx + 66, 312), (cx + 84, 316), (cx + 96, 340)], dk)
    a.poly([(cx + 24, 304), (cx + 32, 290), (cx + 56, 290), (cx + 64, 308)], dk)
    for wx in (cx + 14, cx + 70):
        a.ellipse(wx - 9, 322, wx + 9, 340, dk)
        a.ellipse(wx - 4, 327, wx + 4, 335, "#2a1428")
    a.rect(cx + 34, 294, cx + 52, 300, "#2a1a38")
    a.rect(cx + 8, 330, cx + 90, 332, "#1c1028")
    for (rx, ry) in ((200, 340), (560, 340), (730, 340), (905, 340)):
        for k in range(4):
            a.line([(rx + k * 4, ry), (rx + k * 4 + int(rng.integers(-5, 6)), ry - int(rng.integers(20, 44)))], dk)
        a.poly([(rx - 10, ry), (rx - 4, ry - 12), (rx + 8, ry - 14), (rx + 22, ry)], dk)
    a.rim_top(rim)
    a.glow(150, 330, 160, "#ff8a3a", 0.18, halo="#3a1a34", ry=60)
    pal = glow_palette([dk, rim, "#2a1428", "#1c1028", "#2a1a38", "#6a2a38"], ["#ff8a3a"], (0.2, 0.4))
    return a.finish(pal)
