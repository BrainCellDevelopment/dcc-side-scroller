import math
from pxl import Canvas, put, tf
import hum

SKIN = ("#b8e878", "#7cc24a", "#4c9a3e", "#2a5a4a")
STEEL = ("#f0f2fa", "#b8bcd0", "#7c8098", "#4a4a6a")
BRASS = ("#ffe08a", "#e0a63a", "#a8682a")
LENS = ("#9af0f0", "#4cb8c8")
PANT = ("#a07a54", "#78542f", "#4a3030")
LEATH = PANT
EYEC = "#2a1630"
RED = "#ff4a3a"
WHITE = "#ffffff"

CFG = dict(cx=20, ground=37.3, hip=(20.0, 30.6), tl=7.2, hu=5.4, head=(8.2, 6.4), nose=(8.4, 2.4, 2.6, 2.4),
           head_off=(1.0, 0.0), sw=4.0, hw=2.8, leg_r=1.9, arm_r=1.7, foot=(3.4, 1.8), skin=SKIN, shoe=PANT)


def knife(c, hand, th, curve=0.5):
    pts = []
    x, y = hand
    a = th
    pts.append((x, y))
    for i in range(5):
        x += math.sin(a) * 2.4
        y += -math.cos(a) * 2.4
        a += curve * (0.25 if i > 0 else 0.0)
        pts.append((x, y))
    hilt = c.capsule((hand[0] - math.sin(th) * 1.6, hand[1] + math.cos(th) * 1.6), (pts[1][0], pts[1][1]), 1.3, 1.3)
    c.stamp(hilt, LEATH)
    blade = c.capsule(pts[1], pts[2], 1.4, 1.5) | c.capsule(pts[2], pts[3], 1.5, 1.4) | c.capsule(pts[3], pts[4], 1.4, 1.0) | c.capsule(pts[4], pts[5], 1.0, 0.5)
    c.stamp(blade, STEEL)
    guard = c.disc(pts[1][0], pts[1][1], 1.7)
    c.stamp(guard, BRASS, spec=False)
    return pts


def build(p):
    cfg = CFG
    c = Canvas(40, 40)
    k = hum.skeleton(cfg, p)
    arms = p["arms"]
    hum.draw_arm(c, cfg, k["sh_b"], (k["sh_b"][0] + arms["b"][0], k["sh_b"][1] + arms["b"][1]), 2.3)
    hum.draw_leg(c, cfg, k["hj_b"], p["legs"]["b"])
    hum.draw_leg(c, cfg, k["hj_a"], p["legs"]["a"])
    torso = c.capsule((k["hip"][0] + k["u"][0] * 0.5, k["hip"][1] + k["u"][1] * 0.5), k["S"], 4.6, 5.8)
    c.stamp(torso, SKIN)
    pants = c.ell(k["hip"][0], k["hip"][1] + 0.6, 6.0, 3.6, k["ang"] * 0.6)
    c.stamp(pants, PANT)
    c.fill(c.box(int(k["hip"][0]) - 2, int(k["hip"][1]) + 1, int(k["hip"][0]) + 1, int(k["hip"][1]) + 3) & pants, PANT[2])
    belt = c.ell(k["hip"][0], k["hip"][1] - 2.0, 6.2, 1.5, k["ang"] * 0.6)
    c.stamp(belt, LEATH)
    px, py = tf(k["hip"][0], k["hip"][1] - 2.0, k["ang"] * 0.6, 3.4, 1.6)
    pouch = c.box(int(px) - 1, int(py), int(px) + 2, int(py) + 3)
    c.stamp(pouch, LEATH)
    wx, wy = tf(k["hip"][0], k["hip"][1] - 2.0, k["ang"] * 0.6, -3.6, 1.6)
    wr = c.capsule((wx, wy), (wx - 0.5, wy + 3.8), 0.9, 0.9) | c.disc(wx - 0.5, wy + 4.2, 1.4)
    c.stamp(wr, STEEL, spec=False)
    H, hang = k["H"], k["hang"]
    hx, hy = H
    ex = p.get("ear", 0.0)
    e1 = c.tri(hx, hy, hang, (-6.5, -0.5), (-5.0, 3.0), (-15.0 - ex, -3.0))
    e2 = c.tri(hx, hy, hang, (-5.0, -5.0), (-1.0, -5.5), (-8.0 - ex * 0.5, -11.0))
    c.stamp(e2, SKIN)
    c.stamp(e1, SKIN)
    hm = hum.head_mask(c, cfg, H, hang)
    c.under(torso, hm, 0, 2, SKIN[3])
    c.stamp(hm, SKIN, lt=2)
    lx, ly = c.local(hx, hy, hang)
    pot = hm & (ly < -2.7) | (((lx / 9.0) ** 2 + ((ly + 4.2) / 5.0) ** 2 <= 1.0) & (ly < -2.7))
    c.stamp(pot, STEEL, lt=2, st=2)
    c.fill(((lx / 9.0) ** 2 + ((ly + 3.4) / 5.0) ** 2 <= 1.0) & (ly > -3.7) & (ly < -2.7), STEEL[3])
    hdl = c.capsule(tf(hx, hy, hang, -8.6, -4.0), tf(hx, hy, hang, -11.8, -3.0), 1.4, 1.2) & ~pot
    c.stamp(hdl, STEEL)
    for rv in ((-4.6, -4.6), (0.0, -6.0), (4.8, -4.4)):
        gx, gy = tf(hx, hy, hang, rv[0], rv[1])
        c.dot(gx, gy, STEEL[3])
    c.dot(*tf(hx, hy, hang, -3.0, -6.2), WHITE)
    cm = {"K": EYEC, "L": LENS[0], "l": LENS[1], "R": RED, "W": WHITE, "N": SKIN[3], "B": BRASS[1], "b": BRASS[2], "T": "#fff"}
    eyes = p.get("eyes", "open")
    strap = c.box(0, 0, 0, 0)
    for xx in range(-9, -5):
        gx, gy = tf(hx, hy, hang, xx + 0.5, 0.5)
        c.dot(gx, gy, LEATH[2])
    if eyes in ("open", "wide", "snarl"):
        put(c, hx, hy, hang, 1.4, -1.6, [".BBBB.", "BLLLlB", "BLRRlB", "BlllLB", ".BBBB."], cm)
        put(c, hx, hy, hang, -3.4, -0.8, [".BBB.", "BLLlB", "BLRlB", ".BBB."], cm)
        put(c, hx, hy, hang, 0.8, -3.0, ["KKKK", ".KKK"], cm)
        put(c, hx, hy, hang, -4.4, -2.2, ["KKK", "KK."], cm)
    elif eyes == "squint":
        put(c, hx, hy, hang, 1.4, -1.0, ["K...", ".KKK", "K..."], cm)
        put(c, hx, hy, hang, -3.4, -1.0, [".K", "K.", ".K"], cm)
    elif eyes == "x":
        put(c, hx, hy, hang, 1.6, -1.6, ["K...K", ".K.K.", "..K..", ".K.K.", "K...K"], cm)
        put(c, hx, hy, hang, -3.4, -1.0, ["K.K", ".K.", "K.K"], cm)
    elif eyes == "tired":
        put(c, hx, hy, hang, 1.4, -1.0, [".BBBB.", "BKKKKB", ".BBBB."], cm)
        put(c, hx, hy, hang, -3.4, -1.0, [".BBB.", "BKKKB", ".BBB."], cm)
    m = p.get("mouth", "snarl")
    if m == "snarl":
        put(c, hx, hy, hang, -0.4, 3.6, ["KKKKKK", "KWKWKK", ".K.K.."], cm)
    elif m == "open":
        put(c, hx, hy, hang, -0.8, 3.2, ["KKKKKKK", "KWKWKWK", "KKRRRKK", ".KKKKK."], dict(cm, R="#d8485a"))
    elif m == "pant":
        put(c, hx, hy, hang, -0.4, 3.6, ["KKKKK", "KRRRK", ".KKK."], dict(cm, R="#d8485a"))
    elif m == "flat":
        put(c, hx, hy, hang, 0.0, 4.0, ["KKKKK"], cm)
    put(c, hx, hy, hang, 9.4, 0.2, ["N"], cm)
    ah = (k["sh_a"][0] + arms["a"][0], k["sh_a"][1] + arms["a"][1])
    if p.get("knife") is not None:
        knife(c, ah, p["knife"], p.get("curve", 0.5))
    hum.draw_arm(c, cfg, k["sh_a"], ah, 2.5)
    for s in p.get("streaks", []):
        for i in range(s[2]):
            c.dot(s[0] - i, s[1], WHITE)
    for s in p.get("stars", []):
        for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            c.dot(s[0] + dx, s[1] + dy, "#ffe45e")
    for s in p.get("sweat", []):
        c.dot(s[0], s[1], "#9fd8ff"); c.dot(s[0], s[1] + 1, "#9fd8ff")
    return c


def frames():
    L = dict
    idle = []
    for i, br in enumerate([0, 0.9, 1.0, 0.4]):
        idle.append(L(lean=0.14, breath=br, eyes="open", mouth="snarl", ear=[0, 0.6, 1.2, 0.6][i], arms={"a": (4.5, 3.0), "b": (-3.5, 5.0)},
                      knife=0.25, legs={"a": (4.5, 0), "b": (-4.0, 0)}))
    W = [((5.5, 0, 1.0), (-5.0, 1.4, 1.0), 0.0, (-4, 3.5)),
         ((2.5, 0, 1.3), (-5.0, 3.5, 1.3), 1.0, (-3, 4.5)),
         ((-1.0, 0, 1.03), (2.0, 3.5, 1.5), -0.6, (-2, 5.0)),
         ((-5.0, 1.4, 1.0), (5.5, 0, 1.0), 0.0, (-4, 3.5)),
         ((-5.0, 3.5, 1.3), (2.5, 0, 1.3), 1.0, (-3, 4.5)),
         ((2.0, 3.5, 1.5), (-1.0, 0, 1.03), -0.6, (-2, 5.0))]
    walk = []
    for i, (la, lb, bob, ab) in enumerate(W):
        walk.append(L(lean=0.24, hip=(20.0, 30.6 + bob), legs={"a": la, "b": lb}, arms={"a": (4.5, 3.4), "b": ab},
                      knife=0.35 + (0.15 if i % 3 == 1 else 0.0), eyes="open", mouth="snarl", ear=[0, 1, 1.5, 0, 1, 1.5][i]))
    windup = [L(lean=-0.08, hip=(19.6, 31.2), legs={"a": (5.0, 0, 1.2), "b": (-5.0, 0, 1.2)}, arms={"a": (-1.0, -3.0), "b": (-5.0, 2.0)},
                knife=-0.7, eyes="open", mouth="snarl"),
              L(lean=-0.22, hip=(19.0, 31.8), legs={"a": (5.5, 0, 1.3), "b": (-5.0, 0, 1.3)}, arms={"a": (-4.0, -5.0), "b": (-5.0, 0.0)},
                knife=-1.4, eyes="wide", mouth="open", ear=1.5),
              L(lean=-0.32, hip=(18.4, 32.2), legs={"a": (6.0, 0, 1.35), "b": (-5.5, 0, 1.4)}, arms={"a": (-6.0, -4.0), "b": (-5.0, 1.0)},
                knife=-1.9, eyes="wide", mouth="open", ear=2.5)]
    dash = [L(lean=0.55, hip=(16.0, 31.6), legs={"a": (9.0, 1.0, 1.0), "b": (-6.0, 3.0, 1.1)}, arms={"a": (8.0, 0.5), "b": (-4.0, 4.0)},
              knife=1.55, curve=0.4, eyes="wide", mouth="open", ear=3.0, streaks=[(3, 14, 3), (2, 20, 2)]),
            L(lean=0.6, hip=(16.0, 31.0), legs={"a": (-5.5, 3.0, 1.1), "b": (8.0, 0.5, 1.0)}, arms={"a": (8.5, 1.0), "b": (-4.0, 4.5)},
              knife=1.6, curve=0.4, eyes="wide", mouth="open", ear=3.5, streaks=[(3, 17, 3), (2, 23, 2)])]
    crouch = [L(lean=0.2, hip=(20.0, 32.6), legs={"a": (5.0, 0, 1.5), "b": (-5.0, 0, 1.5)}, arms={"a": (4.0, 4.0), "b": (-4.0, 5.0)},
                knife=0.5, eyes="open", mouth="snarl"),
              L(lean=0.32, hip=(20.0, 34.2), legs={"a": (6.0, 0, 1.9), "b": (-5.5, 0, 1.9)}, arms={"a": (5.0, 4.5), "b": (-4.0, 5.5)},
                knife=0.5, eyes="wide", mouth="open", ear=2.0)]
    air = [L(lean=0.3, hip=(20.0, 29.0), legs={"a": (5.0, 5.0, 1.8), "b": (-4.0, 3.0, 1.6)}, arms={"a": (5.0, -6.0), "b": (-5.0, -4.0)},
             knife=0.4, curve=0.3, eyes="wide", mouth="open", ear=3.0)]
    recover = [L(lean=0.3, breath=0.0, hip=(20.0, 31.4), legs={"a": (4.5, 0, 1.1), "b": (-4.5, 0, 1.1)}, arms={"a": (4.0, 6.0), "b": (-3.0, 6.5)},
                 knife=2.5, curve=0.2, eyes="tired", mouth="pant", ear=-1.0, sweat=[(33, 8)]),
               L(lean=0.38, breath=-0.8, hip=(20.0, 32.0), legs={"a": (4.5, 0, 1.2), "b": (-4.5, 0, 1.2)}, arms={"a": (4.0, 6.5), "b": (-3.0, 7.0)},
                 knife=2.5, curve=0.2, eyes="tired", mouth="pant", ear=-1.0, sweat=[(33, 10)])]
    hurt = [L(lean=-0.32, hip=(19.0, 31.0), legs={"a": (3.5, 2.5, 1.3), "b": (-6.0, 0, 1.0)}, arms={"a": (7.0, -4.0), "b": (-7.0, -2.0)},
              knife=0.6, eyes="squint", mouth="open", head_rot=-0.2, ear=-3.0, sweat=[(34, 8)])]
    defeated = [L(lean=-0.7, hip=(21.0, 30.0), legs={"a": (3.0, 4.5, 1.4), "b": (-5.0, 2.5, 1.2)}, arms={"a": (8.0, -3.0), "b": (-7.0, -1.0)},
                  knife=-0.6, eyes="x", mouth="open", head_rot=-0.2, ear=-3.0),
                L(lean=-1.15, hip=(22.0, 28.4), legs={"a": (33.0, 25.0, "abs"), "b": (30.0, 30.0, "abs")}, arms={"a": (-3.0, -8.0), "b": (-4.0, 5.0)},
                  knife=None, eyes="x", mouth="open", head_rot=0.5, ear=-4.0),
                L(lean=-1.45, hip=(24.0, 34.0), legs={"a": (34.0, 31.0, "abs"), "b": (33.0, 35.0, "abs")}, arms={"a": (5.0, -3.0), "b": (7.0, 0.5)},
                  knife=None, eyes="x", mouth="flat", head_rot=1.15, ear=-6.0, stars=[(10, 14), (15, 12)])]
    return [idle, walk, windup, dash, crouch, air, recover, hurt, defeated]
