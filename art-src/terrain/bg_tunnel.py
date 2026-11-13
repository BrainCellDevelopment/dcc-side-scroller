import numpy as np
from pix import Art, hx
from bgkit import *

H = 360
FIRE = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]
BOT = "#0d1020"


def far():
    rng = np.random.default_rng(120)
    a = Art(640, H, base="#0b0e1b")
    a.rect(0, 8, 640, 256, "#161c32")
    tones = ["#161c32", "#1a2038", "#1e2540", "#141a2e"]
    for r in range(0, 21):
        y0 = 8 + r * 12
        off = (r % 2) * 16
        for bx in range(-32, 640, 32):
            x = bx + off
            t = tones[int(rng.integers(0, 4))]
            a.rect(x + 1, y0 + 1, x + 31, min(256, y0 + 11), t)
            a.rect(x + 1, y0 + 1, x + 31, y0 + 1, "#232c4a")
        a.rect(0, y0, 640, y0, "#0e1222")
        for bx in range(-32, 640, 32):
            a.rect(bx + off, y0, bx + off, y0 + 11, "#0e1222")
    for px in (130, 450):
        a.ellipse(px - 53, 86, px + 53, 170, "#262e50")
        a.rect(px - 53, 128, px + 53, 256, "#262e50")
        a.ellipse(px - 47, 92, px + 47, 166, "#07080f")
        a.rect(px - 47, 128, px + 47, 256, "#07080f")
        ys = np.arange(H)[:, None] * np.ones((1, 640))
        m = a.mask("rect", px - 47, 150, px + 47, 255)
        a.stipple(m, "#0e1222", np.clip((ys - 150) / 100.0, 0, 1) * 0.7)
        a.rect(px + 8, 196, px + 9, 198, "#ffcf7a")
        a.rect(px + 7, 199, px + 10, 201, "#b8322e")
        a.glow(px + 9, 198, 36, "#ffb050", 0.6)
        a.rect(px - 47, 252, px + 47, 256, "#161a2c")
    a.rect(0, 256, 640, H, BOT)
    a.rect(0, 256, 640, 257, "#232c4c")
    a.rect(0, 258, 640, 258, "#161c32")
    for k in range(16):
        x = int(rng.integers(0, 640))
        y = int(rng.integers(20, 180))
        ln = int(rng.integers(14, 50))
        a.rect(x, y, x, y + ln, "#262f50")
    ys = np.arange(H)[:, None] * np.ones((1, 640))
    a.stipple(a.mask("rect", 0, 8, 640, 70), "#0b0e1b", np.clip((70 - ys) / 62.0, 0, 1) * 0.75)
    for (mx, my) in ((40, 140), (300, 100), (560, 170), (220, 210), (380, 230)):
        for _ in range(5):
            a.px(mx + int(rng.integers(-3, 4)), my + int(rng.integers(-2, 3)), "#25503a")
    base = ["#161c32", "#1a2038", "#1e2540", "#141a2e", "#0b0e1b", "#07080f", "#262e50", "#0e1222", "#232c4a", "#0d1020", "#262f50", "#161a2c"]
    return a.finish(glow_palette(base, ["#ffb050"], (0.2, 0.4, 0.6)) + [hx("#25503a"), hx("#ffcf7a"), hx("#b8322e")])


def mid():
    rng = np.random.default_rng(220)
    W = 960
    a = Art(W, H)
    body, ring, dk = "#1b2240", "#2e3860", "#10152a"
    a.rect(0, 0, W, 58, body)
    pillars = [100 + 320 * k for k in range(3)]
    for k, px in enumerate(pillars):
        cx = px + 17 + 160
        yy = np.arange(H)[:, None]
        big = a.mask("ellipse", cx - 145, 58 - 56, cx + 145, 58 + 56) & (yy <= 58)
        a.fill_mask(big, ring)
        sm = a.mask("ellipse", cx - 139, 58 - 50, cx + 139, 58 + 50) & (yy <= 58)
        a.erase(sm)
        for _ in range(9):
            sx = int(rng.integers(cx - 120, cx + 120))
            curve = 58 - 50 * np.sqrt(max(0.0, 1 - ((sx - cx) / 139.0) ** 2))
            ln = int(rng.integers(5, 15))
            a.poly([(sx - 2, int(curve) - 1), (sx + 2, int(curve) - 1), (sx, int(curve) + ln)], ring)
    for px in pillars:
        a.rect(px, 0, px + 34, H, body)
        a.rect(px, 0, px + 7, H, "#2c3658")
        a.rect(px + 29, 0, px + 34, H, dk)
        for by in range(14, 330, 14):
            a.rect(px, by, px + 34, by, dk)
            jx = px + 8 + (by // 14 % 3) * 7
            a.rect(jx, by - 13, jx, by, dk)
        a.rect(px - 5, 56, px + 39, 72, "#232b4c")
        a.rect(px - 5, 56, px + 39, 57, "#3a4670")
        a.rect(px - 5, 71, px + 39, 72, dk)
        a.rect(px - 4, 290, px + 38, 304, "#232b4c")
        a.rect(px - 4, 290, px + 38, 291, "#3a4670")
        a.rect(px + 4, 130, px + 5, 134, "#1a1008")
    for px in pillars:
        for (ly, lx) in ((180, px - 3), (190, px + 38)):
            pass
        tx = px + 17
        a.rect(tx - 4, 172, tx + 4, 174, "#3a2c24")
        a.rect(tx - 2, 174, tx + 2, 190, "#4a3220")
        a.rect(tx - 3, 190, tx + 3, 193, "#3a2c24")
        a.rect(tx - 2, 160, tx + 2, 172, "#5a3a22")
        flame(a, tx, 168, 17, 5, FIRE, lean=0)
        a.glow(tx, 160, 84, "#ff9a3c", 0.62, halo="#5a3a22", ry=76)
        for _ in range(4):
            lx = px + int(rng.integers(2, 30))
            ly = int(rng.integers(220, 290))
            for _ in range(5):
                a.px(lx + int(rng.integers(-2, 3)), ly + int(rng.integers(-2, 3)), "#3f8a46")
            a.px(lx, ly, "#8adf6a")
            a.glow(lx, ly, 9, "#8adf6a", 0.25, halo="#2a5a3a")
    for cx in (330, 600, 880):
        chain(a, cx, 30, 90 + cx % 40, "#3a4468", "#232b4c")
    ground(a, 300, "#12172c", "#323f68", rng, bumps=18, bump_h=10)
    for x in range(0, W, 60):
        a.rect(x, 300, x, 340, "#0a0d1c")
    a.rect(0, 340, W, H, "#12172c")
    pal = glow_palette([body, ring, dk, "#2c3658", "#232b4c", "#3a4670", "#12172c", "#323f68", "#4a3220", "#3a4468"], ["#ff9a3c"], (0.15, 0.3, 0.5)) + [hx(c) for c in FIRE + ["#3f8a46", "#8adf6a", "#5a3a22", "#5a3a22", "#3a2c24", "#1a1008", "#0a0d1c", "#2a5a3a"]]
    return a.finish(pal)


def near():
    rng = np.random.default_rng(320)
    W = 960
    a = Art(W, H)
    dk = "#090c18"
    for _ in range(26):
        x = int(rng.integers(0, W))
        w = int(rng.integers(6, 16))
        ln = int(rng.integers(12, 42))
        a.poly([(x, 0), (x + w, 0), (x + w // 2, ln)], dk)
    a.rect(0, 0, W, 6, dk)
    for px in (200, 700):
        a.rect(px, 0, px + 58, H, dk)
        a.rect(px, 0, px + 1, H, "#4a3426")
        a.rect(px + 1, 0, px + 2, H, "#2a1c1c")
        for by in range(20, 340, 22):
            a.rect(px + 4, by, px + 58, by, "#04050b")
        a.rect(px - 6, 0, px + 64, 14, "#0c1020")
        a.rect(px - 6, 0, px + 64, 1, "#232c4c")
    cx = 460
    chain(a, cx, 6, 110, "#05070e", "#1a2038", thick=2)
    a.rect(cx - 7, 110, cx + 9, 130, dk)
    a.rect(cx - 5, 114, cx + 7, 126, "#ffb347")
    a.rect(cx - 3, 116, cx + 5, 124, "#ffe27a")
    a.rect(cx - 1, 110, cx + 1, 130, dk)
    a.glow(cx + 1, 120, 78, "#ffb050", 0.6, halo="#5a3a22", ry=70)
    ground(a, 344, dk, "#1c2442", rng, bumps=20, bump_h=22, bump_w=(16, 44))
    for x in range(0, W, 5):
        pass
    for _ in range(12):
        x = int(rng.integers(0, W))
        a.rect(x, 18, x, 26, "#2a3a5a")
        a.px(x, 27, "#6a8ab0")
    a.rim_top("#262e50", only=np.zeros((H, W), bool))
    pal = glow_palette([dk, "#4a3426", "#2a1c1c", "#04050b", "#0c1020", "#1c2442"], ["#ffb050"], (0.25, 0.5)) + [hx(c) for c in ("#232c4c", "#05070e", "#1a2038", "#ffb347", "#ffe27a", "#5a3a22", "#2a3a5a", "#6a8ab0")]
    return a.finish(pal)
