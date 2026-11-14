extends Node

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")

var _level: Node2D
var _fails: int = 0
var _shot_dir: String = OS.get_environment("DCC_SHOT_DIR")


func _ready() -> void:
	Game.set_checkpoint(8, Vector2(19384.0, 912.0), 2)
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(30)
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


func _tap() -> void:
	Input.action_press("interact")
	await _frames(3)
	Input.action_release("interact")
	await _frames(4)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(3)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shot_dir, name])


func _filled() -> int:
	return Inventory.slots.filter(func(x: Dictionary) -> bool: return not x.is_empty()).size()


func _run() -> void:
	var mord: Area2D = _level.get_node("Guildhall/Mordecai")
	var player: CharacterBody2D = _level.get_node("Player")
	player.global_position = mord.global_position + Vector2(30.0, -2.0)
	await _frames(20)
	for i: int in 4:
		await _tap()
	await _frames(200)
	await _tap()
	await _tap()
	await _frames(60)
	_check(_filled() == 2, "two items looted (%d)" % _filled())
	PlayerStats.enter_floor(1)
	var cha_before: int = PlayerStats.get_stat("charisma")
	var int_before: int = PlayerStats.get_stat("intelligence")
	await _key(KEY_TAB)
	_check(Game.menu_open and not get_tree().paused, "Tab opens menu without pausing")
	var x_before: float = player.global_position.x
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	_check(absf(player.global_position.x - x_before) < 1.0, "player ignores movement while menu is open")
	await _shot("1_open")
	await _key(KEY_RIGHT)
	await _shot("2_second_slot")
	await _key(KEY_E)
	await _shot("3_equipped")
	_check(_filled() == 1, "equipping moves item out of grid (%d)" % _filled())
	var worn: int = 0
	for s: String in Inventory.EQUIP_SLOTS:
		if not Inventory.equipped[s].is_empty():
			worn += 1
	_check(worn == 1, "one item worn (%d)" % worn)
	_check(not Inventory.equipped["head"].is_empty(), "biscuit worn on head")
	_check(PlayerStats.get_stat("charisma") == cha_before + 3, "biscuit gives +3 charisma (%d -> %d)" % [cha_before, PlayerStats.get_stat("charisma")])
	_check(PlayerStats.get_stat("intelligence") == int_before + 2, "biscuit gives +2 intelligence")
	await _key(KEY_Q)
	await _shot("4_doll_focus")
	await _key(KEY_E)
	await _shot("5_unequipped")
	_check(_filled() == 2, "unequip returns item (%d)" % _filled())
	_check(PlayerStats.get_stat("charisma") == cha_before and PlayerStats.get_stat("intelligence") == int_before, "bonus removed")
	await _key(KEY_Q)
	await _key(KEY_Q)
	await _key(KEY_2)
	_check(Inventory.hotbar[1] == "legendary_pet_biscuit", "key 2 assigns selected item to hotbar slot 2")
	await _shot("6_hotbar_assigned")
	await _key(KEY_ESCAPE)
	_check(not Game.menu_open, "Esc closes menu")
	await _key(KEY_2)
	_check(Inventory.is_equipped("legendary_pet_biscuit"), "hotbar key equips item")
	_check(PlayerStats.get_stat("charisma") == cha_before + 3, "hotbar equip applies bonus")
	await _shot("7_hotbar_equipped")
	await _frames(20)
	await _key(KEY_2)
	_check(not Inventory.is_equipped("legendary_pet_biscuit"), "hotbar key again unequips")
