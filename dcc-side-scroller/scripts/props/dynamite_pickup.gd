extends Area2D

const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")

@export var count: int = 2

var _t: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if Explosives.add_stack(count):
		Game.hint_changed.emit("Goblin Dynamite x%d. G to throw" % count)
		queue_free()


func _draw() -> void:
	var bob: float = sin(_t * 3.0) * 2.0
	draw_rect(Rect2(-3.0, -10.0 + bob, 6.0, 10.0), Color(0.75, 0.15, 0.12))
	draw_rect(Rect2(-3.0, -6.0 + bob, 6.0, 2.0), Color(0.95, 0.9, 0.7))
	draw_circle(Vector2(1.0, -12.0 + bob), 1.5, Color(1.0, 0.8, 0.2))
