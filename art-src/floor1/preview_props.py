"""Contact sheet of the Floor 1 props on a brick backdrop, 6x nearest.
Run: python3 art-src/floor1/preview_props.py <out.png>
"""
import os
import sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
PROPS = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "props")) + "/"
ITEMS = [("lichen_floor", 4), ("lichen_wall", 4), ("torch_bracket", 4), ("skull_sconce", 4), ("neon_guild_sign", 3),
         ("pipe_h", 1), ("pipe_v", 1), ("grate", 1), ("sign_hazard", 1), ("sign_arrow_brick", 1), ("spray_arrow", 1), ("spray_x", 1)]

if __name__ == "__main__":
    sc = 5
    rows = []
    for name, n in ITEMS:
        im = Image.open(PROPS + name + ".png").convert("RGBA")
        rows.append(im)
    wmax = max(i.width for i in rows)
    total_h = sum(i.height + 6 for i in rows)
    canvas = Image.new("RGBA", (wmax + 8, total_h), (46, 22, 26, 255))
    y = 3
    for im in rows:
        canvas.paste(im, (4, y), im)
        y += im.height + 6
    canvas.resize((canvas.width * sc // 2 if False else canvas.width * 3, canvas.height * 3), Image.NEAREST).save(sys.argv[1])
