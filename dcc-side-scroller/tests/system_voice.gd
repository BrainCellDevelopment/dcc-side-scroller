extends Node

const Achievements: GDScript = preload("res://scripts/data/achievements.gd")
const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0
var _unlocked: Array[String] = []
var _announced: Array[String] = []


func _ready() -> void:
	await _run()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _run() -> void:
	var ids: Array = Achievements.ids()
	_check(ids.size() >= 25, "registry has 25+ achievements (%d)" % ids.size())
	var titles: Dictionary = {}
	var texts: Dictionary = {}
	var well_formed: bool = true
	for id: String in ids:
		var e: Array = Achievements.entry(id)
		if e.size() != 2 or str(e[0]).is_empty() or str(e[1]).is_empty():
			well_formed = false
		titles[e[0]] = true
		texts[e[1]] = true
	_check(well_formed, "every entry has a title and a sentence")
	_check(titles.size() == ids.size() and texts.size() == ids.size(), "no duplicate titles or lines")

	Game.achievement_unlocked.connect(func(t: String, _d: String) -> void: _unlocked.append(t))
	SystemVoice.announced.connect(func(t: String, _b: String, _s: float) -> void: _announced.append(t))
	PlayerStats.enter_floor(1)
	_check(SystemVoice.floor_active, "entering floor 1 starts the floor voice")

	_check(SystemVoice.fire("map_upgrade"), "fire() unlocks a registry hook")
	_check(not SystemVoice.fire("not_a_hook"), "unknown hook is ignored")
	SystemVoice.fire("map_upgrade")
	_check(_unlocked.count("Lost And Found") == 1, "an achievement only unlocks once")

	for i: int in 10:
		SystemVoice.count("stomp")
	_check(_unlocked.has("Smush") and _unlocked.has("Boots On The Ground") and _unlocked.has("Mattress Tester"), "stomp counter fires first, 1 and 10")

	var hits: Array[Node2D] = []
	for i: int in 3:
		var prop: Node2D = Node2D.new()
		prop.add_to_group("destructibles")
		prop.set_script(preload("res://tests/system_voice_prop.gd"))
		add_child(prop)
		hits.append(prop)
	Explosives.blast(get_tree(), Vector2.ZERO, 50.0, 1, 0)
	_check(_unlocked.has("Boom!"), "three things blown up fires Boom! from the registry")

	var seen: Dictionary = {}
	var repeats: bool = false
	for i: int in 5:
		var line: String = SystemVoice.next_line("t", Achievements.LEVEL_UP_LINES)
		if seen.has(line):
			repeats = true
		seen[line] = true
	_check(not repeats, "announcement pool does not repeat inside a cycle")

	var level_before: int = PlayerStats.character_level
	PlayerStats.add_xp(100000)
	_check(PlayerStats.character_level > level_before, "xp raised the level")
	_check(_announced.has("LEVEL UP!"), "level-up goes out as an announcement")
	_check(_unlocked.has("Number Go Up"), "level 2 achievement fires on level-up")

	var s0: int = SystemVoice.survivors
	SystemVoice.drop_survivors(1000)
	_check(SystemVoice.survivors == s0 - 1000, "drop_survivors ticks the counter down")
	_check(SystemVoice.format_count(4200000) == "4,200,000", "count formatting")
	SystemVoice.announce_survivors()
	_check(_announced.has("4:00 AM CHECK-IN"), "manager check-in announces")

	_announced.clear()
	Game.floor_time_left = 3599.0
	SystemVoice._process(0.0)
	_check(_announced.has("Time to Level Collapse: 1 hour."), "collapse warning fires crossing 1 hour")
	_check(not _announced.has("Time to Level Collapse: 24 hours."), "older warnings are skipped")
	_check(is_equal_approx(SystemVoice.time_left(), 3599.0), "time_left() reads the floor timer")

	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hud: Node = level.get_node("HUD")
	var label: Label = hud.get_node("SurvivorLabel") as Label
	_check(label != null and label.visible, "HUD shows the survivor counter")
	SystemVoice.set_survivors_visible(false)
	_check(not label.visible, "survivor counter toggles off")
	SystemVoice.set_survivors_visible(true)
	_check(label.visible and label.text.begins_with("Survivors: "), "survivor counter toggles back on")
	level.queue_free()
	Game.reset_run()
	_check(not SystemVoice.floor_active, "reset_run ends the floor")
