extends Node

const DOOR: PackedScene = preload("res://scenes/props/bathroom_door.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")

var _fails: int = 0
var _door: Node2D
var _player: CharacterBody2D
var _unlocks: int = 0


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	Game.achievement_unlocked.connect(func(_t: String, _d: String) -> void: _unlocks += 1)
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
	_door = DOOR.instantiate() as Node2D
	_door.set("hidden_item_id", "closet_roll")
	_door.set("hidden_item_name", "Emergency Toilet Paper")
	_door.position = Vector2(200.0, 0.0)
	add_child(_door)
	_player = PLAYER.instantiate() as CharacterBody2D
	_player.position = Vector2(0.0, -2.0)
	add_child(_player)
	await _frames(10)
	await _far_away_does_nothing()
	await _enter_and_leave()
	await _second_visit()
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
	await _frames(1)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(3)


func _far_away_does_nothing() -> void:
	await _tap()
	_check(not bool(_door.get("inside")), "interact far from the door does nothing")


func _enter_and_leave() -> void:
	_player.global_position = Vector2(200.0, -2.0)
	await _frames(10)
	_player.set("health", 6)
	var health: int = int(_player.get("health"))
	await _tap()
	_check(bool(_door.get("inside")), "interact opens the closet")
	_check(not _player.visible, "player is hidden inside")
	_check(not bool(_player.get("control_enabled")), "player control is off inside")
	_check(Game.in_safe_zone, "enemies leave the player alone inside")
	_check(_unlocks == 1, "achievement fires on first entry")
	var closet: Node = _find_closet()
	_check(closet != null, "closet scene is present")
	_check(closet != null and closet.get_node("SystemLine").text == "Your views just dropped. Nobody wants this.", "System line is shown")
	await _tap()
	_check(bool(_door.get("inside")), "leaving is blocked until the fade-in is over")
	await get_tree().create_timer(1.0).timeout
	await _tap()
	await get_tree().create_timer(0.8).timeout
	_check(not bool(_door.get("inside")), "interact leaves the closet")
	_check(_player.visible, "player is visible again")
	_check(bool(_player.get("control_enabled")), "player control is restored")
	_check(not Game.in_safe_zone, "safe-zone flag is restored")
	_check(int(_player.get("health")) == health, "health is unchanged by the visit")
	_check(_find_closet() == null, "closet scene is removed")
	_check(Inventory.has_item("closet_roll"), "hidden item is taken once")
	_check(_unlocks == 1, "achievement did not fire again on leaving")


func _second_visit() -> void:
	await get_tree().create_timer(0.8).timeout
	await _tap()
	_check(bool(_door.get("inside")), "the door can be used again")
	await get_tree().create_timer(1.0).timeout
	await _tap()
	await get_tree().create_timer(0.8).timeout
	_check(not bool(_door.get("inside")), "left the closet a second time")
	_check(_unlocks == 1, "achievement fires only once")
	var count: int = 0
	for slot: Dictionary in Inventory.slots:
		if not slot.is_empty() and str(slot["id"]) == "closet_roll":
			count += int(slot["count"])
	_check(count == 1, "hidden item is not handed out twice")


func _find_closet() -> Node:
	for node: Node in get_children():
		if node is CanvasLayer and node.has_node("SystemLine"):
			return node
	return null
