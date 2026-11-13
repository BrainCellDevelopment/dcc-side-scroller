import sys
import numpy as np
from PIL import Image
from platform_mirror import render

BG = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/bg/"
FX = (0.1, 0.3, 0.55)
FY = (0.04, 0.1, 0.18)
LAYERS = ("far", "mid", "near")
EXT = {"street": ("#0a0720", "#190e2a", "#150b26", "#0d0816"), "stairwell": ("#070b16", "#0a1020", "#0a1020", "#070b14"),
       "tunnel": ("#0b0e1b", "#0d1020", "#12172c", "#090c18"), "guildhall": ("#150f1c", "#1d110d", "#2a170f", "#140b08")}


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def bg_frame(style, cam, vis=(640, 360), anchor=180.0):
    W, H = vis
    out = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    for i, l in enumerate(LAYERS):
        im = Image.open(BG + f"bg_{style}_{l}.png").convert("RGBA")
        tw, th = im.size
        ox = round(W * 0.5 - cam[0] * FX[i])
        start = (ox % tw) - tw
        top = round(H * 0.5 - th * 0.5 - (cam[1] - anchor) * FY[i])
        ext = EXT[style]
        if i == 0:
            out.paste(hx(ext[0]) + (255,), (0, 0, W, top))
            out.paste(hx(ext[1]) + (255,), (0, top + th, W, H))
        elif i == 1:
            out.paste(hx(ext[2]) + (255,), (0, top + th, W, H))
        else:
            out.paste(hx(ext[3]) + (255,), (0, top + th, W, H))
        x = start
        while x < W:
            out.alpha_composite(im, (x, top)) if False else out.paste(im, (x, top), im)
            x += tw
    return out


def frame(style, cam=(1000, 180)):
    f = bg_frame(style, cam)
    plats = [(0, 300, 640, 16, 2), (40, 236, 96, 16, 0), (190, 200, 96, 16, 1), (340, 236, 112, 16, 2), (500, 190, 96, 16, 3), (270, 130, 64, 16, 2), (100, 150, 64, 48, 0)]
    for k, (x, y, w, h, s) in enumerate(plats):
        if k == 0:
            s = ["street", "stairwell", "tunnel", "guildhall"].index(style)
            s = (0, 1, 2, 3)[s]
        p = render(s, w, h)
        f.paste(p, (x, y), p)
    for (x, y, c) in ((90, 236, (240, 200, 120)), (230, 200, (240, 200, 120)), (700, 0, (0, 0, 0))):
        f.paste(Image.new("RGBA", (12, 20), c + (255,)), (x, y - 20))
    return f


if __name__ == "__main__":
    for st in ("street", "stairwell", "tunnel", "guildhall"):
        f = frame(st)
        f.resize((1280, 720), Image.NEAREST).save(f"/tmp/test_{st}.png")
