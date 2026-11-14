import os
import math
import numpy as np
from PIL import Image, ImageDraw
from pix import hx, bayer_grid
from pxl import count_colors

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
LN = "#0a0a16"
W, H = 640, 360
rng = np.random.default_rng(9)
im = Image.new("RGBA", (W, H), (0, 0, 0, 255))
d = ImageDraw.Draw(im)


def r(x0, y0, x1, y1, c):
    d.rectangle([x0, y0, x1, y1], fill=hx(c) + (255,))


def ro(x0, y0, x1, y1, c, o=LN):
    d.rectangle([x0 - 1, y0 - 1, x1 + 1, y1 + 1], fill=hx(o) + (255,))
    r(x0, y0, x1, y1, c)


def p(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        im.putpixel((int(x), int(y)), hx(c) + (255,))


def line(pts, c, w=1):
    d.line(pts, fill=hx(c) + (255,), width=w)


def poly(pts, c, o=None):
    d.polygon(pts, fill=hx(c) + (255,), outline=hx(o) + (255,) if o else None)


def ell(x0, y0, x1, y1, c, o=None):
    d.ellipse([x0, y0, x1, y1], fill=hx(c) + (255,), outline=hx(o) + (255,) if o else None)


FLOOR = 300
WALL = ("#3a3258", "#342c50")
r(0, 0, W, FLOOR, WALL[0])
for x in range(0, W, 16):
    r(x, 0, x + 7, FLOOR, WALL[1])
    for y in range(6, FLOOR, 12):
        p(x + 3, y, "#3e3660")
for _ in range(900):
    p(int(rng.integers(0, W)), int(rng.integers(0, FLOOR)), "#2c2646")
r(0, 0, W, 9, "#24203e"); r(0, 9, W, 10, LN); r(0, 7, W, 8, "#4a4070")
for x in range(0, W, 6):
    p(x, 10, "#1a1830")
for (x0, y0, x1, y1) in ((250, 14, 292, 60), (580, 230, 624, 270), (40, 110, 70, 150)):
    for _ in range(int((x1 - x0) * (y1 - y0) * 0.25)):
        p(int(rng.integers(x0, x1)), int(rng.integers(y0, y1)), "#2a2444")
line([(300, 11), (304, 24), (299, 34), (306, 46)], "#1e1a34")
poly([(596, 9), (612, 9), (604, 30)], "#2a2444")
poly([(30, 9), (48, 9), (40, 26)], "#2a2444")
r(0, 292, W, 297, "#5a4a66"); r(0, 292, W, 292, "#7a6a84"); r(0, 298, W, 299, LN); r(0, 297, W, 297, "#2a2038")
r(0, FLOOR, W, H, "#5a3a3a")
for y in range(FLOOR, H, 14):
    r(0, y, W, y, "#2e1a22")
    off = (y // 14) * 37
    for x in range(-off % 90, W, 90):
        r(x, y, x, min(y + 13, H), "#2e1a22")
for y in range(FLOOR + 1, H, 14):
    r(0, y, W, y, "#6c4846")
for _ in range(700):
    p(int(rng.integers(0, W)), int(rng.integers(FLOOR, H)), "#4a2c30")
r(0, FLOOR, W, FLOOR, LN)


def bayer_blend(mask_t, color, levels=4):
    pass


ROOM = np.array(im)


def door():
    ro(20, 190, 75, 300, "#6a4a3a")
    r(20, 190, 22, 300, "#8a6048"); r(70, 190, 75, 300, "#4a3028")
    for (x0, y0, x1, y1) in ((28, 200, 66, 240), (28, 250, 66, 292)):
        d.rectangle([x0, y0, x1, y1], outline=hx("#3a241c") + (255,))
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y1 - 1], outline=hx("#7a5640") + (255,))
    r(14, 184, 80, 189, "#7a6a84"); r(14, 184, 80, 184, "#a090a8"); d.rectangle([13, 183, 81, 190], outline=hx(LN) + (255,))
    ell(46, 212, 49, 215, "#201820", "#8a8a98")
    r(60, 252, 64, 256, "#d8b84a"); p(61, 253, "#fff0a0")
    line([(31, 235), (38, 235)], "#c8c0c8", 1); ell(38, 233, 42, 237, "#a0a0b0", LN)
    r(37, 262, 53, 266, "#2a1c20")
    ro(40, 196, 52, 202, "#c8c0a8"); p(44, 199, LN); p(46, 199, LN); p(48, 199, LN)
    for i in range(10):
        p(22 + i * 2, 299, "#ffd070")
    r(22, 298, 73, 299, "#201418")
    for i in range(9):
        r(22 + i * 6, 298, 24 + i * 6, 299, "#ffb347") if i % 2 else None


def coat_rack():
    x = 90
    line([(x, 160), (x, 296)], LN, 4); line([(x, 160), (x, 296)], "#6a4a38", 2)
    r(x - 10, 294, x + 10, 298, LN); r(x - 9, 295, x + 9, 297, "#4a3028")
    for dx, dy in ((-9, 168), (9, 168), (-9, 188), (9, 188)):
        line([(x, dy + 4), (x + dx, dy)], LN, 3); line([(x, dy + 4), (x + dx, dy)], "#8a6a4a", 1)
    poly([(x + 2, 170), (x + 14, 168), (x + 18, 220), (x + 6, 224), (x + 2, 200)], "#3a3a52", LN)
    r(x + 9, 168, x + 14, 220, "#2c2c42")
    ell(x - 22, 158, x - 4, 166, "#7a2a34", LN); r(x - 20, 166, x - 6, 174, "#7a2a34"); d.rectangle([x - 21, 165, x - 5, 174], outline=hx(LN) + (255,))
    r(x - 20, 166, x - 6, 174, "#5a1e2a")


def poster(x, y, w, h, bg, a, b):
    ro(x, y, x + w, y + h, bg)
    r(x + 2, y + 2, x + w - 2, y + 5, a)
    cx = x + w // 2
    ell(cx - 7, y + 10, cx + 7, y + 26, b, LN)
    r(cx - 5, y + 16, cx - 3, y + 18, LN); r(cx + 3, y + 16, cx + 5, y + 18, LN)
    r(cx - 2, y + 21, cx + 2, y + 22, LN)
    r(x + 4, y + h - 8, x + w - 4, y + h - 6, a)
    r(x + 8, y + h - 4, x + w - 8, y + h - 3, b)
    for tx in (x - 1, x + w + 1):
        p(tx, y - 1, "#e8d8a0"); p(tx, y + h + 1, "#e8d8a0")


def poster2(x, y, w, h):
    ro(x, y, x + w, y + h, "#d8c8a0")
    for i in range(6):
        line([(x + 3, y + 5 + i * 5), (x + w - 3, y + 8 + i * 5 - (i % 3))], "#6a5a48", 1)
    r(x + 5, y + h - 12, x + 14, y + h - 4, "#c03a3a")
    poly([(x + w - 4, y + 4), (x + w - 12, y + 4), (x + w - 4, y + 12)], "#b8a880")


def clock(cx, cy, rr=11):
    ell(cx - rr - 1, cy - rr - 1, cx + rr + 1, cy + rr + 1, "#2a2030", LN)
    ell(cx - rr + 1, cy - rr + 1, cx + rr - 1, cy + rr - 1, "#e8e0d0", None)
    for k in range(12):
        a = k * math.pi / 6
        p(cx + math.sin(a) * (rr - 3), cy - math.cos(a) * (rr - 3), "#3a2a30")
    ah = (2 + 23 / 60) * math.pi / 6
    am = 23 * math.pi / 30
    line([(cx, cy), (cx + math.sin(ah) * 5, cy - math.cos(ah) * 5)], LN, 2)
    line([(cx, cy), (cx + math.sin(am) * 8, cy - math.cos(am) * 8)], "#2a2030", 1)
    p(cx, cy, "#c03a3a")


def couch():
    ro(130, 236, 300, 296, "#7a3a4a")
    r(132, 238, 298, 244, "#9a4e5e")
    r(150, 246, 280, 280, "#6a2e40")
    for x in (150, 215, 280):
        line([(x, 246), (x, 280)], "#4a1e30", 1)
    for x in (156, 190, 230, 262):
        p(x, 262, "#4a1e30"); p(x - 1, 262, "#8a4a5a")
    ro(130, 252, 152, 296, "#8a4254")
    r(132, 254, 150, 258, "#a85a6a"); r(132, 290, 150, 296, "#5a2434")
    ro(278, 252, 300, 296, "#8a4254")
    r(280, 254, 298, 258, "#a85a6a"); r(280, 290, 298, 296, "#5a2434")
    ro(152, 280, 278, 296, "#8a4254")
    r(154, 282, 276, 285, "#a85a6a"); r(154, 292, 276, 296, "#5a2434")
    line([(152, 286), (276, 286)], "#6a2e40", 1)
    for x in (136, 288):
        ro(x, 297, x + 5, 301, "#2a1a1a")
    r(182, 252, 182, 258, "#4a1e30")
    ro(256, 246, 272, 262, "#c8a05a")
    d.rectangle([258, 248, 270, 260], outline=hx("#9a7838") + (255,))
    for (x, y) in ((140, 270), (290, 272)):
        r(x, y, x + 3, y + 1, "#c8a05a")
    ro(146, 238, 164, 246, "#2a6a6a")
    r(148, 240, 162, 242, "#4a9a8a")


def lamp():
    line([(116, 125), (116, 295)], LN, 4); line([(116, 125), (116, 295)], "#a89060", 2)
    ro(106, 293, 126, 298, "#5a4a30")
    poly([(102, 112), (130, 112), (136, 138), (96, 138)], "#ffd890", LN)
    r(103, 114, 114, 136, "#ffeaa8"); r(124, 114, 131, 136, "#e8a850")
    r(104, 138, 128, 140, "#fff4c0")
    r(106, 108, 126, 111, "#5a4a30")


def side_table():
    ro(306, 262, 336, 267, "#6a4a38")
    r(307, 263, 335, 264, "#8a6a52")
    for x in (309, 331):
        ro(x, 268, x + 2, 298, "#4a3028")
    r(309, 280, 333, 282, "#4a3028")
    ell(314, 255, 328, 262, "#8a8a98", LN)
    ell(316, 257, 326, 261, "#4a4a58")
    line([(320, 256), (326, 252)], "#e8e0d0", 1); p(326, 252, "#ff8a2a")
    for sx, sy in ((327, 249), (329, 245), (327, 241)):
        p(sx, sy, "#8a86a8")
    ro(300, 254, 304, 261, "#c0c0c8")
    r(300, 254, 304, 255, "#d83a3a")
    ro(331, 257, 335, 261, "#e0a830")


def tv():
    ro(344, 262, 414, 298, "#3a2a2a")
    r(346, 264, 412, 268, "#5a4040"); r(350, 276, 380, 296, "#2a1c1c"); r(390, 272, 410, 292, "#2a1c1c")
    r(392, 276, 408, 280, "#101018")
    ro(350, 208, 408, 262, "#4a4a58")
    r(352, 210, 406, 212, "#6a6a7a")
    ro(356, 214, 396, 256, "#0a1020")
    for yy in range(216, 255):
        c = "#4a7aa8" if (yy % 3 == 0) else "#3a6a98"
        r(358, yy, 394, yy, c if 218 < yy < 250 else "#2a4a78")
    r(362, 236, 380, 252, "#2a3a58"); ell(364, 222, 376, 234, "#8ab4d8")
    r(380, 228, 392, 252, "#5a8ab8")
    line([(358, 220), (394, 220)], "#8ab4d8", 1)
    r(399, 216, 405, 222, "#2a2a32"); r(399, 228, 405, 230, "#2a2a32"); p(402, 250, "#e04a3a")
    line([(380, 208), (366, 188)], LN, 3); line([(380, 208), (366, 188)], "#a0a0b0", 1)
    line([(380, 208), (396, 190)], LN, 3); line([(380, 208), (396, 190)], "#a0a0b0", 1)


def window():
    x0, y0, x1, y1 = 430, 60, 590, 215
    ro(x0 - 8, y0 - 8, x1 + 8, y1 + 8, "#8a8aa0")
    r(x0 - 8, y0 - 8, x1 + 8, y0 - 5, "#a8a8c0")
    d.rectangle([x0 - 1, y0 - 1, x1 + 1, y1 + 1], fill=hx(LN) + (255,))
    for y in range(y0, y1 + 1):
        t = (y - y0) / (y1 - y0)
        stops = ["#0e0c2a", "#1a1840", "#2a2858", "#3e3470", "#6a4678", "#a05a6a"]
        i = min(int(t * 5), 4); f = t * 5 - i
        a, b = hx(stops[i]), hx(stops[i + 1])
        f = min(1, max(0, (f - 0.5) * 2.2 + 0.5))
        for x in range(x0, x1 + 1):
            c = b if bayer_grid(W, H)[y, x] < f else a
            p(x, y, "#%02x%02x%02x" % c)
    for _ in range(50):
        p(int(rng.integers(x0, x1)), int(rng.integers(y0, y0 + 90)), ["#f0ecff", "#b8aeea", "#7468b0"][int(rng.integers(0, 3))])
    mx, my = 520, 112
    for rad, cv, c in ((46, 0.12, "#4a3e86"), (38, 0.2, "#6a5ea0")):
        for yy in range(my - rad, my + rad):
            for xx in range(mx - rad, mx + rad):
                if (xx - mx) ** 2 + (yy - my) ** 2 <= rad * rad and bayer_grid(W, H)[yy, xx] < cv and x0 <= xx <= x1 and y0 <= yy <= y1:
                    p(xx, yy, c)
    ell(mx - 28, my - 28, mx + 28, my + 28, "#ece6ee")
    d.pieslice([mx - 28, my - 28, mx + 28, my + 28], 300, 120, fill=hx("#c4bcd2") + (255,))
    for cx, cy, rr in ((-9, -10, 6), (8, 6, 8), (-12, 12, 4), (13, -14, 3)):
        ell(mx + cx - rr, my + cy - rr, mx + cx + rr, my + cy + rr, "#c2b8d0")
        ell(mx + cx - rr + 1, my + cy - rr + 1, mx + cx + rr - 1, my + cy + rr - 1, "#d8d0e2")
    sx = x0
    while sx < x1:
        w = int(rng.integers(10, 26)); h = int(rng.integers(12, 46))
        r(sx, y1 - h, min(sx + w, x1), y1, "#12122e")
        r(sx, y1 - h, min(sx + w, x1), y1 - h, "#2a2a54")
        for wy in range(y1 - h + 4, y1 - 2, 6):
            for wx in range(sx + 2, min(sx + w, x1) - 2, 4):
                if rng.random() < 0.4:
                    p(wx, wy, "#ffc84a" if rng.random() < 0.7 else "#ff8a3a")
        sx += w + int(rng.integers(0, 4))
    r(466, y1 - 62, 467, y1 - 40, "#12122e"); p(466, y1 - 63, "#e0404a")
    r(x0, y0, x1, y0 + 2, "#8a8aa0")
    r(x0, y0 + 3, x1, y0 + 3, LN)
    r(x0, y0 + 32, x1, y0 + 36, "#8a8aa0")
    r(x0, y0 + 32, x1, y0 + 32, "#c0c0d8")
    r(x0, y0 + 37, x1, y0 + 37, LN)
    r(x0 + 79, y0 + 3, x0 + 81, y0 + 32, "#8a8aa0")
    for k in range(3):
        line([(x0 + 14 + k * 30, y0 + 4), (x0 + 22 + k * 30, y0 + 30)], "#9a96d0", 1) if k != 1 else None
    r(x0 - 2, y1 - 3, x0, y1 + 1, "#6a6a82") if False else None
    ro(x0 - 12, y1 + 1, x1 + 12, y1 + 8, "#9a9ab0")
    r(x0 - 12, y1 + 1, x1 + 12, y1 + 2, "#c8c8e0")
    r(x0 - 12, y1 + 6, x1 + 12, y1 + 8, "#6a6a82")
    for sgn in (0, 1):
        pts = []
        if sgn == 0:
            cur = [(x0 - 6, y0 - 12), (x0 + 28, y0 - 12), (x0 + 30, y0 + 40), (x0 + 38, y0 + 80), (x0 + 34, y0 + 116), (x0 + 22, y0 + 146), (x0 - 6, y0 + 150)]
            fold = "#8a2e4c"; main = "#b0405e"; hi = "#d86a7e"
        else:
            cur = [(x1 + 6, y0 - 12), (x1 - 34, y0 - 12), (x1 - 30, y0 + 30), (x1 - 40, y0 + 70), (x1 - 52, y0 + 100), (x1 - 40, y0 + 130), (x1 - 12, y0 + 150), (x1 + 6, y0 + 150)]
            fold = "#8a2e4c"; main = "#b0405e"; hi = "#d86a7e"
        poly(cur, main, LN)
        n = len(cur)
        for k in range(1, 4):
            t = k / 4
            xa = cur[0][0] + (cur[1][0] - cur[0][0]) * t
            xb = cur[-1][0] + (cur[-2][0] - cur[-1][0]) * t
            line([(xa, cur[0][1]), (xb, cur[-1][1])], fold, 1)
        line([(cur[0][0] + (cur[1][0] - cur[0][0]) * 0.2, cur[0][1]), (cur[-1][0] + (cur[-2][0] - cur[-1][0]) * 0.2, cur[-1][1])], hi, 1)
    r(x0 - 14, y0 - 14, x1 + 14, y0 - 12, "#5a4a30"); d.rectangle([x0 - 15, y0 - 15, x1 + 15, y0 - 11], outline=hx(LN) + (255,))
    ell(x0 - 20, y0 - 16, x0 - 14, y0 - 10, "#8a7a50", LN); ell(x1 + 14, y0 - 16, x1 + 20, y0 - 10, "#8a7a50", LN)


def junk():
    ro(442, 276, 482, 298, "#3a5a6a")
    r(444, 278, 480, 281, "#5a8a9a")
    ro(420, 286, 430, 298, "#c8a05a")
    ro(540, 290, 560, 298, "#e8e0d0")
    r(542, 292, 558, 293, "#c83a3a")
    ro(596, 255, 616, 298, "#5a4a38")
    for y in (262, 272, 282):
        r(598, y, 614, y, "#3a2a20")
    r(600, 248, 612, 254, "#5a8a4a"); ro(599, 252, 613, 255, "#8a4a38")
    ro(32, 268, 62, 298, "#4a4a5a") if False else None


door(); coat_rack(); window()
poster(168, 96, 36, 56, "#2a2a52", "#e04a3a", "#e8d8a8")
poster2(226, 112, 30, 40)
poster(556, 232, 0, 0, "#000", "#000", "#000") if False else None
tv(); couch(); lamp(); side_table(); junk()
clock(302, 106)
ro(140, 98, 150, 112, "#7a8a98") if False else None

arr = np.array(im).astype(float)
yy, xx = np.mgrid[0:H, 0:W]
bay = bayer_grid(W, H)


def tint(arr, field, color, strength, levels=4):
    q = np.floor(np.clip(field, 0, 1) * levels) / levels
    t = np.where(bay < (np.clip(field, 0, 1) * levels - np.floor(np.clip(field, 0, 1) * levels)), q + 1 / levels, q) * strength
    c = np.array(hx(color), dtype=float)
    arr[..., :3] = arr[..., :3] * (1 - t[..., None]) + c * t[..., None]


lamp_f = np.clip(1 - np.sqrt(((xx - 116) / 170.0) ** 2 + ((yy - 140) / 150.0) ** 2), 0, 1) ** 1.3
tint(arr, lamp_f, "#ffb860", 0.55)
tv_f = np.clip(1 - np.sqrt(((xx - 376) / 70.0) ** 2 + ((yy - 245) / 60.0) ** 2), 0, 1)
tint(arr, tv_f, "#6aa0d8", 0.35, 3)
moon_floor = np.zeros((H, W))
moon_poly = Image.new("L", (W, H), 0)
ImageDraw.Draw(moon_poly).polygon([(436, 222), (592, 222), (600, 300), (570, 360), (350, 360), (420, 300)], fill=255)
mp = np.array(moon_poly) / 255.0
mp = np.clip(mp * (1 - np.sqrt(((xx - 500) / 260.0) ** 2 + ((yy - 300) / 120.0) ** 2)), 0, 1)
tint(arr, mp, "#9ab4f0", 0.45, 3)
wall_m = np.clip(1 - np.sqrt(((xx - 510) / 150.0) ** 2 + ((yy - 140) / 130.0) ** 2), 0, 1) * 0.6
tint(arr, wall_m, "#8aa4e8", 0.28, 3)
vig = np.clip((np.sqrt(((xx - 320) / 420.0) ** 2 + ((yy - 190) / 260.0) ** 2) - 0.55) * 1.2, 0, 0.5)
tint(arr, vig, "#0a0818", 0.7, 4)
out = Image.fromarray(arr.astype(np.uint8), "RGBA")
a = np.array(out); a[..., 3] = 255; out = Image.fromarray(a, "RGBA")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    out.save(os.path.join(OUT, "apt_room.png"))
    out.resize((1280, 720), Image.NEAREST).convert("RGB").save(os.path.join(HERE, "_preview", "room.png"))
    print(out.size, count_colors(out))
