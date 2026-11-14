extends Node
## Carl and the rock thrower (#40): collisions between them must not stick, jitter or launch Carl. Rocks are held
## back so only the body collision is under test. #40 could not be reproduced; this pins the expected behaviour.

const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")
const SLIDE_OFF_VY: float = -140.0

var _fails: int = 0
var _world: Node2D = null
var _thrower: CharacterBody2D = null
var _player: CharacterBody2D = null


func _ready() -> void:
	await _run_into_then_jump(false)
	await _run_into_then_jump(true)
	await _head_landing()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _setup(cornered: bool) -> void:
	_world = Node2D.new()
	add_child(_world)
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(3000.0, 32.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 16.0)
	_world.add_child(floor_body)
	if cornered:
		var wall: StaticBody2D = StaticBody2D.new()
		wall.collision_layer = 1
		var wshape: CollisionShape2D = CollisionShape2D.new()
		var wrect: RectangleShape2D = RectangleShape2D.new()
		wrect.size = Vector2(16.0, 400.0)
		wshape.shape = wrect
		wall.add_child(wshape)
		wall.position = Vector2(40.0, -200.0)
		_world.add_child(wall)
	_thrower = GOBLIN.instantiate() as CharacterBody2D
	_thrower.set("variant", 1)
	_world.add_child(_thrower)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(-120.0, -2.0)
	_world.add_child(_player)
	_player.set("health", 999)
	await _frames(3)
	_thrower.set("throw_cooldown", 9999.0)


func _teardown() -> void:
	remove_child(_world)
	_world.free()
	await _frames(2)


func _run_into_then_jump(cornered: bool) -> void:
	var tag: String = "cornered thrower" if cornered else "thrower"
	await _setup(cornered)
	Input.action_press(&"move_right")
	var launches: int = 0
	var flips: int = 0
	var last_sign: float = 0.0
	var minimum_y: float = 0.0
	var jumped: bool = false
	var jump_frame: int = 0
	for i: int in 420:
		if not jumped and is_instance_valid(_thrower) and absf(_player.global_position.x - _thrower.global_position.x) < 26.0 and _player.is_on_floor():
			jumped = true
			jump_frame = i
			Input.action_press(&"jump")
		if jumped and i == jump_frame + 14:
			Input.action_release(&"jump")
		await get_tree().physics_frame
		if is_equal_approx(_player.velocity.y, SLIDE_OFF_VY):
			launches += 1
		var sgn: float = signf(_player.velocity.x)
		if jumped and sgn != 0.0 and last_sign != 0.0 and sgn != last_sign:
			flips += 1
		if sgn != 0.0:
			last_sign = sgn
		minimum_y = minf(minimum_y, _player.global_position.y)
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	_check(jumped, "%s: Carl reached it and jumped" % tag)
	var gone: bool = not is_instance_valid(_thrower)
	var over: bool = gone or _player.global_position.x > _thrower.global_position.x + 12.0
	if cornered:
		over = gone or _player.global_position.x > 20.0
	_check(over, "%s: Carl ends up past or over it (or has stomped it), not stuck (x %.0f)" % [tag, _player.global_position.x])
	_check(launches == 0, "%s: no slide-off launch fired while running and jumping (%d)" % [tag, launches])
	_check(flips == 0, "%s: no left-right jitter after the jump (%d flips)" % [tag, flips])
	_check(minimum_y < -20.0, "%s: the jump got off the ground (apex %.0f)" % [tag, minimum_y])
	await _teardown()


func _head_landing() -> void:
	await _setup(false)
	_thrower.set_physics_process(false)
	_thrower.global_position = Vector2(0.0, 0.0)
	_player.global_position = Vector2(0.0, -60.0)
	_player.velocity = Vector2.ZERO
	var before: int = int(_thrower.get("health"))
	var bounced: bool = false
	for i: int in 40:
		await get_tree().physics_frame
		if _player.velocity.y <= -200.0:
			bounced = true
	_check(bounced, "landing on a thrower's head stomps and bounces Carl")
	_check(not is_instance_valid(_thrower) or int(_thrower.get("health")) < before, "the stomp hurts the thrower")
	await _teardown()
