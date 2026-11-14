extends Node
## Level 2 beats 5 and 6: the grub storm, kobold riders, and Ralph the Frenzied Gerbil at the dog pound.

const LEVEL: PackedScene = preload("res://scenes/level02.tscn")
const S_SKITTER: int = 1
const S_DASH: int = 3
const S_SCREAM: int = 5
const S_STUNNED: int = 7

var _fails: int = 0
var _level: Node = null
var _player: CharacterBody2D = null


func _ready() -> void:
	await _storm()
	await _boss()
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
	_player.set("health", 999)


func _teardown() -> void:
	for box: Node in get_tree().get_nodes_in_group("boss_boxes"):
		box.queue_free()
	remove_child(_level)
	_level.free()
	Game.clear_checkpoint()
	await _frames(2)


func _storm() -> void:
	await _boot("grubstorm")
	var storm: Node2D = _level.get_node("GrubStorm") as Node2D
	_player.global_position = storm.global_position + Vector2(300.0, -2.0)
	await _wait_until(func() -> bool: return int(storm.get("spawned")) >= 2, 5.0)
	_check(bool(storm.get("active")) and int(storm.get("spawned")) >= 2, "the storm spawns grubs while the player is inside")
	await _wait_until(func() -> bool: return int(storm.get("spawned")) >= 10, 40.0)
	_check(int(storm.call("alive_count")) <= 7, "the swarm is capped (%d alive)" % int(storm.call("alive_count")))
	var spawned: int = int(storm.get("spawned"))
	_player.global_position = storm.global_position + Vector2(1010.0, -2.0)
	await _frames(240)
	_check(int(storm.get("spawned")) == spawned, "no new grubs after the zone is crossed")
	await _teardown()
	await _boot("dogpound")
	var riders: int = 0
	for node: Node in _level.get_node("Goblins").get_children():
		if node.get("kind") == 4:
			riders += 1
	_check(riders >= 2, "the kobold quadrant has riders (%d)" % riders)
	await _teardown()


func _boss() -> void:
	await _boot("dogpound")
	var lair: Node2D = _level.get_node("DogPoundLair") as Node2D
	var ralph: CharacterBody2D = lair.get("boss") as CharacterBody2D
	_check(ralph != null and int(ralph.get("enemy_level")) == 11 and bool(ralph.get("is_boss")), "Ralph is a Lv11 boss")
	_player.global_position = lair.global_position + Vector2(-292.0, -2.0)
	await _wait_until(func() -> bool: return bool(lair.get("started")), 1.0)
	_check(bool(lair.get("started")), "the fight starts at the pound entrance")
	await _wait_until(func() -> bool: return bool(ralph.get("active")), 4.0)
	_check(bool(ralph.get("active")), "Ralph activates after the intro")
	_player.global_position = lair.global_position + Vector2(-200.0, -2.0)
	var before: int = int(ralph.get("health"))
	await _wait_until(func() -> bool: return int(ralph.get("state")) == S_DASH, 8.0)
	_check(int(ralph.get("state")) == S_DASH, "Ralph dashes across the pit")
	await _wait_until(func() -> bool: return int(ralph.get("state")) == S_STUNNED or int(ralph.get("state")) == S_SKITTER, 4.0)
	if int(ralph.get("state")) != S_STUNNED:
		await _wait_until(func() -> bool: return int(ralph.get("state")) == S_STUNNED, 16.0)
	_check(int(ralph.get("state")) == S_STUNNED, "Ralph is dizzy after hitting the wall")
	ralph.call("take_damage", 2, Vector2.ZERO)
	_check(int(ralph.get("health")) == before - 4, "hits count double while he is dizzy")
	await _wait_until(func() -> bool: return int(ralph.get("state")) == S_SCREAM, 16.0)
	_check(int(ralph.get("state")) == S_SCREAM, "Ralph screams")
	var rockets: int = 0
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		rockets += 1
	_check(rockets >= 3, "the scream fires rockets (%d)" % rockets)
	var hp: int = int(ralph.get("health"))
	ralph.call("take_damage", 2, Vector2.ZERO)
	_check(int(ralph.get("health")) == hp - 1, "hits are halved while he is not dizzy")
	ralph.call("take_damage", 999, Vector2.ZERO)
	await _frames(4)
	_check(bool(ralph.call("is_dead")), "Ralph dies when his health is gone")
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
