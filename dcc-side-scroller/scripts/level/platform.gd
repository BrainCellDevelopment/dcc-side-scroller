@tool
extends StaticBody2D

const TILE: int = 16
const CAP_H: int = 5
const EDGE_W: int = 3
const TEXTURES: Array = [
	preload("res://assets/tiles/tiles_rubble.png"),
	preload("res://assets/tiles/tiles_iron.png"),
	preload("res://assets/tiles/tiles_stone.png"),
	preload("res://assets/tiles/tiles_wood.png"),
	preload("res://assets/tiles/tiles_brick.png"),
	preload("res://assets/tiles/tiles_wetstone.png"),
	preload("res://assets/tiles/tiles_plank.png"),
]
const OUTLINES: Array = [
	Color(0.1059, 0.0706, 0.149),
	Color(0.0706, 0.0627, 0.1098),
	Color(0.0706, 0.0627, 0.1216),
	Color(0.1216, 0.0784, 0.0627),
	Color(0.0471, 0.0196, 0.0314),
	Color(0.0471, 0.0706, 0.0863),
	Color(0.0706, 0.0392, 0.0314),
]

@export var size: Vector2 = Vector2(64, 16):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_refresh()
@export_enum("Rubble", "Iron", "Stone", "Wood", "Brick", "WetStone", "Plank") var style: int = 2:
	set(value):
		style = clampi(value, 0, TEXTURES.size() - 1)
		_refresh()
@export var one_way: bool = false:
	set(value):
		one_way = value
		_refresh()

@export var snow: bool = false:
	set(value):
		snow = value
		_refresh()

const SNOW_TOP: Color = Color(0.62, 0.72, 0.86, 1.0)
const SNOW_BODY: Color = Color(0.42, 0.5, 0.66, 1.0)
const SNOW_SHADE: Color = Color(0.28, 0.34, 0.5, 1.0)

var _shape: CollisionShape2D = null


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		add_child(_shape)
	_update_shape()
	queue_redraw()


func _refresh() -> void:
	if not is_node_ready():
		return
	_update_shape()
	queue_redraw()


func _update_shape() -> void:
	if _shape == null:
		return
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size * 0.5
	_shape.one_way_collision = one_way


func _variant(cx: int, cy: int) -> int:
	var h: int = (cx * 374761393 + cy * 668265263 + style * 144665) & 0x7FFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF
	return (h >> 7) & 1


func _draw() -> void:
	var tex: Texture2D = TEXTURES[style]
	var cols: int = ceili(size.x / float(TILE))
	var rows: int = ceili(size.y / float(TILE))
	var edge_left_src: float = float(TILE * 3 + 1)
	var edge_right_src: float = float(TILE * 3 + 12)
	for ry: int in rows:
		var y: float = float(ry * TILE)
		var th: float = minf(float(TILE), size.y - y)
		for cx: int in cols:
			var x: float = float(cx * TILE)
			var tw: float = minf(float(TILE), size.x - x)
			var src_x: float = 0.0
			if ry > 0:
				src_x = float(TILE + TILE * _variant(cx, ry))
			draw_texture_rect_region(tex, Rect2(x, y, tw, th), Rect2(src_x, 0.0, tw, th))
		var y0: float = 0.0
		if ry == 0:
			y0 = float(CAP_H)
		if th > y0 and size.x >= 8.0:
			var eh: float = th - y0
			draw_texture_rect_region(tex, Rect2(1.0, y + y0, float(EDGE_W), eh), Rect2(edge_left_src, y0, float(EDGE_W), eh))
			draw_texture_rect_region(tex, Rect2(size.x - 1.0 - float(EDGE_W), y + y0, float(EDGE_W), eh), Rect2(edge_right_src, y0, float(EDGE_W), eh))
	if size.y >= 16.0 and size.x > 2.0:
		draw_rect(Rect2(1.0, size.y - 3.0, size.x - 2.0, 2.0), Color(0.0, 0.0, 0.0, 0.45))
	if snow:
		_draw_snow()
	var outline: Color = OUTLINES[style]
	draw_rect(Rect2(0.0, 0.0, 1.0, size.y), outline)
	draw_rect(Rect2(size.x - 1.0, 0.0, 1.0, size.y), outline)
	draw_rect(Rect2(0.0, size.y - 1.0, size.x, 1.0), outline)


func _draw_snow() -> void:
	var inset: float = 1.0
	var x: float = inset
	var end: float = size.x - inset
	while x < end:
		var h: int = (int(x) * 2654435761 + int(global_position.x) * 40503) & 0x7FFFFFFF
		var w: float = minf(float(2 + (h >> 4) % 3), end - x)
		var depth: float = 3.0 + float((h >> 9) % 3)
		var lift: float = float((h >> 13) % 2)
		draw_rect(Rect2(x, -lift, w, lift + depth), SNOW_BODY)
		draw_rect(Rect2(x, -lift, w, 1.0), SNOW_TOP)
		draw_rect(Rect2(x, depth - 1.0, w, 1.0), SNOW_SHADE)
		x += w
