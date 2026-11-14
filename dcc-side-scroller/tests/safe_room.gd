extends Node

const ROOM: PackedScene = preload("res://scenes/level/safe_room.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")

var _fails: int = 0
var _room: Node2D
var _player: CharacterBody2D
var _neutralised: int = 0


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(3000.0, 40.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 20.0)
	add_child(floor_body)
	_room = ROOM.instantiate() as Node2D
	_room.set("checkpoint_index", 3)
	add_child(_room)
	_room.connect("enemy_neutralised", func(_e: Node) -> void: _neutralised += 1)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(330.0, -2.0)
	add_child(_player)
	await _frames(10)
	await _hall_blocks_door()
	await _enter_heals_and_checkpoints()
	await _follower_neutralised()
	await _boxes_only_inside()
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


func _spawn_goblin(x: float) -> Node2D:
	var goblin: Node2D = GOBLIN.instantiate() as Node2D
	goblin.position = Vector2(x, -2.0)
	add_child(goblin)
	return goblin


func _hall_blocks_door() -> void:
	var door: Node2D = _room.get_node("EntryDoor")
	var goblin: Node2D = _spawn_goblin(340.0)
	_player.global_position = Vector2(290.0, -2.0)
	await _frames(45)
	_check(not bool(door.get("is_open")), "door refuses to open with an enemy in the hallway")
	_check(bool(door.get("locked")), "door is locked while the hallway is occupied")
	_check(not Game.in_safe_zone, "outside the room is not a safe zone")
	goblin.queue_free()
	await _frames(45)
	_check(bool(door.get("is_open")), "door opens once the hallway is clear")


func _enter_heals_and_checkpoints() -> void:
	_player.set("health", 3)
	_player.set("stamina", 10.0)
	_player.set("mana", 0.0)
	_player.global_position = Vector2(180.0, -2.0)
	await _frames(10)
	_check(Game.in_safe_zone, "entering sets the safe zone")
	_check(int(_player.get("health")) == int(_player.get("max_health")), "entering refills health")
	_check(float(_player.get("stamina")) >= float(_player.get("max_stamina")) - 1.0, "entering refills stamina")
	_check(float(_player.get("mana")) >= float(_player.get("max_mana")) - 0.1, "entering refills mana")
	_check(Game.checkpoint_index == 3, "entering sets the checkpoint index")
	_check(Game.checkpoint_position.is_equal_approx(_room.get_node("Checkpoint").global_position), "checkpoint is the room checkpoint")
	_check(bool(_room.get_node("Checkpoint").get("lit")), "checkpoint is lit")
	_player.global_position = Vector2(120.0, -2.0)
	await _frames(40)
	_check(not bool(_room.get_node("EntryDoor").get("is_open")), "entry door closes behind the player")


func _follower_neutralised() -> void:
	var before: int = _neutralised
	var follower: Node2D = _spawn_goblin(330.0)
	await _frames(120)
	_check(is_instance_valid(follower) and follower.global_position.x > 235.0, "follower is held back by the shut door")
	_check(int(_player.get("health")) == int(_player.get("max_health")), "follower never hurt the player")
	_check(not bool(_room.get_node("EntryDoor").get("is_open")), "door stays shut with the follower outside")
	follower.queue_free()
	var intruder: Node2D = _spawn_goblin(60.0)
	await _frames(15)
	_check(_neutralised == before + 1, "an enemy inside the room is neutralised")
	_check(not is_instance_valid(intruder) or intruder.is_queued_for_deletion() or int(intruder.get("state")) == 4, "intruder is out of the fight")
	await _frames(30)


func _boxes_only_inside() -> void:
	_player.global_position = Vector2(60.0, -2.0)
	await _frames(10)
	_check(Game.in_safe_zone, "player is back inside")
	var box: Area2D = _room.call("add_box", "Bronze") as Area2D
	await _frames(60)
	await _tap()
	_check(bool(box.get("is_open")), "box opens inside the safe room")
	_check(Inventory.has_item("bandages"), "opened box added its item")
	var second: Area2D = _room.call("add_box", "Silver") as Area2D
	_player.global_position = Vector2(-400.0, -2.0)
	await _frames(90)
	_check(not Game.in_safe_zone, "player left the safe room")
	await _tap()
	_check(not bool(second.get("is_open")), "box does not open outside the safe room")
	_player.global_position = Vector2(0.0, -2.0)
	await _frames(90)
	await _tap()
	_check(bool(second.get("is_open")), "same box opens after returning inside")
