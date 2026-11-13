import os
from PIL import Image
from pxl import *
import carl

FW, FH = 64, 56
OUTDIR = os.environ.get("DCC_ASSETS", "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/assets/characters")
PV = os.environ.get("DCC_PREVIEW", os.path.join(os.path.dirname(os.path.abspath(__file__)), "_pv"))

D_IDLE = [dict(tail="up", eyes="open"), dict(tail="swish_l", eyes="open"), dict(tail="up", eyes="blink", ears="side"), dict(tail="swish_r", eyes="open")]
D_RUN = [dict(tail="back", ears="side") for _ in range(6)]
D_RUN[1]["tail"] = "low"; D_RUN[4]["tail"] = "low"
D_JUMP = [dict(tail="up", ears="side", eyes="wide")]
D_FALL = [dict(tail="swish_l", ears="flat", eyes="wide")]
D_PUNCH = [dict(tail="up", ears="side"), dict(tail="back", ears="flat", eyes="squeeze"), dict(tail="back", ears="flat", eyes="squeeze"), dict(tail="low", ears="side")]
D_HURT = [dict(tail="swish_r", ears="flat", eyes="squeeze")]
D_DIE = [dict(tail="swish_r", ears="flat", eyes="wide"),
         dict(tail="down", ears="flat", eyes="wide"),
         dict(tail="up", ears="side", eyes="wide"),
         dict(tail="up", ears="side", eyes="blink")]
D_ROWS = [D_IDLE, D_RUN, D_JUMP, D_FALL, D_PUNCH, D_HURT, D_DIE]


def build():
    crow = []
    for r, dr in zip(carl.CARL_ROWS, D_ROWS):
        crow.append([carl.build_carl(p, d)[0] for p, d in zip(r, dr)])
    cs = sheet(crow, FW, FH, 6)
    ds = Image.new("RGBA", cs.size, (0, 0, 0, 0))
    return cs, ds


if __name__ == "__main__":
    cs, ds = build()
    os.makedirs(OUTDIR, exist_ok=True)
    os.makedirs(PV, exist_ok=True)
    cs.save(os.path.join(OUTDIR, "carl.png"))
    ds.save(os.path.join(OUTDIR, "donut.png"))
    preview(cs, os.path.join(PV, "carl.png"), 6, fw=FW, fh=FH)
    print(cs.size, count_colors(cs))
