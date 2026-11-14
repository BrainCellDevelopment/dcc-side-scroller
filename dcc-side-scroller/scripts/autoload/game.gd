extends Node

signal achievement_unlocked(title: String, description: String)
signal player_health_changed(current: int, maximum: int)
signal boss_health_changed(boss_name: String, current: int, maximum: int)
signal boss_cleared()
signal player_stamina_changed(current: int, maximum: int)
signal stamina_denied()
signal combat_changed(active: bool)
signal god_mode_changed(active: bool)
signal safe_zone_changed(active: bool)
signal loot_box_opened(tier: String)
signal hint_changed(text: String)
signal item_added(item: Dictionary)
signal screen_shake(strength: float, duration: float)
signal skin_unlocked(skin_id: String)

const FLOOR_TIME: float = 432000.0
const ACTION_DEADZONE: float = 0.5
const SAVE_PATH: String = "user://profile.cfg"
const TUTORIAL_DEATHS_FOR_SKIN: int = 5
const DEFAULT_SKIN: String = "default"
const TUTORIAL_SKIN: String = "derpy"
const ANIMS_8: Dictionary = {
	"idle": {"row": 0, "count": 8, "fps": 10.0, "loop": true},
	"run": {"row": 1, "count": 8, "fps": 16.0, "loop": true},
	"jump": {"row": 2, "count": 1, "fps": 1.0, "loop": false},
	"fall": {"row": 3, "count": 1, "fps": 1.0, "loop": false},
	"punch": {"row": 4, "count": 8, "fps": 44.0, "loop": false},
	"hurt": {"row": 5, "count": 3, "fps": 15.0, "loop": false},
	"die": {"row": 6, "count": 8, "fps": 8.0, "loop": false},
}
const ANIMS_4: Dictionary = {
	"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true},
	"run": {"row": 1, "count": 6, "fps": 12.0, "loop": true},
	"jump": {"row": 2, "count": 1, "fps": 1.0, "loop": false},
	"fall": {"row": 3, "count": 1, "fps": 1.0, "loop": false},
	"punch": {"row": 4, "count": 4, "fps": 22.0, "loop": false},
	"hurt": {"row": 5, "count": 1, "fps": 1.0, "loop": false},
	"die": {"row": 6, "count": 4, "fps": 8.0, "loop": false},
}
const SKINS: Dictionary = {
	"default": {"name": "Carl", "sheet": "res://assets/characters/carl.png", "frame": Vector2i(136, 136), "scale": 0.5, "anims": ANIMS_8},
	"derpy": {"name": "Derpy Carl", "sheet": "res://assets/characters/skins/carl_derpy.png", "frame": Vector2i(64, 56), "scale": 1.0, "anims": ANIMS_4},
}

var in_combat: bool = false
var god_mode: bool = false
var in_safe_zone: bool = false
var floor_time_left: float = FLOOR_TIME
var checkpoint_index: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_stage: int = 0

var items: Array[Dictionary] = []
var unlocked_skins: Array[String] = [DEFAULT_SKIN]
var selected_skin: String = DEFAULT_SKIN
var tutorial_death_streak: int = 0

var _engaged_enemies: int = 0
var _unlocked: Dictionary = {}


func _ready() -> void:
	_register_inputs()
	_load_profile()


func _process(delta: float) -> void:
	floor_time_left = maxf(floor_time_left - delta, 0.0)


func unlock_achievement(id: String, title: String, description: String) -> void:
	if _unlocked.has(id):
		return
	_unlocked[id] = true
	achievement_unlocked.emit(title, description)


func enemy_engaged() -> void:
	_engaged_enemies += 1
	_refresh_combat()


func enemy_disengaged() -> void:
	_engaged_enemies = maxi(_engaged_enemies - 1, 0)
	_refresh_combat()


func set_god_mode(active: bool) -> void:
	if god_mode == active:
		return
	god_mode = active
	god_mode_changed.emit(active)


func set_safe_zone(active: bool) -> void:
	if in_safe_zone == active:
		return
	in_safe_zone = active
	safe_zone_changed.emit(active)


func report_player_health(current: int, maximum: int) -> void:
	player_health_changed.emit(current, maximum)


func report_player_stamina(current: int, maximum: int) -> void:
	player_stamina_changed.emit(current, maximum)


func deny_stamina() -> void:
	stamina_denied.emit()


func report_boss_health(boss_name: String, current: int, maximum: int) -> void:
	boss_health_changed.emit(boss_name, current, maximum)


func clear_boss() -> void:
	boss_cleared.emit()


func report_loot_box_opened(tier: String) -> void:
	loot_box_opened.emit(tier)


func add_item(id: String, item_name: String, tier: String = "") -> void:
	var item: Dictionary = {"id": id, "name": item_name, "tier": tier}
	items.append(item)
	item_added.emit(item)


func has_item(id: String) -> bool:
	for item: Dictionary in items:
		if str(item["id"]) == id:
			return true
	return false


func set_hint(text: String) -> void:
	hint_changed.emit(text)


func shake(strength: float, duration: float) -> void:
	screen_shake.emit(strength, duration)


func set_checkpoint(index: int, pos: Vector2, stage: int = 0) -> void:
	if index < checkpoint_index:
		return
	checkpoint_index = index
	checkpoint_position = pos
	checkpoint_stage = stage


func clear_checkpoint() -> void:
	checkpoint_index = -1
	checkpoint_position = Vector2.ZERO
	checkpoint_stage = 0


func reset_run() -> void:
	_engaged_enemies = 0
	_refresh_combat()
	set_safe_zone(false)
	floor_time_left = FLOOR_TIME
	items.clear()
	set_hint("")


func skin_sheet() -> Texture2D:
	return load(str(SKINS[selected_skin]["sheet"])) as Texture2D


func skin_frame() -> Vector2i:
	return SKINS[selected_skin]["frame"] as Vector2i


func skin_scale() -> float:
	return float(SKINS[selected_skin]["scale"])


func skin_anims() -> Dictionary:
	return SKINS[selected_skin]["anims"] as Dictionary


func register_tutorial_death() -> bool:
	if selected_skin != DEFAULT_SKIN:
		selected_skin = DEFAULT_SKIN
		tutorial_death_streak = 1
		_save_profile()
		return false
	tutorial_death_streak += 1
	if tutorial_death_streak < TUTORIAL_DEATHS_FOR_SKIN:
		_save_profile()
		return false
	tutorial_death_streak = 0
	unlock_skin(TUTORIAL_SKIN)
	return true


func register_tutorial_complete() -> void:
	selected_skin = DEFAULT_SKIN
	tutorial_death_streak = 0
	_save_profile()


func unlock_skin(skin_id: String) -> bool:
	if not SKINS.has(skin_id):
		return false
	var first_time: bool = not unlocked_skins.has(skin_id)
	if first_time:
		unlocked_skins.append(skin_id)
	selected_skin = skin_id
	_save_profile()
	skin_unlocked.emit(skin_id)
	if first_time:
		unlock_achievement("skin_" + skin_id, "Slow Learner", "Five deaths in a row in the tutorial. Unlocked look: %s." % str(SKINS[skin_id]["name"]))
	return true


func select_skin(skin_id: String) -> bool:
	if not SKINS.has(skin_id) or not unlocked_skins.has(skin_id):
		return false
	selected_skin = skin_id
	_save_profile()
	return true


func reset_profile() -> void:
	unlocked_skins = [DEFAULT_SKIN]
	selected_skin = DEFAULT_SKIN
	tutorial_death_streak = 0
	_save_profile()


func _load_profile() -> void:
	if OS.has_environment("DCC_NO_SAVE"):
		return
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for skin_id: Variant in config.get_value("skins", "unlocked", [DEFAULT_SKIN]):
		if SKINS.has(str(skin_id)) and not unlocked_skins.has(str(skin_id)):
			unlocked_skins.append(str(skin_id))
	tutorial_death_streak = int(config.get_value("progress", "tutorial_death_streak", 0))


func _save_profile() -> void:
	if OS.has_environment("DCC_NO_SAVE"):
		return
	var config: ConfigFile = ConfigFile.new()
	config.set_value("skins", "unlocked", unlocked_skins)
	config.set_value("progress", "tutorial_death_streak", tutorial_death_streak)
	config.save(SAVE_PATH)


func _refresh_combat() -> void:
	var active: bool = _engaged_enemies > 0
	if active == in_combat:
		return
	in_combat = active
	combat_changed.emit(active)


func _register_inputs() -> void:
	var move_left_events: Array[InputEvent] = [
		_key(KEY_A),
		_key(KEY_LEFT),
		_joy_button(JOY_BUTTON_DPAD_LEFT),
		_joy_axis(JOY_AXIS_LEFT_X, -1.0),
	]
	var move_right_events: Array[InputEvent] = [
		_key(KEY_D),
		_key(KEY_RIGHT),
		_joy_button(JOY_BUTTON_DPAD_RIGHT),
		_joy_axis(JOY_AXIS_LEFT_X, 1.0),
	]
	var jump_events: Array[InputEvent] = [
		_key(KEY_SPACE),
		_key(KEY_W),
		_key(KEY_UP),
		_joy_button(JOY_BUTTON_A),
	]
	var attack_events: Array[InputEvent] = [
		_key(KEY_J),
		_key(KEY_X),
		_joy_button(JOY_BUTTON_X),
	]
	var sprint_events: Array[InputEvent] = [
		_key(KEY_SHIFT),
		_joy_button(JOY_BUTTON_RIGHT_SHOULDER),
	]
	var interact_events: Array[InputEvent] = [
		_key(KEY_E),
		_joy_button(JOY_BUTTON_Y),
	]
	_add_action(&"move_left", move_left_events)
	_add_action(&"move_right", move_right_events)
	_add_action(&"jump", jump_events)
	_add_action(&"attack", attack_events)
	_add_action(&"sprint", sprint_events)
	_add_action(&"interact", interact_events)


func _add_action(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, ACTION_DEADZONE)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	return event


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	return event


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
