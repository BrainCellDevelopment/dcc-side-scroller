import math
import numpy as np
from pxl import Canvas, ik, put, tf, sheet, OUT

SKIN = ("#f4c898", "#dea070", "#b87850", "#7a4434")
HAIR = ("#9a6a44", "#6e4428", "#47281a", "#2a160e")
JACK = ("#8a5a3c", "#5e3a26", "#3c2418", "#20120e")
SHIRT = ("#463e44", "#2c262c", "#1a161c")
BOOT = ("#ffb0d0", "#f070a8", "#c04884", "#702850")
SHORT = ("#ffffff", "#f4f0f6", "#d8d0e2", "#a89cb8")
HEART = "#e23344"
EYE = "#24121c"
WHITE = "#ffffff"
MOUTH = "#6a2030"
MOUTH_DARK = "#3a1220"
TONGUE = "#e0564e"
CX = 24.0
GROUND = 54.4
HIP = (CX, 40.4)
TORSO = 8.0
BOOT_H = 2.8


def leg_target(spec):
    if len(spec) == 3 and spec[2] == "abs":
        return spec[0], spec[1], 1.04, None
    fx, lift = spec[0], spec[1]
    slack = spec[2] if len(spec) > 2 else 1.05
    toe = spec[3] if len(spec) > 3 else (0.45 if lift > 2 else 0.0)
    return CX + fx, GROUND - lift, slack, toe


def draw_leg(c, hip_j, spec):
    fx, fy, slack, toe = leg_target(spec)
    lying = toe is None
    ankle = (fx, fy) if lying else (fx - math.sin(toe) * 1.5, fy - BOOT_H)
    d = math.hypot(ankle[0] - hip_j[0], ankle[1] - hip_j[1])
    seg = max(d / 2 * slack, 1.5)
    knee, ankle = ik(hip_j, ankle, seg, seg, -1)
    c.stamp(c.capsule(hip_j, knee, 2.5, 2.2) | c.capsule(knee, ankle, 2.1, 1.9), SKIN)
    mid = (ankle[0] + (knee[0] - ankle[0]) * 0.12, ankle[1] + (knee[1] - ankle[1]) * 0.12)
    if lying:
        boot = c.capsule(mid, ankle, 2.5, 2.7) | c.ell(ankle[0] + 1.4, ankle[1] - 2.2, 2.4, 3.2)
        c.stamp(boot, BOOT)
    else:
        heel = (fx - 0.6, fy - 2.0)
        boot = c.capsule(mid, heel, 2.3, 2.4) | c.ell(fx + 1.4, fy - 2.0, 4.4, 2.3, toe * 0.6)
        boot &= c.py < fy + 0.2 + abs(toe) * 4.0
        c.stamp(boot, BOOT)
        c.fill(boot & (c.py > fy - 0.9), BOOT[3])
        for k in range(3):
            c.dot(fx + 1.2 + k * 1.6, fy - 2.6 + (k % 2) * 0.9, BOOT[3])
        c.fill(c.capsule((heel[0] - 1.2, heel[1] - 2.4), (mid[0] + 1.2, mid[1] - 0.2), 0.7) & boot, BOOT[0])
    cuff_end = (hip_j[0] + (knee[0] - hip_j[0]) * 0.5, hip_j[1] + (knee[1] - hip_j[1]) * 0.5)
    leg_short = c.capsule(hip_j, cuff_end, 2.9, 3.0)
    c.stamp(leg_short, SHORT)
    heart(c, hip_j[0] + (cuff_end[0] - hip_j[0]) * 0.75, hip_j[1] + (cuff_end[1] - hip_j[1]) * 0.75, leg_short)
    return leg_short


def heart(c, x, y, clip=None):
    x, y = int(math.floor(x)), int(math.floor(y))
    for dx, dy in ((-1, -1), (1, -1), (-1, 0), (0, 0), (1, 0), (0, 1)):
        X, Y = x + dx + c.ox, y + dy + c.oy
        if 0 <= X < c.w and 0 <= Y < c.h and (clip is None or clip[Y, X]):
            c.dot(x + dx, y + dy, HEART)


def draw_arm(c, sh, hand, fist_r, slack=1.1, bend=1, bare=False):
    d = math.hypot(hand[0] - sh[0], hand[1] - sh[1])
    seg = max(d / 2 * slack, 1.5)
    elbow, hand = ik(sh, hand, seg, seg, bend)
    if bare:
        c.stamp(c.capsule(elbow, hand, 2.2, 1.9), SKIN)
        c.stamp(c.capsule(sh, elbow, 2.6, 2.3), SKIN)
    else:
        c.stamp(c.capsule(elbow, hand, 2.7, 2.3), JACK)
        c.stamp(c.capsule(sh, elbow, 3.2, 2.8), JACK)
        wrist = (elbow[0] + (hand[0] - elbow[0]) * 0.8, elbow[1] + (hand[1] - elbow[1]) * 0.8)
        c.fill(c.capsule(wrist, hand, 2.3) & c.capsule(elbow, hand, 2.7, 2.3) & ~c.capsule(wrist, hand, 1.2), JACK[3])
    c.stamp(c.disc(hand[0], hand[1], fist_r), SKIN)
    return hand


def rect(c, H, ang, x0, y0, x1, y1):
    lx, ly = c.local(H[0], H[1], ang)
    return (lx >= x0) & (lx < x1) & (ly >= y0) & (ly < y1)


def face(c, H, ang, p):
    kind = p.get("eyes", "open")
    R = lambda *a: rect(c, H, ang, *a)
    for x0, w, pw in ((0.2, 3.2, 1.5), (4.5, 2.0, 1.1)):
        if kind in ("open", "wide", "squint"):
            top = -1.4 if kind == "wide" else (0.2 if kind == "squint" else -0.6)
            bot = 1.6 if kind != "squint" else 1.3
            c.fill(R(x0, top, x0 + w, bot), WHITE)
            c.fill(R(x0 + w - pw, top, x0 + w, bot), EYE)
        elif kind == "blink":
            c.fill(R(x0, 0.4, x0 + w, 1.4), EYE)
        elif kind == "x":
            for dx, dy in ((0, 0), (2, 0), (1, 1), (0, 2), (2, 2)):
                gx, gy = tf(H[0], H[1], ang, x0 + 0.5 + dx * w / 3.2, -0.8 + dy)
                c.dot(gx, gy, EYE)
    brow = p.get("brow", "angry")
    if brow == "tired":
        c.fill(R(-0.4, -2.2, 2.6, -1.2), HAIR[3])
        c.fill(R(4.0, -2.0, 6.4, -1.2), HAIR[3])
    if brow == "angry":
        c.fill(R(-1.2, -3.2, 1.4, -1.6), HAIR[3])
        c.fill(R(1.4, -2.4, 4.0, -0.6), HAIR[3])
        c.fill(R(4.0, -2.4, 5.2, -0.6), HAIR[3])
        c.fill(R(5.2, -3.0, 6.6, -1.6), HAIR[3])
    elif brow == "up":
        c.fill(R(0.0, -3.4, 3.4, -2.2), HAIR[3])
        c.fill(R(4.4, -3.4, 6.4, -2.2), HAIR[3])
    elif brow == "hurt":
        c.fill(R(-0.6, -2.2, 1.6, -1.0), HAIR[3])
        c.fill(R(1.6, -3.2, 3.6, -2.0), HAIR[3])
        c.fill(R(4.2, -3.2, 5.4, -2.0), HAIR[3])
        c.fill(R(5.4, -2.2, 6.6, -1.0), HAIR[3])
    c.fill(R(6.2, 1.6, 7.2, 2.6), SKIN[2])
    mouth = p.get("mouth", "grit")
    if mouth in ("line", "flat"):
        c.fill(R(2.0, 3.6, 6.0, 4.6), MOUTH)
    elif mouth == "grit":
        c.fill(R(1.4, 2.8, 6.4, 5.2), MOUTH_DARK)
        c.fill(R(2.0, 3.2, 6.0, 4.6), WHITE)
        c.fill(R(3.8, 3.2, 4.4, 4.6), SKIN[3])
    elif mouth == "shout":
        c.fill(R(1.6, 2.6, 6.4, 5.8), MOUTH_DARK)
        c.fill(R(2.2, 2.8, 6.0, 3.8), WHITE)
        c.fill(R(2.6, 4.6, 5.6, 5.6), TONGUE)
    elif mouth in ("open", "o"):
        c.fill(R(2.6, 2.8, 5.8, 5.6), MOUTH_DARK)
        c.fill(R(3.0, 4.4, 5.4, 5.4), TONGUE)
    put(c, H[0], H[1], ang, -2.2, 3.4, ["s.s", ".s."], {"s": SKIN[2]})


def hair(c, H, ang, head, p):
    lx, ly = c.local(H[0], H[1], ang)
    sw = p.get("sway", 0.0) * 0.5
    m = head & ((ly < -3.4) | ((lx < -3.2) & (ly < 0.6)) | ((lx < -4.6) & (ly < 2.6)))
    T = lambda a, b, t: c.tri(H[0], H[1], ang, a, b, t)
    m |= T((-6.2, 1.0), (-3.6, -3.0), (-10.4 - sw, -1.6))
    m |= T((-6.4, -1.6), (-3.0, -5.0), (-10.6 - sw, -6.4))
    m |= T((-5.4, -4.0), (-1.2, -5.6), (-7.4 - sw, -10.6))
    m |= T((-3.0, -5.0), (1.4, -5.6), (-2.4 - sw * 0.6, -11.6))
    m |= T((0.0, -5.4), (4.0, -4.8), (2.4, -11.2))
    m |= T((2.6, -5.0), (6.4, -2.6), (7.4 + sw * 0.4, -9.4))
    m |= T((4.6, -4.0), (6.6, -2.0), (9.6 + sw * 0.4, -5.4))
    c.stamp(m, HAIR)
    for a, b in (((-4.0, -4.0), (-7.4, -8.0)), ((-1.0, -5.0), (-2.2, -9.0)), ((2.4, -5.0), (2.6, -8.6)), ((-5.0, -1.0), (-8.0, -3.4))):
        for k in range(4):
            t = k / 3.0
            gx, gy = tf(H[0], H[1], ang, a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            X, Y = int(math.floor(gx)) + c.ox, int(math.floor(gy)) + c.oy
            if 0 <= X < c.w and 0 <= Y < c.h and m[Y, X]:
                c.dot(gx, gy, HAIR[0])
    return m


def build_carl(p):
    c = Canvas(64, 64, 8, 8)
    ang = p.get("lean", 0.06)
    hip = p.get("hip", HIP)
    lying = abs(ang) > 1.2
    u = (math.sin(ang), -math.cos(ang))
    rt = (math.cos(ang), math.sin(ang))
    tl = TORSO + p.get("breath", 0.0) * 0.6
    S = (hip[0] + u[0] * tl, hip[1] + u[1] * tl)
    hang = ang + p.get("head_rot", 0.0)
    hf, hu = p.get("head_off", (1.2, 0.0))
    hu_ = 6.6 + hu
    H = (S[0] + u[0] * hu_ + rt[0] * hf, S[1] + u[1] * hu_ + rt[1] * hf)

    hj_b = (hip[0] + rt[0] * 2.6 - u[0] * 1.2, hip[1] + rt[1] * 2.6 - u[1] * 1.2)
    hj_a = (hip[0] - rt[0] * 2.4 - u[0] * 1.2, hip[1] - rt[1] * 2.4 - u[1] * 1.2)
    sh_b = (S[0] + rt[0] * 3.6 - u[0] * 1.6, S[1] + rt[1] * 3.6 - u[1] * 1.6)
    sh_a = (S[0] - rt[0] * 3.2 - u[0] * 1.8, S[1] - rt[1] * 3.2 - u[1] * 1.8)

    arms = p["arms"]
    fr = p.get("fist", (2.6, 2.4))
    bends = p.get("bend", (1, 1))
    draw_arm(c, sh_b, (sh_b[0] + arms["b"][0], sh_b[1] + arms["b"][1]), fr[1], bend=bends[1], bare=True)
    draw_leg(c, hj_b, p["legs"]["b"])
    draw_leg(c, hj_a, p["legs"]["a"])

    def B(lx, ly):
        return tf(hip[0], hip[1], ang, lx, ly)

    pelvis = c.poly([B(-5.2, -2.2), B(5.4, -2.2), B(5.8, 2.6), B(0.6, 3.4), B(-5.6, 2.6)])
    c.stamp(pelvis, SHORT)
    c.fill(c.poly([B(-5.2, -2.2), B(5.4, -2.2), B(5.4, -1.4), B(-5.2, -1.4)]) & pelvis, SHORT[2])
    heart(c, *B(1.2, 1.2), pelvis)
    heart(c, *B(-3.4, 0.6), pelvis)
    heart(c, *B(5.0, 0.4), pelvis)

    neck = c.capsule(S, (S[0] + u[0] * 2.6 + rt[0], S[1] + u[1] * 2.6 + rt[1]), 2.6)
    c.stamp(neck, SKIN)
    torso = c.poly([B(-4.6, -1.4), B(4.8, -1.4), B(6.2, -tl + 1.8), B(4.4, -tl - 0.8), B(-4.6, -tl - 0.8), B(-6.4, -tl + 1.8)])
    torso |= c.disc(*B(-4.8, -tl + 1.4), 2.6) | c.disc(*B(4.6, -tl + 1.4), 2.6)
    hood = c.ell(*B(-3.4, -tl - 0.6), 3.4, 2.4, ang)
    c.stamp(torso | hood, JACK)
    shirt = c.poly([B(1.0, -1.4), B(4.4, -1.4), B(5.0, -tl + 1.4), B(3.6, -tl - 0.6), B(1.6, -tl - 0.6)]) & torso
    c.stamp(shirt, SKIN, outline=False, spec=False)
    c.fill(c.tri(S[0], S[1], ang, (0.6, -1.4), (4.0, -1.4), (2.6, 1.6)) & shirt, SKIN[2])
    c.fill(c.poly([B(2.2, -3.2), B(4.0, -3.2), B(3.6, -2.4), B(2.4, -2.4)]) & shirt, SKIN[3])
    c.fill(c.poly([B(0.2, -1.4), B(1.2, -1.4), B(1.8, -tl - 0.4), B(0.8, -tl - 0.4)]) & torso, JACK[0])
    c.fill(c.poly([B(-4.6, -2.6), B(1.0, -2.6), B(1.0, -1.4), B(-4.6, -1.4)]) & torso, JACK[3])

    lx, ly = c.local(H[0], H[1], hang)
    head = ((lx / 6.4) ** 2 + (ly / 6.0) ** 2) <= 1.0
    head |= (lx >= -5.0) & (lx <= 6.2) & (ly >= 0.0) & (ly <= 5.8)
    head |= ((lx - 6.6) / 1.2) ** 2 + ((ly - 1.8) / 1.2) ** 2 <= 1.0
    head &= ~((lx > 5.2) & (ly > 4.8)) & ~((lx < -3.8) & (ly > 4.6))
    c.under(torso, head, 0, 1, JACK[3])
    c.stamp(head, SKIN)
    c.fill(head & (ly > 4.6) & (lx < 4.0), SKIN[2])
    ear = ((lx + 3.6) / 1.4) ** 2 + ((ly - 1.2) / 2.0) ** 2 <= 1.0
    c.fill(ear & head, SKIN[2])
    c.fill(ear & head & (lx < -3.6), SKIN[3])
    hair(c, H, hang, head, p)
    face(c, H, hang, p)

    ha = draw_arm(c, sh_a, (sh_a[0] + arms["a"][0], sh_a[1] + arms["a"][1]), fr[0], bend=bends[0])
    if p.get("knuckles"):
        for k in range(3):
            c.dot(ha[0] + 1.6, ha[1] - 1.4 + k * 1.3, SKIN[3])
    for s in p.get("streaks", []):
        for i in range(s[2]):
            c.dot(s[0] - i, s[1], WHITE if i < s[2] - 2 else "#c8b8ff")
    for s in p.get("sweat", []):
        c.dot(s[0], s[1], "#9fd8ff")
        c.dot(s[0], s[1] + 1, "#9fd8ff")
    for s in p.get("stars", []):
        for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            c.dot(s[0] + dx, s[1] + dy, "#ffe45e")
    for _ in range(6):
        if c.a[:, 0, 3].any() or c.a[:, 1, 3].any():
            c.a = np.roll(c.a, 1, axis=1)
            c.a[:, 0] = 0
    anchor = {"S": S, "rt": rt, "u": u, "ang": ang, "H": H, "hip": hip, "sh_b": sh_b}
    anchor['ha'] = ha
    return c, anchor


