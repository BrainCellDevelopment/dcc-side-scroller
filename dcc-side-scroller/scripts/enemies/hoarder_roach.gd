extends StaticBody2D
## The weak point: a cockroach sitting in the Hoarder's mouth. One hit kills it.

signal killed(roach: Node)

const SHELL: Color = Color("2e1218")
const SHELL_LIGHT: Color = Color("6b2b2a")
const GLOW: Color = Color(1.0, 0.85, 0.3, 0.9)

var health: int = 1
var dead: bool = false

var _t: float = 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("enemies")
	add_to_group("hoarder_roach")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	# The mouth sits about 50 px above her feet, higher than a standing punch reaches, so the
	# hurtbox extends down over her chin and chest (the roach itself is drawn at the origin).
	rect.size = Vector2(20.0, 38.0)
	shape.position = Vector2(0.0, 12.0)
	shape.shape = rect
	add_child(shape)
	z_index = 12


func is_dead() -> bool:
	return dead


func take_damage(_amount: int, _from: Vector2) -> void:
	if dead:
		return
	dead = true
	health = 0
	killed.emit(self)
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var ring: float = 9.0 + sin(_t * 12.0) * 1.5
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 16, GLOW, 1.0)
	var wiggle: float = sin(_t * 30.0) * 1.0
	draw_rect(Rect2(-5.0, -3.0 + wiggle, 10.0, 6.0), SHELL)
	draw_rect(Rect2(-4.0, -2.0 + wiggle, 8.0, 2.0), SHELL_LIGHT)
	draw_line(Vector2(-5.0, -3.0), Vector2(-9.0, -6.0 - wiggle), SHELL, 1.0)
	draw_line(Vector2(5.0, -3.0), Vector2(9.0, -6.0 + wiggle), SHELL, 1.0)
	draw_line(Vector2(-3.0, 3.0), Vector2(-6.0, 6.0), SHELL, 1.0)
	draw_line(Vector2(3.0, 3.0), Vector2(6.0, 6.0 - wiggle), SHELL, 1.0)
