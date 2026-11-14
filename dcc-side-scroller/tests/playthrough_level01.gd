extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const TIME_LIMIT: float = 600.0
# Pacing: bot seconds to first-time-player seconds. The bot never reads text, never stops to look and never
# misjudges a jump, so walking and small fights take a human about 3 to 5 times as long. Boss fights are paced
# by the boss's own timers, so a human needs about 1.5 to 2 times the bot. The hand-off is text, about 2 times.
const WALK_FACTOR: Vector2 = Vector2(3.0, 5.0)
const BOSS_FACTOR: Vector2 = Vector2(1.5, 2.0)
const TEXT_FACTOR: Vector2 = Vector2(1.5, 2.5)
const SECTION_NAMES: PackedStringArray = ["tunnel", "rats", "saferoom", "hoarder", "workshop", "swine", "collapse", "handoff"]
# The bot plays with the health the game gives it. DCC_BOT_HEALTH only exists to debug later sections.
const HEAL_BELOW: int = 4
const FACING: int = -1
const BOX_PATIENCE: float = 20.0
const STUCK_LIMIT: float = 25.0
const MAX_DEATHS: int = 12
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
var _stage: int = 0
var _stage_time: float = 0.0
var _carry_health: int = 0
var _stats: Dictionary = {}
var _last_hp: int = -1
var _potion_cooldown: float = 0.0
var _room_wait: float = 0.0
var _room_done: bool = Game.has_meta("bot_room_done")
var _shot_dir: String = OS.get_environment("DCC_SHOT_DIR")
var _shot_label: String = ""
var _shot_wait: float = 0.0
var _shots: Dictionary = {}
var _swine_hp: int = -1


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
	FloorHandoff.scene_changer = Callable(self, "_swap")
	_player = _level.get_node("Player") as CharacterBody2D
	var health_text: String = OS.get_environment("DCC_BOT_HEALTH")
	if not health_text.is_empty():
		_player.set("health", int(health_text))
	_stats = _load_stats()
	_last_hp = int(_player.get("health"))
	Game.player_health_changed.connect(_on_health)
	_player.connect("died", _on_died)
	Game.achievement_unlocked.connect(_on_achievement)


func _load_stats() -> Dictionary:
	if not Game.has_meta("bot_stats"):
		var fresh: Dictionary = {}
		for key: String in SECTION_NAMES:
			fresh[key] = {"time": 0.0, "dmg": 0, "heal_potion": 0, "heal_room": 0, "heal_regen": 0, "deaths": 0, "hp_in": -1, "hp_out": -1, "low": 99, "potions": 0}
		Game.set_meta("bot_stats", fresh)
	return Game.get_meta("bot_stats") as Dictionary


func _unopened_boxes() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(node.get("summoned")) and not bool(node.get("is_open")):
			count += 1
	return count


func _total_damage() -> int:
	var total: int = 0
	for key: String in SECTION_NAMES:
		total += int((_stats[key] as Dictionary)["dmg"])
	return total


func _row() -> Dictionary:
	var key: String = SECTION_NAMES[clampi(_section, 0, SECTION_NAMES.size() - 1)] if _stage == 0 else "handoff"
	return _stats[key] as Dictionary


func _on_health(current: int, _maximum: int) -> void:
	var previous: int = _last_hp
	_last_hp = current
	if not _stats.is_empty() and current > 0:
		_row()["low"] = mini(int(_row()["low"]), current)
	if previous <= 0 or _stats.is_empty():
		return
	var row: Dictionary = _row()
	if current < previous:
		row["dmg"] = int(row["dmg"]) + previous - current
	elif Game.in_safe_zone:
		row["heal_room"] = int(row["heal_room"]) + current - previous
	elif _potion_cooldown > 0.0:
		row["heal_potion"] = int(row["heal_potion"]) + current - previous
	else:
		row["heal_regen"] = int(row["heal_regen"]) + current - previous


func _shot(label: String) -> void:
	if _shot_dir.is_empty() or _shots.has(label):
		return
	_shots[label] = true
	var image: Image = get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(_shot_dir.path_join(label + ".png"))


func _report() -> void:
	_log("section report (bot seconds, real damage taken, healing by source, deaths, health in/out):")
	var total_time: float = 0.0
	var total_dmg: int = 0
	for key: String in SECTION_NAMES:
		var row: Dictionary = _stats[key]
		total_time += float(row["time"])
		total_dmg += int(row["dmg"])
		_log("  %-9s %6.1fs  dmg %2d  healed potion %d room %d regen %d  deaths %d  hp %d -> %d (low %d)" % [key, float(row["time"]), int(row["dmg"]), int(row["heal_potion"]), int(row["heal_room"]), int(row["heal_regen"]), int(row["deaths"]), int(row["hp_in"]), int(row["hp_out"]), int(row["low"])])
	var low: float = 0.0
	var high: float = 0.0
	for key: String in SECTION_NAMES:
		var seconds: float = float((_stats[key] as Dictionary)["time"])
		var factor: Vector2 = BOSS_FACTOR if key == "hoarder" or key == "swine" else (TEXT_FACTOR if key == "handoff" else WALK_FACTOR)
		low += seconds * factor.x
		high += seconds * factor.y
	_log("  total     %6.1fs  dmg %2d; first-time player estimate %.1f to %.1f minutes (walk x%.0f-%.0f, boss x%.1f-%.1f, text x%.1f-%.1f)" % [total_time, total_dmg, low / 60.0, high / 60.0, WALK_FACTOR.x, WALK_FACTOR.y, BOSS_FACTOR.x, BOSS_FACTOR.y, TEXT_FACTOR.x, TEXT_FACTOR.y])


func _llamas_alive() -> int:
	var alive: int = 0
	for foe: Node2D in _foes():
		if foe.has_method("is_asleep"):
			alive += 1
	return alive


func _count_variant(variant: int) -> int:
	var alive: int = 0
	for foe: Node2D in _foes():
		var v: Variant = foe.get("variant")
		if v != null and int(v) == variant:
			alive += 1
	return alive


func _deaths() -> int:
	return int(Game.get_meta("bot_deaths")) if Game.has_meta("bot_deaths") else 0


func _log(text: String) -> void:
	print("[%7.1f] %s" % [_elapsed, text])


func _on_died() -> void:
	Game.set_meta("bot_deaths", _deaths() + 1)
	_row()["deaths"] = int(_row()["deaths"]) + 1
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
	_report()
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
	if _stage > 0:
		_hand_off(delta)
		return
	var pos: Vector2 = _player.global_position
	var section: int = int(_level.get("section"))
	if section != _section:
		if _section >= 0:
			_row()["hp_out"] = int(_player.get("health"))
		_section = section
		_row()["hp_in"] = int(_player.get("health"))
		_log("section %d %s at (%.0f, %.0f), health %d/%d, potions %d, dynamite %d, unopened boxes %d" % [section, _keys[section], pos.x, pos.y, int(_player.get("health")), int(_player.get("max_health")), Inventory.count_of("healing_potion"), Explosives.stack_count(), _unopened_boxes()])
		_shot_label = "%d_%s" % [section, _keys[section]]
		_shot_wait = 1.5
		if section == 1:
			_log("llama alleys left behind with %d of 2 llamas alive, health %d" % [_llamas_alive(), int(_player.get("health"))])
		if section == 5:
			_log("workshop left behind with %d of 2 bomb bards and %d of 1 shamanka alive" % [_count_variant(2), _count_variant(3)])
	_row()["time"] = float(_row()["time"]) + delta
	if _shot_wait > 0.0:
		_shot_wait -= delta
		if _shot_wait <= 0.0:
			_shot(_shot_label)
	_potion_cooldown = maxf(_potion_cooldown - delta, 0.0)
	_manage_items(delta)
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
		_log("Floor 1 complete: collapse beat running, health %d/%d, level %d xp %d, smush %d" % [int(_player.get("health")), int(_player.get("max_health")), PlayerStats.character_level, PlayerStats.xp, PlayerStats.smush_count])
		_shot("6_collapse_end")
		_row()["hp_out"] = int(_player.get("health"))
		_stage = 1
		return
	_track_progress(delta, pos)
	if _room_step(delta):
		_hold(&"jump", false)
		return
	_navigate(pos)
	_hold(&"jump", _jump_hold > 0.0)


# What a player would do with the bag: wear gear, eat cookies, drink a healing potion when low.
func _manage_items(_delta: float) -> void:
	for i: int in Inventory.slots.size():
		var item: Dictionary = Inventory.slots[i]
		if item.is_empty():
			continue
		var slot_name: String = str(item.get("slot", ""))
		if not slot_name.is_empty() and Inventory.equipped.get(slot_name, {}).is_empty():
			if Inventory.equip_from(i):
				_log("equipped %s" % str(item.get("name", item["id"])))
				return
	if Game.in_safe_zone and Inventory.count_of("experience_cookie") > 0:
		_use("experience_cookie")
	var hp: int = int(_player.get("health"))
	if hp > 0 and hp <= HEAL_BELOW and _potion_cooldown <= 0.0 and Inventory.count_of("healing_potion") > 0:
		_use("healing_potion")


func _use(item_id: String) -> void:
	for i: int in Inventory.slots.size():
		if not Inventory.slots[i].is_empty() and str(Inventory.slots[i]["id"]) == item_id:
			_potion_cooldown = 0.2
			var before: int = int(_player.get("health"))
			if Inventory.use_item(i):
				_row()["potions"] = int(_row()["potions"]) + 1
				_log("used %s, health %d -> %d, level %d xp %d" % [item_id, before, int(_player.get("health")), PlayerStats.character_level, PlayerStats.xp])
			return


# Safe room: stand still and open every loot box (E), the way a player would, before moving on.
func _room_step(delta: float) -> bool:
	if _room_done or _section != 2 or not Game.in_safe_zone:
		return false
	_move(0)
	_room_wait += delta
	var waiting: int = 0
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(node.get("summoned")) and not bool(node.get("is_open")):
			waiting += 1
	if _room_wait > 1.0 and waiting > 0 and _room_wait < BOX_PATIENCE and fmod(_room_wait, 0.8) < delta:
		_tap(&"interact")
	if (waiting == 0 and _room_wait > 3.0) or _room_wait >= BOX_PATIENCE:
		_log("safe room done after %.1fs: %d boxes left, bag potions %d mana potions %d toast %d dynamite %d, health %d/%d" % [_room_wait, waiting, Inventory.count_of("healing_potion"), Inventory.count_of("mana_potion"), Inventory.count_of("mana_toast"), Explosives.stack_count(), int(_player.get("health")), int(_player.get("max_health"))])
		_room_done = true
		Game.set_meta("bot_room_done", true)
		if OS.get_environment("DCC_BOT_LOOT") == "none":
			_strip_consumables()
		return false
	return true


# Debug knob for the worst-case measurement: the box rolls came up empty.
func _strip_consumables() -> void:
	for i: int in Inventory.slots.size():
		var item: Dictionary = Inventory.slots[i]
		if not item.is_empty() and str(item.get("use", "")) == "heal":
			Inventory.remove_at(i, int(item["count"]))
	_log("DCC_BOT_LOOT=none: healing potions dropped from the bag")


func _boss_fight_on() -> bool:
	for foe: Node2D in _foes():
		if foe.get("is_boss") == true and foe.get("active") == true:
			return true
	return false


# Stops short of a sealed door and throws dynamite until it opens. True while it is handling the door.
func _blast_door_step(pos: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group("destructibles"):
		var door: Node2D = node as Node2D
		if door == null or door.get("is_open") != false:
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


# Stand-in for SceneTree.change_scene_to_file: the bot lives in this scene, so the next scene is swapped in as a child.
func _swap(path: String) -> void:
	remove_child(_level)
	_level.queue_free()
	_level = (load(path) as PackedScene).instantiate()
	add_child(_level)
	_stage_time = 0.0
	if path == FloorHandoff.CABIN_SCENE:
		_stage = 2
		_log("yacht cabin: interview")
	else:
		_stage = 3
		_carry_health = int(FloorHandoff.carried.get("health", -1))
		_player = _level.get_node("Player") as CharacterBody2D
		_player.connect("died", _on_died)
		_log("Level 2 stub reached: health %d, level %d xp %d, flags map %s pass %s" % [int(_player.get("health")), PlayerStats.character_level, PlayerStats.xp, str(Game.get_meta("neighborhood_map", false)), str(Game.get_meta("desperado_pass", false))])


func _hand_off(delta: float) -> void:
	_stage_time += delta
	_row()["time"] = float(_row()["time"]) + delta
	_stuck_time = 0.0
	if _stage_time > 60.0:
		_finish(false, "hand-off stalled in stage %d" % _stage)
		return
	if _stage == 2:
		if fmod(_stage_time, 0.4) < delta:
			_level.call("advance")
		return
	if _stage == 3:
		if bool(_level.get("complete")):
			_move(0)
			var carried_ok: bool = int(_player.get("health")) > 0 and _carry_health > 0 and PlayerStats.floor_number == 2
			_finish(carried_ok, "reached the Level 2 stub, health %d (carried %d), level %d xp %d, total damage taken %d" % [int(_player.get("health")), _carry_health, PlayerStats.character_level, PlayerStats.xp, _total_damage()])
			return
		_move(1)
		if _player.is_on_floor() and _jump_hold <= 0.0 and _ray(_player.global_position + Vector2(0.0, -8.0), _player.global_position + Vector2(22.0, -8.0)):
			_jump_hold = 0.4
		_hold(&"jump", _jump_hold > 0.0)


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
