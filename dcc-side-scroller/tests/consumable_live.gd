extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")

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


func _ready() -> void:
	add_child(LEVEL.instantiate())
	await _frames(30)
	var player: Node = get_tree().get_first_node_in_group("player")
	print("floor active: ", PlayerStats.active, " hp ", player.get("health"), "/", player.get("max_health"))
	Inventory.add_item("healing_potion", "Healing Potion", "Bronze", 3, ItemDefs.extra("healing_potion"))
	player.set("health", 3)
	Game.report_player_health(3, int(player.get("max_health")))
	Inventory.assign_hotbar(0, "healing_potion")
	await _frames(5)
	await _key(KEY_1)
	_check(int(player.get("health")) == 9, "hotbar key 1 heals 6 (hp %d)" % int(player.get("health")))
	_check(Inventory.count_of("healing_potion") == 2, "potion consumed from hotbar (%d left)" % Inventory.count_of("healing_potion"))
	player.set("health", 2)
	await _key(KEY_TAB)
	await _key(KEY_E)
	_check(int(player.get("health")) == 8, "menu E heals 6 (hp %d)" % int(player.get("health")))
	await _shot("hotbar_menu_open")
	await _key(KEY_ESCAPE)
	await _shot("hotbar_closed")
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
