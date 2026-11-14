import os
from PIL import Image, ImageDraw

ASSETS = os.path.join(os.path.dirname(__file__), "..", "..", "dcc-side-scroller", "assets")
MISSILE_W, MISSILE_H = 14, 8
IMPACT = 24
CORE = (255, 250, 255, 255)
HOT = (225, 190, 255, 255)
MID = (170, 105, 235, 255)
DEEP = (100, 55, 185, 255)
RIM = (52, 28, 110, 255)
GLOW = (170, 105, 235, 90)
SPARK = (190, 235, 255, 255)


def missile_frame(i):
    im = Image.new("RGBA", (MISSILE_W, MISSILE_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    wob = (0, 1, 0, -1)[i]
    d.ellipse([6, 0, 13, 7], fill=GLOW)
    d.polygon([(0, 4 + wob), (6, 1), (6, 6)], fill=DEEP)
    d.polygon([(2, 4 + wob // 2), (6, 2), (6, 5)], fill=MID)
    d.ellipse([6, 1, 12, 6], fill=RIM)
    d.ellipse([7, 2, 12, 5], fill=MID)
    d.ellipse([8, 2, 12, 5], fill=HOT)
    d.rectangle([9, 3, 11, 4], fill=CORE)
    if i % 2 == 0:
        d.point((1, 2 + wob), fill=SPARK)
    else:
        d.point((3, 6 - wob), fill=SPARK)
    return im


def impact_frame(i):
    im = Image.new("RGBA", (IMPACT, IMPACT), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = IMPACT // 2
    r = (3, 6, 9, 10, 11)[i]
    a = (255, 235, 190, 120, 50)[i]
    if i < 4:
        d.ellipse([c - r, c - r, c + r - 1, c + r - 1], fill=(DEEP[0], DEEP[1], DEEP[2], a))
        d.ellipse([c - r + 2, c - r + 2, c + r - 3, c + r - 3], fill=(MID[0], MID[1], MID[2], a))
    if i < 3:
        d.ellipse([c - r // 2, c - r // 2, c + r // 2 - 1, c + r // 2 - 1], fill=(CORE[0], CORE[1], CORE[2], 255))
    spokes = ((0, 0, 0, 0), (4, 6, 4, 6), (7, 10, 7, 10), (9, 12, 9, 12), (10, 12, 10, 12))[i]
    n = 8
    import math
    for k in range(n):
        ang = k * math.pi * 2 / n + 0.3
        r0, r1 = spokes[0] + 2, spokes[1] + 2
        if i == 0:
            continue
        x0, y0 = c + math.cos(ang) * r0, c + math.sin(ang) * r0
        x1, y1 = c + math.cos(ang) * r1, c + math.sin(ang) * r1
        d.line([(x0, y0), (x1, y1)], fill=SPARK if i < 3 else (SPARK[0], SPARK[1], SPARK[2], 140), width=1)
    return im


def main():
    sheet = Image.new("RGBA", (MISSILE_W * 4, MISSILE_H), (0, 0, 0, 0))
    for i in range(4):
        sheet.paste(missile_frame(i), (MISSILE_W * i, 0))
    sheet.save(os.path.join(ASSETS, "fx", "magic_missile.png"))
    sheet = Image.new("RGBA", (IMPACT * 5, IMPACT), (0, 0, 0, 0))
    for i in range(5):
        sheet.paste(impact_frame(i), (IMPACT * i, 0))
    sheet.save(os.path.join(ASSETS, "fx", "magic_impact.png"))
    print("wrote magic_missile.png and magic_impact.png")


main()
