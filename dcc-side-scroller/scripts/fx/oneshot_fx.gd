extends Node2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")

@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(24, 24)
@export var frame_count: int = 4
@export var fps: float = 14.0
@export var drift: Vector2 = Vector2.ZERO

var _sprite: AnimatedSprite2D


func _ready() -> void:
	if sheet == null:
		queue_free()
		return
	var anims: Dictionary = {"play": {"row": 0, "count": frame_count, "fps": fps, "loop": false}}
	_sprite = SpriteUtil.make_sprite(sheet, frame_size, anims)
	_sprite.name = "Sprite"
	_sprite.offset = Vector2(-float(frame_size.x) * 0.5, -float(frame_size.y) * 0.5)
	add_child(_sprite)
	_sprite.animation_finished.connect(_on_finished)
	_sprite.play("play")
	set_process(drift != Vector2.ZERO)


func _process(delta: float) -> void:
	position += drift * delta


func _on_finished() -> void:
	queue_free()
