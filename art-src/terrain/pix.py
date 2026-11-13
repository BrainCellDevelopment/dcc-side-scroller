import numpy as np
from PIL import Image, ImageDraw

BAYER = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=float) / 16.0 + 1 / 32.0


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def bayer_grid(w, h):
    return np.tile(BAYER, (h // 4 + 1, w // 4 + 1))[:h, :w]


class Art:
    def __init__(self, w, h, base=None):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0) if base is None else hx(base) + (255,))
        self.d = ImageDraw.Draw(self.img)
        self.glows = []
        self.bayer = bayer_grid(w, h)

    def _c(self, c):
        return (hx(c) if isinstance(c, str) else tuple(c)) + (255,)

    def _offs(self):
        return (-self.w, 0, self.w)

    def rect(self, x0, y0, x1, y1, c):
        c = self._c(c)
        for dx in self._offs():
            self.d.rectangle([x0 + dx, y0, x1 + dx, y1], fill=c)

    def poly(self, pts, c):
        c = self._c(c)
        for dx in self._offs():
            self.d.polygon([(x + dx, y) for x, y in pts], fill=c)

    def ellipse(self, x0, y0, x1, y1, c):
        c = self._c(c)
        for dx in self._offs():
            self.d.ellipse([x0 + dx, y0, x1 + dx, y1], fill=c)

    def line(self, pts, c, width=1):
        c = self._c(c)
        for dx in self._offs():
            self.d.line([(x + dx, y) for x, y in pts], fill=c, width=width)

    def px(self, x, y, c):
        if 0 <= y < self.h:
            self.img.putpixel((int(x) % self.w, int(y)), self._c(c))

    def arr(self):
        return np.array(self.img)

    def setarr(self, a):
        self.img = Image.fromarray(a.astype(np.uint8), "RGBA")
        self.d = ImageDraw.Draw(self.img)

    def mask(self, kind, *args):
        m = Image.new("L", (self.w, self.h), 0)
        md = ImageDraw.Draw(m)
        for dx in self._offs():
            if kind == "ellipse":
                x0, y0, x1, y1 = args
                md.ellipse([x0 + dx, y0, x1 + dx, y1], fill=255)
            elif kind == "rect":
                x0, y0, x1, y1 = args
                md.rectangle([x0 + dx, y0, x1 + dx, y1], fill=255)
            elif kind == "poly":
                md.polygon([(x + dx, y) for x, y in args[0]], fill=255)
        return np.array(m) > 0

    def fill_mask(self, m, c):
        a = self.arr()
        a[m] = self._c(c)
        self.setarr(a)

    def erase(self, m):
        a = self.arr()
        a[m] = (0, 0, 0, 0)
        self.setarr(a)

    def alpha(self):
        return self.arr()[..., 3] > 0

    def stipple(self, m, c, cov):
        a = self.arr()
        covv = np.broadcast_to(np.asarray(cov, dtype=float), m.shape)
        sel = m & (self.bayer < covv)
        a[sel] = self._c(c)
        self.setarr(a)

    def stipple_under(self, m, c, cov):
        a = self.arr()
        covv = np.broadcast_to(np.asarray(cov, dtype=float), m.shape)
        sel = m & (self.bayer < covv) & (a[..., 3] == 0)
        a[sel] = self._c(c)
        self.setarr(a)

    def hband(self, y0, y1, stops, sharp=3.0):
        a = self.arr()
        n = len(stops)
        cols = np.array([hx(s) for s in stops], dtype=float)
        for y in range(y0, y1):
            t = (y - y0) / max(1, (y1 - y0 - 1)) * (n - 1)
            i = min(int(t), n - 2)
            f = t - i
            f = min(1, max(0, (f - 0.5) * sharp + 0.5))
            row = np.where(self.bayer[y][:, None] < f, cols[i + 1], cols[i])
            a[y, :, :3] = row
            a[y, :, 3] = 255
        self.setarr(a)

    def glow(self, cx, cy, r, col, strength=0.6, halo=None, ry=None):
        self.glows.append((cx, cy, r, ry or r, hx(col) if isinstance(col, str) else col, strength, halo))

    def rim_top(self, c, only=None):
        a = self.arr()
        op = a[..., 3] > 0
        above = np.zeros_like(op)
        above[1:] = op[:-1]
        sel = op & ~above
        if only is not None:
            sel &= only
        a[sel] = self._c(c)
        self.setarr(a)

    def finish(self, palette, halo_scale=0.9, halo_max=0.55, dither=18.0):
        a = self.arr()
        H, W = self.h, self.w
        ys, xs = np.mgrid[0:H, 0:W]
        pal = np.array([hx(p) if isinstance(p, str) else p for p in palette], dtype=float)
        if self.glows:
            E = np.zeros((H, W))
            acc = np.zeros((H, W, 3))
            hcol = np.zeros((H, W, 3))
            hbest = np.zeros((H, W))
            for (cx, cy, rx, ry, col, st, halo) in self.glows:
                e = np.zeros((H, W))
                for dx in (-W, 0, W):
                    d = np.sqrt(((xs - (cx + dx)) / rx) ** 2 + ((ys - cy) / ry) ** 2)
                    e = np.maximum(e, np.clip(1 - d, 0, 1) ** 1.6 * st)
                E += e
                acc += e[..., None] * np.array(col, dtype=float)
                if halo is not None:
                    better = e > hbest
                    hcol[better] = hx(halo) if isinstance(halo, str) else halo
                    hbest = np.where(better, e, hbest)
            opaque = a[..., 3] > 0
            Es = np.maximum(E, 1e-6)
            avg = acc / Es[..., None]
            lit = np.clip(E, 0, 1)
            base = a[..., :3].astype(float)
            out = base + avg * lit[..., None] * 0.85
            jitter = (self.bayer - 0.5) * dither
            q = np.clip(out + jitter[..., None], 0, 255)
            idx = np.argmin(((q[:, :, None, :] - pal[None, None, :, :]) ** 2).sum(-1), axis=-1)
            qc = pal[idx]
            sel = opaque & (E > 0.02)
            a[sel, :3] = qc[sel]
            cov = np.clip(E * halo_scale, 0, halo_max)
            st_sel = (~opaque) & (self.bayer < cov) & (hbest > 0)
            a[st_sel, :3] = hcol[st_sel]
            a[st_sel, 3] = 255
        a[..., 3] = np.where(a[..., 3] > 127, 255, 0)
        self.setarr(a)
        return self.img

    def save(self, path):
        self.img.save(path)


def ncolors(img):
    a = np.array(img)
    a = a[a[..., 3] > 0][:, :3]
    return len(np.unique(a, axis=0))


def pnoise(w, h, cell, rng, octaves=1):
    cw = max(1, w // cell)
    ch = h // cell + 2
    g = rng.random((ch, cw))
    out = np.zeros((h, w))
    for y in range(h):
        gy = y / cell
        y0 = int(gy)
        fy = gy - y0
        for x in range(w):
            gx = x / cell
            x0 = int(gx) % cw
            x1 = (x0 + 1) % cw
            fx = gx - int(gx)
            fx = fx * fx * (3 - 2 * fx)
            fyy = fy * fy * (3 - 2 * fy)
            v = (g[y0, x0] * (1 - fx) + g[y0, x1] * fx) * (1 - fyy) + (g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x1] * fx) * fyy
            out[y, x] = v
    return out
