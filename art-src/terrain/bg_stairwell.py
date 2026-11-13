import numpy as np
from pix import Art, hx
from bgkit import *

H = 360
FIRE = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]
BOT = "#0a1020"


def far():
    rng = np.random.default_rng(110)
    a = Art(640, H, base="#070b16")
    a.hband(8, 256, ["#070b16", "#0b1226", "#101a36", "#17264a"], sharp=2.5)
    a.rect(0, 256, 640, H, BOT)
    a.rect(0, 256, 640, 257, "#1c2c52")
    for k in range(4):
        cx = 80 + k * 160
        a.rect(cx - 70, 20, cx + 70, 256, "#0c1428")
    for k in range(4):
        cx = 80 + k * 160
        a.ellipse(cx - 62, 24, cx + 62, 150, "#1a2a52")
        a.rect(cx - 62, 88, cx + 62, 256, "#1a2a52")
        a.ellipse(cx - 56, 30, cx + 56, 144, "#080d1a")
        a.rect(cx - 56, 88, cx + 56, 256, "#080d1a")
        ys = np.arange(H)[:, None] * np.ones((1, 640))
        m = a.mask("rect", cx - 56, 150, cx + 56, 255)
        a.stipple(m, "#101a34", np.clip((ys - 150) / 100.0, 0, 1) * 0.8)
        a.stipple(a.mask("rect", cx - 56, 200, cx + 56, 255), "#16254a", np.clip((ys - 200) / 60.0, 0, 1) * 0.6)
    for k in range(4):
        cx = 80 + k * 160
        a.rect(cx + 70 - 14, 20, cx + 70 + 14, 256, "#0c1428")
        a.rect(cx + 70 - 14, 20, cx + 70 - 11, 256, "#16264a")
        a.rect(cx + 70 - 1, 20, cx + 70 + 14, 256, "#0a1122")
    for k in range(4):
        cx = 80 + k * 160
        x0 = cx - 50
        for i in range(10):
            sx = x0 + i * 10
            sy = 170 + i * 8
            a.rect(sx, sy, sx + 9, sy + 1, "#2a4070")
            a.rect(sx, sy + 2, sx + 9, 256, "#10193a")
        a.line([(x0, 140), (x0 + 99, 220)], "#3a5488")
        for i in range(0, 100, 20):
            a.line([(x0 + i, 140 + i * 0.8), (x0 + i, 150 + i * 0.8)], "#2a4070")
    lamps = [(70, 120), (150, 190), (250, 100), (330, 205), (410, 130), (490, 185), (570, 110), (620, 200), (30, 195), (200, 150)]
    for (lx, ly) in lamps:
        a.rect(lx, ly, lx + 1, ly + 1, "#ffcf7a")
        a.glow(lx, ly, 22, "#ffb050", 0.6)
    a.stipple(a.mask("ellipse", -40, 205, 680, 285), "#1f3560", 0.22)
    a.stipple(a.mask("ellipse", -40, 225, 680, 270), "#2a4478", 0.2)
    for k in range(8):
        x = int(rng.integers(0, 640))
        y = int(rng.integers(20, 60))
        chain(a, x, 20, y + 60, "#1c2c52", "#10193a")
    base = ["#070b16", "#0c1428", "#080d1a", "#1a2a52", "#10193a", "#16254a", "#2a4070", "#3a5488", "#1c2c52", "#0b1226", "#101a36", "#17264a", "#16264a", "#0a1122", BOT, "#1f3560", "#2a4478", "#ffcf7a"]
    return a.finish(glow_palette(base, ["#ffb050"], (0.2, 0.4, 0.65)))


def mid():
    rng = np.random.default_rng(210)
    W = 960
    a = Art(W, H)
    body, rimc, dk = "#0e1730", "#223662", "#070d1c"
    for k in range(4):
        cx = 120 + k * 240 + 20
        for sx in range(cx - 120, cx - 119):
            pass
    for x in range(0, W, 8):
        pass
    a.rect(0, 0, W, 64, body)
    for k in range(4):
        px = 100 + k * 240
        cx = px + 20 + 120
        big = a.mask("ellipse", cx - 98, 64 - 57, cx + 98, 64 + 57) & (np.arange(H)[:, None] <= 64)
        a.fill_mask(big, rimc)
        sm = a.mask("ellipse", cx - 92, 64 - 51, cx + 92, 64 + 51) & (np.arange(H)[:, None] <= 64)
        a.erase(sm)
    for k in range(4):
        px = 100 + k * 240
        a.rect(px - 22, 0, px + 62, 14, "#0c1428")
    cat = 236
    for x in range(0, W, 8):
        a.rect(x, 214, x, cat, "#1a2c52")
    a.rect(0, 212, W, 213, "#3a5488")
    a.rect(0, 214, W, 214, "#223662")
    a.rect(0, cat, W, cat + 7, body)
    a.rect(0, cat, W, cat, "#2a4070")
    for x in range(0, W, 24):
        a.line([(x, cat + 8), (x + 24, cat + 36)], "#162545")
        a.line([(x + 24, cat + 8), (x, cat + 36)], "#162545")
    a.rect(0, cat + 8, W, cat + 8, "#162545")
    a.rect(0, cat + 36, W, cat + 37, "#162545")
    for k in range(4):
        px = 100 + k * 240
        a.rect(px, 0, px + 40, H, body)
        a.rect(px, 0, px + 6, H, "#1a2a4c")
        a.rect(px + 36, 0, px + 40, H, dk)
        for by in range(30, 340, 48):
            a.rect(px, by, px + 40, by + 3, dk)
            a.rect(px, by + 4, px + 40, by + 4, "#1a2a4c")
            for rx in (px + 4, px + 18, px + 32):
                a.px(rx, by + 1, "#3a5a96")
        a.rect(px - 6, 56, px + 46, 70, "#162545")
        a.rect(px - 6, 56, px + 46, 57, "#2a4070")
        a.rect(px - 6, 69, px + 46, 70, dk)
    lamps = []
    for k in range(4):
        lx = 100 + k * 240 + 20 + 120
        lamps.append(lx)
        chain(a, lx, 8, 112, "#2a3c66", "#162545")
        a.poly([(lx - 7, 126), (lx + 7, 126), (lx + 4, 112), (lx - 4, 112)], "#1a2a4c")
        a.rect(lx - 7, 126, lx + 7, 127, dk)
        a.rect(lx - 3, 128, lx + 3, 131, "#ffd27a")
        a.rect(lx - 2, 129, lx + 2, 130, "#fff0b0")
    for lx in lamps:
        a.glow(lx, 128, 78, "#ffb050", 0.6, halo="#6a4420", ry=70)
        cone = a.mask("poly", [(lx - 4, 133), (lx + 4, 133), (lx + 58, 250), (lx - 58, 250)])
        a.stipple_under(cone, "#4a3a36", 0.16)
    ground(a, 300, "#0a1020", "#2a4070", rng, bumps=0)
    for x in range(0, W, 48):
        a.rect(x, 300, x, H, "#162545")
    a.rect(0, 340, W, H, "#0a1020")
    pal = glow_palette([body, rimc, dk, "#1a2a4c", "#162545", "#2a4070", "#3a5488", "#0c1428", "#2a3c66", "#0a1020", "#4a3a36"], ["#ffb050"], (0.15, 0.3, 0.5)) + [hx(c) for c in ("#ffd27a", "#fff0b0", "#3a5a96", "#6a4420")]
    return a.finish(pal)


def near():
    rng = np.random.default_rng(310)
    W = 960
    a = Art(W, H)
    dk, rim = "#070b14", "#26385c"
    a.rect(0, 0, W, 17, dk)
    a.rect(0, 5, W, 5, "#1a2a4c")
    for x in range(40, W, 160):
        a.rect(x, 0, x + 10, 22, "#04070e")
        a.rect(x + 2, 22, x + 8, 30, dk)
    x0, y0 = 160, 90
    n = 28
    top = []
    for i in range(n):
        top += [(x0 + i * 14, y0 + i * 8), (x0 + (i + 1) * 14, y0 + i * 8)]
    bot = [(x0 + n * 14 - 6, y0 + n * 8 + 30), (x0 - 2, y0 + 30)]
    a.poly(top + bot, dk)
    for i in range(0, n, 3):
        px = x0 + i * 14 + 6
        py = y0 + i * 8
        a.rect(px, py - 28, px + 1, py, dk)
    a.line([(x0 + 6, y0 - 28), (x0 + n * 14 - 8, y0 + (n - 1) * 8 - 28)], dk, 2)
    for cx in (620, 700, 760):
        chain(a, cx, 17, 150 + (cx % 3) * 20, dk, "#1a2a4c", thick=2)
        a.rect(cx - 3, 150 + (cx % 3) * 20, cx + 5, 158 + (cx % 3) * 20, dk)
    lx = 840
    a.rect(lx, 190, lx + 4, 344, dk)
    a.rect(lx - 6, 330, lx + 10, 344, dk)
    a.line([(lx + 2, 192), (lx + 16, 186), (lx + 28, 194)], dk, 3)
    a.poly([(lx + 20, 196), (lx + 36, 196), (lx + 34, 206), (lx + 22, 206)], dk)
    a.rect(lx + 24, 204, lx + 32, 207, "#ffcf7a")
    a.glow(lx + 28, 206, 70, "#ffb050", 0.55, halo="#5a3a20", ry=60)
    ground(a, 344, dk, "#1c2c4c", rng, bumps=10, bump_h=10, bump_w=(20, 50))
    for x in range(0, W, 36):
        a.rect(x, 346, x + 1, 352, "#0c1220")
    a.rim_top(rim, only=np.zeros((H, W), bool))
    pal = glow_palette([dk, rim, "#1a2a4c", "#04070e", "#1c2c4c", "#0c1220"], ["#ffb050"], (0.25, 0.5)) + [hx(c) for c in ("#ffcf7a", "#5a3a20")]
    return a.finish(pal)
