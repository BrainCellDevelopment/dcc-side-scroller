import math
from pxl import Canvas, ik, put, tf, sheet, OUT
import donut

SKIN = ("#ffd9a8", "#f8b873", "#e0904f", "#9a5448")
HAIR = ("#f0a060", "#d07840", "#a04e2c", "#4a2a26")
TANK = ("#8a8494", "#6a6474", "#4a4654", "#34303e")
JACK = ("#c4a0d4", "#94689e", "#623e6c", "#38203e")
SHORT = ("#ffffff", "#f6f0f8", "#e2d8ea", "#b8a8c8")
RED = ("#ff9a74", "#f0584a", "#e03c48", "#a52a42")
SOLE = "#f4eefa"
EYE = "#2a1630"
WHITE = "#ffffff"
MOUTH = "#7a2a3c"
GROUND = 37.1

def leg_target(spec):
    if len(spec) == 3 and spec[2] == "abs":
        return spec[0], spec[1], 1.05, 0.0
    fx, lift = spec[0], spec[1]
    slack = spec[2] if len(spec) > 2 else 1.06
    toe = spec[3] if len(spec) > 3 else (0.4 if lift > 2 else 0.0)
    return 24 + fx, GROUND - lift, slack, toe


def draw_leg(c, hip_j, spec):
    fx, fy, slack, toe = leg_target(spec)
    ankle = (fx, fy - 0.6)
    d = math.hypot(ankle[0] - hip_j[0], ankle[1] - hip_j[1])
    seg = max(d / 2 * slack, 1.2)
    knee, ankle = ik(hip_j, ankle, seg, seg, -1)
    m = c.capsule(hip_j, knee, 2.2, 2.0) | c.capsule(knee, ankle, 2.0, 1.7)
    c.stamp(m, SKIN)
    shoe = c.ell(fx + 1.3, fy + 0.2, 3.7, 2.1, toe)
    c.stamp(shoe, RED)
    sole = c.ell(fx + 1.3, fy + 0.2, 3.7, 2.1, toe) & ~c.ell(fx + 1.3, fy - 0.9, 3.7, 2.1, toe)
    c.fill(sole & shoe, SOLE)
    return m


def draw_arm(c, sh, hand, fist_r, slack=1.12):
    d = math.hypot(hand[0] - sh[0], hand[1] - sh[1])
    seg = max(d / 2 * slack, 1.2)
    elbow, hand = ik(sh, hand, seg, seg, 1)
    fm = c.capsule(elbow, hand, 2.2, 1.9)
    c.stamp(fm, SKIN)
    um = c.capsule(sh, elbow, 3.0, 2.7)
    c.stamp(um, JACK)
    m = um | fm
    f = c.disc(hand[0], hand[1], fist_r * 1.15)
    c.stamp(f, SKIN)
    return hand


def rect(c, H, ang, x0, y0, x1, y1):
    lx, ly = c.local(H[0], H[1], ang)
    return (lx >= x0) & (lx < x1) & (ly >= y0) & (ly < y1)


def face(c, H, ang, p):
    kind = p.get("eyes", "open")
    ex = p.get("eye_dx", 0.0)
    R = lambda *a: rect(c, H, ang, *a)
    for x0, far in ((2.0 + ex, False), (-4.4 + ex, True)):
        if kind in ("open", "wide", "squint"):
            top = -1.0 if kind == "wide" else -0.4
            bot = 2.0 if kind != "squint" else 0.8
            if kind == "squint":
                top = 0.0
            c.fill(R(x0, top, x0 + 4.0, bot), WHITE)
            px0 = x0 + 2.0 if not far else x0 + 1.6
            c.fill(R(px0, top, px0 + 2.0, min(bot, top + 2.4)), EYE)
        elif kind == "blink":
            c.fill(R(x0, 1.0, x0 + 4.0, 2.0), EYE)
        elif kind == "x":
            for dx, dy in ((0, 0), (2, 0), (1, 1), (0, 2), (2, 2)):
                gx, gy = tf(H[0], H[1], ang, x0 + 0.5 + dx, -0.4 + dy)
                c.dot(gx, gy, EYE)
    brow = p.get("brow", "angry")
    bc = EYE
    if brow == "angry":
        c.fill(R(1.2 + ex, -2.2, 3.6 + ex, -0.6), bc)
        c.fill(R(3.6 + ex, -3.4, 6.6 + ex, -1.8), bc)
        c.fill(R(-5.0 + ex, -3.4, -2.0 + ex, -1.8), bc)
        c.fill(R(-2.0 + ex, -2.2, 0.4 + ex, -0.6), bc)
    elif brow == "up":
        c.fill(R(2.0 + ex, -2.6, 6.0 + ex, -1.6), bc)
        c.fill(R(-4.4 + ex, -2.6, -0.4 + ex, -1.6), bc)
    elif brow == "hurt":
        c.fill(R(1.4 + ex, -2.0, 3.6 + ex, -1.0), bc)
        c.fill(R(3.6 + ex, -3.0, 6.0 + ex, -2.0), bc)
        c.fill(R(-4.4 + ex, -3.0, -2.0 + ex, -2.0), bc)
        c.fill(R(-2.0 + ex, -2.0, 0.2 + ex, -1.0), bc)
    mouth = p.get("mouth", "line")
    MD = "#3a1222"
    if mouth in ("line", "flat"):
        c.fill(R(-1.0 + ex, 3.8, 4.0 + ex, 4.8), MOUTH)
    elif mouth == "grit":
        c.fill(R(-1.4 + ex, 2.8, 4.6 + ex, 6.0), MD)
        c.fill(R(-1.0 + ex, 2.8, 4.2 + ex, 4.0), WHITE)
        c.fill(R(-1.0 + ex, 4.8, 4.2 + ex, 5.8), WHITE)
    elif mouth == "shout":
        c.fill(R(-1.4 + ex, 2.6, 4.6 + ex, 6.6), MD)
        c.fill(R(-1.0 + ex, 2.6, 4.2 + ex, 3.8), WHITE)
        c.fill(R(-0.2 + ex, 5.2, 3.4 + ex, 6.4), RED[1])
    elif mouth in ("open", "o"):
        c.fill(R(-0.6 + ex, 3.0, 3.4 + ex, 6.2), MD)
        c.fill(R(-0.2 + ex, 5.0, 3.0 + ex, 6.0), RED[1])
    stub = {"s": HAIR[2]}
    put(c, H[0], H[1], ang, -5.0, 3.6, ["s.s.", ".s.s"], stub)


def hair(c, H, ang, head, p):
    lx, ly = c.local(H[0], H[1], ang)
    sw = p.get("sway", 0.0) * 0.4
    cap = head & ((ly < -4.8) | ((lx < -5.0) & (ly < 1.8)))
    m = cap
    m |= c.tri(H[0], H[1], ang, (-7.4, -1.6), (-4.4, -5.4), (-10.0 - sw, -5.6))
    m |= c.tri(H[0], H[1], ang, (-6.4, -4.4), (-2.4, -6.0), (-6.6 - sw, -9.6))
    m |= c.tri(H[0], H[1], ang, (-3.0, -5.6), (1.6, -5.8), (-2.0 - sw * 0.5, -10.0))
    m |= c.tri(H[0], H[1], ang, (1.0, -5.8), (5.0, -5.2), (3.6 + sw * 0.5, -10.0))
    m |= c.tri(H[0], H[1], ang, (4.2, -5.0), (7.8, -2.6), (10.4 + sw * 0.5, -7.4))
    c.stamp(m, HAIR)
    return m


def build_carl(p, cat=None):
    c = Canvas(64, 56, 8, 16)
    ang = p.get("lean", 0.05)
    hip = p.get("hip", (24.0, 31.2))
    if not any(len(v) == 3 and v[2] == "abs" for v in p["legs"].values()):
        hip = (hip[0], hip[1] - 4.2)
    u = (math.sin(ang), -math.cos(ang))
    rt = (math.cos(ang), math.sin(ang))
    tl = 6.4 + p.get("breath", 0.0) * 0.5
    S = (hip[0] + u[0] * tl, hip[1] + u[1] * tl)
    hang = ang + p.get("head_rot", 0.0)
    hf, hu = p.get("head_off", (1.2, 0.0))
    hu_ = 7.6 + hu
    H = (S[0] + u[0] * hu_ + rt[0] * hf, S[1] + u[1] * hu_ + rt[1] * hf)

    hj_b = (hip[0] - rt[0] * 2.4, hip[1] + 1.8)
    hj_a = (hip[0] + rt[0] * 2.6, hip[1] + 1.8)
    sh_b = (S[0] - rt[0] * 4.8, S[1] - rt[1] * 4.8 + 1.4)
    sh_a = (S[0] + rt[0] * 4.4, S[1] + rt[1] * 4.4 + 1.4)

    arms = p["arms"]
    fr = p.get("fist", (2.5, 2.4))
    draw_leg(c, hj_b, p["legs"]["b"])
    hb = draw_arm(c, sh_b, (sh_b[0] + arms["b"][0], sh_b[1] + arms["b"][1]), fr[1])
    draw_leg(c, hj_a, p["legs"]["a"])

    def B(lx, ly, o=hip):
        return tf(o[0], o[1], ang, lx, ly)

    neck = c.capsule(S, (S[0] + u[0] * 3.0, S[1] + u[1] * 3.0), 3.0)
    c.stamp(neck, SKIN)
    torso = c.poly([B(-3.6, 0.8), B(3.6, 0.8), B(6.2, -tl + 1.4), B(4.2, -tl - 0.2), B(-4.2, -tl - 0.2), B(-6.2, -tl + 1.4)])
    torso |= c.disc(*B(-4.8, -tl + 1.4), 2.4) | c.disc(*B(4.8, -tl + 1.4), 2.4)
    c.stamp(torso, JACK)
    shirt = c.poly([B(-2.8, 0.8), B(2.8, 0.8), B(3.0, -tl + 0.6), B(-3.0, -tl + 0.6)]) & torso
    c.stamp(shirt, TANK, outline=False)
    vs = c.tri(S[0], S[1], ang, (-1.8, -1.6), (1.8, -1.6), (0.0, 2.0)) & shirt
    c.fill(vs, SKIN[1])

    bang = ang if abs(ang) > 0.7 else ang * 0.7
    shorts = c.poly([B(-5.0, -1.6), B(5.0, -1.6), B(6.4, 4.0), B(-6.4, 4.0)])
    shorts |= c.disc(*B(5.4, 3.2), 1.0) | c.disc(*B(-5.4, 3.2), 1.0)
    if abs(ang) > 1.2:
        shorts = c.ell(hip[0], hip[1] + 0.8, 3.8, 6.0, bang)
    c.stamp(shorts, SHORT)
    HRT = ["R.R", "RRR", ".R."]
    for hxo, hyo in ((-4.0, 0.8), (0.0, 1.0), (4.0, 0.8)):
        hx, hy = tf(hip[0], hip[1] + 1.8, bang, hxo, hyo)
        c.pattern(int(math.floor(hx)) - 1, int(math.floor(hy)) - 1, HRT, {"R": RED[1]})
    if abs(ang) < 1.2:
        for sg in (-1, 1):
            for k in range(7):
                t = k / 6.0
                fx, fy = B(sg * (4.4 - t * 0.5), -tl + 1.2 + t * (tl - 0.8))
                if torso[int(fy) + c.oy if False else min(max(int(math.floor(fy)) + c.oy, 0), c.h - 1), min(max(int(math.floor(fx)) + c.ox, 0), c.w - 1)]:
                    c.dot(fx, fy, JACK[3])
                    c.dot(fx + sg * 1.0, fy, JACK[0])
                gx, gy = B(sg * (5.8 - t * 0.4), -tl + 2.2 + t * (tl - 3.0))
                c.dot(gx, gy, JACK[2])
    flaps = c.poly([B(-6.4, -tl + 1.4), B(-2.9, -tl + 0.6), B(-2.9, 0.4), B(-5.6, 1.0)]) | c.poly([B(6.4, -tl + 1.4), B(2.9, -tl + 0.6), B(2.9, 0.4), B(5.6, 1.0)])
    if abs(ang) < 1.2:
        c.stamp(flaps & ~c.poly([B(-2.8, 3), B(2.8, 3), B(2.8, -tl), B(-2.8, -tl)]), JACK, outline=False)

    lx, ly = c.local(H[0], H[1], hang)
    head = (((lx / 7.0) ** 2 + (ly / 6.5) ** 2) <= 1.0) | ((abs(lx - 0.4) <= 6.3) & (ly >= 0.0) & (ly <= 6.4)) | (((lx - 6.8) / 1.3) ** 2 + ((ly - 1.0) / 1.3) ** 2 <= 1.0)
    head &= ~((lx > 5.4) & (ly > 4.2))
    c.under(torso, head, 0, 2, TANK[3])
    c.stamp(head, SKIN, lt=1, st=1)
    lx2, ly2 = lx, ly
    em = ((lx2 + 7.0) / 1.2) ** 2 + ((ly2 - 1.0) / 2.0) ** 2 <= 1.0
    c.fill(em & head, SKIN[2])
    hm = hair(c, H, hang, head, p)
    face(c, H, hang, p)

    if cat is not None:
        if "cat_abs" in p:
            donut.draw_cat(c, p["cat_abs"], 0.0, cat)
        else:
            P = tf(H[0], H[1], hang, 0.4, -10.6 + p.get("cat_dy", 0.0))
            donut.draw_cat(c, P, hang * 0.85, cat)

    ha = draw_arm(c, sh_a, (sh_a[0] + arms["a"][0], sh_a[1] + arms["a"][1]), fr[0])
    if p.get("knuckles"):
        for k in range(3):
            c.dot(ha[0] + 1.0, ha[1] - 1.0 + k * 1.2, SKIN[3])
    for s in p.get("streaks", []):
        for i in range(s[2]):
            c.dot(s[0] - i, s[1], WHITE)
    for s in p.get("sweat", []):
        c.dot(s[0], s[1], "#9fd8ff")
        c.dot(s[0], s[1] + 1, "#9fd8ff")
    for s in p.get("stars", []):
        for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            c.dot(s[0] + dx, s[1] + dy, "#ffe45e")
    import numpy as np
    for _ in range(6):
        if c.a[:, 0, 3].any() or c.a[:, 1, 3].any():
            c.a = np.roll(c.a, 1, axis=1)
            c.a[:, 0] = 0
    anchor = {"S": S, "rt": rt, "u": u, "ang": ang, "H": H, "hip": hip, "sh_b": sh_b}
    return c, anchor


def shift_mask(c, m):
    from pxl import shift
    return shift(m, 0, 1)


def lst(**kw):
    return kw


IDLE_ARMS = {"a": (5.2, 5.0), "b": (-3.0, 6.4)}


def idle_frames():
    out = []
    for i, (br, eyes) in enumerate([(0.0, "open"), (1.0, "open"), (1.0, "blink"), (0.0, "open")]):
        out.append(lst(lean=0.06, breath=br, eyes=eyes, brow="angry", mouth="shout", sway=[0, 0.6, 1.2, 0.6][i],
                       arms={"a": (5.2, 5.0 - br * 0.0), "b": (-3.0, 6.4)},
                       legs={"a": (4.2, 0), "b": (-3.6, 0)}, fist=(2.5, 2.4)))
    return out


def run_frames():
    L = 0.2
    fr = [
        lst(lean=L, hip=(24, 31.4), legs={"a": (6.5, 0, 1.0), "b": (-6, 1.6, 1.0)},
            arms={"a": (-4.5, 3.5), "b": (6.0, -0.5)}),
        lst(lean=L + 0.04, hip=(24, 32.4), legs={"a": (2.5, 0, 1.3), "b": (-6, 4.5, 1.25)},
            arms={"a": (-4.0, 4.6), "b": (4.5, 2.0)}),
        lst(lean=L, hip=(24, 30.4), legs={"a": (-1.5, 0, 1.03), "b": (2.5, 4.5, 1.5)},
            arms={"a": (-2.0, 6.0), "b": (1.5, 5.5)}),
        lst(lean=L, hip=(24, 31.4), legs={"b": (6.5, 0, 1.0), "a": (-6, 1.6, 1.0)},
            arms={"b": (-4.5, 3.5), "a": (6.0, -0.5)}),
        lst(lean=L + 0.04, hip=(24, 32.4), legs={"b": (2.5, 0, 1.3), "a": (-6, 4.5, 1.25)},
            arms={"b": (-4.0, 4.6), "a": (4.5, 2.0)}),
        lst(lean=L, hip=(24, 30.4), legs={"b": (-1.5, 0, 1.03), "a": (2.5, 4.5, 1.5)},
            arms={"b": (-2.0, 6.0), "a": (1.5, 5.5)}),
    ]
    for f in fr:
        f.update(eyes="open", brow="angry", mouth="grit", fist=(2.5, 2.4), head_off=(2.4, 0.0), sway=1.4)
    return fr


JUMP = lst(lean=0.12, hip=(24, 30.2), legs={"a": (3.5, 5.0, 1.7, 0.5), "b": (-3.0, 3.0, 1.5, 0.4)},
           arms={"a": (4.0, -6.0), "b": (-5.0, -3.0)}, eyes="open", brow="up", mouth="open",
           fist=(2.6, 2.4), sway=2.0, head_off=(2.0, 0.0))
FALL = lst(lean=-0.04, hip=(24, 30.2), legs={"a": (5.0, 1.8, 1.1, -0.2), "b": (-4.5, 3.0, 1.15, 0.3)},
           arms={"a": (6.0, -3.5), "b": (-6.0, -3.2)}, eyes="wide", brow="up", mouth="o",
           fist=(2.6, 2.4), sway=-1.5, head_off=(1.4, 0.0), cat_dy=1.0)

PUNCH = [
    lst(lean=-0.16, hip=(22.6, 31.8), legs={"a": (6.0, 0, 1.0), "b": (-6.0, 0, 1.35)},
        arms={"a": (-5.6, 1.6), "b": (5.0, -1.0)}, eyes="open", brow="angry", mouth="grit",
        fist=(3.0, 2.4), head_off=(1.4, 0.0), sway=-1.0),
    lst(lean=0.26, hip=(25.0, 31.6), legs={"a": (8.5, 0, 1.0), "b": (-6.5, 0, 1.05)},
        arms={"a": (10.5, 2.0), "b": (-4.0, 3.5)}, eyes="open", brow="angry", mouth="grit",
        fist=(3.4, 2.4), head_off=(2.2, 0.0), sway=1.8, streaks=[(34, 24, 3), (33, 27, 4)], knuckles=False),
    lst(lean=0.32, hip=(25.2, 31.8), legs={"a": (9.5, 0, 1.15), "b": (-5.0, 0.4, 1.0)},
        arms={"a": (10.2, 1.2), "b": (-4.5, 3.0)}, eyes="open", brow="angry", mouth="grit",
        fist=(3.9, 2.4), head_off=(2.4, 0.0), sway=2.2, knuckles=True),
    lst(lean=0.12, hip=(24.6, 31.4), legs={"a": (6.0, 0, 1.0), "b": (-5.0, 0, 1.1)},
        arms={"a": (7.0, 1.5), "b": (-3.0, 5.0)}, eyes="open", brow="angry", mouth="line",
        fist=(3.0, 2.4), head_off=(1.8, 0.0), sway=1.0),
]

HURT = lst(lean=-0.3, hip=(22.2, 30.6), legs={"a": (3.0, 2.5, 1.35, 0.3), "b": (-6.5, 0, 1.0)},
           arms={"a": (7.0, 2.5), "b": (-7.0, 1.0)}, eyes="squint", brow="hurt", mouth="open",
           fist=(2.6, 2.4), head_rot=-0.2, head_off=(1.0, 0.0), sway=-2.0, sweat=[(40, 9), (38, 12)])

DIE = [
    lst(lean=-0.5, hip=(22.4, 29.6), legs={"a": (3.0, 3.5, 1.3, 0.4), "b": (-5.0, 0.0, 1.1)},
        arms={"a": (6.0, 4.0), "b": (-6.5, 2.5)}, eyes="squint", brow="hurt", mouth="open",
        fist=(2.6, 2.4), head_rot=-0.25, head_off=(1.0, 0.0), sway=-2.5),
    lst(lean=-1.0, hip=(26.0, 29.0), legs={"a": (31.0, 26.0, "abs"), "b": (28.0, 31.0, "abs")},
        arms={"a": (-4.0, -6.0), "b": (-6.0, 3.0)}, eyes="x", brow="hurt", mouth="open",
        fist=(2.6, 2.4), head_rot=0.5, head_off=(1.0, 0.0), sway=-2.5),
    lst(lean=-1.45, hip=(27.0, 29.0), legs={"a": (38.0, 28.0, "abs"), "b": (37.0, 32.5, "abs")},
        arms={"a": (-2.0, -5.0), "b": (5.0, 4.0)}, eyes="x", brow="hurt", mouth="o",
        fist=(2.6, 2.4), head_rot=1.0, head_off=(1.2, 0.0), sway=-1.0, cat_abs=(28, 22.5)),
    lst(lean=-1.55, hip=(27.5, 29.8), legs={"a": (38.5, 29.5, "abs"), "b": (38.0, 33.5, "abs")},
        arms={"a": (-4.0, 3.5), "b": (5.0, 4.5)}, eyes="x", brow="hurt", mouth="line",
        fist=(2.6, 2.4), head_rot=1.1, head_off=(1.2, 0.0), sway=-0.5, stars=[(8, 14), (13, 11)], cat_abs=(24, 23.5)),
]

CARL_ROWS = [idle_frames(), run_frames(), [JUMP], [FALL], PUNCH, [HURT], DIE]
