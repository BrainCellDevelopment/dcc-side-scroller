extends CanvasLayer
## Screen-space snowfall for the surface only. Intensity follows the player's
## position relative to the surface gate, matching the area veil's fade.

const FLAKES_PER_LAYER: Array[int] = [110, 70, 40]
const LAYER_SPEED: Array[float] = [30.0, 46.0, 66.0]
const LAYER_SIZE: Array[float] = [1.0, 2.0, 3.0]
const LAYER_ALPHA: Array[float] = [0.45, 0.65, 0.9]
const LAYER_PARALLAX: Array[float] = [0.04, 0.08, 0.14]
const WIND: float = -14.0
const SWAY: float = 6.0
const VIEW: Vector2 = Vector2(640.0, 360.0)

@export var edge_x: float = 0.0
@export var fade_from: float = 10.0
@export var fade_to: float = 120.0

var _flakes: Array[Dictionary] = []
var _time: float = 0.0
var _intensity: float = 1.0
var _last_cam: Vector2 = Vector2.ZERO
var _have_cam: bool = false


func _ready() -> void:
	layer = 5
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 30
	for l: int in FLAKES_PER_LAYER.size():
		for i: int in FLAKES_PER_LAYER[l]:
			_flakes.append({
				"l": l,
				"x": rng.randf() * VIEW.x,
				"y": rng.randf() * VIEW.y,
				"phase": rng.randf() * TAU,
				"speed": rng.randf_range(0.8, 1.2),
			})
	var canvas: Node2D = Node2D.new()
	canvas.name = "Flakes"
	canvas.draw.connect(_draw_flakes.bind(canvas))
	add_child(canvas)
	_update_intensity()
	visible = _intensity > 0.001


func _process(delta: float) -> void:
	_time += delta
	_update_intensity()
	visible = _intensity > 0.001
	if not visible:
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	var cam_delta: Vector2 = Vector2.ZERO
	if cam != null:
		var pos: Vector2 = cam.get_screen_center_position()
		if _have_cam:
			cam_delta = pos - _last_cam
		_last_cam = pos
		_have_cam = true
	for f: Dictionary in _flakes:
		var l: int = int(f["l"])
		f["y"] = fposmod(float(f["y"]) + LAYER_SPEED[l] * float(f["speed"]) * delta - cam_delta.y * LAYER_PARALLAX[l], VIEW.y)
		f["x"] = fposmod(float(f["x"]) + WIND * float(f["speed"]) * delta - cam_delta.x * LAYER_PARALLAX[l], VIEW.x)
	(get_node("Flakes") as Node2D).queue_redraw()


func _update_intensity() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	_intensity = 1.0 - smoothstep(edge_x + fade_from, edge_x + fade_to, player.global_position.x)


func _draw_flakes(canvas: Node2D) -> void:
	for f: Dictionary in _flakes:
		var l: int = int(f["l"])
		var sway: float = sin(_time * 0.9 + float(f["phase"])) * SWAY
		var pos: Vector2 = Vector2(roundf(float(f["x"]) + sway), roundf(float(f["y"])))
		var size: float = LAYER_SIZE[l]
		canvas.draw_rect(Rect2(pos, Vector2(size, size)), Color(0.8, 0.87, 0.97, LAYER_ALPHA[l] * _intensity))
