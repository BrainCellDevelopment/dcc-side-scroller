extends Node2D
## Mongo the Mongoliensis: a seven-inch, pink-downed, plucked-chicken-looking raptor pup that follows Carl
## and bites Donut's nose. Code-drawn placeholder. Follows the player with a lag; bobs and hops.

const FOLLOW_RATE: float = 6.0
const BACK: float = 22.0
const PINK: Color = Color(1.0, 0.66, 0.74)
const PINK_D: Color = Color(0.86, 0.44, 0.56)
const BELLY: Color = Color(1.0, 0.86, 0.88)
const TOOTH: Color = Color(1.0, 1.0, 0.95)

var target: Node2D = null

var _clock: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_clock += delta
	if target != null and is_instance_valid(target):
		var face: float = float(target.get("facing")) if target.get("facing") != null else 1.0
		var goal: Vector2 = target.global_position + Vector2(-face * BACK, 0.0)
		global_position = global_position.lerp(goal, 1.0 - exp(-FOLLOW_RATE * delta))
		_facing = face
	queue_redraw()


func _draw() -> void:
	var f: float = _facing
	var hop: float = absf(sin(_clock * 7.0)) * 2.5
	var y: float = -hop
	# serpentine tail
	draw_line(Vector2(-6.0 * f, y - 5.0), Vector2(-14.0 * f, y - 3.0 + sin(_clock * 6.0) * 2.0), PINK_D, 2.0)
	# legs
	draw_line(Vector2(-1.0 * f, y - 3.0), Vector2(-1.0 * f, 0.0), PINK_D, 1.5)
	draw_line(Vector2(3.0 * f, y - 3.0), Vector2(3.0 * f, 0.0), PINK_D, 1.5)
	# body and downy belly
	draw_circle(Vector2(0.0, y - 7.0), 6.0, PINK)
	draw_circle(Vector2(1.0 * f, y - 5.0), 3.5, BELLY)
	# tiny forearms
	draw_line(Vector2(4.0 * f, y - 6.0), Vector2(7.0 * f, y - 4.0), PINK_D, 1.0)
	# head, eye, teeth
	draw_circle(Vector2(5.0 * f, y - 12.0), 4.0, PINK)
	draw_circle(Vector2(6.5 * f, y - 13.0), 0.9, Color(0.1, 0.04, 0.08))
	draw_line(Vector2(7.0 * f, y - 10.5), Vector2(10.0 * f, y - 10.5), PINK_D, 1.5)
	draw_rect(Rect2(8.0 * f - 0.5, y - 10.0, 1.0, 1.5), TOOTH)
