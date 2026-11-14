"""Level 1 section 3: The Hoarder (#60, #51). Imported by build_level01.py.

Forward coordinates (u grows with play, mirrored on write by levelkit). Layout, u from the section start:
  96   checkpoint 3 (the respawn point for the whole fight)
  130..370  dynamite sticks on the floor and four Scatterers loafing in the garbage
  420  sealed door with a Spanish health notice: only a dynamite blast opens it
  452  arena lock A (behind the player once the fight starts), 880 lock B
  455..475  fight trigger just inside the door
  452..880  the round lair: garbage-pile cover and platforms, skull sconces, the Hoarder at 830
The lair is wired by scripts/level/hoarder_lair.gd (HoarderLair node), which finds the nodes below by name.
"""
from levelkit import vec

WIDTH = 896

RES = {
    "hoarder": "res://scenes/enemies/hoarder.tscn",
    "garbage_pile": "res://scenes/props/garbage_pile.tscn",
    "blast_door": "res://scenes/props/blast_door.tscn",
    "dynamite_pickup": "res://scenes/props/dynamite_pickup.tscn",
    "hoarder_lair": "res://scenes/level/hoarder_lair.tscn",
    "scatterer": "res://scenes/enemies/scatterer.tscn",
    "prop_skull_sconce": "res://scenes/props/skull_sconce.tscn",
}

DOOR_U = 420
LOCK_A_U = 452
LOCK_B_U = 880
START_U = (455, 475)
BOSS_U = 830
DOOR_HEIGHT = 140
SCATTERER_US = (170, 215, 290, 335)
DYNAMITE_US = (130, 250, 370)
# (u, width, height) solid piles in the lair: platforms and cover
LAIR_PILES = ((530, 44, 28), (610, 56, 36), (700, 44, 28), (770, 40, 32))
# backdrop piles: 15-foot heaps along the round wall and in the approach
BACKDROP = ((60, 70, 54), (200, 80, 46), (330, 90, 70), (478, 56, 100), (650, 110, 84), (872, 60, 110))
SCONCES = (470, 560, 760, 864)
HINT_TEXT = "A sealed door with a health notice. Dynamite opens it: G to throw, then stand back"

_state = {}


def build(kit, x0, floor, furnish):
    kit.flat(WIDTH)
    kit.cp(3, x0 + 96, 3)
    for u in SCATTERER_US:
        kit.add_enemy("hoarder_scatterer", x0 + u, floor)
    kit.hint("HintHoarderDoor", x0 + 300, x0 + 410, HINT_TEXT)
    kit.trig("HoarderStart", "arena", "", x0 + START_U[0], x0 + START_U[1], floor - 300, floor + 120)
    kit.walls.append({"name": "HoarderLockA", "x": x0 + LOCK_A_U, "y": floor - 250, "kind": "arena"})
    kit.walls.append({"name": "HoarderLockB", "x": x0 + LOCK_B_U, "y": floor - 250, "kind": "arena"})
    furnish(x0, x0 + WIDTH)
    for u in SCONCES:
        kit.add_prop("prop_skull_sconce", x0 + u, floor - 118, free=True)
    _state["x0"] = x0
    _state["floor"] = floor


def emit(kit, w):
    """Lair nodes. Called from write_tscn after the Doors node exists."""
    x0, floor = _state["x0"], _state["floor"]
    w.raw("Bosses", "Node2D", ".", [])
    w.inst("Hoarder", "Bosses", "hoarder", position=vec(kit.mx(x0 + BOSS_U), floor - 2))
    n = 0
    for e in kit.enemies:
        if e["kind"] != "hoarder_scatterer":
            continue
        n += 1
        w.inst("HoarderScatterer%d" % n, "Goblins", "scatterer", position=vec(kit.mx(e["x"]), e["y"] - 2))
    w.inst("HoarderDoor", "Doors", "blast_door", position=vec(kit.mx(x0 + DOOR_U), floor), size=vec(16, DOOR_HEIGHT))
    for i, u in enumerate(DYNAMITE_US):
        w.inst("Dynamite%d" % (i + 1), "Deco", "dynamite_pickup", position=vec(kit.mx(x0 + u), floor))
    for i, (u, pw, ph) in enumerate(LAIR_PILES):
        w.inst("LairPile%d" % (i + 1), "Platforms", "garbage_pile", position=vec(kit.mx(x0 + u), floor),
               width="%d.0" % pw, height="%d.0" % ph, seed_value=str(i + 1))
    for i, (u, pw, ph) in enumerate(BACKDROP):
        w.inst("PileBackdrop%d" % (i + 1), "Deco", "garbage_pile", position=vec(kit.mx(x0 + u), floor),
               width="%d.0" % pw, height="%d.0" % ph, solid="false", seed_value=str(i + 11))
    w.inst("HoarderLair", ".", "hoarder_lair")
