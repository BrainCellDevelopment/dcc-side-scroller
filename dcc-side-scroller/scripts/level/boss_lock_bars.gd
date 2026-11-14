extends Node2D
## Glowing forcefield bars drawn over an arena wall. Visible only while locked.

const BAR_COLOR: Color = Color(1.0, 0.25, 0.2)
const GLOW_COLOR: Color = Color(1.0, 0.2, 0.15, 0.25)
const BAR_SPACING: float = 12.0

var size: Vector2 = Vector2(16.0, 720.0)
var _time: float = 0.0


func _ready() -> void:
	z_index = 40
	visible = false
	set_process(false)


func set_locked(value: bool) -> void:
	visible = value
	set_process(value)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.6 + 0.4 * sin(_time * 5.0)
	draw_rect(Rect2(-size.x, -size.y * 0.5, size.x * 2.0, size.y), Color(GLOW_COLOR, GLOW_COLOR.a * pulse))
	var count: int = int(size.y / BAR_SPACING)
	for i: int in count:
		var y: float = -size.y * 0.5 + BAR_SPACING * 0.5 + float(i) * BAR_SPACING
		draw_rect(Rect2(-2.0, y - 1.5, 4.0, 3.0), Color(BAR_COLOR, 0.5 + 0.5 * pulse))
	draw_rect(Rect2(-1.0, -size.y * 0.5, 2.0, size.y), Color(BAR_COLOR, 0.35 + 0.4 * pulse))
