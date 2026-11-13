#!/usr/bin/env python3
import numpy as np
from PIL import Image

ROOT = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/props/"
W, H = 96, 112
FRAMES = 5
DARK = (22, 15, 20, 255)
DARK2 = (34, 24, 30, 255)

src = np.array(Image.open(ROOT + "big_door.png").convert("RGBA"))

yy, xx = np.mgrid[0:H, 0:W]
ell = ((xx - 47.5) / 39.0) ** 2 + ((yy - 30.0) / 22.0) ** 2 <= 1.0
box = (xx >= 9) & (xx <= 86) & (yy >= 30) & (yy <= 103)
inner = (box | (ell & (yy < 30) & (xx >= 9) & (xx <= 86))) & (yy <= 103)

base = src.copy()
base[inner] = DARK
for y in range(H):
    for x in range(W):
        if inner[y, x] and (y // 6 + x // 6) % 2 == 0:
            base[y, x] = DARK2

sheet = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
for f in range(FRAMES):
    p = f / (FRAMES - 1)
    frame = base.copy()
    for x0, x1, hinge in ((9, 47, "l"), (48, 86, "r")):
        width = x1 - x0 + 1
        nw = max(2, int(round(width * (1.0 - 0.88 * p))))
        for nx in range(nw):
            sx = int(nx * width / nw)
            dx = x0 + nx if hinge == "l" else x1 - nw + 1 + nx
            sxx = x0 + sx
            for y in range(H):
                if inner[y, sxx] and inner[y, dx]:
                    frame[y, dx] = src[y, sxx]
    sheet.paste(Image.fromarray(frame), (f * W, 0))
sheet.save(ROOT + "door.png")
print("door.png", sheet.size)
