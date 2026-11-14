extends Area2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/fx/lava_puddle.png")
const FRAME: Vector2i = Vector2i(32, 10)
const ANIMS: Dictionary = {"bubble": {"row": 0, "count": 4, "fps": 5.0, "loop": true}}
const HIT_HEIGHT: float = 6.0
const REPEAT_TIME: float = 0.7
const FADE_TIME: float = 1.2
const MAX_TEMPORARY: int = 6

@export var width: float = 32.0
@export var damage: int = 1
@export var lifetime: float = 0.0

var _cooldown: float = 0.0
var _age: float = 0.0
var _sprite: AnimatedSprite2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("hazards")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(maxf(width - 6.0, 4.0), HIT_HEIGHT)
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(width * 0.5, -HIT_HEIGHT * 0.5)
	add_child(shape)
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.name = "Sprite"
	_sprite.position = Vector2(width * 0.5, 0.0)
	_sprite.scale = Vector2(width / float(FRAME.x), 1.0)
	add_child(_sprite)
	_sprite.play("bubble")
	if lifetime > 0.0:
		add_to_group("lava_puddles")
		_trim_old.call_deferred()


func _trim_old() -> void:
	var puddles: Array[Node] = get_tree().get_nodes_in_group("lava_puddles")
	while puddles.size() > MAX_TEMPORARY:
		var oldest: Node = puddles.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()


func _physics_process(delta: float) -> void:
	if lifetime > 0.0:
		_age += delta
		if _age >= lifetime:
			queue_free()
			return
		_sprite.modulate.a = clampf((lifetime - _age) / FADE_TIME, 0.0, 1.0)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or Game.in_safe_zone:
		return
	for body: Node2D in get_overlapping_bodies():
		if not body.is_in_group("player") or not body.has_method("take_damage"):
			continue
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			continue
		body.call("take_damage", damage, global_position + Vector2(width * 0.5, 0.0))
		_cooldown = REPEAT_TIME
		return
