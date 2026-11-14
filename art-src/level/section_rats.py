"""Level 1 section 1: The Rats' Corridor (#58, #56). Imported by build_level01.py.

Forward coordinates (u grows with play, mirrored on write by levelkit). Layout, u from the section start:
  96   checkpoint
  190  bathroom door (empty closet, a quiet breather)
  300..444  five level-2 rats (the pack)
  560  bathroom door (empty closet)
  600..720  Scatterers on the straight, then a step block and a raised ledge that ends in a wall:
  752..928  the optional dead end, a bathroom door with a hidden small item on the ledge
  840, 880  two more Scatterers loafing under the ledge
"""
from levelkit import vec, qstr

WIDTH = 960
BRICK = 4

RES = {
    "rat": "res://scenes/enemies/rat.tscn",
    "scatterer": "res://scenes/enemies/scatterer.tscn",
    "bathroom_door": "res://scenes/props/bathroom_door.tscn",
    "prop_lichen_floor": "res://scenes/props/lichen_floor.tscn",
    "prop_lichen_wall": "res://scenes/props/lichen_wall.tscn",
    "prop_grate": "res://scenes/props/grate.tscn",
    "prop_pipe_h": "res://scenes/props/pipe_h.tscn",
    "prop_skull_sconce": "res://scenes/props/skull_sconce.tscn",
}

RAT_XS = (300, 336, 372, 408, 444)
SCATTERER_XS = (600, 640, 680, 720, 840, 880)
HIDDEN_ITEM = ("soap_travel", "Travel-Size Soap")

_doors = []


def build(kit, x0, floor, furnish):
    kit.flat(WIDTH, style=BRICK)
    kit.cp(1, x0 + 96, 1)

    for u in RAT_XS:
        kit.add_enemy("rat", x0 + u, floor)
    for u in SCATTERER_XS:
        kit.add_enemy("scatterer", x0 + u, floor)

    # Optional dead end: step block up, a one-way ledge, a wall behind the door.
    kit.block(x0 + 752, 48, 48, style=BRICK)
    kit.add_plat(x0 + 752, floor - 96, 176, 16, BRICK, kind="upper", one_way=True)
    kit.add_plat(x0 + 928, floor - 176, 16, 96, BRICK, kind="deco")

    _doors.clear()
    _doors.append({"name": "LooA", "x": x0 + 190, "y": floor, "item": None})
    _doors.append({"name": "LooB", "x": x0 + 560, "y": floor, "item": None})
    _doors.append({"name": "LooDeadEnd", "x": x0 + 896, "y": floor - 96, "item": HIDDEN_ITEM})

    furnish(x0, x0 + WIDTH)
    for u in (60, 250, 470, 640, 780):
        kit.add_prop("prop_lichen_floor", x0 + u, floor)
    for u in (150, 330, 520, 700, 940):
        kit.add_prop("prop_lichen_wall", x0 + u, floor)
    for u in (240, 480, 620):
        kit.add_prop("prop_grate", x0 + u, floor - 56)
    for u in (200, 540, 830):
        kit.add_prop("prop_pipe_h", x0 + u, floor - 132)
    kit.add_prop("prop_skull_sconce", x0 + 868, floor - 150)


def emit(kit, w):
    """Rats, Scatterers and the bathroom doors. Called from write_tscn after the Doors node exists."""
    counts = {"rat": 0, "scatterer": 0}
    for e in kit.enemies:
        k = e["kind"]
        if k not in counts:
            continue
        counts[k] += 1
        w.inst("%s%02d" % (k.capitalize(), counts[k]), "Goblins", k, position=vec(kit.mx(e["x"]), e["y"] - 2))
    for d in _doors:
        props = {"position": vec(kit.mx(d["x"]), d["y"])}
        if d["item"]:
            props["hidden_item_id"] = qstr(d["item"][0])
            props["hidden_item_name"] = qstr(d["item"][1])
        w.inst(d["name"], "Doors", "bathroom_door", **props)
