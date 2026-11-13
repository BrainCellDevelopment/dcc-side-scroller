import numpy as np
from pxlib import *

GL1 = (112, 52, 60)
GL2 = (74, 38, 58)


def torch_frame(k):
    cv = Cv(20, 32)
    paint(cv, rect(cv, 6, 24, 13, 28), STEEL)
    paint(cv, rect(cv, 8, 14, 11, 29), WOOD)
    paint(cv, rect(cv, 6, 11, 13, 16), CHAR)
    flat(cv, rect(cv, 7, 12, 8, 12), RUST[2])
    cv.px(12, 14, RUST[3])
    cv.px(9, 25, STEEL[4])
    flame(cv, 9, 12, 11 + (k % 2), 4.2, k * 1.7, sway=[-1.2, 0.6, 1.4, -0.4][k])
    glow_halo(cv, 9.5, 7, 9, 13, GL1, GL2)
    return cv


def lichen_frame(k):
    cv = Cv(24, 24)
    rs = np.random.RandomState(11)
    pulse = [0, 1, 2, 1][k]
    blobs = [(12, 15, 6, 4), (6, 17, 3, 3), (18, 17, 4, 3), (10, 9, 4, 3), (16, 10, 3, 3), (4, 11, 2, 2)]
    for (x, y, rx, ry) in blobs:
        paint(cv, ell(cv, x - rx, y - ry, x + rx, y + ry), [GREEN[0], GREEN[0], GREEN[1], GREEN[2], GREEN[3]], hl=1, sd=1)
    for (x, y, rx, ry) in blobs:
        for i in range(3):
            sx = x + rs.randint(-rx + 1, rx)
            sy = y + rs.randint(-ry + 1, ry)
            c = GREEN[3 + (1 if pulse >= 1 else 0)] if i == 0 else GREEN[2 + (1 if pulse == 2 else 0)]
            cv.px(sx, sy, c)
            if pulse == 2 and i == 0:
                cv.px(sx + 1, sy, GREEN[3])
    glow_halo(cv, 12, 14, 9 + pulse, 12 + pulse, (36, 96, 78), (28, 66, 70))
    return cv


def fire_frame(k):
    cv = Cv(32, 48)
    paint(cv, poly(cv, [(4, 47), (7, 41), (14, 38), (22, 40), (28, 44), (28, 47)]), CHAR)
    paint(cv, line(cv, [(5, 44), (27, 41)], 3), WOOD)
    paint(cv, line(cv, [(7, 40), (25, 46)], 3), WOOD)
    flat(cv, rect(cv, 10, 41, 21, 42), RUST[3])
    heights = [30, 34, 28, 32][k % 4]
    flame(cv, 16, 42, heights, 9.5, k * 1.3, sway=[-2, 1.5, 2.5, -1][k % 4])
    flame(cv, 9, 42, 17 + (k % 3) * 2, 4.5, k * 2.1 + 1, sway=[1, -2, 1.5, -1, 2, 0][k])
    flame(cv, 23, 42, 15 + ((k + 1) % 3) * 2, 4.5, k * 1.9 + 2, sway=[-1, 2, -1.5, 1, -2, 1][k])
    rs = np.random.RandomState(40 + k)
    for i in range(5):
        cv.px(8 + rs.randint(0, 17), 4 + rs.randint(0, 24) - k * 2 % 8, FLAME_Y if i % 2 else FLAME_O)
    glow_halo(cv, 16, 32, 15, 20, GL1, GL2)
    return cv


def fireplace_frame(k):
    cv = Cv(48, 56)
    stone = rect(cv, 0, 4, 47, 55)
    paint(cv, stone, STONE, hl=1, sd=2)
    for y in range(8, 55, 8):
        flat(cv, rect(cv, 1, y, 46, y), STONE[1])
        off = 0 if (y // 8) % 2 else 6
        for x in range(off + 6, 46, 12):
            flat(cv, rect(cv, x, y - 7, x, y - 1), STONE[1])
    paint(cv, rect(cv, 11, 17, 36, 55), CHAR, hl=0, sd=0, ol=True)
    flat(cv, rect(cv, 12, 18, 35, 54), (40, 22, 40))
    paint(cv, rect(cv, 0, 4, 47, 11), WOOD, hl=1, sd=1)
    for x in range(4, 46, 8):
        flat(cv, rect(cv, x, 6, x, 9), WOOD[1])
    paint(cv, rect(cv, 9, 15, 38, 17), STONE, hl=1, sd=1)
    paint(cv, ell(cv, 4, 0, 11, 6), BONE, hl=1, sd=1)
    flat(cv, rect(cv, 6, 3, 6, 3), CHAR[0])
    flat(cv, rect(cv, 9, 3, 9, 3), CHAR[0])
    paint(cv, rect(cv, 37, 1, 39, 5), BONE, hl=1, sd=1)
    cv.px(38, 0, FLAME_Y)
    cv.px(38, -1, FLAME_O)
    paint(cv, line(cv, [(14, 52), (33, 50)], 4), WOOD)
    paint(cv, line(cv, [(15, 49), (32, 53)], 4), WOOD, ol=False)
    flat(cv, rect(cv, 14, 50, 33, 51), RUST[3])
    flame(cv, 24, 49, 24 + [0, 3, -1, 2][k], 8.5, k * 1.4, sway=[-1.5, 1.5, 2, -1][k])
    flame(cv, 17, 49, 12 + (k % 2) * 3, 4, k * 2 + 1, sway=[1, -1.5, 1, -2][k])
    flame(cv, 31, 49, 13 + ((k + 1) % 2) * 3, 4, k * 2.3 + 2, sway=[-1, 2, -1, 1][k])
    rs = np.random.RandomState(70 + k)
    for i in range(4):
        cv.px(15 + rs.randint(0, 19), 24 + rs.randint(0, 12), FLAME_Y)
    for x in range(0, 48):
        for y in range(56, 56):
            pass
    return cv


def guildmaster_frame(k):
    cv = Cv(32, 40)
    b = [0, 1, 0, 1][k]
    blink = k == 2
    paint(cv, rect(cv, 9, 36, 14, 39), IRON, hl=1, sd=1)
    paint(cv, rect(cv, 17, 36, 22, 39), IRON, hl=1, sd=1)
    robe = poly(cv, [(8, 38), (9, 21 + b), (22, 21 + b), (24, 38)])
    paint(cv, robe, PURP, hl=1, sd=2)
    flat(cv, rect(cv, 9, 35, 23, 36), BRASS[2])
    flat(cv, rect(cv, 15, 22 + b, 16, 36), BRASS[2])
    flat(cv, rect(cv, 11, 28 + b, 21, 28 + b), IRON[1])
    paint(cv, rect(cv, 24, 4, 25, 38), WOOD, hl=1, sd=0)
    gem = ell(cv, 22, 0 + (b and 0), 27, 5)
    gem_c = [PURP[3], PURP[4], PURP[3], PURP[4]][k]
    paint(cv, gem, [PURP[0], PURP[1], gem_c, PURP[4], (255, 255, 255)], hl=1, sd=1)
    arm = poly(cv, [(19, 24 + b), (24, 24 + b), (25, 29 + b), (19, 30 + b)])
    paint(cv, arm, PURP, hl=1, sd=1)
    paint(cv, ell(cv, 22, 27 + b, 26, 31 + b), BONE, hl=1, sd=1)
    paint(cv, ell(cv, 5, 24 + b, 10, 29 + b), BONE, hl=1, sd=1)
    paint(cv, rect(cv, 6, 26 + b, 10, 33 + b), PURP, hl=1, sd=1, ol=False)
    hd = ell(cv, 8, 6 + b, 23, 22 + b)
    paint(cv, hd, BONE, hl=1, sd=1)
    paint(cv, poly(cv, [(7, 8 + b), (10, 0 + b), (21, 0 + b), (24, 8 + b), (24, 10 + b), (7, 10 + b)]), PURP, hl=1, sd=1)
    flat(cv, rect(cv, 7, 9 + b, 24, 10 + b), BRASS[2])
    BR = [STONE[1], STONE[2], STONE[3], (214, 208, 214), (244, 240, 236)]
    paint(cv, poly(cv, [(10, 19 + b), (22, 19 + b), (21, 27 + b), (18, 29 + b), (16, 27 + b), (14, 29 + b), (11, 26 + b)]), BR, hl=1, sd=1)
    paint(cv, ell(cv, 11, 17 + b, 15, 20 + b), BR, hl=1, sd=1)
    paint(cv, ell(cv, 17, 17 + b, 21, 20 + b), BR, hl=1, sd=1)
    flat(cv, rect(cv, 15, 23 + b, 17, 23 + b), STONE[1])
    paint(cv, rect(cv, 13, 15 + b, 19, 17 + b), BONE, hl=0, sd=0, ol=False)
    paint(cv, ell(cv, 14, 13 + b, 18, 17 + b), IRON, hl=1, sd=1, ol=False)
    flat(cv, rect(cv, 11, 12 + b, 14, 12 + b), STONE[3])
    flat(cv, rect(cv, 17, 12 + b, 20, 12 + b), STONE[3])
    cv.px(11, 13 + b, STONE[3])
    cv.px(20, 13 + b, STONE[3])
    if blink:
        flat(cv, rect(cv, 12, 14 + b, 13, 14 + b), CHAR[0])
        flat(cv, rect(cv, 18, 14 + b, 19, 14 + b), CHAR[0])
    else:
        flat(cv, rect(cv, 12, 14 + b, 13, 15 + b), CHAR[0])
        flat(cv, rect(cv, 18, 14 + b, 19, 15 + b), CHAR[0])
        cv.px(12, 14 + b, STEEL[4])
        cv.px(18, 14 + b, STEEL[4])
    exterior_outline(cv)
    return cv


if __name__ == "__main__":
    sets = {
        "torch": [torch_frame(k) for k in range(4)],
        "lichen": [lichen_frame(k) for k in range(4)],
        "fire": [fire_frame(k) for k in range(6)],
        "fireplace": [fireplace_frame(k) for k in range(4)],
        "guildmaster": [guildmaster_frame(k) for k in range(4)],
    }
    for n, fr in sets.items():
        arr = sheet([fr])
        save(arr, "props/%s.png" % n)
        preview(arr, n, 6)
        preview12(arr, n)
