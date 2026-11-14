extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const RAT: PackedScene = preload("res://scenes/enemies/rat.tscn")
const SCATTERER: PackedScene = preload("res://scenes/enemies/scatterer.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")

var _fails: int = 0
var _unlocks: Array[String] = []


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	PlayerStats.reset()
	PlayerStats.enter_floor(1)
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void: _unlocks.append(title))
	await _level_content()
	await _sandbox()
	await _dead_end_run()
	Game.clear_checkpoint()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _count(level: Node, prefix: String) -> int:
	var n: int = 0
	for node: Node in level.get_node("Goblins").get_children():
		if str(node.name).begins_with(prefix):
			n += 1
	return n


func _level_content() -> void:
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await _frames(2)
	_check(_count(level, "Rat") == 5, "five rats in the corridor")
	_check(_count(level, "Scatterer") == 6, "six Scatterers in the corridor")
	var rat: Node = level.get_node("Goblins/Rat01")
	_check(int(rat.get("enemy_level")) == 2 and rat.is_in_group("enemies"), "rat is a level-2 enemy")
	_check(level.get_node("Doors").get_child_count() >= 4, "bathroom doors are placed (plus the entry door)")
	var dead_end: Node = level.get_node("Doors/LooDeadEnd")
	_check(str(dead_end.get("hidden_item_id")) != "", "dead-end door hides an item")
	_check(str(level.get_node("Doors/LooA").get("hidden_item_id")) == "", "other doors hide nothing")
	remove_child(level)
	level.free()


func _make_floor() -> StaticBody2D:
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
	return floor_body


func _stats_text() -> String:
	for child: Node in PlayerStats.get_children():
		if child.has_method("_stats_bbcode"):
			return str(child.call("_stats_bbcode", false))
	return ""


func _sandbox() -> void:
	var floor_body: StaticBody2D = _make_floor()
	var player: CharacterBody2D = PLAYER.instantiate() as CharacterBody2D
	player.position = Vector2(100.0, -90.0)
	add_child(player)
	var rat: CharacterBody2D = RAT.instantiate() as CharacterBody2D
	rat.name = "StompRat"
	rat.position = Vector2(100.0, -2.0)
	add_child(rat)
	var xp_before: int = PlayerStats.xp + PlayerStats.character_level * 1000
	await _frames(60)
	_check(int(rat.get("health")) <= 0, "stomping a rat kills it")
	_check(PlayerStats.smush_count == 1, "Smush counter counts the stomp kill")
	for i: int in 9:
		PlayerStats.add_smush()
	_check(_unlocks.has("Stompetition"), "ten Smush kills unlock the achievement")
	_check(PlayerStats.xp + PlayerStats.character_level * 1000 > xp_before, "rat kill awards XP")
	_check(_stats_text().contains("Smush 10"), "stats menu shows the Smush counter")
	await get_tree().create_timer(1.2).timeout
	_check(not is_instance_valid(rat) or rat.is_queued_for_deletion(), "dead rat is removed")

	var biter: CharacterBody2D = RAT.instantiate() as CharacterBody2D
	biter.position = Vector2(300.0, -2.0)
	add_child(biter)
	player.global_position = Vector2(300.0, -2.0)
	player.velocity = Vector2.ZERO
	player.set("health", 10)
	await _frames(3)
	biter.set("state", 2)
	biter.set("attack_phase", 1)
	biter.call("_try_hit", player)
	_check(int(player.get("health")) == 9, "rat bite does damage")
	_check(player.get_node_or_null("Poison") != null, "rat bite poisons")
	await get_tree().create_timer(3.6).timeout
	var hp: int = int(player.get("health"))
	_check(hp <= 7 and hp >= 5, "poison ticks cost health (%d)" % hp)
	_check(player.get_node_or_null("Poison") == null, "poison wears off")
	biter.free()

	var near: CharacterBody2D = SCATTERER.instantiate() as CharacterBody2D
	near.position = Vector2(500.0, -2.0)
	add_child(near)
	var far: CharacterBody2D = SCATTERER.instantiate() as CharacterBody2D
	far.position = Vector2(680.0, -2.0)
	add_child(far)
	player.global_position = Vector2(400.0, -2.0)
	player.velocity = Vector2.ZERO
	await _frames(6)
	_check(int(near.get("state")) != 0, "Scatterer notices the player")
	_check(int(far.get("state")) != 0, "one Scatterer alerts the rest of the swarm")
	near.free()
	far.free()
	player.free()
	floor_body.free()


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(3)
	Input.action_release(action)
	await _frames(3)


func _dead_end_run() -> void:
	PlayerStats.reset()
	PlayerStats.enter_floor(1)
	Inventory.clear()
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await _frames(3)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	await _frames(2)
	var player: CharacterBody2D = level.get_node("Player") as CharacterBody2D
	var door: Node2D = level.get_node("Doors/LooDeadEnd") as Node2D
	player.global_position = Vector2(door.global_position.x + 220.0, 302.0)
	player.set("health", 999)
	await _frames(5)
	var reached: bool = false
	for i: int in 1500:
		await get_tree().physics_frame
		var from: Vector2 = player.global_position + Vector2(0.0, -8.0)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, from + Vector2(-22.0, 0.0), 1)
		var wall: bool = not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
		var dx: float = door.global_position.x - player.global_position.x
		var below: bool = not (player.is_on_floor() and player.global_position.y < door.global_position.y + 10.0)
		if below:
			Input.action_press("move_left")
			var on_block: bool = player.global_position.y < 270.0
			if player.is_on_floor() and (wall or on_block):
				Input.action_press("jump")
			elif not player.is_on_floor() and player.velocity.y < 0.0:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			continue
		Input.action_release("jump")
		if absf(dx) < 6.0:
			reached = true
			break
		if dx < 0.0:
			Input.action_press("move_left")
			Input.action_release("move_right")
		else:
			Input.action_press("move_right")
			Input.action_release("move_left")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	_check(reached, "player can climb to the dead-end door (y %.0f, door y %.0f)" % [player.global_position.y, door.global_position.y])
	if reached:
		await _frames(6)
		await _tap(&"interact")
		_check(bool(door.get("inside")), "dead-end door opens")
		await get_tree().create_timer(1.0).timeout
		for n: Node in get_children():
			if n is CanvasLayer and n.has_method("leave"):
				n.call("leave")
		await get_tree().create_timer(0.8).timeout
		_check(Inventory.has_item("soap_travel"), "the hidden item is in the inventory")
	remove_child(level)
	level.free()
