extends Node
## Issue #121: the Goblin Engineer and Carl must not pass through or sink into each other while the fight
## is running. The Engineer's collision mask and Carl's mask have to agree.

const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const ENGINEER: PackedScene = preload("res://scenes/enemies/engineer.tscn")
const MIN_GAP: float = 12.0

var _fails: int = 0
var _world: Node2D = null
var _player: CharacterBody2D = null
var _engineer: CharacterBody2D = null


func _ready() -> void:
	await _setup()
	await _walk_into_standing_carl()
	await _teardown()
	await _setup()
	await _engineer_runs_the_fight()
	await _teardown()
	await _setup()
	await _flee_through_carl()
	await _teardown()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _setup() -> void:
	_world = Node2D.new()
	add_child(_world)
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(4000.0, 32.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 16.0)
	_world.add_child(floor_body)
	_engineer = ENGINEER.instantiate() as CharacterBody2D
	_engineer.position = Vector2(-160.0, 0.0)
	_world.add_child(_engineer)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(0.0, -2.0)
	_world.add_child(_player)
	_player.set("health", 9999)
	await _frames(5)


func _teardown() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	remove_child(_world)
	_world.free()
	await _frames(2)


func _gap() -> float:
	return absf(_player.global_position.x - _engineer.global_position.x)


func _walk_into_standing_carl() -> void:
	_engineer.call("activate")
	_engineer.set("state", 3)
	_engineer.set("facing", 1)
	_engineer.set("state_timer", 1.2)
	var closest: float = 9999.0
	for i: int in 70:
		await _frames(1)
		closest = minf(closest, _gap())
	_check(closest >= MIN_GAP, "a dashing Engineer stops at Carl instead of running through him (closest %.1f px)" % closest)
	_check(_engineer.global_position.x < _player.global_position.x, "he is still on his own side of Carl (%.0f < %.0f)" % [_engineer.global_position.x, _player.global_position.x])


func _engineer_runs_the_fight() -> void:
	_engineer.call("activate")
	var closest: float = 9999.0
	var worst_dy: float = 0.0
	for i: int in 60 * 8:
		await _frames(1)
		if absf(_player.global_position.y - _engineer.global_position.y) < 8.0:
			closest = minf(closest, _gap())
		worst_dy = maxf(worst_dy, absf(_player.global_position.y))
	_check(closest >= MIN_GAP, "through a full fight the two never overlap on the floor (closest %.1f px)" % closest)
	_check(worst_dy < 90.0, "Carl is never launched off the floor by the overlap (max rise %.0f px)" % worst_dy)


func _flee_through_carl() -> void:
	_engineer.call("activate")
	_engineer.global_position = Vector2(-30.0, 0.0)
	_player.global_position = Vector2(0.0, -2.0)
	_player.velocity = Vector2.ZERO
	await _frames(5)
	var start_x: float = _player.global_position.x
	_engineer.call("take_damage", 9999, Vector2(-200.0, 0.0))
	_check(int(_engineer.get("state")) == 7, "the last hit defeats the Engineer")
	_engineer.set("scripted", true)
	_player.set("control_enabled", false)
	var tween: Tween = create_tween()
	tween.tween_property(_engineer, "global_position:x", _engineer.global_position.x + 400.0, 2.4)
	await _frames(60 * 3)
	_check(absf(_player.global_position.x - start_x) < 8.0, "Carl in front of the fleeing Engineer is not carried off (moved %.0f px)" % (_player.global_position.x - start_x))
	_check(_engineer.global_position.x > start_x + 300.0, "the Engineer still runs off (x %.0f)" % _engineer.global_position.x)
