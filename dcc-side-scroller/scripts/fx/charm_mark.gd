extends Node2D
## A small bobbing heart over a neutral goblin (charm or Goblin Pass).

var faint: bool = false
var _t: float = 0.0
var _pop: float = 0.0


func pulse() -> void:
	_pop = 1.0


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(_pop - delta * 2.0, 0.0)
	position.y = -34.0 + sin(_t * 3.0) * 1.5
	scale = Vector2.ONE * (1.0 + _pop * 0.8)
	modulate.a = 0.45 if faint else 1.0
	queue_redraw()


func _draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		var a: float = TAU * float(i) / 24.0
		var x: float = 16.0 * pow(sin(a), 3.0)
		var y: float = 13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a)
		pts.append(Vector2(x, -y) * 0.3)
	draw_colored_polygon(pts, Color(1.0, 0.35, 0.6))
