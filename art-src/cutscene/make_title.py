import json
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "dcc-side-scroller", "assets", "cutscene", "title_glyphs.png")
FONT = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
LETTERS = "DUNGEOSCRLA"
GH = 12
WIDTH_SCALE = 0.88
SKEW = 0.26
SIZES = (5, 8)
OUTLINE = (27, 16, 32, 255)
SHADOW = (74, 26, 60, 255)
HI = (255, 244, 150, 255)
TOP = (255, 226, 90, 255)
MID = (255, 196, 36, 255)
LOW = (255, 140, 28, 255)
EDGE = (214, 82, 26, 255)


def bitmap(ch):
    font = ImageFont.truetype(FONT, 140)
    img = Image.new("L", (220, 220), 0)
    ImageDraw.Draw(img).text((20, 10), ch, font=font, fill=255)
    box = img.getbbox()
    img = img.crop(box)
    gw = max(5, min(12, round(img.width / img.height * GH * WIDTH_SCALE)))
    small = img.resize((gw, GH), Image.BOX)
    return [[small.getpixel((x, y)) > 105 for x in range(gw)] for y in range(GH)]


def skewed(bits):
    gw = len(bits[0])
    extra = int((GH - 1) * SKEW) + 1
    out = [[False] * (gw + extra) for _ in range(GH)]
    for y in range(GH):
        shift = int((GH - 1 - y) * SKEW)
        for x in range(gw):
            if bits[y][x]:
                out[y][x + shift] = True
    return out


def dilate(mask, r=1):
    h, w = len(mask), len(mask[0])
    res = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if mask[y][x]:
                for dy in range(-r, r + 1):
                    for dx in range(-r, r + 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w:
                            res[yy][xx] = True
    return res


def style(bits, n):
    gw = len(bits[0])
    pad = 2
    w, h = gw + pad * 2 + 1, GH + pad * 2 + 1
    body = [[False] * w for _ in range(h)]
    for y in range(GH):
        for x in range(gw):
            body[y + pad][x + pad] = bits[y][x]
    outline = dilate(body, 1)
    shadow = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if outline[y][x] and y + 1 < h and x + 1 < w:
                shadow[y + 1][x + 1] = True
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if shadow[y][x]:
                img.putpixel((x, y), SHADOW)
    for y in range(h):
        for x in range(w):
            if outline[y][x]:
                img.putpixel((x, y), OUTLINE)
    for y in range(h):
        for x in range(w):
            if not body[y][x]:
                continue
            row = y - pad
            below = y + 1 < h and body[y + 1][x]
            above = y > 0 and body[y - 1][x]
            if not above:
                c = HI
            elif row < 4:
                c = TOP
            elif row < 8:
                c = MID
            else:
                c = LOW
            if not below:
                c = EDGE
            img.putpixel((x, y), c)
    return img.resize((w * n, h * n), Image.NEAREST), gw * n


def main():
    glyphs = {n: [] for n in SIZES}
    for ch in LETTERS:
        bits = skewed(bitmap(ch))
        for n in SIZES:
            glyphs[n].append(style(bits, n))
    cells = {}
    for n in SIZES:
        cells[n] = (max(g[0].width for g in glyphs[n]), max(g[0].height for g in glyphs[n]))
    width = max(cells[n][0] * len(LETTERS) for n in SIZES)
    height = sum(cells[n][1] for n in SIZES)
    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    y0 = 0
    info = {"letters": LETTERS, "rows": []}
    for n in SIZES:
        cw, ch_ = cells[n]
        adv = []
        for i, (img, advance) in enumerate(glyphs[n]):
            atlas.alpha_composite(img, (i * cw, y0))
            adv.append(advance)
        info["rows"].append({"n": n, "cell": [cw, ch_], "y": y0, "advance": adv})
        y0 += ch_
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    atlas.save(OUT)
    print(atlas.size)
    print(json.dumps(info))


main()
