extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(3)


func _shot(name: String) -> void:
	if OS.get_environment("DCC_SHOT_DIR").is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [OS.get_environment("DCC_SHOT_DIR"), name])


func _unopened() -> Array[Node]:
	var out: Array[Node] = []
	for box: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(box.get("summoned")) and not bool(box.get("is_open")):
			out.append(box)
	return out


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	Game.earned_boxes = {"Bronze": 2, "Silver": 1, "Gold": 1}
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	var room: Node2D = level.get_node("FastFoodRoom") as Node2D
	var player: CharacterBody2D = level.get_node("Player") as CharacterBody2D
	player.set("health", 999)
	await _frames(10)
	player.global_position = room.global_position + Vector2(200.0, -2.0)
	await _frames(40)
	_check(_unopened().size() == 7, "seven boxes waiting in the room (%d)" % _unopened().size())
	for box: Node in _unopened():
		_check((box as Node2D).visible, "box visible inside the safe room")
		break
	player.global_position = room.global_position + Vector2(-room.get("width") * 0.5 - 400.0, -2.0)
	await _frames(40)
	_check(not Game.in_safe_zone, "left the safe room")
	var hidden: int = 0
	for box: Node in _unopened():
		if not (box as Node2D).visible:
			hidden += 1
	_check(hidden == 7, "all unopened boxes are hidden outside the safe room (%d)" % hidden)
	await _key(KEY_TAB)
	var button: Button = null
	for node: Node in get_tree().root.find_children("*", "Button", true, false):
		button = node as Button
	_check(button != null and button.disabled, "button is disabled outside a safe room")
	await _shot("button_outside")
	await _key(KEY_ESCAPE)
	player.global_position = room.global_position + Vector2(200.0, -2.0)
	await _frames(40)
	_check(_unopened().size() == 7 and (_unopened()[0] as Node2D).visible, "boxes reappear on re-entering")
	await _key(KEY_TAB)
	_check(button != null and not button.disabled and button.text.contains("(7)"), "button enabled with count: %s" % (button.text if button != null else "none"))
	await _shot("button_inside")
	var opened: Array[int] = [0]
	Game.loot_box_opened.connect(func(_t: String) -> void: opened[0] += 1)
	button.pressed.emit()
	await _frames(20)
	_check(opened[0] == 7, "button opened all seven boxes (%d)" % opened[0])
	_check(button.text.contains("(0)") and button.disabled, "button resets to zero")
	await _shot("button_after")
	await _key(KEY_ESCAPE)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
