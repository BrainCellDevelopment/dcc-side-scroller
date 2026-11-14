"""Imports the hand-supplied Hoarder pixel art into game sprites.

Reads art-src/floor1/hoarder_{idle,roar,run}_ref.webp and writes
dcc-side-scroller/assets/characters/hoarder_idle.png, hoarder_roar.png (one frame each)
and hoarder_run.png (8 frames side by side). Frame canvas 192x160 texels, feet at the
bottom centre with a 2 px margin; the Sprite2D shows a texel at 0.5 game px.
Needs numpy, pillow, scipy.
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "characters"))
FW, FH, MARGIN = 192, 160, 2
STAND_H = 144
RUN_H = 130


def key_black(arr):
    dark = arr[..., :3].max(2) <= 16
    lab, n = ndi.label(dark)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    sizes = ndi.sum(dark, lab, range(n + 1))
    bg = np.isin(lab, [i for i in range(1, n + 1) if i in edge or sizes[i] > 4000])
    arr[..., 3] = np.where(bg, 0, 255)
    solid = arr[..., 3] > 0
    lab, n = ndi.label(solid, structure=np.ones((3, 3)))
    sizes = ndi.sum(solid, lab, range(n + 1))
    # drop specks but keep the separate big pieces (the mop head floats clear of the body)
    keep = np.isin(lab, [i for i in range(1, n + 1) if sizes[i] >= 3000])
    arr[..., 3] = np.where(keep, 255, 0)
    return arr


def crop_box(arr):
    ys, xs = np.where(arr[..., 3] > 40)
    return arr[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def resize(arr, h):
    """LANCZOS on premultiplied colour, then a hard alpha threshold (no halos)."""
    w = max(1, round(arr.shape[1] * h / arr.shape[0]))
    a = arr[..., 3:].astype(np.float32) / 255.0
    pre = np.concatenate([arr[..., :3].astype(np.float32) * a, arr[..., 3:].astype(np.float32)], -1)
    ch = [np.asarray(Image.fromarray(pre[..., k]).resize((w, h), Image.LANCZOS)) for k in range(4)]
    al = np.clip(ch[3], 0, 255)
    rgb = np.stack(ch[:3], -1) / np.maximum(al[..., None] / 255.0, 1e-3)
    out = np.dstack([np.clip(rgb, 0, 255), np.where(al >= 128, 255, 0)]).astype(np.uint8)
    out[out[..., 3] == 0] = 0
    return out


def place(canvas, tile, base_y, cx=None):
    h, w = tile.shape[:2]
    x = (FW - w) // 2 if cx is None else int(round(cx - w / 2))
    y = base_y - h
    if x < 0 or x + w > FW or y < 0:
        raise SystemExit("tile %dx%d too big for the %dx%d frame" % (w, h, FW, FH))
    canvas[y:y + h, x:x + w] = tile


def standing(name):
    src = np.asarray(Image.open(os.path.join(HERE, "hoarder_%s_ref.webp" % name)).convert("RGBA")).copy()
    tile = resize(crop_box(key_black(src)), STAND_H)
    canvas = np.zeros((FH, FW, 4), np.uint8)
    place(canvas, tile, FH - MARGIN)
    Image.fromarray(canvas).save(os.path.join(OUT, "hoarder_%s.png" % name))
    print(name, tile.shape[:2][::-1], "texels")


def run():
    src = np.asarray(Image.open(os.path.join(HERE, "hoarder_run_ref.webp")).convert("RGBA")).copy()
    solid = src[..., 3] > 40
    cols = solid.sum(0) > 2
    spans, s = [], None
    for i, v in enumerate(cols):
        if v and s is None:
            s = i
        if not v and s is not None:
            spans.append((s, i))
            s = None
    if s is not None:
        spans.append((s, len(cols)))
    if len(spans) != 8:
        raise SystemExit("expected 8 run frames, found %d" % len(spans))
    crops = []
    for x0, x1 in spans:
        sub = src[:, x0:x1].copy()
        sub[sub[..., 3] <= 40] = 0
        sub[sub[..., 3] > 40, 3] = 255
        ys = np.where(sub[..., 3] > 0)[0]
        crops.append((sub[ys.min():ys.max() + 1], int(ys.max()) + 1, int(ys.max() - ys.min() + 1)))
    ground = max(b for _, b, _ in crops)
    # one shared scale (from the median frame height) so the cycle keeps its size and bounce
    scale = RUN_H / float(np.median([h for _, _, h in crops]))
    sheet = np.zeros((FH, FW * 8, 4), np.uint8)
    for i, (arr, bottom, h) in enumerate(crops):
        th = max(1, round(h * scale))
        tile = resize(arr, th)
        canvas = np.zeros((FH, FW, 4), np.uint8)
        lift = round((ground - bottom) * scale)
        place(canvas, tile, FH - MARGIN - lift)
        sheet[:, i * FW:(i + 1) * FW] = canvas
    Image.fromarray(sheet).save(os.path.join(OUT, "hoarder_run.png"))
    print("run 8 frames", sheet.shape[1], "x", sheet.shape[0])


if __name__ == "__main__":
    standing("idle")
    standing("roar")
    run()
