import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit
from kit import OUTLINE, WHITE, STEEL, STEEL_L, STEEL_D, WOOD, WOOD_D, RED, RED_L, RED_D
from kit import GOLD, GOLD_L, GOLD_D, GREEN, GREEN_D, BLUE, BLUE_L, BLUE_D, ORANGE, BROWN
from kit import GREY, GREY_D, CREAM, save, sheet

O = OUTLINE


def rgb(r, g, b, a=255):
    return (r, g, b, a)


def ln(x0, inner):
    """x0 dots, outline, inner, outline; padded to 16."""
    s = "." * x0 + "o" + inner + "o"
    assert len(s) <= 16, (s, len(s))
    return s.ljust(16, ".")


def pad(s):
    assert len(s) <= 16, (s, len(s))
    return s.ljust(16, ".")


def grid():
    return [["."] * 16 for _ in range(16)]


def art(g, x, y, lines):
    for dy, l in enumerate(lines):
        for dx, ch in enumerate(l):
            if ch != ".":
                g[y + dy][x + dx] = ch


def fin(g):
    return ["".join(r) for r in g]


ids = []


def out(item, rows, pal):
    p = dict(pal)
    p["o"] = O
    save(item, rows, p)
    ids.append(item)


# ---------------------------------------------------------------- dynamite
out("dynamite", [
    pad(".........y"),
    pad("........yYy"),
    pad(".........o"),
    pad("........o"),
    pad(".ooooooooooooo"),
    pad(".oRreoRreoRreo"),
    pad(".oRreoRreoRreo"),
    pad(".oRreoRreoRreo"),
    pad(".oyyyyyyyyyyyo"),
    pad(".ogggggggggggo"),
    pad(".oRreoRreoRreo"),
    pad(".oRreoRreoRreo"),
    pad(".oRreoRreoRreo"),
    pad(".oRreoRreoRreo"),
    pad(".ooooooooooooo"),
    pad(""),
], {"y": GOLD, "Y": GOLD_L, "R": RED_L, "r": RED, "e": RED_D, "g": GOLD_D})

# ---------------------------------------------------------------- lighter
out("lighter", [
    pad("........o"),
    pad(".......oOo"),
    pad(".......oOo"),
    pad("......oOYOo"),
    pad("......oOYOo"),
    pad("......oOYOo"),
    pad(".......ooo"),
    pad("....oooooooo"),
    pad("....oSSsssdo"),
    pad("....oooooooo"),
    pad("....oSssssdo"),
    pad("....oSsyysdo"),
    pad("....oSssssdo"),
    pad("....oSssssdo"),
    pad("....oooooooo"),
    pad(""),
], {"S": STEEL_L, "s": STEEL, "d": STEEL_D, "O": ORANGE, "Y": rgb(255, 230, 110), "y": GOLD})

# ---------------------------------------------------------------- goblin_smoke_bomb
out("goblin_smoke_bomb", [
    pad("....ooo"),
    pad("..ooWWWoo...Y"),
    pad(".oWWWLWWWo.yYy"),
    pad(".oWWWWWWWWo.k"),
    pad("..oooooooo.k"),
    pad("..........k"),
    pad(".....oooooo"),
    pad("....oLLMMMMo"),
    pad("...oLLMMMMMMo"),
    pad("..oLMMMMMMMMDo"),
    pad("..oLMMMMMMMMDo"),
    pad("..oMMMMMMMMMDo"),
    pad("..oMMMMMMMMDDo"),
    pad("...oMMMMMMDDo"),
    pad("....oDDDDDDo"),
    pad(".....oooooo"),
], {"W": rgb(225, 228, 236), "L": rgb(140, 142, 160), "M": rgb(86, 88, 104),
    "D": rgb(52, 52, 68), "k": BROWN, "y": GOLD, "Y": GOLD_L})
# smoke uses W; bomb highlights use L; keep L distinct on the smoke too
# (fix: smoke highlight pixel 'L' is the same grey as the bomb highlight, fine)

# ---------------------------------------------------------------- hobgoblin_pus
out("hobgoblin_pus", [
    pad("..........Y"),
    pad(".........r"),
    pad(".........r"),
    pad("........r"),
    pad(".....oooooo"),
    pad("....oPPpppqo"),
    pad("...oPPpppppqo"),
    pad("..oPppppppppqo"),
    pad("..oooooooooooo"),
    pad("..oSSSSSSSSsdo"),
    pad("...osssssssdo"),
    pad("...oyyyyyyyyo"),
    pad("...oyyyyyyyyo"),
    pad("...osssssssdo"),
    pad("...osssssssdo"),
    pad("...oooooooooo"),
], {"P": rgb(222, 230, 168), "p": rgb(190, 205, 130), "q": rgb(140, 170, 100),
    "S": STEEL_L, "s": STEEL, "d": STEEL_D, "y": GOLD, "r": RED, "Y": GOLD_L})

# ---------------------------------------------------------------- detonator_trigger
out("detonator_trigger", [
    pad("......b....r"),
    pad(".......b..r"),
    pad(".......b.r"),
    pad("...oo.ooo.ooo"),
    pad("...oWWoWWWWvo"),
    pad("...oWWWWWWWvo"),
    pad("...oWWWWWWWvo"),
    pad("...oWWWWWWWvo"),
    pad("...oWWooooWvo"),
    pad("...oWWoRrovvo"),
    pad("...oWWoreovvo"),
    pad("...oWWooooWvo"),
    pad("...oWWWWWWWvo"),
    pad("...oWWWWWWvvo"),
    pad("...oooooooooo"),
    pad(""),
], {"W": WHITE, "v": rgb(190, 200, 220), "R": RED_L, "r": RED, "e": RED_D,
    "b": BLUE, "x": GOLD})

# ---------------------------------------------------------------- proximity_trigger
out("proximity_trigger", [
    pad(""),
    pad(".....oooooo"),
    pad("...ooGGGGGGoo"),
    pad("..oLLGGGGGGGGo"),
    pad("..oLGttttGGGDo"),
    pad("..oGGtooooGGDo"),
    pad("..oGtGoRroGGDo"),
    pad("..oGGGorroGtGDo"),
    pad("..oGGtooooGGDo"),
    pad("..oGGGGGGtttDo"),
    pad("..oGGGGGGGGDDo"),
    pad("...ooDDDDDDoo"),
    pad(".....oooooo"),
    pad("....oSo..oSo"),
    pad("....oSo..oSo"),
    pad("....ooo..ooo"),
], {"G": rgb(60, 150, 90), "L": rgb(110, 200, 130), "D": rgb(30, 90, 60), "t": rgb(150, 230, 150),
    "R": RED_L, "r": RED, "e": RED_D, "S": STEEL_L})

# ---------------------------------------------------------------- goo_inator_3000
out("goo_inator_3000", [
    pad(""),
    pad(""),
    pad(".....oooooo"),
    pad(".....oLGGDo"),
    pad(".....oLGGDo"),
    pad("...oooooooooooo"),
    pad("...oYYOOOOOOOeo"),
    pad("ooooYOOOOOOOOeo"),
    pad("oSSsOOOOOOOOOeo"),
    pad("oSsdOOOOOOOOeeo"),
    pad("ooooooooooooooo"),
    pad(".oGo....oeeo"),
    pad(".oGo....oeeo"),
    pad("oGLGo....oeeo"),
    pad("oGGGo....oeeo"),
    pad(".ooo.....oooo"),
], {"L": rgb(150, 235, 110), "G": rgb(80, 190, 70), "D": GREEN_D, "Y": rgb(255, 190, 90),
     "O": ORANGE, "e": rgb(170, 90, 30), "S": STEEL_L, "s": STEEL, "d": STEEL_D})

# ---------------------------------------------------------------- gorgon_marital_aid
out("gorgon_marital_aid", [
    pad("....oooooooo"),
    pad("...oSSSSSSsdo"),
    pad("...oSdSSdSsdo"),
    pad("...oSdSSdSsdo"),
    pad("...oSdSSdSsdo"),
    pad("...oSdSSdSsdo"),
    pad("...oSSSSSSsdo"),
    pad("....oSSSSsdo"),
    pad("......oSdo"),
    pad("......oSdo"),
    pad(".....oyyyyo"),
    pad(".....oLGLGo"),
    pad(".....oGDGDo"),
    pad(".....oLGLGo"),
    pad(".....oGDGDo"),
    pad("......oooo"),
], {"S": STEEL_L, "s": STEEL, "d": STEEL_D, "y": GOLD, "L": rgb(140, 225, 110),
    "G": GREEN, "D": GREEN_D})

# ---------------------------------------------------------------- workbench_kit
out("workbench_kit", [
    pad(""),
    pad("..........oooooo"),
    pad("..........oSSsdo"),
    pad("..........oSSsdo"),
    pad(".oooooo...oooooo"),
    pad(".oSSsdo....oko"),
    pad(".oSddso....oko"),
    pad("oooooooooooooooo"),
    pad("oWWWWWWWWWWWWWWo"),
    pad("oYYYYYYYYYYYYYYo"),
    pad("oooooooooooooooo"),
    pad("..okKo......oKko"),
    pad("..okKo......oKko"),
    pad("..okKooooooooKko"),
    pad("..okKo......oKko"),
    pad("..oooo......oooo"),
], {"S": STEEL_L, "s": STEEL, "d": STEEL_D, "W": rgb(216, 156, 100), "Y": WOOD,
    "k": WOOD, "K": WOOD_D})

# ---------------------------------------------------------------- jug_o_boom
out("jug_o_boom", [
    pad("........o"),
    pad(".......oOo"),
    pad("......oOYOo"),
    pad("......oOYOo"),
    pad("......oWWo"),
    ln(5, "CcDD"),
    ln(6, "CD"),
    ln(4, "CCcccD"),
    ln(3, "CCcccccD"),
    ln(2, "CCcccccccccD"),
    ln(2, "CCcxccxcccDD"),
    ln(2, "CCccxxccccDD"),
    ln(2, "CCcxccxcccDD"),
    ln(2, "CccccccccDDD"),
    ln(3, "CcccccDD"),
    "....oooooooo....",
], {"C": rgb(232, 152, 96), "c": rgb(196, 112, 62), "D": rgb(138, 76, 46), "x": rgb(60, 34, 28),
    "W": CREAM, "O": ORANGE, "Y": rgb(255, 230, 110)})

# ---------------------------------------------------------------- goblin_pass
g = grid()
for y in range(16):
    for x in range(16):
        d = math.hypot(x - 7.5, y - 7.5)
        if 7 < d <= 8:
            g[y][x] = "q"
        elif 6 < d <= 7:
            g[y][x] = "o"
        elif 5 < d <= 6:
            g[y][x] = "y"
        elif d <= 5:
            g[y][x] = "K"
# clean skull overlay (rows 4-10)
g2 = grid()
for y in range(16):
    for x in range(16):
        g2[y][x] = g[y][x]
# restore ring/background then paint the skull properly
for y in range(16):
    for x in range(16):
        d = math.hypot(x - 7.5, y - 7.5)
        if 7 < d <= 8:
            g2[y][x] = "q"
        elif 6 < d <= 7:
            g2[y][x] = "o"
        elif 5 < d <= 6:
            g2[y][x] = "y"
        elif d <= 5:
            g2[y][x] = "K"
        else:
            g2[y][x] = "."
art(g2, 0, 4, [
    "...L.LLLLLL.L...",
    "...LLLLLLLLLL...",
    "....LooLLooL....",
    "....LooLLooL....",
    "....LLLooLLL....",
    ".....LLLLLL.....",
    ".....LoLLoL.....",
])
out("goblin_pass", fin(g2), {"q": rgb(255, 214, 80, 170), "y": GOLD, "K": rgb(22, 44, 38),
                              "L": rgb(176, 232, 132)})

# ---------------------------------------------------------------- desperado_pass
g = grid()
for y in range(3, 13):
    for x in range(1, 15):
        edge = y in (3, 12) or x in (1, 14)
        g[y][x] = "o" if edge else "D"
for y in (7, 8):
    g[y][1] = "."
    g[y][14] = "."
    g[y][2] = "o"
    g[y][13] = "o"
for y in range(4, 12, 2):
    g[y][11] = "W"
for y in (5, 6, 9, 10):
    g[y][12] = "P"
    g[y][13] = "P" if y in (5, 9) else "D"
art(g, 0, 0, [
    "................",
    "................",
    "................",
    "................",
    "................",
    "........PQ......",
    ".......PQ.......",
    "......PQ........",
    ".....PQ.........",
    "....WWp.........",
    "...pp...........",
    "..p.............",
])
out("desperado_pass", fin(g), {"D": rgb(46, 24, 72), "W": rgb(240, 240, 255), "P": rgb(255, 70, 200),
                                "Q": rgb(255, 190, 240), "p": rgb(190, 30, 140)})

# ---------------------------------------------------------------- goblin_copper_chopper
g = grid()
art(g, 0, 0, [
    "..........ww....",
    ".........wWWw...",
    "..........oooo..",
    ".....oooo.oCDo..",
    ".....okko.oCDo..",
    ".....okko.oCDooo",
    ".....oooooooooo.",
    ".....oCCcycDDo o".replace(" ", ""),
    ".....oCcccccDDoo",
    ".....occcccDDoo.",
    ".....ooooooooo..",
])
wheel = [
    ".ooo.",
    "oSSSo",
    "oSdSo",
    "oSSSo",
    ".ooo.",
]
art(g, 5, 11, wheel)
art(g, 11, 11, wheel)
art(g, 0, 8, [
    ".ooo.",
    "oCCco",
    "occDo",
    "oDDDo",
    ".ooo.",
])
art(g, 1, 13, [
    ".ooo",
    "oSdo",
    ".ooo",
])
for y in range(7, 11):
    g[y][14] = "o"
out("goblin_copper_chopper", fin(g), {"w": rgb(200, 205, 220), "W": rgb(236, 238, 248), "C": rgb(240, 160, 100),
    "c": rgb(196, 106, 58), "D": rgb(132, 66, 44), "k": rgb(60, 54, 66), "y": GOLD,
    "S": rgb(170, 175, 190), "d": rgb(90, 90, 104)})

# ---------------------------------------------------------------- neighborhood_map
g = grid()
for y in range(2, 14):
    for x in range(1, 15):
        edge = y in (2, 13) or x in (1, 14)
        if edge:
            g[y][x] = "o"
        else:
            g[y][x] = "q" if x in (5, 9) else "P"
for y in range(3, 7):
    g[y][2] = "L"
for (x, y) in [(3, 11), (4, 10), (6, 10), (7, 9), (8, 8), (9, 8), (10, 7)]:
    g[y][x] = "d"
for (x, y) in [(11, 4), (13, 4), (12, 5), (11, 6), (13, 6)]:
    g[y][x] = "r"
g[4][3] = "t"
g[3][4] = "t"
g[4][4] = "t"
g[11][12] = "t"
out("neighborhood_map", fin(g), {"P": rgb(240, 222, 168), "q": rgb(206, 176, 118), "L": rgb(255, 242, 200),
                                  "d": BROWN, "r": RED, "t": GREEN})

# ---------------------------------------------------------------- books
def book(cover, light, dark, extra_fn, pages=False, gold=True):
    g = grid()
    for y in range(1, 15):
        for x in range(2, 14):
            g[y][x] = "o"
    for y in range(2, 14):
        for x in range(3, 13):
            g[y][x] = "C"
    for x in range(3, 13):
        g[2][x] = "L"
        g[13][x] = "D"
    for y in range(2, 14):
        g[y][3] = "D"
        g[y][4] = "D"
        g[y][5] = "d"
    if gold:
        for y in (3, 11):
            g[y][3] = "y"
            g[y][4] = "y"
        g[2][12] = "y"
        g[13][12] = "y"
    if pages:
        for x in range(4, 13):
            g[13][x] = "P"
        for y in range(2, 13):
            g[y][12] = "r"
        for x in range(3, 5):
            g[13][x] = "D"
    extra_fn(g)
    return fin(g), {"C": cover, "L": light, "D": dark, "d": tuple(int(c * 0.7) for c in dark[:3]) + (255,),
                    "y": GOLD, "P": CREAM, "r": RED}


def sym_missile(g):
    art(g, 6, 4, [
        "...Y...",
        "..YWY..",
        ".YWWWY.",
        "..YWY..",
        "...Y...",
        "..B....",
        ".B.....",
        "B......",
    ])


def sym_wisp(g):
    art(g, 6, 4, [
        "..WWWW.",
        ".W....W",
        ".W.WW.W",
        ".W..W.W",
        "..W.W.W",
        "...WW.W",
        "......W",
        ".....W.",
    ])


def sym_minions(g):
    sk = ["WWW", "oWo", ".W."]
    art(g, 6, 4, sk)
    art(g, 10, 4, sk)
    art(g, 8, 8, sk)


def sym_puddle(g):
    art(g, 6, 4, [
        "...W...",
        "...W...",
        "..WWW..",
        ".W...W.",
        "W..W..W",
        ".W...W.",
        "..WWW..",
    ])


def sym_hand(g):
    art(g, 6, 4, [
        ".W.W.W.",
        ".W.W.W.",
        ".WWWWW.",
        "WWWWWWW",
        ".WWWWW.",
        "..WWW..",
        "..W.W..",
        "..W.W..",
    ])


def sym_fieldguide(g):
    art(g, 7, 3, [
        ".WWW.",
        "WWWWW",
        "WoWoW",
        ".WWW.",
        ".WoW.",
    ])
    art(g, 6, 8, [
        ".mm.",
        "mBBm",
        "mBBm",
        ".mm.",
        "....k",
        ".....k",
    ])


rows, pal = book(rgb(70, 140, 200), rgb(130, 190, 250), rgb(36, 66, 140), sym_missile)
pal.update({"Y": rgb(255, 236, 130), "W": WHITE, "B": rgb(170, 220, 255)})
out("tome_magic_missile", rows, pal)

rows, pal = book(rgb(150, 170, 196), rgb(205, 220, 238), rgb(96, 112, 140), sym_wisp)
pal.update({"W": WHITE})
out("tome_wisp_armor", rows, pal)

rows, pal = book(rgb(140, 30, 44), rgb(200, 70, 80), rgb(80, 14, 30), sym_minions)
pal.update({"W": rgb(245, 240, 225)})
out("tome_minion_army", rows, pal)

rows, pal = book(rgb(36, 160, 156), rgb(110, 220, 210), rgb(18, 90, 100), sym_puddle)
pal.update({"W": rgb(230, 255, 250)})
out("tome_puddle_jumper", rows, pal)

rows, pal = book(rgb(26, 58, 44), rgb(52, 104, 76), rgb(12, 28, 24), sym_hand)
pal.update({"W": rgb(226, 220, 190)})
out("tome_second_chance", rows, pal)

rows, pal = book(rgb(86, 168, 76), rgb(150, 220, 120), rgb(44, 110, 60), sym_fieldguide, pages=True, gold=False)
pal.update({"W": WHITE, "m": O, "B": rgb(150, 210, 255), "k": WOOD_D})
out("borough_field_guide", rows, pal)

if __name__ == "__main__":
    sheet(ids, os.path.join(os.path.dirname(os.path.abspath(__file__)), "_preview_c.png"), scale=8, cols=5)
