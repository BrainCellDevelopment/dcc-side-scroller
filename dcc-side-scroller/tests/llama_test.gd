extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const LLAMA: PackedScene = preload("res://scenes/enemies/llama.tscn")
const BALL: PackedScene = preload("res://scenes/enemies/lava_ball.tscn")
const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")

var _level: Node2D
var _player: CharacterBody2D
var _fails: int = 0
var _spawned: int = 0


func _ready() -> void:
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(30)
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 999)
	await _run()
	Game.clear_checkpoint()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _llamas() -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in _level.get_node("Goblins").get_children():
		if node.has_method("is_asleep"):
			found.append(node)
	return found


func _spawn(at: Vector2, dormant: bool = false) -> Node2D:
	_spawned += 1
	var llama: Node2D = LLAMA.instantiate() as Node2D
	llama.name = "TestLlama%d" % _spawned
	llama.set("dormant", dormant)
	_level.get_node("Goblins").add_child(llama)
	llama.global_position = at
	return llama


func _clear_others() -> void:
	for node: Node in _level.get_node("Goblins").get_children():
		if not node.has_method("is_asleep"):
			node.queue_free()


func _until(cond: Callable, max_frames: int) -> bool:
	for i: int in max_frames:
		if cond.call():
			return true
		await _frames(1)
	return cond.call()


func _run() -> void:
	_clear_others()
	var level_llamas: Array[Node] = _llamas()
	_check(level_llamas.size() == 2, "level 1 alleys hold 2 llamas (%d)" % level_llamas.size())
	var asleep: int = 0
	for llama: Node in level_llamas:
		_check(int(llama.get("enemy_level")) == 3 and not bool(llama.get("is_boss")), "%s is a level 3 non-boss" % llama.name)
		_check(llama.is_in_group("enemies") and llama.has_method("take_damage"), "%s follows the enemy interface" % llama.name)
		if bool(llama.call("is_asleep")):
			asleep += 1
	_check(asleep == 1, "exactly one llama starts asleep (the scripted one)")
	_check(_level.get_node_or_null("Goblins/SleepingLlama") != null, "the sleeping llama keeps its name")
	for llama: Node in level_llamas:
		llama.queue_free()
	await _frames(2)

	var floor_y: float = 304.0
	var base: float = 3000.0

	# Scripted wake: Donut's missile wakes the sleeper.
	var sleeper: Node2D = _spawn(Vector2(base, floor_y - 2.0), true)
	await _frames(20)
	_check(bool(sleeper.call("is_asleep")), "sleeping llama stays asleep when nothing happens")
	_player.global_position = Vector2(base + 170.0, floor_y - 2.0)
	_player.call("_set_facing", -1)
	await _frames(10)
	_check(bool(sleeper.call("is_asleep")), "walking up at range does not wake it")
	Input.action_press("spell")
	await _frames(3)
	Input.action_release("spell")
	var woke: bool = await _until(func() -> bool: return not bool(sleeper.call("is_asleep")), 90)
	_check(woke, "a cast wakes the sleeping llama")
	_player.global_position = Vector2(base - 4000.0, floor_y - 2.0)
	await _frames(1)
	sleeper.queue_free()
	await _frames(2)

	# Telegraph and spit.
	var spitter: Node2D = _spawn(Vector2(base, floor_y - 2.0))
	_player.global_position = Vector2(base + 150.0, floor_y - 2.0)
	_player.set("health", 999)
	await _frames(5)
	var telegraphed: bool = await _until(func() -> bool: return bool(spitter.get("throat_open")), 240)
	_check(telegraphed, "llama telegraphs: throat opens during the spit windup")
	_check(int(spitter.get("state")) == spitter.get_script().get_script_constant_map()["State"]["WINDUP"], "windup state while telegraphing")
	var ball_seen: bool = await _until(func() -> bool: return not get_tree().get_nodes_in_group("projectiles").is_empty(), 90)
	_check(ball_seen, "llama spits a lava ball after the telegraph")
	await _frames(1)
	spitter.queue_free()
	await _frames(2)

	# Throat shot with a real punch while the llama winds up.
	PlayerStats.reset()
	PlayerStats.enter_floor(1)
	var xp_before: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	var target: Node2D = _spawn(Vector2(base, floor_y - 2.0))
	await _frames(10)
	_player.global_position = Vector2(base + 30.0, floor_y - 2.0)
	_player.call("_set_facing", -1)
	target.call("_start_windup")
	target.set("state_timer", 5.0)
	_check(bool(target.get("throat_open")), "windup opens the throat")
	await _frames(2)
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	var punched: bool = await _until(func() -> bool: return bool(target.call("is_dead")), 30)
	_check(punched, "a punch to the throat kills the llama outright")
	_check(bool(target.get("ruptured")), "the kill is a gland rupture")
	var xp_after: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	_check(xp_after - xp_before == XpTable.xp_for_kill(3) + 25, "throat kill pays the Lv3 XP plus the 25 XP bonus (%d)" % (xp_after - xp_before))
	await _frames(2)

	# Conventional kill: punches and stomps elsewhere do normal damage.
	await _frames(40)
	_player.global_position = Vector2(base - 4000.0, floor_y - 2.0)
	var plain: Node2D = _spawn(Vector2(base, floor_y - 2.0))
	await _frames(10)
	var feet: Vector2 = plain.global_position
	var hp: int = int(plain.get("max_health"))
	_check(hp >= 4, "llama has a real health pool (%d)" % hp)
	xp_before = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	plain.call("take_damage", 1, feet + Vector2(30.0, 0.0))
	_check(int(plain.get("health")) == hp - 1 and not bool(plain.call("is_dead")), "a ground punch does 1 damage and does not rupture")
	_check(bool((plain.get_node("HealthBar") as Node2D).visible), "health bar appears after damage")
	plain.call("take_damage", 1, feet + Vector2(-40.0 * float(plain.get("facing")), -30.0))
	_check(int(plain.get("health")) == hp - 2, "a head-height hit from behind is just damage")
	for i: int in hp - 2:
		await _frames(30)
		_check(not bool(plain.call("is_dead")) or i == hp - 3, "still standing before the last hit")
		plain.call("take_damage", 1, feet + Vector2(30.0, 0.0))
	_check(bool(plain.call("is_dead")) and not bool(plain.get("ruptured")), "llama can be beaten conventionally")
	xp_after = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	_check(xp_after - xp_before == XpTable.xp_for_kill(3), "conventional kill pays the plain Lv3 XP (%d)" % (xp_after - xp_before))
	await _frames(2)

	# Head-height hit from the front (jump punch or missile) ruptures the gland.
	var tall: Node2D = _spawn(Vector2(base, floor_y - 2.0))
	await _frames(10)
	var facing: int = int(tall.get("facing"))
	tall.call("take_damage", 1, tall.global_position + Vector2(30.0 * float(facing), -26.0))
	_check(bool(tall.call("is_dead")) and bool(tall.get("ruptured")), "a head-height hit from the front ruptures the throat")

	# Lava puddles: a ball landing on the floor leaves a puddle that burns.
	var ball: Area2D = BALL.instantiate() as Area2D
	_level.add_child(ball)
	ball.global_position = Vector2(base + 400.0, floor_y - 40.0)
	ball.call("launch", Vector2(0.0, 80.0), 1)
	var puddled: bool = await _until(func() -> bool: return not get_tree().get_nodes_in_group("lava_puddles").is_empty(), 60)
	_check(puddled, "a lava ball that lands leaves a puddle")
	var puddle: Node2D = get_tree().get_nodes_in_group("lava_puddles")[0] as Node2D
	_check(absf(puddle.global_position.y - floor_y) < 1.0, "puddle sits on the floor")
	_player.global_position = puddle.global_position + Vector2(8.0, -2.0)
	_player.set("health", 10)
	await _frames(15)
	_check(int(_player.get("health")) < 10, "standing in lava burns")
	var static_puddles: int = 0
	for node: Node in get_tree().get_nodes_in_group("hazards"):
		if node.has_method("_trim_old") and float(node.get("lifetime")) <= 0.0:
			static_puddles += 1
	_check(static_puddles >= 3, "the alleys have permanent idle puddles (%d)" % static_puddles)
