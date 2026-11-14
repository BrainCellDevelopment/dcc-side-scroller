extends Node
## Level 2 beats 3 and 4: clurichaun slingshots and the Taint, the smoothie bench, and the Krakaren Clone.

const LEVEL: PackedScene = preload("res://scenes/level02.tscn")
const Taint: GDScript = preload("res://scripts/combat/taint.gd")

var _fails: int = 0
var _level: Node = null
var _player: CharacterBody2D = null


func _ready() -> void:
	await _taint_and_bench()
	await _boss()
	Game.clear_checkpoint()
	Game.set_meta("smoothie_immune", false)
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
		left -= get_physics_process_delta_time()
	return cond.call()


func _boot(target: String) -> void:
	var probe: Node = LEVEL.instantiate()
	add_child(probe)
	probe.call("dev_goto", target)
	remove_child(probe)
	probe.free()
	_level = LEVEL.instantiate()
	add_child(_level)
	await _frames(4)
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 5)


func _teardown() -> void:
	for box: Node in get_tree().get_nodes_in_group("boss_boxes"):
		box.queue_free()
	remove_child(_level)
	_level.free()
	Game.clear_checkpoint()
	await _frames(2)


func _taint_and_bench() -> void:
	await _boot("clurichaun")
	var clur: int = 0
	for node: Node in _level.get_node("Goblins").get_children():
		if node.get("variant") == 4:
			clur += 1
	_check(clur >= 4, "clurichaun section has slingshot clurichauns (%d)" % clur)
	Taint.apply(_player)
	await _frames(2)
	_check(Taint.is_tainted(_player), "taint applies")
	_check(not bool(_player.call("heal", 3)), "no healing while tainted")
	_check(int(_player.get("health")) == 5, "health unchanged by a blocked heal")
	_player.get_node("Taint").queue_free()
	await _frames(2)
	_check(bool(_player.call("heal", 3)), "healing works again once the taint is gone")
	var bench: Node2D = _level.get_node("SmoothieBench") as Node2D
	_player.global_position = bench.global_position + Vector2(0.0, -2.0)
	await _frames(4)
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	await _frames(2)
	_check(bool(bench.get("done")) and Taint.is_immune(), "the bench blends the immunity smoothie")
	Taint.apply(_player)
	await _frames(2)
	_check(not Taint.is_tainted(_player), "smoothie makes the player immune to the taint")
	Game.set_meta("smoothie_immune", false)
	await _teardown()


func _boss() -> void:
	await _boot("krakaren")
	var lair: Node2D = _level.get_node("KrakarenLair") as Node2D
	var boss: Node2D = lair.get("boss") as Node2D
	_check(boss != null and int(boss.get("enemy_level")) == 10 and bool(boss.get("is_boss")), "the Krakaren is a Lv10 boss")
	_player.set("health", 999)
	_player.global_position = lair.global_position + Vector2(-292.0, -2.0)
	await _wait_until(func() -> bool: return bool(lair.get("started")), 1.0)
	_check(bool(lair.get("started")), "the fight starts at the lair entrance")
	await _wait_until(func() -> bool: return bool(boss.get("active")), 4.0)
	_check(bool(boss.get("active")), "the boss activates after the intro")
	var tentacle: Node = boss.get_node("Tentacle1")
	_player.global_position = lair.global_position + Vector2(-80.0, -2.0)
	var before: int = int(boss.get("health"))
	await _wait_until(func() -> bool: return int(tentacle.get("state")) == 1, 6.0)
	_check(int(tentacle.get("state")) == 1, "a tentacle telegraphs")
	tentacle.call("take_damage", 5, Vector2.ZERO)
	_check(int(boss.get("health")) == before, "a telegraphing tentacle cannot be hurt")
	await _wait_until(func() -> bool: return int(tentacle.get("state")) == 3, 3.0)
	_check(int(tentacle.get("state")) == 3, "the tentacle sags stuck after slamming")
	tentacle.call("take_damage", 5, Vector2.ZERO)
	_check(int(boss.get("health")) == before - 5, "a stuck tentacle can be hurt")
	var mucus: int = 0
	var watcher: Callable = func() -> bool:
		for node: Node in get_tree().get_nodes_in_group("projectiles"):
			if bool(node.get("taints")):
				mucus += 1
		return mucus > 0
	_check(await _wait_until(watcher, 14.0), "the Krakaren spits taint mucus")
	boss.call("tentacle_hit", int(boss.get("health")))
	await _frames(4)
	_check(bool(boss.call("is_dead")), "the Krakaren dies when its health is gone")
	await _wait_until(func() -> bool: return lair.get("boss_arena").get("dropped_box") != null, 2.0)
	_check(lair.get("boss_arena").get("dropped_box") != null, "the boss box drops")
	_check(not bool(lair.get("boss_arena").get("locked")), "the arena lock opens")
	await _walk_out(lair)
	await _teardown()


## The exit must be open once the boss is down: walk right from inside the arena to past its edge.
func _walk_out(lair: Node2D) -> void:
	_player.global_position = lair.global_position + Vector2(lair.get("half_width") - 80.0, -2.0)
	_player.velocity = Vector2.ZERO
	await _frames(4)
	Input.action_press(&"move_right")
	await _frames(150)
	Input.action_release(&"move_right")
	_check(_player.global_position.x > lair.global_position.x + float(lair.get("half_width")) + 24.0, "the player can walk out through the exit after the boss (x %.0f)" % (_player.global_position.x - lair.global_position.x))
