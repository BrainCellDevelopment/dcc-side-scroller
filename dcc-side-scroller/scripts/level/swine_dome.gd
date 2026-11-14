extends Node2D
## Backdrop for the Ball of Swine arena (#67). Before the fight it is a plain brick hall; when the
## walls drop (reveal 0 to 1) the roller-rink dome shows: black light, neon rings, a mirror ball,
## speaker stacks that thump and neon chase lines in the floor grooves.
## layer 0 draws behind the world, layer 1 draws the floor grooves on top of the floor.

const BACK_TOP: float = -460.0
const BACK_BOTTOM: float = 70.0
const PANEL_DROP: float = 520.0
const VIOLET_DARK: Color = Color(0.1, 0.04, 0.23)
const VIOLET: Color = Color(0.2, 0.08, 0.42)
const NEON_VIOLET: Color = Color(0.42, 0.16, 0.82)
const NEON_PINK: Color = Color(0.82, 0.44, 1.0)
const NEON_CYAN: Color = Color(0.3, 0.95, 0.95)
const BRICK: Color = Color(0.18, 0.07, 0.09)
const BRICK_LINE: Color = Color(0.1, 0.04, 0.06)
const BEAT_HZ: float = 2.0

@export var layer: int = 0
@export var half_width: float = 352.0
@export var stairs_left: float = -368.0
@export var stairs_length: float = 160.0

var reveal: float = 0.0
var boss_lane_y: float = 0.0
var beating: bool = false

var _clock: float = 0.0


func _ready() -> void:
	z_index = -1 if layer == 0 else 2


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func beat() -> float:
	if not beating:
		return 0.0
	var phase: float = fposmod(_clock * BEAT_HZ, 1.0)
	return pow(1.0 - phase, 3.0)


func _draw() -> void:
	if layer == 0:
		_draw_back()
	else:
		_draw_floor()


func _draw_back() -> void:
	var left: float = stairs_left - stairs_length
	var right: float = half_width + 20.0
	var height: float = BACK_BOTTOM - BACK_TOP
	if reveal > 0.0:
		draw_rect(Rect2(left, BACK_TOP, right - left, height), VIOLET_DARK)
		_draw_dome(left, right)
	var drop: float = reveal * PANEL_DROP
	draw_rect(Rect2(left, BACK_TOP + drop, right - left, height), BRICK)
	var y: float = BACK_TOP + drop
	var row: int = 0
	while y < BACK_BOTTOM + drop:
		draw_line(Vector2(left, y), Vector2(right, y), BRICK_LINE, 2.0)
		var x: float = left + (0.0 if row % 2 == 0 else 14.0)
		while x < right:
			draw_line(Vector2(x, y), Vector2(x, y + 14.0), BRICK_LINE, 2.0)
			x += 28.0
		y += 14.0
		row += 1
	_draw_stairs(left)


func _draw_dome(left: float, right: float) -> void:
	var pulse: float = beat()
	var center: Vector2 = Vector2(0.0, -150.0)
	for i: int in 5:
		var radius: float = 70.0 + float(i) * 58.0 + pulse * 3.0
		var color: Color = NEON_VIOLET if i % 2 == 0 else NEON_PINK
		draw_arc(center, radius, PI, TAU, 48, Color(color, (0.3 + 0.35 * pulse) * reveal), 3.0)
	draw_circle(Vector2(0.0, -330.0), 14.0 + pulse * 2.0, Color(0.85, 0.85, 1.0, reveal))
	for i: int in 9:
		var a: float = PI * 0.15 + float(i) * PI * 0.7 / 8.0 + sin(_clock * 0.8 + float(i)) * 0.08
		var tip: Vector2 = Vector2(0.0, -330.0) + Vector2(cos(a), sin(a)) * 520.0
		var color2: Color = NEON_CYAN if i % 3 == 0 else NEON_PINK
		draw_line(Vector2(0.0, -330.0), tip, Color(color2, 0.1 + 0.12 * pow(sin(_clock * 3.0 + float(i) * 1.7), 2.0)), 2.0)
	for side: float in [-1.0, 1.0]:
		var sx: float = side * (half_width - 14.0)
		for i: int in 3:
			var h: float = 22.0 - float(i) * 0.0
			var cy: float = -h * float(i + 1)
			draw_rect(Rect2(sx - 14.0, cy, 28.0, h), Color(0.08, 0.06, 0.1))
			draw_circle(Vector2(sx, cy + h * 0.5), 7.0 + pulse * 1.5, Color(0.2, 0.15, 0.3))
			draw_circle(Vector2(sx, cy + h * 0.5), 3.0, Color(NEON_PINK, 0.5 + 0.5 * pulse))
	var wall_glow: float = 0.15 + 0.25 * pulse
	draw_rect(Rect2(left, -300.0, 4.0, 300.0), Color(NEON_CYAN, wall_glow * reveal))
	draw_rect(Rect2(right - 4.0, -300.0, 4.0, 300.0), Color(NEON_CYAN, wall_glow * reveal))


func _draw_stairs(left: float) -> void:
	var run: float = 18.0
	for i: int in 7:
		var x: float = left + 12.0 + float(i) * run
		var h: float = 8.0 + float(i) * 8.0
		draw_rect(Rect2(x, -h, run, h), Color(0.22, 0.12, 0.14))
		draw_line(Vector2(x, -h), Vector2(x + run, -h), Color(0.56, 0.4, 0.36), 2.0)
	draw_rect(Rect2(left + 6.0, -96.0, 40.0, 14.0), Color(0.05, 0.03, 0.06))
	draw_string(ThemeDB.fallback_font, Vector2(left + 8.0, -86.0), "STAIRS", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 8, Color(0.4, 1.0, 0.5))


func _draw_floor() -> void:
	if reveal <= 0.0:
		return
	var y: float = 1.0
	var left: float = -half_width
	var width: float = half_width * 2.0
	var pulse: float = beat()
	draw_rect(Rect2(left, y, width, 3.0), Color(NEON_VIOLET, (0.55 + 0.35 * pulse) * reveal))
	var chase: float = fposmod(_clock * 90.0, 40.0)
	var x: float = left - 40.0 + chase
	var k: int = 0
	while x < left + width:
		var color: Color = NEON_CYAN if k % 3 == 0 else NEON_PINK
		var x0: float = maxf(x, left)
		var x1: float = minf(x + 18.0, left + width)
		if x1 > x0:
			draw_rect(Rect2(x0, y + 5.0, x1 - x0, 2.0), Color(color, 0.85 * reveal))
		x += 40.0
		k += 1
	for lane: int in 3:
		var ly: float = -48.0 * float(lane) - 1.0
		if lane > 0:
			draw_rect(Rect2(left, ly, width, 2.0), Color(NEON_VIOLET, 0.6 * reveal))
