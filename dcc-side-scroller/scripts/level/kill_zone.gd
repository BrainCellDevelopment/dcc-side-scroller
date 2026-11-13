@tool
extends Area2D

@export var size: Vector2 = Vector2(256, 64):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh()

var _shape: CollisionShape2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 6
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		add_child(_shape)
	_update_shape()
	queue_redraw()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _refresh() -> void:
	if not is_node_ready():
		return
	_update_shape()
	queue_redraw()


func _update_shape() -> void:
	if _shape == null:
		return
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size * 0.5


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.1, 0.1, 0.18))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.2, 0.2, 0.6), false, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("kill"):
		body.call_deferred("kill")
	else:
		body.queue_free()
