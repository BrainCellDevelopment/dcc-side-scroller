"""Floor 1 palette sheet (single source of truth, mirrored in docs/floor-1-plan.md).

Four families: brick red, lichen green, torch orange, bone white, plus neutrals
(wet stone, plank, iron). Later neighborhoods (workshop, garbage, rave dome) add
accents on top of these; they never replace them.

Run `python3 palette.py <out.png>` to render the sheet.
"""


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


# dark -> light ramps
BRICK = ["#1a0a10", "#2e1218", "#4a1c20", "#6b2b2a", "#8f4034", "#b85c42"]
LICHEN = ["#0e2620", "#1c523a", "#3a9448", "#86dc68", "#c8f5a0"]
TORCH = ["#6e1f1c", "#c8481e", "#f5882a", "#ffc45a", "#fff0b0"]
BONE = ["#4a3838", "#8a7866", "#c8b692", "#eee2c0", "#fffaf0"]
WET = ["#141c20", "#22323a", "#3a5256", "#5f8280", "#9ac0b8"]
PLANK = ["#1e120e", "#3a2218", "#5a3622", "#80502e", "#aa7640"]
IRON = ["#161218", "#2e2a36", "#4e4a5c", "#7c7888", "#aeaab8"]
OUTLINE = "#0c0508"

SHEET = {
    "brick red": BRICK,
    "lichen green": LICHEN,
    "torch orange": TORCH,
    "bone white": BONE,
    "wet stone": WET,
    "plank": PLANK,
    "iron": IRON,
}

# Neighborhood accents (use only inside their neighborhood)
ACCENTS = {
    "garbage (Hoarder)": ["#3a2c1a", "#5e4a28", "#8a7440"],
    "workshop (steam, coal)": ["#1c1a1c", "#6a6e74", "#d8dce0"],
    "rave dome (black light)": ["#1a0a3a", "#6a2ad0", "#d070ff"],
}


def rgb(ramp):
    return [hx(c) for c in ramp]


if __name__ == "__main__":
    import sys
    from PIL import Image, ImageDraw
    rows = list(SHEET.items()) + list(ACCENTS.items())
    sw = 40
    img = Image.new("RGB", (sw * 6 + 170, len(rows) * sw), (12, 8, 10))
    d = ImageDraw.Draw(img)
    for r, (name, ramp) in enumerate(rows):
        d.text((6, r * sw + sw // 2 - 5), name, fill=(220, 210, 200))
        for i, c in enumerate(ramp):
            d.rectangle([170 + i * sw, r * sw + 4, 170 + (i + 1) * sw - 4, r * sw + sw - 4], fill=hx(c))
    img.save(sys.argv[1])
