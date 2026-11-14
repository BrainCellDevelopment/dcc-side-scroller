extends Node

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")

var _fails: int = 0


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _ready() -> void:
	Game.reset_run()
	Game.reset_boxes()
	Game.clear_checkpoint()
	var toasts: Array[String] = []
	Game.item_added.connect(func(item: Dictionary) -> void:
		if str(item.get("id", "")) == "loot_box":
			toasts.append(str(item["tier"])))
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(not Game.starter_boxes_announced, "nothing granted on the surface")
	level.call("_enter_section", 1)
	_check(not Game.starter_boxes_announced, "nothing granted on the staircase")
	var before: int = toasts.size()
	level.call("_enter_section", 2)
	_check(Game.starter_boxes_announced and toasts.slice(before) == ["Bronze", "Legendary"], "entering the dungeon grants the Bronze and Legendary starters %s" % str(toasts.slice(before)))
	level.call("_enter_section", 3)
	_check(toasts.size() == before + 2, "starter boxes are only granted once")
	_check(Game.earned_boxes == {"Bronze": 1}, "only the Still Breathing achievement box is held %s" % str(Game.earned_boxes))
	Game.grant_box("Silver")
	Game.reset_run()
	_check(Game.earned_boxes.get("Silver", 0) == 1, "dying keeps unopened boxes")
	Game.reset_boxes()
	_check(Game.earned_boxes.is_empty(), "a fresh run clears them")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
