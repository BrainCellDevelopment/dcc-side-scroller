import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "dcc-side-scroller", "assets", "characters", "pineapple.png")
S = 24
OUTLINE = (40, 28, 20, 255)
STICK = (150, 100, 55, 255)
STICK_L = (190, 135, 80, 255)
BODY = (240, 200, 45, 255)
BODY_L = (255, 232, 110, 255)
BODY_D = (190, 140, 25, 255)
LEAF = (70, 165, 70, 255)
LEAF_D = (35, 100, 45, 255)


def base():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([10, 12, 13, 23], fill=OUTLINE)
    d.rectangle([11, 12, 12, 22], fill=STICK)
    d.line([(11, 13), (11, 22)], fill=STICK_L)
    d.ellipse([6, 3, 17, 15], fill=BODY, outline=OUTLINE)
    d.ellipse([8, 5, 11, 8], fill=BODY_L)
    for x in range(7, 17, 3):
        for y in range(5, 15, 3):
            if (x + y) % 2 == 0:
                for px, py in ((x, y), (x + 1, y + 1)):
                    if im.getpixel((px, py)) == BODY:
                        d.point((px, py), fill=BODY_D)
    d.rectangle([10, 13, 13, 14], fill=OUTLINE)
    d.rectangle([11, 13, 12, 14], fill=STICK)
    leaves = [((9, 4), (6, 0), LEAF), ((11, 3), (10, 0), LEAF_D), ((12, 3), (13, 0), LEAF), ((14, 4), (17, 0), LEAF_D)]
    for a, b, c in leaves:
        d.line([a, b], fill=OUTLINE, width=3)
        d.line([a, b], fill=c, width=1)
    return im


def main():
    sheet = Image.new("RGBA", (S * 4, S), (0, 0, 0, 0))
    im = base()
    for i in range(4):
        sheet.paste(im.rotate(-90 * i, resample=Image.NEAREST), (S * i, 0))
    sheet.save(OUT)
    print("wrote", os.path.abspath(OUT))


main()
