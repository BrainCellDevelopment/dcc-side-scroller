import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import *

O = OUTLINE
ICONS = {}
ORDER = []


def add(item_id, rows, pal):
    ORDER.append(item_id)
    rows = [r if r else "." * 16 for r in rows]
    ICONS[item_id] = (rows, pal)


def mirror(half):
    return [r + r[::-1] for r in half]


def poke(rows, pts):
    rows = [list(r) for r in rows]
    for x, y, ch in pts:
        rows[y][x] = ch
    return ["".join(r) for r in rows]


# ---- fireplace_poker
add("fireplace_poker", [
    "..........OOOO..",
    ".........OllssO.",
    "........OlOOOsdO",
    "........OsO..OdO",
    ".......OlsO..OOO",
    "......OlsO......",
    ".....OlsO.......",
    "....OlsO........",
    "...OlsO.........",
    "..OhsO..........",
    ".OhhdO..........",
    "OhhdO...........",
    "OhdO............",
    "OdO.............",
    "OOO.............",
    "................",
], {"O": O, "l": STEEL_L, "s": STEEL, "d": STEEL_D, "h": GREY_D})

# ---- toad_cudgel
add("toad_cudgel", [
    "................",
    "....OOOOO.......",
    "...OgGGgdOO.....",
    "..OgGwGGgdO.....",
    "..OGGGgGGdO.....",
    "..OgGGGwGdO.....",
    "...OdGGGdOO.....",
    "....OOdGdO......",
    ".....OGgdO......",
    "......OGdO......",
    "......OGgdO.....",
    ".......OGdO.....",
    ".......OGgdO....",
    "........OGdO....",
    "........OddO....",
    ".........OO.....",
], {"O": O, "G": (120, 110, 60, 255), "g": (150, 140, 80, 255), "d": (78, 70, 40, 255), "w": (96, 140, 70, 255)})

# ---- fingerless_gloves
add("fingerless_gloves", [""] + mirror([
    ".O.O.O..",
    "OsOsOsO.",
    "OsssssO.",
    "OdddddO.",
    "OgLgggO.",
    "OgLggdO.",
    "OgggggO.",
    "OgggggO.",
    "OgggggO.",
    "OdgggdO.",
    "OgggggO.",
    "OdddddO.",
    "OdddddO.",
    "OOOOOOO.",
]) + [""], {"O": O, "g": GREY, "L": (196, 196, 206, 255), "d": GREY_D, "s": SKIN})

# ---- toe_ring
add("toe_ring", [
    "................",
    "................",
    "......OOOO......",
    ".....OkwwkO.....",
    ".....OkwwkO.....",
    "......OOOO......",
    "....OOlssOO.....",
    "...OlO..OsdO....",
    "..OlO....OsdO...",
    "..OsO....OdsO...",
    "..OsO....OdsO...",
    "..OsdO..OdsO....",
    "...OsdOOdsO.....",
    "....OOsssOO.....",
    ".....OOOO.......",
    "................",
], {"O": O, "l": WHITE, "s": (200, 205, 215, 255), "d": (130, 135, 155, 255), "w": WHITE, "k": (30, 24, 40, 255)})

# ---- nightgaunt_cloak
add("nightgaunt_cloak", [
    "................",
    "......OOOO......",
    ".....OpppdO.....",
    "....OpOOOddO....",
    "....OpO..OdO....",
    "....OpOOOOdO....",
    "...OPpPPPddPO...",
    "..OPPpPPPPdPPO..",
    "..OPPPPpPPPdPO..",
    ".OPPpPPPPPdPPPO.",
    ".OPPPPPpPPPPdPO.",
    ".OPPPPPPPPPPPdO.",
    "OPPpPPPPPPPPPPdO",
    "OPPPPdPPPPPPdPPO",
    "OPOPPOPOPPOPOPPO",
    ".O.OO.O.OO.O.OO.",
], {"O": O, "P": (50, 34, 76, 255), "p": (84, 60, 120, 255), "d": (28, 18, 44, 255)})

# ---- trollskin_shirt
add("trollskin_shirt", [
    "................",
    "..OOO......OOO..",
    ".OgggOOOOOOgggO.",
    "OgGggOdOOdOgGggO",
    "OgGgdOOggOOdgGgO",
    "OgGdOgGGGgGOdGgO",
    ".OOOgGGdGGGgOOO.",
    "...OgGGdGGGgdO..",
    "...OgGGdRRGgdO..",
    "...OgGGdRRGgdO..",
    "...OgGGdGGGgdO..",
    "...OgGGdGGGgdO..",
    "...OGgGdGGGgdO..",
    "...OdGGdGGGddO..",
    "....OOOOOOOOO...",
    "................",
], {"O": O, "g": (130, 150, 120, 255), "G": (100, 120, 96, 255), "d": (62, 80, 66, 255), "R": RED})

# ---- spiked_kneepads
add("spiked_kneepads", ["", ""] + mirror([
    "..O..O..",
    "..l..l..",
    ".OsOOsO.",
    "OLggggdO",
    "OLggggdO",
    "OgggggdO",
    "ObbbbbbO",
    "OgggggdO",
    "OgggggdO",
    "OddddddO",
    ".OOOOOO.",
]) + ["", "", ""], {"O": O, "g": GREY, "L": (196, 196, 206, 255), "d": GREY_D, "b": BROWN, "s": STEEL, "l": STEEL_L})

# ---- war_gauntlet
add("war_gauntlet", [
    "................",
    "...O..O..O..O...",
    "..OaOOaOOaOOaO..",
    "..OOOOOOOOOOOOO.",
    "..OLsOLsOLsOLsO.",
    "..OLsOLsOLsOLsO.",
    "..OsdOsdOsdOsdO.",
    "..OOOOOOOOOOOOO.",
    "..OLsssssssssdO.",
    "..OLssssssssddO.",
    "..OOOOOOOOOOOOO.",
    ".OLssssssssssdO.",
    ".OLsDsssssssDdO.",
    ".OdddddddddddddO",
    ".OOOOOOOOOOOOOO.",
    "................",
], {"O": O, "L": STEEL_L, "s": STEEL, "d": STEEL_D, "D": (70, 90, 115, 255), "a": ORANGE})

# ---- lucky_boxers
add("lucky_boxers", [
    "................",
    "................",
    "..OOOOOOOOOOOO..",
    "..ObbbbbbbbbbO..",
    "..ObBbBbBbBbbO..",
    "..OOOOOOOOOOOO..",
    "..OwwwwwwwwwsO..",
    "..OwHwHwwwwwsO..",
    "..OwwHwwwHwHsO..",
    "..OwwwwwwwHwsO..",
    "..OwwwwOOwwwsO..",
    ".OwwwwwOOwwwwsO.",
    ".OwwwwwOOwwwwsO.",
    ".OOOOOOOOOOOOOO.",
    "................",
    "................",
], {"O": O, "w": WHITE, "s": (200, 205, 220, 255), "b": (210, 215, 235, 255), "B": (160, 170, 210, 255), "H": RED})

# ---- pedicure_kit
add("pedicure_kit", [
    "..............y.",
    ".............yYy",
    "..............y.",
    "..OOOOOOOOOOOO..",
    "..OppppppppppO..",
    "..OpPPPPPPPPpO..",
    ".OOOOOOOOOOOOOO.",
    ".OkkkkkkkkkkkkO.",
    ".OkOOOOOOkOOOkO.",
    ".OkOfffffOOssOkO"[:16],
    ".OkOOOOOOkOssOkO"[:16],
    ".OkkkkkkkkOOOkO.",
    ".OppppppppppppO."[:16],
    ".OOOOOOOOOOOOOO.",
    "................",
    "................",
], {"O": O, "p": (255, 170, 200, 255), "P": (255, 205, 225, 255), "k": (200, 90, 140, 255), "f": STEEL_L, "s": STEEL, "y": WHITE, "Y": GOLD_L})

# ---- shuriken_of_bloodlust
_q = [
    ".......O",
    "......Os",
    "......Os",
    ".....Ols",
    ".....Ols",
    "...OOOss",
    ".OOllsss",
    "Ossssssh",
]
_full = mirror(_q)
_full = _full + _full[::-1]
add("shuriken_of_bloodlust", poke(_full, [
    (7, 2, "R"), (7, 3, "R"), (8, 4, "R"), (6, 3, "R"),
    (2, 7, "R"), (3, 7, "R"), (3, 6, "R"),
    (13, 7, "R"), (12, 7, "R"), (13, 9, "R"),
    (8, 12, "R"), (7, 13, "R"),
]), {"O": O, "l": STEEL_L, "s": STEEL, "h": O, "R": RED})

# ---- sepsis_crown
add("sepsis_crown", [
    "................",
    "................",
    ".OPO..OPPO..OPO.",
    ".OgOOOOggOOOgO..",
    ".OgGOOOggGOOOgO.",
    ".OgggOkkkkOgggO.",
    ".OgggOkPPkOgggO.",
    ".OgggOkPkkOgggO.",
    ".OgGGOkkPkOGGgO.",
    ".OOOOOOOOOOOOOO.",
    "......OzzO......",
    "......OzZO......",
    "......OzzO......",
    ".......OzO......",
    ".......OO.......",
    "................",
], {"O": O, "P": PURPLE_L, "g": GOLD, "G": GOLD_D, "k": (30, 18, 44, 255), "z": (110, 190, 60, 255), "Z": (170, 230, 110, 255)})

# ---- fae_scale_crupper
add("fae_scale_crupper", [
    "................",
    "....OOOOOOOO....",
    "....OLssssdO....".replace("....OLssssdO....", "....OLsssssdO..."),
    "....OOOOOOOO....",
    "...OBbBbBbBbO...",
    "...ObBbBbBbBO...",
    "..OBbBsOBbBbBO..",
    "..ObBbOkkOBbBO..",
    ".OBbBsOkkOsbBbO.",
    ".ObBbBbOOBbBbBO.",
    "OBbBbBbBbBbBbBbO",
    "OsLsLsLsLsLsLsdO",
    ".OOOOOOOOOOOOOO.",
    "................",
    "................",
    "................",
], {"O": O, "L": WHITE, "s": (200, 205, 215, 255), "d": (130, 135, 155, 255), "B": (170, 215, 245, 255), "b": (120, 170, 225, 255), "k": (30, 24, 40, 255)})

# ---- slate_butterfly_talisman
_b = [
    "...c....",
    "....c...",
    ".....c..",
    "......c.",
    ".OO...OD",
    "OLsOOOsD",
    "OLsssssD",
    "OsssSssD",
    ".OsssSsD",
    "..OOssdD",
    "..OsddOD",
    "...OOO.D",
    "......OB",
    ".....OBb",
    "......OO",
    "........",
]
add("slate_butterfly_talisman", mirror(_b), {"O": O, "c": BROWN, "L": (170, 176, 188, 255), "s": (118, 126, 142, 255), "S": (84, 90, 106, 255), "d": (60, 64, 80, 255), "D": (40, 40, 52, 255), "B": BLUE_L, "b": BLUE})

# ---- bandages
add("bandages", [
    "................",
    "....OOOOOO......",
    "..OOCCCCCCOO....",
    ".OCCCCCCCCCdO...",
    ".OCCOOOOOCCCdO..",
    ".OCOCCCCCOCCdO..",
    ".OCOCOOOCOCCdO..",
    ".OCOCCCCCOCdO...",
    ".OCCOOOOOCCdO...",
    "..OdCCCCCCdOOOOO",
    "...OOddddOCCCsCO",
    ".....OOOOCCsCCCO"[:16],
    ".......OOCCCCOOO",
    "........OCsCCO..",
    ".........OOOO...",
    "................",
], {"O": O, "C": CREAM, "d": (205, 185, 140, 255), "s": (170, 80, 64, 255)})

# ---- knuckle_wraps
add("knuckle_wraps", [
    "...O..O..O..O...",
    "...l..l..l..l...",
    "..OsOOsOOsOOsO..",
    "..OWWWWWWWWWWO..",
    "..OWbWbWbWbWWO..",
    "..OWWbWbWbWbWO..",
    "..OWbWbWbWbWWO..",
    "..OWWWWWWWWWdO..",
    "...OWWWWWWWdO...",
    "...OWbbbbbWdO...",
    "...OWWWWWWWdO...",
    "...OWbbbbbWdO...",
    "...OWWWWWWWdO...",
    "...OdddddddO....",
    "....OOOOOOO.....",
    "................",
], {"O": O, "W": (225, 205, 165, 255), "b": (150, 105, 80, 255), "d": (176, 150, 112, 255), "s": STEEL, "l": STEEL_L})

if __name__ == "__main__":
    for k in ORDER:
        rows, pal = ICONS[k]
        save(k, rows, pal)
    sheet(ORDER, os.path.join(os.path.dirname(os.path.abspath(__file__)), "_preview_a.png"))
