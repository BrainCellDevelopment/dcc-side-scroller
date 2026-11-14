extends Node2D

const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const EXPLOSION: PackedScene = preload("res://scenes/fx/explosion.tscn")
const GRAVITY: float = 520.0
const WORLD_MASK: int = 1
const BOUNCE: float = 0.35

@export var fuse_time: float = 1.6
@export var blast_radius: float = 56.0
@export var blast_damage: int = 3
@export var player_damage: int = 1

var velocity: Vector2 = Vector2.ZERO
var exploded: bool = false

var _age: float = 0.0
var _resting: bool = false


func _ready() -> void:
	add_to_group("dynamite")
	z_index = 8


func launch(from: Vector2, direction: Vector2) -> void:
	global_position = from
	velocity = direction


func _physics_process(delta: float) -> void:
	if exploded:
		return
	_age += delta
	if not _resting:
		_step(delta)
	queue_redraw()
	if _age >= fuse_time:
		explode()


func _step(delta: float) -> void:
	velocity.y += GRAVITY * delta
	var target: Vector2 = global_position + velocity * delta
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target, WORLD_MASK)
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = target
		rotation += signf(velocity.x) * 9.0 * delta
		return
	var normal: Vector2 = result["normal"]
	global_position = (result["position"] as Vector2) + normal
	velocity = velocity.bounce(normal) * BOUNCE
	if velocity.length() < 40.0:
		velocity = Vector2.ZERO
		_resting = true


func explode() -> void:
	if exploded:
		return
	exploded = true
	var fx: Node2D = EXPLOSION.instantiate() as Node2D
	fx.global_position = global_position
	fx.scale = Vector2.ONE * (blast_radius / 32.0)
	get_parent().add_child(fx)
	Game.shake(4.0, 0.3)
	Explosives.blast(get_tree(), global_position, blast_radius, blast_damage, player_damage)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-2.0, -5.0, 4.0, 10.0), Color(0.75, 0.15, 0.12))
	draw_rect(Rect2(-2.0, -1.0, 4.0, 2.0), Color(0.95, 0.9, 0.7))
	draw_line(Vector2(0.0, -5.0), Vector2(1.0, -8.0), Color(0.3, 0.2, 0.1), 1.0)
	var left: float = clampf(1.0 - _age / fuse_time, 0.0, 1.0)
	var flicker: float = 1.0 + 0.5 * sin(_age * 40.0)
	draw_circle(Vector2(1.0, -8.0), 1.5 + flicker, Color(1.0, 0.8, 0.2, 0.5 + 0.5 * left))
	draw_circle(Vector2(1.0, -8.0), 1.0, Color(1.0, 1.0, 0.8))
