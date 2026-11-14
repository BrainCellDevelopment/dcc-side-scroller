extends Node

const LEVEL: PackedScene = preload("res://scenes/level00.tscn")

var _level: Node2D
var _fails: int = 0
var _shot_dir: String = OS.get_environment("DCC_SHOT_DIR")
func _ready() -> void:
	Game.set_checkpoint(8, Vector2(19384.0, 912.0), 2)
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(30)
	await _guild()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _tap() -> void:
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(3)


func _shot(name: String) -> void:
	if _shot_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shot_dir, name])


func _guild() -> void:
	var entry: Node2D = _level.get_node("Doors/GuildEntryDoor")
	var exit_door: Node2D = _level.get_node("Doors/GuildExitDoor")
	var mord: Area2D = _level.get_node("Guildhall/Mordecai")
	var boxes: Array[Node] = _level.get_node("Guildhall/LootBoxes").get_children()
	var player: CharacterBody2D = _level.get_node("Player")
	_check(entry.get("is_open"), "guild entry door open on arrival")
	_check(exit_door.get("locked") and not exit_door.get("is_open"), "exit door locked and closed")
	_check(not boxes[0].visible, "boxes hidden before dialogue")
	player.global_position = mord.global_position + Vector2(30.0, -2.0)
	await _frames(20)
	await _shot("guild_prompt")
	await _tap()
	_check(mord.get("talking"), "E starts dialogue")
	await _shot("guild_dialogue")
	await _tap()
	await _tap()
	_check(mord.get("talking"), "still talking mid dialogue")
	await _tap()
	_check(mord.get("talked") and not mord.get("talking"), "dialogue finished")
	_check(boxes[0].visible and boxes[1].visible, "boxes appear after dialogue")
	await _frames(200)
	var face: float = player.global_position.y - boxes[0].global_position.y
	_check(face > 15.0 and face < 35.0, "box at face height (%.1f above feet)" % face)
	_check(absf(boxes[0].global_position.x - player.global_position.x) < 48.0, "box near face horizontally")
	await _shot("guild_boxes")
	_check(not exit_door.get("is_open"), "exit door still closed before boxes")
	await _tap()
	_check(boxes[0].get("is_open") and not boxes[1].get("is_open"), "first E opens only first box")
	_check(Game.items.size() == 1, "item added")
	await _shot("guild_item")
	await _tap()
	_check(boxes[1].get("is_open") and Game.items.size() == 2, "second box opened")
	await _frames(120)
	_check(exit_door.get("is_open"), "exit door opened")
	await _shot("guild_exit_open")
	player.global_position = exit_door.global_position + Vector2(0.0, -2.0)
	await _frames(10)
	_check(_level.get("complete"), "level complete when walking through open door")
	await _shot("guild_complete")
