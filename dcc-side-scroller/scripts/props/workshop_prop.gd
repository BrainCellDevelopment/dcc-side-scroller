extends Node2D
## Goblin workshop dressing (#61). One script, several looks. Origin at the feet.
## "barrel" (funpowder) and "boiler" are destructibles: a dynamite blast sets them off.

signal blown

const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const EXPLOSION: PackedScene = preload("res://scenes/fx/explosion.tscn")
const STEAM: PackedScene = preload("res://scenes/fx/steam_puff.tscn")
const IRON: Color = Color(0.24, 0.24, 0.27)
const IRON_LIGHT: Color = Color(0.42, 0.43, 0.47)
const IRON_DARK: Color = Color(0.11, 0.1, 0.12)
const COAL: Color = Color(0.11, 0.1, 0.12)
const RUST: Color = Color(0.62, 0.3, 0.18)
const PINE: Color = Color(1.0, 0.82, 0.25)
const LEAF: Color = Color(0.35, 0.65, 0.3)

@export_enum("engine", "dozer", "coal", "barrel", "boiler", "pineapples", "conveyor", "pipe") var kind: String = "barrel"
@export var width: float = 96.0

var blasted: bool = false
var _t: float = 0.0
var _puff: float = 0.0


func _ready() -> void:
	match kind:
		"barrel", "boiler":
			add_to_group("destructibles")
			z_index = 1
		"dozer", "pineapples":
			z_index = 1


func _process(delta: float) -> void:
	_t += delta
	if kind == "engine":
		_puff -= delta
		if _puff <= 0.0:
			_puff = 1.1
			var fx: Node2D = STEAM.instantiate() as Node2D
			add_child(fx)
			fx.position = Vector2(width * 0.3, -104.0)
	queue_redraw()


# Called by Explosives.blast.
func blast(center: Vector2) -> void:
	if blasted:
		return
	blasted = true
	remove_from_group("destructibles")
	_detonate.call_deferred(center)


func _detonate(_center: Vector2) -> void:
	var big: bool = kind == "boiler"
	var parent: Node = get_parent()
	var fx: Node2D = EXPLOSION.instantiate() as Node2D
	fx.scale = Vector2.ONE * (2.0 if big else 1.0)
	parent.add_child(fx)
	fx.global_position = global_position + Vector2(0.0, -16.0 if big else -8.0)
	Game.shake(6.0 if big else 3.0, 0.4 if big else 0.25)
	if big:
		for i: int in 3:
			var puff: Node2D = STEAM.instantiate() as Node2D
			parent.add_child(puff)
			puff.global_position = global_position + Vector2(float(i - 1) * 18.0, -28.0 - float(i) * 6.0)
	Explosives.blast(get_tree(), global_position + Vector2(0.0, -12.0), 96.0 if big else 44.0, 4 if big else 2, 1)
	blown.emit()
	queue_free()


func _draw() -> void:
	match kind:
		"engine":
			_draw_engine()
		"dozer":
			_draw_dozer()
		"coal":
			_draw_coal()
		"barrel":
			_draw_barrel()
		"boiler":
			_draw_boiler()
		"pineapples":
			_draw_pineapples()
		"conveyor":
			_draw_conveyor()
		"pipe":
			draw_rect(Rect2(0.0, -4.0, width, 4.0), IRON_LIGHT)
			draw_rect(Rect2(0.0, -4.0, width, 4.0), IRON_DARK, false, 1.0)


func _pineapple(at: Vector2, r: float) -> void:
	draw_circle(at, r, PINE)
	draw_circle(at + Vector2(-r * 0.3, -r * 0.2), r * 0.35, Color(1.0, 0.95, 0.6))
	for i: int in 3:
		draw_line(at + Vector2(float(i - 1) * r * 0.5, -r * 0.8), at + Vector2(float(i - 1) * r * 0.9, -r * 1.7), LEAF, 1.5)


func _draw_engine() -> void:
	var w: float = width
	draw_rect(Rect2(0.0, -26.0, w, 26.0), IRON)
	draw_rect(Rect2(0.0, -26.0, w, 26.0), IRON_DARK, false, 2.0)
	draw_rect(Rect2(w * 0.1, -86.0, w * 0.34, 60.0), IRON_LIGHT)
	draw_rect(Rect2(w * 0.1, -86.0, w * 0.34, 60.0), IRON_DARK, false, 2.0)
	draw_rect(Rect2(w * 0.22, -104.0, w * 0.18, 18.0), IRON)
	draw_rect(Rect2(w * 0.22, -104.0, w * 0.18, 18.0), IRON_DARK, false, 2.0)
	var hub: Vector2 = Vector2(w * 0.72, -48.0)
	draw_circle(hub, 30.0, IRON)
	draw_arc(hub, 30.0, 0.0, TAU, 32, IRON_DARK, 3.0)
	for i: int in 6:
		var a: float = _t * 1.6 + TAU * float(i) / 6.0
		draw_line(hub, hub + Vector2(cos(a), sin(a)) * 28.0, IRON_LIGHT, 3.0)
	draw_circle(hub, 6.0, RUST)
	var push: float = sin(_t * 1.6) * 9.0
	draw_line(hub + Vector2(cos(_t * 1.6), sin(_t * 1.6)) * 20.0, Vector2(w * 0.27 + push, -40.0), RUST, 3.0)
	for i: int in 4:
		draw_circle(Vector2(w * 0.14 + float(i) * 9.0, -76.0), 2.0, Color(1.0, 0.8, 0.3))


func _draw_dozer() -> void:
	var w: float = width
	draw_rect(Rect2(0.0, -32.0, w, 32.0), Color(0.55, 0.12, 0.1))
	draw_rect(Rect2(0.0, -32.0, w, 32.0), IRON_DARK, false, 2.0)
	draw_rect(Rect2(2.0, -10.0, w - 4.0, 10.0), IRON)
	for i: int in 6:
		draw_circle(Vector2(8.0 + float(i) * (w - 16.0) / 5.0, -5.0), 4.0, IRON_LIGHT)
	draw_rect(Rect2(48.0, -80.0, 46.0, 48.0), Color(0.45, 0.1, 0.09))
	draw_rect(Rect2(48.0, -80.0, 46.0, 48.0), IRON_DARK, false, 2.0)
	draw_rect(Rect2(56.0, -72.0, 24.0, 16.0), Color(0.6, 0.85, 0.95, 0.8))
	draw_rect(Rect2(-6.0, -38.0, 8.0, 38.0), IRON_LIGHT)
	_pineapple(Vector2(w * 0.3, -41.0), 6.0)


func _draw_coal() -> void:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.0), Vector2(width * 0.18, -26.0), Vector2(width * 0.34, -34.0), Vector2(width * 0.5, -58.0), Vector2(width * 0.66, -38.0), Vector2(width * 0.84, -22.0), Vector2(width, 0.0)])
	draw_colored_polygon(pts, COAL)
	draw_polyline(pts, Color(0.28, 0.27, 0.32), 2.0)
	for i: int in 9:
		draw_circle(Vector2(width * (0.2 + 0.07 * float(i)), -8.0 - float((i * 7) % 5) * 7.0), 1.6, Color(0.5, 0.5, 0.58))


func _draw_barrel() -> void:
	draw_rect(Rect2(-6.0, -16.0, 12.0, 16.0), RUST)
	draw_rect(Rect2(-6.0, -16.0, 12.0, 16.0), IRON_DARK, false, 1.0)
	draw_rect(Rect2(-6.0, -11.0, 12.0, 2.0), Color(0.95, 0.75, 0.15))
	draw_rect(Rect2(-6.0, -5.0, 12.0, 2.0), Color(0.95, 0.75, 0.15))
	draw_circle(Vector2(0.0, -7.0), 1.5, Color(1.0, 0.95, 0.8))


func _draw_boiler() -> void:
	draw_rect(Rect2(-22.0, -56.0, 44.0, 56.0), IRON)
	draw_rect(Rect2(-22.0, -56.0, 44.0, 56.0), IRON_DARK, false, 2.0)
	for y: float in [-44.0, -28.0, -12.0]:
		draw_line(Vector2(-22.0, y), Vector2(22.0, y), IRON_LIGHT, 2.0)
	draw_circle(Vector2(0.0, -34.0), 8.0, Color(0.8, 0.78, 0.7))
	draw_arc(Vector2(0.0, -34.0), 8.0, 0.0, TAU, 20, IRON_DARK, 1.5)
	var needle: float = -2.4 + (sin(_t * 2.0) * 0.5 + 0.5) * 1.6
	draw_line(Vector2(0.0, -34.0), Vector2(0.0, -34.0) + Vector2(cos(needle), sin(needle)) * 6.0, Color(0.8, 0.1, 0.1), 1.5)
	draw_rect(Rect2(-6.0, -64.0, 12.0, 8.0), IRON_LIGHT)
	draw_rect(Rect2(-14.0, -18.0, 28.0, 6.0), Color(1.0, 0.45, 0.1, 0.4 + 0.3 * sin(_t * 5.0)))


func _draw_pineapples() -> void:
	draw_rect(Rect2(-12.0, -12.0, 24.0, 12.0), Color(0.55, 0.38, 0.2))
	draw_rect(Rect2(-12.0, -12.0, 24.0, 12.0), IRON_DARK, false, 1.0)
	_pineapple(Vector2(-6.0, -16.0), 5.0)
	_pineapple(Vector2(5.0, -17.0), 5.0)


func _draw_conveyor() -> void:
	draw_rect(Rect2(0.0, -14.0, width, 8.0), IRON)
	draw_rect(Rect2(0.0, -14.0, width, 8.0), IRON_DARK, false, 1.0)
	var x: float = fmod(_t * 18.0, 12.0)
	while x < width:
		draw_line(Vector2(x, -14.0), Vector2(x, -6.0), IRON_LIGHT, 1.0)
		x += 12.0
	for lx: float in [4.0, width - 6.0]:
		draw_rect(Rect2(lx, -6.0, 3.0, 6.0), IRON_LIGHT)
	_pineapple(Vector2(fmod(_t * 18.0 + 30.0, width), -20.0), 5.0)
