extends Node

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")
const TIME_LIMIT: float = 1500.0
const BOT_HEALTH: int = 999
const STUCK_LIMIT: float = 25.0
const MAX_DEATHS: int = 12
const SECTION_NAMES: Array[String] = ["Surface", "Staircase", "Entrance", "Tunnels", "Arena", "Dozer arena", "Guildhall", "Complete"]
const PHASE_PLAY: int = 0
const PHASE_ARENA: int = 1
const PHASE_FIGHT: int = 2
const PHASE_AFTERMATH: int = 3
const PHASE_COMPLETE: int = 4
const STATE_PATROL: int = 1
const JUMP_LEAD: float = 0.55
const PLAYER_SPEED: float = 130.0
const DECK_TOP: float = 30.0
const DOZER_ARENA_X: int = 18432

var _level: Node
var _player: CharacterBody2D
var _dozer: Node2D
var _elapsed: float = 0.0
var _attack_timer: float = 0.0
var _jump_hold: float = 0.0
var _fight_time: float = 0.0
var _ignore_foes: float = 0.0
var _release: Array[StringName] = []
var _section: int = -1
var _section_time: float = 0.0
var _phase: int = -1
var _last_health: int = BOT_HEALTH
var _best_x: float = 0.0
var _stuck_time: float = 0.0
var _finished: bool = false
var _shot_dir: String = OS.get_environment("DCC_SHOT_DIR")
var _shots: Dictionary = {}


func _ready() -> void:
	var speed_text: String = OS.get_environment("DCC_SPEED")
	Engine.time_scale = 1.0 if speed_text.is_empty() else float(speed_text)
	if Game.has_meta("bot_elapsed"):
		_elapsed = float(Game.get_meta("bot_elapsed"))
	var start: String = OS.get_environment("DCC_START")
	if start == "fight" or start == "fight2":
		Game.set_checkpoint(7, Vector2(float(DOZER_ARENA_X) + 56.0, 912.0), 3 if start == "fight2" else 1)
	_level = LEVEL.instantiate()
	add_child(_level)
	_player = _level.get_node("Player") as CharacterBody2D
	_dozer = _level.get_node("Dozer") as Node2D
	_player.set("health", BOT_HEALTH)
	_player.connect("died", _on_died)
	Game.achievement_unlocked.connect(_on_achievement)
	Game.boss_health_changed.connect(_on_boss)
	Game.loot_box_opened.connect(_on_loot)


func _deaths() -> int:
	return int(Game.get_meta("bot_deaths")) if Game.has_meta("bot_deaths") else 0


func _log(text: String) -> void:
	print("[%7.1f] %s" % [_elapsed, text])


func _on_died() -> void:
	Game.set_meta("bot_deaths", _deaths() + 1)
	Game.set_meta("bot_elapsed", _elapsed)
	var pos: Vector2 = _player.global_position
	_log("DIED #%d at (%.0f, %.0f) section %d phase %d" % [_deaths(), pos.x, pos.y, _section, _phase])
	if _deaths() > MAX_DEATHS:
		_finish(false, "too many deaths")


func _on_achievement(title: String, _description: String) -> void:
	_log("achievement: %s" % title)


func _on_boss(boss_name: String, current: int, maximum: int) -> void:
	_log("boss %s %d/%d" % [boss_name, current, maximum])


func _on_loot(tier: String) -> void:
	_log("loot box opened: %s" % tier)


func _finish(passed: bool, text: String) -> void:
	if _finished:
		return
	_finished = true
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


func _jump(hold_time: float = 0.4) -> void:
	_jump_hold = hold_time


func _shot(label: String) -> void:
	if _shot_dir.is_empty() or _shots.has(label):
		return
	_shots[label] = true
	get_viewport().get_texture().get_image().save_png(_shot_dir.path_join(label + ".png"))


func _ray(from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 1)
	return not _player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	_section_time += delta
	_attack_timer -= delta
	_ignore_foes -= delta
	for action: StringName in _release:
		Input.action_release(action)
	_release.clear()
	if _jump_hold > 0.0:
		_jump_hold -= delta
	var pos: Vector2 = _player.global_position
	var phase: int = int(_level.get("_phase"))
	var section: int = int(_level.get("section"))
	if phase != _phase:
		_phase = phase
		_log("phase %d at (%.0f, %.0f)" % [phase, pos.x, pos.y])
	if section != _section:
		_section = section
		_section_time = 0.0
		_log("section %d %s at (%.0f, %.0f) damage so far %d" % [section, SECTION_NAMES[mini(section, 7)], pos.x, pos.y, BOT_HEALTH - int(_player.get("health"))])
	if _section_time > 1.5 and section < 7:
		_shot("sec%d" % section)
	if _elapsed > TIME_LIMIT:
		_finish(false, "timed out in section %d phase %d at (%.0f, %.0f)" % [section, phase, pos.x, pos.y])
		return
	match phase:
		PHASE_PLAY:
			_track_progress(delta, pos)
			_navigate(pos)
		PHASE_ARENA:
			_fight_arena(pos)
		PHASE_FIGHT:
			_fight(pos)
		PHASE_AFTERMATH:
			if section >= 6:
				_loot(pos)
			else:
				_track_progress(delta, pos)
				_navigate(pos)
		PHASE_COMPLETE:
			_move(0)
			if _section_time > 0.4 or section == 7:
				_shot("complete")
				_finish(true, "level 0 complete, damage taken %d" % (BOT_HEALTH - int(_player.get("health"))))
	_hold(&"jump", _jump_hold > 0.0)


func _track_progress(delta: float, pos: Vector2) -> void:
	if pos.x > _best_x + 8.0:
		_best_x = pos.x
		_stuck_time = 0.0
		return
	_stuck_time += delta
	if int(_stuck_time * 10.0) % 30 == 0 and _stuck_time > 5.0 and Engine.get_physics_frames() % 10 == 0:
		var near: String = ""
		for foe: Node2D in _foes():
			if absf(foe.global_position.x - pos.x) < 120.0:
				near += " [%s %.0f,%.0f]" % [foe.name, foe.global_position.x, foe.global_position.y]
		var hit: Dictionary = _player.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(pos + Vector2(0.0, -8.0), pos + Vector2(22.0, -8.0), 1))
		var up: Dictionary = _player.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(pos + Vector2(0.0, -20.0), pos + Vector2(0.0, -90.0), 1))
		_log("stuck dbg pos %s vel %s floor %s ctl %s jh %.2f wall %s ceil %s foes%s" % [pos, _player.velocity, _player.is_on_floor(), _player.get("control_enabled"), _jump_hold, hit.get("collider"), up.get("collider"), near])
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


func _punch(pos: Vector2, target: Node2D) -> void:
	var dx: float = target.global_position.x - pos.x
	if absf(dx) < 38.0 and absf(target.global_position.y - pos.y) < 30.0 and _attack_timer <= 0.0 and int(_player.get("facing")) == (1 if dx >= 0.0 else -1):
		_attack_timer = 0.45
		_tap(&"attack")


func _navigate(pos: Vector2) -> void:
	var on_floor: bool = _player.is_on_floor()
	var front: Node2D = null
	if _ignore_foes <= 0.0:
		for foe: Node2D in _foes():
			var dx: float = foe.global_position.x - pos.x
			if dx > -4.0 and dx < 52.0 and absf(foe.global_position.y - pos.y) < 26.0:
				front = foe
				break
	if front != null:
		_fight_time += get_physics_process_delta_time()
		if _fight_time > 4.0:
			_ignore_foes = 3.0
			_fight_time = 0.0
		_move(1 if front.global_position.x - pos.x > 30.0 else 0)
		_punch(pos, front)
		return
	_fight_time = 0.0
	_move(1)
	if on_floor and _jump_hold <= 0.0 and (_wall_ahead(pos) or _gap_ahead(pos) or _hazard_ahead(pos)):
		_jump()


func _wall_ahead(pos: Vector2, dir: int = 1) -> bool:
	return _ray(pos + Vector2(0.0, -8.0), pos + Vector2(22.0 * dir, -8.0))


func _gap_ahead(pos: Vector2, dir: int = 1) -> bool:
	return not _ray(pos + Vector2(14.0 * dir, -4.0), pos + Vector2(14.0 * dir, 56.0))


func _hazard_ahead(pos: Vector2, dir: int = 1) -> bool:
	for node: Node in get_tree().get_nodes_in_group("hazards"):
		var spikes: Node2D = node as Node2D
		if spikes == null:
			continue
		var dx: float = (spikes.global_position.x - pos.x) * dir
		if dx > 0.0 and dx < 22.0 and absf(spikes.global_position.y - pos.y) < 40.0:
			return true
	return false


func _fight_arena(pos: Vector2) -> void:
	var target: Node2D = null
	var best: float = 1.0e9
	for foe: Node2D in _foes():
		var distance: float = absf(foe.global_position.x - pos.x)
		if distance < best:
			best = distance
			target = foe
	if target == null:
		_move(0)
		return
	var dx: float = target.global_position.x - pos.x
	var direction: int = 1 if dx >= 0.0 else -1
	if absf(dx) > 24.0:
		_move(direction)
	elif int(_player.get("facing")) != direction:
		_move(direction)
	else:
		_move(0)
	_punch(pos, target)


func _fight(pos: Vector2) -> void:
	if not _dozer.visible or int(_dozer.get("state")) == 0:
		_move(0)
		return
	if Engine.get_physics_frames() % 60 == 0:
		_log("fight pos (%.0f, %.0f) dozer %.0f dir %d state %s open %s round %d" % [pos.x, pos.y, _dozer.global_position.x, int(_dozer.get("direction")), _dozer.get("state"), _dozer.get("vulnerable"), int(_dozer.get("round_index"))])
	var flying: int = get_tree().get_nodes_in_group("projectiles").size()
	if flying > 0:
		_shot("pineapple_%d" % (Engine.get_physics_frames() / 8))
	var direction: int = int(_dozer.get("direction"))
	var speeds: Array = (_dozer.get_script() as GDScript).get_script_constant_map()["PATROL_SPEEDS"]
	var vx: float = float(direction) * float(speeds[int(_dozer.get("round_index"))]) if int(_dozer.get("state")) == STATE_PATROL else 0.0
	var deck: float = _dozer.global_position.x - 10.0 * float(direction)
	var on_deck: bool = _player.is_on_floor() and pos.y < _dozer.global_position.y - 20.0 and absf(pos.x - deck) < 34.0
	if on_deck:
		_move(0)
		if _jump_hold <= 0.0:
			_jump(0.3)
		return
	var toward: int = 1 if deck > pos.x else -1
	_move(toward)
	if not _player.is_on_floor() or _jump_hold > 0.0:
		return
	var aligned: float = absf(deck + vx * JUMP_LEAD - (pos.x + float(toward) * PLAYER_SPEED * JUMP_LEAD))
	if aligned < 12.0:
		_jump(0.45)


func _walk_to(pos: Vector2, x: float, tolerance: float = 5.0) -> bool:
	var dx: float = x - pos.x
	if absf(dx) > tolerance:
		_move(1 if dx > 0.0 else -1)
		if _player.is_on_floor() and _jump_hold <= 0.0 and _wall_ahead(pos):
			_jump()
		return false
	_move(0)
	return true


func _loot(pos: Vector2) -> void:
	var guild: Node = _level.get_node("Guildhall")
	var mordecai: Node2D = guild.get_node("Mordecai")
	if not bool(mordecai.get("talked")):
		if _walk_to(pos, mordecai.global_position.x - 24.0, 8.0) and _attack_timer <= 0.0:
			_attack_timer = 0.4
			_tap(&"interact")
		return
	var target: Node2D = null
	for node: Node in guild.get_node("LootBoxes").get_children():
		if not bool(node.get("is_open")):
			target = node as Node2D
			break
	if target != null:
		_move(0)
		if _attack_timer <= 0.0:
			_attack_timer = 0.6
			_tap(&"interact")
		return
	var door: Node2D = _level.get_node("Doors/GuildEntryDoor")
	_walk_to(pos, door.global_position.x - 6.0, 4.0)
