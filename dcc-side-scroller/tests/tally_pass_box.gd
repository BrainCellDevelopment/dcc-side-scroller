extends Node2D

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
	var always: bool = true
	for i in range(300):
		if str(LootTables.roll(LootTables.ROOM_KIT, "Silver")["id"]) != "goblin_pass":
			always = false
	_check(always, "Tally's room Silver box always rolls the Goblin Pass")
	var random_offers: bool = false
	for i in range(600):
		if str(LootTables.roll(LootTables.FLOOR1_KIT, "Silver")["id"]) == "goblin_pass":
			random_offers = true
	_check(not random_offers, "random Floor 1 Silver boxes never offer the pass")
	var box: Area2D = load("res://scenes/props/loot_box.tscn").instantiate() as Area2D
	box.set("kit", LootTables.ROOM_KIT)
	box.set("tier", "Silver")
	add_child(box)
	get_tree().current_scene = self
	box.call("_open")
	_check(Inventory.tattoos.has("goblin_pass"), "opening that box gives the tattoo")
	_check(str(box.get("rewarded_id")) == "goblin_pass", "the box reports the pass as its reward")
	var again: Dictionary = LootTables.roll(LootTables.ROOM_KIT, "Silver")
	_check(str(again["id"]) == "experience_cookie", "a second roll in the same run falls back to a cookie")
	var scene_text: String = FileAccess.get_file_as_string("res://scenes/level01.tscn")
	_check(not scene_text.contains("charm_gift = \"goblin_pass\""), "no goblin hands out the pass any more")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
