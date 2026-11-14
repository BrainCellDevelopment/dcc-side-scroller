extends Node2D
## Code-drawn set for the Floor 2 storm shelter (storm_shelter.gd): concrete walls, fluorescent tubes,
## French restroom signs, rows of dusty cots, old TVs and the mailbox.

const HALF: float = 384.0
const HEIGHT: float = 150.0
const WALL: Color = Color(0.6, 0.6, 0.57)
const WALL_LINE: Color = Color(0.5, 0.5, 0.47)
const WALL_DARK: Color = Color(0.42, 0.42, 0.4)
const SKIRT: Color = Color(0.32, 0.32, 0.3)
const TUBE: Color = Color(0.96, 0.98, 0.92)
const COT_FRAME: Color = Color(0.3, 0.3, 0.32)
const SIGN_GREEN: Color = Color(0.12, 0.5, 0.3)
const ORANGE: Color = Color(1.0, 0.54, 0.12)

var mailbox_x: float = 250.0
var mail_open: bool = false


func _draw() -> void:
	draw_rect(Rect2(-HALF, -HEIGHT, HALF * 2.0, HEIGHT), WALL)
	for i: int in 25:
		draw_rect(Rect2(-HALF + 32.0 * float(i), -HEIGHT, 1.0, HEIGHT), WALL_LINE)
	for row: int in 4:
		draw_rect(Rect2(-HALF, -HEIGHT + 36.0 * float(row), HALF * 2.0, 1.0), WALL_LINE)
	draw_rect(Rect2(-HALF, -HEIGHT, HALF * 2.0, 8.0), WALL_DARK)
	draw_rect(Rect2(-HALF, -10.0, HALF * 2.0, 10.0), SKIRT)
	_draw_tubes()
	_draw_signs()
	_draw_cots(-340.0, 6)
	_draw_cots(100.0, 3)
	_draw_tvs(-128.0)
	_draw_mailbox(mailbox_x)
	_draw_stains()


func _draw_tubes() -> void:
	for i: int in 6:
		var x: float = -330.0 + 130.0 * float(i)
		draw_rect(Rect2(x, -HEIGHT + 12.0, 44.0, 3.0), TUBE)
		draw_rect(Rect2(x - 2.0, -HEIGHT + 15.0, 48.0, 14.0), Color(TUBE.r, TUBE.g, TUBE.b, 0.07))


func _draw_signs() -> void:
	for x: float in [-200.0, 200.0]:
		draw_rect(Rect2(x - 22.0, -112.0, 44.0, 12.0), SIGN_GREEN)
		draw_rect(Rect2(x - 22.0, -112.0, 44.0, 1.0), Color(1.0, 1.0, 1.0, 0.5))
		draw_string(ThemeDB.fallback_font, Vector2(x - 22.0, -103.0), "TOILETTES", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 7, Color(0.95, 1.0, 0.95))
	draw_rect(Rect2(-60.0, -118.0, 120.0, 12.0), Color(0.12, 0.12, 0.14))
	draw_string(ThemeDB.fallback_font, Vector2(-60.0, -109.0), "ABRI ANTI-TEMPETE", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 7, Color(0.9, 0.9, 0.8))


func _draw_cots(x0: float, count: int) -> void:
	for i: int in count:
		var x: float = x0 + 40.0 * float(i)
		var blanket: Color = Color(0.58, 0.5, 0.4) if i % 2 == 0 else Color(0.46, 0.5, 0.56)
		draw_rect(Rect2(x, -18.0, 32.0, 4.0), COT_FRAME)
		draw_rect(Rect2(x + 1.0, -18.0, 2.0, 18.0), COT_FRAME)
		draw_rect(Rect2(x + 29.0, -18.0, 2.0, 18.0), COT_FRAME)
		draw_rect(Rect2(x + 3.0, -23.0, 26.0, 6.0), blanket)
		draw_rect(Rect2(x + 3.0, -26.0, 9.0, 4.0), Color(0.82, 0.8, 0.74))
		draw_rect(Rect2(x + 3.0, -23.0, 26.0, 1.0), Color(1.0, 1.0, 1.0, 0.2))
		draw_rect(Rect2(x + 3.0, -17.0, 26.0, 2.0), Color(0.7, 0.66, 0.58, 0.55))


func _draw_tvs(x: float) -> void:
	draw_rect(Rect2(x - 2.0, -22.0, 70.0, 3.0), Color(0.25, 0.2, 0.17))
	draw_rect(Rect2(x, -19.0, 3.0, 19.0), Color(0.25, 0.2, 0.17))
	draw_rect(Rect2(x + 63.0, -19.0, 3.0, 19.0), Color(0.25, 0.2, 0.17))
	for i: int in 2:
		var tx: float = x + 3.0 + 32.0 * float(i)
		draw_rect(Rect2(tx, -44.0, 28.0, 22.0), Color(0.16, 0.16, 0.18))
		draw_rect(Rect2(tx + 2.0, -42.0, 20.0, 16.0), Color(0.3, 0.46, 0.5) if i == 0 else Color(0.22, 0.3, 0.34))
		draw_rect(Rect2(tx + 4.0, -40.0, 8.0, 3.0), Color(1.0, 1.0, 1.0, 0.25))
		draw_rect(Rect2(tx + 24.0, -40.0, 2.0, 2.0), ORANGE)


func _draw_mailbox(x: float) -> void:
	draw_rect(Rect2(x - 2.0, -20.0, 4.0, 20.0), Color(0.3, 0.22, 0.16))
	draw_rect(Rect2(x - 12.0, -34.0, 24.0, 14.0), Color(0.15, 0.3, 0.6))
	draw_rect(Rect2(x - 12.0, -34.0, 24.0, 2.0), Color(0.3, 0.46, 0.8))
	draw_rect(Rect2(x - 8.0, -29.0, 16.0, 2.0), Color(0.05, 0.08, 0.18))
	var flag_y: float = -40.0 if not mail_open else -30.0
	draw_rect(Rect2(x + 12.0, flag_y, 2.0, 10.0), Color(0.5, 0.5, 0.5))
	draw_rect(Rect2(x + 12.0, flag_y, 7.0, 4.0), Color(0.85, 0.15, 0.12))
	if not mail_open:
		draw_circle(Vector2(x, -42.0), 9.0, Color(1.0, 0.9, 0.5, 0.12))


func _draw_stains() -> void:
	for i: int in 8:
		var x: float = -300.0 + 85.0 * float(i)
		draw_rect(Rect2(x, -70.0 - float(i % 3) * 10.0, 3.0, 12.0 + float(i % 4) * 4.0), Color(0.45, 0.4, 0.34, 0.5))
