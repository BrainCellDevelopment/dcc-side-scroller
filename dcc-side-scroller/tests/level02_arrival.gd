extends Node
## Level 2 beats 1 and 2: the Brindle Grub and Danger Dingo roster, and the storm shelter (safe zone,
## Mordecai the Bugaboo, the Second Chance mailbox).

const LEVEL: PackedScene = preload("res://scenes/level02.tscn")

var _fails: int = 0
var _level: Node = null
var _player: CharacterBody2D = null


func _ready() -> void:
	await _roster()
	await _shelter()
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


func _teardown() -> void:
	remove_child(_level)
	_level.free()
	Game.clear_checkpoint()
	await _frames(2)


func _roster() -> void:
	await _boot("arrival")
	var grubs: int = 0
	var dingoes: int = 0
	for node: Node in _level.get_node("Goblins").get_children():
		if node.get("kind") == 2:
			grubs += 1
		elif node.get("kind") == 3:
			dingoes += 1
	_check(grubs >= 4 and dingoes >= 2, "arrival has grubs and dingoes (%d, %d)" % [grubs, dingoes])
	var dingo: CharacterBody2D = null
	for node: Node in _level.get_node("Goblins").get_children():
		if node.get("kind") == 3:
			dingo = node as CharacterBody2D
			break
	_check(dingo != null and int(dingo.get("enemy_level")) == 5 and int(dingo.get("max_health")) > 1, "dingo is a Lv5 with more than one hit")
	dingo.call("take_damage", 99, dingo.global_position + Vector2(-10.0, 0.0))
	await _frames(3)
	_check(int(dingo.get("state")) == 3, "dingo dies when its health is gone")
	await _teardown()


func _shelter() -> void:
	await _boot("shelter")
	var room: Node2D = _level.get_node_or_null("StormShelter") as Node2D
	_check(room != null, "level has the storm shelter")
	_player.global_position = room.global_position + Vector2(-60.0, -2.0)
	await _frames(4)
	_check(Game.in_safe_zone, "the shelter is a safe zone")
	var mord: Area2D = room.get("mordecai") as Area2D
	_check(mord != null and mord.get("sheet") != null, "Mordecai is in the shelter with the Bugaboo sheet")
	_check(not bool(room.call("is_ready")), "shelter not ready before talking and mail")
	_player.global_position = mord.global_position + Vector2(-10.0, -2.0)
	await _frames(3)
	for i: int in 4:
		Input.action_press(&"interact")
		await _frames(2)
		Input.action_release(&"interact")
		await _frames(2)
	_check(bool(mord.get("talked")), "Mordecai's talk finishes")
	_player.global_position = room.global_position + Vector2(250.0, -2.0)
	await _frames(4)
	Input.action_press(&"interact")
	await _frames(2)
	Input.action_release(&"interact")
	await _frames(2)
	_check(bool(room.get("mail_taken")) and bool(Game.get_meta("second_chance", false)), "mailbox gives Second Chance")
	_check(bool(room.call("is_ready")), "shelter ready after talk, mail and boxes")
	await _teardown()
