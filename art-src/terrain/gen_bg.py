import os
import sys
import importlib
from PIL import Image
from pix import ncolors
from bgkit import EXT, force_rows

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller", "assets", "bg")) + "/"
STYLES = {"street": "bg_street", "stairwell": "bg_stairwell", "tunnel": "bg_tunnel", "guildhall": "bg_guildhall"}

if __name__ == "__main__":
    want = sys.argv[1:] or list(STYLES)
    for s in want:
        mod = importlib.import_module(STYLES[s])
        for layer in ("far", "mid", "near"):
            img = getattr(mod, layer)()
            e = EXT[s]
            if layer == "far":
                img = force_rows(img, e[0], e[1])
            else:
                img = force_rows(img, None, e[2] if layer == "mid" else e[3])
            img.save(OUT + f"bg_{s}_{layer}.png")
            print(s, layer, img.size, ncolors(img))
