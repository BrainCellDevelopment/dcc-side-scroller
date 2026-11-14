extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const Course: GDScript = preload("res://scripts/data/chopper_course.gd")

var _fails: int = 0


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _ready() -> void:
	Game.reset_run()
	Game.clear_checkpoint()
	Game.set_checkpoint(4, Vector2(2336.0, 304.0), 4)
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	await _frames(10)
	var stop: Node2D = null
	for node: Node in level.get_children():
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("chopper_stop.gd"):
			stop = node as Node2D
	_check(stop != null, "Level 1 has the parked chopper")
	var player: CharacterBody2D = level.get_node("Player") as CharacterBody2D
	player.global_position = stop.global_position + Vector2(0.0, -2.0)
	player.velocity = Vector2.ZERO
	await _frames(40)
	_check(player.is_on_floor(), "there is ground under the chopper")
	_check(absf(player.global_position.y - 304.0) < 6.0, "Carl stands on the floor line (y %.0f)" % player.global_position.y)
	_check(bool(stop.call("near_player")) and bool((stop.get("_prompt") as Label).visible), "standing beside it shows the ride prompt")
	player.global_position = stop.global_position + Vector2(400.0, -2.0)
	await _frames(5)
	_check(not bool(stop.call("near_player")) and not bool((stop.get("_prompt") as Label).visible), "walking on hides the prompt")
	level.queue_free()
	await _frames(3)
	Game.set_checkpoint(Course.RETURN_INDEX, Course.RETURN_POSITION, Course.RETURN_STAGE)
	var back: Node2D = LEVEL.instantiate() as Node2D
	add_child(back)
	await _frames(10)
	var again: CharacterBody2D = back.get_node("Player") as CharacterBody2D
	_check(absf(again.global_position.x - Course.RETURN_POSITION.x) < 8.0, "finishing the ride lands Carl at the Swine arena checkpoint (x %.0f)" % again.global_position.x)
	_check(int(back.get("section")) == 4 or int(back.get("section")) == 5, "back in the workshop or swine section (%d)" % int(back.get("section")))
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
