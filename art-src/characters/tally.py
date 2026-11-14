import os
from pxl import Canvas, sheet, preview, count_colors

OUTDIR = os.environ.get("DCC_ASSETS", os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller", "assets", "characters"))
PV = os.environ.get("DCC_PREVIEW", os.path.join(os.path.dirname(os.path.abspath(__file__)), "_pv"))
FW, FH = 32, 40

FUR = ("#c9b79a", "#a8946f", "#7f6a52", "#574636")
SKIN = ("#ffd2b4", "#f0a98c", "#cf7c6c", "#9a5058")
NOSE = ("#ffb0a0", "#e8766c", "#b84a58", "#7c2c44")
APRON = ("#dbe9ff", "#8fb4ee", "#5f86c8", "#3d5a94")
HAT = ("#ffffff", "#f1ece4", "#cfc6c0", "#9a8f98")
SHOE = ("#8a6a58", "#6a4a40", "#4a3030")
EYE = "#1b1226"
WHITE = "#ffffff"


def frame(bob=0, blink=False, mouth=0, arm=0):
    c = Canvas(FW, FH)
    by = bob
    for fx in (11, 19):
        c.stamp(c.ell(fx, 38.2, 3.6, 1.8), SHOE)
    body = c.box(9, 24 + by, 23, 37) | c.ell(16, 26 + by, 7.5, 4.5)
    c.stamp(body, FUR)
    apron = c.box(11, 26 + by, 21, 38) | c.ell(16, 27 + by, 5.0, 2.5)
    c.stamp(apron, APRON)
    c.fill(c.box(13, 30 + by, 19, 33 + by), APRON[0])
    c.fill(c.box(13, 30 + by, 19, 31 + by), APRON[3])
    ha = (7 + arm, 29 + by)
    c.stamp(c.capsule((10, 27 + by), ha, 1.6, 1.4), FUR)
    c.stamp(c.disc(ha[0], ha[1], 1.8), SKIN)
    c.stamp(c.capsule((22, 27 + by), (25, 31 + by), 1.6, 1.4), FUR)
    c.stamp(c.disc(25, 31 + by, 1.8), SKIN)
    head = c.ell(16, 16 + by, 8.5, 7.5)
    c.stamp(head, FUR)
    c.stamp(c.ell(16, 18 + by, 6.2, 5.0), SKIN)
    c.stamp(c.disc(16, 19 + by, 2.4), NOSE)
    for ex in (12.5, 19.5):
        if blink:
            c.fill(c.box(int(ex) - 1, 15 + by, int(ex) + 1, 16 + by), EYE)
        else:
            c.fill(c.box(int(ex) - 1, 14 + by, int(ex) + 1, 16 + by), EYE)
            c.dot(ex - 1, 14 + by, WHITE)
    if mouth:
        c.fill(c.box(14, 22 + by, 19, 22 + mouth + by), "#6a2a40")
    c.stamp(c.box(12, 23 + by, 20, 25 + by), FUR)
    hat = c.box(10, 7 + by, 22, 12 + by)
    c.stamp(hat, HAT)
    c.fill(c.box(10, 11 + by, 22, 12 + by), APRON[2])
    return c


def idle():
    return [frame(0), frame(0), frame(1, blink=True), frame(1)]


def talk():
    return [frame(0, mouth=2, arm=-1), frame(0, mouth=1, arm=1), frame(1, mouth=2, arm=-1), frame(0, mouth=0, arm=0)]


if __name__ == "__main__":
    os.makedirs(OUTDIR, exist_ok=True)
    os.makedirs(PV, exist_ok=True)
    s = sheet([idle(), talk()], FW, FH, 4)
    s.save(os.path.join(OUTDIR, "tally.png"))
    preview(s, os.path.join(PV, "tally.png"), 8, fw=FW, fh=FH)
    print(s.size, count_colors(s))
