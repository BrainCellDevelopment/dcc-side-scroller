"""Quick parallax preview of the Floor 1 background styles (no Godot needed).
Run: python3 art-src/floor1/preview_bg.py <out_dir> [cam_x]
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from PIL import Image  # noqa: E402
from gen_bg_floor1 import EXT, OUT  # noqa: E402
from palette import hx  # noqa: E402

FX = (0.1, 0.3, 0.55)
FY = (0.04, 0.1, 0.18)


def frame(style, cam=(1000, 180), vis=(640, 360)):
    w, h = vis
    out = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    e = EXT[style]
    for i, layer in enumerate(("far", "mid", "near")):
        im = Image.open(OUT + "bg_%s_%s.png" % (style, layer)).convert("RGBA")
        tw, th = im.size
        ox = round(w * 0.5 - cam[0] * FX[i])
        start = (ox % tw) - tw
        top = round(h * 0.5 - th * 0.5 - (cam[1] - 180) * FY[i])
        if i == 0:
            out.paste(hx(e[0]) + (255,), (0, 0, w, top))
            out.paste(hx(e[1]) + (255,), (0, top + th, w, h))
        elif i == 1:
            out.paste(hx(e[2]) + (255,), (0, top + th, w, h))
        else:
            out.paste(hx(e[3]) + (255,), (0, top + th, w, h))
        x = start
        while x < w:
            out.paste(im, (x, top), im)
            x += tw
    return out


if __name__ == "__main__":
    out_dir = sys.argv[1]
    cam_x = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    for s in EXT:
        frame(s, (cam_x, 180)).convert("RGB").resize((1024, 576), Image.NEAREST).save(os.path.join(out_dir, "bg_%s.png" % s))
