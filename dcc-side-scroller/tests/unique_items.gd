extends Node

const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")
const LootTables: GDScript = preload("res://scripts/data/loot_tables.gd")

var _fails: int = 0


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1


func _run() -> void:
	Game.reset_run()
	_check(ItemDefs.is_unique("goblin_pass"), "goblin pass is unique")
	_check(not ItemDefs.is_unique("healing_potion"), "healing potion is not unique")
	_check(ItemDefs.give("goblin_pass", 3), "first goblin pass is received")
	_check(Inventory.count_of("goblin_pass") == 1, "only one is added even when more are requested")
	_check(not ItemDefs.give("goblin_pass"), "a second goblin pass is refused")
	Inventory.clear()
	_check(not ItemDefs.give("goblin_pass"), "still refused after it leaves the bag, same run")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var seen: bool = false
	for i in range(600):
		if str(LootTables.roll(LootTables.FLOOR1_KIT, "Silver", rng)["id"]) == "goblin_pass":
			seen = true
	_check(not seen, "silver rolls never offer the goblin pass again")
	Game.reset_run()
	_check(ItemDefs.give("goblin_pass"), "a new run can receive it once more")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
