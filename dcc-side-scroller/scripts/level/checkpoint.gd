extends Area2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/props/checkpoint.png")
const FRAME: Vector2i = Vector2i(24, 40)
const ANIMS: Dictionary = {
	"off": {"row": 0, "count": 1, "fps": 1.0, "loop": true},
	"lit": {"row": 1, "count": 4, "fps": 8.0, "loop": true},
}
const FLAME_POS: Vector2 = Vector2(0.0, -30.0)

signal activated(index: int)

@export var index: int = 0
@export var stage: int = 0

var lit: bool = false

var _sprite: AnimatedSprite2D = null
var _glow: Sprite2D = null
var _glow_tween: Tween = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.name = "Sprite"
	add_child(_sprite)
	_glow = Sprite2D.new()
	_glow.name = "Glow"
	_glow.texture = _make_glow_texture()
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.position = FLAME_POS
	_glow.z_index = 1
	add_child(_glow)
	body_entered.connect(_on_body_entered)
	_set_lit(index <= Game.checkpoint_index, false)


func _make_glow_texture() -> Texture2D:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var centre: Vector2 = Vector2(23.5, 23.5)
	for y: int in 48:
		for x: int in 48:
			var d: float = Vector2(float(x), float(y)).distance_to(centre)
			var a: float = 0.0
			if d < 6.0:
				a = 0.4
			elif d < 11.0:
				a = 0.22
			elif d < 17.0:
				a = 0.11
			elif d < 23.0:
				a = 0.045
			if a > 0.0:
				img.set_pixel(x, y, Color(1.0, 0.6, 0.2, a))
	return ImageTexture.create_from_image(img)


func _set_lit(on: bool, burst: bool) -> void:
	lit = on
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow.visible = on
	if on:
		_sprite.play("lit")
		_glow.modulate.a = 1.0
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(_glow, "modulate:a", 0.6, 0.3)
		_glow_tween.tween_property(_glow, "modulate:a", 1.0, 0.3)
		if burst:
			_burst()
	else:
		_sprite.play("off")


func _burst() -> void:
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1.0, 0.85, 0.35, 1.0))
	fade.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.amount = 18
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector2(0.0, -1.0)
	p.spread = 70.0
	p.gravity = Vector2(0.0, 200.0)
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color_ramp = fade
	p.position = FLAME_POS
	p.z_index = 2
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if index <= Game.checkpoint_index:
		return
	Game.set_checkpoint(index, global_position, stage)
	_set_lit(true, true)
	activated.emit(index)
