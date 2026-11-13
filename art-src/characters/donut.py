import math
import numpy as np
from PIL import Image
from pxl import tf, rgb, dilate4, OUT

TORT = ("#d08a3a", "#8a5a30", "#5a3824", "#33201a")

COL = {
    "d": "#4a2c1c", "D": "#241410", "b": "#6e4628", "o": "#c47a30", "O": "#8a4e20", "t": "#d8a860",
    "y": "#ffb81c", "k": "#120a14", "n": "#c26a7a", "W": "#ffffff", "e": "#d98aa0",
    "L": "#e6c4ff", "p": "#a468e8", "q": "#6a3cb8", "J": "#ff7ac0",
    "c": "#8a4bd0", "C": "#c8a0f4", "B": "#9fd4ff", "V": "#7c4cc4", "m": "#2a1418", "l": "#d8b8ff",
}

W = 23
CROWN = ["L.L.L.L.L", "LpLpLpLpL", "ppppJpppp", "qqqqqqqqq"]


def eyes_rows(kind):
    if kind in ("blink", "squeeze"):
        return ["ddddd", "ddddd", "kkkkk", "ddddd"]
    if kind == "sad":
        return ["ddddd", "dkkkd", "kdddk", "ddddd"]
    if kind == "wide":
        return ["yyyyy", "ykkky", "ykkky", "yyyyy"]
    return [".yyy.", "yWkyy", "ykkyy", ".yyy."]


def build_rows(d):
    ey = eyes_rows(d.get("eyes", "open"))
    rows = {}
    for i, s in enumerate(CROWN):
        rows[i] = "." * 7 + s + "." * 7
    rows[4] = "..dDdbbbdddddddbbbdDd.."
    rows[5] = ".dDddbbbooodddddbbbdDd."
    rows[6] = "dDddbbooDd" + "ttt" + "DddbbdddDd"
    L = ["bdd", "ddo", ".dD", ".dd"]
    R = ["ddb", "dod", "od.", "oo."]
    mids = ["DtttttD", "ttttttt", "ttnkntt", "tttmttt"]
    for k in range(4):
        e = ey[k].replace(".", "D")
        rows[7 + k] = L[k] + e + mids[k] + e + R[k]
    rows[11] = "ddbodb" + "ttmmtttmmtt" + "bddbdd"
    rows[12] = "ddb" + "cCcCcCcVcCcCcCcCc" + "bdd"
    rows[13] = ".ddbooobdd" + "BVB" + "bddDbddbd."
    rows[14] = "..ddbooobd" + "LVL" + "dbddDbbd.."
    rows[15] = "...dd.bd.dD.bD.dD.bd..."
    return rows


EARS = {
    "up": [(3, 2, "d"), (2, 3, "ddd"), (3, 3, "e"), (19, 2, "d"), (18, 3, "ddd"), (19, 3, "e")],
    "side": [(1, 3, "dd"), (0, 4, "d"), (0, 5, "d"), (20, 3, "dd"), (22, 4, "d"), (22, 5, "d")],
    "flat": [(0, 4, "d"), (0, 5, "d"), (22, 4, "d"), (22, 5, "d")],
}

TAILS = {
    "up": ([(-8, -3), (-12, -4), (-14, -7), (-12, -10)], (2.8, 3.4, 3.6, 3.0)),
    "swish_l": ([(-8, -3), (-12, -4), (-15, -7), (-15, -9)], (2.8, 3.4, 3.6, 3.0)),
    "swish_r": ([(-8, -3), (-11, -5), (-11, -8), (-9, -10)], (2.8, 3.4, 3.6, 3.0)),
    "back": ([(-8, -3), (-12, -4), (-15, -5), (-17, -4)], (2.8, 3.3, 3.5, 3.0)),
    "low": ([(-8, -3), (-12, -2), (-15, -1), (-17, 0)], (2.8, 3.3, 3.4, 2.9)),
    "down": ([(-8, -3), (-11, -1), (-12, 1), (-12, 3)], (2.4, 2.9, 2.9, 2.4)),
}


def sprite(d):
    g = {}
    rows = build_rows(d)
    for y, s in rows.items():
        assert len(s) == W, (y, len(s), s)
        for x, ch in enumerate(s):
            if ch != ".":
                g[(x, y)] = ch
    for x, y, s in EARS[d.get("ears", "up")]:
        for i, ch in enumerate(s):
            g[(x + i, y)] = ch
    return g


ROWS_N = 16


def draw_cat(c, P, ang, d):
    px, py = P

    def T(lx, ly):
        return tf(px, py, ang, lx, ly)

    pts, rad = TAILS[d.get("tail", "up")]
    tail = [T(*p) for p in pts]
    tm = c.capsule(tail[0], tail[1], rad[0], rad[1]) | c.capsule(tail[1], tail[2], rad[1], rad[2]) | c.capsule(tail[2], tail[3], rad[2], rad[3])
    tuft = dilate4(tm) & ~tm & (((c.xx * 7 + c.yy * 13) % 3) == 0)
    tm = tm | tuft
    c.stamp(tm, TORT)
    mx, my = T((pts[1][0] + pts[2][0]) / 2 + 1, (pts[1][1] + pts[2][1]) / 2)
    c.fill(c.ell(mx, my, 2.0, 2.6, ang) & tm, COL["o"])
    c.fill(c.disc(*tail[3], rad[3] * 0.8) & tm, COL["D"])

    ox, oy = int(round(px)) - 11 + c.ox, int(round(py)) - ROWS_N + c.oy
    g = sprite(d)
    m = np.zeros((c.h, c.w), bool)
    layer = np.zeros((c.h, c.w, 4), np.uint8)
    for (x, y), ch in g.items():
        X, Y = ox + x, oy + y
        if 0 <= X < c.w and 0 <= Y < c.h:
            m[Y, X] = True
            layer[Y, X] = (*rgb(COL[ch]), 255)
    ring = dilate4(m) & ~m
    layer[ring] = (*rgb(OUT), 255)
    if abs(ang) > 0.02:
        cx, cy = px + c.ox, py + c.oy
        im = Image.fromarray(layer, "RGBA").rotate(-math.degrees(ang), resample=Image.NEAREST, center=(cx, cy))
        layer = np.array(im)
    sel = layer[..., 3] > 0
    c.a[sel] = layer[sel]
