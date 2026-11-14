extends Node2D

const REACH: float = 60000.0
const TOP: float = -4000.0
const BOTTOM: float = 6000.0

@export var edge_x: float = 0.0
@export var feather: float = 96.0
@export var fade_from: float = 10.0
@export var fade_to: float = 120.0
@export var tint: Color = Color(0.02, 0.012, 0.04, 1.0)

var reveal: float = 0.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		queue_redraw()

var _behind: float = 0.0


func _ready() -> void:
	z_index = 40
	_refresh(true)


func _process(_delta: float) -> void:
	_refresh(false)


func _refresh(force: bool) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var x: float = player.global_position.x
	var behind: float = smoothstep(edge_x + fade_from, edge_x + fade_to, x)
	if not force and is_equal_approx(behind, _behind):
		return
	_behind = behind
	queue_redraw()


func _draw() -> void:
	_draw_side(1.0, 1.0 - reveal)
	_draw_side(-1.0, _behind)


func _draw_side(direction: float, amount: float) -> void:
	if amount <= 0.001:
		return
	var solid: Color = Color(tint.r, tint.g, tint.b, amount)
	var clear: Color = Color(tint.r, tint.g, tint.b, 0.0)
	var inner: float = edge_x + direction * feather
	draw_polygon(
		PackedVector2Array([Vector2(edge_x, TOP), Vector2(inner, TOP), Vector2(inner, BOTTOM), Vector2(edge_x, BOTTOM)]),
		PackedColorArray([clear, solid, solid, clear])
	)
	var far: float = inner + direction * REACH
	draw_rect(Rect2(minf(inner, far), TOP, absf(far - inner), BOTTOM - TOP), solid)
