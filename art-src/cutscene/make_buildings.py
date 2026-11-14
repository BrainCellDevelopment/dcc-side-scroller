import os
import numpy as np
from PIL import Image, ImageDraw
from pix import hx
from pxl import count_colors

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
LINE = "#0a0e1c"
IRON = "#0c1020"
LIT = ("#ffe9a0", "#ffc84a", "#e8923a")
DARKWIN = ("#1c2a4c", "#101830", "#0a1024")


class B:
    def __init__(self, w, h, seed):
        self.w, self.h = w, h
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
        self.rng = np.random.default_rng(seed)

    def r(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=hx(c) + (255,))

    def p(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.putpixel((int(x), int(y)), hx(c) + (255,))

    def l(self, pts, c, w=1):
        self.d.line(pts, fill=hx(c) + (255,), width=w)

    def poly(self, pts, c):
        self.d.polygon(pts, fill=hx(c) + (255,))

    def get(self, x, y):
        return self.im.getpixel((x, y))

    def body(self, x0, y0, x1, y1, cols, brick=True, mortar=None):
        lit, mid, shade, dark = cols
        self.r(x0, y0, x1, y1, mid)
        w = x1 - x0
        self.r(x0, y0, x0 + 1, y1, lit)
        self.r(x1 - int(w * 0.28), y0, x1, y1, shade)
        self.r(x1 - int(w * 0.10), y0, x1, y1, dark)
        if brick:
            m = mortar or dark
            for y in range(y0 + 2, y1, 4):
                off = 3 if (y // 4) % 2 else 0
                for x in range(x0 + off, x1, 6):
                    if self.rng.random() < 0.8:
                        self.p(x, y, m)
                        if self.rng.random() < 0.35:
                            self.p(x + 1, y, m)
            for _ in range((x1 - x0) * (y1 - y0) // 90):
                x = int(self.rng.integers(x0 + 2, x1 - 1))
                y = int(self.rng.integers(y0 + 2, y1 - 1))
                self.p(x, y, lit if x < x1 - w * 0.28 else shade)
        self.d.rectangle([x0 - 1, y0 - 1, x1 + 1, y1], outline=hx(LINE) + (255,))

    def cornice(self, x0, x1, y, cols, hgt=4):
        lit, mid, shade, dark = cols
        self.r(x0 - 2, y - hgt, x1 + 2, y, lit)
        self.r(x0 - 2, y - 1, x1 + 2, y, mid)
        self.r(x0 - 2, y + 1, x1 + 2, y + 2, dark)
        self.r(x1 - 8, y - hgt, x1 + 2, y, shade)
        self.d.rectangle([x0 - 3, y - hgt - 1, x1 + 3, y + 3], outline=hx(LINE) + (255,))
        for x in range(x0, x1, 5):
            self.r(x, y + 3, x + 1, y + 4, dark)

    def window(self, x, y, w, h, lit, kind=0, trim="#7a6a78"):
        self.d.rectangle([x - 1, y - 1, x + w, y + h], outline=hx(LINE) + (255,))
        if lit:
            for j in range(h):
                c = LIT[0] if j < 2 else (LIT[1] if j < h * 0.7 else LIT[2])
                self.r(x, y + j, x + w - 1, y + j, c)
            if kind == 1:
                self.r(x + 1, y + 1, x + 2, y + h - 1, "#c4503a")
                self.r(x + w - 3, y + 1, x + w - 2, y + h - 1, "#c4503a")
            if kind == 2:
                self.r(x + w // 2 - 1, y + h - 5, x + w // 2 + 1, y + h - 1, "#5a3028")
                self.r(x + w // 2, y + h - 7, x + w // 2, y + h - 6, "#5a3028")
        else:
            for j in range(h):
                self.r(x, y + j, x + w - 1, y + j, DARKWIN[0] if j < h * 0.3 else DARKWIN[1])
            self.l([(x + 1, y + 1), (x + 1, y + 3)], "#3a5080")
            if kind == 3:
                self.r(x, y + h - 3, x + w - 1, y + h - 1, DARKWIN[2])
        self.r(x + w // 2, y, x + w // 2, y + h - 1, LINE) if w > 6 else None
        self.r(x, y + h // 2, x + w - 1, y + h // 2, LINE) if h > 8 else None
        self.r(x - 2, y + h + 1, x + w + 1, y + h + 2, trim)
        self.d.rectangle([x - 3, y + h + 1, x + w + 2, y + h + 3], outline=hx(LINE) + (255,))

    def grid(self, x0, x1, y0, y1, ww, wh, gx, gy, p_lit, kinds=(0, 0, 0, 1, 2, 3), skip=None, trim="#7a6a78"):
        nx = (x1 - x0 - gx + 2) // (ww + gx)
        ox = x0 + ((x1 - x0) - (nx * ww + (nx - 1) * gx)) // 2
        rows = []
        y = y0
        while y + wh < y1:
            rows.append(y)
            y += wh + gy
        for ri, y in enumerate(rows):
            for i in range(nx):
                if skip and skip(ri, i):
                    continue
                self.window(ox + i * (ww + gx), y, ww, wh, self.rng.random() < p_lit, int(self.rng.choice(kinds)), trim)
        return rows, ox, nx

    def fire_escape(self, x0, x1, ys, flip=False):
        for k, y in enumerate(ys):
            self.r(x0, y, x1, y, IRON)
            self.r(x0, y + 1, x1, y + 1, "#2a3454")
            self.r(x0, y - 5, x0, y - 1, IRON)
            self.r(x1, y - 5, x1, y - 1, IRON)
            self.r(x0, y - 5, x1, y - 5, IRON)
            for x in range(x0 + 3, x1, 4):
                self.p(x, y - 3, "#1a2240")
            if k + 1 < len(ys):
                ny = ys[k + 1]
                sx0, sx1 = (x0 + 2, x0 + 9) if (k % 2 == 0) != flip else (x1 - 9, x1 - 2)
                if (k % 2 == 0) != flip:
                    self.l([(sx0, y), (sx1, ny)], IRON, 2)
                else:
                    self.l([(sx1, y), (sx0, ny)], IRON, 2)
                self.p(sx0, ny, IRON)
        self.r(x0, ys[0] - 5, x0, ys[-1], IRON)

    def graffiti(self, x, y, text_px, c, c2):
        for (dx, dy) in text_px:
            self.p(x + dx, y + dy, c)
            self.p(x + dx + 1, y + dy + 1, c2)

    def door(self, x, y, w, h, c="#3a2a36", lit=False):
        self.r(x - 1, y - 1, x + w, y + h, LINE)
        self.r(x, y, x + w - 1, y + h - 1, c)
        self.r(x + 1, y + 1, x + w // 2 - 1, y + h - 1, "#4c3844")
        self.r(x + w - 4, y + h // 2, x + w - 3, y + h // 2 + 1, "#e0b84a")
        if lit:
            self.r(x + 2, y + 2, x + w - 3, y + 5, LIT[1])

    def laundry(self, x0, y0, x1, y1, sag=3):
        n = x1 - x0
        for i in range(n + 1):
            t = i / n
            self.p(x0 + i, y0 + (y1 - y0) * t + sag * 4 * t * (1 - t), "#c8c0d8")
        cols = ["#e8e0f0", "#e0505a", "#6ab0e0", "#f0c850", "#e8e0f0"]
        for k in range(1, 5):
            t = k / 5
            x = int(x0 + n * t)
            y = int(y0 + (y1 - y0) * t + sag * 4 * t * (1 - t))
            c = cols[k % 5]
            self.r(x, y + 1, x + 2, y + 5, c)
            self.r(x + 2, y + 1, x + 2, y + 5, "#9890b0")

    def save(self, name):
        a = np.array(self.im)
        self.im.save(os.path.join(OUT, name))
        return self.im


BRICK_R = ("#b0584a", "#8a3e3a", "#5e2a34", "#3a1c2c")
BRICK_O = ("#c07858", "#9a5a46", "#6a3a44", "#42263a")
CONC = ("#8a96ae", "#65718e", "#444e72", "#2a3254")
BRICK_P = ("#8a5e84", "#66426a", "#46304e", "#2c1e3a")
BRICK_G = ("#5e8a8c", "#42666e", "#2e4658", "#1c2e40")


def bld_a():
    b = B(150, 420, 11)
    top = 20
    b.body(8, top, 140, 419, BRICK_R)
    b.cornice(8, 140, top + 1, BRICK_R, 5)
    rows, ox, nx = b.grid(18, 130, top + 14, 360, 14, 20, 12, 18, 0.38)
    b.fire_escape(ox - 3, ox + 2 * 14 + 12 + 3, [r + 24 for r in rows[1:-1]])
    b.r(8, 360, 140, 366, BRICK_R[3])
    b.r(8, 366, 140, 419, BRICK_R[2])
    b.door(60, 376, 24, 43, lit=True)
    b.r(54, 368, 90, 372, "#3a5a8a")
    b.d.rectangle([53, 367, 90, 372], outline=hx(LINE) + (255,))
    b.r(18, 380, 46, 402, "#1c2a4c"); b.d.rectangle([17, 379, 47, 403], outline=hx(LINE) + (255,))
    b.r(20, 382, 44, 386, "#3a5080")
    b.r(100, 380, 128, 402, "#ffc84a"); b.d.rectangle([99, 379, 129, 403], outline=hx(LINE) + (255,))
    b.r(100, 390, 128, 402, "#e8923a"); b.r(113, 380, 114, 402, LINE)
    b.l([(120, top - 7), (120, 0)], IRON, 1); b.l([(112, 6), (128, 6)], IRON); b.l([(115, 11), (125, 11)], IRON)
    b.l([(70, top - 7), (70, 8)], IRON); b.l([(70, 8), (84, 14)], IRON); b.p(84, 14, "#e0404a")
    b.r(24, top - 14, 34, top - 5, BRICK_R[2]); b.d.rectangle([23, top - 15, 35, top - 4], outline=hx(LINE) + (255,))
    pts = [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2), (1, 3), (4, 0), (4, 1), (4, 2), (4, 3), (5, 3), (7, 0), (8, 0), (7, 1), (7, 2), (7, 3), (8, 3), (11, 0), (11, 1), (11, 2), (11, 3), (12, 0), (12, 2)]
    b.graffiti(106, 346, pts, "#4ae0c0", "#14584c")
    b.laundry(18, 130, 70, 136, 4)
    return b.save("bld_a.png")


def bld_b():
    b = B(120, 520, 22)
    b.body(14, 60, 106, 519, CONC, brick=False)
    for y in range(64, 519, 12):
        b.r(15, y, 105, y, CONC[2])
    b.cornice(14, 106, 61, CONC, 4)
    b.r(30, 46, 90, 56, CONC[1]); b.d.rectangle([29, 45, 91, 57], outline=hx(LINE) + (255,))
    b.r(64, 46, 90, 56, CONC[2])
    tx0, tx1, ty = 38, 82, 14
    for lx in (40, 52, 66, 78):
        b.r(lx, 36, lx + 1, 45, IRON)
    b.l([(40, 45), (52, 36)], IRON); b.l([(52, 45), (66, 36)], IRON)
    b.r(tx0, ty, tx1, 36, "#6a4a40"); b.r(tx0, ty, tx0 + 3, 36, "#9a6a58"); b.r(tx1 - 12, ty, tx1, 36, "#3e2a34")
    for y in range(ty + 4, 36, 6):
        b.r(tx0, y, tx1, y, "#24161e")
    b.d.rectangle([tx0 - 1, ty - 1, tx1 + 1, 37], outline=hx(LINE) + (255,))
    b.poly([(tx0 - 3, ty), (60, ty - 12), (tx1 + 3, ty)], "#3e2a34"); b.l([(tx0 - 3, ty), (60, ty - 12), (tx1 + 3, ty)], LINE)
    b.l([(60, ty - 12), (60, 0)], IRON); b.p(60, 1, "#e0404a")
    rows, ox, nx = b.grid(22, 98, 76, 470, 10, 18, 10, 20, 0.33, trim="#8a96ae")
    b.fire_escape(ox + 20, ox + 20 + 38, [r + 22 for r in rows[2:-2]], flip=True)
    b.r(14, 474, 106, 480, CONC[3]); b.r(14, 481, 106, 519, CONC[2])
    b.door(48, 490, 22, 29)
    b.r(20, 486, 40, 508, "#ffc84a"); b.d.rectangle([19, 485, 41, 509], outline=hx(LINE) + (255,))
    b.r(29, 486, 30, 508, LINE); b.r(20, 496, 40, 497, LINE)
    b.r(76, 488, 100, 508, "#1c2a4c"); b.d.rectangle([75, 487, 101, 509], outline=hx(LINE) + (255,))
    pts = [(0, 3), (1, 2), (2, 1), (3, 2), (4, 3), (6, 0), (6, 1), (6, 2), (6, 3), (7, 0), (8, 1), (9, 2), (10, 3), (10, 0)]
    b.graffiti(24, 456, pts, "#ff5aa8", "#5a1e44")
    b.laundry(22, 300, 98, 310, 5)
    b.laundry(22, 190, 98, 186, 4)
    return b.save("bld_b.png")


def bld_c():
    b = B(170, 380, 33)
    top = 30
    b.body(6, top, 164, 379, BRICK_O)
    b.cornice(6, 164, top + 1, BRICK_O, 6)
    for cx in (22, 140):
        b.r(cx, top - 24, cx + 12, top - 6, BRICK_O[2]); b.d.rectangle([cx - 1, top - 25, cx + 13, top - 5], outline=hx(LINE) + (255,))
        b.r(cx - 2, top - 28, cx + 14, top - 25, BRICK_O[0]); b.d.rectangle([cx - 3, top - 29, cx + 15, top - 25], outline=hx(LINE) + (255,))
        b.r(cx + 9, top - 24, cx + 12, top - 6, BRICK_O[3])
    b.r(70, top - 20, 100, top - 6, "#2a3454"); b.d.rectangle([69, top - 21, 101, top - 5], outline=hx(LINE) + (255,))
    for i, ch in enumerate((1, 0, 1, 1, 0, 1)):
        b.r(73 + i * 4, top - 17, 74 + i * 4, top - 9, "#e8923a" if ch else "#5a4a60")
    b.r(40, top - 10, 62, top - 6, IRON); b.l([(40, top - 6), (44, top - 12), (58, top - 12), (62, top - 6)], IRON)
    b.r(104, 8, 106, top - 6, IRON); b.d.rectangle([98, 4, 112, 8], outline=hx(LINE) + (255,), fill=hx("#3a5a8a") + (255,))
    rows, ox, nx = b.grid(14, 156, top + 16, 318, 16, 22, 10, 18, 0.4, skip=lambda r, i: False)
    b.fire_escape(ox + (nx - 2) * 26 - 4, ox + (nx - 2) * 26 + 22, [r + 26 for r in rows[1:-1]])
    b.laundry(14, 120, 80, 126, 4)
    b.r(6, 318, 164, 324, BRICK_O[3]); b.r(6, 325, 164, 379, BRICK_O[2])
    b.r(16, 332, 100, 348, "#b0384a"); b.d.rectangle([15, 331, 101, 349], outline=hx(LINE) + (255,))
    for x in range(16, 100, 8):
        b.r(x, 332, x + 3, 348, "#e8e0f0")
    b.r(18, 352, 98, 376, "#ffc84a"); b.d.rectangle([17, 351, 99, 377], outline=hx(LINE) + (255,))
    b.r(18, 366, 98, 376, "#e8923a")
    for x in (38, 58, 78):
        b.r(x, 352, x + 1, 376, LINE)
    b.r(30, 358, 36, 366, "#5a3028"); b.r(66, 360, 72, 368, "#5a3028")
    b.door(118, 336, 28, 43)
    b.r(112, 322, 150, 330, "#2a3454"); b.d.rectangle([111, 321, 151, 331], outline=hx(LINE) + (255,))
    for i in range(6):
        b.r(115 + i * 6, 324, 117 + i * 6, 328, "#4ae0c0" if i != 3 else "#1c2a4c")
    pts = [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3), (2, 3), (4, 0), (4, 1), (4, 2), (4, 3), (5, 0), (6, 0), (6, 1), (6, 2), (6, 3), (5, 3), (9, 0), (9, 1), (9, 2), (9, 3), (10, 1), (11, 2), (11, 0), (11, 3)]
    b.graffiti(112, 300, pts, "#f0e04a", "#5a501c")
    return b.save("bld_c.png")


def bld_d():
    b = B(130, 460, 44)
    top = 52
    b.body(10, top + 22, 120, 459, BRICK_P)
    b.body(24, top, 106, top + 24, BRICK_P)
    b.cornice(24, 106, top + 1, BRICK_P, 4)
    b.cornice(10, 120, top + 23, BRICK_P, 4)
    b.l([(98, top - 6), (98, 6)], IRON); b.l([(92, 12), (104, 12)], IRON); b.l([(94, 18), (102, 18)], IRON); b.l([(98, 6), (98, 4)], "#e0404a")
    b.d.ellipse([34, top - 16, 56, top + 2], fill=hx("#9aa4c0") + (255,), outline=hx(LINE) + (255,))
    b.d.pieslice([34, top - 16, 56, top + 2], 100, 280, fill=hx("#5a6688") + (255,))
    b.l([(45, top - 7), (60, top - 14)], IRON, 1); b.r(44, top - 6, 46, top, IRON)
    for ax in (30, 76):
        b.r(ax, top + 6, ax + 12, top + 16, "#5a6688"); b.d.rectangle([ax - 1, top + 5, ax + 13, top + 17], outline=hx(LINE) + (255,))
        for k in range(3):
            b.r(ax + 2, top + 8 + k * 3, ax + 10, top + 8 + k * 3, "#2a3454")
    rows, ox, nx = b.grid(18, 112, top + 38, 410, 12, 18, 10, 20, 0.36, trim="#8a5e84")
    for r in rows[2:6]:
        pass
    b.fire_escape(ox - 4, ox + 28, [r + 22 for r in rows[2:-2]])
    b.laundry(ox + 28, rows[3] + 6, 116, rows[3] + 18, 5)
    b.r(10, 410, 120, 416, BRICK_P[3]); b.r(10, 417, 120, 459, BRICK_P[2])
    b.door(24, 424, 22, 35)
    b.r(60, 424, 112, 452, "#1c2a4c"); b.d.rectangle([59, 423, 113, 453], outline=hx(LINE) + (255,))
    b.r(62, 426, 110, 430, "#3a5080")
    for x in (73, 86, 99):
        b.r(x, 424, x + 1, 452, LINE)
    b.r(62, 436, 110, 450, "#ffc84a")
    b.r(62, 444, 110, 450, "#e8923a")
    pts = [(0, 1), (1, 0), (2, 1), (1, 2), (1, 3), (4, 0), (4, 1), (4, 2), (4, 3), (5, 3), (6, 2), (6, 1), (6, 0), (9, 0), (9, 1), (9, 2), (9, 3), (10, 0), (11, 1), (10, 2), (11, 3)]
    b.graffiti(70, 398, pts, "#ff8a3a", "#5a2a14")
    return b.save("bld_d.png")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    pv = os.path.join(HERE, "_preview")
    os.makedirs(pv, exist_ok=True)
    ims = [bld_a(), bld_b(), bld_c(), bld_d()]
    sheet = Image.new("RGBA", (150 + 120 + 170 + 130 + 30, 520), (28, 36, 70, 255))
    x = 5
    for im in ims:
        sheet.alpha_composite(im, (x, 520 - im.height))
        x += im.width + 5
        print(im.size, count_colors(im))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).convert("RGB").save(os.path.join(pv, "bld.png"))
