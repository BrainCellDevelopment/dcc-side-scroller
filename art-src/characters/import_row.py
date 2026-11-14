import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SHEET = os.environ.get("DCC_CARL", os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "characters", "carl.png")))
FW, FH = 320, 320
BASELINE = FH - 10
SPRITE_SCALE = 0.208
BAKE = 0.8
ROWS = {
    "idle": {"row": 0, "ref": "idle_ref.webp", "scale": 0.158, "anchor": "feet"},
    "run": {"row": 1, "ref": "run_ref.webp", "scale": 0.205, "anchor": "box"},
    "punch": {"row": 4, "ref": "punch_ref.webp", "scale": 0.18, "anchor": "feet", "split": "components"},
    "hurt": {"row": 5, "ref": "damage_ref.webp", "scale": 0.26, "anchor": "feet", "key": "black", "band": (725, 985, 625, 1536), "gap": 1, "min_w": 60, "pick": [1, 2, 3]},
    "die": {"row": 6, "ref": "damage_ref.webp", "scale": 0.26, "anchor": "feet", "key": "black", "band": (400, 665, 0, 1536), "split": "components"},
    "jump": {"row": 2, "ref": "jump_ref.webp", "scale": 0.205, "anchor": "box", "pick": [1], "own_bottom": True},
    "fall": {"row": 3, "ref": "jump_ref.webp", "scale": 0.205, "anchor": "box", "pick": [4], "own_bottom": True},
}


def spans(mask, gap=10):
    out, s, last = [], None, None
    for i, v in enumerate(mask):
        if v:
            if s is None:
                s = i
            last = i
        elif s is not None and i - last > gap:
            out.append((s, last + 1))
            s = None
    if s is not None:
        out.append((s, last + 1))
    return out


def feet_x(sub):
    ys = np.where(sub.sum(1) > 0)[0]
    lo = ys.max() - int((ys.max() - ys.min()) * 0.2)
    xs = np.where(sub[lo:].sum(0) > 0)[0]
    return (xs.min() + xs.max()) / 2.0


def load_frames(cfg):
    src = Image.open(os.path.join(HERE, cfg["ref"])).convert("RGBA")
    arr = np.asarray(src).copy()
    if cfg.get("key") == "black":
        from scipy import ndimage as ndi
        dark = arr[..., :3].max(2) <= 16
        lab, n = ndi.label(dark)
        edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        sizes = ndi.sum(dark, lab, range(n + 1))
        bg = np.isin(lab, [i for i in range(1, n + 1) if i in edge or sizes[i] > 4000])
        arr[..., 3] = np.where(bg, 0, 255)
    if "band" in cfg:
        y0, y1, x0, x1 = cfg["band"]
        keep_box = np.zeros(arr.shape[:2], bool)
        keep_box[y0:y1, x0:x1] = True
        arr[~keep_box, 3] = 0
    solid = arr[..., 3] > 40
    parts = []
    if cfg.get("split") == "components":
        from scipy import ndimage as ndi
        lab, n = ndi.label(solid, structure=np.ones((3, 3)))
        for i, o in enumerate(ndi.find_objects(lab), 1):
            if (lab[o] == i).sum() > 2000:
                parts.append((o[1].start, o[1].stop, lab == i))
        parts.sort(key=lambda t: t[0])
    else:
        found = spans(solid.sum(0) > 0, cfg.get("gap", 10))
        min_w = cfg.get("min_w", 0)
        wide = [sp for sp in found if sp[1] - sp[0] >= min_w]
        for sp in found:
            if sp[1] - sp[0] < min_w:
                k = min(range(len(wide)), key=lambda j: min(abs(wide[j][0] - sp[1]), abs(wide[j][1] - sp[0])))
                wide[k] = (min(wide[k][0], sp[0]), max(wide[k][1], sp[1]))
        for c0, c1 in sorted(wide):
            keep = np.zeros_like(solid)
            keep[:, c0:c1] = True
            parts.append((c0, c1, keep))
    bottom = int(np.where(solid.sum(1) > 0)[0].max()) + 1
    info = []
    for c0, c1, keep in parts:
        sub = solid & keep
        ys = np.where(sub.sum(1) > 0)[0]
        xs = np.where(sub.sum(0) > 0)[0]
        ax = c0 + feet_x(sub[:, c0:c1]) if cfg["anchor"] == "feet" else (xs.min() + xs.max()) / 2.0
        info.append((ax, xs.min(), xs.max() + 1, int(ys.max()) + 1, keep, int(ys.min())))
    half = int(max(max(ax - x0, x1 - ax) for ax, x0, x1, _, _, _ in info)) + 6
    top = max(0, min(t for *_, t in info) - 2)
    frames = []
    for ax, x0, x1, own, keep, own_top in info:
        masked = arr.copy()
        masked[~dilate(keep), 3] = 0
        im = Image.fromarray(masked)
        cx = int(round(ax)) - half
        frames.append(im.crop((cx, max(0, own_top - 2) if cfg.get("own_bottom") else top, cx + half * 2, own if cfg.get("own_bottom") else bottom)))
    return frames


def dilate(mask):
    out = mask.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            out |= np.roll(np.roll(mask, dy, 0), dx, 1)
    return out


def resample(cell, factor):
    arr = np.asarray(cell).astype(np.float64)
    if abs(factor - 1.0) < 1e-3:
        return Image.fromarray(arr.astype(np.uint8))
    w = max(1, round(cell.width * factor))
    h = max(1, round(cell.height * factor))
    a = arr[..., 3:] / 255.0
    pre = np.concatenate([arr[..., :3] * a, arr[..., 3:]], -1)
    chans = [np.asarray(Image.fromarray(pre[..., k].astype(np.float32), mode="F").resize((w, h), Image.LANCZOS)) for k in range(4)]
    al = np.clip(chans[3], 0, 255)
    rgb = np.stack(chans[:3], -1) / np.maximum(al[..., None] / 255.0, 1e-3)
    out = np.dstack([np.clip(rgb, 0, 255), al]).astype(np.uint8)
    out[al < 1] = 0
    return Image.fromarray(out)


def main(names):
    names = names or list(ROWS)
    refs = {}
    loaded = {}
    for n in names:
        cfg = ROWS[n]
        key = (cfg["ref"], bool(cfg.get("own_bottom")), str(cfg.get("band")))
        if key not in refs:
            refs[key] = load_frames(cfg)
        frames = refs[key]
        loaded[n] = [frames[i] for i in cfg["pick"]] if "pick" in cfg else frames
    cols = max(len(f) for f in loaded.values())
    rows = max(c["row"] for c in ROWS.values()) + 1
    base = Image.new("RGBA", (FW * max(cols, 8), FH * rows), (0, 0, 0, 0))
    for n in names:
        cfg = ROWS[n]
        factor = cfg["scale"] * BAKE / SPRITE_SCALE
        for i, cell in enumerate(loaded[n]):
            tile = resample(cell, factor)
            if tile.width > FW or tile.height > BASELINE + 1:
                raise SystemExit("%s frame %d is %s, too big for %dx%d" % (n, i, tile.size, FW, FH))
            base.alpha_composite(tile, (i * FW + (FW - tile.width) // 2, cfg["row"] * FH + BASELINE + 1 - tile.height))
        print(n, len(loaded[n]), "frames, source scale %.3f" % factor)
    base.save(SHEET)
    print(base.size)


if __name__ == "__main__":
    main(sys.argv[1:])
