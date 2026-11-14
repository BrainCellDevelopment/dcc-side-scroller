extends Node

const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")
const ItemEffects: GDScript = preload("res://scripts/combat/item_effects.gd")

var _fails: int = 0


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1


func _bag_has(id: String) -> bool:
	for slot: Dictionary in Inventory.slots:
		if not slot.is_empty() and str(slot["id"]) == id:
			return true
	return false


func _run() -> void:
	Game.reset_run()
	_check(ItemDefs.give("goblin_pass"), "goblin pass is received")
	_check(not _bag_has("goblin_pass"), "it takes no bag slot")
	_check(Inventory.tattoos.has("goblin_pass"), "it is stored as a tattoo")
	_check(Inventory.has_item("goblin_pass") and Inventory.count_of("goblin_pass") == 1, "it still counts as owned")
	_check(ItemEffects.has_goblin_pass(), "goblins still see the pass")
	_check(str(Inventory.tattoo_item().get("name", "")) == "Goblin Pass", "tattoo_item returns it for the doll")
	ItemDefs.give("healing_potion")
	_check(_bag_has("healing_potion"), "normal items still use the bag")
	Game.reset_run()
	_check(Inventory.tattoos.is_empty() and not Inventory.has_item("goblin_pass"), "a new run clears the tattoo")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
