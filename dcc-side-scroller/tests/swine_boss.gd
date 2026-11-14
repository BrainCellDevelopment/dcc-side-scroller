extends Node
## Ball of Swine (#67): the arena, both solutions (Speedbump fortress and dynamite), a failed
## fortress that does not soft-lock, the hazards, contact rules and the Tuskling mop-up.

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")
const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const DYNAMITE: PackedScene = preload("res://scenes/combat/dynamite.tscn")
const BALL_DORMANT: int = 0
const BALL_WINDUP: int = 3
const BALL_ROLL: int = 4
const BALL_WEDGED: int = 5

var _fails: int = 0
var _level: Node = null
var _arena: Node2D = null
var _player: CharacterBody2D = null
var _ball: CharacterBody2D = null
var _titles: Array[String] = []


func _ready() -> void:
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void: _titles.append(title))
	await _static_checks()
	await _fortress_route()
	await _failed_fortress_route()
	await _dynamite_route()
	await _hazards_and_contact()
	Game.clear_checkpoint()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _boot() -> void:
	var probe: Node = LEVEL.instantiate()
	add_child(probe)
	probe.call("dev_goto", "swine")
	remove_child(probe)
	probe.free()
	_level = LEVEL.instantiate()
	add_child(_level)
	await _frames(4)
	_arena = get_tree().get_first_node_in_group("swine_arena") as Node2D
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 999)
	_ball = _arena.get("boss") as CharacterBody2D


func _teardown() -> void:
	for box: Node in get_tree().get_nodes_in_group("boss_boxes"):
		box.queue_free()
	remove_child(_level)
	_level.free()
	_level = null
	Game.clear_checkpoint()
	await _frames(2)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _wait_until(cond: Callable, timeout: float) -> bool:
	var left: float = timeout
	while left > 0.0:
		if cond.call():
			return true
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	return cond.call()


func _put_player(pos: Vector2) -> void:
	_player.global_position = pos
	_player.velocity = Vector2.ZERO
	_player.reset_physics_interpolation()


func _press_interact() -> void:
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	await _frames(2)


func _start_fight() -> void:
	_put_player(_arena.global_position + Vector2(318.0, -2.0))
	await _wait_until(func() -> bool: return bool(_arena.get("started")), 1.0)
	await _wait_until(func() -> bool: return bool(_ball.get("active")), 5.0)


func _fortress() -> Node2D:
	return _arena.get("fortress") as Node2D


func _build_fortress_by_input() -> void:
	var fort: Node2D = _fortress()
	for i: int in 2:
		var piece: int = int((fort.call("free_piece_indices") as Array[int])[0])
		_put_player(fort.call("piece_position", piece) as Vector2 + Vector2(0.0, -2.0))
		await _frames(2)
		await _press_interact()
		_check(bool(fort.call("is_carrying")), "piece %d lifted with E" % i)
		var socket: int = int((fort.call("empty_socket_indices") as Array[int])[0])
		_put_player(fort.call("socket_position", socket) as Vector2 + Vector2(0.0, -2.0))
		await _frames(2)
		await _press_interact()
		_check(not bool(fort.call("is_carrying")), "piece %d placed with E" % i)


func _static_checks() -> void:
	await _boot()
	_check(_arena != null, "level has a swine arena")
	_check(_ball != null and not _ball.is_in_group("enemies"), "ball is not in the enemies group")
	_check(_ball.is_in_group("destructibles"), "ball is destructible (dynamite)")
	_check(int(_ball.get("enemy_level")) == 15 and bool(_ball.get("is_boss")), "ball is a Lv15 boss")
	_check(int(_ball.get("state")) == BALL_DORMANT, "ball dormant before the fight")
	_check(bool(_arena.get("field_dropped")) == false, "forcefield up before the fight")
	var entry: CollisionShape2D = _arena.get("_entry_shape") as CollisionShape2D
	_check(entry.disabled, "entry open before the fight")
	var cache: int = 0
	for child: Node in _arena.get_children():
		if str(child.name).begins_with("DynamiteCache"):
			cache += int(child.get("count"))
	_check(cache >= 4, "arena has a dynamite cache of at least 4 sticks (%d)" % cache)
	var lanes: Array[float] = _arena.call("lane_ys")
	_check(lanes.size() == 3 and is_equal_approx(lanes[0] - lanes[1], 48.0), "three lanes 48 apart")
	var plats: int = 0
	for plat: Node in _level.get_node("Platforms").get_children():
		var plat2: Node2D = plat as Node2D
		if plat2 != null and plat2.global_position.y < lanes[0] - 40.0 and plat2.global_position.y > lanes[0] - 120.0 and bool(plat.get("one_way")):
			plats += 1
	_check(plats == 2, "two one-way lane platforms exist (%d)" % plats)
	await _teardown()


func _fortress_route() -> void:
	await _boot()
	var xp_before: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	await _start_fight()
	var entry: CollisionShape2D = _arena.get("_entry_shape") as CollisionShape2D
	_check(bool(_arena.get("started")), "walking in starts the fight")
	_check(not entry.disabled, "entry shuts behind the player")
	_check(bool(_ball.get("active")), "ball active after the intro")
	var hp: int = int(_ball.get("health"))
	_ball.call("take_damage", 5, _ball.global_position)
	_check(int(_ball.get("health")) == hp, "melee does nothing to a rolling ball")
	await _build_fortress_by_input()
	_check(bool(_fortress().get("armed")), "both pieces placed arms the fortress")
	_check(bool(_ball.get("gate_armed")), "ball knows the gate is armed")
	_put_player(_arena.global_position + Vector2(200.0, -2.0))
	var wedged: bool = await _wait_until(func() -> bool: return int(_ball.get("state")) == BALL_WEDGED, 20.0)
	_check(wedged, "ball wedges in the fortress")
	_check(absf(_ball.global_position.x - _arena.global_position.x) < 1.0, "wedged on the gate")
	_check(_ball.call("is_vulnerable"), "wedged ball can be hurt")
	var field: bool = bool(_arena.get("field_dropped"))
	_check(not field, "forcefield still up while the ball lives")
	for i: int in 4:
		_ball.call("take_damage", 1, _ball.global_position + Vector2(30.0, 0.0))
	_check(int(_ball.get("health")) == 1, "wedged hits count double (health %d)" % int(_ball.get("health")))
	var pop_at: Vector2 = _ball.global_position
	_ball.call("take_damage", 1, _ball.global_position + Vector2(30.0, 0.0))
	await _frames(3)
	var arena_node: Node2D = _arena.get("boss_arena") as Node2D
	_check(bool(arena_node.get("finished")), "boss defeat flow ran")
	_check(bool(_arena.get("field_dropped")), "forcefield drops on the pop")
	_check(bool(_arena.get("won")), "arena marked won")
	_check(Game.has_meta("borough_field_guide"), "Borough Field Guide flag set")
	_check(_titles.has("Boss Of The Block"), "borough_boss achievement fired")
	var box: Node = arena_node.get("dropped_box")
	_check(box != null and str(box.get("tier")) == "Boss" and str(box.get("kit")) == "floor1", "Boss box (floor1 kit) dropped")
	var entry_open: bool = entry.disabled
	_check(entry_open, "entry unlocked after the pop")
	var mop: Array[Node] = _arena.get("mopup")
	_check(mop.size() == 6, "six killable Tusklings spill out")
	var crowd: Array[Node] = _arena.get("crowd")
	_check(crowd.size() + mop.size() >= 30, "30 or more nobles in total (%d)" % (crowd.size() + mop.size()))
	var levels: Array[int] = []
	for noble: Node in mop:
		levels.append(int(noble.get("enemy_level")))
	levels.sort()
	_check(levels == [4, 4, 4, 5, 5, 8], "Tusklings are Lv4 x3, Lv5 x2, Lv8 x1 %s" % str(levels))
	await _frames(30)
	var moved: bool = false
	for noble: Node in mop:
		if (noble as Node2D).global_position.distance_to(pop_at) > 20.0:
			moved = true
	_check(moved, "Tusklings scatter")
	var boss_xp: int = XpTable.xp_for_kill(15, true)
	var after_boss: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	_check(after_boss - xp_before == boss_xp, "boss paid %d XP (got %d)" % [boss_xp, after_boss - xp_before])
	for noble: Node in mop:
		noble.call("take_damage", 1, (noble as Node2D).global_position + Vector2(-10.0, 0.0))
		noble.call("take_damage", 5, (noble as Node2D).global_position + Vector2(-10.0, 0.0))
	var expected: int = 3 * XpTable.xp_for_kill(4) + 2 * XpTable.xp_for_kill(5) + XpTable.xp_for_kill(8)
	var final_xp: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	_check(final_xp - after_boss == expected, "Tusklings paid %d XP (got %d)" % [expected, final_xp - after_boss])
	await _teardown()


func _failed_fortress_route() -> void:
	await _boot()
	await _start_fight()
	var fort: Node2D = _fortress()
	var piece: int = int((fort.call("free_piece_indices") as Array[int])[0])
	_put_player(fort.call("piece_position", piece) as Vector2 + Vector2(0.0, -2.0))
	await _frames(2)
	await _press_interact()
	await _press_interact()
	_check(not bool(fort.call("is_carrying")) and int(fort.call("piece_state", piece)) == 2, "E away from a socket drops the piece")
	await _press_interact()
	_check(bool(fort.call("is_carrying")), "a dropped piece can be lifted again")
	fort.call("break_fortress")
	_check(not bool(fort.call("is_carrying")) and (fort.call("free_piece_indices") as Array[int]).size() == 2, "breaking the fortress returns the pieces")
	await _build_fortress_by_input()
	_put_player(_arena.global_position + Vector2(200.0, -2.0))
	var wedged: bool = await _wait_until(func() -> bool: return int(_ball.get("state")) == BALL_WEDGED, 20.0)
	_check(wedged, "ball wedges")
	var hp: int = int(_ball.get("health"))
	var freed: bool = await _wait_until(func() -> bool: return int(_ball.get("state")) != BALL_WEDGED, 9.0)
	_check(freed, "unattended wedge breaks free")
	_check(int(_ball.get("health")) == hp, "ball healed nothing and lost nothing")
	_check(not bool(fort.get("armed")) and int(fort.call("placed_count")) == 0, "fortress breaks when the ball breaks free")
	_check((fort.call("free_piece_indices") as Array[int]).size() == 2 and (fort.call("empty_socket_indices") as Array[int]).size() == 2, "pieces are back at the depots: it can be rebuilt")
	_check(not bool(_ball.get("gate_armed")), "ball no longer thinks the gate is armed")
	await _build_fortress_by_input()
	var again: bool = await _wait_until(func() -> bool: return int(_ball.get("state")) == BALL_WEDGED, 30.0)
	_check(again, "the rebuilt fortress wedges it again")
	for i: int in 5:
		_ball.call("take_damage", 1, _ball.global_position + Vector2(-30.0, 0.0))
	await _frames(3)
	_check(bool(_arena.get("won")), "second attempt pops it")
	await _teardown()


func _dynamite_route() -> void:
	await _boot()
	await _start_fight()
	var hp: int = int(_ball.get("health"))
	var stick: Node2D = DYNAMITE.instantiate() as Node2D
	stick.set("fuse_time", 0.1)
	_level.add_child(stick)
	stick.global_position = _ball.call("center") as Vector2
	await _frames(12)
	_check(int(_ball.get("health")) == hp - 3, "a real dynamite blast costs the ball 3 health (%d)" % int(_ball.get("health")))
	_check(int(_ball.get("state")) != BALL_ROLL, "a blast staggers a rolling ball")
	Explosives.blast(get_tree(), _ball.call("center") as Vector2, 56.0, 3, 0)
	_check(int(_ball.get("health")) == hp - 6, "second blast")
	_check(not bool(_arena.get("won")), "two sticks are not enough")
	Explosives.blast(get_tree(), _ball.call("center") as Vector2, 56.0, 3, 0)
	await _frames(3)
	_check(bool(_arena.get("won")), "third blast pops it: dynamite is a valid solution")
	_check(bool(_arena.get("field_dropped")), "forcefield drops after the dynamite win")
	await _teardown()


func _hazards_and_contact() -> void:
	await _boot()
	await _start_fight()
	var hazards: Node2D = _arena.get("hazards") as Node2D
	hazards.call("stop")
	var floor_y: float = _arena.global_position.y
	_ball.set("state", BALL_WINDUP)
	_ball.global_position = Vector2(_arena.global_position.x - 300.0, floor_y)
	_ball.set("_timer", 999.0)
	var before: int = int(_player.get("health"))
	hazards.call("fire_laser", 0)
	_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 2.0))
	await _frames(20)
	_check(int(_player.get("health")) == before, "laser warns first and does no damage during the warning")
	await _wait_until(func() -> bool: return int(_player.get("health")) < before, 2.0)
	_check(int(_player.get("health")) == before - 1, "laser hits a player standing in its lane")
	await _wait_until(func() -> bool: return (hazards.get("_items") as Array).is_empty(), 2.0)
	before = int(_player.get("health"))
	hazards.call("fire_laser", 0)
	for i: int in 150:
		_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 48.0 - 2.0))
		await get_tree().physics_frame
	_check(int(_player.get("health")) == before, "a player on the lane above is safe from the floor laser")
	hazards.call("fire_groove", _arena.global_position.x + 100.0)
	for i: int in 150:
		_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 20.0))
		await get_tree().physics_frame
	_check(int(_player.get("health")) == before, "jumping clear of a floor groove is safe")
	await _wait_until(func() -> bool: return (hazards.get("_items") as Array).is_empty(), 2.0)
	hazards.call("fire_groove", _arena.global_position.x + 100.0)
	_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 2.0))
	await _wait_until(func() -> bool: return int(_player.get("health")) < before, 3.0)
	_check(int(_player.get("health")) == before - 1, "a floor groove hurts a player standing on it after the warning")
	await _wait_until(func() -> bool: return (hazards.get("_items") as Array).is_empty(), 2.0)
	await _wait_until(func() -> bool: return _player.is_on_floor(), 1.0)
	await get_tree().create_timer(1.0).timeout
	before = int(_player.get("health"))
	_ball.set("state", BALL_ROLL)
	_ball.set("heading", 1)
	_ball.set("lane", 0)
	_ball.global_position = Vector2(_arena.global_position.x + 60.0 - 40.0, floor_y)
	_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 2.0))
	await _frames(40)
	_check(int(_player.get("health")) <= before - 2, "a rolling ball hurts a player in its lane (%d -> %d)" % [before, int(_player.get("health"))])
	await get_tree().create_timer(1.0).timeout
	before = int(_player.get("health"))
	_ball.set("state", BALL_ROLL)
	_ball.set("heading", 1)
	_ball.global_position = Vector2(_arena.global_position.x + 20.0, floor_y)
	for i: int in 60:
		_put_player(Vector2(_arena.global_position.x + 100.0, floor_y - 48.0 - 2.0))
		await get_tree().physics_frame
	_check(int(_player.get("health")) == before, "a player on the next lane up is not hit by the rolling ball")
	await _teardown()
