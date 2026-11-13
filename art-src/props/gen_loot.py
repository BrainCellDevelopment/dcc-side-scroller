import numpy as np
from pxlib import *

TIERS = {
    "Bronze": dict(body=WOOD, trim=IRON, lock=BRASS, gem=None),
    "Silver": dict(body=STEEL, trim=STONE, lock=BRASS, gem=None),
    "Gold": dict(body=RUST, trim=BRASS, lock=BRASS, gem=None),
    "Legendary": dict(body=PURP, trim=BRASS, lock=BRASS, gem=PURP),
}
GLOW = {"Bronze": (255, 214, 120), "Silver": (214, 236, 255), "Gold": (255, 232, 110), "Legendary": (236, 170, 255)}


def chest(tier, mode, k):
    t = TIERS[tier]
    cv = Cv(32, 32)
    gc = GLOW[tier]
    open_k = k if mode == 'open' else -1
    if tier == "Legendary":
        glow_halo(cv, 16, 22, 15, 18, (70, 38, 110), (48, 30, 86))
    if open_k >= 3:
        paint(cv, rect(cv, 7, 4, 24, 13), t['body'], hl=0, sd=0)
        flat(cv, rect(cv, 9, 6, 22, 12), t['body'][0])
        flat(cv, rect(cv, 11, 7, 20, 7), t['body'][1])
        paint(cv, rect(cv, 7, 4, 24, 5), t['trim'], hl=1, sd=1)
    paint(cv, rect(cv, 4, 17, 27, 31), t['body'], hl=1, sd=2)
    for x in range(8, 27, 5):
        flat(cv, rect(cv, x, 19, x, 29), t['body'][1])
    if open_k >= 0:
        flat(cv, rect(cv, 5, 17, 26, 18), gc)
        flat(cv, rect(cv, 7, 16, 24, 16), gc)
    paint(cv, rect(cv, 4, 17, 7, 31), t['trim'], hl=1, sd=1, ol=False)
    paint(cv, rect(cv, 24, 17, 27, 31), t['trim'], hl=1, sd=1, ol=False)
    paint(cv, rect(cv, 4, 26, 27, 28), t['trim'], hl=1, sd=1, ol=False)
    for (x, y) in ((5, 19), (26, 19), (5, 30), (26, 30)):
        cv.px(x, y, t['trim'][4])
    if open_k < 3:
        lift = [0, 2, 5][max(0, open_k)] if open_k >= 0 else 0
        hh = [8, 8, 6][max(0, open_k)] if open_k >= 0 else 8
        top = 17 - lift - hh
        if open_k >= 1:
            for x in range(8, 24):
                for y in range(17 - lift, 17):
                    if (x + y) % 2 == 0:
                        cv.px(x, y, gc)
        lid = rrect(cv, 4, top, 27, 16 - lift)
        paint(cv, lid, t['body'], hl=1, sd=1)
        paint(cv, rect(cv, 4, top + 1, 7, 16 - lift), t['trim'], hl=1, sd=1, ol=False)
        paint(cv, rect(cv, 24, top + 1, 27, 16 - lift), t['trim'], hl=1, sd=1, ol=False)
        flat(cv, rect(cv, 9, top + 1, 22, top + 1), t['body'][3])
        flat(cv, rect(cv, 4, 15 - lift, 27, 16 - lift), t['trim'][2])
    if open_k < 2:
        lk = rect(cv, 14, 15, 17, 21)
        paint(cv, lk, t['lock'], hl=1, sd=1)
        cv.px(15, 18, t['lock'][0])
    if tier == "Legendary":
        gm = ell(cv, 13, 22, 18, 27)
        paint(cv, gm, [PURP[0], PURP[2], PURP[3], PURP[4], (255, 255, 255)], hl=1, sd=1)
    if open_k >= 2:
        for x in range(10, 22):
            for y in range(0, 16):
                d = abs(x - 15.5) / 6.0 + y / 16.0 * 0.0
                dens = 1 - (15 - y) / (6.0 + open_k * 3) - d * 0.6
                if open_k >= 2 and dens > 0.3 and cv.a[y, x, 3] == 0 and (x + y) % 2 == 0:
                    cv.px(x, y, gc if dens > 0.55 else tuple(int(c * 0.7) for c in gc))
        rs = np.random.RandomState(open_k)
        for i in range(4 + open_k):
            cv.px(9 + rs.randint(0, 14), 2 + rs.randint(0, 12) - (open_k - 2) * 1, (255, 255, 255) if i % 2 else gc)
    if mode == 'idle' and k == 1:
        cx, cy = (23, 14) if tier != "Legendary" else (16, 9)
        for d in (-2, -1, 0, 1, 2):
            cv.px(cx + d, cy, (255, 255, 255) if d == 0 else gc)
            cv.px(cx, cy + d, (255, 255, 255) if d == 0 else gc)
    if mode == 'idle' and k == 0:
        cv.px(23 if tier != "Legendary" else 16, 14 if tier != "Legendary" else 9, (255, 255, 255))
    exterior_outline(cv)
    return cv


def loot_sheet():
    rows = []
    for tier in TIERS:
        rows.append([chest(tier, 'idle', k) for k in range(2)] + [Cv(32, 32) for _ in range(3)])
        rows.append([chest(tier, 'open', k) for k in range(5)])
    return sheet(rows)


if __name__ == "__main__":
    arr = loot_sheet()
    save(arr, "props/loot_box.png")
    preview(arr, "loot", 4)
    preview12(arr[:64], "loot")
