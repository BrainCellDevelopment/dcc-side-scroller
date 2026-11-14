"""Floor 1 props: lichen clusters, torch bracket, skull sconce, pipes, grate, signs,
the neon "Da Tutorial Guild" sign and spray-paint arrows.

All decor only (no collision). Sheets are row-based (one row, N frames) for animated
props and single images for static ones. Output: dcc-side-scroller/assets/props/.
Run: python3 art-src/floor1/gen_props_floor1.py
"""
import os
import sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "props"))
sys.path.insert(0, HERE)
import pxlib  # noqa: E402
from pxlib import Cv, rect, ell, poly, line, paint, flat, speckle, exterior_outline, flame, glow_halo, sheet, save  # noqa: E402
import palette as P  # noqa: E402

pxlib.OL = P.hx(P.OUTLINE)
OLC = pxlib.OL
BR = P.rgb(P.BRICK[1:])
LI = P.rgb(P.LICHEN)
TO = P.rgb(P.TORCH)
BO = P.rgb(P.BONE)
WE = P.rgb(P.WET)
PL = P.rgb(P.PLANK)
IR = P.rgb(P.IRON)
FLAME_COLS = (TO[0], TO[1], TO[3], TO[4])
GL_G1, GL_G2 = (28, 74, 56), (18, 46, 44)
GL_O1, GL_O2 = (110, 44, 30), (66, 28, 28)


# ------------------------------------------------------------------ lichen
def lichen_floor_frame(k):
    """Low mat of lichen growing on the floor, 32x14, origin bottom-centre."""
    cv = Cv(32, 14)
    pulse = [0, 1, 2, 1][k]
    rs = np.random.RandomState(5)
    blobs = [(16, 12, 9, 3), (6, 12, 4, 2), (26, 12, 4, 2), (11, 9, 3, 2), (21, 9, 3, 2)]
    for (x, y, rx, ry) in blobs:
        paint(cv, ell(cv, x - rx, y - ry, x + rx, y + ry) & (np.arange(14)[:, None] <= 13), [LI[0], LI[0], LI[1], LI[2], LI[3]], hl=1, sd=1)
    for (x, y, rx, ry) in blobs:
        for i in range(3):
            sx = x + rs.randint(-rx + 1, rx)
            sy = y + rs.randint(-ry + 1, ry)
            cv.px(sx, sy, LI[3 + (1 if pulse >= 1 else 0)] if i == 0 else LI[2 + (1 if pulse == 2 else 0)])
    # flatten the base so it sits on the floor
    cv.a[13, :, :] = np.where(cv.a[13, :, 3:4] > 0, np.array([*OLC, 255], np.uint8), 0)
    glow_halo(cv, 16, 9, 13 + pulse, 17 + pulse, GL_G1, GL_G2)
    cv.a[13, :, :] = np.where(cv.a[13, :, 3:4] > 0, np.array([*LI[0], 255], np.uint8), 0)
    return cv


def lichen_wall_frame(k):
    """Lichen creeping up a wall from the floor, 24x30, origin bottom-centre."""
    cv = Cv(24, 30)
    pulse = [0, 1, 2, 1][k]
    rs = np.random.RandomState(9)
    blobs = [(12, 26, 8, 3), (7, 21, 4, 3), (16, 20, 4, 3), (10, 15, 3, 3), (15, 12, 3, 2), (8, 9, 2, 2)]
    for (x, y, rx, ry) in blobs:
        paint(cv, ell(cv, x - rx, y - ry, x + rx, y + ry), [LI[0], LI[0], LI[1], LI[2], LI[3]], hl=1, sd=1)
    for (x, y, rx, ry) in blobs:
        for i in range(3):
            sx = x + rs.randint(-rx + 1, rx)
            sy = y + rs.randint(-ry + 1, ry)
            cv.px(sx, sy, LI[3 + (1 if pulse >= 1 else 0)] if i == 0 else LI[2 + (1 if pulse == 2 else 0)])
    glow_halo(cv, 12, 18, 11 + pulse, 15 + pulse, GL_G1, GL_G2)
    return cv


# ------------------------------------------------------------------ torches
def torch_bracket_frame(k):
    """Iron wall bracket with a wrapped torch, 22x36, origin centre."""
    cv = Cv(22, 36)
    paint(cv, rect(cv, 9, 20, 12, 34), PL)
    paint(cv, rect(cv, 6, 24, 15, 28), IR)
    paint(cv, rect(cv, 7, 31, 14, 34), IR)
    paint(cv, rect(cv, 6, 13, 15, 20), [P.hx(P.BRICK[0]), IR[0], IR[1], IR[2], IR[3]])
    flat(cv, rect(cv, 7, 14, 8, 14), TO[1])
    cv.px(13, 17, TO[2])
    cv.px(10, 26, IR[4])
    flame(cv, 10, 13, 13 + (k % 2), 4.8, k * 1.7, sway=[-1.2, 0.6, 1.4, -0.4][k], cols=FLAME_COLS)
    glow_halo(cv, 10.5, 8, 9, 13, GL_O1, GL_O2)
    return cv


def skull_sconce_frame(k):
    """Bone skull holding a flame, 20x32, origin centre. The Hoarder's lair uses these."""
    cv = Cv(20, 32)
    # iron cup
    paint(cv, rect(cv, 5, 12, 14, 16), IR)
    # skull
    paint(cv, ell(cv, 3, 14, 16, 26), BO, hl=1, sd=1)
    paint(cv, rect(cv, 6, 24, 13, 30), BO, hl=1, sd=1, ol=False)
    flat(cv, rect(cv, 5, 19, 8, 22), P.hx(P.BRICK[0]))
    flat(cv, rect(cv, 11, 19, 14, 22), P.hx(P.BRICK[0]))
    flat(cv, rect(cv, 9, 23, 10, 24), P.hx(P.BRICK[0]))
    for x in (7, 9, 11):
        cv.px(x, 28, P.hx(P.BRICK[0]))
        cv.px(x, 29, P.hx(P.BRICK[0]))
    cv.px(5, 20, TO[2] if k % 2 else TO[1])
    cv.px(12, 20, TO[2] if k % 2 == 0 else TO[1])
    flame(cv, 9, 12, 10 + (k % 2), 4.2, k * 1.9, sway=[-1, 0.8, 1.2, -0.6][k], cols=FLAME_COLS)
    glow_halo(cv, 9.5, 6, 8, 12, GL_O1, GL_O2)
    return cv


# ------------------------------------------------------------------ static props
def pipe_h():
    """Horizontal pipe run with flanges and a drip stain, 64x14, origin centre."""
    cv = Cv(64, 14)
    from pxlib import cyl_h
    cyl_h(cv, rect(cv, 0, 4, 63, 9), IR)
    for x in (10, 30, 50):
        paint(cv, rect(cv, x, 2, x + 3, 11), IR)
        cv.px(x + 1, 3, IR[4])
        cv.px(x + 1, 10, IR[0])
    # rust drip
    for y in range(10, 14):
        cv.px(40, y, P.hx(P.BRICK[3]) if y < 13 else P.hx(P.TORCH[1]))
    cv.px(22, 5, TO[1])
    cv.px(23, 5, TO[1])
    return cv


def pipe_v():
    """Vertical pipe with a bracket and a lichen dab, 14x64, origin bottom-centre."""
    cv = Cv(14, 64)
    from pxlib import cyl_v
    cyl_v(cv, rect(cv, 4, 0, 9, 63), IR)
    for y in (8, 28, 48):
        paint(cv, rect(cv, 2, y, 11, y + 3), IR)
        cv.px(3, y + 1, IR[4])
    for (x, y) in ((5, 40), (6, 40), (5, 41), (4, 39)):
        cv.px(x, y, LI[2])
    cv.px(6, 39, LI[3])
    return cv


def grate():
    """Wall grate over a dark void, 32x20, origin centre."""
    cv = Cv(32, 20)
    paint(cv, rect(cv, 0, 0, 31, 19), [P.hx(P.BRICK[0]), IR[0], IR[1], IR[2], IR[3]], hl=1, sd=1)
    flat(cv, rect(cv, 3, 3, 28, 16), (6, 3, 10))
    for x in range(5, 28, 4):
        paint(cv, rect(cv, x, 3, x + 1, 16), IR, hl=0, sd=0, ol=False)
    flat(cv, rect(cv, 3, 8, 28, 9), IR[1])
    flat(cv, rect(cv, 3, 8, 28, 8), IR[3])
    for (x, y) in ((1, 1), (30, 1), (1, 18), (30, 18)):
        cv.px(x, y, IR[4])
    # faint green glow leaking from behind
    for x in (9, 10, 21):
        cv.px(x, 13, LI[1])
        cv.px(x, 14, LI[0])
    return cv


def sign_hazard():
    """Hand-painted warning board on two posts: bone skull on brick red. 26x34, origin bottom-centre."""
    cv = Cv(26, 34)
    paint(cv, rect(cv, 3, 18, 5, 33), PL)
    paint(cv, rect(cv, 20, 18, 22, 33), PL)
    paint(cv, rect(cv, 1, 1, 24, 22), PL)
    flat(cv, rect(cv, 3, 3, 22, 20), BR[2])
    flat(cv, rect(cv, 3, 3, 22, 4), BR[3])
    # skull
    flat(cv, ell(cv, 8, 6, 17, 14), BO[3])
    flat(cv, rect(cv, 10, 13, 15, 17), BO[3])
    flat(cv, rect(cv, 9, 9, 11, 11), (12, 5, 8))
    flat(cv, rect(cv, 14, 9, 16, 11), (12, 5, 8))
    flat(cv, rect(cv, 12, 12, 13, 13), (12, 5, 8))
    for x in (11, 13, 15):
        cv.px(x, 16, (12, 5, 8))
    flat(cv, rect(cv, 6, 18, 19, 18), BO[3])
    for (x, y) in ((2, 2), (23, 2), (2, 21), (23, 21)):
        cv.px(x, y, IR[4])
    speckle(cv, cv.opaque(), PL[0], 0.07, 12)
    exterior_outline(cv)
    return cv


def sign_arrow_brick():
    """Plank direction sign (points left, the way the level runs), 34x22, origin bottom-centre."""
    cv = Cv(34, 26)
    paint(cv, rect(cv, 15, 14, 18, 25), PL)
    paint(cv, poly(cv, [(32, 2), (10, 2), (2, 8), (10, 14), (32, 14)]), PL)
    flat(cv, poly(cv, [(28, 6), (14, 6), (14, 4), (7, 8), (14, 12), (14, 10), (28, 10)]), TO[2])
    flat(cv, poly(cv, [(27, 7), (13, 7), (9, 8), (13, 9), (27, 9)]), TO[3])
    cv.px(30, 4, IR[4])
    cv.px(30, 12, IR[4])
    speckle(cv, cv.opaque(), PL[0], 0.08, 4)
    exterior_outline(cv)
    return cv


# ------------------------------------------------------------------ neon guild sign
GLYPHS = {
    "A": [".XX.", "X..X", "XXXX", "X..X", "X..X"],
    "D": ["XXX.", "X..X", "X..X", "X..X", "XXX."],
    "G": [".XXX", "X...", "X.XX", "X..X", ".XXX"],
    "I": ["XXXX", ".XX.", ".XX.", ".XX.", "XXXX"],
    "L": ["X...", "X...", "X...", "X...", "XXXX"],
    "O": [".XX.", "X..X", "X..X", "X..X", ".XX."],
    "R": ["XXX.", "X..X", "XXX.", "X.X.", "X..X"],
    "T": ["XXXX", ".XX.", ".XX.", ".XX.", ".XX."],
    "U": ["X..X", "X..X", "X..X", "X..X", ".XX."],
}


def text_width(s):
    return sum(4 if ch != " " else 3 for ch in s) + (len(s) - 1)


def draw_text(cv, x, y, s, col, thick=False):
    for ch in s:
        if ch == " ":
            x += 4
            continue
        for gy, row in enumerate(GLYPHS[ch]):
            for gx, c in enumerate(row):
                if c == "X":
                    cv.px(x + gx, y + gy, col)
        x += 5
    return x


def neon_frame(k):
    """'DA TUTORIAL GUILD' neon on a dark iron board. 3 frames: on, flicker, dim. 74x34, origin centre."""
    cv = Cv(74, 34)
    paint(cv, rect(cv, 0, 0, 73, 33), [P.hx(P.BRICK[0]), IR[0], IR[0], IR[1], IR[2]], hl=1, sd=1)
    for (x, y) in ((2, 2), (71, 2), (2, 31), (71, 31)):
        cv.px(x, y, IR[3])
    on = [True, False, True][k]
    dim = k == 1
    glow = TO[3] if not dim else TO[1]
    core = TO[4] if not dim else TO[2]
    tube = TO[2] if not dim else TO[0]
    lines = [("DA TUTORIAL", 6), ("GUILD", 16)]
    # glow pass (1px bleed), then tube, then core
    for text, y in lines:
        x0 = (74 - text_width(text)) // 2
        tmp = Cv(74, 34)
        draw_text(tmp, x0, y, text, (1, 1, 1))
        m = tmp.opaque()
        from pxlib import dil
        bleed = dil(m) & ~m
        ys, xs = np.nonzero(bleed)
        for yy, xx in zip(ys, xs):
            if cv.a[yy, xx, 3] and (xx + yy) % 2 == 0 and on:
                cv.px(xx, yy, TO[0])
        draw_text(cv, x0, y, text, tube)
        # core: top row of each glyph lit brighter
        draw_text(cv, x0, y, text, tube)
        for yy, xx in zip(*np.nonzero(m)):
            if yy == y + 2:
                cv.px(xx, yy, core)
    if k == 1:
        # one letter dead during the flicker: blank the 'D' in GUILD
        x0 = (74 - text_width("GUILD")) // 2 + 5 * 4
        for gy in range(5):
            for gx in range(4):
                cv.px(x0 + gx, 16 + gy, IR[1])
    # underline arrow in lichen green
    flat(cv, rect(cv, 14, 25, 58, 25), LI[2] if on else LI[1])
    flat(cv, poly(cv, [(14, 25), (19, 22), (19, 28)]), LI[3] if on else LI[1])
    flat(cv, rect(cv, 20, 26, 58, 26), LI[0])
    return cv


# ------------------------------------------------------------------ spray paint arrow
def spray_arrow():
    """Spray-paint arrow, points left (flip with scale.x). 34x18, origin centre."""
    cv = Cv(34, 18)
    rs = np.random.RandomState(7)
    body = poly(cv, [(32, 6), (16, 6), (16, 2), (3, 9), (16, 16), (16, 12), (32, 12)])
    from pxlib import dil
    # fuzzy overspray first
    fz = dil(body) & ~body
    ys, xs = np.nonzero(fz)
    for y, x in zip(ys, xs):
        if rs.rand() < 0.5:
            cv.px(x, y, TO[0])
    flat(cv, body, TO[2])
    top = body.copy()
    top[8:] = False
    flat(cv, top, TO[3])
    # paint drips
    for x, ln in ((10, 5), (21, 3), (28, 4)):
        y0 = 12 if x > 16 else 13
        for y in range(y0, min(17, y0 + ln)):
            cv.px(x, y, TO[1] if y > y0 else TO[2])
    return cv


def spray_x():
    """Spray-paint cross-and-skull 'do not go' mark in bone white, 20x20, origin centre."""
    cv = Cv(20, 20)
    flat(cv, line(cv, [(3, 3), (16, 16)], 2), BO[3])
    flat(cv, line(cv, [(16, 3), (3, 16)], 2), BO[3])
    for (x, y) in ((4, 17), (4, 18), (15, 17), (16, 18), (9, 10)):
        cv.px(x, y, BO[2])
    return cv


ANIMATED = {
    "lichen_floor": ([lichen_floor_frame(k) for k in range(4)]),
    "lichen_wall": ([lichen_wall_frame(k) for k in range(4)]),
    "torch_bracket": ([torch_bracket_frame(k) for k in range(4)]),
    "skull_sconce": ([skull_sconce_frame(k) for k in range(4)]),
    "neon_guild_sign": ([neon_frame(k) for k in range(3)]),
}
STATIC = {
    "pipe_h": pipe_h, "pipe_v": pipe_v, "grate": grate, "sign_hazard": sign_hazard,
    "sign_arrow_brick": sign_arrow_brick, "spray_arrow": spray_arrow, "spray_x": spray_x,
}

if __name__ == "__main__":
    for n, frames in ANIMATED.items():
        arr = sheet([frames])
        save(arr, "props/%s.png" % n)
        print(n, arr.shape[1], arr.shape[0], len(frames))
    for n, fn in STATIC.items():
        cv = fn()
        save(cv.a, "props/%s.png" % n)
        print(n, cv.w, cv.h)
