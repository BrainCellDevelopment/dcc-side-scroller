import os
import numpy as np
from PIL import Image
from pix import Art
from bgkit import stars, smoke
from pxl import count_colors

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
STOPS = ["#0a0818", "#120c28", "#1a1038", "#1c1640", "#1a2048", "#202a54", "#2c3466", "#4a3a78", "#78447a", "#a8506a", "#d4703e", "#f0a050"]


def column(a, x0, ytop, ybot, rng, col, col2, r0=4, grow=0.04, drift=14):
    y = ybot
    i = 0
    while y > ytop:
        cx = x0 + drift * np.sin(i * 0.3 + x0) * (1 - (y - ytop) / (ybot - ytop + 1)) + i * 0.3
        r = r0 + (ybot - y) * grow
        m = a.mask("ellipse", int(cx - r), int(y - r * 0.9), int(cx + r), int(y + r * 0.9))
        a.stipple_under(m, col, 0.7) if False else None
        a.stipple(m, col, 0.55)
        m2 = a.mask("ellipse", int(cx - r * 0.5 + 2), int(y - r * 0.5), int(cx + r * 0.5 + 2), int(y + r * 0.4))
        a.stipple(m2, col2, 0.45)
        y -= 7
        i += 1


def build():
    rng = np.random.default_rng(77)
    a = Art(640, 720, base="#0a0818")
    a.hband(0, 720, STOPS, sharp=2.0)
    stars(a, rng, 150, 330, ["#f0ecff", "#b8aeea", "#7468b0"])
    for _ in range(60):
        a.px(int(rng.integers(0, 640)), int(rng.integers(0, 340)), "#9a90d8")
    mx, my = 470, 120
    for r, cov, c in ((78, 0.10, "#2c2658"), (64, 0.16, "#3c3470"), (54, 0.22, "#5a4e90")):
        m = a.mask("ellipse", mx - r, my - r, mx + r, my + r)
        a.stipple(m, c, cov)
    a.ellipse(mx - 42, my - 42, mx + 42, my + 42, "#cfc8d8")
    a.ellipse(mx - 42, my - 42, mx + 38, my + 38, "#ece6ee")
    shade = a.mask("ellipse", mx - 36, my - 40, mx + 46, my + 44) & ~a.mask("ellipse", mx - 42, my - 42, mx + 36, my + 38)
    m = a.mask("ellipse", mx - 42, my - 42, mx + 42, my + 42)
    a.stipple(m & shade, "#b4aac8", 0.9)
    for cx, cy, r in ((-14, -14, 9), (12, 8, 12), (-18, 16, 6), (20, -22, 5), (2, -26, 4), (-4, 30, 5)):
        a.ellipse(mx + cx - r, my + cy - r, mx + cx + r, my + cy + r, "#c2b8d0")
        a.ellipse(mx + cx - r + 1, my + cy - r + 1, mx + cx + r - 1, my + cy + r - 1, "#d6cee0")
        a.ellipse(mx + cx - r + 2, my + cy - r + 2, mx + cx + r, my + cy + r, "#b2a8c6") if r > 8 else None
    col_top, col_hi = "#2a2048", "#3a2c5c"
    for x0, yb in ((90, 360), (300, 400), (560, 380), (200, 330)):
        column(a, x0, 20, yb, rng, col_top, col_hi, r0=3, grow=0.06, drift=5)
    for y0, y1, c, cv in ((380, 560, "#5a3068", 0.3), (480, 720, "#8a3a54", 0.28)):
        for _ in range(14):
            cx = int(rng.integers(-40, 680)); cy = int(rng.integers(y0, y1))
            w = int(rng.integers(50, 130)); h = int(rng.integers(8, 18))
            m = a.mask("ellipse", cx - w, cy - h, cx + w, cy + h)
            a.stipple(m, c, cv)
            m = a.mask("ellipse", cx - w * 0.7, cy - h * 0.7, cx + w * 0.7, cy + h * 0.4)
            a.stipple(m, "#2c1a40", cv * 0.7)
    for x0, yb in ((140, 720), (420, 720), (610, 720)):
        column(a, x0, 380, yb, rng, "#4a2a52", "#6a3458", r0=6, grow=0.05, drift=9)
    for _ in range(90):
        x = int(rng.integers(0, 640)); y = int(rng.integers(380, 719))
        a.px(x, y, "#2a1a30" if rng.random() < 0.6 else "#f0a050")
    img = a.img
    arr = np.array(img).astype(float)
    ys = np.arange(720)
    t = np.clip((ys - 360) / 359.0, 0, 1)
    alpha = np.where(ys < 360, 255, np.round(255 * (1 - t))).astype(np.uint8)
    out = np.array(img)
    out[..., 3] = alpha[:, None]
    return Image.fromarray(out, "RGBA")


if __name__ == "__main__":
    img = build()
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "sky_pan.png"))
    bg = Image.new("RGBA", img.size, (60, 160, 60, 255))
    bg.alpha_composite(img)
    bg.resize((480, 540), Image.NEAREST).convert("RGB").save(os.path.join(HERE, "_preview", "sky.png"))
    print(img.size)
