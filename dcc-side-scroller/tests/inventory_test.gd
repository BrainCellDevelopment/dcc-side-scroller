extends SceneTree

var _fails: int = 0


func _check(ok: bool, label: String) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1


func _initialize() -> void:
	await process_frame
	var inv: Node = root.get_node("Inventory")
	var stats: Node = root.get_node("PlayerStats")
	stats.enter_floor(1)
	inv.clear()
	_check(inv.add_item("a", "A", "Bronze", 1, {"slot": "head", "bonuses": {"strength": 2}}), "add")
	_check(inv.add_item("a", "A", "Bronze"), "stack")
	_check(int(inv.slots[0]["count"]) == 2, "stack count")
	var before: int = stats.get_stat("strength")
	_check(inv.equip_from(0), "equip from stack")
	_check(int(inv.slots[0]["count"]) == 1, "stack decremented")
	_check(stats.get_stat("strength") == before + 2, "gear bonus applied")
	_check(inv.unequip("head"), "unequip")
	_check(int(inv.slots[0]["count"]) == 2, "returned to stack")
	_check(stats.get_stat("strength") == before, "bonus removed")
	for i: int in inv.SLOT_COUNT:
		inv.add_item("x%d" % i, "X", "Bronze")
	_check(not inv.add_item("overflow", "O"), "full rejects")
	_check(not inv.equip_from(5), "non-equippable rejected")
	inv.clear()
	_check(not inv.has_item("a"), "clear")
	print("RESULT " + ("PASS" if _fails == 0 else "FAIL"))
	quit(_fails)
