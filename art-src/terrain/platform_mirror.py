import numpy as np
from PIL import Image

TILES = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/tiles/"
NAMES = ["rubble", "iron", "stone", "wood"]
OUTLINE = [(0x1b, 0x12, 0x26), (0x12, 0x10, 0x1c), (0x12, 0x10, 0x1f), (0x1f, 0x14, 0x10)]
_cache = {}


def tex(i):
    if i not in _cache:
        _cache[i] = np.array(Image.open(TILES + f"tiles_{NAMES[i]}.png").convert("RGBA"))
    return _cache[i]


def variant(cx, cy, style):
    h = (cx * 374761393 + cy * 668265263 + style * 144665) & 0x7FFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF
    return (h >> 7) & 1


def render(style, w, h):
    t = tex(style)
    out = np.zeros((h, w, 4), dtype=np.uint8)

    def blit(sx, sy, sw, sh, dx, dy):
        out[dy:dy + sh, dx:dx + sw] = t[sy:sy + sh, sx:sx + sw]

    cols = (w + 15) // 16
    rows = (h + 15) // 16
    for ry in range(rows):
        for cx in range(cols):
            tw = min(16, w - cx * 16)
            th = min(16, h - ry * 16)
            src = 0 if ry == 0 else 16 + 16 * variant(cx, ry, style)
            blit(src, 0, tw, th, cx * 16, ry * 16)
        y = ry * 16
        th = min(16, h - y)
        y0 = 5 if ry == 0 else 0
        if th > y0:
            blit(48 + 1, y0, 3, th - y0, 1, y + y0)
            blit(48 + 12, y0, 3, th - y0, w - 4, y + y0)
    o = np.array(OUTLINE[style] + (255,), dtype=np.uint8)
    out[:, 0] = o
    out[:, w - 1] = o
    out[h - 1, :] = o
    out[0, 0] = o
    out[0, w - 1] = o
    if h >= 16:
        sh = out[h - 3:h - 1, 1:w - 1].astype(float)
        sh[..., :3] *= 0.55
        out[h - 3:h - 1, 1:w - 1] = sh.astype(np.uint8)
    return Image.fromarray(out, "RGBA")
