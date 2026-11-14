extends Node

const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _level: Node2D
var _fails: int = 0


func _ready() -> void:
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(40)
	await _run()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _press_spell() -> void:
	Input.action_press("spell")
	await _frames(3)
	Input.action_release("spell")


func _run() -> void:
	var player: CharacterBody2D = _level.get_node("Player")
	var thrower: Node2D = _level.get_node("Goblins/IntroThrower")
	_check(thrower.get("variant") == 1, "intro enemy is a rock thrower")
	_check(bool(player.get("spell_enabled")), "spell enabled in level 1")
	player.global_position = Vector2(thrower.global_position.x + 200.0, 300.0)
	await _frames(30)
	_check(bool(_level.get("_hint_shown")), "magic missile hint shown near the thrower")
	var mana_before: float = float(player.get("mana"))
	await _press_spell()
	_check(float(player.get("mana")) < mana_before, "cast drains mana")
	_check(get_tree().get_nodes_in_group("missiles").size() == int(player.get("missile_count")), "cast fires the configured missile count")
	_check(not bool(_level.get("_hint_shown")), "hint hides after the first cast")
	await _frames(100)
	_check(not is_instance_valid(thrower) or int(thrower.get("health")) <= 0, "homing missiles killed the out-of-reach thrower")
	_check(get_tree().get_nodes_in_group("missiles").is_empty(), "missiles are gone after hitting")
	player.set("mana", 5.0)
	await _frames(25)
	var missiles_before: int = get_tree().get_nodes_in_group("missiles").size()
	await _press_spell()
	_check(get_tree().get_nodes_in_group("missiles").size() == missiles_before, "cast refused with too little mana")
	Game.set_god_mode(true)
	await _frames(5)
	_check(is_equal_approx(float(player.get("mana")), float(player.get("max_mana"))), "god mode gives full mana")
	Game.set_god_mode(false)
