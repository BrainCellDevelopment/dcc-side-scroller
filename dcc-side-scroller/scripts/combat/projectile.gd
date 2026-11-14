extends Area2D

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const Targeting: GDScript = preload("res://scripts/combat/targeting.gd")
const SHEET: Texture2D = preload("res://assets/fx/magic_missile.png")
const IMPACT_SCENE: PackedScene = preload("res://scenes/fx/magic_impact.tscn")
const FRAME: Vector2i = Vector2i(14, 8)
const ANIMS: Dictionary = {"fly": {"row": 0, "count": 4, "fps": 16.0, "loop": true}}
const TRAIL_POINTS: int = 10
const ANCHOR_TIME: float = 0.3
const LAUNCH_JITTER: float = 0.3
const WANDER_RATE: float = 5.0
const WANDER_CALM_NEAR: float = 30.0
const WANDER_CALM_RANGE: float = 150.0
const MASK_AT_ENEMIES: int = 5
const MASK_AT_PLAYER: int = 3

@export var speed: float = 230.0
@export var damage: int = 1
@export var lifetime: float = 2.2
@export var turn_rate: float = 14.0
@export var wander: bool = true
@export var home_delay: float = 0.14
@export var target_range: float = 280.0
@export var target_arc: float = 75.0
@export var target_group: StringName = &"enemies"

var velocity: Vector2 = Vector2.ZERO

var _age: float = 0.0
var _done: bool = false
var _target: Node2D = null
var anchor: Node2D = null
var anchor_offset: Vector2 = Vector2.ZERO

var _heading: float = 0.0
var _wander_rate: float = 0.0
var _wander_target: float = 0.0
var _wander_timer: float = 0.0
var _trail: Line2D = null
var _history: Array[Vector2] = []


func _ready() -> void:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	sprite.name = "Sprite"
	sprite.offset = Vector2(-float(FRAME.x) * 0.5 + 3.0, -float(FRAME.y) * 0.5)
	add_child(sprite)
	sprite.play("fly")
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.z_index = -1
	_trail.width = 4.0
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = curve
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.45, 0.25, 0.85, 0.3))
	gradient.set_color(1, Color(0.85, 0.65, 1.0, 0.85))
	_trail.gradient = gradient
	add_child(_trail)
	add_to_group("missiles")
	body_entered.connect(_on_body_entered)


func fire(direction: Vector2, group: StringName = &"enemies") -> void:
	target_group = group
	_heading = direction.angle()
	if wander:
		_heading += randf_range(-LAUNCH_JITTER, LAUNCH_JITTER)
	velocity = Vector2.from_angle(_heading) * speed
	collision_mask = MASK_AT_PLAYER if group == &"player" else MASK_AT_ENEMIES
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	if _done:
		return
	_age += delta
	var calm: float = 1.0
	if _age >= home_delay:
		calm = _steer(delta)
	if wander:
		_drift(delta, calm)
	velocity = Vector2.from_angle(_heading) * speed
	rotation = velocity.angle()
	global_position += velocity * delta
	_update_trail()
	if _age >= lifetime:
		_finish()


func _steer(delta: float) -> float:
	if not Targeting.is_valid(_target):
		_target = Targeting.nearest(global_position, velocity, get_tree().get_nodes_in_group(target_group), target_range, target_arc)
	if _target == null:
		return 1.0
	var offset: Vector2 = _target.global_position + Targeting.AIM_OFFSET - global_position
	var turn: float = clampf(angle_difference(_heading, offset.angle()), -turn_rate * delta, turn_rate * delta)
	_heading += turn
	return clampf((offset.length() - WANDER_CALM_NEAR) / WANDER_CALM_RANGE, 0.2, 1.0)


func _drift(delta: float, calm: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(0.07, 0.17)
		_wander_target = randf_range(-1.0, 1.0) * WANDER_RATE
	_wander_rate = lerpf(_wander_rate, _wander_target, clampf(delta * 12.0, 0.0, 1.0))
	_heading += _wander_rate * calm * delta


func _update_trail() -> void:
	_history.append(global_position)
	var anchored: bool = anchor != null and is_instance_valid(anchor) and _age < ANCHOR_TIME
	if not anchored:
		anchor = null
		while _history.size() > TRAIL_POINTS:
			_history.pop_front()
	_trail.global_position = Vector2.ZERO
	_trail.clear_points()
	if anchored:
		_trail.add_point(anchor.global_position + anchor_offset)
	for point: Vector2 in _history:
		_trail.add_point(point)


func _on_body_entered(body: Node2D) -> void:
	if _done or body == null or not is_instance_valid(body):
		return
	if body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.call("take_damage", damage, global_position)
		_finish()
	elif body.is_in_group("player") or body.is_in_group("enemies"):
		return
	else:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	var impact: Node2D = IMPACT_SCENE.instantiate() as Node2D
	impact.global_position = global_position
	get_parent().add_child.call_deferred(impact)
	queue_free()
