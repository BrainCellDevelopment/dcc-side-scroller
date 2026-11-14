#!/usr/bin/env python3
"""Floor 2 art kit (#Level 2): recolours the Floor 1 tiles and backgrounds into the Floor 2 look
(bone-white floors, grey cinderblock, orange lichen). PIL only.
Tiles: tiles_cinder.png (grey cinderblock), tiles_concrete.png (white concrete), tiles_slab.png (dusty slab).
Backgrounds: bg_floor2_*, bg_floor2_artery_*, bg_floor2_corridor_* (far/mid/near).
Run: python3 art-src/floor2/gen_floor2_art.py
"""
import colorsys
import os
from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ASSETS = ROOT + "/dcc-side-scroller/assets/"


def grade(im, tint, lift, sat, orange_green=True):
    """Map luminance onto a tint ramp; lichen greens become orange."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if orange_green and 0.2 < h < 0.5 and s > 0.25:
                h = 0.07 + (h - 0.2) * 0.1
                s = min(1.0, s * 1.25)
                v = min(1.0, v * 1.15 + 0.08)
            else:
                h = tint[0]
                s = s * sat
                v = min(1.0, v * tint[2] + lift)
            r2, g2, b2 = colorsys.hsv_to_rgb(h, min(1.0, s), min(1.0, v))
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return im


def tiles():
    jobs = {
        "tiles_cinder.png": ("tiles_brick.png", (0.1, 0.0, 1.9), 0.10, 0.12),
        "tiles_concrete.png": ("tiles_stone.png", (0.1, 0.0, 2.6), 0.30, 0.08),
        "tiles_slab.png": ("tiles_plank.png", (0.09, 0.0, 2.2), 0.18, 0.15),
    }
    for out, (src, tint, lift, sat) in jobs.items():
        grade(Image.open(ASSETS + "tiles/" + src), tint, lift, sat).save(ASSETS + "tiles/" + out)
        print("wrote", out)


def backgrounds():
    pairs = {"floor2": "floor1", "floor2_artery": "floor1_artery", "floor2_corridor": "floor1_corridor"}
    for new, old in pairs.items():
        for layer in ("far", "mid", "near"):
            src = ASSETS + "bg/bg_%s_%s.png" % (old, layer)
            if not os.path.exists(src):
                continue
            grade(Image.open(src), (0.08, 0.0, 1.6), 0.07, 0.35).save(ASSETS + "bg/bg_%s_%s.png" % (new, layer))
            print("wrote bg_%s_%s.png" % (new, layer))


if __name__ == "__main__":
    tiles()
    backgrounds()
