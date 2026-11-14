extends Node2D
## Code-drawn set for the Level 1 greenroom (greenroom.gd): back wall, ON AIR door, costume rack, couch, vanity.
## glow_only draws just the warm light wash that sits in front of the room.

const COUCH: Color = Color(0.13, 0.27, 0.68)
const COUCH_DARK: Color = Color(0.09, 0.19, 0.5)
const RUG: Color = Color(0.36, 0.1, 0.14)
const BULB: Color = Color(1.0, 0.86, 0.5)
const FRAME: Color = Color(0.2, 0.11, 0.07)
const ROOM_HALF: float = 144.0
const ROOM_H: float = 120.0
const DOOR_X: float = -64.0
const WALL: Color = Color(0.09, 0.2, 0.17)
const WALL_LINE: Color = Color(0.11, 0.24, 0.2)
const BEAM: Color = Color(0.07, 0.05, 0.05)
const WOOD_DARK: Color = Color(0.2, 0.11, 0.07)
const WOOD: Color = Color(0.29, 0.165, 0.094)
const WOOD_LIGHT: Color = Color(0.42, 0.26, 0.15)
const BRASS: Color = Color(0.86, 0.66, 0.26)
const COUCH_LIGHT: Color = Color(0.22, 0.4, 0.86)
const DOOR_GLOW: Color = Color(1.0, 0.82, 0.5, 0.9)
const AIR_RED: Color = Color(0.75, 0.1, 0.12)

var glow_only: bool = false


func _draw() -> void:
	if glow_only:
		_draw_glow()
		return
	var left: float = -ROOM_HALF
	var width: float = ROOM_HALF * 2.0
	draw_rect(Rect2(left, -ROOM_H, width, ROOM_H), WALL)
	for i: int in 13:
		draw_rect(Rect2(left + 22.0 * float(i), -ROOM_H, 1.0, ROOM_H), WALL_LINE)
	draw_rect(Rect2(left, -ROOM_H, width, 10.0), BEAM)
	draw_rect(Rect2(left, -ROOM_H + 10.0, width, 1.0), BRASS)
	draw_rect(Rect2(left, -30.0, width, 30.0), WOOD_DARK)
	draw_rect(Rect2(left, -31.0, width, 2.0), WOOD_LIGHT)
	for i: int in 9:
		draw_rect(Rect2(left + 32.0 * float(i), -28.0, 1.0, 28.0), BEAM)
	draw_rect(Rect2(left, -4.0, width, 4.0), BEAM)
	draw_rect(Rect2(left, -ROOM_H, 6.0, ROOM_H), BEAM)
	draw_rect(Rect2(ROOM_HALF - 6.0, -ROOM_H, 6.0, ROOM_H), BEAM)
	_draw_string_lights(left + 8.0, ROOM_HALF - 8.0)
	_draw_door()
	_draw_costume_rack(-130.0)
	_draw_poster(Vector2(-30.0, -86.0), Vector2(18.0, 24.0), Color(0.62, 0.2, 0.18))
	_draw_poster(Vector2(2.0, -92.0), Vector2(22.0, 16.0), Color(0.22, 0.4, 0.55))
	_draw_couch(-46.0)
	_draw_rug(-60.0, 70.0)
	_draw_vanity(54.0)
	_draw_plant(-98.0)
	_draw_snack_table(94.0)


func _draw_string_lights(x0: float, x1: float) -> void:
	var x: float = x0
	var index: int = 0
	var prev: Vector2 = Vector2(x0, -ROOM_H + 11.0)
	while x <= x1:
		var sag: float = sin((x - x0) / (x1 - x0) * PI * 3.0)
		var pos: Vector2 = Vector2(x, -ROOM_H + 14.0 + absf(sag) * 7.0)
		draw_line(prev, pos, WOOD_DARK, 1.0)
		var tint: Color = BULB if index % 2 == 0 else Color(1.0, 0.62, 0.45)
		draw_circle(pos + Vector2(0.0, 2.0), 3.6, Color(tint.r, tint.g, tint.b, 0.16))
		draw_circle(pos + Vector2(0.0, 2.0), 1.5, tint)
		prev = pos
		x += 14.0
		index += 1


func _draw_door() -> void:
	var cx: float = DOOR_X
	draw_rect(Rect2(cx - 15.0, -64.0, 30.0, 64.0), FRAME)
	draw_rect(Rect2(cx - 12.0, -61.0, 24.0, 61.0), DOOR_GLOW)
	draw_rect(Rect2(cx - 12.0, -61.0, 24.0, 6.0), Color(1.0, 0.95, 0.75, 0.55))
	draw_rect(Rect2(cx - 14.0, -80.0, 28.0, 11.0), Color(0.12, 0.03, 0.04))
	draw_rect(Rect2(cx - 13.0, -79.0, 26.0, 9.0), AIR_RED)
	draw_string(ThemeDB.fallback_font, Vector2(cx - 13.0, -71.5), "ON AIR", HORIZONTAL_ALIGNMENT_CENTER, 26.0, 7, Color(1.0, 0.9, 0.85))
	draw_circle(Vector2(cx, -75.0), 22.0, Color(AIR_RED.r, AIR_RED.g, AIR_RED.b, 0.07))


func _draw_costume_rack(x: float) -> void:
	draw_rect(Rect2(x - 14.0, -52.0, 28.0, 2.0), BRASS)
	draw_rect(Rect2(x - 14.0, -52.0, 2.0, 52.0), BRASS)
	draw_rect(Rect2(x + 12.0, -52.0, 2.0, 52.0), BRASS)
	var cloth: Array[Color] = [Color(0.55, 0.12, 0.2), Color(0.18, 0.4, 0.3), Color(0.7, 0.55, 0.15), Color(0.3, 0.2, 0.5)]
	for i: int in 4:
		var hx: float = x - 10.0 + 7.0 * float(i)
		draw_rect(Rect2(hx, -50.0, 5.0, 2.0), BRASS)
		draw_rect(Rect2(hx - 1.0, -48.0, 7.0, 26.0 - 3.0 * float(i % 2)), cloth[i])


func _draw_poster(top_left: Vector2, size: Vector2, tint: Color) -> void:
	draw_rect(Rect2(top_left - Vector2(2.0, 2.0), size + Vector2(4.0, 4.0)), FRAME)
	draw_rect(Rect2(top_left, size), tint)
	draw_rect(Rect2(top_left + Vector2(3.0, 3.0), Vector2(size.x - 6.0, 3.0)), Color(1.0, 1.0, 1.0, 0.45))
	draw_rect(Rect2(top_left + Vector2(3.0, 9.0), Vector2(size.x - 10.0, 2.0)), Color(1.0, 1.0, 1.0, 0.25))


func _draw_couch(x: float) -> void:
	draw_rect(Rect2(x + 2.0, -32.0, 46.0, 18.0), COUCH_DARK)
	draw_rect(Rect2(x + 2.0, -32.0, 46.0, 3.0), COUCH_LIGHT)
	draw_rect(Rect2(x - 2.0, -22.0, 8.0, 22.0), COUCH)
	draw_rect(Rect2(x + 44.0, -22.0, 8.0, 22.0), COUCH)
	draw_rect(Rect2(x + 4.0, -16.0, 42.0, 12.0), COUCH)
	draw_rect(Rect2(x + 4.0, -16.0, 42.0, 2.0), COUCH_LIGHT)
	draw_rect(Rect2(x, -4.0, 3.0, 4.0), FRAME)
	draw_rect(Rect2(x + 49.0, -4.0, 3.0, 4.0), FRAME)


func _draw_rug(x: float, w: float) -> void:
	draw_rect(Rect2(x, -2.0, w, 2.0), RUG)
	draw_rect(Rect2(x + 3.0, -2.0, w - 6.0, 1.0), BRASS)


func _draw_vanity(x: float) -> void:
	draw_rect(Rect2(x, -70.0, 36.0, 34.0), FRAME)
	draw_rect(Rect2(x + 2.0, -68.0, 32.0, 30.0), Color(0.5, 0.58, 0.66))
	draw_rect(Rect2(x + 4.0, -66.0, 10.0, 4.0), Color(0.8, 0.88, 0.95, 0.5))
	for i: int in 5:
		var bx: float = x + 3.0 + 7.5 * float(i)
		draw_circle(Vector2(bx, -72.0), 3.6, Color(BULB.r, BULB.g, BULB.b, 0.18))
		draw_circle(Vector2(bx, -72.0), 1.6, BULB)
		draw_circle(Vector2(bx, -34.0), 3.6, Color(BULB.r, BULB.g, BULB.b, 0.18))
		draw_circle(Vector2(bx, -34.0), 1.6, BULB)
	draw_rect(Rect2(x - 2.0, -22.0, 40.0, 3.0), WOOD_LIGHT)
	draw_rect(Rect2(x, -19.0, 3.0, 19.0), WOOD)
	draw_rect(Rect2(x + 33.0, -19.0, 3.0, 19.0), WOOD)
	draw_rect(Rect2(x + 4.0, -28.0, 5.0, 6.0), Color(0.7, 0.25, 0.35))
	draw_rect(Rect2(x + 12.0, -26.0, 4.0, 4.0), BRASS)


func _draw_snack_table(x: float) -> void:
	draw_rect(Rect2(x, -18.0, 16.0, 2.0), WOOD_LIGHT)
	draw_rect(Rect2(x + 2.0, -16.0, 2.0, 16.0), WOOD)
	draw_rect(Rect2(x + 12.0, -16.0, 2.0, 16.0), WOOD)
	draw_rect(Rect2(x + 3.0, -23.0, 10.0, 5.0), Color(0.82, 0.8, 0.74))
	draw_rect(Rect2(x + 4.0, -22.0, 8.0, 1.0), Color(0.55, 0.3, 0.2))


func _draw_plant(x: float) -> void:
	draw_rect(Rect2(x - 5.0, -12.0, 10.0, 12.0), Color(0.45, 0.22, 0.14))
	var leaf: Color = Color(0.2, 0.5, 0.3)
	for i: int in 5:
		var angle: float = -PI * 0.5 + (float(i) - 2.0) * 0.5
		draw_line(Vector2(x, -12.0), Vector2(x, -12.0) + Vector2(cos(angle), sin(angle)) * 18.0, leaf, 2.0)


func _draw_glow() -> void:
	for i: int in 3:
		var r: float = 120.0 - 30.0 * float(i)
		draw_circle(Vector2(30.0, -60.0), r, Color(1.0, 0.8, 0.45, 0.018))
