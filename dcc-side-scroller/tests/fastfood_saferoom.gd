extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")

var _fails: int = 0
var _level: Node2D
var _room: Node2D
var _player: CharacterBody2D
var _opened: int = 0
var _achievements: Array[String] = []


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	Game.loot_box_opened.connect(func(_t: String) -> void: _opened += 1)
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void: _achievements.append(title))
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	_room = _level.get_node("FastFoodRoom") as Node2D
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 999)
	await _frames(10)
	await _door_denies_enemies()
	await _enter_and_checkpoint()
	await _talk_and_eat()
	await _open_boxes()
	await _exit()
	await _respawn()
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _tap() -> void:
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(3)


func _at(dx: float) -> void:
	_player.global_position = _room.global_position + Vector2(dx, -2.0)
	_player.velocity = Vector2.ZERO


func _door_denies_enemies() -> void:
	var door: Node2D = _room.get_node("EntryDoor")
	var goblin: Node2D = GOBLIN.instantiate() as Node2D
	goblin.global_position = _room.global_position + Vector2(350.0, -2.0)
	_level.add_child(goblin)
	await _frames(10)
	_at(336.0)
	await _frames(50)
	_check(not bool(door.get("is_open")), "door stays shut with an enemy at the door")
	_check(not Game.in_safe_zone, "outside the door is not a safe zone")
	goblin.queue_free()
	await _frames(50)
	_check(bool(door.get("is_open")), "door opens once the hall is clear")


func _enter_and_checkpoint() -> void:
	_player.set("health", 4)
	_at(200.0)
	await _frames(15)
	_check(Game.in_safe_zone, "entering sets the safe zone")
	_check(int(_player.get("health")) == int(_player.get("max_health")), "entering heals")
	_check(Game.checkpoint_index == 2, "entering fixes the first Floor 1 checkpoint (index 2)")
	var anchor: Node2D = _level.get_node("Checkpoints/CP2") as Node2D
	_check(Game.checkpoint_position.distance_to(anchor.global_position) < 1.0, "room checkpoint matches the level checkpoint")
	_check(_achievements.has("Four Walls, Zero Stabbing"), "first_safe_room achievement fired")
	_check(get_tree().get_nodes_in_group("loot_boxes").size() == 2, "a Bronze and a Silver box appear")
	var tiers: Array = []
	for box: Node in get_tree().get_nodes_in_group("loot_boxes"):
		tiers.append(str(box.get("tier")))
	_check(tiers.has("Bronze") and tiers.has("Silver"), "box tiers are Bronze and Silver")


func _talk_and_eat() -> void:
	var tally: Node2D = _room.get_node("Caretaker") as Node2D
	_at(tally.position.x)
	await _frames(10)
	var taps: int = 0
	while not bool(tally.get("perk_taken")) and taps < 12:
		await _tap()
		taps += 1
	_check(bool(tally.get("perk_taken")), "talking to Tally gives the paper hat (%d presses)" % taps)
	_check(Inventory.has_item("tally_paper_hat"), "the hat is in the inventory")
	await _tap()
	_check(not bool(tally.get("talking")), "dialogue ends")
	_player.set("health", 2)
	await _tap()
	_check(bool(tally.get("meal_eaten")), "eating is offered after the talk")
	_check(int(_player.get("health")) == int(_player.get("max_health")), "the meal is a full heal")
	_check(float(_player.get("buff_left")) > 60.0, "the meal gives a short buff")
	var shown: String = (tally.get_node("Speech") as Label).text
	_check(shown.to_lower().contains("vindaloo"), "Tally serves vindaloo")
	await _tap()
	_check((tally.get_node("Speech") as Label).text.to_lower().contains("salmon"), "salmon line for Donut")
	await _tap()
	await _tap()
	_check(not bool(tally.get("talking")), "meal dialogue ends")
	_check(bool(_player.get("control_enabled")), "player control is back")


func _open_boxes() -> void:
	_at(-20.0)
	await _frames(100)
	var before: int = _opened
	for i: int in 4:
		await _tap()
	_check(_opened - before == 2, "both boxes open here (%d)" % (_opened - before))
	_check(Inventory.slots.any(func(x: Dictionary) -> bool: return not x.is_empty()), "boxes gave items")


func _exit() -> void:
	var door: Node2D = _room.get_node("ExitDoor")
	_at(-296.0)
	await _frames(60)
	_check(bool(door.get("is_open")), "exit door opens with a clear hall")
	_at(-360.0)
	await _frames(30)
	_check(not Game.in_safe_zone, "outside the exit is not a safe zone")


func _respawn() -> void:
	_level.queue_free()
	await _frames(3)
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	await _frames(10)
	var player: Node2D = level.get_node("Player") as Node2D
	var room: Node2D = level.get_node("FastFoodRoom") as Node2D
	_check(int(level.get("section")) == 2, "respawn lands in the safe room section")
	_check(absf(player.global_position.x - (room.global_position.x + 48.0)) < 4.0, "respawn is at the room checkpoint (%.0f vs %.0f)" % [player.global_position.x, room.global_position.x + 48.0])
