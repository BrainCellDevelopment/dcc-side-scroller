extends Node
## Test arena: spawns a boss scene (the Engineer) behind the boss framework with
## an intro delay and a boss box drop.

const BOSS_ARENA: GDScript = preload("res://scripts/level/boss_arena.gd")
const ENGINEER: PackedScene = preload("res://scenes/enemies/engineer.tscn")

var _fails: int = 0


func _ready() -> void:
	var world: Node2D = Node2D.new()
	add_child(world)
	var player: Node2D = Node2D.new()
	player.add_to_group("player")
	world.add_child(player)
	var boss: CharacterBody2D = ENGINEER.instantiate() as CharacterBody2D
	world.add_child(boss)
	var wall: StaticBody2D = StaticBody2D.new()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, 720.0)
	shape.shape = rect
	shape.disabled = true
	wall.add_child(shape)
	world.add_child(wall)
	var arena: Node2D = BOSS_ARENA.new() as Node2D
	arena.set("boss_name", "Test Boss")
	arena.set("tooltip", "A test.")
	arena.set("intro_seconds", 0.3)
	arena.set("drop_tier", "Gold")
	arena.set("map_reward", true)
	world.add_child(arena)
	var hud_stub: Node = Node.new()
	hud_stub.set_script(preload("res://tests/boss_hud_stub.gd"))
	add_child(hud_stub)
	arena.set("hud", hud_stub)
	var announcements: Array[String] = []
	SystemVoice.announced.connect(func(t: String, _b: String, _s: float) -> void: announcements.append(t))
	var cues: Array[StringName] = []
	arena.connect("audio_cue", func(c: StringName) -> void: cues.append(c))
	var locks: Array[CollisionShape2D] = [shape]
	arena.call("setup", boss, locks)
	var seen: Array[String] = []
	Game.boss_health_changed.connect(func(n: String, _c: int, _m: int) -> void: seen.append(n))
	await get_tree().process_frame
	_check(not bool(arena.get("started")), "not started before start()")
	arena.call("start")
	await get_tree().process_frame
	_check(not shape.disabled, "arena locked at intro")
	_check(not bool(boss.get("active")), "boss frozen during intro")
	_check(arena.get_child_count() >= 1, "VS card built")
	_check(announcements.is_empty(), "no System announcement duplicates the VS card (%s)" % str(announcements))
	_check((hud_stub.get("banners") as Array).is_empty(), "no HUD banner duplicates the VS card")
	await get_tree().create_timer(0.5).timeout
	_check(bool(boss.get("active")), "boss active after intro")
	_check(seen.has("Goblin Engineer"), "boss health bar reported")
	boss.call("take_damage", 9999, Vector2.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(shape.disabled, "arena unlocked on defeat")
	_check(bool(arena.get("finished")), "defeat flow finished")
	var box: Node = arena.get("dropped_box")
	_check(box != null and is_instance_valid(box), "boss box dropped")
	if box != null:
		_check(str(box.get("tier")) == "Gold" and bool(box.get("summoned")) and not bool(box.get("is_open")), "box is Gold, summoned, unopened")
		_check(box.is_in_group("boss_boxes"), "box tagged boss_boxes")
	_check(Game.has_meta("neighborhood_map"), "map reward flag set")
	_check(cues == [&"boss_intro", &"boss_fight", &"boss_defeated"], "audio cues fired in order %s" % str(cues))
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1
