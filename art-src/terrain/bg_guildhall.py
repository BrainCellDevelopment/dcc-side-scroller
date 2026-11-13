import numpy as np
from pix import Art, hx
from bgkit import *

H = 360
FIRE = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]
BOT = "#1d110d"


def far():
    rng = np.random.default_rng(130)
    a = Art(640, H, base="#150f1c")
    a.rect(0, 8, 640, 256, "#2a2236")
    tones = ["#2a2236", "#2e2640", "#322a46", "#271f33"]
    for r in range(0, 14):
        y0 = 8 + r * 12
        if y0 > 172:
            break
        off = (r % 2) * 16
        for bx in range(-32, 640, 32):
            x = bx + off
            a.rect(x + 1, y0 + 1, x + 31, y0 + 11, tones[int(rng.integers(0, 4))])
            a.rect(x + 1, y0 + 1, x + 31, y0 + 1, "#3a3050")
        a.rect(0, y0, 640, y0, "#1f1828")
        for bx in range(-32, 640, 32):
            a.rect(bx + off, y0, bx + off, y0 + 11, "#1f1828")
    a.rect(0, 176, 640, 256, "#3a2216")
    for x in range(0, 640, 8):
        t = ["#3a2216", "#44281a", "#2e1a12"][(x // 8) % 3]
        a.rect(x, 178, x + 6, 256, t)
        a.rect(x + 7, 178, x + 7, 256, "#1f120c")
        a.rect(x, 178, x, 256, ["#4c2e1e", "#56331f", "#3a2216"][(x // 8) % 3])
    a.rect(0, 170, 640, 177, "#5a3a22")
    a.rect(0, 170, 640, 171, "#7a4e2c")
    a.rect(0, 177, 640, 177, "#2a160e")
    for wx in (110, 430):
        a.ellipse(wx - 32, 34, wx + 32, 98, "#120c18")
        a.rect(wx - 32, 66, wx + 32, 160, "#120c18")
        a.ellipse(wx - 27, 39, wx + 27, 93, "#14204a")
        a.rect(wx - 27, 66, wx + 27, 155, "#14204a")
        yy = np.arange(H)[:, None] * np.ones((1, 640))
        a.stipple(a.mask("rect", wx - 27, 100, wx + 27, 155), "#22327a", np.clip((yy - 100) / 55.0, 0, 1) * 0.8)
        a.rect(wx - 1, 39, wx, 155, "#120c18")
        a.rect(wx - 27, 100, wx + 27, 101, "#120c18")
        a.rect(wx - 32, 158, wx + 32, 162, "#3a2a2a")
        for _ in range(6):
            a.px(wx + int(rng.integers(-24, 24)), int(rng.integers(50, 150)), "#cfd8ff")
    for wx in (110, 430):
        m = a.mask("poly", [(wx - 24, 160), (wx + 24, 160), (wx + 96, 256), (wx + 20, 256)])
        a.stipple(m & a.alpha(), "#3a3a62", 0.2)
    for sx in (270, 590, 20):
        a.rect(sx - 1, 108, sx + 1, 118, "#1a1008")
        a.rect(sx - 4, 118, sx + 4, 119, "#1a1008")
        a.rect(sx - 1, 100, sx + 1, 107, "#e8d8b0")
        flame(a, sx, 101, 8, 2, FIRE)
        a.glow(sx, 98, 56, "#ffb050", 0.55)
    a.rect(0, 256, 640, H, BOT)
    a.rect(0, 256, 640, 257, "#3a2216")
    for y in (268, 284, 302, 324):
        a.rect(0, y, 640, y, "#251810")
    yy = np.arange(H)[:, None] * np.ones((1, 640))
    a.stipple(a.mask("rect", 0, 8, 640, 60), "#150f1c", np.clip((60 - yy) / 52.0, 0, 1) * 0.8)
    base = ["#2a2236", "#2e2640", "#322a46", "#271f33", "#3a2216", "#44281a", "#2e1a12", "#5a3a22", "#7a4e2c", "#150f1c", "#1f1828", "#120c18", "#14204a", "#22327a", BOT, "#3a3050", "#1f120c", "#2a160e"]
    pal = glow_palette(base, ["#ffb050"], (0.2, 0.4, 0.6)) + [hx(c) for c in ("#cfd8ff", "#3a3a62", "#e8d8b0", "#4c2e1e", "#56331f", "#3a2a2a", "#251810", "#1a1008") + tuple(FIRE)]
    return a.finish(pal)


def mid():
    rng = np.random.default_rng(230)
    W = 960
    a = Art(W, H)
    body, lite, dk = "#3a2215", "#5c3a22", "#241309"
    a.rect(0, 0, W, 38, "#2c1a10")
    a.rect(0, 38, W, 40, dk)
    a.rect(0, 0, W, 1, "#4a2c1a")
    posts = [60 + 240 * k for k in range(4)]
    for px in posts:
        a.poly([(px, 40), (px - 44, 40), (px, 84)], "#2c1a10")
        a.poly([(px + 30, 40), (px + 74, 40), (px + 30, 84)], "#2c1a10")
        a.line([(px - 2, 84), (px - 44, 42)], "#5c3a22")
        a.line([(px + 32, 84), (px + 74, 42)], "#5c3a22")
    banners = [(posts[0] + 120, "#8a2a3a"), (posts[2] + 120, "#2a5a6a")]
    for (bx, bc) in banners:
        a.rect(bx - 17, 42, bx + 17, 44, "#241309")
        a.poly([(bx - 16, 44), (bx + 16, 44), (bx + 16, 126), (bx, 112), (bx - 16, 126)], bc)
        a.line([(bx - 16, 46), (bx - 16, 126), (bx, 112), (bx + 16, 126), (bx + 16, 46)], "#d8a040")
        a.poly([(bx, 62), (bx + 7, 74), (bx, 86), (bx - 7, 74)], "#d8a040")
        a.poly([(bx, 67), (bx + 3, 74), (bx, 81), (bx - 3, 74)], bc)
    for px in posts:
        a.rect(px, 0, px + 30, H, body)
        a.rect(px, 0, px + 6, H, lite)
        a.rect(px + 26, 0, px + 30, H, dk)
        for by in (100, 108):
            a.rect(px, by, px + 30, by + 1, dk)
        for dx in range(4, 28, 8):
            a.px(px + dx, 104, "#7a4e2c")
            a.px(px + dx + 1, 104, "#7a4e2c")
        a.rect(px - 3, 150, px + 33, 160, "#2c1a10")
        a.rect(px - 3, 150, px + 33, 150, "#7a4e2c")
    fx = 540
    a.rect(fx - 56, 170, fx + 56, 300, "#3a3040")
    for ry in range(172, 300, 12):
        a.rect(fx - 56, ry, fx + 56, ry, "#241c2c")
    for rx in range(-56, 56, 20):
        a.rect(fx + rx, 172, fx + rx, 300, "#241c2c")
    a.rect(fx - 62, 160, fx + 62, 170, "#4a3a48")
    a.rect(fx - 62, 160, fx + 62, 161, "#6a5a68")
    a.ellipse(fx - 36, 200, fx + 36, 262, "#0d0608")
    a.rect(fx - 36, 232, fx + 36, 300, "#0d0608")
    a.rect(fx - 30, 285, fx + 30, 300, "#1a0c0a")
    for (dx, h) in ((-18, 26), (-4, 38), (12, 30), (0, 20)):
        flame(a, fx + dx, 298, h, 9, FIRE, lean=dx // 8)
    for dx in (-20, 20):
        a.rect(fx + dx - 10, 150, fx + dx - 8, 160, "#e8d8b0")
        flame(a, fx + dx - 9, 150, 7, 2, FIRE)
    a.glow(fx, 270, 140, "#ff9a3c", 0.7, halo="#6a3a20", ry=110)
    a.glow(fx, 150, 30, "#ffb050", 0.4)
    cx = 330
    chain(a, cx, 41, 96, "#1a1008", "#3a2a1a")
    a.ellipse(cx - 24, 96, cx + 24, 108, "#1a1008")
    a.ellipse(cx - 21, 98, cx + 21, 106, "#3a2a1a")
    for dx in (-20, -10, 0, 10, 20):
        a.rect(cx + dx - 1, 90, cx + dx, 96, "#e8d8b0")
        flame(a, cx + dx, 90, 6, 1, FIRE)
    a.glow(cx, 92, 70, "#ffb050", 0.55, halo="#6a3a20", ry=60)
    ground(a, 300, "#2a170f", "#6a4428", rng, bumps=0)
    for x in range(0, W, 32):
        a.rect(x, 300, x, 340, "#1d110d")
    for y in (312, 326):
        a.rect(0, y, W, y, "#1d110d")
    a.rect(0, 340, W, H, "#2a170f")
    pal = glow_palette([body, lite, dk, "#2c1a10", "#3a3040", "#241c2c", "#2a170f", "#6a4428", "#4a3a48", "#0d0608"], ["#ff9a3c"], (0.15, 0.3, 0.5)) + [hx(c) for c in FIRE + ["#7a4e2c", "#8a2a3a", "#2a5a6a", "#d8a040", "#e8d8b0", "#1a1008", "#3a2a1a", "#1d110d", "#4a2c1a", "#6a5a68", "#1a0c0a", "#6a3a20"]]
    return a.finish(pal)


def near():
    rng = np.random.default_rng(330)
    W = 960
    a = Art(W, H)
    dk = "#140b08"
    a.rect(0, 0, W, 26, dk)
    a.rect(0, 0, W, 1, "#5a3418")
    for x in range(0, W, 240):
        a.poly([(x, 26), (x + 60, 26), (x, 74)], dk)
        a.poly([(x + 240 - 60, 26), (x + 240, 26), (x + 240, 74)], dk)
    for (cx0, c0, c1, c2) in ((30, "#2a0e18", "#3a1420", "#1c0910"), (560, "#1c1a2a", "#2a2840", "#12101c")):
        for i in range(0, 66, 6):
            col = (c0, c1, c2)[(i // 6) % 3]
            ln = 190 + int(6 * np.sin(i * 0.7))
            a.rect(cx0 + i, 26, cx0 + i + 5, 26 + ln, col)
            a.rect(cx0 + i, 26 + ln - 4, cx0 + i + 5, 26 + ln, c2)
        a.rect(cx0 - 4, 26, cx0 + 68, 32, dk)
        a.rect(cx0 + 20, 130, cx0 + 46, 134, "#8a6a30")
    for px in (300, 800):
        a.rect(px, 0, px + 44, H, dk)
        a.rect(px, 0, px + 2, H, "#7a4a22")
        a.rect(px + 2, 0, px + 3, H, "#3a2010")
        a.rect(px - 6, 120, px + 50, 134, dk)
        a.rect(px - 6, 120, px + 50, 121, "#4a2c1a")
    a.ellipse(430, 296, 480, 346, dk)
    a.rect(430, 306, 480, 336, dk)
    for by in (310, 322, 334):
        a.rect(430, by, 480, by, "#2a1810")
    a.rect(420, 248, 520, 252, dk)
    a.rect(424, 252, 428, 346, dk)
    a.rect(512, 252, 516, 346, dk)
    a.rect(668, 316, 740, 322, dk)
    a.rect(672, 322, 676, 346, dk)
    a.rect(732, 322, 736, 346, dk)
    ground(a, 346, dk, "#4a2a14", rng, bumps=6, bump_h=8)
    a.rim_top("#4a2c1a", only=np.zeros((H, W), bool))
    a.glow(120, 330, 170, "#ff9a3c", 0.22, halo="#3a1c10", ry=80)
    pal = glow_palette([dk, "#7a4a22", "#3a2010", "#4a2c1a", "#2a1810", "#2a0e18"], ["#ff9a3c"], (0.25, 0.5)) + [hx(c) for c in ("#3a1420", "#1c0910", "#1c1a2a", "#2a2840", "#12101c", "#8a6a30", "#5a3418", "#4a2a14", "#3a1c10")]
    return a.finish(pal)
