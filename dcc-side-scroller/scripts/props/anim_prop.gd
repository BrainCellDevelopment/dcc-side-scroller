extends Node2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")

@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(16, 16)
@export var frame_count: int = 4
@export var fps: float = 8.0
@export var centered_origin: bool = false
@export var random_start: bool = true

var _sprite: AnimatedSprite2D


func _ready() -> void:
	if sheet == null:
		return
	var anims: Dictionary = {"idle": {"row": 0, "count": frame_count, "fps": fps, "loop": true}}
	_sprite = SpriteUtil.make_sprite(sheet, frame_size, anims)
	_sprite.name = "Sprite"
	if centered_origin:
		_sprite.offset = Vector2(-float(frame_size.x) * 0.5, -float(frame_size.y) * 0.5)
	add_child(_sprite)
	_sprite.play("idle")
	if random_start:
		_sprite.frame = randi() % frame_count
