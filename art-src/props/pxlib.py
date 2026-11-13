import os
import numpy as np
from PIL import Image, ImageDraw

OL = (27, 18, 38)
ASSETS = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets"


def R(*hexes):
    return [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in hexes]


IRON = R('#3b2436', '#5f3a42', '#8e5a48', '#c0865a', '#eab684')
STEEL = R('#2a2845', '#4a4e72', '#7580a0', '#aab8c4', '#e6eee0')
BRASS = R('#57303a', '#96562e', '#d28e38', '#f4c85a', '#fff0a8')
WOOD = R('#38222f', '#5e3a3c', '#8c5c44', '#b88458', '#e0b07a')
STONE = R('#2b2740', '#4c4666', '#78708a', '#a49aa2', '#d4c8bc')
RUST = R('#3e1c32', '#7a2e3e', '#b4503c', '#dc7e4c', '#f4b070')
LEAT = R('#3a1a34', '#701e46', '#a63a50', '#d46a62', '#f0a090')
GREEN = R('#17334a', '#25605a', '#4d9a5a', '#8cd068', '#d0f0a0')
BONE = R('#5e3c50', '#a07c6c', '#d8bc94', '#f4e2b4', '#fffae0')
CHAR = R('#150f22', '#2a2036', '#463a54', '#6a5a70', '#968290')
PURP = R('#1e1442', '#42246a', '#7240a4', '#a86cd0', '#e0b0f0')
NAVY = R('#171a3a', '#2a3466', '#44589a', '#6e8cc8', '#a8c8f0')
CLOTH = R('#3a2a3a', '#66443e', '#9a6a4a', '#c89a62', '#ecc890')
FLAME_R = (150, 52, 60)
FLAME_O = (240, 120, 44)
FLAME_Y = (255, 206, 76)
FLAME_W = (255, 246, 190)


class Cv:
    def __init__(self, w, h):
        self.w = w
        self.h = h
        self.a = np.zeros((h, w, 4), np.uint8)

    def px(self, x, y, c):
        x = int(x)
        y = int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x] = (c[0], c[1], c[2], 255)

    def get(self, x, y):
        return tuple(self.a[y, x])

    def opaque(self):
        return self.a[..., 3] > 0

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                if other.a[y, x, 3] > 0:
                    xx, yy = x + ox, y + oy
                    if 0 <= xx < self.w and 0 <= yy < self.h:
                        self.a[yy, xx] = other.a[y, x]


def _mk(cv, fn):
    im = Image.new('L', (cv.w, cv.h), 0)
    fn(ImageDraw.Draw(im))
    return np.array(im) > 0


def rect(cv, x0, y0, x1, y1):
    return _mk(cv, lambda d: d.rectangle([x0, y0, x1, y1], fill=255))


def ell(cv, x0, y0, x1, y1):
    return _mk(cv, lambda d: d.ellipse([x0, y0, x1, y1], fill=255))


def poly(cv, pts):
    return _mk(cv, lambda d: d.polygon([tuple(p) for p in pts], fill=255))


def line(cv, pts, w=1):
    return _mk(cv, lambda d: d.line([tuple(p) for p in pts], fill=255, width=w))


def rrect(cv, x0, y0, x1, y1):
    m = rect(cv, x0, y0, x1, y1)
    for (x, y) in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        if 0 <= x < cv.w and 0 <= y < cv.h:
            m[y, x] = False
    return m


def sh(m, dx, dy):
    o = np.roll(np.roll(m, dy, 0), dx, 1)
    if dy > 0:
        o[:dy] = False
    elif dy < 0:
        o[dy:] = False
    if dx > 0:
        o[:, :dx] = False
    elif dx < 0:
        o[:, dx:] = False
    return o


def dil(m):
    return m | sh(m, 1, 0) | sh(m, -1, 0) | sh(m, 0, 1) | sh(m, 0, -1)


def paint(cv, m, ramp, hl=1, sd=1, ol=True, olc=OL):
    tone = np.full(m.shape, 2, np.int8)
    dn = np.zeros(m.shape, bool)
    rt = np.zeros(m.shape, bool)
    up = np.zeros(m.shape, bool)
    lf = np.zeros(m.shape, bool)
    for i in range(1, sd + 1):
        dn |= ~sh(m, 0, -i)
        rt |= ~sh(m, -i, 0)
    for i in range(1, hl + 1):
        up |= ~sh(m, 0, i)
        lf |= ~sh(m, i, 0)
    tone[dn | rt] = 1
    tone[~sh(m, 0, -1) & ~sh(m, -1, 0)] = 0
    tone[up | lf] = 3
    tone[~sh(m, 0, 1) & ~sh(m, 1, 0)] = 4
    for t in range(5):
        sel = m & (tone == t)
        cv.a[sel] = (ramp[t][0], ramp[t][1], ramp[t][2], 255)
    if ol:
        ring = dil(m) & ~m
        cv.a[ring] = (olc[0], olc[1], olc[2], 255)
    return m


def flat(cv, m, c, ol=False):
    cv.a[m] = (c[0], c[1], c[2], 255)
    if ol:
        cv.a[dil(m) & ~m] = (OL[0], OL[1], OL[2], 255)


def cyl_v(cv, m, ramp, ol=True):
    ys, xs = np.nonzero(m)
    x0, x1 = xs.min(), xs.max()
    seq = [3, 4, 3, 2, 2, 2, 1, 0]
    for y, x in zip(ys, xs):
        f = (x - x0) / max(1, (x1 - x0 + 1))
        cv.px(x, y, ramp[seq[int(f * len(seq))]])
    if ol:
        cv.a[dil(m) & ~m] = (OL[0], OL[1], OL[2], 255)


def cyl_h(cv, m, ramp, ol=True):
    ys, xs = np.nonzero(m)
    y0, y1 = ys.min(), ys.max()
    seq = [4, 3, 3, 2, 2, 2, 1, 1, 0]
    for y, x in zip(ys, xs):
        f = (y - y0) / max(1, (y1 - y0 + 1))
        cv.px(x, y, ramp[seq[int(f * len(seq))]])
    if ol:
        cv.a[dil(m) & ~m] = (OL[0], OL[1], OL[2], 255)


def speckle(cv, m, c, p, seed=1):
    rs = np.random.RandomState(seed)
    r = rs.rand(*m.shape) < p
    sel = m & r & (cv.a[..., 3] > 0)
    cv.a[sel] = (c[0], c[1], c[2], 255)


def dither(cv, m, c, phase=0, only_empty=False):
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        if (x + y + phase) % 2 == 0:
            if only_empty and cv.a[y, x, 3] > 0:
                continue
            cv.px(x, y, c)


def exterior_outline(cv):
    a = cv.opaque()
    ring = dil(a) & ~a
    cv.a[ring] = (OL[0], OL[1], OL[2], 255)


def pts_line(cv, x0, y0, x1, y1, c):
    m = line(cv, [(x0, y0), (x1, y1)], 1)
    flat(cv, m, c)


def flame(cv, cx, by, h, w, phase, sway=0.0, cols=None):
    cols = cols or (FLAME_R, FLAME_O, FLAME_Y, FLAME_W)
    for col, sc in zip(cols, (1.0, 0.78, 0.55, 0.32)):
        hh = h * sc
        ww = w * sc
        for dy in range(int(hh) + 1):
            t = dy / max(1.0, hh)
            half = ww * (1 - t) ** 0.7
            off = sway * t ** 1.6 + 1.2 * np.sin(phase + t * 5.0) * t
            for dx in range(-int(half) - 1, int(half) + 2):
                if abs(dx) <= half:
                    cv.px(round(cx + dx + off), by - dy, col)


def glow_halo(cv, cx, cy, r1, r2, c1, c2):
    for y in range(cv.h):
        for x in range(cv.w):
            if cv.a[y, x, 3] > 0:
                continue
            d = np.hypot(x - cx, y - cy)
            if d <= r1 and (x + y) % 2 == 0:
                cv.px(x, y, c1)
            elif d <= r2 and x % 2 == 0 and y % 2 == 0:
                cv.px(x, y, c2)


def sheet(rows):
    fh = rows[0][0].h
    fw = rows[0][0].w
    cols = max(len(r) for r in rows)
    out = np.zeros((fh * len(rows), fw * cols, 4), np.uint8)
    for ri, row in enumerate(rows):
        for ci, f in enumerate(row):
            out[ri * fh:(ri + 1) * fh, ci * fw:(ci + 1) * fw] = f.a
    return out


def save(arr, rel):
    path = os.path.join(ASSETS, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    Image.fromarray(arr, 'RGBA').save(path)
    return path


def _bg(h, w, sc):
    ys, xs = np.mgrid[0:h * sc, 0:w * sc]
    t = ((xs // (8 * sc)) + (ys // (8 * sc))) % 2
    bg = np.zeros((h * sc, w * sc, 3), np.uint8)
    bg[t == 0] = (52, 54, 78)
    bg[t == 1] = (64, 66, 92)
    return bg


def preview(arr, name, scale=6):
    h, w = arr.shape[:2]
    big = np.kron(arr, np.ones((scale, scale, 1), np.uint8))
    bg = _bg(h, w, scale)
    a = big[..., 3:4] / 255.0
    out = (big[..., :3] * a + bg * (1 - a)).astype(np.uint8)
    Image.fromarray(out, 'RGB').save("/tmp/preview_%s.png" % name)


def preview12(arr, name):
    h, w = arr.shape[:2]
    canvas = np.zeros((h * 2 + 8, w * 3 + 16, 3), np.uint8)
    canvas[:] = (90, 92, 120)
    for sc, ox in ((1, 4), (2, w + 8)):
        big = np.kron(arr, np.ones((sc, sc, 1), np.uint8))
        hh, ww = big.shape[:2]
        reg = canvas[4:4 + hh, ox:ox + ww]
        a = big[..., 3:4] / 255.0
        canvas[4:4 + hh, ox:ox + ww] = (big[..., :3] * a + reg * (1 - a)).astype(np.uint8)
    Image.fromarray(canvas, 'RGB').save("/tmp/preview_%s_12.png" % name)
