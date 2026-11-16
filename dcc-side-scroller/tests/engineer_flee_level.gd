extends Node
## Issue #121 in the real Level 0 arena: after the last hit the fleeing Engineer must not carry off a Carl
## standing in front of him.

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")

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
	OS.set_environment("DCC_SKIP_INTRO", "1")
	var level: Node2D = LEVEL.instantiate() as Node2D
	var arena_cp: Node2D = null
	for node: Node in level.get_node("Checkpoints").get_children():
		if int(node.get("index")) == 6:
			arena_cp = node as Node2D
	Game.set_checkpoint(6, arena_cp.global_position, int(arena_cp.get("stage")))
	add_child(level)
	await _frames(60)
	var engineer: CharacterBody2D = level.get_node("Engineer") as CharacterBody2D
	var player: CharacterBody2D = level.get_node("Player") as CharacterBody2D
	player.set("health", 9999)
	level.call("_start_arena")
	var waited: int = 0
	while not bool(engineer.get("active")) and waited < 600:
		await _frames(1)
		waited += 1
	_check(bool(engineer.get("active")), "the fight starts (waited %d frames)" % waited)
	engineer.set("health", 1)
	engineer.set("state", 0)
	engineer.set("state_timer", 99.0)
	player.global_position = engineer.global_position + Vector2(24.0, -2.0)
	player.velocity = Vector2.ZERO
	await _frames(4)
	var start_x: float = player.global_position.x
	engineer.call("take_damage", 1, engineer.global_position + Vector2(-50.0, 0.0))
	_check(int(engineer.get("state")) == 7, "the last hit defeats him")
	await _frames(60 * 5)
	var moved: float = player.global_position.x - start_x
	_check(absf(moved) < 40.0, "Carl standing in front is not carried off (moved %.0f px)" % moved)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
