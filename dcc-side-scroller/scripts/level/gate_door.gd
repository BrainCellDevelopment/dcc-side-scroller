extends Node2D

signal opened
signal unlocked

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/props/gate_door.png")
const FRAME: Vector2i = Vector2i(64, 112)
const HINGE_X: float = 6.0
const ANIMS: Dictionary = {"swing": {"row": 0, "count": 8, "fps": 18.0, "loop": false}}
const REVEAL_DELAY: float = 0.12
const REVEAL_TIME: float = 0.25
const PROMPT_RANGE: float = 70.0

@export var auto_open_range: float = 110.0
@export var locked: bool = false
@export var locked_text: String = "Locked"
@export var sealed_text: String = "No way back"
@export var close_behind: bool = true
@export var close_distance: float = 150.0
@export var closed_z: int = 45
@export var open_z: int = 39

var is_open: bool = false
var veil: Node2D = null

var _sprite: AnimatedSprite2D = null
var _shut: bool = false
var _busy: bool = false
var _reveal_tween: Tween = null

@onready var _body_shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	z_as_relative = false
	z_index = closed_z
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.position.x = float(FRAME.x) * 0.5 - HINGE_X
	_sprite.animation_finished.connect(_on_swing_finished)
	add_child(_sprite)
	_sprite.animation = &"swing"
	_sprite.frame = 0
	_sprite.pause()
	_prompt.visible = false
	_prompt.scale.x = _side()


func unlock() -> void:
	if not locked:
		return
	locked = false
	unlocked.emit()


func open(animated: bool = true) -> void:
	if is_open:
		return
	is_open = true
	locked = false
	_shut = false
	_prompt.visible = false
	if animated:
		_busy = true
		_sprite.play(&"swing")
		_fade_reveal(1.0, REVEAL_DELAY)
		return
	_sprite.frame = ANIMS["swing"]["count"] - 1
	_sprite.pause()
	z_index = open_z
	_body_shape.set_deferred("disabled", true)
	_set_reveal(1.0)
	opened.emit()


func close(animated: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	locked = true
	_shut = true
	if sealed_text != "":
		locked_text = sealed_text
	z_index = closed_z
	var beyond: bool = _ahead() > 0.0
	if animated:
		_busy = true
		_sprite.play_backwards(&"swing")
		_fade_reveal(1.0 if beyond else 0.0, 0.0)
		return
	_sprite.frame = 0
	_sprite.pause()
	_body_shape.set_deferred("disabled", false)
	_set_reveal(1.0 if beyond else 0.0)


func _process(_delta: float) -> void:
	if _busy:
		return
	var px: float = _player_x()
	if is_open:
		if close_behind and _ahead() > close_distance:
			close()
		return
	if not locked and not _shut and auto_open_range > 0.0 and _ahead() > -auto_open_range:
		open()
		return
	_prompt.visible = locked and locked_text != "" and absf(px - global_position.x) < PROMPT_RANGE
	if _prompt.visible:
		_prompt.text = locked_text


func _side() -> float:
	return -1.0 if scale.x < 0.0 else 1.0


func _ahead() -> float:
	return (_player_x() - global_position.x) * _side()


func _player_x() -> float:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return global_position.x
	return player.global_position.x


func _fade_reveal(target: float, delay: float) -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.tween_interval(delay)
	_reveal_tween.tween_method(_set_reveal, _reveal(), target, REVEAL_TIME)


func _on_swing_finished() -> void:
	_busy = false
	if is_open:
		Game.shake(3.0, 0.22)
		z_index = open_z
		_body_shape.set_deferred("disabled", true)
		opened.emit()
	else:
		Game.shake(2.5, 0.2)
		_body_shape.set_deferred("disabled", false)


func _reveal() -> float:
	if veil == null:
		return 0.0
	return float(veil.get("reveal"))


func _set_reveal(amount: float) -> void:
	if veil != null:
		veil.set("reveal", amount)
