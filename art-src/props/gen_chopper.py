"""Goblin Copper Chopper ride art (#69): the chopper, barricade, rot sticker, steam valve and coal.

Run with /tmp/artvenv/bin/python from art-src/props. Writes into dcc-side-scroller/assets/props.
All sprites face right and are drawn at final size; the ride mirrors them for leftward travel.
"""
import math
import os
from PIL import Image

ASSETS = os.path.join(os.path.dirname(__file__), "..", "..", "dcc-side-scroller", "assets", "props")
O = (12, 5, 8, 255)
COPPER = [(110, 52, 28, 255), (170, 92, 44, 255), (214, 130, 62, 255), (246, 176, 96, 255)]
STEEL = [(38, 36, 46, 255), (78, 74, 92, 255), (124, 120, 136, 255), (174, 170, 184, 255)]
BONE = [(74, 56, 56, 255), (138, 120, 102, 255), (200, 182, 146, 255), (238, 226, 192, 255)]
RED = [(74, 28, 32, 255), (143, 64, 52, 255), (212, 72, 56, 255)]
STEAM = [(150, 156, 164, 255), (200, 206, 212, 255), (240, 244, 248, 255)]


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x0, y0, x1, y1, c):
    px = im.load()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < im.width and 0 <= y < im.height:
                px[x, y] = c


def disc(im, cx, cy, r, c):
    px = im.load()
    for y in range(int(cy - r), int(cy + r) + 1):
        for x in range(int(cx - r), int(cx + r) + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.5 and 0 <= x < im.width and 0 <= y < im.height:
                px[x, y] = c


def line(im, x0, y0, x1, y1, c, w=1):
    px = im.load()
    n = int(max(abs(x1 - x0), abs(y1 - y0))) * 2 + 1
    for i in range(n + 1):
        t = i / n
        x = round(x0 + (x1 - x0) * t)
        y = round(y0 + (y1 - y0) * t)
        for dx in range(w):
            for dy in range(w):
                if 0 <= x + dx < im.width and 0 <= y + dy < im.height:
                    px[x + dx, y + dy] = c


def outline(im):
    src = im.copy()
    sp = src.load()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if sp[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and sp[nx, ny][3] > 0 and sp[nx, ny] != O:
                        px[x, y] = O
                        break


def wheel(im, cx, cy, r, phase):
    disc(im, cx, cy, r, O)
    disc(im, cx, cy, r - 2, STEEL[0])
    disc(im, cx, cy, r - 5, STEEL[1])
    for k in range(4):
        a = phase + k * math.pi / 2
        line(im, cx, cy, cx + math.cos(a) * (r - 3), cy + math.sin(a) * (r - 3), STEEL[3])
    disc(im, cx, cy, 2, COPPER[2])


def chopper_frame(i):
    im = canvas(104, 48)
    phase = i * math.pi / 8
    # sidecar tub with a skull on the nose, trailing behind the bike
    rect(im, 2, 28, 34, 38, COPPER[1])
    rect(im, 2, 28, 34, 30, COPPER[3])
    rect(im, 2, 36, 34, 38, COPPER[0])
    rect(im, 4, 24, 32, 28, STEEL[1])
    rect(im, 6, 26, 30, 28, STEEL[0])
    disc(im, 6, 33, 5, BONE[2])
    rect(im, 4, 33, 9, 38, BONE[2])
    px = im.load()
    for x, y in ((4, 31), (7, 31)):
        px[x, y] = O
    px[5, 34] = O
    px[7, 34] = O
    wheel(im, 18, 40, 6, phase)
    line(im, 34, 33, 42, 33, STEEL[2], 2)
    # bike frame, tank, engine
    wheel(im, 46, 37, 10, phase)
    wheel(im, 90, 37, 10, -phase)
    line(im, 46, 37, 62, 24, STEEL[2], 2)
    line(im, 62, 24, 90, 37, STEEL[3], 2)
    line(im, 66, 12, 88, 36, STEEL[2], 2)
    rect(im, 52, 22, 74, 34, STEEL[1])
    rect(im, 52, 22, 74, 24, STEEL[2])
    rect(im, 56, 26, 70, 33, STEEL[0])
    rect(im, 54, 9, 72, 20, COPPER[1])
    rect(im, 54, 9, 72, 11, COPPER[3])
    rect(im, 54, 18, 72, 20, COPPER[0])
    rect(im, 60, 12, 66, 14, COPPER[3])
    rect(im, 40, 17, 52, 21, RED[1])
    rect(im, 40, 17, 52, 18, RED[2])
    # handlebars and headlamp
    line(im, 70, 12, 76, 8, STEEL[3], 2)
    disc(im, 80, 20, 3, BONE[3])
    # exhaust stack venting steam
    rect(im, 40, 22, 44, 36, STEEL[2])
    rect(im, 38, 12, 42, 22, STEEL[1])
    puff = 3 + (i % 4)
    for k in range(3):
        disc(im, 38 - k * 3, 8 - k * 4 - (i % 2), puff - k, STEAM[min(k, 2)])
    outline(im)
    return im


def barricade():
    im = canvas(32, 40)
    for x0 in (3, 12, 21):
        rect(im, x0, 6, x0 + 7, 38, (90, 54, 34, 255))
        rect(im, x0, 6, x0 + 1, 38, (170, 118, 64, 255))
        rect(im, x0 + 7, 6, x0 + 7, 38, (30, 18, 14, 255))
    rect(im, 1, 14, 30, 18, STEEL[1])
    rect(im, 1, 14, 30, 15, STEEL[3])
    rect(im, 1, 28, 30, 32, STEEL[1])
    rect(im, 1, 28, 30, 29, STEEL[3])
    for x in (4, 14, 24):
        rect(im, x, 2, x + 2, 6, STEEL[3])
        rect(im, x + 1, 0, x + 1, 2, STEEL[3])
    rect(im, 12, 19, 19, 26, RED[2])
    rect(im, 14, 20, 17, 25, BONE[3])
    outline(im)
    return im


def rot_sticker(i):
    im = canvas(24, 16)
    w = 22 + (i % 2)
    rect(im, 12 - w // 2, 3, 12 + w // 2 - 1, 14, (26, 22, 30, 255))
    rect(im, 12 - w // 2, 3, 12 + w // 2 - 1, 4, (62, 56, 74, 255))
    px = im.load()
    for x in range(12 - w // 2, 12 + w // 2, 3):
        px[x, 2] = (26, 22, 30, 255)
        px[x, 15] = (26, 22, 30, 255)
    for x, y in ((8, 8), (15, 8)):
        rect(im, x, y, x + 1, y + 1, RED[2] if i % 2 == 0 else (255, 120, 90, 255))
    outline(im)
    return im


def steam_valve(i):
    im = canvas(24, 32)
    rect(im, 9, 14, 14, 31, STEEL[1])
    rect(im, 9, 14, 10, 31, STEEL[3])
    rect(im, 5, 28, 18, 31, STEEL[2])
    disc(im, 11, 10, 7, COPPER[1])
    disc(im, 11, 10, 5, COPPER[2])
    line(im, 4, 10, 18, 10, COPPER[0], 2)
    line(im, 11, 3, 11, 17, COPPER[0], 2)
    disc(im, 11, 10, 2, STEEL[3])
    puff = 2 + (i % 2)
    disc(im, 19, 4 - i % 2, puff, STEAM[2])
    disc(im, 21, 1, 1, STEAM[1])
    outline(im)
    return im


def coal():
    im = canvas(16, 12)
    for (cx, cy, r) in ((5, 8, 4), (11, 8, 4), (8, 4, 4)):
        disc(im, cx, cy, r, (24, 22, 28, 255))
    px = im.load()
    for x, y in ((6, 6), (9, 3), (11, 9), (4, 9)):
        px[x, y] = (246, 136, 42, 255)
    outline(im)
    return im


def sheet(frames, path):
    w = sum(f.width for f in frames)
    h = max(f.height for f in frames)
    out = canvas(w, h)
    x = 0
    for f in frames:
        out.paste(f, (x, h - f.height))
        x += f.width
    out.save(path)
    print("wrote", os.path.normpath(path), out.size)


if __name__ == "__main__":
    sheet([chopper_frame(i) for i in range(4)], os.path.join(ASSETS, "chopper.png"))
    sheet([barricade()], os.path.join(ASSETS, "chopper_barricade.png"))
    sheet([rot_sticker(i) for i in range(2)], os.path.join(ASSETS, "rot_sticker.png"))
    sheet([steam_valve(i) for i in range(2)], os.path.join(ASSETS, "steam_valve.png"))
    sheet([coal()], os.path.join(ASSETS, "coal.png"))
