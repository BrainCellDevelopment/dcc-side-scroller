extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const TIME_LIMIT: float = 600.0
const BOT_HEALTH: int = 999
const STUCK_LIMIT: float = 25.0
const MAX_DEATHS: int = 12
const FACING: int = -1

var _level: Node
var _player: CharacterBody2D
var _elapsed: float = 0.0
var _attack_timer: float = 0.0
var _jump_hold: float = 0.0
var _fight_time: float = 0.0
var _ignore_foes: float = 0.0
var _release: Array[StringName] = []
var _section: int = -1
var _best_x: float = 1.0e9
var _stuck_time: float = 0.0
var _finished: bool = false
var _keys: PackedStringArray = PackedStringArray()


func _ready() -> void:
	var speed_text: String = OS.get_environment("DCC_SPEED")
	Engine.time_scale = 1.0 if speed_text.is_empty() else float(speed_text)
	if Game.has_meta("bot_elapsed"):
		_elapsed = float(Game.get_meta("bot_elapsed"))
	var start: String = OS.get_environment("DCC_START")
	_level = LEVEL.instantiate()
	add_child(_level)
	_keys = _level.call("dev_sections")
	if not start.is_empty() and not Game.has_meta("bot_started"):
		Game.set_meta("bot_started", true)
		if not bool(_level.call("dev_goto", start)):
			_finish(false, "unknown DCC_START " + start)
			return
		remove_child(_level)
		_level.free()
		_level = LEVEL.instantiate()
		add_child(_level)
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", BOT_HEALTH)
	_player.connect("died", _on_died)
	Game.achievement_unlocked.connect(_on_achievement)


func _llamas_alive() -> int:
	var alive: int = 0
	for foe: Node2D in _foes():
		if foe.has_method("is_asleep"):
			alive += 1
	return alive


func _deaths() -> int:
	return int(Game.get_meta("bot_deaths")) if Game.has_meta("bot_deaths") else 0


func _log(text: String) -> void:
	print("[%7.1f] %s" % [_elapsed, text])


func _on_died() -> void:
	Game.set_meta("bot_deaths", _deaths() + 1)
	Game.set_meta("bot_elapsed", _elapsed)
	_log("DIED #%d at (%.0f, %.0f) section %d" % [_deaths(), _player.global_position.x, _player.global_position.y, _section])
	if _deaths() > MAX_DEATHS:
		_finish(false, "too many deaths")


func _on_achievement(title: String, _description: String) -> void:
	_log("achievement: %s" % title)


func _finish(passed: bool, text: String) -> void:
	if _finished:
		return
	_finished = true
	Game.clear_checkpoint()
	_log("%s: %s (deaths %d)" % ["PASS" if passed else "FAIL", text, _deaths()])
	get_tree().quit(0 if passed else 1)


func _hold(action: StringName, pressed: bool) -> void:
	if pressed and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not pressed and Input.is_action_pressed(action):
		Input.action_release(action)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	_release.append(action)


func _move(direction: int) -> void:
	_hold(&"move_left", direction < 0)
	_hold(&"move_right", direction > 0)


func _ray(from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 1)
	return not _player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	_attack_timer -= delta
	_ignore_foes -= delta
	for action: StringName in _release:
		Input.action_release(action)
	_release.clear()
	if _jump_hold > 0.0:
		_jump_hold -= delta
	var pos: Vector2 = _player.global_position
	var section: int = int(_level.get("section"))
	if section != _section:
		_section = section
		_log("section %d %s at (%.0f, %.0f)" % [section, _keys[section], pos.x, pos.y])
		if section == 1:
			_log("llama alleys left behind with %d of 2 llamas alive, health %d" % [_llamas_alive(), int(_player.get("health"))])
	if _elapsed > TIME_LIMIT:
		_finish(false, "timed out in section %d at (%.0f, %.0f)" % [section, pos.x, pos.y])
		return
	if bool(_level.get("complete")):
		_move(0)
		_finish(true, "reached the end of the stub, damage taken %d, level %d xp %d, smush %d" % [BOT_HEALTH - int(_player.get("health")), PlayerStats.character_level, PlayerStats.xp, PlayerStats.smush_count])
		return
	_track_progress(delta, pos)
	_navigate(pos)
	_hold(&"jump", _jump_hold > 0.0)


func _track_progress(delta: float, pos: Vector2) -> void:
	if pos.x < _best_x - 8.0:
		_best_x = pos.x
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if _stuck_time > STUCK_LIMIT:
		_finish(false, "stuck at (%.0f, %.0f) section %d" % [pos.x, pos.y, _section])


func _foes() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var foe: Node2D = node as Node2D
		if foe == null or foe.is_queued_for_deletion():
			continue
		var hp: Variant = foe.get("health")
		if hp != null and int(hp) <= 0:
			continue
		result.append(foe)
	return result


func _navigate(pos: Vector2) -> void:
	var front: Node2D = null
	if _ignore_foes <= 0.0:
		for foe: Node2D in _foes():
			var ahead: float = (foe.global_position.x - pos.x) * float(FACING)
			if ahead > -4.0 and ahead < 52.0 and absf(foe.global_position.y - pos.y) < 26.0:
				front = foe
				break
	if front != null:
		_fight_time += get_physics_process_delta_time()
		if _fight_time > 4.0:
			_ignore_foes = 3.0
			_fight_time = 0.0
		var dx: float = front.global_position.x - pos.x
		var toward: int = 1 if dx >= 0.0 else -1
		if absf(dx) > 30.0 or int(_player.get("facing")) != toward:
			_move(toward)
		else:
			_move(0)
		if absf(dx) < 38.0 and _attack_timer <= 0.0 and int(_player.get("facing")) == toward:
			_attack_timer = 0.45
			_tap(&"attack")
		return
	_fight_time = 0.0
	_move(FACING)
	if _player.is_on_floor() and _jump_hold <= 0.0 and (_wall_ahead(pos) or _gap_ahead(pos) or _hazard_ahead(pos)):
		_jump_hold = 0.4


func _wall_ahead(pos: Vector2) -> bool:
	return _ray(pos + Vector2(0.0, -8.0), pos + Vector2(22.0 * FACING, -8.0))


func _gap_ahead(pos: Vector2) -> bool:
	return not _ray(pos + Vector2(14.0 * FACING, -4.0), pos + Vector2(14.0 * FACING, 56.0))


func _hazard_ahead(pos: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group("hazards"):
		var spikes: Node2D = node as Node2D
		if spikes == null:
			continue
		var dx: float = pos.x - (spikes.global_position.x + float(spikes.get("width")))
		if dx > -4.0 and dx < 22.0 and absf(spikes.global_position.y - pos.y) < 40.0:
			return true
	return false
