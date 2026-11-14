extends Node

const DropRates: GDScript = preload("res://scripts/data/drop_rates.gd")

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")

var _level: Node2D
var _fails: int = 0


func _ready() -> void:
	Game.reset_run()
	Game.set_checkpoint(8, Vector2(19384.0, 912.0), 2)
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(30)
	await _run()
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


func _shot(name: String) -> void:
	if OS.get_environment("DCC_SHOT_DIR").is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [OS.get_environment("DCC_SHOT_DIR"), name])


func _visible_boxes() -> int:
	var n: int = 0
	for box: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if (box as Node2D).visible and not bool(box.get("is_open")):
			n += 1
	return n


func _run() -> void:
	var earned_before: int = Game.earned_boxes.size()
	_check(earned_before == 0, "no boxes earned before any kills")
	for i: int in 120:
		var goblin: Node = GOBLIN.instantiate()
		_level.add_child(goblin)
		goblin.call("_die")
	var total: int = 0
	for tier: String in Game.earned_boxes:
		total += int(Game.earned_boxes[tier])
	_check(total == DropRates.TUTORIAL_BOX_CAP, "Level 0 kills stop at %d earned boxes (%d from 120 kills)" % [DropRates.TUTORIAL_BOX_CAP, total])
	_check(not Game.earned_boxes.has("Gold") and not Game.earned_boxes.has("Legendary"), "Level 0 drops only Bronze and Silver %s" % str(Game.earned_boxes))
	_check(_visible_boxes() == 0, "earned boxes do not exist in the world yet")
	Game.earned_boxes = {"Bronze": 5, "Silver": 3}
	var mord: Area2D = _level.get_node("Guildhall/Mordecai")
	var player: CharacterBody2D = _level.get_node("Player")
	player.global_position = mord.global_position + Vector2(30.0, -2.0)
	await _frames(20)
	for i: int in 4:
		await _tap()
	await _frames(200)
	_check(_visible_boxes() == 10, "guildhall shows 2 fixed + 8 earned boxes (10 total) (%d)" % _visible_boxes())
	await _shot("earned_boxes_guildhall")
	_check(Game.earned_boxes.is_empty(), "earned boxes were taken")
	_check(not _level.get("_exit_ready"), "exit not ready before opening the fixed boxes")
	var opened: Array[int] = [0]
	Game.loot_box_opened.connect(func(_tier: String) -> void: opened[0] += 1)
	var attempts: int = 0
	while opened[0] < 10 and attempts < 40:
		attempts += 1
		await _tap()
		await _frames(30)
	_check(opened[0] == 10, "all ten boxes opened (%d)" % opened[0])
	await _frames(120)
	_check(_level.get("_exit_ready"), "exit ready once boxes are opened")
	var items: int = 0
	for slot: Dictionary in Inventory.slots:
		if not slot.is_empty():
			items += int(slot["count"])
	_check(items >= 10, "opening ten boxes yields items (%d total)" % items)
