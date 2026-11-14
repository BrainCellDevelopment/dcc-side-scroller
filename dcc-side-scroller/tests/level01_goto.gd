extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0


func _ready() -> void:
	var probe: Node = LEVEL.instantiate()
	add_child(probe)
	var keys: PackedStringArray = probe.call("dev_sections")
	_check(keys.size() >= 7, "level has at least the 7 plan sections (%d)" % keys.size())
	_check(not bool(probe.call("dev_goto", "nowhere")), "unknown target is refused")
	remove_child(probe)
	probe.free()
	for index: int in keys.size():
		await _try(keys[index], index)
		await _try("cp%d" % index, index)
	Game.clear_checkpoint()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _try(target: String, expected: int) -> void:
	var level: Node = LEVEL.instantiate()
	add_child(level)
	_check(bool(level.call("dev_goto", target)), "dev_goto %s accepted" % target)
	remove_child(level)
	level.free()
	level = LEVEL.instantiate()
	add_child(level)
	for i: int in 5:
		await get_tree().physics_frame
	var player: Node2D = level.get_node("Player") as Node2D
	var area: Node = level.get_node("Triggers/Sec%d" % expected)
	var x: float = player.global_position.x
	_check(int(level.get("section")) == expected, "%s: section is %d" % [target, expected])
	_check(x >= float(area.get_meta("x0")) and x < float(area.get_meta("x1")), "%s: player x %.0f inside the section" % [target, x])
	remove_child(level)
	level.free()
