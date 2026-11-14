extends StaticBody2D

signal opened

@export var size: Vector2 = Vector2(16.0, 80.0)

var is_open: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("destructibles")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0.0, -size.y * 0.5)
	shape.name = "CollisionShape2D"
	add_child(shape)
	z_index = 5


# Only a blast opens this door. Called by Explosives.blast.
func blast(_center: Vector2) -> void:
	if is_open:
		return
	is_open = true
	(get_node("CollisionShape2D") as CollisionShape2D).set_deferred("disabled", true)
	remove_from_group("destructibles")
	Game.shake(3.0, 0.25)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	opened.emit()


func _draw() -> void:
	var rect: Rect2 = Rect2(-size.x * 0.5, -size.y, size.x, size.y)
	draw_rect(rect, Color(0.32, 0.3, 0.3))
	draw_rect(rect, Color(0.15, 0.14, 0.14), false, 2.0)
	for i: int in 3:
		var y: float = -size.y + size.y * (float(i) + 0.5) / 3.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.9, 0.7, 0.1), 2.0)
