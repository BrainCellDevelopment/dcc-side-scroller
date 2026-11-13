extends Area2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const ROCK_SHEET: Texture2D = preload("res://assets/characters/rock.png")
const ANIMS: Dictionary = {"spin": {"row": 0, "count": 4, "fps": 14.0, "loop": true}}
const LIFETIME: float = 4.0

@export var fall_gravity: float = 520.0
@export var damage: int = 1

var velocity: Vector2 = Vector2.ZERO

var _age: float = 0.0
var _done: bool = false


func _ready() -> void:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(ROCK_SHEET, Vector2i(8, 8), ANIMS)
	sprite.name = "Sprite"
	sprite.position = Vector2(0.0, 4.0)
	add_child(sprite)
	sprite.play("spin")
	body_entered.connect(_on_body_entered)


func launch(initial_velocity: Vector2, hit_damage: int = 1) -> void:
	velocity = initial_velocity
	damage = hit_damage


func _physics_process(delta: float) -> void:
	if _done:
		return
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	_age += delta
	if _age >= LIFETIME:
		_finish()


func _on_body_entered(body: Node2D) -> void:
	if _done or body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player"):
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			_finish()
			return
		if body.has_method("take_damage"):
			body.call("take_damage", damage, global_position)
		_finish()
	elif body.is_in_group("enemies"):
		return
	else:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_deferred("monitoring", false)
	hide()
	queue_free()
