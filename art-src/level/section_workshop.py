"""Level 1 section 4: the goblin workshop (#61). Imported by build_level01.py.

Forward coordinates (u grows with play, mirrored on write by levelkit). Layout, u from the section start:
  96        checkpoint
  0..220    yard: coal heap, conveyor, pineapple crates, two grunts, funpowder barrels at 200 and 212
  256       steam vent A
  304..400  parked dozer 1, a Bomb Bard on its cab roof (u 352..400)
  424       grunt in the gap, barrel at 416
  448..544  parked dozer 2, a Bomb Bard on its cab roof (u 496..544)
  560       steam vent B
  612       grunt
  640..660  funpowder barrels, then the boiler at 680 and the Shamanka at 712 behind the steam engine

Violence: fight up the hall. Dynamite: throw it at the barrels and boiler for a chain blast that takes the grunt
and the Shamanka with it. Charm: Donut charms the Shamanka, who hands over a Goblin Pass, and the plain goblins
(and her bards) stop hating Carl on sight.
Cut from the issue: Scat Thug spear raccoons and the Rory and Lorelai trade scene (sets up #69).
"""
from levelkit import vec, qstr, fnum

WIDTH = 768
PLANK = 6

RES = {
    "workshop_prop": "res://scenes/props/workshop_prop.tscn",
    "steam_vent": "res://scenes/level/steam_vent.tscn",
    "workshop_site": "res://scenes/level/workshop_site.tscn",
}

GRUNT_XS = (190, 232, 424, 612)
BARDS = ((376, 80), (520, 80))
SHAMANKA_X = 712
BARDS_LEVEL = 5
SHAMANKA_LEVEL = 7
SHAMANKA_GIFT = ""
DOZERS = (304, 448)
VENTS = ((256, 0.0), (560, 1.6))
BARRELS = (200, 212, 416, 640, 652)
BOILER_X = 680

_props = []


def _prop(kind, x, y, width=None, free=True):
    _props.append({"kind": kind, "x": x, "y": y, "w": width})


def build(kit, x0, floor, furnish):
    kit.flat(WIDTH)
    kit.cp(4, x0 + 96, 4)

    for u in GRUNT_XS:
        kit.grunt(x0 + u)
    for u, up in BARDS:
        kit.add_enemy("bard", x0 + u, floor - up)
    kit.add_enemy("shamanka", x0 + SHAMANKA_X, floor)

    for u in DOZERS:
        kit.block(x0 + u, 96, 32, style=PLANK)["hide"] = True
        kit.add_plat(x0 + u + 48, floor - 80, 48, 16, PLANK, kind="upper", one_way=True)["hide"] = True
        _prop("dozer", x0 + u, floor, 96)

    for u, ph in VENTS:
        kit.add_enemy("vent", x0 + u, floor, phase=ph)

    _prop("coal", x0 + 8, floor, 120)
    _prop("conveyor", x0 + 64, floor, 120)
    _prop("engine", x0 + 640, floor, 96)
    for u in (24, 140, 172, 300, 404, 596, 732):
        _prop("pineapples", x0 + u, floor)
    for u in BARRELS:
        _prop("barrel", x0 + u, floor)
    _prop("boiler", x0 + BOILER_X, floor)
    _prop("pipe", x0 + 192, floor - 120, 160)
    _prop("pipe", x0 + 560, floor - 140, 200)

    furnish(x0, x0 + WIDTH)


def emit(kit, w):
    """Bomb Bards, Shamanka, steam vents and the dressing. Called from write_tscn after Hazards and Goblins exist."""
    bi = 0
    for e in kit.enemies:
        k = e["kind"]
        pos = vec(kit.mx(e["x"]), e["y"] - 2)
        if k == "bard":
            bi += 1
            w.inst("Bard%02d" % bi, "Goblins", "goblin", position=pos, variant="2", enemy_level=str(BARDS_LEVEL))
        elif k == "shamanka":
            w.inst("Shamanka01", "Goblins", "goblin", position=pos, variant="3", enemy_level=str(SHAMANKA_LEVEL),
                   charm_gift=qstr(SHAMANKA_GIFT))
        elif k == "vent":
            w.inst("Vent%d" % int(e["x"]), "Hazards", "steam_vent", position=vec(kit.mspan(e["x"], 32), e["y"]),
                   phase=fnum(e["phase"]))
    for i, p in enumerate(_props):
        width = p["w"] or 24
        props = {"position": vec(kit.mspan(p["x"], width) if p["w"] else kit.mx(p["x"]), p["y"]), "kind": qstr(p["kind"])}
        if p["w"]:
            props["width"] = fnum(p["w"]) + ".0"
        w.inst("Work%02d" % i, "Deco", "workshop_prop", **props)
    # first step into the hall counts as finding the workshop
    x_mid = kit.mx(kit.sections[4]["x0"] + 96)
    w.inst("WorkshopSite", ".", "workshop_site", position=vec(x_mid, 184))
