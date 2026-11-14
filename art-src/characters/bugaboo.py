"""Mordecai's Floor 2 form: a Bugaboo, a tall black bear-like creature with huge owl eyes and thin limbs.
Original art drawn procedurally with PIL. 40x52 frames, feet on the bottom row, faces right.
bugaboo.png rows: idle(4) talk(4). Run: python3 art-src/characters/bugaboo.py
"""
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "characters"))
FW, FH = 40, 52
OUT = (14, 10, 20, 255)
FUR = (48, 42, 58, 255)
FUR_D = (30, 26, 40, 255)
FUR_L = (84, 74, 96, 255)
EYE_W = (246, 240, 214, 255)
EYE_Y = (255, 200, 52, 255)
PUPIL = (20, 12, 16, 255)
MOUTH = (96, 30, 48, 255)
CLAW = (214, 204, 186, 255)
VEST = (126, 84, 44, 255)


def outline(img):
    px = img.load()
    w, h = img.size
    mark = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                        mark.append((x, y))
                        break
    for x, y in mark:
        px[x, y] = OUT


def frame(bob=0, talk=0, arm=0, blink=False):
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b = bob
    # legs
    d.rectangle((13, 41 + b, 17, 50), fill=FUR_D)
    d.rectangle((22, 41 + b, 26, 50), fill=FUR_D)
    d.rectangle((12, 50, 18, 51), fill=FUR)
    d.rectangle((21, 50, 27, 51), fill=FUR)
    # hunched body
    d.ellipse((8, 20 + b, 31, 45 + b), fill=FUR)
    d.ellipse((10, 22 + b, 24, 34 + b), fill=FUR_L)
    d.rectangle((13, 30 + b, 26, 40 + b), fill=VEST)
    d.line([(20, 30 + b), (20, 40 + b)], fill=FUR_D, width=1)
    # thin arms
    ay = 30 + b
    d.line([(10, 26 + b), (6, ay + 8 - arm), (7, ay + 14)], fill=FUR, width=2)
    d.line([(29, 26 + b), (33, ay + 6 - arm * 2), (35, ay + 11 - arm * 3)], fill=FUR, width=2)
    d.point([(7, ay + 15), (35, ay + 12 - arm * 3), (36, ay + 12 - arm * 3)], fill=CLAW)
    # head: round with big ears
    d.ellipse((9, 5 + b, 31, 26 + b), fill=FUR)
    d.ellipse((7, 3 + b, 14, 10 + b), fill=FUR_D)
    d.ellipse((26, 3 + b, 33, 10 + b), fill=FUR_D)
    # owl eyes
    for ex in (13, 22):
        d.ellipse((ex, 10 + b, ex + 8, 19 + b), fill=EYE_W)
        if blink:
            d.line([(ex, 15 + b), (ex + 8, 15 + b)], fill=PUPIL, width=1)
        else:
            d.ellipse((ex + 2, 12 + b, ex + 7, 18 + b), fill=EYE_Y)
            d.rectangle((ex + 4, 13 + b, ex + 5, 17 + b), fill=PUPIL)
    # muzzle and mouth
    d.ellipse((15, 19 + b, 27, 26 + b), fill=FUR_L)
    d.point([(20, 20 + b), (21, 20 + b)], fill=PUPIL)
    if talk:
        d.rectangle((17, 23 + b, 24, 24 + b + talk), fill=MOUTH)
    else:
        d.line([(17, 23 + b), (24, 23 + b)], fill=PUPIL, width=1)
    outline(img)
    return img


def main():
    rows = [
        [frame(bob=0), frame(bob=1), frame(bob=0, blink=True), frame(bob=1)],
        [frame(talk=1, arm=0), frame(talk=2, arm=1), frame(talk=1, arm=0), frame(talk=2, arm=2)],
    ]
    out = Image.new("RGBA", (FW * 4, FH * 2), (0, 0, 0, 0))
    for r, row in enumerate(rows):
        for c, fr in enumerate(row):
            out.paste(fr, (c * FW, r * FH))
    path = os.path.join(DEST, "bugaboo.png")
    out.save(path)
    print("wrote", path, out.size)


if __name__ == "__main__":
    main()
