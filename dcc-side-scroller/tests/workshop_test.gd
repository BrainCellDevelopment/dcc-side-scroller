extends Node

const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")
const BOMB: PackedScene = preload("res://scenes/enemies/glass_bomb.tscn")
const PROP: PackedScene = preload("res://scenes/props/workshop_prop.tscn")
const VENT: PackedScene = preload("res://scenes/level/steam_vent.tscn")
const DYNAMITE: PackedScene = preload("res://scenes/combat/dynamite.tscn")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")
const BombScript: GDScript = preload("res://scripts/enemies/glass_bomb.gd")

var _fails: int = 0
var _player: CharacterBody2D
var _stage: Node2D


func _ready() -> void:
	await _bomb_and_bard()
	await _shamanka_anguish()
	await _charm_path()
	await _violence_path()
	await _boiler_blast()
	await _steam_vent()
	await _level_layout()
	Inventory.clear()
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


func _setup() -> void:
	if _stage != null:
		_stage.queue_free()
		await _frames(2)
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	PlayerStats.reset()
	PlayerStats.enter_floor(1)
	_stage = Node2D.new()
	add_child(_stage)
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(3000.0, 40.0)
	shape.shape = rect
	floor_body.add_child(shape)
	floor_body.position = Vector2(0.0, 20.0)
	_stage.add_child(floor_body)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(0.0, -2.0)
	_stage.add_child(_player)
	_player.call("enable_spell")
	_player.set("health", 999)
	await _frames(8)


func _spawn(scene: PackedScene, x: float, props: Dictionary = {}) -> Node2D:
	var node: Node2D = scene.instantiate() as Node2D
	node.position = Vector2(x, -2.0)
	for key: String in props:
		node.set(key, props[key])
	_stage.add_child(node)
	return node


func _charm() -> void:
	Input.action_press("charm")
	await _frames(2)
	Input.action_release("charm")
	await _frames(3)


func _hostile_for(goblin: Node2D, frames: int) -> bool:
	var before: int = int(_player.get("health"))
	var seen: bool = false
	for i: int in frames:
		await get_tree().physics_frame
		if is_instance_valid(goblin) and int(goblin.get("state")) in [1, 2]:
			seen = true
	return seen or int(_player.get("health")) < before


func _bombs_in_air() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		if node.get_script() == BombScript:
			count += 1
	return count


func _bomb_and_bard() -> void:
	await _setup()
	var bard: Node2D = _spawn(GOBLIN, 170.0, {"variant": 2, "enemy_level": 5})
	await _frames(4)
	_check(int(bard.get("max_health")) == 3, "Bomb Bard has 3 health")
	var thrown: bool = false
	for i: int in 420:
		await get_tree().physics_frame
		if _bombs_in_air() > 0:
			thrown = true
			break
	_check(thrown, "Bomb Bard throws a glass bomb at Carl")
	bard.queue_free()
	await _setup()
	var friend: Node2D = _spawn(GOBLIN, 14.0, {"variant": 0})
	var before: int = int(_player.get("health"))
	var friend_hp: int = int(friend.get("health"))
	var bomb: Area2D = BOMB.instantiate() as Area2D
	_stage.add_child(bomb)
	bomb.global_position = Vector2(4.0, -12.0)
	bomb.call("launch", Vector2.ZERO, 1)
	await _frames(6)
	_check(int(_player.get("health")) == before - 1, "a glass bomb burst hurts Carl")
	_check(int(friend.get("health")) < friend_hp, "careless: the burst hurts goblins too")
	friend.queue_free()
	await _frames(2)


func _shamanka_anguish() -> void:
	await _setup()
	var shamanka: Node2D = _spawn(GOBLIN, 150.0, {"variant": 3, "enemy_level": 7})
	var grunt: Node2D = _spawn(GOBLIN, 230.0, {"variant": 0})
	await _frames(4)
	_check(int(shamanka.get("max_health")) == 4, "Shamanka has 4 health")
	var buffed: bool = false
	for i: int in 600:
		await get_tree().physics_frame
		if bool(grunt.call("is_anguished")):
			buffed = true
			break
	_check(buffed, "Shamanka casts anguish on a nearby goblin")
	shamanka.queue_free()
	grunt.queue_free()
	await _frames(2)


func _charm_path() -> void:
	await _setup()
	var shamanka: Node2D = _spawn(GOBLIN, 40.0, {"variant": 3, "enemy_level": 7, "charm_gift": "goblin_pass"})
	var grunt: Node2D = _spawn(GOBLIN, 110.0, {"variant": 0})
	var bard: Node2D = _spawn(GOBLIN, 150.0, {"variant": 2, "enemy_level": 5})
	await _frames(5)
	await _charm()
	_check(bool(shamanka.call("is_charmed")), "Donut charms the Shamanka")
	_check(Inventory.count_of("goblin_pass") >= 1, "the charmed Shamanka hands over a Goblin Pass")
	await _frames(3)
	_check(bool(grunt.call("is_passive")) and bool(bard.call("is_passive")), "with the pass the workshop goblins stand down")
	var hostile: bool = await _hostile_for(bard, 240)
	_check(not hostile, "charm route: nobody fights or bombs Carl")
	_check(_bombs_in_air() == 0, "no bombs in the air on the charm route")
	for n: Node2D in [shamanka, grunt, bard]:
		n.queue_free()
	await _frames(3)


func _violence_path() -> void:
	await _setup()
	var bard: Node2D = _spawn(GOBLIN, 60.0, {"variant": 2, "enemy_level": 5})
	var shamanka: Node2D = _spawn(GOBLIN, 90.0, {"variant": 3, "enemy_level": 7})
	await _frames(4)
	for i: int in 3:
		bard.call("take_damage", 1, Vector2(30.0, 0.0))
		await _frames(14)
	for i: int in 4:
		shamanka.call("take_damage", 1, Vector2(30.0, 0.0))
		await _frames(14)
	var total: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	var expected: int = XpTable.xp_for_kill(5) + XpTable.xp_for_kill(7)
	_check(total == expected, "killing a bard and the Shamanka pays %d XP (got %d)" % [expected, total])
	await _frames(2)


func _boiler_blast() -> void:
	await _setup()
	var boiler: Node2D = PROP.instantiate() as Node2D
	boiler.set("kind", "boiler")
	boiler.position = Vector2(300.0, 0.0)
	_stage.add_child(boiler)
	var barrel: Node2D = PROP.instantiate() as Node2D
	barrel.set("kind", "barrel")
	barrel.position = Vector2(262.0, 0.0)
	_stage.add_child(barrel)
	var shamanka: Node2D = _spawn(GOBLIN, 330.0, {"variant": 3, "enemy_level": 7})
	var grunt: Node2D = _spawn(GOBLIN, 345.0, {"variant": 0})
	await _frames(4)
	var stick: Node2D = DYNAMITE.instantiate() as Node2D
	stick.set("fuse_time", 0.3)
	_stage.add_child(stick)
	stick.call("launch", Vector2(262.0, -14.0), Vector2.ZERO)
	await _frames(60)
	_check(not is_instance_valid(barrel), "dynamite sets off the funpowder barrel")
	_check(not is_instance_valid(boiler), "the barrel blast chains into the boiler")
	_check(not is_instance_valid(shamanka) or int(shamanka.get("health")) <= 0, "the boiler blast takes the Shamanka")
	_check(not is_instance_valid(grunt) or int(grunt.get("health")) <= 0, "the boiler blast takes the grunt")
	await _frames(30)


func _steam_vent() -> void:
	await _setup()
	var vent: Node2D = VENT.instantiate() as Node2D
	vent.position = Vector2(-16.0, 0.0)
	vent.set("phase", 2.9)
	_stage.add_child(vent)
	var before: int = int(_player.get("health"))
	await _frames(60)
	_check(int(_player.get("health")) < before, "a blasting steam vent hurts Carl")
	vent.queue_free()
	await _frames(2)


func _level_layout() -> void:
	await _setup()
	var level: Node = LEVEL.instantiate()
	_stage.add_child(level)
	await _frames(3)
	var bards: int = 0
	var shamankas: int = 0
	var grunts_in_workshop: int = 0
	var site: Node2D = level.get_node("WorkshopSite") as Node2D
	for node: Node in level.get_node("Goblins").get_children():
		var v: Variant = node.get("variant")
		if v == null:
			continue
		if int(v) == 2:
			bards += 1
		elif int(v) == 3:
			shamankas += 1
			_check(bool(node.get("charmable")) and str(node.get("charm_gift")).is_empty(), "workshop Shamanka is charmable but hands out no pass (it comes from Tally's box)")
		elif int(v) == 0 and (node as Node2D).global_position.x > site.global_position.x - 672.0 and (node as Node2D).global_position.x < site.global_position.x + 96.0:
			grunts_in_workshop += 1
	_check(bards == 2 and shamankas == 1, "workshop has 2 Bomb Bards and 1 Shamanka")
	_check(grunts_in_workshop == 4, "workshop has 4 grunts (%d)" % grunts_in_workshop)
	var found: Array = [false]
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void:
		if title == "Tinkerer's Pity":
			found[0] = true)
	var player: Node2D = level.get_node("Player") as Node2D
	player.global_position = site.global_position
	await _frames(6)
	_check(bool(found[0]), "workshop_found fires on entering the hall")
	level.queue_free()
	await _frames(2)
