import math
from pxl import Canvas, put, tf
import hum

GREEN = ("#c4f07a", "#8ad04c", "#5aa83c", "#2f6a48")
OLIVE = ("#f0f08a", "#c4d460", "#92a84a", "#4e6a46")
CLOTH = ("#d89258", "#b06840", "#7a4234")
WOOD = ("#d09a5e", "#a06a38", "#62381f")
PINE = ("#fff08a", "#ffd23f", "#e8962a", "#a85a22")
PURP = ("#c88af0", "#9258d0", "#5f3698")
SACK = ("#f0d49c", "#cba062", "#8a6038")
ROCKC = ("#e2dce8", "#aba3be", "#6c6488")
EYEC = "#2a1630"
YEL = "#ffe45e"
WHITE = "#ffffff"

CFG = {
    "grunt": dict(cx=16, ground=29.3, hip=(16.0, 24.4), tl=6.0, hu=4.6, head=(7.2, 5.8), nose=(7.2, 1.8, 2.7, 2.3),
                  head_off=(1.0, 0.0), sw=3.4, hw=2.2, leg_r=1.5, arm_r=1.4, foot=(3.0, 1.7), skin=GREEN),
    "thrower": dict(cx=16, ground=29.3, hip=(16.0, 24.0), tl=6.4, hu=4.5, head=(6.6, 5.4), nose=(6.6, 1.6, 2.3, 2.0),
                    head_off=(1.0, 0.0), sw=3.0, hw=2.0, leg_r=1.3, arm_r=1.3, foot=(2.8, 1.6), skin=OLIVE),
}


def club(c, hand, th):
    d = (math.sin(th), -math.cos(th))
    shaft = c.capsule((hand[0] - d[0] * 1.5, hand[1] - d[1] * 1.5), (hand[0] + d[0] * 6.0, hand[1] + d[1] * 6.0), 1.1, 1.4)
    c.stamp(shaft, WOOD)
    pc = (hand[0] + d[0] * 9.0, hand[1] + d[1] * 9.0)
    leaves = c.tri(pc[0], pc[1], th, (-1.6, -2.4), (1.6, -2.4), (0.0, -6.2))
    leaves |= c.tri(pc[0], pc[1], th, (-1.0, -2.6), (-3.6, -4.6), (-0.4, -4.4))
    leaves |= c.tri(pc[0], pc[1], th, (1.0, -2.6), (3.6, -4.6), (0.4, -4.4))
    c.stamp(leaves, (GREEN[1], GREEN[2], GREEN[3]))
    pm = c.ell(pc[0], pc[1], 3.0, 3.5, th)
    c.stamp(pm, PINE)
    for i, (lx, ly) in enumerate([(-1.2, -1.6), (1.2, -1.6), (0.0, -0.2), (-1.8, 0.8), (1.8, 0.8), (0.0, 1.8)]):
        gx, gy = tf(pc[0], pc[1], th, lx, ly)
        c.dot(gx, gy, PINE[3])


def build(p, kind):
    cfg = CFG[kind]
    c = Canvas(32, 32)
    k = hum.skeleton(cfg, p)
    skin = cfg["skin"]
    arms = p["arms"]
    hr = 1.8
    if kind == "thrower":
        sx, sy = k["S"][0] - k["rt"][0] * 5.2, k["S"][1] - k["rt"][1] * 5.2 + 2.6
        sk = c.ell(sx, sy, 4.2, 5.0, k["ang"])
        top = c.tri(sx, sy, k["ang"], (-1.6, -4.0), (1.6, -4.0), (0.0, -7.0))
        c.stamp(top, SACK)
        c.stamp(sk, SACK)
        if not p.get("rock"):
            c.stamp(c.disc(sx + 0.5, sy - 5.0, 2.2), ROCKC)
    hb = hum.draw_arm(c, cfg, k["sh_b"], (k["sh_b"][0] + arms["b"][0], k["sh_b"][1] + arms["b"][1]), hr)
    hum.draw_leg(c, cfg, k["hj_b"], p["legs"]["b"])
    hum.draw_leg(c, cfg, k["hj_a"], p["legs"]["a"])
    torso = c.capsule((k["hip"][0] + k["u"][0] * 0.5, k["hip"][1] + k["u"][1] * 0.5), k["S"], 3.4, 4.4)
    c.stamp(torso, skin)
    cloth = c.tri(k["hip"][0], k["hip"][1] + 0.5, k["ang"] * 0.6, (-4.6, -2.2), (4.6, -2.2), (0.6, 5.6))
    cloth |= c.tri(k["hip"][0], k["hip"][1] + 0.5, k["ang"] * 0.6, (-4.6, -2.2), (1.0, -2.2), (-2.6, 4.2))
    c.stamp(cloth, CLOTH if kind == "grunt" else (PURP[1], PURP[2], "#3e2470"))
    belt = c.ell(k["hip"][0], k["hip"][1] - 1.6, 4.8, 1.2, k["ang"] * 0.6)
    c.stamp(belt, WOOD)
    if kind == "thrower":
        strap = c.capsule((k["sh_b"][0] + 1, k["sh_b"][1] + 1), (k["hip"][0] + 2, k["hip"][1] - 2), 0.7, 0.7)
        c.stamp(strap & torso, SACK, outline=False, spec=False)
    H, hang = k["H"], k["hang"]
    sc = 1.0 if kind == "grunt" else 0.7
    e1 = c.tri(H[0], H[1], hang, (-5.0, -1.5), (-4.0, 2.4), (-5.0 - 8.5 * sc - p.get("ear", 0.0), -5.0 + (0 if kind == "grunt" else 2.0)))
    e2 = c.tri(H[0], H[1], hang, (-4.0, -4.0), (0.0, -4.8), (-5.0 - p.get("ear", 0.0) * 0.5, -10.0 * sc - 1.0))
    c.stamp(e2, skin)
    c.stamp(e1, skin)
    hm = hum.head_mask(c, cfg, H, hang)
    c.under(torso, hm, 0, 2, skin[3])
    c.stamp(hm, skin, lt=2)
    lx, ly = c.local(H[0], H[1], hang)
    inner = c.tri(H[0], H[1], hang, (-5.0, -0.2), (-4.4, 1.4), (-8.5, -2.4))
    c.fill(inner & ~hm, "#a8506a")
    if kind == "thrower":
        cap = hm & (ly < -3.3)
        cap |= c.tri(H[0], H[1], hang, (-6.5, -3.4), (5.2, -3.6), (-12.0, 0.5 + p.get("tip", 0.0)))
        c.stamp(cap, PURP)
        c.fill(hm & (ly > -3.4) & (ly < -2.6) & (lx > -6.5), PURP[2])
    cm = {"K": EYEC, "Y": YEL, "W": WHITE, "N": skin[3]}
    eyes = p.get("eyes", "open")
    hx, hy = H
    if eyes == "open":
        put(c, hx, hy, hang, 2.4, -1.4, ["KKK", "YYK", "YYY"], cm)
        put(c, hx, hy, hang, -2.8, -1.4, ["KK", "YK", "YY"], cm)
    elif eyes == "blink":
        put(c, hx, hy, hang, 2.4, 0.4, ["KKK"], cm)
        put(c, hx, hy, hang, -2.8, 0.4, ["KK"], cm)
    elif eyes == "squint":
        put(c, hx, hy, hang, 2.4, -0.8, ["K..", ".KK", "K.."], cm)
        put(c, hx, hy, hang, -2.8, -0.8, [".K", "K.", ".K"], cm)
    elif eyes == "x":
        put(c, hx, hy, hang, 2.4, -1.0, ["K.K", ".K.", "K.K"], cm)
        put(c, hx, hy, hang, -3.0, -1.0, ["K.K", ".K.", "K.K"], cm)
    elif eyes == "wide":
        put(c, hx, hy, hang, 2.2, -1.8, ["KKKK", "YYYK", "YYYY", "YYYY"], cm)
        put(c, hx, hy, hang, -3.0, -1.8, ["KKK", "YYK", "YYY", "YYY"], cm)
    m = p.get("mouth", "grin")
    if m == "grin":
        put(c, hx, hy, hang, 0.4, 3.0, ["...W.", "KKKKK"], cm)
    elif m == "open":
        put(c, hx, hy, hang, 0.0, 2.6, ["KKKKKK", "KWKWWK", ".KKKK."], cm)
    elif m == "o":
        put(c, hx, hy, hang, 1.0, 3.0, ["KK", "KK"], cm)
    elif m == "flat":
        put(c, hx, hy, hang, 0.4, 3.4, ["KKKK"], cm)
    put(c, hx, hy, hang, 8.0, 0.6, ["N"], cm)
    ah = (k["sh_a"][0] + arms["a"][0], k["sh_a"][1] + arms["a"][1])
    if kind == "grunt":
        club(c, ah, p["club"])
    elif p.get("rock"):
        rd = p["rock"]
        c.stamp(c.disc(ah[0] + rd[0], ah[1] + rd[1], 2.6), ROCKC)
    hum.draw_arm(c, cfg, k["sh_a"], ah, hr)
    for s in p.get("streaks", []):
        for i in range(s[2]):
            c.dot(s[0] - i, s[1], WHITE)
    for s in p.get("stars", []):
        for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
            c.dot(s[0] + dx, s[1] + dy, YEL)
    return c, k, ah


def frames(kind):
    g = kind == "grunt"
    L = dict
    idle = []
    for i, (br, eyes) in enumerate([(0, "open"), (0.9, "open"), (1.0, "blink"), (0.4, "open")]):
        idle.append(L(lean=0.12, breath=br, eyes=eyes, mouth="grin", ear=[0, 0.5, 1.0, 0.5][i], tip=[0, 1, 1, 0][i],
                      arms={"a": (3.0, 2.0) if g else (3.0, 4.0), "b": (-2.5, 4.5)}, club=0.12 + br * 0.06,
                      rock=(1.0, -2.6) if not g else None, legs={"a": (3.4, 0), "b": (-3.0, 0)}))
    walk = []
    W = [((4.5, 0, 1.0), (-4.0, 1.2, 1.0), 0.0, (3.4, 2.4), (-3, 3.5)),
         ((2.0, 0, 1.3), (-4.0, 3.0, 1.3), 1.0, (3.4, 3.0), (-2, 4.0)),
         ((-1.0, 0, 1.03), (1.5, 3.0, 1.5), -0.5, (3.8, 2.4), (-1, 4.5)),
         ((-4.0, 1.2, 1.0), (4.5, 0, 1.0), 0.0, (3.4, 2.4), (-3, 3.5)),
         ((-4.0, 3.0, 1.3), (2.0, 0, 1.3), 1.0, (3.4, 3.0), (-2, 4.0)),
         ((1.5, 3.0, 1.5), (-1.0, 0, 1.03), -0.5, (3.8, 2.4), (-1, 4.5))]
    for i, (la, lb, bob, aa, ab) in enumerate(W):
        walk.append(L(lean=0.2, hip=(16.0, 24.4 + bob), legs={"a": la, "b": lb}, arms={"a": aa if g else (3.0, 4.0), "b": ab},
                      club=0.15 + (0.2 if i % 3 == 1 else 0.0), eyes="open", mouth="grin", rock=(1.0, -2.6) if not g else None,
                      ear=[0, 1, 1.5, 0, 1, 1.5][i], tip=[0, 1, 1, 0, 1, 1][i]))
    if g:
        windup = [L(lean=0.0, hip=(16, 25.0), legs={"a": (4.0, 0, 1.2), "b": (-3.5, 0, 1.2)}, arms={"a": (2.0, -4.5), "b": (-3.0, -1.0)},
                    club=-0.2, eyes="open", mouth="grin"),
                  L(lean=-0.22, hip=(15.4, 25.2), legs={"a": (4.0, 0, 1.3), "b": (-4.0, 0, 1.3)}, arms={"a": (-0.5, -7.0), "b": (-4.0, -3.0)},
                    club=-1.0, eyes="wide", mouth="open", ear=1.5)]
        attack = [L(lean=0.2, hip=(15.2, 24.8), legs={"a": (5.0, 0, 1.0), "b": (-4.0, 0, 1.2)}, arms={"a": (2.5, -4.0), "b": (-3.0, 2.0)},
                    club=0.35, eyes="open", mouth="open", streaks=[(10, 7, 2)]),
                  L(lean=0.4, hip=(14.6, 25.4), legs={"a": (6.0, 0, 1.0), "b": (-3.5, 0, 1.1)}, arms={"a": (2.0, 1.0), "b": (-3.5, 3.0)},
                    club=1.2, eyes="open", mouth="open", ear=1.5),
                  L(lean=0.35, hip=(14.6, 25.4), legs={"a": (6.0, 0, 1.0), "b": (-3.5, 0, 1.1)}, arms={"a": (2.0, 3.0), "b": (-3.5, 3.0)},
                    club=1.9, eyes="open", mouth="grin")]
    else:
        windup = [L(lean=-0.05, hip=(16, 24.4), legs={"a": (3.4, 0, 1.2), "b": (-3.0, 0, 1.2)}, arms={"a": (2.0, -5.0), "b": (-3.0, 1.0)},
                    rock=(0.5, -3.0), eyes="open", mouth="grin"),
                  L(lean=-0.25, hip=(15.4, 24.8), legs={"a": (4.0, 0, 1.3), "b": (-4.0, 0, 1.3)}, arms={"a": (0.5, -9.0), "b": (-4.0, -2.0)},
                    rock=(0.0, -3.0), eyes="wide", mouth="open", ear=1.0, tip=1.5)]
        attack = [L(lean=0.3, hip=(16.4, 24.4), legs={"a": (5.0, 0, 1.0), "b": (-4.0, 0, 1.2)}, arms={"a": (6.5, -6.5), "b": (-3.0, 3.0)},
                    eyes="open", mouth="open", streaks=[(12, 11, 2)]),
                  L(lean=0.45, hip=(17.0, 25.0), legs={"a": (6.0, 0, 1.0), "b": (-3.5, 0, 1.1)}, arms={"a": (6.0, 1.5), "b": (-3.5, 3.0)},
                    eyes="open", mouth="open"),
                  L(lean=0.3, hip=(16.6, 24.6), legs={"a": (5.0, 0, 1.0), "b": (-3.5, 0, 1.1)}, arms={"a": (4.5, 3.0), "b": (-3.0, 3.5)},
                    eyes="open", mouth="grin")]
    hurt = [L(lean=-0.35, hip=(15.4, 24.0), legs={"a": (3.0, 1.8, 1.3), "b": (-4.5, 0, 1.0)}, arms={"a": (5.0, -4.5), "b": (-5.5, -2.0)},
              club=0.2, rock=None, eyes="squint", mouth="open", head_rot=-0.2, ear=-2.0, tip=2.0)]
    die = [L(lean=-0.6, hip=(17.0, 23.4), legs={"a": (2.0, 4.0, 1.3), "b": (-4.5, 2.0, 1.2)}, arms={"a": (5.0, -4.5), "b": (-6.0, -2.0)},
             club=-1.4, eyes="squint", mouth="open", head_rot=-0.2, ear=-2.0, tip=2.0),
           L(lean=-1.1, hip=(18.5, 22.4), legs={"a": (25.5, 19.5, "abs"), "b": (23.0, 24.0, "abs")}, arms={"a": (-4.0, -6.0), "b": (-3.0, 5.0)},
             club=-2.0, eyes="x", mouth="open", head_rot=0.5, ear=-3.0, tip=2.0),
           L(lean=-1.42, hip=(20.0, 26.2), legs={"a": (27.5, 24.0, "abs"), "b": (26.5, 27.6, "abs")}, arms={"a": (5.0, -2.0), "b": (5.0, 0.5)},
             club=-2.5, eyes="x", mouth="o", head_rot=1.1, ear=-5.0, tip=1.0),
           L(lean=-1.5, hip=(20.0, 26.8), legs={"a": (28.0, 26.0, "abs"), "b": (27.0, 28.4, "abs")}, arms={"a": (6.0, -2.0), "b": (6.0, 0.5)},
             club=-2.5, eyes="x", mouth="flat", head_rot=1.15, ear=-5.0, stars=[(6, 9), (11, 7)])]
    for f in die:
        f.setdefault("rock", None)
    return [idle, walk, windup, attack, hurt, die]
