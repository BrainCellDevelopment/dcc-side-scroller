extends Node
## Landing on the Goblin Engineer's head (#41, #43): it hurts him and bounces Carl like a goblin stomp, a second
## stomp straight after is ignored (no stun-lock), he cannot be stomped while inactive, and he still blocks Carl
## from the side without trapping him.

const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const ENGINEER: PackedScene = preload("res://scenes/enemies/engineer.tscn")

var _fails: int = 0
var _world: Node2D = null
var _player: CharacterBody2D = null
var _engineer: CharacterBody2D = null


func _ready() -> void:
	await _setup(true)
	await _stomp_checks()
	await _teardown()
	await _setup(false)
	await _inactive_check()
	await _teardown()
	await _setup(true)
	await _side_check()
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


func _setup(activate: bool) -> void:
	_world = Node2D.new()
	add_child(_world)
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(2000.0, 32.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 16.0)
	_world.add_child(floor_body)
	_engineer = ENGINEER.instantiate() as CharacterBody2D
	_engineer.position = Vector2(0.0, 0.0)
	_world.add_child(_engineer)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(-300.0, -2.0)
	_world.add_child(_player)
	_player.set("health", 999)
	await _frames(3)
	if activate:
		_engineer.call("activate")
		_engineer.set("state_timer", 99.0)
	await _frames(2)


func _teardown() -> void:
	remove_child(_world)
	_world.free()
	await _frames(2)


func _drop_onto_head() -> void:
	_player.global_position = Vector2(0.0, -90.0)
	_player.velocity = Vector2(0.0, 120.0)


func _stomp_checks() -> void:
	var before: int = int(_engineer.get("health"))
	_drop_onto_head()
	await _wait_for(func() -> bool: return int(_engineer.get("health")) < before, 1.5)
	_check(int(_engineer.get("health")) == before - int(_player.get("stomp_damage")), "landing on his head hurts the Engineer (%d -> %d)" % [before, int(_engineer.get("health"))])
	_check(_player.velocity.y < 0.0, "Carl bounces off (vy %.0f)" % _player.velocity.y)
	var after_first: int = int(_engineer.get("health"))
	_drop_onto_head()
	await _frames(40)
	_check(int(_engineer.get("health")) == after_first, "a second stomp right away is ignored (no stun-lock)")
	await get_tree().create_timer(1.0).timeout
	_check(bool(_engineer.call("can_be_stomped")), "he can be stomped again after the lock")
	var third: int = int(_engineer.get("health"))
	_drop_onto_head()
	await _wait_for(func() -> bool: return int(_engineer.get("health")) < third, 1.5)
	_check(int(_engineer.get("health")) == third - int(_player.get("stomp_damage")), "stomping again after the lock hurts him again")
	_player.global_position = Vector2(0.0, -34.0)
	_player.velocity = Vector2.ZERO
	await _frames(5)
	await get_tree().create_timer(1.5).timeout
	_check(absf(_player.global_position.x) > 6.0 or _player.global_position.y >= -2.0, "Carl cannot stand on his head (x %.0f y %.0f)" % [_player.global_position.x, _player.global_position.y])


func _inactive_check() -> void:
	var before: int = int(_engineer.get("health"))
	_drop_onto_head()
	await _frames(60)
	_check(int(_engineer.get("health")) == before, "a stomp does nothing before the fight is active")
	_check(not bool(_engineer.call("can_be_stomped")), "he cannot be stomped while inactive")


func _side_check() -> void:
	_engineer.set("state", 0)
	_player.global_position = Vector2(-80.0, -2.0)
	_player.velocity = Vector2.ZERO
	Input.action_press(&"move_right")
	await _frames(90)
	Input.action_release(&"move_right")
	_check(_player.global_position.x < _engineer.global_position.x, "Engineer still blocks Carl from the side (%.0f < %.0f)" % [_player.global_position.x, _engineer.global_position.x])
	_check(absf(_player.global_position.y) < 8.0, "Carl is not launched or trapped at his side (y %.0f)" % _player.global_position.y)


func _wait_for(cond: Callable, timeout: float) -> void:
	var left: float = timeout
	while left > 0.0 and not cond.call():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
