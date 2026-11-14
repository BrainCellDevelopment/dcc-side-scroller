extends "res://scripts/props/caretaker.gd"
## Tally, the Bopca cook of safe room #1 (#59): talk and take the hat, then eat for a full heal and a short buff.

signal meal_served

const BUFF_NAME: String = "Well Fed"
const BUFF_SECONDS: float = 90.0
const BUFF_HINT: String = "Well Fed: faster and harder hits for 90 seconds"

@export var meal_lines: PackedStringArray = PackedStringArray()
@export var meal_done_line: String = "Plate is empty."

var meal_eaten: bool = false

var _eating: bool = false


func _process(_delta: float) -> void:
	if not _inside:
		return
	_face_player()
	if talking:
		if Game.action_just_pressed("interact"):
			_advance()
		return
	var hungry: bool = perk_taken and not meal_eaten
	_prompt.text = "E: eat" if hungry else "E: talk"
	_prompt.visible = true
	if Game.action_just_pressed("interact"):
		if hungry:
			start_meal()
		else:
			start_dialogue()


func start_dialogue() -> void:
	if meal_eaten:
		perk_taken = true
		repeat_line = meal_done_line
	super()


func start_meal() -> void:
	talking = true
	_eating = true
	_index = 0
	_prompt.visible = false
	_sprite.play("talk")
	_set_player_control(false)
	serve_meal()
	_show(meal_lines[0] if not meal_lines.is_empty() else "Eat.")
	dialogue_started.emit()


func serve_meal() -> bool:
	if meal_eaten:
		return false
	meal_eaten = true
	if _player != null and is_instance_valid(_player):
		_player.call("restore_all")
		_player.call("apply_buff", BUFF_NAME, BUFF_SECONDS)
	Game.set_hint(BUFF_HINT)
	meal_served.emit()
	return true


func _advance() -> void:
	if not _eating:
		super()
		return
	_index += 1
	if _index >= meal_lines.size():
		_eating = false
		_finish()
		return
	_show(meal_lines[_index])


func _finish() -> void:
	_eating = false
	super()
