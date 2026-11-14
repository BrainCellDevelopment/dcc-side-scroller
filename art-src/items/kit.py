import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller", "assets", "ui", "items")
SIZE = 16
OUTLINE = (34, 20, 32, 255)
WHITE = (255, 255, 255, 255)
STEEL = (140, 170, 200, 255)
STEEL_L = (190, 215, 235, 255)
STEEL_D = (96, 120, 150, 255)
WOOD = (176, 120, 72, 255)
WOOD_D = (120, 76, 44, 255)
RED = (214, 48, 64, 255)
RED_L = (255, 110, 120, 255)
RED_D = (140, 24, 48, 255)
GOLD = (240, 196, 48, 255)
GOLD_L = (255, 236, 130, 255)
GOLD_D = (190, 130, 28, 255)
GREEN = (80, 176, 80, 255)
GREEN_D = (40, 110, 60, 255)
BLUE = (70, 120, 220, 255)
BLUE_L = (130, 180, 255, 255)
BLUE_D = (40, 70, 150, 255)
PURPLE = (140, 80, 190, 255)
PURPLE_L = (190, 140, 235, 255)
PURPLE_D = (84, 44, 124, 255)
ORANGE = (240, 140, 40, 255)
BROWN = (110, 70, 50, 255)
SKIN = (240, 190, 140, 255)
GREY = (150, 150, 160, 255)
GREY_D = (90, 90, 104, 255)
CREAM = (250, 235, 200, 255)


def render(rows, palette):
    assert len(rows) == SIZE, "need %d rows, got %d" % (SIZE, len(rows))
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        assert len(row) == SIZE, "row %d has %d chars: %r" % (y, len(row), row)
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            img.putpixel((x, y), palette[ch])
    return img


def save(item_id, rows, palette):
    os.makedirs(OUT, exist_ok=True)
    img = render(rows, palette)
    img.save(os.path.join(OUT, item_id + ".png"))
    return img


def sheet(ids, path, scale=8, cols=8):
    imgs = [Image.open(os.path.join(OUT, i + ".png")).convert("RGBA") for i in ids]
    rows = (len(imgs) + cols - 1) // cols
    pad = 4
    cell = SIZE * scale + pad
    sh = Image.new("RGBA", (cols * cell, rows * cell), (60, 50, 80, 255))
    for k, im in enumerate(imgs):
        sh.alpha_composite(im.resize((SIZE * scale, SIZE * scale), Image.NEAREST), ((k % cols) * cell + pad // 2, (k // cols) * cell + pad // 2))
    sh.save(path)
