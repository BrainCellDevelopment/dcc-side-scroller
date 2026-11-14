"""Floor 1 backgrounds: bg_floor1 (neighborhood tunnel), bg_floor1_artery, bg_floor1_corridor.

Each style has far (640 wide), mid and near (960 wide) layers, all 360 tall and
horizontally seamless, loaded by scripts/level/background.gd.
Run: python3 art-src/floor1/gen_bg_floor1.py [style ...]
"""
import os
import sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "terrain"))
sys.path.insert(0, HERE)
from pix import Art, hx, ncolors  # noqa: E402
from bgkit import glow_palette, chain, ground, force_rows  # noqa: E402
import palette as P  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "bg")) + "/"
H = 360
B, L, T, N, W = P.BRICK, P.LICHEN, P.TORCH, P.BONE, P.WET

# fill colours used by background.gd above/below each layer, per style
EXT = {
    "floor1": (B[0], "#0e0709", "#150a0d", "#0a0507"),
    "floor1_artery": ("#10080b", "#160b0d", "#1a0d0f", "#0b0608"),
    "floor1_corridor": ("#08040a", "#0d0708", "#120a0c", "#08040a"),
}


def brick_wall(a, rng, y0, y1, tones, bh=12, bw=32, mortar=B[0], hi=None):
    rows = (y1 - y0) // bh + 1
    for r in range(rows):
        y = y0 + r * bh
        off = (r % 2) * (bw // 2)
        for bx in range(-bw, a.w + bw, bw):
            x = bx + off
            t = tones[int(rng.integers(0, len(tones)))]
            a.rect(x + 1, y + 1, x + bw - 1, min(y1, y + bh - 1), t)
            if hi:
                a.rect(x + 1, y + 1, x + bw - 1, y + 1, hi)
        a.rect(0, y, a.w, y, mortar)
        for bx in range(-bw, a.w + bw, bw):
            a.rect(bx + off, y, bx + off, min(y1, y + bh - 1), mortar)
    a.rect(0, y1, a.w, y1 + 1, mortar)


def lichen(a, rng, x, y, n=7, spread=5, drip=True):
    """Glowing lichen blob (call a.glow separately). Sits ON a surface at y (grows upward)."""
    for _ in range(n):
        px = x + int(rng.integers(-spread, spread + 1))
        py = y - int(rng.integers(0, max(2, spread // 2 + 1)))
        a.px(px, py, L[1])
        a.px(px + 1, py, L[2])
        if rng.random() < 0.5:
            a.px(px, py - 1, L[2])
    for _ in range(max(2, n // 2)):
        a.px(x + int(rng.integers(-spread, spread + 1)), y - int(rng.integers(0, 3)), L[3])
    a.px(x, y - 1, L[4])
    if drip:
        for _ in range(2):
            dx = x + int(rng.integers(-spread, spread + 1))
            for k in range(int(rng.integers(2, 6))):
                a.px(dx, y + 1 + k, L[1] if k > 1 else L[2])


def wall_lichen(a, rng, x, y, glow=26, n=9, spread=6, strength=0.5):
    lichen(a, rng, x, y, n, spread)
    a.glow(x, y - 2, glow, GREENGLOW, strength, halo=L[0], ry=int(glow * 0.8))


def torch(a, x, y, big=True, strength=0.7, r=70):
    a.rect(x - 4, y + 10, x + 4, y + 12, N[0])
    a.rect(x - 2, y, x + 2, y + 12, P.PLANK[1])
    a.rect(x - 3, y - 4, x + 3, y, P.IRON[1])
    a.rect(x - 4, y - 4, x - 4, y - 3, P.IRON[3])
    from bgkit import flame
    flame(a, x, y - 3, 17 if big else 11, 5 if big else 3, [T[0], T[1], T[3], T[4]], lean=0)
    a.glow(x, y - 10, r, T[2], strength, halo=T[0], ry=int(r * 0.9))


def arch_opening(a, cx, top, bot, half, ring, inner, rng):
    yy = np.arange(a.h)[:, None] * np.ones((1, a.w))
    a.ellipse(cx - half - 6, top - 6, cx + half + 6, top + half * 2 - 6, ring)
    a.rect(cx - half - 6, top + half - 6, cx + half + 6, bot, ring)
    a.ellipse(cx - half, top, cx + half, top + half * 2, inner)
    a.rect(cx - half, top + half, cx + half, bot, inner)
    m = a.mask("rect", cx - half, top + half, cx + half, bot)
    # voussoir ticks around the arch
    for k in range(-4, 5):
        ang = np.pi * (0.5 + k / 9.0)
        rx = (half + 3) * np.cos(ang)
        ry = (half + 3) * np.sin(ang)
        a.px(cx + int(rx), top + half - int(ry), B[1])
        a.px(cx + int(rx * 1.07), top + half - int(ry * 1.07), B[5])


def vignette_top(a, y0, y1, col, strength=0.8):
    ys = np.arange(a.h)[:, None] * np.ones((1, a.w))
    a.stipple(a.mask("rect", 0, y0, a.w, y1), col, np.clip((y1 - ys) / float(y1 - y0), 0, 1) * strength)


def pal_for(base, glows, extra):
    return glow_palette(base, glows, (0.25, 0.5)) + [hx(c) for c in extra]


GREENGLOW = "#46b868"
GL = [GREENGLOW, T[2]]
BASE_COMMON = [B[1], B[2], B[3], B[0], P.OUTLINE, B[4], B[5], W[0], W[1]]
EXTRA_COMMON = [L[0], L[1], L[2], L[3], L[4], T[0], T[1], T[2], T[3], T[4], N[0], N[1], P.PLANK[1], P.IRON[1], P.IRON[2], P.IRON[3], "#10080b", "#160b0d", "#1a0d0f"]


# ------------------------------------------------------------------ floor1 (neighborhood tunnel)
def far_tunnel():
    rng = np.random.default_rng(1100)
    a = Art(640, H, base=B[0])
    brick_wall(a, rng, 8, 256, [B[2], B[3], "#3e181c", "#52221f"], hi=B[4])
    for px in (130, 450):
        arch_opening(a, px, 90, 256, 46, B[3], "#07030a", rng)
        ys = np.arange(H)[:, None] * np.ones((1, 640))
        m = a.mask("rect", px - 46, 140, px + 46, 255)
        a.stipple(m, "#0e0509", np.clip((ys - 140) / 110.0, 0, 1) * 0.7)
        for k in range(6):
            lichen(a, rng, px - 30 + k * 12, 250, 5, 3)
        a.glow(px, 232, 52, GREENGLOW, 0.55, halo=L[0], ry=46)
    for (mx, my) in ((40, 150), (300, 100), (560, 175), (220, 215), (380, 205), (590, 70), (20, 60)):
        wall_lichen(a, rng, mx, my, glow=30, n=8, spread=6, strength=0.42)
    a.rect(0, 256, 640, H, "#0e0709")
    a.rect(0, 256, 640, 257, B[3])
    a.rect(0, 258, 640, 258, B[1])
    vignette_top(a, 8, 78, "#0c0508", 0.8)
    for x in (80, 270, 380, 590):
        a.rect(x, 8, x + 1, 24, B[0])
    return a.finish(pal_for(BASE_COMMON, GL, EXTRA_COMMON))


def mid_tunnel():
    rng = np.random.default_rng(1200)
    Wd = 960
    a = Art(Wd, H)
    body, ring, dk = B[2], B[4], B[0]
    a.rect(0, 0, Wd, 58, B[1])
    pillars = [100 + 320 * k for k in range(3)]
    for px in pillars:
        cx = px + 17 + 160
        yy = np.arange(H)[:, None]
        big = a.mask("ellipse", cx - 145, 2, cx + 145, 114) & (yy <= 58)
        a.fill_mask(big, ring)
        sm = a.mask("ellipse", cx - 139, 8, cx + 139, 108) & (yy <= 58)
        a.erase(sm)
        for _ in range(8):
            sx = int(rng.integers(cx - 120, cx + 120))
            curve = 58 - 50 * np.sqrt(max(0.0, 1 - ((sx - cx) / 139.0) ** 2))
            a.poly([(sx - 2, int(curve) - 1), (sx + 2, int(curve) - 1), (sx, int(curve) + int(rng.integers(5, 12)))], ring)
    for px in pillars:
        a.rect(px, 0, px + 34, H, body)
        a.rect(px, 0, px + 6, H, B[4])
        a.rect(px + 29, 0, px + 34, H, dk)
        for by in range(14, 330, 14):
            a.rect(px, by, px + 34, by, dk)
            jx = px + 8 + (by // 14 % 3) * 7
            a.rect(jx, by - 13, jx, by, dk)
        a.rect(px - 5, 56, px + 39, 72, B[3])
        a.rect(px - 5, 56, px + 39, 57, B[5])
        a.rect(px - 5, 71, px + 39, 72, dk)
        a.rect(px - 4, 290, px + 38, 304, B[3])
        a.rect(px - 4, 290, px + 38, 291, B[5])
        for k in range(3):
            wall_lichen(a, rng, px + 6 + k * 11, 230 + k * 22, glow=18, n=6, spread=4, strength=0.4)
    # pipe run between pillars
    for k in range(3):
        x0 = pillars[k] + 40
        x1 = pillars[(k + 1) % 3] + (960 if k == 2 else 0) - 6
        a.rect(x0, 118, x1, 124, P.IRON[1])
        a.rect(x0, 118, x1, 119, P.IRON[3])
        a.rect(x0, 124, x1, 124, P.IRON[0])
        for jx in range(x0 + 20, x1, 70):
            a.rect(jx, 116, jx + 3, 126, P.IRON[2])
    for cx in (330, 600, 880):
        chain(a, cx, 30, 80 + cx % 30, B[5], B[3])
    # one torch pair per second pillar for a warm accent, lichen does the rest
    torch(a, pillars[1] + 17, 172, big=False, strength=0.5, r=64)
    ground(a, 300, "#150a0d", B[4], rng, bumps=16, bump_h=9)
    for x in range(0, Wd, 60):
        a.rect(x, 300, x, 340, "#0c0508")
    a.rect(0, 340, Wd, H, "#150a0d")
    return a.finish(pal_for(BASE_COMMON, GL, EXTRA_COMMON))


def near_tunnel():
    rng = np.random.default_rng(1300)
    Wd = 960
    a = Art(Wd, H)
    dk = "#0a0507"
    for _ in range(24):
        x = int(rng.integers(0, Wd))
        w = int(rng.integers(6, 16))
        a.poly([(x, 0), (x + w, 0), (x + w // 2, int(rng.integers(12, 40)))], dk)
    a.rect(0, 0, Wd, 6, dk)
    for px in (200, 700):
        a.rect(px, 0, px + 58, H, dk)
        a.rect(px, 0, px + 1, H, B[3])
        a.rect(px + 1, 0, px + 2, H, B[1])
        for by in range(20, 340, 22):
            a.rect(px + 4, by, px + 58, by, "#050204")
        a.rect(px - 6, 0, px + 64, 14, "#12080b")
        a.rect(px - 6, 0, px + 64, 1, B[2])
        for k in range(4):
            lichen(a, rng, px + 8 + k * 12, 330 - k * 3, 6, 4)
        a.glow(px + 28, 322, 34, GREENGLOW, 0.5, halo=L[0], ry=26)
    # a hanging lichen lamp-cluster
    cx = 460
    chain(a, cx, 6, 100, "#05030a", B[2], thick=2)
    a.ellipse(cx - 14, 96, cx + 14, 124, "#05030a")
    for k in range(10):
        a.px(cx - 8 + k * 2, 108 + int(rng.integers(-5, 6)), L[2 + k % 2])
    a.px(cx, 110, L[4])
    a.glow(cx, 110, 70, GREENGLOW, 0.55, halo=L[0], ry=64)
    ground(a, 344, dk, B[2], rng, bumps=20, bump_h=22, bump_w=(16, 44))
    for _ in range(12):
        x = int(rng.integers(0, Wd))
        a.rect(x, 18, x, 26, W[1])
        a.px(x, 27, W[4])
    return a.finish(pal_for([dk, B[3], B[1], "#050204", "#12080b", B[2]], GL, EXTRA_COMMON))


# ------------------------------------------------------------------ artery (wide, torch-lit)
def far_artery():
    rng = np.random.default_rng(2100)
    a = Art(640, H, base=B[0])
    brick_wall(a, rng, 8, 270, ["#52221f", B[3], "#5e2a26", "#46201e"], bh=14, bw=32, hi=B[5])
    # huge vault ribs
    for px in (0, 160, 320, 480):
        a.rect(px - 7, 8, px + 7, 270, B[1])
        a.rect(px - 7, 8, px - 5, 270, B[4])
        a.rect(px + 5, 8, px + 7, 270, B[0])
        a.rect(px - 11, 8, px + 11, 24, B[2])
        a.rect(px - 11, 24, px + 11, 24, B[0])
        a.rect(px - 10, 250, px + 10, 270, B[2])
        a.rect(px - 10, 250, px + 10, 251, B[5])
    # dark side-passage openings between ribs
    for px in (80, 400):
        a.rect(px - 22, 150, px + 22, 270, "#07030a")
        a.ellipse(px - 22, 128, px + 22, 172, "#07030a")
        a.rect(px - 26, 150, px - 24, 270, B[4])
        a.rect(px + 24, 150, px + 26, 270, B[0])
        a.glow(px, 255, 38, GREENGLOW, 0.4, halo=L[0], ry=30)
        for k in range(4):
            lichen(a, rng, px - 14 + k * 9, 268, 4, 3)
    # torches
    for tx in (80, 240, 400, 560):
        torch(a, tx, 150, big=True, strength=0.78, r=86)
    a.rect(0, 270, 640, H, "#160b0d")
    a.rect(0, 270, 640, 271, B[4])
    a.rect(0, 272, 640, 272, B[1])
    vignette_top(a, 8, 90, "#10080b", 0.8)
    return a.finish(pal_for(BASE_COMMON, [T[2], GREENGLOW], EXTRA_COMMON))


def mid_artery():
    rng = np.random.default_rng(2200)
    Wd = 960
    a = Art(Wd, H)
    # thick brick buttresses with torches and a hung banner-less rail
    for k, px in enumerate(range(80, Wd, 320)):
        a.rect(px, 0, px + 46, H, B[2])
        a.rect(px, 0, px + 8, H, B[4])
        a.rect(px + 38, 0, px + 46, H, B[0])
        for by in range(12, 340, 16):
            a.rect(px, by, px + 46, by, B[0])
            jx = px + 12 + (by // 16 % 3) * 10
            a.rect(jx, by - 15, jx, by, B[0])
        a.rect(px - 6, 40, px + 52, 56, B[3])
        a.rect(px - 6, 40, px + 52, 41, B[5])
        a.rect(px - 6, 55, px + 52, 56, B[0])
        a.rect(px - 6, 290, px + 52, 306, B[3])
        a.rect(px - 6, 290, px + 52, 291, B[5])
        # bone/skull sconce shape on the buttress
        sx = px + 23
        a.ellipse(sx - 6, 116, sx + 6, 128, N[2])
        a.rect(sx - 4, 126, sx + 4, 131, N[2])
        a.rect(sx - 4, 121, sx - 2, 123, B[0])
        a.rect(sx + 2, 121, sx + 4, 123, B[0])
        a.rect(sx - 1, 124, sx + 1, 125, B[0])
        a.rect(sx - 4, 129, sx + 4, 129, B[0])
        from bgkit import flame
        flame(a, sx, 117, 18, 5, [T[0], T[1], T[3], T[4]])
        a.glow(sx, 106, 96, T[2], 0.8, halo=T[0], ry=88)
    for k in range(3):
        a.rect(0, 60 + k * 0, Wd, 60, B[1])
    # overhead pipe cluster
    for (y, c) in ((22, P.IRON[1]), (30, P.IRON[2]), (37, P.IRON[1])):
        a.rect(0, y, Wd, y + 4, c)
        a.rect(0, y, Wd, y, P.IRON[3])
        a.rect(0, y + 4, Wd, y + 4, P.IRON[0])
    for jx in range(30, Wd, 96):
        a.rect(jx, 19, jx + 4, 42, P.IRON[0])
        a.rect(jx + 1, 19, jx + 1, 42, P.IRON[3])
    ground(a, 300, "#1a0d0f", B[5], rng, bumps=12, bump_h=7)
    for x in range(0, Wd, 48):
        a.rect(x, 300, x, 340, "#0c0508")
    a.rect(0, 340, Wd, H, "#1a0d0f")
    # arrow stripe on the floor of the artery
    for x in range(20, Wd, 160):
        a.rect(x, 318, x + 26, 321, T[1])
        a.poly([(x + 26, 314), (x + 34, 319), (x + 26, 325)], T[1])
    return a.finish(pal_for(BASE_COMMON, [T[2], GREENGLOW], EXTRA_COMMON))


def near_artery():
    rng = np.random.default_rng(2300)
    Wd = 960
    a = Art(Wd, H)
    dk = "#0b0608"
    a.rect(0, 0, Wd, 10, dk)
    for px in range(60, Wd, 480):
        a.rect(px, 0, px + 64, H, dk)
        a.rect(px, 0, px + 1, H, B[3])
        a.rect(px + 1, 0, px + 2, H, B[1])
        for by in range(20, 340, 24):
            a.rect(px + 4, by, px + 64, by, "#050204")
        a.rect(px - 8, 0, px + 72, 16, "#140a0c")
        a.rect(px - 8, 0, px + 72, 1, B[2])
        # big torch bracket silhouette with strong warm glow bleeding out
        tx = px + 32
        a.rect(tx - 7, 152, tx + 7, 158, P.IRON[1])
        a.rect(tx - 7, 152, tx + 7, 152, P.IRON[3])
        a.rect(tx - 4, 124, tx + 4, 152, P.IRON[1])
        a.rect(tx - 4, 124, tx - 3, 152, P.IRON[2])
        a.rect(tx - 5, 120, tx + 5, 126, P.IRON[2])
        from bgkit import flame
        flame(a, tx, 132, 26, 7, [T[0], T[1], T[3], T[4]])
        a.glow(tx, 116, 120, T[2], 0.78, halo=T[0], ry=110)
    for _ in range(18):
        x = int(rng.integers(0, Wd))
        a.poly([(x, 0), (x + 10, 0), (x + 5, int(rng.integers(10, 26)))], dk)
    ground(a, 346, dk, B[3], rng, bumps=18, bump_h=18, bump_w=(16, 44))
    return a.finish(pal_for([dk, B[3], B[1], "#050204", "#140a0c", B[2]], [T[2], GREENGLOW], EXTRA_COMMON))


# ------------------------------------------------------------------ corridor (low ceiling, lichen)
CEIL = 120  # ceiling underside in the far layer


def far_corridor():
    rng = np.random.default_rng(3100)
    a = Art(640, H, base="#08040a")
    brick_wall(a, rng, CEIL, 256, [B[1], B[2], "#3a161a", "#2a1016"], bh=10, bw=24, hi=B[3])
    a.rect(0, 8, 640, CEIL, "#07030a")
    # ceiling beams / low arches
    for px in range(0, 640, 128):
        a.rect(px - 5, CEIL - 22, px + 5, CEIL + 4, B[2])
        a.rect(px - 5, CEIL - 22, px - 4, CEIL + 4, B[4])
        a.rect(px - 20, CEIL - 4, px + 20, CEIL + 6, B[3])
        a.rect(px - 20, CEIL - 4, px + 20, CEIL - 3, B[5])
        a.rect(px - 20, CEIL + 6, px + 20, CEIL + 6, B[0])
    for px in (60, 220, 380, 540):
        a.rect(px - 15, 168, px + 15, 220, "#030103")
        for gx in range(px - 13, px + 14, 4):
            a.rect(gx, 170, gx, 218, P.IRON[1])
        a.rect(px - 16, 166, px + 16, 167, B[4])
        a.rect(px - 16, 221, px + 16, 222, B[0])
    for (mx, my) in ((30, 150), (100, 230), (160, 140), (200, 240), (300, 160), (340, 235), (430, 150), (480, 238), (600, 160), (610, 232)):
        wall_lichen(a, rng, mx, my, glow=32, n=10, spread=7, strength=0.5)
    a.rect(0, 256, 640, H, "#0d0708")
    a.rect(0, 256, 640, 257, B[3])
    vignette_top(a, 8, CEIL + 6, "#06030a", 0.8)
    return a.finish(pal_for(BASE_COMMON, GL, EXTRA_COMMON))


def mid_corridor():
    rng = np.random.default_rng(3200)
    Wd = 960
    a = Art(Wd, H)
    dk = "#07030a"
    # thick low ceiling slab with drips
    a.rect(0, 0, Wd, 74, B[0])
    for by in range(0, 74, 12):
        a.rect(0, by, Wd, by, dk)
        off = (by // 12 % 2) * 16
        for bx in range(0, Wd, 32):
            a.rect(bx + off, by, bx + off, by + 12, dk)
    a.rect(0, 74, Wd, 80, B[2])
    a.rect(0, 74, Wd, 74, B[4])
    a.rect(0, 80, Wd, 80, dk)
    for _ in range(26):
        x = int(rng.integers(0, Wd))
        ln = int(rng.integers(4, 12))
        a.rect(x, 80, x, 80 + ln, L[1] if ln < 8 else L[2])
        a.px(x, 81 + ln, L[3])
    for k in range(9):
        wall_lichen(a, rng, 40 + k * 106 + int(rng.integers(-12, 12)), 82, glow=28, n=7, spread=6, strength=0.45)
    # support posts
    for px in range(60, Wd, 240):
        a.rect(px, 80, px + 16, 300, B[1])
        a.rect(px, 80, px + 3, 300, B[3])
        a.rect(px + 13, 80, px + 16, 300, dk)
        a.rect(px - 3, 290, px + 19, 300, B[2])
        a.rect(px - 3, 290, px + 19, 290, B[4])
    # pipes along the wall
    a.rect(0, 150, Wd, 156, P.IRON[1])
    a.rect(0, 150, Wd, 150, P.IRON[3])
    a.rect(0, 156, Wd, 156, P.IRON[0])
    for jx in range(10, Wd, 120):
        a.rect(jx, 147, jx + 4, 159, P.IRON[2])
    ground(a, 300, "#120a0c", B[4], rng, bumps=14, bump_h=7)
    a.rect(0, 340, Wd, H, "#120a0c")
    return a.finish(pal_for(BASE_COMMON, GL, EXTRA_COMMON))


def near_corridor():
    rng = np.random.default_rng(3300)
    Wd = 960
    a = Art(Wd, H)
    dk = "#050205"
    a.rect(0, 0, Wd, 34, dk)
    a.rect(0, 34, Wd, 35, B[1])
    for _ in range(34):
        x = int(rng.integers(0, Wd))
        w = int(rng.integers(8, 24))
        a.poly([(x, 34), (x + w, 34), (x + w // 2, 34 + int(rng.integers(8, 30)))], dk)
    for k in range(7):
        x = 40 + k * 140 + int(rng.integers(-20, 20))
        wall_lichen(a, rng, x, 48, glow=44, n=9, spread=7, strength=0.5)
    # low foreground arches
    for px in (150, 630):
        a.rect(px, 0, px + 40, H, dk)
        a.rect(px, 0, px + 1, H, B[2])
        for by in range(30, 340, 26):
            a.rect(px + 3, by, px + 40, by, "#020102")
    ground(a, 346, dk, B[2], rng, bumps=22, bump_h=16, bump_w=(14, 40))
    for k in range(5):
        lichen(a, rng, 100 + k * 190, 344, 6, 5, drip=False)
        a.glow(100 + k * 190, 340, 36, GREENGLOW, 0.45, halo=L[0], ry=24)
    return a.finish(pal_for([dk, B[3], B[1], "#020102", B[2], B[0]], GL, EXTRA_COMMON))


STYLES = {
    "floor1": (far_tunnel, mid_tunnel, near_tunnel),
    "floor1_artery": (far_artery, mid_artery, near_artery),
    "floor1_corridor": (far_corridor, mid_corridor, near_corridor),
}

if __name__ == "__main__":
    want = sys.argv[1:] or list(STYLES)
    for s in want:
        e = EXT[s]
        for layer, fn in zip(("far", "mid", "near"), STYLES[s]):
            img = fn()
            if layer == "far":
                img = force_rows(img, e[0], e[1])
            else:
                img = force_rows(img, None, e[2] if layer == "mid" else e[3])
            img.save(OUT + f"bg_{s}_{layer}.png")
            print(s, layer, img.size, ncolors(img))
