extends Node
## Showcase of the Floor 1 art kit (backgrounds, platform styles, props).
## Run windowed: godot --path dcc-side-scroller res://tests/floor1_art_kit.tscn
## With DCC_SHOT_DIR set it saves one screenshot per background style and quits.

const BACKGROUND: PackedScene = preload("res://scenes/level/background.tscn")
const PLATFORM: PackedScene = preload("res://scenes/level/platform.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")

const STYLES: Array = [
	{"index": 4, "name": "tunnel"},
	{"index": 5, "name": "artery"},
	{"index": 6, "name": "corridor"},
]
const GROUND_Y: float = 300.0

var _bg: CanvasLayer
var _world: Node2D
var _shot_dir: String = OS.get_environment("DCC_SHOT_DIR")


func _ready() -> void:
	var res: PackedStringArray = OS.get_environment("DCC_RES").split("x")
	if res.size() == 2:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(int(res[0]), int(res[1]))
		await get_tree().create_timer(0.5).timeout
	_bg = BACKGROUND.instantiate() as CanvasLayer
	_bg.set("initial_style", 4)
	add_child(_bg)
	_world = Node2D.new()
	add_child(_world)
	var cam: Camera2D = Camera2D.new()
	cam.position = Vector2(320.0, 180.0)
	add_child(cam)
	cam.make_current()
	for entry: Variant in STYLES:
		var d: Dictionary = entry
		_bg.call("set_style", int(d["index"]), 0.0)
		_build(String(d["name"]))
		await get_tree().create_timer(0.6).timeout
		await _shot(String(d["name"]))
		for c: Node in _world.get_children():
			c.queue_free()
		await get_tree().process_frame
	if not _shot_dir.is_empty():
		get_tree().quit()


func _shot(label: String) -> void:
	if _shot_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var size: Vector2i = get_window().size
	get_viewport().get_texture().get_image().save_png("%s/floor1_%s_%dx%d.png" % [_shot_dir, label, size.x, size.y])


func _plat(pos: Vector2, size: Vector2, style: int, one_way: bool = false) -> void:
	var p: StaticBody2D = PLATFORM.instantiate() as StaticBody2D
	p.set("size", size)
	p.set("style", style)
	p.set("one_way", one_way)
	p.position = pos
	_world.add_child(p)


func _prop(path: String, pos: Vector2, flip: bool = false) -> void:
	var n: Node2D = (load("res://scenes/props/%s.tscn" % path) as PackedScene).instantiate() as Node2D
	n.position = pos
	if flip:
		n.scale.x = -1.0
	_world.add_child(n)


func _build(kind: String) -> void:
	_plat(Vector2(0.0, GROUND_Y), Vector2(640.0, 60.0), 4)
	_plat(Vector2(40.0, 236.0), Vector2(96.0, 16.0), 5)
	_plat(Vector2(470.0, 226.0), Vector2(96.0, 16.0), 6, true)
	_plat(Vector2(250.0, 170.0), Vector2(64.0, 16.0), 4)
	var player: Node2D = PLAYER.instantiate() as Node2D
	player.position = Vector2(300.0, GROUND_Y)
	_world.add_child(player)
	match kind:
		"tunnel":
			_prop("lichen_floor", Vector2(120.0, GROUND_Y))
			_prop("lichen_wall", Vector2(210.0, GROUND_Y))
			_prop("lichen_floor", Vector2(420.0, GROUND_Y))
			_prop("lichen_floor", Vector2(80.0, 236.0))
			_prop("torch_bracket", Vector2(560.0, 240.0))
			_prop("sign_hazard", Vector2(370.0, GROUND_Y))
			_prop("pipe_h", Vector2(100.0, 130.0))
			_prop("spray_arrow", Vector2(560.0, 270.0))
		"artery":
			_prop("torch_bracket", Vector2(60.0, 230.0))
			_prop("skull_sconce", Vector2(200.0, 232.0))
			_prop("torch_bracket", Vector2(420.0, 230.0))
			_prop("skull_sconce", Vector2(580.0, 232.0))
			_prop("neon_guild_sign", Vector2(320.0, 100.0))
			_prop("spray_arrow", Vector2(130.0, 270.0))
			_prop("sign_arrow_brick", Vector2(500.0, GROUND_Y))
			_prop("lichen_floor", Vector2(350.0, GROUND_Y))
		"corridor":
			_prop("lichen_wall", Vector2(60.0, GROUND_Y))
			_prop("lichen_floor", Vector2(160.0, GROUND_Y))
			_prop("lichen_wall", Vector2(380.0, GROUND_Y))
			_prop("lichen_floor", Vector2(520.0, GROUND_Y))
			_prop("lichen_floor", Vector2(510.0, 226.0))
			_prop("grate", Vector2(160.0, 240.0))
			_prop("pipe_h", Vector2(320.0, 215.0))
			_prop("pipe_v", Vector2(440.0, GROUND_Y))
			_prop("spray_x", Vector2(560.0, 250.0))
