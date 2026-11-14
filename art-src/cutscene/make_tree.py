import os
import numpy as np
from PIL import Image
from pxl import Canvas, rgb, count_colors, preview

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
BARK = ("#7a6676", "#54445a", "#382c42", "#1e1628")


def build():
    c = Canvas(90, 150)
    rng = np.random.default_rng(5)
    segs = [
        ((45, 150), (45, 92), 7.0, 5.0),
        ((45, 94), (44, 78), 5.0, 4.4),
        ((44, 80), (30, 52), 4.4, 3.0), ((30, 52), (20, 28), 3.0, 2.0), ((20, 28), (14, 8), 2.0, 1.2),
        ((30, 52), (40, 30), 2.4, 1.5), ((40, 30), (38, 12), 1.5, 1.0),
        ((22, 36), (6, 30), 1.6, 1.0), ((24, 44), (8, 50), 1.5, 1.0),
        ((44, 80), (56, 71), 4.2, 3.8), ((56, 71), (66, 67), 3.8, 3.4), ((66, 67), (82, 56), 3.4, 2.4),
        ((82, 56), (86, 40), 2.2, 1.2), ((74, 61), (74, 38), 1.8, 1.0), ((74, 40), (66, 24), 1.2, 0.8),
        ((82, 56), (88, 58), 1.6, 1.0),
        ((46, 98), (60, 90), 1.6, 1.0), ((44, 108), (30, 100), 1.6, 1.0),
    ]
    m = np.zeros((c.h, c.w), bool)
    for a, b, r0, r1 in segs:
        m |= c.capsule(a, b, r0, r1)
    root = c.poly([(36, 150), (40, 140), (50, 140), (55, 150)])
    m |= root
    c.stamp(m, BARK)
    for _ in range(40):
        x = int(rng.integers(40, 51)); y = int(rng.integers(95, 148))
        if m[y, x]:
            c.dot(x - c.ox, y - c.oy, BARK[3] if rng.random() < 0.6 else BARK[0])
    return c


if __name__ == "__main__":
    c = build()
    img = Image.fromarray(c.a, "RGBA")
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, "tree.png"))
    a = np.array(img)[..., 3]
    for x in (60, 62, 64, 66, 68):
        print(x, np.where(a[:, x] > 0)[0].min())
    preview(img, os.path.join(HERE, "_preview", "tree.png"), 5)
    print(img.size, count_colors(img))
