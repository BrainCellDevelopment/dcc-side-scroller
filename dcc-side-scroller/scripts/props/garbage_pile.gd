extends StaticBody2D
## Lumpy garbage mound. Origin is bottom centre. A solid pile is a platform and cover
## (blocks shockwaves); the Hoarder can smash it and it regrows. Non-solid piles are backdrop.

const BAG_DARK: Color = Color("3a2c1a")
const BAG_MID: Color = Color("5e4a28")
const BAG_LIGHT: Color = Color("8a7440")
const BONE: Color = Color("c8b692")
const RUST: Color = Color("b85c42")
const OUTLINE: Color = Color("0c0508")
const REGROW_SECONDS: float = 8.0

@export var width: float = 48.0
@export var height: float = 28.0
@export var solid: bool = true
@export var seed_value: int = 1

var smashed: bool = false

var _shape: CollisionShape2D = null
var _top: PackedVector2Array = PackedVector2Array()
var _bits: Array[Dictionary] = []


func _ready() -> void:
	if solid:
		collision_layer = 1
		collision_mask = 0
		add_to_group("garbage_piles")
		_shape = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(width, height * 0.9)
		_shape.shape = rect
		_shape.position = Vector2(0.0, -height * 0.45)
		add_child(_shape)
		z_index = 4
	else:
		collision_layer = 0
		collision_mask = 0
	_build()


func smash() -> void:
	if smashed or not solid:
		return
	smashed = true
	_shape.set_deferred("disabled", true)
	Game.shake(2.0, 0.15)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_interval(REGROW_SECONDS)
	tween.tween_callback(_regrow)


func _regrow() -> void:
	smashed = false
	_shape.set_deferred("disabled", false)
	modulate.a = 1.0


func _build() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + int(width) * 31 + int(height)
	var half: float = width * 0.5
	var steps: int = maxi(int(width / 8.0), 4)
	_top.append(Vector2(-half, 0.0))
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var edge: float = 1.0 - pow(absf(t * 2.0 - 1.0), 6.0) * 0.35
		var lump: float = 0.86 + rng.randf() * 0.14
		_top.append(Vector2(-half + width * t, -height * edge * lump))
	_top.append(Vector2(half, 0.0))
	var count: int = maxi(int(width * height / 90.0), 6)
	for i: int in count:
		_bits.append({
			"pos": Vector2(rng.randf_range(-half + 3.0, half - 3.0), -rng.randf_range(2.0, maxf(height - 3.0, 3.0))),
			"size": Vector2(rng.randf_range(3.0, 8.0), rng.randf_range(2.0, 5.0)),
			"kind": rng.randi() % 5,
		})
	queue_redraw()


func _draw() -> void:
	if _top.size() < 3:
		return
	draw_colored_polygon(_top, BAG_DARK)
	var outline: PackedVector2Array = _top.duplicate()
	outline.append(_top[0])
	draw_polyline(outline, OUTLINE, 1.0)
	for bit: Dictionary in _bits:
		var pos: Vector2 = bit["pos"]
		var size: Vector2 = bit["size"]
		var color: Color = BAG_MID
		match int(bit["kind"]):
			1:
				color = BAG_LIGHT
			2:
				color = BONE
			3:
				color = RUST
		draw_rect(Rect2(pos, size), color)
		if int(bit["kind"]) == 4:
			draw_rect(Rect2(pos + Vector2(1.0, 0.0), Vector2(size.x - 2.0, 1.0)), BAG_LIGHT)
