import numpy as np
from pix import Art, hx


def blend(a, b, t):
    ca, cb = hx(a), hx(b)
    return tuple(int(round(ca[i] + (cb[i] - ca[i]) * t)) for i in range(3))


def glow_palette(base, glows, steps=(0.18, 0.36, 0.6)):
    out = [hx(c) for c in base]
    for b in base[:6]:
        for g in glows:
            for t in steps:
                out.append(blend(b, g, t))
    return out


def poly_mask(art, pts):
    return art.mask("poly", pts)


def jag_profile(rng, x, w, top, jitter=10, step=(4, 12)):
    pts = []
    cx = x
    y = top + int(rng.integers(0, jitter))
    pts.append((x, y))
    while cx < x + w:
        cx = min(x + w, cx + int(rng.integers(*step)))
        r = rng.random()
        ny = y
        if r < 0.4:
            ny = top + int(rng.integers(0, jitter))
        elif r < 0.7:
            ny = y + int(rng.integers(-3, 4))
        pts.append((cx, y))
        if ny != y:
            pts.append((cx, ny))
        y = ny
    return pts


def ruin(art, x, w, top, base, body, face, rng, lit, dark, lit2=None, lit_p=0.2, cell=(9, 12), jitter=10, face_w=0.35, wins=True):
    prof = jag_profile(rng, x, w, top, jitter)
    pts = [(x, base)] + prof + [(x + w, base)]
    m = art.mask("poly", pts)
    art.fill_mask(m, body)
    if face is not None:
        fm = art.mask("rect", x, 0, x + int(w * face_w), art.h) & m
        art.fill_mask(fm, face)
    if wins:
        for cy in range(top + 10, base - 8, cell[1]):
            for cx in range(x + 4, x + w - 8, cell[0]):
                ww, wh = 4, 6
                xs = [(cx + i) % art.w for i in range(ww)]
                if cy + wh >= art.h:
                    continue
                if not m[cy:cy + wh, xs].all():
                    continue
                v = rng.random()
                if v < lit_p:
                    col = lit
                elif v < lit_p + 0.15 and lit2:
                    col = lit2
                else:
                    col = dark
                art.rect(cx, cy, cx + ww - 1, cy + wh - 1, col)
    return m


def tongue(art, cx, by, h, w, col, lean=0):
    pts = [(cx - w, by), (cx - w + 1, by - h * 0.35), (cx - w * 0.4 + lean * 0.4, by - h * 0.62),
           (cx - w * 0.15 + lean * 0.8, by - h * 0.82), (cx + lean, by - h), (cx + w * 0.3 + lean * 0.6, by - h * 0.62),
           (cx + w * 0.75, by - h * 0.45), (cx + w, by - h * 0.25), (cx + w, by)]
    art.poly([(int(round(a)), int(round(b))) for a, b in pts], col)


def flame(art, cx, by, h, w, cols, lean=0):
    tongue(art, cx, by, h, w, cols[0], lean)
    tongue(art, cx - 1, by, h * 0.72, w * 0.68, cols[1], lean * 0.6)
    tongue(art, cx, by, h * 0.45, w * 0.38, cols[2], lean * 0.3)
    tongue(art, cx, by, h * 0.22, w * 0.18, cols[3])


def smoke(art, x, y, rng, n, col, drift=3.0, r0=5, grow=1.4, cov0=0.6, fall=0.045, cmin=0.1):
    for i in range(n):
        cx = x + drift * i + 4 * np.sin(i * 0.9 + x)
        cy = y - i * 9
        r = r0 + i * grow
        m = art.mask("ellipse", int(cx - r), int(cy - r * 0.8), int(cx + r), int(cy + r * 0.8))
        art.stipple_under(m, col, max(cmin, cov0 - i * fall))


def stars(art, rng, n, ymax, cols):
    for _ in range(n):
        x = int(rng.integers(0, art.w))
        y = int(rng.integers(10, ymax))
        c = cols[int(rng.integers(0, len(cols)))]
        art.px(x, y, c)
    for _ in range(max(2, n // 14)):
        x = int(rng.integers(0, art.w))
        y = int(rng.integers(12, ymax))
        art.px(x, y, cols[0])
        art.px(x - 1, y, cols[1])
        art.px(x + 1, y, cols[1])
        art.px(x, y - 1, cols[1])
        art.px(x, y + 1, cols[1])


def chain(art, x, y0, y1, c0, c1, thick=1):
    for y in range(y0, y1):
        if (y // 2) % 2 == 0:
            art.rect(x, y, x + thick, y, c0)
        else:
            art.rect(x - (1 if thick > 0 else 0), y, x + thick + (1 if thick > 0 else 0), y, c1)


def catenary(art, x0, y0, x1, y1, sag, col):
    n = abs(x1 - x0)
    for i in range(n + 1):
        t = i / max(1, n)
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + sag * 4 * t * (1 - t)
        art.px(round(x), round(y), col)


def ground(art, y_top, col, rim, rng, bumps=0, bump_h=8, bump_w=(12, 30)):
    art.rect(0, y_top, art.w, art.h, col)
    for _ in range(bumps):
        x = int(rng.integers(0, art.w))
        w = int(rng.integers(*bump_w))
        h = int(rng.integers(3, bump_h))
        pts = [(x, y_top), (x + w * 0.2, y_top - h * 0.7), (x + w * 0.45, y_top - h), (x + w * 0.7, y_top - h * 0.6), (x + w, y_top)]
        art.poly([(int(a), int(b)) for a, b in pts], col)
    art.rim_top(rim)


EXT = {
    "street": ("#0a0720", "#190e2a", "#150b26", "#0d0816"),
    "stairwell": ("#070b16", "#0a1020", "#0a1020", "#070b14"),
    "tunnel": ("#0b0e1b", "#0d1020", "#12172c", "#090c18"),
    "guildhall": ("#150f1c", "#1d110d", "#2a170f", "#140b08"),
}


def force_rows(img, top, bottom, rows=6):
    a = np.array(img)
    if top:
        a[:8, :, :3] = hx(top)
        a[:8, :, 3] = 255
    if bottom:
        a[-rows:, :, :3] = hx(bottom)
        a[-rows:, :, 3] = 255
    from PIL import Image
    return Image.fromarray(a, "RGBA")
