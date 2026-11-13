import math
import numpy as np
from PIL import Image, ImageDraw

OUT = "#1b1226"


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def shift(m, dx, dy):
    r = np.zeros_like(m)
    h, w = m.shape
    ys = slice(max(dy, 0), h + min(dy, 0))
    yd = slice(max(-dy, 0), h + min(-dy, 0))
    xs = slice(max(dx, 0), w + min(dx, 0))
    xd = slice(max(-dx, 0), w + min(-dx, 0))
    r[ys, xs] = m[yd, xd]
    return r


def dilate4(m):
    return m | shift(m, 1, 0) | shift(m, -1, 0) | shift(m, 0, 1) | shift(m, 0, -1)


def ik(p0, p1, l1, l2, bend):
    dx = p1[0] - p0[0]
    dy = p1[1] - p0[1]
    d0 = math.hypot(dx, dy)
    if d0 < 1e-6:
        return (p0[0], p0[1] + l1), p0
    ux, uy = dx / d0, dy / d0
    d = min(d0, l1 + l2 - 0.01)
    d = max(d, abs(l1 - l2) + 0.01)
    a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
    h = math.sqrt(max(l1 * l1 - a * a, 0.0))
    mx = p0[0] + ux * a
    my = p0[1] + uy * a
    elbow = (mx - uy * h * bend, my + ux * h * bend)
    end = (p0[0] + ux * d, p0[1] + uy * d)
    return elbow, end


class Canvas:
    def __init__(self, w, h, ox=0, oy=0):
        self.w, self.h = w, h
        self.ox, self.oy = ox, oy
        self.a = np.zeros((h, w, 4), np.uint8)
        yy, xx = np.mgrid[0:h, 0:w]
        self.xx, self.yy = xx, yy
        self.px = xx + 0.5 - ox
        self.py = yy + 0.5 - oy

    def ell(self, cx, cy, rx, ry, ang=0.0):
        dx = self.px - cx
        dy = self.py - cy
        if ang:
            c, s = math.cos(ang), math.sin(ang)
            u = dx * c + dy * s
            v = -dx * s + dy * c
        else:
            u, v = dx, dy
        return (u / rx) ** 2 + (v / ry) ** 2 <= 1.0

    def disc(self, cx, cy, r):
        return self.ell(cx, cy, r, r)

    def box(self, x0, y0, x1, y1):
        x0, x1, y0, y1 = x0 + self.ox, x1 + self.ox, y0 + self.oy, y1 + self.oy
        return (self.xx >= x0) & (self.xx < x1) & (self.yy >= y0) & (self.yy < y1)

    def poly(self, pts):
        im = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(im).polygon([(float(x + self.ox), float(y + self.oy)) for x, y in pts], fill=255)
        return np.array(im) > 0

    def capsule(self, p0, p1, r0, r1=None):
        if r1 is None:
            r1 = r0
        n = max(int(math.hypot(p1[0] - p0[0], p1[1] - p0[1]) * 2), 1)
        m = np.zeros((self.h, self.w), bool)
        for i in range(n + 1):
            t = i / n
            m |= self.disc(p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t, r0 + (r1 - r0) * t)
        return m

    def local(self, cx, cy, ang):
        dx = self.px - cx
        dy = self.py - cy
        c, s = math.cos(ang), math.sin(ang)
        return dx * c + dy * s, -dx * s + dy * c

    def tri(self, cx, cy, ang, p0, p1, p2):
        lx, ly = self.local(cx, cy, ang)

        def side(a, b):
            return (lx - a[0]) * (b[1] - a[1]) - (ly - a[1]) * (b[0] - a[0])

        d0, d1, d2 = side(p0, p1), side(p1, p2), side(p2, p0)
        return ((d0 >= 0) & (d1 >= 0) & (d2 >= 0)) | ((d0 <= 0) & (d1 <= 0) & (d2 <= 0))

    def stamp(self, mask, ramp, outline=True, lt=1, st=1, spec=True, clip=None):
        if clip is not None:
            mask = mask & clip
        if not mask.any():
            return mask
        if outline:
            ring = dilate4(mask) & ~mask
            self.a[ring] = (*rgb(OUT), 255)
        if len(ramp) == 3:
            hi, li, mi, sh = ramp[0], ramp[0], ramp[1], ramp[2]
        else:
            hi, li, mi, sh = ramp
        self.a[mask] = (*rgb(mi), 255)
        light = mask & ~shift(mask, lt, lt)
        shade = mask & ~shift(mask, -st, -st)
        self.a[light] = (*rgb(li), 255)
        self.a[shade] = (*rgb(sh), 255)
        if spec:
            sp = mask & ~shift(mask, 1, 0) & ~shift(mask, 0, 1) & ~shift(mask, 1, 1) & ~shade
            self.a[sp] = (*rgb(hi), 255)
        return mask

    def fill(self, mask, color):
        self.a[mask] = (*rgb(color), 255)

    def dot(self, x, y, color):
        x, y = int(math.floor(x)) + self.ox, int(math.floor(y)) + self.oy
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x] = (*rgb(color), 255)

    def pattern(self, x, y, rows, cmap):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in cmap:
                    self.dot(x + i, y + j, cmap[ch])

    def under(self, base, caster, dx, dy, color):
        m = base & shift(caster, dx, dy) & ~caster
        self.fill(m, color)
        return m


def tf(cx, cy, ang, lx, ly):
    c, s = math.cos(ang), math.sin(ang)
    return cx + lx * c - ly * s, cy + lx * s + ly * c


def put(canvas, cx, cy, ang, lx, ly, rows, cmap):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in cmap:
                gx, gy = tf(cx, cy, ang, lx + i + 0.5, ly + j + 0.5)
                canvas.dot(gx, gy, cmap[ch])


def sheet(rows, fw, fh, cols=None):
    cols = cols or max(len(r) for r in rows)
    img = np.zeros((fh * len(rows), fw * cols, 4), np.uint8)
    for ri, row in enumerate(rows):
        for ci, fr in enumerate(row):
            img[ri * fh:(ri + 1) * fh, ci * fw:(ci + 1) * fw] = fr.a
    return Image.fromarray(img, "RGBA")


def preview(img, path, scale=6, bg=(70, 86, 120), fw=None, fh=None):
    w, h = img.size
    base = Image.new("RGBA", (w, h), bg + (255,))
    base.alpha_composite(img)
    big = base.resize((w * scale, h * scale), Image.NEAREST)
    if fw:
        d = ImageDraw.Draw(big)
        for x in range(0, w + 1, fw):
            d.line([(x * scale, 0), (x * scale, h * scale)], fill=(255, 255, 255, 60))
        for y in range(0, h + 1, fh):
            d.line([(0, y * scale), (w * scale, y * scale)], fill=(255, 255, 255, 60))
    big.convert("RGB").save(path)


def count_colors(img):
    a = np.array(img)
    m = a[..., 3] > 0
    cols = {tuple(p) for p in a[m][:, :3]}
    alphas = set(np.unique(a[..., 3]).tolist())
    return len(cols), alphas
