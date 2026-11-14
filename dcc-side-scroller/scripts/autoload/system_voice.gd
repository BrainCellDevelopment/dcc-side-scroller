extends Node
## The System's voice: Floor 1 achievements, announcements, survivor counter
## and the floor timer API. Data lives in scripts/data/achievements.gd.
##
## Hooks for other scripts:
##   SystemVoice.fire("hook_id")            unlock a registry achievement
##   SystemVoice.count("stomp")             bump a counter (fires "stomp_<n>")
##   SystemVoice.announce(title, body, s, major)   corner toast; major = centre-screen banner (boss intro, floor close)
##   SystemVoice.drop_survivors(n)          the collapse beat uses this
##   SystemVoice.time_left() / begin_floor(n, seconds)
## See docs/achievement-hooks.md for the list of hooks and owners.

signal announced(title: String, body: String, seconds: float)
## Same announcement with its weight: the HUD shows major ones centre-screen and the rest as corner toasts.
signal announced_ex(title: String, body: String, seconds: float, major: bool)
signal survivors_changed(count: int)
signal survivors_visibility_changed(shown: bool)

const Achievements: GDScript = preload("res://scripts/data/achievements.gd")
const SURVIVORS_START: int = 4200000
const SURVIVORS_PER_SECOND: float = 3.0
const MANAGER_EVERY_SECONDS: float = 900.0
const FIRSTS: Dictionary = {"kill": "first_blood", "stomp": "first_smush", "death": "first_death"}
const TOGGLE_ACTION: StringName = &"toggle_survivors"

var survivors: int = SURVIVORS_START
var survivors_visible: bool = true
var floor_active: bool = false

var _counters: Dictionary = {}
var _pool_next: Dictionary = {}
var _decay_carry: float = 0.0
var _manager_timer: float = 0.0
var _warned: Dictionary = {}


func _ready() -> void:
	if not InputMap.has_action(TOGGLE_ACTION):
		InputMap.add_action(TOGGLE_ACTION)
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_V
		InputMap.action_add_event(TOGGLE_ACTION, key)
	PlayerStats.leveled_up.connect(_on_leveled_up)


func _process(delta: float) -> void:
	if not floor_active:
		return
	_decay_carry += SURVIVORS_PER_SECOND * delta
	if _decay_carry >= 1.0:
		var whole: int = int(_decay_carry)
		_decay_carry -= float(whole)
		drop_survivors(whole)
	_manager_timer += delta
	if _manager_timer >= MANAGER_EVERY_SECONDS:
		_manager_timer = 0.0
		announce_survivors()
	_check_collapse_warnings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		set_survivors_visible(not survivors_visible)


## Resets run-scoped state. Counters and unlocks persist per session.
## seconds < 0 keeps the current floor timer (Game.floor_time_left).
func begin_floor(floor_index: int = 1, seconds: float = -1.0) -> void:
	if floor_active and floor_index >= 1 and seconds < 0.0:
		return
	floor_active = floor_index >= 1
	survivors = SURVIVORS_START
	_decay_carry = 0.0
	_manager_timer = 0.0
	_warned.clear()
	if seconds >= 0.0:
		Game.floor_time_left = seconds
	survivors_changed.emit(survivors)


func end_floor() -> void:
	floor_active = false


func time_left() -> float:
	return Game.floor_time_left


func fire(hook: String) -> bool:
	var entry: Array = Achievements.entry(hook)
	if entry.is_empty():
		return false
	Game.unlock_achievement(hook, str(entry[0]), str(entry[1]))
	return true


## Bumps a named counter and fires "<name>_<n>" if the registry has it.
func count(counter_name: String, amount: int = 1) -> int:
	if not PlayerStats.active:
		return int(_counters.get(counter_name, 0))
	var total: int = int(_counters.get(counter_name, 0)) + amount
	_counters[counter_name] = total
	if total == 1 and FIRSTS.has(counter_name):
		fire(str(FIRSTS[counter_name]))
	fire("%s_%d" % [counter_name, total])
	return total


func counter_value(counter_name: String) -> int:
	return int(_counters.get(counter_name, 0))


func announce(title: String, body: String, seconds: float = 3.5, major: bool = false) -> void:
	announced.emit(title, body, seconds)
	announced_ex.emit(title, body, seconds, major)


## Returns the next line of a pool, cycling through all of them before any repeat.
func next_line(pool_name: String, pool: Array) -> String:
	if pool.is_empty():
		return ""
	var index: int = int(_pool_next.get(pool_name, 0)) % pool.size()
	_pool_next[pool_name] = index + 1
	return str(pool[index])


func announce_boss_intro(boss_name: String) -> void:
	announce(boss_name, next_line("boss_intro", Achievements.BOSS_INTRO_LINES), 3.0, true)


func announce_patch_notes() -> void:
	announce("PATCH NOTES", next_line("patch", Achievements.PATCH_NOTES), 4.0, true)


func announce_survivors() -> void:
	var line: String = next_line("manager", Achievements.MANAGER_LINES) % format_count(survivors)
	announce("4:00 AM CHECK-IN", line, 4.5)


func drop_survivors(amount: int) -> void:
	if amount <= 0:
		return
	survivors = maxi(survivors - amount, 0)
	survivors_changed.emit(survivors)


func set_survivors_visible(value: bool) -> void:
	if survivors_visible == value:
		return
	survivors_visible = value
	survivors_visibility_changed.emit(value)


static func format_count(value: int) -> String:
	var digits: String = str(value)
	var out: String = ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return out


func _check_collapse_warnings() -> void:
	for threshold: int in Achievements.COLLAPSE_LINES.keys():
		if _warned.has(threshold) or Game.floor_time_left > float(threshold):
			continue
		_warned[threshold] = true
		# Joining a run already inside a window skips the older warnings.
		if Game.floor_time_left > float(threshold) - 5.0:
			var lines: Array = Achievements.COLLAPSE_LINES[threshold]
			announce(str(lines[0]), str(lines[1]), 4.5, true)


func _on_leveled_up(level: int) -> void:
	fire("level_%d" % level)
	announce("Level Up: %d" % level, "", 3.0)
