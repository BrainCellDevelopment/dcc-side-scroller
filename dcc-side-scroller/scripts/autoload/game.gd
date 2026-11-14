extends Node

signal achievement_unlocked(title: String, description: String)
signal player_health_changed(current: int, maximum: int)
signal boss_health_changed(boss_name: String, current: int, maximum: int)
signal boss_cleared()
signal combat_changed(active: bool)
signal safe_zone_changed(active: bool)
signal loot_box_opened(tier: String)
signal hint_changed(text: String)
signal item_added(item: Dictionary)
signal screen_shake(strength: float, duration: float)

const FLOOR_TIME: float = 432000.0
const WORLD_SCALE: float = 1.25
const ACTION_DEADZONE: float = 0.5

var in_combat: bool = false
var in_safe_zone: bool = false
var floor_time_left: float = FLOOR_TIME
var checkpoint_index: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_stage: int = 0

var items: Array[Dictionary] = []

var _engaged_enemies: int = 0
var _unlocked: Dictionary = {}


func _ready() -> void:
	_register_inputs()


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


func set_safe_zone(active: bool) -> void:
	if in_safe_zone == active:
		return
	in_safe_zone = active
	safe_zone_changed.emit(active)


func report_player_health(current: int, maximum: int) -> void:
	player_health_changed.emit(current, maximum)


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
	var interact_events: Array[InputEvent] = [
		_key(KEY_E),
		_joy_button(JOY_BUTTON_Y),
	]
	_add_action(&"move_left", move_left_events)
	_add_action(&"move_right", move_right_events)
	_add_action(&"jump", jump_events)
	_add_action(&"attack", attack_events)
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
