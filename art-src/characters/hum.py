import math
from pxl import Canvas, ik, put, tf


def leg_target(cfg, spec):
    cx, ground = cfg["cx"], cfg["ground"]
    if len(spec) == 3 and spec[2] == "abs":
        return spec[0], spec[1], 1.05, 0.0
    fx, lift = spec[0], spec[1]
    slack = spec[2] if len(spec) > 2 else 1.06
    toe = spec[3] if len(spec) > 3 else (0.4 if lift > 2 else 0.0)
    return cx + fx, ground - lift, slack, toe


def draw_leg(c, cfg, hip_j, spec):
    fx, fy, slack, toe = leg_target(cfg, spec)
    ankle = (fx, fy - 0.5)
    d = math.hypot(ankle[0] - hip_j[0], ankle[1] - hip_j[1])
    seg = max(d / 2 * slack, 1.0)
    knee, ankle = ik(hip_j, ankle, seg, seg, -1)
    r = cfg["leg_r"]
    m = c.capsule(hip_j, knee, r, r * 0.9) | c.capsule(knee, ankle, r * 0.9, r * 0.85)
    c.stamp(m, cfg["skin"])
    fr = cfg["foot"]
    foot = c.ell(fx + 1.0, fy + 0.1, fr[0], fr[1], toe)
    c.stamp(foot, cfg.get("shoe", cfg["skin"]))
    return m


def draw_arm(c, cfg, sh, hand, hand_r):
    d = math.hypot(hand[0] - sh[0], hand[1] - sh[1])
    seg = max(d / 2 * 1.1, 1.0)
    elbow, hand = ik(sh, hand, seg, seg, 1)
    r = cfg["arm_r"]
    m = c.capsule(sh, elbow, r, r * 0.85) | c.capsule(elbow, hand, r * 0.85, r * 0.8)
    c.stamp(m, cfg["skin"])
    c.stamp(c.disc(hand[0], hand[1], hand_r), cfg["skin"])
    return hand


def skeleton(cfg, p):
    ang = p.get("lean", 0.1)
    hip = p.get("hip", cfg["hip"])
    u = (math.sin(ang), -math.cos(ang))
    rt = (math.cos(ang), math.sin(ang))
    tl = cfg["tl"] + p.get("breath", 0.0)
    S = (hip[0] + u[0] * tl, hip[1] + u[1] * tl)
    hang = ang + p.get("head_rot", 0.0)
    hf, hu = p.get("head_off", cfg["head_off"])
    hu_ = cfg["hu"] + hu
    H = (S[0] + u[0] * hu_ + rt[0] * hf, S[1] + u[1] * hu_ + rt[1] * hf)
    sw = cfg["sw"]
    return dict(ang=ang, hip=hip, u=u, rt=rt, S=S, hang=hang, H=H,
                hj_b=(hip[0] - rt[0] * cfg["hw"], hip[1] + 1.2), hj_a=(hip[0] + rt[0] * cfg["hw"], hip[1] + 1.2),
                sh_b=(S[0] - rt[0] * sw, S[1] - rt[1] * sw + 0.6), sh_a=(S[0] + rt[0] * sw, S[1] + rt[1] * sw + 0.6))


def head_mask(c, cfg, H, hang):
    lx, ly = c.local(H[0], H[1], hang)
    rx, ry = cfg["head"]
    m = (lx / rx) ** 2 + (ly / ry) ** 2 <= 1.0
    nx, ny, nrx, nry = cfg["nose"]
    m |= ((lx - nx) / nrx) ** 2 + ((ly - ny) / nry) ** 2 <= 1.0
    return m
