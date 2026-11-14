import math
import os
import numpy as np
from PIL import Image
from pxl import Canvas, tf, shift, preview, count_colors, rgb, OUT as OUTLINE

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "cutscene")
PV = os.path.join(HERE, "_preview")
DARK = ("#7a5236", "#4e3022", "#2c1a14", "#170d0c")
ORNG = ("#f0b866", "#d08a3a", "#9a5a24", "#5e3418")
TAN = ("#f4d49a", "#dcae6a", "#b07a40", "#7a4c28")
EYE = "#ffb81c"
EYE_HI = "#fff2a0"
PUP = "#120a14"
PURP = ("#e6c4ff", "#a468e8", "#6a3cb8", "#3a2070")
NOSE = "#c26a7a"
BTF = "#9fd4ff"


def shade_patch(c, region, patches, ramp):
    m = region & patches
    c.fill(m, ramp[1])
    edge_hi = m & ~shift(m, 1, 1)
    edge_lo = m & ~shift(m, -1, -1)
    c.fill(edge_hi & (region), ramp[0])
    c.fill(edge_lo & region, ramp[2])


def blobs(c, spec, s, ox, oy):
    m = np.zeros((c.h, c.w), bool)
    for x, y, rx, ry in spec:
        m |= c.ell(ox + x * s, oy + y * s, rx * s, ry * s)
    return m


def cat(p):
    c = Canvas(32, 32)
    s = p.get("s", 1.0)
    ox, oy = p.get("ox", 16.0), p.get("oy", 32.0)
    W = lambda x, y: (ox + x * s, oy + y * s)
    R = lambda v: v * s
    body_c = p.get("body", (-1, -8))
    br = p.get("brx", 7.5), p.get("bry", 8.0)
    bang = p.get("bang", 0.0)
    hc = p.get("head", (3, -19.5))
    hang = p.get("hang", 0.0)
    tail = p.get("tail", [(-6, -3), (-11, -4), (-13, -9), (-11, -14)])
    trad = p.get("trad", (2.6, 3.2, 3.4, 2.8))

    pts = [W(*q) for q in tail]
    tm = c.capsule(pts[0], pts[1], R(trad[0]), R(trad[1])) | c.capsule(pts[1], pts[2], R(trad[1]), R(trad[2])) | c.capsule(pts[2], pts[3], R(trad[2]), R(trad[3]))
    tuft = (tm | shift(tm, 1, 0) | shift(tm, -1, 0)) & ~tm & (((c.xx * 7 + c.yy * 13) % 3) == 0)
    tm = tm | tuft
    c.stamp(tm, DARK)
    c.fill(c.capsule(pts[1], pts[2], R(1.3), R(1.5)) & tm, ORNG[1])
    c.fill(c.disc(*pts[3], R(trad[3] * 0.8)) & tm, DARK[3])

    legs = p.get("legs", "sit")
    if legs == "sit":
        hind = c.ell(*W(-5, -3.2), R(5.2), R(3.4)) 
        c.stamp(hind, DARK)
    elif legs == "stretch":
        for (a, b) in p["limbs"]:
            c.stamp(c.capsule(W(*a), W(*b), R(2.0), R(1.7)), DARK)

    bx, by = W(*body_c)
    body = c.ell(bx, by, R(br[0]), R(br[1]), bang)
    c.stamp(body, DARK)
    chest = c.ell(*W(body_c[0] + 4.5, body_c[1] + 1.5), R(3.2), R(5.6), bang)
    c.fill(chest & body, TAN[1])
    c.fill(chest & body & ~shift(chest & body, 1, 1), TAN[0])
    pat = blobs(c, p.get("patches_b", [(-4, -10, 3.4, 4.4), (1, -4, 2.4, 2.4)]), s, ox, oy)
    shade_patch(c, body & ~chest, pat, ORNG)

    if legs == "sit":
        for fx in (4.5, 7.2):
            fl = c.capsule(W(fx - 0.5, -9), W(fx, -1.6), R(2.1), R(1.9))
            fl |= c.ell(*W(fx + 0.9, -1.2), R(2.6), R(1.4))
            c.stamp(fl, DARK)
            c.fill(fl & (c.py > oy - R(2.4)) & (c.px > ox + R(fx - 0.6)), TAN[1])
    elif legs == "stretch":
        for (a, b) in p["flimbs"]:
            c.stamp(c.capsule(W(*a), W(*b), R(2.0), R(1.7)) | c.disc(*W(*b), R(2.0)), DARK)

    nk = (hc[0] - 1, hc[1] + 5)
    collar = c.capsule(W(hc[0] - 4.5, hc[1] + 5.4), W(hc[0] + 4.0, hc[1] + 5.9), R(1.5)) & (c.ell(*W(*hc), R(11), R(11)))
    hx_, hy_ = W(*hc)
    hl = lambda lx, ly: tf(hx_, hy_, hang, lx * s, ly * s)
    head = c.ell(hx_, hy_, R(8.0), R(6.4), hang) | c.ell(*hl(1.5, 2.6), R(8.6), R(4.0), hang)
    ears = c.tri(hx_, hy_, hang, (R(-6.8), R(-2.0)), (R(-5.0), R(-9.0)), (R(-1.0), R(-5.0)))
    ears |= c.tri(hx_, hy_, hang, (R(0.5), R(-5.2)), (R(4.4), R(-9.2)), (R(6.4), R(-2.4)))
    if p.get("collar", True):
        c.stamp(collar, PURP)
        c.fill(collar & ~shift(collar, 1, 1), PURP[0])
    c.stamp(head | ears, DARK)
    ear_in = c.tri(hx_, hy_, hang, (R(-5.8), R(-2.8)), (R(-4.8), R(-7.0)), (R(-2.4), R(-4.6)))
    ear_in |= c.tri(hx_, hy_, hang, (R(1.6), R(-4.8)), (R(4.0), R(-7.2)), (R(5.4), R(-3.0)))
    c.fill(ear_in & (head | ears), "#d98aa0")
    hpat = blobs(c, [], s, ox, oy)
    hp = c.ell(*hl(-3.5, -3.5), R(3.6), R(3.2)) | c.ell(*hl(6.0, 2.5), R(2.6), R(2.4))
    shade_patch(c, (head | ears) & ~ear_in, hp, ORNG)
    muz = c.ell(*hl(5.6, 2.4), R(3.8), R(3.0), hang)
    c.fill(muz & head, TAN[1])
    c.fill(c.ell(*hl(1.0, -0.6), R(1.0), R(3.8), hang) & head & ~muz, TAN[1])

    mode = p.get("eyes", "open")
    for lx in (0.2, 6.2):
        ex, ey = hl(lx, -0.8)
        if mode == "blink":
            for k in range(-2, 3):
                gx, gy = hl(lx + k * 0.9, -0.2)
                c.dot(gx, gy, PUP)
        else:
            e = c.ell(ex, ey, R(2.5), R(2.6), hang)
            c.fill(e, EYE)
            c.fill(e & ~shift(e, 0, 1), "#e08a10")
            dx = 0.8 if mode != "down" else 0.5
            dy = 0.0 if mode != "down" else 1.0
            c.fill(c.ell(*hl(lx + dx, -0.6 + dy), R(1.0), R(1.9), hang), PUP)
            c.dot(*hl(lx - 0.4, -2.2), EYE_HI)
    c.dot(*hl(8.4, 2.4), NOSE)
    c.dot(*hl(8.4, 3.4), "#2a1418")
    c.dot(*hl(7.4, 3.8), "#2a1418")

    for i, (tx, ty, col) in enumerate(((-1.5, -6.6, PURP[0]), (0.6, -7.2, PURP[1]), (2.6, -6.6, PURP[0]))):
        gx, gy = hl(tx - 0.8, ty - 0.5)
        c.dot(gx, gy, PURP[0] if i != 1 else "#ff7ac0")
    for k in range(-3, 2):
        c.dot(*hl(k * 0.9 + 0.2, -5.6), PURP[1])
    if p.get("collar", True):
        cx, cy = W(hc[0] + 1.2, hc[1] + 7.2)
        c.dot(cx, cy, BTF); c.dot(cx - 1, cy, "#7c4cc4"); c.dot(cx + 1, cy, "#7c4cc4"); c.dot(cx, cy + 1, BTF)
    return c


SITS = [dict(s=0.92, ox=17.5), dict(s=0.92, ox=17.5, eyes="blink"), dict(s=0.92, ox=17.5, tail=[(-6, -3), (-11, -3), (-14, -5), (-15, -9)])]
LEAP_A = dict(legs="stretch", s=0.72, ox=14.5, oy=30, body=(0, -11), brx=10.5, bry=5.2, bang=-0.5, head=(10, -18), hang=-0.4,
              tail=[(-8, -8), (-13, -5), (-16, -2), (-18, 1)], collar=True,
              limbs=[((-5, -10), (-13, -7)), ((-3, -8), (-9, -3))],
              flimbs=[((6, -13), (13, -17)), ((4, -12), (12, -12))], patches_b=[(-4, -12, 3.4, 3), (3, -9, 2.4, 2.4)])
LEAP_B = dict(legs="stretch", s=0.72, ox=14.5, oy=30, body=(0, -9), brx=10.5, bry=5.0, bang=0.0, head=(11, -11), hang=0.15,
              tail=[(-9, -10), (-14, -8), (-17, -10), (-19, -14)],
              limbs=[((-6, -8), (-14, -5)), ((-4, -6), (-11, -1))],
              flimbs=[((6, -9), (14, -12)), ((5, -7), (13, -6))], patches_b=[(-4, -10, 3.4, 3), (3, -7, 2.4, 2.4)])
HEAD = dict(s=0.68, ox=17, oy=31.5, tail=[(-6, -3), (-11, -3), (-14, -6), (-14, -11)])
BRANCH = dict(ox=17, s=0.95, oy=31.5, eyes="down", hang=0.35, head=(5, -17.5), body=(-1, -8), tail=[(-6, -3), (-10, -1), (-12, 4), (-11, 9)], trad=(2.6, 3.0, 3.0, 2.4))


def build():
    rows = [SITS, [LEAP_A, LEAP_B], [HEAD], [BRANCH]]
    out = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    for r, row in enumerate(rows):
        for i, p in enumerate(row):
            out.paste(Image.fromarray(cat(p).a, "RGBA"), (i * 32, r * 32))
    return out


if __name__ == "__main__":
    img = build()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PV, exist_ok=True)
    img.save(os.path.join(OUT, "cutscene_donut.png"))
    preview(img, os.path.join(PV, "donut.png"), 10, fw=32, fh=32)
    print(img.size, count_colors(img))
