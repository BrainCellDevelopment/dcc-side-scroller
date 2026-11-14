extends Node2D
## Code-drawn set for the dog pound boss lair (dogpound_lair.gd): cinderblock walls, rows of cages with
## caged dingoes, a bone-and-chair wall, the dirt pit ring on the floor and a municipal sign.

const WALL: Color = Color(0.5, 0.48, 0.45)
const WALL_LINE: Color = Color(0.42, 0.4, 0.38)
const BEAM: Color = Color(0.2, 0.18, 0.18)
const BARS: Color = Color(0.22, 0.24, 0.28)
const BARS_L: Color = Color(0.5, 0.54, 0.6)
const DIRT: Color = Color(0.4, 0.28, 0.18)
const DIRT_D: Color = Color(0.3, 0.2, 0.13)
const DOG: Color = Color(0.45, 0.34, 0.24)
const BONE: Color = Color(0.86, 0.82, 0.7)
const HEIGHT: float = 140.0

var half_width: float = 320.0


func _draw() -> void:
	var w: float = half_width * 2.0 + 48.0
	var left: float = -half_width - 24.0
	draw_rect(Rect2(left, -HEIGHT, w, HEIGHT), WALL)
	for row: int in 4:
		draw_rect(Rect2(left, -HEIGHT + 36.0 * float(row), w, 1.0), WALL_LINE)
	for i: int in 21:
		draw_rect(Rect2(left + 32.0 * float(i) + float(i % 2) * 16.0, -HEIGHT + 4.0, 1.0, 32.0), WALL_LINE)
	draw_rect(Rect2(left, -HEIGHT, w, 8.0), BEAM)
	# cages along the back wall
	var x: float = left + 18.0
	var index: int = 0
	while x < half_width - 40.0:
		_cage(x, -14.0, index)
		x += 62.0
		index += 1
	# the pit: a worn dirt ring on the floor
	draw_rect(Rect2(-half_width + 24.0, -4.0, half_width * 2.0 - 48.0, 4.0), DIRT)
	draw_rect(Rect2(-half_width + 24.0, -4.0, half_width * 2.0 - 48.0, 1.0), DIRT_D)
	for i: int in 16:
		draw_rect(Rect2(-half_width + 40.0 + float(i) * 38.0, -3.0, 6.0, 1.0), DIRT_D)
	# bone and chair wall at the right end
	for i: int in 7:
		var bx: float = half_width - 70.0 + float(i % 4) * 12.0
		var by: float = -26.0 - float(i / 4) * 14.0
		draw_rect(Rect2(bx, by, 10.0, 3.0), BONE)
		draw_circle(Vector2(bx, by + 1.5), 2.0, BONE)
		draw_circle(Vector2(bx + 10.0, by + 1.5), 2.0, BONE)
	# municipal sign
	draw_rect(Rect2(-60.0, -128.0, 120.0, 16.0), Color(0.12, 0.2, 0.34))
	draw_string(ThemeDB.fallback_font, Vector2(-60.0, -116.0), "CANIL MUNICIPAL", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 8, Color(0.9, 0.94, 1.0))


func _cage(x: float, y: float, index: int) -> void:
	var w: float = 50.0
	var h: float = 38.0
	var top: float = y - h - 12.0 - float((index % 2)) * 0.0
	draw_rect(Rect2(x, top, w, h), Color(0.12, 0.1, 0.12))
	if index % 3 != 2:
		# a caged dingo
		draw_circle(Vector2(x + 18.0, top + h - 10.0), 9.0, DOG)
		draw_circle(Vector2(x + 30.0, top + h - 14.0), 6.0, DOG)
		draw_rect(Rect2(x + 29.0, top + h - 21.0, 2.0, 5.0), Color(0.1, 0.08, 0.08))
		draw_circle(Vector2(x + 31.0, top + h - 15.0), 1.0, Color(0.95, 0.2, 0.15))
	for i: int in 6:
		draw_rect(Rect2(x + 3.0 + float(i) * 8.0, top, 1.5, h), BARS_L)
	draw_rect(Rect2(x, top, w, 2.0), BARS)
	draw_rect(Rect2(x, top + h - 2.0, w, 2.0), BARS)
	draw_rect(Rect2(x - 2.0, top + h, 4.0, 12.0), BARS)
	draw_rect(Rect2(x + w - 2.0, top + h, 4.0, 12.0), BARS)
