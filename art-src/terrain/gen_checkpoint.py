import numpy as np
from PIL import Image
from pix import hx

OUT = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/props/checkpoint.png"
OL = "#1b1226"
I0, I1, I2, I3 = "#2a2c44", "#444a70", "#6a74a0", "#a4b0d8"
G0, G1 = "#2e2a40", "#3e3a56"
F = ["#b8322e", "#f06a2a", "#ffb347", "#ffe27a"]


class S:
    def __init__(self, w, h):
        self.a = np.zeros((h, w, 4), dtype=np.uint8)

    def p(self, x, y, c):
        if 0 <= y < self.a.shape[0] and 0 <= x < self.a.shape[1]:
            self.a[y, x] = hx(c) + (255,)

    def r(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)


def post(s, ox, oy, lit_state, frame):
    P = lambda x, y, c: s.p(ox + x, oy + y, c)
    R = lambda x0, y0, x1, y1, c: s.r(ox + x0, oy + y0, ox + x1, oy + y1, c)
    R(5, 36, 18, 39, OL)
    R(6, 36, 17, 38, I1)
    R(6, 36, 17, 36, I3)
    R(6, 38, 17, 38, I0)
    R(8, 33, 15, 35, OL)
    R(9, 33, 14, 35, I1)
    R(9, 33, 14, 33, I2)
    R(9, 35, 14, 35, I0)
    R(10, 16, 13, 33, OL)
    R(11, 16, 12, 33, I1)
    R(11, 16, 11, 33, I2)
    R(12, 16, 12, 33, I0)
    for y in (22, 27):
        R(10, y, 13, y + 1, OL)
        R(11, y, 11, y, I3)
        R(12, y, 12, y, I1)
    R(7, 15, 16, 17, OL)
    R(8, 15, 15, 16, I2)
    R(8, 15, 15, 15, I3)
    R(8, 16, 15, 16, I1)
    R(5, 3, 18, 4, OL)
    R(8, 1, 15, 2, OL)
    R(9, 2, 14, 2, I2)
    R(10, 0, 13, 1, OL)
    R(7, 4, 16, 4, I2)
    R(6, 5, 17, 5, I1)
    R(6, 5, 6, 14, OL)
    R(17, 5, 17, 14, OL)
    R(7, 5, 7, 14, I2)
    R(16, 5, 16, 14, I0)
    R(8, 6, 15, 13, OL)
    R(8, 14, 15, 14, I0)
    R(7, 14, 16, 14, OL)
    R(7, 14, 16, 14, I1)
    R(11, 5, 12, 13, OL) if False else None
    if not lit_state:
        R(9, 7, 14, 12, "#1a1830")
        R(9, 7, 10, 8, "#2a2846")
        R(10, 11, 13, 12, "#26243c")
        P(11, 10, "#3a3858")
    else:
        glass = ["#6a2a2a", "#8a3a22"]
        R(9, 7, 14, 12, glass[0])
        R(9, 7, 14, 7, glass[1])
        flick = [(0, 0), (1, -1), (0, 1), (-1, 0)][frame]
        h = [5, 6, 5, 4][frame]
        cx = 11 + (frame % 2)
        base_y = 12
        for i in range(h):
            w = 2 if i < h - 2 else 1
            for dx in range(-w + 1, w + 1) if w > 1 else (0, 1):
                P(cx + dx - (0 if w > 1 else 0), base_y - i, F[1] if i < h - 1 else F[0])
        R(10, 10, 13, 12, F[1])
        R(11, 9, 12, 12, F[2])
        R(11, 11, 12, 12, F[3])
        P(cx, base_y - h + 1, F[0])
        P(cx + (1 if frame % 2 else 0), base_y - h + 2, F[1])
        R(9, 12, 14, 12, F[1])
        P(9, 8, "#ffb347")
        P(14, 8, "#ffb347") if frame % 2 else None
    P(7, 5, I3)
    P(8, 4, I3)


def make():
    s = S(96, 80)
    post(s, 0, 0, False, 0)
    for f in range(4):
        post(s, f * 24, 40, True, f)
    return Image.fromarray(s.a, "RGBA")


if __name__ == "__main__":
    img = make()
    img.save(OUT)
    bg = Image.new("RGBA", img.size, (30, 24, 50, 255))
    bg.paste(img, (0, 0), img)
    bg.resize((96 * 6, 80 * 6), Image.NEAREST).save("/tmp/preview_checkpoint.png")
