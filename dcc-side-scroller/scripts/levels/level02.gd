extends Node2D
## Level 2 stub (#68): the palette flip after the collapse. White floors, cinderblock walls and
## orange lichen, all code-drawn. One flat run to an end marker; carries Carl's health, XP,
## items and the Desperado Pass and Neighborhood Map flags in from Floor 1 (see floor_handoff.gd).

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
const WIDTH: float = 1800.0
const FLOOR_Y: float = 300.0
const WALL_TOP: float = -200.0
const START_X: float = 80.0
const END_X: float = 1700.0
const TITLE: String = "LEVEL 2"
const END_TEXT: String = "LEVEL 2\nTo be continued"
const TITLE_SECONDS: float = 2.5
const FOCUS_ON_FLOOR: float = 40.0

const BLOCK_W: float = 32.0
const BLOCK_H: float = 16.0
const WALL_A: Color = Color(0.74, 0.74, 0.7)
const WALL_B: Color = Color(0.68, 0.68, 0.64)
const MORTAR: Color = Color(0.5, 0.5, 0.47)
const FLOOR_WHITE: Color = Color(0.93, 0.93, 0.9)
const FLOOR_EDGE: Color = Color(0.62, 0.62, 0.6)
const LICHEN: Color = Color(1.0, 0.54, 0.12)
const LICHEN_DARK: Color = Color(0.7, 0.28, 0.06)
const SHELVES: Array[Vector3] = [Vector3(420.0, 252.0, 96.0), Vector3(760.0, 228.0, 96.0), Vector3(1180.0, 252.0, 112.0), Vector3(1440.0, 224.0, 96.0)]
const LICHEN_SPOTS: Array[Vector3] = [
	Vector3(140.0, 270.0, 1.0), Vector3(300.0, 180.0, 1.4), Vector3(520.0, 296.0, 0.8), Vector3(660.0, 120.0, 1.2),
	Vector3(900.0, 280.0, 1.5), Vector3(1010.0, 170.0, 1.0), Vector3(1260.0, 292.0, 1.2), Vector3(1380.0, 150.0, 1.4),
	Vector3(1560.0, 284.0, 1.0), Vector3(1650.0, 190.0, 1.3),
]

var complete: bool = false
## What arrived from Floor 1, captured when the level starts (the hand-off test reads it).
var arrival: Dictionary = {}

var _player: CharacterBody2D = null
var _camera: Camera2D = null
var _hud: CanvasLayer = null
var _backdrop: Node2D = null
var _focus_y: float = 0.0
var _time: float = 0.0


func _enter_tree() -> void:
	Game.floor_time_left = Game.FLOOR_TIME
	PlayerStats.enter_floor(2)


func _ready() -> void:
	_build_world()
	_player = PLAYER_SCENE.instantiate() as CharacterBody2D
	_player.name = "Player"
	_player.position = Vector2(START_X, FLOOR_Y - 2.0)
	add_child(_player)
	_player.connect("died", _on_player_died)
	_player.call("enable_spell")
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	_camera.limit_left = 0
	_camera.limit_right = int(WIDTH)
	_camera.limit_top = int(WALL_TOP)
	_camera.limit_bottom = int(FLOOR_Y + 64.0)
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(_camera)
	_hud = HUD_SCENE.instantiate() as CanvasLayer
	_hud.name = "HUD"
	add_child(_hud)
	_capture_arrival()
	_focus_y = _player.global_position.y - FOCUS_ON_FLOOR
	_camera.global_position = Vector2(_player.global_position.x, _focus_y)
	_camera.reset_smoothing()
	_hud.call("show_banner", TITLE, TITLE_SECONDS)


func _process(delta: float) -> void:
	_time += delta
	_backdrop.queue_redraw()


func _physics_process(_delta: float) -> void:
	if _player.is_on_floor():
		_focus_y = _player.global_position.y - FOCUS_ON_FLOOR
	_camera.global_position = Vector2(_player.global_position.x, _focus_y)
	if not complete and _player.global_position.x >= END_X:
		_on_end_reached()


func _capture_arrival() -> void:
	var flags: Dictionary = {}
	for flag: String in FloorHandoff.FLAGS:
		flags[flag] = bool(Game.get_meta(flag, false))
	arrival = {
		"health": int(_player.get("health")),
		"max_health": int(_player.get("max_health")),
		"level": PlayerStats.character_level,
		"xp": PlayerStats.xp,
		"items": FloorHandoff.item_total(),
		"flags": flags,
		"survivors": SystemVoice.survivors,
		"floor": PlayerStats.floor_number,
	}


func _on_end_reached() -> void:
	complete = true
	_player.set("control_enabled", false)
	_hud.call("show_banner", END_TEXT, 0.0)


func _on_player_died() -> void:
	_hud.call("show_banner", "YOU DIED", 0.0)
	await get_tree().create_timer(1.8).timeout
	Game.carried_health = -1
	get_tree().reload_current_scene()


func dev_sections() -> PackedStringArray:
	return PackedStringArray(["start"])


func dev_goto(target: String) -> bool:
	return target == "start"


func _build_world() -> void:
	_backdrop = Node2D.new()
	_backdrop.name = "Backdrop"
	_backdrop.z_index = -10
	_backdrop.draw.connect(_draw_backdrop)
	add_child(_backdrop)
	_solid("Floor", Vector2(WIDTH * 0.5, FLOOR_Y + 32.0), Vector2(WIDTH, 64.0), false)
	for index: int in SHELVES.size():
		var shelf: Vector3 = SHELVES[index]
		_solid("Shelf%d" % index, Vector2(shelf.x + shelf.z * 0.5, shelf.y + 8.0), Vector2(shelf.z, 16.0), true)
	_solid("RightBound", Vector2(WIDTH + 8.0, FLOOR_Y - 250.0), Vector2(16.0, 720.0), false)
	_solid("LeftBound", Vector2(-8.0, FLOOR_Y - 250.0), Vector2(16.0, 720.0), false)


func _solid(node_name: String, center: Vector2, size: Vector2, one_way: bool) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	body.add_child(shape)
	add_child(body)
	return body


func _draw_backdrop() -> void:
	var node: Node2D = _backdrop
	var rows: int = int((FLOOR_Y - WALL_TOP) / BLOCK_H) + 1
	node.draw_rect(Rect2(-64.0, WALL_TOP - 64.0, WIDTH + 128.0, FLOOR_Y - WALL_TOP + 64.0 + 128.0), WALL_A)
	for row: int in rows:
		var y: float = WALL_TOP + float(row) * BLOCK_H
		var shift: float = BLOCK_W * 0.5 if row % 2 == 1 else 0.0
		node.draw_rect(Rect2(-64.0, y, WIDTH + 128.0, 1.0), MORTAR)
		var x: float = -64.0 - shift
		while x < WIDTH + 64.0:
			node.draw_rect(Rect2(x, y, 1.0, BLOCK_H), MORTAR)
			if (int(x / BLOCK_W) + row) % 5 == 0:
				node.draw_rect(Rect2(x + 1.0, y + 1.0, BLOCK_W - 1.0, BLOCK_H - 1.0), WALL_B)
			x += BLOCK_W
	node.draw_rect(Rect2(-64.0, FLOOR_Y, WIDTH + 128.0, 80.0), FLOOR_WHITE)
	node.draw_rect(Rect2(-64.0, FLOOR_Y, WIDTH + 128.0, 3.0), Color(1.0, 1.0, 0.98))
	node.draw_rect(Rect2(-64.0, FLOOR_Y + 3.0, WIDTH + 128.0, 2.0), FLOOR_EDGE)
	var tile: float = -64.0
	while tile < WIDTH + 64.0:
		node.draw_rect(Rect2(tile, FLOOR_Y + 5.0, 1.0, 59.0), Color(0.8, 0.8, 0.77))
		tile += 48.0
	for index: int in SHELVES.size():
		var shelf: Vector3 = SHELVES[index]
		node.draw_rect(Rect2(shelf.x, shelf.y, shelf.z, 16.0), FLOOR_WHITE)
		node.draw_rect(Rect2(shelf.x, shelf.y, shelf.z, 3.0), Color(1.0, 1.0, 0.98))
		node.draw_rect(Rect2(shelf.x, shelf.y + 14.0, shelf.z, 2.0), FLOOR_EDGE)
	for index: int in LICHEN_SPOTS.size():
		var spot: Vector3 = LICHEN_SPOTS[index]
		var pulse: float = 0.75 + 0.25 * sin(_time * 1.5 + float(index))
		var center: Vector2 = Vector2(spot.x, spot.y)
		for ring: int in 4:
			node.draw_circle(center, (24.0 - float(ring) * 5.0) * spot.z, Color(LICHEN.r, LICHEN.g, LICHEN.b, 0.05 * pulse))
		for blob: int in 5:
			var offset: Vector2 = Vector2(float(blob - 2) * 4.0 * spot.z, float((blob * 5) % 3) * 2.0)
			node.draw_circle(center + offset, (3.0 + float(blob % 3)) * spot.z * 0.8, LICHEN_DARK if blob % 2 == 0 else LICHEN)
	node.draw_rect(Rect2(END_X - 4.0, FLOOR_Y - 60.0, 8.0, 60.0), LICHEN_DARK)
	node.draw_rect(Rect2(END_X - 18.0, FLOOR_Y - 60.0, 36.0, 12.0), LICHEN)
