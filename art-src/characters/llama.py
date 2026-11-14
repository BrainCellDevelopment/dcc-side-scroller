"""Bad Llama art (#57): assets/characters/llama.png, assets/fx/lava_ball.png, assets/fx/lava_puddle.png.

Needs only Pillow. Run from anywhere: python3 art-src/characters/llama.py [preview.png]

llama.png rows (frame 72x56, feet at the bottom row, faces right, body centred on x=36):
  0 idle 4 | 1 walk 6 | 2 windup 3 | 3 spit 2 | 4 hurt 1 | 5 die 4 | 6 sleep 2 | 7 wake 2
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller", "assets")
FW, FH = 72, 56
OUT = (27, 18, 38, 255)


def rgb(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


WOOL = [rgb(c) for c in ("#f4e2b6", "#dcb987", "#b48c5e", "#7c5a3e")]
SKIN = [rgb(c) for c in ("#e6c8a0", "#c49a72", "#8e6a4a")]
HOOF = rgb("#3a2a2c")
TEETH = rgb("#fffaf0")
MOUTH = rgb("#8e2a44")
EYE = rgb("#1b1226")
EYE_HI = rgb("#ffe45e")
GLAND = [rgb(c) for c in ("#6e1f1c", "#c8481e", "#f5882a", "#ffc45a", "#fff0b0")]
ZED = rgb("#c8f5a0")


class Layer:
    def __init__(self):
        self.im = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)


def capsule(d, p0, p1, w, fill):
    d.line([p0, p1], fill=fill, width=w)
    r = w / 2.0
    for p in (p0, p1):
        d.ellipse([p[0] - r + 0.5, p[1] - r + 0.5, p[0] + r - 0.5, p[1] + r - 0.5], fill=fill)


def ell(d, cx, cy, rx, ry, fill):
    d.ellipse([round(cx - rx), round(cy - ry), round(cx + rx - 1), round(cy + ry - 1)], fill=fill)


def leg(d, hip, foot, col, hoof=True):
    capsule(d, hip, foot, 4, col)
    if hoof:
        d.rectangle([foot[0] - 2, foot[1] - 1, foot[0] + 2, foot[1]], fill=HOOF)


def pose_frame(p):
    """Draw one llama frame from a pose dict."""
    base = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    gy = 55
    by = p.get("by", 0.0)
    cx = 36 + p.get("dx", 0)
    lying = p.get("lying", False)
    body_cy = 33 + by if not lying else 44
    body_ry = 11 if not lying else 9
    hipf, hipb = (cx + 9, body_cy + 7), (cx - 10, body_cy + 7)
    if not lying:
        for (hx, hy), off, col in ((hipf, p.get("far_f", (0, 0)), SKIN[2]), (hipb, p.get("far_b", (0, 0)), SKIN[2])):
            leg(d, (hx - 2, hy), (hx - 2 + off[0], gy - off[1]), col)
    # tail
    tx, ty = cx - 15, body_cy - 3 + p.get("tail", 0)
    ell(d, tx - 1, ty, 3, 3, WOOL[2])
    # body
    ell(d, cx, body_cy, 17, body_ry + 1, WOOL[2])
    ell(d, cx, body_cy - 1, 16, body_ry, WOOL[1])
    ell(d, cx - 1, body_cy - 3, 13, body_ry - 4, WOOL[0])
    # wool tufts on the back
    for i in range(5):
        tx0 = cx - 11 + i * 5
        d.polygon([(tx0, body_cy - body_ry + 1), (tx0 + 2, body_cy - body_ry - 2 + (i % 2)), (tx0 + 4, body_cy - body_ry + 1)], fill=WOOL[0])
    # belly shade
    d.arc([cx - 15, body_cy - 6, cx + 15, body_cy + body_ry + 1], 20, 160, fill=WOOL[3])
    if not lying:
        for (hx, hy), off in ((hipf, p.get("near_f", (0, 0))), (hipb, p.get("near_b", (0, 0)))):
            leg(d, (hx + 1, hy), (hx + 1 + off[0], gy - off[1]), SKIN[1])
    else:
        capsule(d, (cx + 4, 50), (cx + 14, 53), 4, SKIN[1])
        capsule(d, (cx - 12, 51), (cx - 4, 53), 4, SKIN[1])
    # neck
    hx, hy = p["head"]
    hx, hy = hx + p.get("dx", 0), hy + by * 0.5
    sx, sy = cx + 12, body_cy - 3
    capsule(d, (sx, sy), (hx - 2, hy + 4), 9, WOOL[1])
    capsule(d, (sx - 1, sy - 2), (hx - 3, hy + 3), 5, WOOL[0])
    # throat gland (front of the neck, low)
    g = p.get("gland", 0)
    gx = round(sx + (hx - 2 - sx) * 0.55 + 3)
    gy2 = round(sy + (hy + 4 - sy) * 0.55 + 1)
    if g:
        ell(d, gx, gy2, 3 + (g > 1), 3 + (g > 1), GLAND[1])
        ell(d, gx, gy2, 2, 2, GLAND[2 + (g > 1)])
        d.point((gx, gy2 - 1), fill=GLAND[4])
        if g > 1:
            for ox, oy in ((-4, -3), (4, -2), (0, 5)):
                d.point((gx + ox, gy2 + oy), fill=GLAND[3])
    else:
        ell(d, gx, gy2, 2, 2, SKIN[0])
    # head
    tilt = p.get("tilt", 0)
    ell(d, hx, hy, 6, 5, WOOL[1])
    ell(d, hx + 5, hy + 1 + tilt, 5, 3, SKIN[0])
    ell(d, hx - 1, hy - 2, 4, 2, WOOL[0])
    mouth = p.get("mouth", "closed")
    my = round(hy + 3 + tilt)
    if mouth == "closed":
        d.line([(hx + 5, my), (hx + 9, my)], fill=OUT, width=1)
        d.point((hx + 8, my + 1), fill=TEETH)
    elif mouth in ("open", "spit"):
        jaw = 3 if mouth == "open" else 4
        d.polygon([(hx + 3, my - 1), (hx + 10, my - 1), (hx + 10, my + jaw), (hx + 3, my + jaw - 1)], fill=MOUTH)
        d.rectangle([hx + 4, my - 1, hx + 5, my], fill=TEETH)
        d.rectangle([hx + 8, my - 1, hx + 9, my], fill=TEETH)
        d.rectangle([hx + 6, my + jaw - 1, hx + 7, my + jaw], fill=TEETH)
        if mouth == "spit":
            ell(d, hx + 8, my + 1, 3, 3, GLAND[2])
            ell(d, hx + 8, my + 1, 2, 2, GLAND[3])
            d.point((hx + 8, my), fill=GLAND[4])
    # ears
    d.polygon([(hx - 4, hy - 3), (hx - 6, hy - 10 + p.get("ear", 0)), (hx - 1, hy - 5)], fill=WOOL[2])
    d.polygon([(hx - 1, hy - 4), (hx, hy - 11 + p.get("ear", 0)), (hx + 3, hy - 5)], fill=WOOL[1])
    # eye
    eyes = p.get("eyes", "open")
    ex, ey = round(hx + 1), round(hy - 1)
    if eyes == "open":
        d.rectangle([ex, ey, ex + 2, ey + 2], fill=EYE)
        d.point((ex + 1, ey), fill=EYE_HI)
    elif eyes == "angry":
        d.rectangle([ex, ey, ex + 2, ey + 2], fill=EYE)
        d.point((ex + 2, ey + 1), fill=EYE_HI)
        d.line([(ex - 1, ey - 2), (ex + 3, ey - 1)], fill=OUT, width=1)
    elif eyes == "closed":
        d.line([(ex, ey + 1), (ex + 3, ey + 1)], fill=EYE, width=1)
    elif eyes == "x":
        for a, b in ((0, 0), (2, 0), (1, 1), (0, 2), (2, 2)):
            d.point((ex + a, ey + b), fill=EYE)
    elif eyes == "wide":
        d.rectangle([ex - 1, ey - 1, ex + 3, ey + 3], fill=TEETH)
        d.rectangle([ex + 1, ey, ex + 2, ey + 2], fill=EYE)
    for sx0, sy0 in p.get("zs", []):
        for ox, oy in ((0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)):
            d.point((sx0 + ox, sy0 + oy), fill=ZED)
    for sx0, sy0 in p.get("stars", []):
        for ox, oy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            d.point((sx0 + ox, sy0 + oy), fill=EYE_HI)
    return outline(base)


def outline(im):
    a = im.split()[3]
    grown = a.filter(ImageFilter.MaxFilter(3))
    # 4-neighbour grow so the outline stays one pixel and not chunky on diagonals
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(Image.new("RGBA", im.size, OUT), mask=grown)
    out.alpha_composite(im)
    return out


def row_frames():
    L = dict
    stand = dict(head=(54, 14), eyes="angry", mouth="closed")
    idle = []
    for i, (by, tail, eyes, ear) in enumerate([(0, 0, "angry", 0), (0.6, 1, "angry", 0), (1.0, 1, "closed", 1), (0.4, 0, "angry", 0)]):
        idle.append(L(stand, by=by, tail=tail, eyes=eyes, ear=ear, head=(54, 14 + (by > 0.5)),
                      near_f=(0, 0), near_b=(0, 0), far_f=(0, 0), far_b=(0, 0)))
    walk = []
    cyc = [(4, 0), (2, 2), (-1, 1), (-4, 0), (-2, 2), (1, 1)]
    for i, (sw, lift) in enumerate(cyc):
        j = (i + 3) % 6
        sw2, lift2 = cyc[j]
        walk.append(L(stand, by=-(lift % 2) * 0.8, tail=i % 2, dx=0, near_f=(sw, lift), near_b=(sw2, lift2), far_f=(sw2, lift2), far_b=(sw, lift),
                      head=(54 + (1 if i % 3 == 0 else 0), 14 + (i % 2))))
    windup = [
        L(head=(52, 12), by=0.6, eyes="angry", mouth="closed", gland=1, ear=1, near_f=(-1, 0), near_b=(1, 0), far_f=(-1, 0), far_b=(1, 0)),
        L(head=(48, 5), by=1.2, eyes="angry", mouth="open", gland=2, ear=2, tilt=-1, near_f=(-2, 0), near_b=(2, 0), far_f=(-2, 0), far_b=(2, 0)),
        L(head=(46, 2), by=1.6, eyes="wide", mouth="open", gland=2, ear=2, tilt=-1, near_f=(-2, 0), near_b=(2, 0), far_f=(-2, 0), far_b=(2, 0)),
    ]
    spit = [
        L(head=(58, 12), by=0.0, eyes="angry", mouth="spit", gland=2, ear=0, dx=1, near_f=(2, 0), near_b=(-2, 0), far_f=(2, 0), far_b=(-2, 0)),
        L(head=(56, 15), by=-0.5, eyes="angry", mouth="open", gland=1, ear=0, dx=0, near_f=(1, 0), near_b=(-1, 0), far_f=(1, 0), far_b=(-1, 0)),
    ]
    hurt = [L(head=(48, 12), by=1.5, dx=-2, eyes="x" if False else "closed", mouth="open", ear=-1, tail=2, near_f=(-2, 0), near_b=(2, 0), far_f=(-1, 0), far_b=(1, 0), stars=[(60, 5)])]
    die = [
        L(head=(46, 12), by=2.0, dx=-2, eyes="x", mouth="open", ear=-2, near_f=(-3, 0), near_b=(3, 0), far_f=(-2, 0), far_b=(2, 0)),
        L(head=(48, 20), by=5.0, dx=-1, eyes="x", mouth="open", ear=-2, near_f=(-3, 2), near_b=(4, 1), far_f=(-2, 2), far_b=(3, 1)),
        L(head=(54, 33), by=9.0, lying=True, eyes="x", mouth="open", ear=-3, tail=3),
        L(head=(56, 38), by=0.0, lying=True, eyes="x", mouth="flat" if False else "open", ear=-3, tail=3, stars=[(52, 24)]),
    ]
    sleep = [
        L(head=(55, 40), lying=True, eyes="closed", mouth="closed", ear=-2, tilt=1, zs=[(60, 28)]),
        L(head=(55, 40), lying=True, by=-0.6, eyes="closed", mouth="closed", ear=-2, tilt=1, tail=1, zs=[(62, 22), (58, 30)]),
    ]
    wake = [
        L(head=(52, 18), by=3.0, eyes="wide", mouth="open", ear=2, near_f=(-2, 0), near_b=(1, 0), far_f=(-1, 0), far_b=(2, 0), stars=[(58, 6)]),
        L(head=(53, 10), by=0.5, eyes="angry", mouth="open", ear=2, near_f=(1, 0), near_b=(-1, 0), far_f=(1, 0), far_b=(-1, 0)),
    ]
    return [idle, walk, windup, spit, hurt, die, sleep, wake]


def build_llama():
    rows = row_frames()
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (FW * cols, FH * len(rows)), (0, 0, 0, 0))
    for ri, row in enumerate(rows):
        for ci, p in enumerate(row):
            sheet.paste(pose_frame(p), (ci * FW, ri * FH))
    return sheet


def build_lava_ball():
    s = 10
    sheet = Image.new("RGBA", (s * 4, s), (0, 0, 0, 0))
    for i in range(4):
        im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        wob = (0, 1, 0, -1)[i]
        d.ellipse([0, 0, 9, 9], fill=OUT)
        d.ellipse([1, 1, 8, 8], fill=GLAND[1])
        d.ellipse([2, 2 + (wob > 0), 7, 7], fill=GLAND[2])
        d.ellipse([3, 3, 6, 6 - (wob < 0)], fill=GLAND[3])
        d.point((4 + (i % 2), 4), fill=GLAND[4])
        d.point((1 + i, 9), fill=GLAND[2])
        sheet.paste(im, (i * s, 0))
    return sheet


def build_puddle():
    w, h = 32, 10
    sheet = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
    for i in range(4):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([0, 3, 31, 9], fill=OUT)
        d.ellipse([1, 4, 30, 9], fill=GLAND[0])
        d.ellipse([3, 4, 28, 8], fill=GLAND[1])
        d.ellipse([6, 5, 25, 8], fill=GLAND[2])
        d.ellipse([11, 5, 20, 7], fill=GLAND[3])
        for k, bx in enumerate((7, 14, 22)):
            ph = (i + k) % 4
            if ph == 0:
                d.rectangle([bx, 3, bx + 1, 4], fill=GLAND[3])
            elif ph == 1:
                d.point((bx, 2), fill=GLAND[2])
                d.point((bx + 1, 3), fill=GLAND[4])
            elif ph == 2:
                d.point((bx, 1), fill=GLAND[1])
        sheet.paste(im, (i * w, 0))
    return sheet


def main():
    llama = build_llama()
    llama.save(os.path.join(ASSETS, "characters", "llama.png"))
    build_lava_ball().save(os.path.join(ASSETS, "fx", "lava_ball.png"))
    build_puddle().save(os.path.join(ASSETS, "fx", "lava_puddle.png"))
    if len(sys.argv) > 1:
        scale = 4
        prev = Image.new("RGBA", (llama.width, llama.height), (40, 28, 36, 255))
        prev.alpha_composite(llama)
        prev.resize((prev.width * scale, prev.height * scale), Image.NEAREST).save(sys.argv[1])
    print("wrote llama.png", llama.size)


if __name__ == "__main__":
    main()
