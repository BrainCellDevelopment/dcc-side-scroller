extends Node

const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const GOBLIN: PackedScene = preload("res://scenes/enemies/goblin.tscn")
const ENGINEER: PackedScene = preload("res://scenes/enemies/engineer.tscn")
const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")

var _fails: int = 0
var _player: CharacterBody2D


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
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(0.0, -2.0)
	add_child(_player)
	_player.call("enable_spell")
	_player.set("health", 999)
	await _frames(10)
	await _charm_goblin()
	await _immune()
	await _pass_item()
	await _expiry()
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


func _spawn(scene: PackedScene, x: float, props: Dictionary = {}) -> Node2D:
	var node: Node2D = scene.instantiate() as Node2D
	node.position = Vector2(x, -2.0)
	for key: String in props:
		node.set(key, props[key])
	add_child(node)
	return node


func _charm() -> void:
	Input.action_press("charm")
	await _frames(2)
	Input.action_release("charm")
	await _frames(3)


func _hostile_for(goblin: Node2D, frames: int) -> bool:
	var health_before: int = int(_player.get("health"))
	var seen: bool = false
	for i: int in frames:
		await get_tree().physics_frame
		if int(goblin.get("state")) in [1, 2]:
			seen = true
	return seen or int(_player.get("health")) < health_before


func _charm_goblin() -> void:
	var goblin: Node2D = _spawn(GOBLIN, 40.0, {"charm_gift": "dynamite"})
	await _frames(5)
	await _charm()
	_check(bool(goblin.call("is_charmed")), "charm lands on a plain goblin in front of Carl")
	_check(goblin.is_in_group("charmed"), "charmed goblin is flagged for the HUD")
	_check(Inventory.count_of("dynamite") >= 1, "charmed goblin hands over its trade item")
	var hostile: bool = await _hostile_for(goblin, 90)
	_check(not hostile, "charmed goblin ignores Carl (no chase, no damage)")
	goblin.queue_free()
	await _frames(3)


func _immune() -> void:
	var boss: Node2D = _spawn(GOBLIN, 40.0, {"is_boss": true})
	await _frames(5)
	await _charm()
	_check(not bool(boss.call("is_charmed")), "boss goblin cannot be charmed")
	boss.queue_free()
	var marked: Node2D = _spawn(GOBLIN, 40.0, {"charmable": false})
	await _frames(5)
	await _charm()
	_check(not bool(marked.call("is_charmed")), "red-marked goblin cannot be charmed")
	marked.queue_free()
	var engineer: Node2D = _spawn(ENGINEER, 40.0)
	await _frames(5)
	await _charm()
	_check(not engineer.has_method("charm"), "engineer is immune")
	engineer.queue_free()
	await _frames(3)


func _pass_item() -> void:
	var plain: Node2D = _spawn(GOBLIN, 40.0)
	var boss: Node2D = _spawn(GOBLIN, 500.0, {"is_boss": true})
	await _frames(3)
	_check(not bool(plain.call("is_passive")), "hostile without the pass")
	ItemDefs.give("goblin_pass")
	await _frames(3)
	_check(bool(plain.call("is_passive")), "Goblin Pass makes a plain goblin neutral")
	_check(not bool(boss.call("is_passive")), "Goblin Pass does not cover a boss goblin")
	var hostile: bool = await _hostile_for(plain, 90)
	_check(not hostile, "pass-holder is ignored by plain goblin")
	Inventory.clear()
	await _frames(3)
	_check(not bool(plain.call("is_passive")), "neutrality ends when the pass leaves the bag")
	plain.queue_free()
	boss.queue_free()
	await _frames(3)


func _expiry() -> void:
	var goblin: Node2D = _spawn(GOBLIN, 40.0)
	await _frames(3)
	goblin.call("charm", 0.2)
	_check(bool(goblin.call("is_charmed")), "timed charm active")
	await _frames(30)
	_check(not bool(goblin.call("is_charmed")), "timed charm wears off")
	goblin.queue_free()
	await _frames(2)
