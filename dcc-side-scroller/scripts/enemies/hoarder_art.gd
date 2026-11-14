extends Node2D
## Drawn placeholder art for the Hoarder (faces +x; the body flips Visual.scale.x).
## Garbage-bag browns from the Floor 1 palette; pose follows the boss state.

const OUTLINE: Color = Color("0c0508")
const BAG_DARK: Color = Color("3a2c1a")
const BAG_MID: Color = Color("5e4a28")
const BAG_LIGHT: Color = Color("8a7440")
const SKIN: Color = Color("c8b692")
const SKIN_SHADE: Color = Color("8a7866")
const BURN: Color = Color("4a1c20")
const SORE: Color = Color("b85c42")
const HAIR: Color = Color("2e1218")
const MOUTH: Color = Color("1a0a10")

var _boss: CharacterBody2D = null
var _t: float = 0.0
var _lean: float = 0.0
var _head_drop: float = 0.0
var _arm: float = 0.0
var _squat: float = 0.0
var _open: float = 0.0


func _ready() -> void:
	_boss = get_parent() as CharacterBody2D
	z_index = 3


func _process(delta: float) -> void:
	_t += delta
	if _boss == null:
		return
	var target_lean: float = 0.0
	var target_head: float = 0.0
	var target_arm: float = 0.0
	var target_squat: float = 0.0
	var target_open: float = 0.0
	match int(_boss.get("state")):
		1:
			target_lean = 2.0 + sin(_t * 8.0)
		2:
			target_arm = 1.0
			target_head = -3.0
		3:
			target_arm = -0.4
			target_squat = 5.0
		4:
			target_lean = 12.0
			target_head = 16.0
			target_open = 1.0
		5:
			target_lean = 8.0
			target_squat = 4.0 + sin(_t * 40.0)
		6:
			target_lean = 14.0
			target_arm = -0.3
		8:
			target_lean = 6.0
			target_head = 12.0
			target_arm = -0.2
		9:
			target_lean = 12.0
			target_head = 22.0
			target_squat = 18.0
			target_arm = -0.6
	var k: float = clampf(delta * 12.0, 0.0, 1.0)
	_lean = lerpf(_lean, target_lean, k)
	_head_drop = lerpf(_head_drop, target_head, k)
	_arm = lerpf(_arm, target_arm, k)
	_squat = lerpf(_squat, target_squat, k)
	_open = lerpf(_open, target_open, k)
	queue_redraw()


func _draw() -> void:
	var s: float = _squat
	var lean: float = _lean
	var sway: float = sin(_t * 8.0) * 2.0 if _boss != null and int(_boss.get("state")) == 1 else 0.0
	_leg(-9.0 + sway, s)
	_leg(7.0 - sway, s)
	var hip: Vector2 = Vector2(0.0, -18.0 + s)
	var shoulder: Vector2 = Vector2(lean * 0.6, -46.0 + s)
	var torso: PackedVector2Array = PackedVector2Array([
		hip + Vector2(-15.0, 0.0), shoulder + Vector2(-17.0, 6.0), shoulder + Vector2(-8.0, -4.0),
		shoulder + Vector2(10.0, -4.0), shoulder + Vector2(19.0, 8.0), hip + Vector2(15.0, 0.0)])
	draw_colored_polygon(torso, BAG_MID)
	draw_polyline(_closed(torso), OUTLINE, 1.0)
	draw_circle(shoulder + Vector2(-10.0, 1.0), 8.0, BAG_DARK)
	draw_circle(shoulder + Vector2(10.0, 3.0), 9.0, BAG_LIGHT)
	draw_rect(Rect2(hip + Vector2(-10.0, -8.0), Vector2(20.0, 4.0)), BAG_DARK)
	draw_rect(Rect2(shoulder + Vector2(-4.0, 12.0), Vector2(8.0, 6.0)), SORE)
	_arm_draw(shoulder + Vector2(-8.0, 6.0), -1.0)
	var head: Vector2 = shoulder + Vector2(lean * 0.5 + 6.0, -9.0 + _head_drop * 0.9)
	draw_circle(head, 9.0, SKIN)
	draw_arc(head, 9.0, 0.0, TAU, 20, OUTLINE, 1.0)
	draw_circle(head + Vector2(-3.0, -2.0), 4.5, BURN)
	draw_circle(head + Vector2(4.0, 3.0), 1.5, SORE)
	draw_circle(head + Vector2(-5.0, 4.0), 1.0, SORE)
	draw_rect(Rect2(head + Vector2(-9.0, -10.0), Vector2(18.0, 4.0)), HAIR)
	draw_rect(Rect2(head + Vector2(-10.0, -7.0), Vector2(3.0, 12.0)), HAIR)
	draw_rect(Rect2(head + Vector2(2.0, -3.0), Vector2(3.0, 2.0)), OUTLINE)
	var gape: float = 2.0 + _open * 6.0
	draw_rect(Rect2(head + Vector2(2.0, 3.0), Vector2(7.0 + _open * 3.0, gape)), MOUTH)
	_arm_draw(shoulder + Vector2(12.0, 6.0), 1.0)


func _leg(x: float, squat: float) -> void:
	draw_rect(Rect2(x - 5.0, -20.0 + squat, 10.0, 20.0 - squat), BAG_DARK)
	draw_rect(Rect2(x - 6.0, -4.0, 14.0, 4.0), OUTLINE)


func _arm_draw(base: Vector2, side: float) -> void:
	var down: Vector2 = Vector2(side * 4.0, 22.0 + _squat * 0.4)
	var up: Vector2 = Vector2(side * 6.0, -26.0)
	var amount: float = clampf(_arm, -1.0, 1.0)
	var tip: Vector2 = base + (down.lerp(up, amount) if amount >= 0.0 else down + Vector2(side * 6.0 * -amount, 0.0))
	draw_line(base, tip, SKIN_SHADE, 6.0)
	draw_circle(tip, 5.0, SKIN)
	draw_circle(tip + Vector2(0.0, 1.0), 2.0, SORE)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = points.duplicate()
	out.append(points[0])
	return out
