import math
import os
from PIL import Image
from pxl import *
import carl, donut, goblin, engineer, make_carl_donut

OUTDIR = os.environ.get("DCC_ASSETS", "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/characters")
ROCK = ("#e2dce8", "#aba3be", "#6c6488")


def rock_frame(k):
    c = Canvas(8, 8)
    base = [3.0, 2.6, 3.1, 2.4, 3.0, 2.5, 2.9, 2.6, 3.0, 2.5]
    n = len(base)
    pts = []
    for i in range(n):
        a = i / n * math.tau + k * math.pi / 8
        pts.append((4 + math.cos(a) * base[i], 4 + math.sin(a) * base[i]))
    m = c.poly(pts)
    c.stamp(m, ROCK)
    c.dot(4 + math.cos(k * 1.1) * 1.0, 4 + math.sin(k * 1.1) * 1.0, ROCK[2])
    return c


def main():
    os.makedirs(OUTDIR, exist_ok=True)
    cs, ds = make_carl_donut.build()
    cs.save(os.path.join(OUTDIR, "carl.png"))
    ds.save(os.path.join(OUTDIR, "donut.png"))
    for kind, name in (("grunt", "goblin.png"), ("thrower", "goblin_thrower.png")):
        R = [[goblin.build(p, kind)[0] for p in r] for r in goblin.frames(kind)]
        sheet(R, 32, 32, 6).save(os.path.join(OUTDIR, name))
    R = [[engineer.build(p) for p in r] for r in engineer.frames()]
    sheet(R, 40, 40, 6).save(os.path.join(OUTDIR, "engineer.png"))
    sheet([[rock_frame(k) for k in range(4)]], 8, 8, 4).save(os.path.join(OUTDIR, "rock.png"))
    for n in ("carl", "donut", "goblin", "goblin_thrower", "engineer", "rock"):
        im = Image.open(os.path.join(OUTDIR, n + ".png"))
        print(n, im.size, count_colors(im))


if __name__ == "__main__":
    main()
