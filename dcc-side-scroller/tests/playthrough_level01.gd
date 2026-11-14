extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const TIME_LIMIT: float = 600.0
const BOT_HEALTH: int = 999
const STUCK_LIMIT: float = 25.0
const MAX_DEATHS: int = 12
const FACING: int = -1
const DOOR_STANDOFF: float = 100.0
const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")

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
var _throw_wait: float = 0.5
var _boss_log: float = 0.0
var _finished: bool = false
var _room_seen: bool = Game.has_meta("bot_room_seen")
var _keys: PackedStringArray = PackedStringArray()
var _swine_logged: bool = false
var _swine_tick: int = -1


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
	if section == 2 and Game.in_safe_zone and not _room_seen:
		_room_seen = true
		Game.set_meta("bot_room_seen", true)
		_log("safe room entered, checkpoint %d, health %d" % [Game.checkpoint_index, int(_player.get("health"))])
	if section >= 3 and not _room_seen and not Game.has_meta("bot_started"):
		_finish(false, "left the safe room section without entering the room")
		return
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


func _boss_fight_on() -> bool:
	for foe: Node2D in _foes():
		if foe.get("is_boss") == true and foe.get("active") == true:
			return true
	return false


# Stops short of a sealed door and throws dynamite until it opens. True while it is handling the door.
func _blast_door_step(pos: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group("destructibles"):
		var door: Node2D = node as Node2D
		if door == null or bool(door.get("is_open")):
			continue
		var ahead: float = (door.global_position.x - pos.x) * float(FACING)
		if ahead < 0.0 or ahead > 150.0 or absf(door.global_position.y - pos.y) > 40.0:
			continue
		if ahead > DOOR_STANDOFF:
			return false
		_move(0)
		if int(_player.get("facing")) != FACING:
			_move(FACING)
			return true
		_throw_wait -= get_physics_process_delta_time()
		if _throw_wait <= 0.0:
			if Explosives.stack_count() <= 0:
				_finish(false, "no dynamite left at the sealed door")
				return true
			_log("throwing dynamite at the sealed door")
			_throw_wait = 2.5
			_tap(&"throw")
		return true
	return false


func _track_progress(delta: float, pos: Vector2) -> void:
	if _boss_fight_on():
		_stuck_time = 0.0
		_boss_log -= delta
		if _boss_log <= 0.0:
			_boss_log = 10.0
			var boss: Node = _level.get_node_or_null("Bosses/Hoarder")
			if boss != null:
				_log("Hoarder health %d/%d state %d at %.0f, player health %d at %.0f facing %d" % [int(boss.get("health")), int(boss.get("max_health")), int(boss.get("state")), (boss as Node2D).global_position.x, int(_player.get("health")), _player.global_position.x, int(_player.get("facing"))])
		return
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
	var arena: Node2D = get_tree().get_first_node_in_group("swine_arena") as Node2D
	if arena != null and bool(arena.get("started")) and not bool(arena.get("won")):
		_swine(pos, arena)
		return
	var front: Node2D = null
	if _ignore_foes <= 0.0:
		for foe: Node2D in _foes():
			var ahead: float = (foe.global_position.x - pos.x) * float(FACING)
			var behind: float = -80.0 if foe.get("is_boss") == true and foe.get("active") == true else -4.0
			if ahead > behind and ahead < 52.0 and absf(foe.global_position.y - pos.y) < 26.0:
				if front == null:
					front = foe
				if foe.is_in_group("hoarder_roach"):
					front = foe
					break
	if front != null:
		if front.get("is_boss") != true and not front.is_in_group("hoarder_roach"):
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
	if _blast_door_step(pos):
		return
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


func _toward(pos: Vector2, x: float) -> int:
	return 1 if x >= pos.x else -1


func _walk_to(pos: Vector2, x: float) -> void:
	var direction: int = _toward(pos, x)
	_move(direction)
	if _player.is_on_floor() and _jump_hold <= 0.0 and _ray(pos + Vector2(0.0, -8.0), pos + Vector2(22.0 * float(direction), -8.0)):
		_jump_hold = 0.14


# Ball of Swine: build the Speedbump fortress with E, wait for the wedge, then punch it.
func _swine(pos: Vector2, arena: Node2D) -> void:
	_stuck_time = 0.0
	var ball: Node2D = arena.get("boss") as Node2D
	var fort: Node2D = arena.get("fortress") as Node2D
	if ball == null or not is_instance_valid(ball) or not bool(ball.get("active")):
		_move(0)
		return
	if not _swine_logged:
		_swine_logged = true
		_log("Ball of Swine fight: building the fortress")
	if bool(ball.call("is_vulnerable")):
		var dx: float = ball.global_position.x - pos.x
		var toward: int = _toward(pos, ball.global_position.x)
		if absf(dx) > 34.0:
			_walk_to(pos, ball.global_position.x)
		else:
			_move(0)
			if int(_player.get("facing")) != toward:
				_move(toward)
			elif _attack_timer <= 0.0:
				_attack_timer = 0.45
				_tap(&"attack")
		return
	if pos.y < arena.global_position.y - 40.0:
		_move(1 if pos.x > arena.global_position.x else -1)
		return
	if int(_elapsed) % 5 == 0 and int(_elapsed) != _swine_tick:
		_swine_tick = int(_elapsed)
		_log("swine: ball state %d lane %d hp %d, bot x %.0f carrying %s placed %d" % [int(ball.get("state")), int(ball.get("lane")), int(ball.get("health")), pos.x, str(fort.call("is_carrying")), int(fort.call("placed_count"))])
	var target_x: float = INF
	if bool(fort.call("is_carrying")):
		var sockets: Array[int] = fort.call("empty_socket_indices")
		if not sockets.is_empty():
			target_x = (fort.call("socket_position", sockets[0]) as Vector2).x
	else:
		var pieces: Array[int] = fort.call("free_piece_indices")
		if not pieces.is_empty():
			target_x = (fort.call("piece_position", pieces[0]) as Vector2).x
	if target_x == INF:
		_move(0)
		return
	if absf(target_x - pos.x) < 12.0 and _player.is_on_floor():
		_move(0)
		if _attack_timer <= 0.0:
			_attack_timer = 0.5
			_tap(&"interact")
		return
	_walk_to(pos, target_x)
