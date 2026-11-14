extends CanvasLayer

const STYLES: Array = [
	{
		"name": "street",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "05080f", "bottom": "2c4064"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "17233b"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "080d1a"},
		],
	},
	{
		"name": "stairwell",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "070b16", "bottom": "0a1020"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "0a1020"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "070b14"},
		],
	},
	{
		"name": "tunnel",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "0b0e1b", "bottom": "0d1020"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "12172c"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "090c18"},
		],
	},
	{
		"name": "guildhall",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "150f1c", "bottom": "1d110d"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "2a170f"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "140b08"},
		],
	},
	{
		"name": "floor1",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "1a0a10", "bottom": "0e0709"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "150a0d"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "0a0507"},
		],
	},
	{
		"name": "floor1_artery",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "10080b", "bottom": "160b0d"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "1a0d0f"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "0b0608"},
		],
	},
	{
		"name": "floor1_corridor",
		"layers": [
			{"file": "far", "fx": 0.1, "fy": 0.04, "top": "08040a", "bottom": "0d0708"},
			{"file": "mid", "fx": 0.3, "fy": 0.1, "top": "", "bottom": "120a0c"},
			{"file": "near", "fx": 0.55, "fy": 0.18, "top": "", "bottom": "08040a"},
		],
	},
]
const FILL_EXTENT: float = 6000.0

@export_enum("Street", "Stairwell", "Tunnel", "Guildhall", "Floor1", "Floor1Artery", "Floor1Corridor") var initial_style: int = 0
@export var anchor_cam_y: float = 180.0

var current_style: int = -1

var _roots: Dictionary = {}
var _layer_data: Dictionary = {}
var _fade_tween: Tween = null


func _ready() -> void:
	layer = -10
	process_priority = 100
	if current_style < 0:
		set_style(initial_style, 0.0)


func set_style(style_index: int, fade_time: float = 0.8) -> void:
	if style_index < 0 or style_index >= STYLES.size():
		return
	if style_index == current_style:
		return
	var previous: int = current_style
	current_style = style_index
	var root: Node2D = _get_root(style_index)
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	for key: Variant in _roots.keys():
		if int(key) != previous and int(key) != style_index:
			(_roots[key] as Node2D).visible = false
	root.visible = true
	move_child(root, get_child_count() - 1)
	_update_style(style_index)
	if previous < 0 or fade_time <= 0.0 or not is_inside_tree():
		root.modulate.a = 1.0
		if previous >= 0:
			(_roots[previous] as Node2D).visible = false
		return
	var old_root: Node2D = _roots[previous] as Node2D
	old_root.modulate.a = 1.0
	root.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(root, "modulate:a", 1.0, fade_time)
	_fade_tween.tween_callback(old_root.hide)


func _get_root(style_index: int) -> Node2D:
	if _roots.has(style_index):
		return _roots[style_index] as Node2D
	var def: Dictionary = STYLES[style_index]
	var root: Node2D = Node2D.new()
	root.name = "Style_" + String(def["name"])
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)
	var data: Array = []
	for item: Variant in def["layers"]:
		var ld: Dictionary = item
		var tex: Texture2D = load("res://assets/bg/bg_%s_%s.png" % [def["name"], ld["file"]]) as Texture2D
		var entry: Dictionary = {
			"fx": float(ld["fx"]),
			"fy": float(ld["fy"]),
			"tw": float(tex.get_width()),
			"th": float(tex.get_height()),
			"top_fill": null,
			"bottom_fill": null,
		}
		if String(ld["top"]) != "":
			entry["top_fill"] = _make_fill(root, Color.html(String(ld["top"])))
		if String(ld["bottom"]) != "":
			entry["bottom_fill"] = _make_fill(root, Color.html(String(ld["bottom"])))
		var rect: TextureRect = TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_TILE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(rect)
		entry["rect"] = rect
		data.append(entry)
	_roots[style_index] = root
	_layer_data[style_index] = data
	return root


func _make_fill(parent: Node2D, color: Color) -> ColorRect:
	var fill: ColorRect = ColorRect.new()
	fill.color = color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)
	return fill


func _process(_delta: float) -> void:
	for key: Variant in _roots.keys():
		if (_roots[key] as Node2D).visible:
			_update_style(int(key))


func _update_style(style_index: int) -> void:
	if not is_inside_tree():
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	var cam_pos: Vector2 = Vector2(view.x * 0.5, anchor_cam_y)
	if get_viewport().get_camera_2d() != null:
		cam_pos = get_viewport().get_canvas_transform().affine_inverse() * (view * 0.5)
	var scale: float = maxf(1.0, float(get_window().size.y) / view.y)
	var data: Array = _layer_data[style_index]
	for item: Variant in data:
		var entry: Dictionary = item
		var tw: float = entry["tw"]
		var th: float = entry["th"]
		var origin_x: float = roundf((view.x * 0.5 - cam_pos.x * float(entry["fx"])) * scale) / scale
		var start_x: float = fposmod(origin_x, tw) - tw
		var top_y: float = roundf((view.y * 0.5 - th * 0.5 - (cam_pos.y - anchor_cam_y) * float(entry["fy"])) * scale) / scale
		var rect: TextureRect = entry["rect"]
		rect.position = Vector2(start_x, top_y)
		rect.size = Vector2(view.x + tw + 2.0, th)
		var top_fill: ColorRect = entry["top_fill"]
		if top_fill != null:
			top_fill.position = Vector2(0.0, top_y - FILL_EXTENT)
			top_fill.size = Vector2(view.x, FILL_EXTENT)
		var bottom_fill: ColorRect = entry["bottom_fill"]
		if bottom_fill != null:
			bottom_fill.position = Vector2(0.0, top_y + th)
			bottom_fill.size = Vector2(view.x, FILL_EXTENT)
