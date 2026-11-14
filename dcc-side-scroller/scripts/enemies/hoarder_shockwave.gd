extends Area2D
## Ground shockwave from the Hoarder's stomp. Jump it. Garbage piles block it.

const COLOR: Color = Color("8a7440")
const COLOR_DARK: Color = Color("3a2c1a")

var direction: float = 1.0
var speed: float = 150.0
var distance_left: float = 240.0
var damage: int = 1

var _hit: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	monitorable = false
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(14.0, 10.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -5.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	z_index = 9


func _physics_process(delta: float) -> void:
	var step: float = speed * delta
	global_position.x += direction * step
	distance_left -= step
	queue_redraw()
	if distance_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("garbage_piles"):
		queue_free()
		return
	if _hit or not body.is_in_group("player") or not body.has_method("take_damage"):
		return
	if Game.in_safe_zone:
		return
	_hit = true
	body.call("take_damage", damage, global_position)


func _draw() -> void:
	var lean: float = -direction * 5.0
	draw_colored_polygon(PackedVector2Array([Vector2(-7.0, 0.0), Vector2(lean, -11.0), Vector2(7.0, 0.0)]), COLOR)
	draw_colored_polygon(PackedVector2Array([Vector2(-4.0, 0.0), Vector2(lean * 0.6, -6.0), Vector2(4.0, 0.0)]), COLOR_DARK)
