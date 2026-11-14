extends Node2D
## Expanding purple ring when a Shamanka casts anguish.

var radius: float = 150.0
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.6:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k: float = _t / 0.6
	draw_arc(Vector2.ZERO, radius * k, 0.0, TAU, 48, Color(0.75, 0.3, 0.95, 1.0 - k), 2.0)
	draw_arc(Vector2.ZERO, radius * k * 0.7, 0.0, TAU, 40, Color(1.0, 0.5, 0.6, (1.0 - k) * 0.7), 1.0)
