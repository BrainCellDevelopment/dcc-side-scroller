extends Node2D

const BAR_WIDTH: int = 20
const OUTLINE: Color = Color(0.106, 0.071, 0.149, 1.0)
const BACK: Color = Color(0.29, 0.1, 0.17, 1.0)
const FILL: Color = Color(0.87, 0.16, 0.24, 1.0)
const HIGHLIGHT: Color = Color(1.0, 0.45, 0.4, 1.0)

var _ratio: float = 1.0


func _ready() -> void:
	visible = false


func _draw() -> void:
	draw_rect(Rect2(-11.0, 0.0, 22.0, 4.0), OUTLINE)
	draw_rect(Rect2(-10.0, 1.0, float(BAR_WIDTH), 2.0), BACK)
	var filled: int = clampi(roundi(float(BAR_WIDTH) * _ratio), 1, BAR_WIDTH)
	draw_rect(Rect2(-10.0, 1.0, float(filled), 2.0), FILL)
	draw_rect(Rect2(-10.0, 1.0, float(filled), 1.0), HIGHLIGHT)


func update_health(current: int, maximum: int) -> void:
	if maximum <= 0 or current <= 0 or current >= maximum:
		visible = false
		return
	_ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	visible = true
	queue_redraw()
