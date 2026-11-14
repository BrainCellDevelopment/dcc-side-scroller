extends Node
## Floor end (#68): stairwell, the last cigarette, the heal at the foot of the stairs, the collapse beat
## (survivor counter, achievements, patch notes), the yacht cabin interview, the summary card and the
## Level 2 stub, with real scene changes and the carried state checked at the end.

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const SPEED: float = 3.0

var _fails: int = 0
var _level: Node = null
var _player: CharacterBody2D = null
var _titles: Array[String] = []
var _announced: Array[String] = []
var _count_seen: Array[int] = []


func _ready() -> void:
	await get_tree().process_frame
	Engine.time_scale = SPEED
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void: _titles.append(title))
	SystemVoice.announced.connect(func(title: String, _b: String, _s: float) -> void: _announced.append(title))
	await _run()
	Engine.time_scale = 1.0
	Game.clear_checkpoint()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _wait_until(cond: Callable, timeout: float) -> bool:
	var left: float = timeout
	while left > 0.0:
		if cond.call():
			return true
		await get_tree().physics_frame
		left -= get_physics_process_delta_time() / SPEED
	return cond.call()


func _scene() -> Node:
	return get_tree().current_scene


func _scene_is(path: String) -> bool:
	var scene: Node = _scene()
	return scene != null and scene.scene_file_path == path


func _put_at_trigger(trigger: String) -> void:
	var area: Node2D = _level.get_node("Triggers/" + trigger) as Node2D
	_player.global_position = area.global_position
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()


func _run() -> void:
	# 1. the generated section: stairs, triggers and the checkpoint exist
	var probe: Node = LEVEL.instantiate()
	add_child(probe)
	_check(bool(probe.call("dev_goto", "collapse")), "dev_goto collapse accepted")
	for trigger: String in ["Cigarette", "Landing", "EndZone", "BgStairs"]:
		_check(probe.get_node_or_null("Triggers/" + trigger) != null, "trigger %s exists" % trigger)
	remove_child(probe)
	probe.free()
	_level = LEVEL.instantiate()
	get_tree().root.add_child(_level)
	get_tree().current_scene = _level
	await _frames(4)
	_player = _level.get_node("Player") as CharacterBody2D

	# 2. state that has to survive the trip
	PlayerStats.add_xp(60)
	Game.add_item("test_tonic", "Test Tonic", "bronze", {}, 2)
	Game.set_meta("neighborhood_map", true)
	Game.set_meta("desperado_pass", true)
	Game.set_meta("borough_field_guide", true)
	var level_before: int = PlayerStats.character_level
	var xp_before: int = PlayerStats.xp
	var items_before: int = FloorHandoff.item_total()
	var max_health: int = int(_player.get("max_health"))
	_player.set("health", 3)
	Game.report_player_health(3, max_health)
	_check(items_before > 0, "carries items (%d)" % items_before)
	FloorHandoff.play_seconds = 125.0

	# 3. the last cigarette
	_put_at_trigger("Cigarette")
	await _wait_until(func() -> bool: return not bool(_player.get("control_enabled")), 2.0)
	_check(not bool(_player.get("control_enabled")), "cigarette beat holds the player")
	await _wait_until(func() -> bool: return bool(_player.get("control_enabled")), 12.0)
	_check(bool(_player.get("control_enabled")), "cigarette beat hands control back")
	_check(Game.has_meta("last_cigarette"), "cigarette flag set")
	_check(not bool(_level.get("complete")), "level not complete after the cigarette")

	# 4. descending restores health
	_check(int(_player.get("health")) == 3, "still hurt at the top of the stairs")
	_put_at_trigger("Landing")
	await _wait_until(func() -> bool: return int(_player.get("health")) == max_health, 2.0)
	_check(int(_player.get("health")) == max_health, "health restored at the foot of the stairs (%d)" % int(_player.get("health")))

	# 5. the collapse
	var before: int = SystemVoice.survivors
	SystemVoice.survivors_changed.connect(func(count: int) -> void: _count_seen.append(count))
	_put_at_trigger("EndZone")
	await _frames(4)
	_check(not bool(_level.get("complete")), "end held until the greenroom is done")
	var room: Node = _level.get_node("Greenroom")
	room.set("talked", true)
	for box: Node in get_tree().get_nodes_in_group("loot_boxes"):
		box.set("is_open", true)
	await _wait_until(func() -> bool: return bool(_level.get("complete")), 2.0)
	_check(bool(_level.get("complete")), "collapse starts at the end zone")
	_check(not bool(_player.get("control_enabled")), "player held during the collapse")
	await _wait_until(func() -> bool: return _titles.has("Door Closing, Mind The Gap"), 12.0)
	_check(_titles.has("Door Closing, Mind The Gap"), "collapse_survived fired")
	_check(_titles.has("Counting Heads"), "survivor_count_milestone fired")
	var lost: int = before - SystemVoice.survivors
	_check(lost >= FloorHandoff.SURVIVORS_LOST and lost < FloorHandoff.SURVIVORS_LOST + 20000, "survivor counter dropped about 700,000 (%d)" % lost)
	_check(_count_seen.size() >= 10, "the counter ticked down in steps (%d updates)" % _count_seen.size())
	await _wait_until(func() -> bool: return _announced.has("PATCH NOTES"), 8.0)
	_check(_announced.has("PATCH NOTES"), "patch notes announced")
	_check(_announced.has("LEVEL 1 IS CLOSED"), "collapse notice announced")

	# 6. the cabin, reached through a real scene change
	await _wait_until(func() -> bool: return _scene_is("res://scenes/yacht_cabin.tscn"), 12.0)
	_check(_scene_is("res://scenes/yacht_cabin.tscn"), "scene changed to the yacht cabin")
	_level = null
	var cabin: Node = _scene()
	if cabin == null or not _scene_is("res://scenes/yacht_cabin.tscn"):
		return
	var summary: Dictionary = FloorHandoff.summary
	_check(float(summary.get("seconds", 0.0)) >= 125.0, "summary has the time (%.0f s)" % float(summary.get("seconds", 0.0)))
	_check(absi(int(summary.get("survivors", -1)) - SystemVoice.survivors) < 5000, "summary has survivors left")
	_check(int(summary.get("achievements", 0)) >= 2, "summary counts achievements (%d)" % int(summary.get("achievements", 0)))
	_check(summary.has("kills") and summary.has("boxes") and int(summary.get("items", 0)) == items_before, "summary has kills and loot")
	_check(Game.carried_health == max_health, "health carried (%d)" % Game.carried_health)
	var lines: int = 0
	var guard: int = 0
	while not bool(cabin.get("summary_shown")) and guard < 80:
		cabin.call("advance")
		await _frames(2)
		lines += 1
		guard += 1
	_check(bool(cabin.get("summary_shown")), "interview runs to the summary card (%d presses)" % lines)
	_check(int(cabin.get("choice_made")) >= 0, "the interview offered a choice")
	var card: Node = cabin.get("_summary_layer") as Node
	_check(card != null and card.get("lines").size() == 6, "summary card shows 6 lines")
	if card != null:
		var text: String = " ".join(card.get("lines"))
		_check(text.contains("Neighborhood Map") and text.contains("Desperado Pass"), "summary names the carried flags")
		_check(text.contains(SystemVoice.format_count(int(summary["survivors"]))), "summary shows survivors left")

	# 7. Level 2 stub with the state carried
	cabin.call("advance")
	await _wait_until(func() -> bool: return _scene_is("res://scenes/level02.tscn"), 6.0)
	_check(_scene_is("res://scenes/level02.tscn"), "scene changed to the Level 2 stub")
	var stub: Node = _scene()
	if stub == null or not _scene_is("res://scenes/level02.tscn"):
		return
	await _frames(3)
	var arrival: Dictionary = stub.get("arrival")
	_check(int(arrival["floor"]) == 2, "stats floor is 2")
	_check(int(arrival["health"]) == max_health, "arrived with carried health (%d)" % int(arrival["health"]))
	_check(int(arrival["level"]) == level_before and int(arrival["xp"]) == xp_before, "XP and level carried (lvl %d xp %d)" % [int(arrival["level"]), int(arrival["xp"])])
	_check(int(arrival["items"]) == items_before, "items carried (%d)" % int(arrival["items"]))
	var flags: Dictionary = arrival["flags"]
	_check(bool(flags["neighborhood_map"]) and bool(flags["desperado_pass"]), "map and pass flags carried")
	_check(absi(int(arrival["survivors"]) - int(summary["survivors"])) < 5000, "survivor count carried")
	_check(Game.floor_time_left > Game.FLOOR_TIME - 5.0, "floor timer reset for Level 2")
	var walker: CharacterBody2D = stub.get_node("Player") as CharacterBody2D
	walker.global_position = Vector2(float(stub.get("END_X")) + 8.0, float(stub.get("FLOOR_Y")) - 2.0)
	await _wait_until(func() -> bool: return bool(stub.get("complete")), 2.0)
	_check(bool(stub.get("complete")), "Level 2 stub end reached")
