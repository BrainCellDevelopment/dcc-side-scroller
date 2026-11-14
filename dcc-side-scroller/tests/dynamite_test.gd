extends Node

const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const DYNAMITE: PackedScene = preload("res://scenes/combat/dynamite.tscn")
const DOOR: PackedScene = preload("res://scenes/props/blast_door.tscn")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0


class Dummy:
	extends Node2D
	var health: int = 3
	var hits: int = 0

	func take_damage(amount: int, _from: Vector2) -> void:
		health -= amount
		hits += 1


func _ready() -> void:
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


func _dummy(pos: Vector2) -> Dummy:
	var d: Dummy = Dummy.new()
	d.add_to_group("enemies")
	d.global_position = pos
	add_child(d)
	return d


func _run() -> void:
	Explosives.reset()
	Inventory.clear()
	# Direct blast: radius 50 around (0,0). Dummy body centre is 12px above its origin.
	var near_a: Dummy = _dummy(Vector2(10.0, 12.0))
	var near_b: Dummy = _dummy(Vector2(-30.0, 12.0))
	var near_c: Dummy = _dummy(Vector2(0.0, 40.0))
	var far: Dummy = _dummy(Vector2(200.0, 12.0))
	var hit: Array[Node] = Explosives.blast(get_tree(), Vector2.ZERO, 50.0, 2, 0)
	_check(hit.size() == 3, "blast hits exactly the 3 targets in radius")
	_check(near_a.hits == 1 and near_b.hits == 1 and near_c.hits == 1, "every in-radius enemy damaged once")
	_check(far.hits == 0, "enemy outside radius untouched")
	_check(near_a.health == 1, "damage amount applied")
	_check(Explosives.handling == 1, "Explosives Handling counter increments")
	for d: Dummy in [near_a, near_b, near_c, far]:
		d.queue_free()

	# Sealed door: blast out of range leaves it shut, in range opens it.
	var door: StaticBody2D = DOOR.instantiate() as StaticBody2D
	door.position = Vector2(0.0, 300.0)
	add_child(door)
	await _frames(2)
	var shape: CollisionShape2D = door.get_node("CollisionShape2D")
	Explosives.blast(get_tree(), Vector2(0.0, 100.0), 50.0, 2, 0)
	_check(not bool(door.get("is_open")) and not shape.disabled, "distant blast leaves sealed door shut")
	var opened_flag: Array[bool] = [false]
	door.connect("opened", func() -> void: opened_flag[0] = true)
	Explosives.blast(get_tree(), Vector2(20.0, 270.0), 50.0, 2, 0)
	await _frames(2)
	_check(bool(door.get("is_open")) and opened_flag[0], "blast in range opens the sealed door")
	_check(shape.disabled, "opened door no longer blocks")

	# Thrown stick: item cost, fuse, floor, damage to a group.
	var floor_body: StaticBody2D = StaticBody2D.new()
	var floor_shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(2000.0, 20.0)
	floor_shape.shape = rect
	floor_body.add_child(floor_shape)
	floor_body.position = Vector2(0.0, 520.0)
	add_child(floor_body)
	var group: Array[Dummy] = [_dummy(Vector2(500.0, 510.0)), _dummy(Vector2(520.0, 510.0)), _dummy(Vector2(480.0, 510.0))]
	var bystander: Dummy = _dummy(Vector2(800.0, 510.0))
	Explosives.add_stack(2)
	_check(Explosives.stack_count() == 2, "stack starts at 2")
	var stick: Node2D = DYNAMITE.instantiate() as Node2D
	add_child(stick)
	stick.set("fuse_time", 1.0)
	stick.call("launch", Vector2(500.0, 480.0), Vector2.ZERO)
	_check(Explosives.consume_one() and Explosives.stack_count() == 1, "throwing costs one stack item")
	await _frames(90)
	_check(not is_instance_valid(stick), "stick exploded after its fuse")
	var all_hit: bool = true
	for d: Dummy in group:
		all_hit = all_hit and d.hits == 1
	_check(all_hit, "thrown blast damaged the whole group")
	_check(bystander.hits == 0, "distant bystander unharmed")
	_check(Explosives.handling == 3, "handling counts each blast that hit something")

	# Player integration in level 1.
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	await _frames(30)
	var player: CharacterBody2D = level.get_node("Player")
	Inventory.clear()
	var before: int = get_tree().get_nodes_in_group("dynamite").size()
	_check(not bool(player.call("throw_dynamite")), "cannot throw with no dynamite")
	Explosives.add_stack(1)
	_check(bool(player.call("throw_dynamite")), "player throws when holding dynamite")
	_check(Explosives.stack_count() == 0, "player throw consumed the last stick")
	_check(get_tree().get_nodes_in_group("dynamite").size() == before + 1, "dynamite node spawned")
	_check(InputMap.has_action("throw"), "throw input action registered")
	_check(Explosives.handling >= 3, "handling retained")
