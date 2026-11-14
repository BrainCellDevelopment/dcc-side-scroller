import os
import sys
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHEET = os.environ.get("DCC_CARL", os.path.normpath(os.path.join(HERE, "..", "..", "dcc-side-scroller", "assets", "characters", "carl.png")))
FW, FH = 80, 80
BASELINE = FH - 2
COLORS = int(os.environ.get("RUN_COLORS", "112"))
SHARPEN = int(os.environ.get("RUN_SHARPEN", "90"))
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
        info.append((ax, xs.min(), xs.max() + 1, int(ys.max()) + 1, keep))
    half = int(max(max(ax - x0, x1 - ax) for ax, x0, x1, _, _ in info)) + 6
    frames = []
    for ax, x0, x1, own, keep in info:
        masked = arr.copy()
        masked[~dilate(keep), 3] = 0
        im = Image.fromarray(masked)
        cx = int(round(ax)) - half
        frames.append(im.crop((cx, 0, cx + half * 2, own if cfg.get("own_bottom") else bottom)))
    return frames


def dilate(mask):
    out = mask.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            out |= np.roll(np.roll(mask, dy, 0), dx, 1)
    return out


def shrink(cell, scale):
    w = max(1, round(cell.width * scale))
    h = max(1, round(cell.height * scale))
    arr = np.asarray(cell).astype(float)
    a = arr[..., 3:] / 255.0
    pre = np.concatenate([arr[..., :3] * a, arr[..., 3:]], -1)
    chans = [np.asarray(Image.fromarray(pre[..., k].astype(np.uint8)).resize((w, h), Image.BOX)).astype(float) for k in range(4)]
    sa = chans[3] / 255.0
    rgb = np.stack(chans[:3], -1) / np.maximum(sa[..., None], 1e-3)
    return np.clip(rgb, 0, 255).astype(np.uint8), sa > 0.5


def build_palette(sets):
    px = []
    for frames in sets:
        for f in frames:
            arr = np.asarray(f)
            m = arr[..., 3] > 250
            px.append(arr[m][:, :3])
    allpx = np.concatenate(px)
    rng = np.random.default_rng(1)
    if len(allpx) > 400000:
        allpx = allpx[rng.choice(len(allpx), 400000, replace=False)]
    side = int(np.ceil(np.sqrt(len(allpx))))
    pad = np.zeros((side * side, 3), np.uint8)
    pad[:len(allpx)] = allpx
    pad[len(allpx):] = allpx[0]
    return Image.fromarray(pad.reshape(side, side, 3)).quantize(COLORS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)


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
    pal = build_palette(refs.values())
    base = Image.open(SHEET).convert("RGBA")
    need_w = FW * max(len(f) for f in loaded.values())
    if base.width < need_w:
        wide = Image.new("RGBA", (need_w, base.height), (0, 0, 0, 0))
        wide.paste(base, (0, 0))
        base = wide
    for n in names:
        cfg = ROWS[n]
        row = Image.new("RGBA", (base.width, FH), (0, 0, 0, 0))
        for i, cell in enumerate(loaded[n]):
            rgb, m = shrink(cell, cfg["scale"])
            img = Image.fromarray(rgb)
            if SHARPEN:
                img = img.filter(ImageFilter.UnsharpMask(radius=0.8, percent=SHARPEN, threshold=0))
            img = img.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
            h, w = m.shape
            tile = Image.fromarray(np.dstack([np.asarray(img), np.where(m, 255, 0).astype(np.uint8)]))
            row.alpha_composite(tile, (i * FW + (FW - w) // 2, BASELINE + 1 - h))
        base.paste((0, 0, 0, 0), (0, cfg["row"] * FH, base.width, (cfg["row"] + 1) * FH))
        base.alpha_composite(row, (0, cfg["row"] * FH))
        print(n, len(loaded[n]), "frames")
    base.save(SHEET)
    print(base.size)


if __name__ == "__main__":
    main(sys.argv[1:])
