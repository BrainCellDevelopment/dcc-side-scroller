extends Node2D

signal opened

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/props/gate_door.png")
const FRAME: Vector2i = Vector2i(64, 112)
const HINGE_X: float = 6.0
const ANIMS: Dictionary = {"swing": {"row": 0, "count": 8, "fps": 18.0, "loop": false}}
const REVEAL_DELAY: float = 0.12
const REVEAL_TIME: float = 0.25

@export var trigger_range: float = 110.0
@export var closed_z: int = 45
@export var open_z: int = 39

var is_open: bool = false
var veil: Node2D = null

var _sprite: AnimatedSprite2D = null

@onready var _body_shape: CollisionShape2D = $Body/CollisionShape2D


func _ready() -> void:
	z_index = closed_z
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.position.x = float(FRAME.x) * 0.5 - HINGE_X
	_sprite.animation_finished.connect(_on_swing_finished)
	add_child(_sprite)
	_sprite.animation = &"swing"
	_sprite.frame = 0
	_sprite.pause()


func start_open() -> void:
	is_open = true
	_sprite.frame = ANIMS["swing"]["count"] - 1
	_sprite.pause()
	z_index = open_z
	_body_shape.set_deferred("disabled", true)
	_set_reveal(1.0)
	opened.emit()


func _process(_delta: float) -> void:
	if is_open:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if player.global_position.x > global_position.x - trigger_range:
		_open()


func _open() -> void:
	is_open = true
	_sprite.play(&"swing")
	var tween: Tween = create_tween()
	tween.tween_interval(REVEAL_DELAY)
	tween.tween_method(_set_reveal, 0.0, 1.0, REVEAL_TIME)


func _on_swing_finished() -> void:
	Game.shake(3.0, 0.22)
	z_index = open_z
	_body_shape.set_deferred("disabled", true)
	opened.emit()


func _set_reveal(amount: float) -> void:
	if veil != null:
		veil.set("reveal", amount)
