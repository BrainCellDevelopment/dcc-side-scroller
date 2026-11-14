extends Area2D
## Boiler steam hazard (#61). Hisses, then blasts a column of steam that hurts Carl, then rests.

@export var width: float = 32.0
@export var height: float = 64.0
@export var damage: int = 1
@export var rest_time: float = 2.2
@export var warn_time: float = 0.7
@export var blast_time: float = 0.9
@export var phase: float = 0.0

var _t: float = 0.0
var _cooldown: float = 0.0
var _shape: CollisionShape2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_t = phase
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width - 6.0, height)
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	_shape.position = Vector2(width * 0.5, -height * 0.5)
	_shape.disabled = true
	add_child(_shape)
	z_index = 6


func is_blasting() -> bool:
	return _phase_name() == "blast"


func _phase_name() -> String:
	var cycle: float = rest_time + warn_time + blast_time
	var u: float = fmod(_t, cycle)
	if u < rest_time:
		return "rest"
	if u < rest_time + warn_time:
		return "warn"
	return "blast"


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	var live: bool = is_blasting()
	_shape.set_deferred("disabled", not live)
	queue_redraw()
	if not live or _cooldown > 0.0 or Game.in_safe_zone:
		return
	for body: Node2D in get_overlapping_bodies():
		if not body.is_in_group("player") or not body.has_method("take_damage"):
			continue
		if body.has_method("is_dead") and bool(body.call("is_dead")):
			continue
		body.call("take_damage", damage, global_position + Vector2(width * 0.5, 0.0))
		_cooldown = 0.8
		return


func _draw() -> void:
	var c: float = width * 0.5
	draw_rect(Rect2(c - 7.0, -5.0, 14.0, 5.0), Color(0.3, 0.3, 0.34))
	draw_rect(Rect2(c - 7.0, -5.0, 14.0, 5.0), Color(0.1, 0.1, 0.12), false, 1.0)
	var phase_name: String = _phase_name()
	if phase_name == "warn":
		for i: int in 3:
			var y: float = -8.0 - float(i) * 6.0 - fmod(_t * 20.0, 6.0)
			draw_circle(Vector2(c + sin(_t * 9.0 + float(i)) * 3.0, y), 2.0, Color(0.85, 0.88, 0.9, 0.7))
	elif phase_name == "blast":
		for i: int in 7:
			var y: float = -6.0 - float(i) * height / 7.0
			var r: float = 6.0 + float(i) * 0.9
			draw_circle(Vector2(c + sin(_t * 12.0 + float(i) * 1.7) * 3.0, y), r, Color(0.9, 0.92, 0.95, 0.75))
