extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	Game.earned_boxes = {"Bronze": 2, "Silver": 1, "Legendary": 1}
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	var room: Node2D = level.get_node("FastFoodRoom") as Node2D
	var player: CharacterBody2D = level.get_node("Player") as CharacterBody2D
	player.set("health", 999)
	await _frames(10)
	_check(get_tree().get_nodes_in_group("loot_boxes").size() == 0, "no boxes exist outside the safe room")
	player.global_position = room.global_position + Vector2(200.0, -2.0)
	await _frames(20)
	var tiers: Array = []
	for box: Node in get_tree().get_nodes_in_group("loot_boxes"):
		tiers.append(str(box.get("tier")))
	tiers.sort()
	_check(tiers.size() == 6, "entering the room adds 4 earned boxes to the 2 room boxes (%d)" % tiers.size())
	_check(tiers.count("Legendary") == 1 and tiers.count("Bronze") == 3, "earned tiers are present %s" % str(tiers))
	_check(Game.earned_boxes.is_empty(), "earned boxes were handed over")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
