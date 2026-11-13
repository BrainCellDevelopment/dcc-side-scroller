import numpy as np
from pxlib import *

YEL = (244, 200, 88)
DRK = (58, 36, 48)


def W(x, y):
    return (56 + x, 64 + y)


def body():
    cv = Cv(112, 64)
    arm = rect(cv, *W(26, -23), *W(46, -14))
    paint(cv, arm, STEEL)
    rect_ex = rect(cv, *W(-56, -26), *W(-51, -21))
    paint(cv, rect_ex, STEEL)
    flat(cv, rect(cv, *W(-56, -26), *W(-55, -21)), CHAR[0])
    ch = poly(cv, [W(-52, -30), W(30, -30), W(37, -17), W(37, -11), W(-52, -11)])
    paint(cv, ch, IRON, hl=1, sd=2)
    for sx in (-36, -14, 10):
        flat(cv, rect(cv, *W(sx, -29), *W(sx, -12)), IRON[0])
        for ry in (-26, -20, -14):
            cv.px(*W(sx - 1, ry), IRON[4])
            cv.px(*W(sx + 1, ry), IRON[4])
    p1 = rect(cv, *W(-50, -27), *W(-38, -15))
    paint(cv, p1, STEEL)
    p2 = rect(cv, *W(-11, -26), *W(5, -14))
    paint(cv, p2, RUST)
    p3 = rect(cv, *W(13, -27), *W(26, -17))
    paint(cv, p3, STEEL)
    for (a, b, c_, d) in ((-49, -26, -39, -16), (-10, -25, 4, -15), (14, -26, 25, -18)):
        for (x, y) in ((a, b), (c_, b), (a, d), (c_, d)):
            cv.px(*W(x, y), STEEL[4] if (x, y) != (a, d) else STEEL[0])
    paint(cv, rect(cv, *W(-33, -27), *W(-17, -15)), CHAR, hl=1, sd=1)
    paint(cv, ell(cv, *W(-31, -26), *W(-19, -19)), BONE, hl=1, sd=1)
    paint(cv, rect(cv, *W(-29, -20), *W(-21, -16)), BONE, hl=1, sd=1)
    for ex in (-29, -24):
        flat(cv, rect(cv, *W(ex, -24), *W(ex + 2, -22)), CHAR[0])
    cv.px(*W(-26, -21), CHAR[0])
    for tx in (-28, -26, -24, -22):
        cv.px(*W(tx, -17), CHAR[0])
        cv.px(*W(tx, -16), CHAR[0])
    for x in range(-50, 30, 6):
        cv.px(*W(x, -28), IRON[4])
        cv.px(*W(x, -27), IRON[0])
    flat(cv, rect(cv, *W(-52, -14), *W(36, -12)), IRON[0])
    for (x, y0, y1) in ((-45, -14, -8), (-27, -13, -9), (2, -14, -10), (22, -16, -12)):
        pass
    for x, y0 in ((-46, -27), (-3, -27), (18, -26), (-34, -14)):
        flat(cv, rect(cv, *W(x, y0 + 2), *W(x, y0 + 7)), RUST[2])
    speckle(cv, ch, IRON[0], 0.08, 3)
    speckle(cv, ch, RUST[3], 0.02, 4)
    bo = rrect(cv, *W(-54, -47), *W(-31, -31))
    cyl_h(cv, bo, BRASS)
    for bx in (-50, -42, -34):
        bm = rect(cv, *W(bx, -47), *W(bx + 1, -31)) & bo
        flat(cv, bm, BRASS[0])
        cv.px(*W(bx, -46), BRASS[4])
        cv.px(*W(bx, -32), BRASS[4])
    for (x, y) in ((-47, -42), (-39, -42), (-47, -36), (-39, -36)):
        cv.px(*W(x, y), BRASS[4])
        cv.px(*W(x + 1, y + 1), BRASS[0])
    g = ell(cv, *W(-39, -43), *W(-34, -38))
    paint(cv, g, STEEL, hl=1, sd=1)
    flat(cv, rect(cv, *W(-37, -42), *W(-36, -40)), STEEL[4])
    pts_line(cv, *W(-36, -41), *W(-35, -43), RUST[3])
    st = rect(cv, *W(-46, -58), *W(-39, -47))
    cyl_v(cv, st, STEEL)
    for y in (-52, -49):
        flat(cv, rect(cv, *W(-46, y), *W(-39, y)), STEEL[1])
    rim = rect(cv, *W(-48, -61), *W(-37, -58))
    paint(cv, rim, STEEL, hl=1, sd=1)
    flat(cv, rect(cv, *W(-46, -61), *W(-39, -60)), CHAR[0])
    speckle(cv, st, CHAR[1], 0.15, 5)
    bk = rect(cv, *W(12, -44), *W(16, -31))
    paint(cv, bk, LEAT)
    cu = rrect(cv, *W(12, -34), *W(29, -31))
    paint(cv, cu, LEAT)
    flat(cv, rect(cv, *W(13, -30), *W(14, -30)), STEEL[1])
    flat(cv, rect(cv, *W(27, -30), *W(28, -30)), STEEL[1])
    cs = rect(cv, *W(27, -41), *W(33, -31))
    paint(cv, cs, STEEL)
    for (gx, gy) in ((29, -39), (29, -35)):
        g2 = ell(cv, *W(gx - 1, gy - 1), *W(gx + 1, gy + 1))
        flat(cv, g2, BONE[4])
        cv.px(*W(gx, gy), RUST[3])
    pts_line(cv, *W(32, -41), *W(34, -47), STEEL[3])
    flat(cv, ell(cv, *W(33, -49), *W(36, -46)), RUST[3], ol=True)
    cv.px(*W(33, -49), RUST[4])
    lamp = rect(cv, *W(31, -44), *W(34, -42))
    paint(cv, lamp, BRASS)
    cv.px(*W(33, -43), BRASS[4])
    pole_l = rect(cv, *W(13, -58), *W(13, -44))
    flat(cv, pole_l, STEEL[2], ol=True)
    pole_r = rect(cv, *W(32, -58), *W(32, -50))
    flat(cv, pole_r, STEEL[2], ol=True)
    pts = [W(9, -64), W(35, -64), W(36, -58), W(33, -56), W(30, -58), W(26, -55), W(22, -58), W(18, -56), W(14, -58), W(11, -56), W(8, -59)]
    cp = poly(cv, pts)
    paint(cv, cp, CLOTH, hl=1, sd=1)
    patch = rect(cv, *W(22, -63), *W(29, -60))
    paint(cv, patch, LEAT, ol=False)
    pts_line(cv, *W(14, -62), *W(18, -62), CLOTH[1])
    pts_line(cv, *W(30, -62), *W(33, -62), CLOTH[1])
    for x in (12, 21, 30):
        cv.px(*W(x, -63), CLOTH[4])
    nose = poly(cv, [W(30, -30), W(37, -17), W(37, -11), W(30, -11)])
    for (x, y) in ((32, -22), (34, -16), (33, -26)):
        cv.px(*W(x, y), IRON[4])
        cv.px(*W(x, y + 1), IRON[0])
    for k in range(0, 6):
        flat(cv, rect(cv, *W(31 + (k % 2) * 3, -22 + k * 2), *W(32 + (k % 2) * 3, -21 + k * 2)), YEL if k % 2 == 0 else DRK)
    exterior_outline(cv)
    return cv


def hatch_frame(state, k):
    cv = Cv(40, 24)
    pivot_y = 19
    if state == 'open':
        beam = [14, 16, 18][k]
        hole = rect(cv, 5, 19, 34, 22)
        flat(cv, hole, (88, 30, 56))
        for y, c in ((22, (150, 52, 60)), (21, (214, 100, 48)), (20, (244, 160, 64)), (19, (255, 226, 120))):
            flat(cv, rect(cv, 6, y, 33, y), c)
        for y in range(19 - beam, 19):
            t = (19 - y) / beam
            for x in range(9, 31):
                edge = abs(x - 19.5) / 11
                dens = 1 - t - edge * 0.5
                if dens > 0.5 and (x + y) % 2 == 0:
                    cv.px(x, y, FLAME_Y if t < 0.4 else FLAME_W if dens > 0.7 else FLAME_O)
                elif dens > 0.2 and (x % 2 == 0 and y % 2 == 0):
                    cv.px(x, y, FLAME_O)
        for (sx, sy) in (((14, 6), (24, 4), (19, 9)), ((12, 4), (26, 7), (20, 3)), ((16, 5), (23, 9), (28, 4)))[k]:
            cv.px(sx, sy, FLAME_W)
        flat(cv, rect(cv, 4, 19, 4, 22), STEEL[0])
        flat(cv, rect(cv, 35, 19, 35, 22), STEEL[0])
        ang = 100
    elif state == 'opening':
        ang = [20, 50, 82][k]
    else:
        ang = 0
    for side in (0, 1):
        th = np.radians(ang)
        L = 16.5 if state == 'closed' else 16
        px_, py_ = (3.5, pivot_y + 0.5) if side == 0 else (36.5, pivot_y + 0.5)
        dx = np.cos(th) * (1 if side == 0 else -1)
        dy = -np.sin(th)
        nx = np.sin(th) * (1 if side == 0 else -1)
        ny = np.cos(th)
        t = 4
        pts = [(px_, py_), (px_ + L * dx, py_ + L * dy), (px_ + L * dx + t * nx, py_ + L * dy + t * ny), (px_ + t * nx, py_ + t * ny)]
        m = poly(cv, [(int(round(a)), int(round(b))) for a, b in pts])
        paint(cv, m, STEEL, hl=1, sd=1)
        ys, xs = np.nonzero(m)
        for y, x in zip(ys, xs):
            if ((x + y) // 3) % 2 == 0 and cv.get(x, y)[:3] != OL:
                cv.px(x, y, YEL if cv.get(x, y)[:3] in (STEEL[2], STEEL[3], STEEL[4]) else BRASS[1])
        if m.any():
            ex = int(round(px_ + (L - 2) * dx))
            ey = int(round(py_ + (L - 2) * dy))
            cv.px(ex, ey, STEEL[4])
    if state == 'closed':
        flat(cv, rect(cv, 19, 19, 20, 22), DRK)
        v = ell(cv, 17, 14, 22, 19)
        paint(cv, v, BRASS)
        flat(cv, rect(cv, 19, 15, 20, 18), BRASS[0])
        flat(cv, rect(cv, 17, 16, 22, 17), BRASS[0])
        flat(cv, rect(cv, 19, 16, 20, 17), BRASS[3])
    cv.px(3, 18, STEEL[4])
    return cv


def driver_frames():
    out = []
    for k in range(2):
        cv = Cv(24, 24)
        b = 0 if k == 0 else 1
        paint(cv, rect(cv, 7, 17, 17, 21), CLOTH, hl=1, sd=1)
        paint(cv, rect(cv, 8, 9 + b, 16, 18), RUST, hl=1, sd=1)
        flat(cv, rect(cv, 8, 15 + b, 16, 15 + b), BRASS[1])
        paint(cv, rect(cv, 15, 19, 21, 22), IRON, hl=1, sd=1)
        paint(cv, rect(cv, 17, 20, 22, 23), CHAR, hl=1, sd=1)
        hd = ell(cv, 8, 2 + b, 19, 11 + b)
        paint(cv, hd, GREEN, hl=1, sd=1)
        paint(cv, poly(cv, [(8, 5 + b), (3, 3 + b), (9, 8 + b)]), GREEN, hl=1, sd=1)
        paint(cv, rect(cv, 19, 6 + b, 21, 9 + b), GREEN, hl=1, sd=1, ol=True)
        pot = poly(cv, [(7, 5 + b), (8, 0 + b), (19, 0 + b), (20, 5 + b)])
        paint(cv, pot, STEEL, hl=1, sd=1)
        flat(cv, rect(cv, 11, 0 + b, 14, 0 + b), STEEL[4])
        flat(cv, rect(cv, 7, 5 + b, 20, 5 + b), STEEL[1])
        paint(cv, ell(cv, 14, 5 + b, 18, 9 + b), BRASS, hl=1, sd=1)
        flat(cv, rect(cv, 15, 6 + b, 16, 7 + b), BONE[4])
        flat(cv, rect(cv, 12, 4 + b, 18, 4 + b), IRON[0])
        cv.px(17, 9 + b, IRON[0])
        cv.px(16, 10 + b, IRON[0])
        cv.px(14, 10 + b, IRON[0])
        arm = line(cv, [(13, 13 + b), (19, 15 - b)], 1)
        paint(cv, arm, GREEN, hl=1, sd=1)
        paint(cv, ell(cv, 19, 14 - b, 22, 17 - b), GREEN, hl=1, sd=1)
        exterior_outline(cv)
        out.append(cv)
    return out


def wheel_frame(k):
    cv = Cv(28, 28)
    phi = np.radians(k * 10.0)
    cx, cy = 13.5, 13.5
    for i in range(6):
        a = phi + i * np.pi / 3
        a0, a1 = a - 0.5, a + 0.5
        tip = (cx + np.cos(a) * 14, cy + np.sin(a) * 14)
        b0 = (cx + np.cos(a0) * 8, cy + np.sin(a0) * 8)
        b1 = (cx + np.cos(a1) * 8, cy + np.sin(a1) * 8)
        m = poly(cv, [(round(p[0]), round(p[1])) for p in (b0, tip, b1)])
        paint(cv, m, STEEL, hl=1, sd=1)
        flat(cv, rect(cv, int(tip[0]) - 0, int(tip[1]) - 0, int(tip[0]), int(tip[1])), RUST[3])
    disc = ell(cv, 4, 4, 23, 23)
    paint(cv, disc, IRON, hl=2, sd=2)
    ring = ell(cv, 7, 7, 20, 20)
    flat(cv, ring, IRON[1])
    flat(cv, ell(cv, 8, 8, 19, 19), IRON[2])
    for i in range(6):
        a = phi + i * np.pi / 3 + np.pi / 6
        bx, by = cx + np.cos(a) * 7, cy + np.sin(a) * 7
        cv.px(bx, by, BRASS[4])
        cv.px(bx + 1, by + 1, BRASS[0])
    hub = ell(cv, 10, 10, 17, 17)
    paint(cv, hub, BRASS, hl=1, sd=1)
    for i in range(6):
        a = phi + i * np.pi / 3
        cv.px(cx + np.cos(a) * 2.2, cy + np.sin(a) * 2.2, BRASS[0])
    flat(cv, rect(cv, 12, 12, 13, 13), BRASS[4])
    speckle(cv, disc, IRON[0], 0.1, 8 + k)
    return cv


def track_frame(k):
    cv = Cv(88, 16)
    L = 72.0
    r = 8.0
    pitch = 4
    for y in range(16):
        for x in range(88):
            px_, py_ = x + 0.5, y + 0.5
            dx = max(8 - px_, 0, px_ - 80)
            dist = np.hypot(dx, py_ - 8)
            if dist > r:
                continue
            if dist <= 5:
                cv.px(x, y, (36, 26, 42))
                continue
            if px_ < 8:
                th = np.arctan2(py_ - 8, px_ - 8)
                th = th if th > 0 else th + 2 * np.pi
                p = L + r * np.pi + L + r * (th - np.pi / 2)
            elif px_ > 80:
                th = np.arctan2(py_ - 8, px_ - 80)
                p = L + r * (th + np.pi / 2)
            elif py_ < 8:
                p = px_ - 8
            else:
                p = L + r * np.pi + (80 - px_)
            idx = int((p - k) // 2) % 2
            c = STEEL[2] if idx == 0 else STEEL[1]
            if dist > 7 and py_ < 8:
                c = STEEL[3] if idx == 0 else STEEL[2]
            if dist > 7 and py_ >= 8:
                c = STEEL[0]
            cv.px(x, y, c)
    spokes = k * 22.5
    for (wx, rad) in ((8, 5), (80, 5), (22, 3), (36, 3), (50, 3), (64, 3)):
        m = ell(cv, wx - rad, 8 - rad, wx + rad - 1, 8 + rad - 1)
        paint(cv, m, STEEL, hl=1, sd=1)
        for j in range(4):
            a = np.radians(spokes + j * 90)
            cv.px(wx - 0.5 + np.cos(a) * (rad - 2), 7.5 + np.sin(a) * (rad - 2), STEEL[0])
            if rad == 5:
                cv.px(wx - 0.5 + np.cos(a) * 2, 7.5 + np.sin(a) * 2, STEEL[0])
        cv.px(wx - 1, 7, BRASS[3])
        cv.px(wx, 7, BRASS[3])
    speckle(cv, cv.opaque(), IRON[2], 0.05, 20 + k)
    exterior_outline(cv)
    return cv


def compose(tr_k=0, wh_k=0, hatch=('closed', 0), driver=True):
    cv = Cv(150, 72)
    ox, oy = 72, 70
    b = body()
    cv.blit(b, ox - 56, oy - 64)
    cv.blit(track_frame(tr_k), ox - 10 - 44, oy - 16)
    h = hatch_frame(*hatch)
    cv.blit(h, ox - 12 - 20, oy - 28 - 23)
    if driver:
        cv.blit(driver_frames()[0], ox + 21 - 12, oy - 30 - 23)
    cv.blit(wheel_frame(wh_k), ox + 44 - 14, oy - 28)
    return cv


if __name__ == "__main__":
    save(sheet([[body()]]), "boss/dozer_body.png")
    save(sheet([[track_frame(k) for k in range(4)]]), "boss/dozer_tracks.png")
    save(sheet([[wheel_frame(k) for k in range(6)]]), "boss/dozer_wheel.png")
    hs = [[hatch_frame('closed', 0)], [hatch_frame('opening', k) for k in range(3)], [hatch_frame('open', k) for k in range(3)]]
    save(sheet(hs), "boss/dozer_hatch.png")
    save(sheet([driver_frames()]), "boss/dozer_driver.png")
    for n, a in (("body", sheet([[body()]])), ("tracks", sheet([[track_frame(k) for k in range(4)]])), ("wheel", sheet([[wheel_frame(k) for k in range(6)]])), ("hatch", sheet(hs)), ("driver", sheet([driver_frames()]))):
        preview(a, "boss_" + n, 6)
    comp = np.concatenate([compose(0, 0, ('closed', 0)).a, compose(2, 3, ('open', 1)).a], axis=1)
    preview(comp, "boss_comp", 5)
    preview12(compose(1, 2, ('open', 0)).a, "boss_comp")
