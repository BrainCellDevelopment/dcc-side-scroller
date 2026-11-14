extends Area2D
## Bomb Bard's glass bomb: an arc, then a small burst on whatever it lands on. It hurts goblins too.

const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const EXPLOSION: PackedScene = preload("res://scenes/fx/explosion.tscn")
const LIFETIME: float = 3.0
const BURST_RADIUS: float = 26.0
const FRIENDLY_DAMAGE: int = 1

@export var fall_gravity: float = 520.0
@export var damage: int = 1

var velocity: Vector2 = Vector2.ZERO

var _age: float = 0.0
var _done: bool = false
var _spin: float = 0.0


func _ready() -> void:
	add_to_group("projectiles")
	z_index = 8
	body_entered.connect(_on_body_entered)


func launch(initial_velocity: Vector2, hit_damage: int = 1) -> void:
	velocity = initial_velocity
	damage = hit_damage


func _physics_process(delta: float) -> void:
	if _done:
		return
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	_spin += delta * 12.0
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		_burst()


func _on_body_entered(body: Node2D) -> void:
	if _done or body == null or not is_instance_valid(body):
		return
	if body.is_in_group("enemies"):
		return
	_burst()


func _burst() -> void:
	if _done:
		return
	_done = true
	set_deferred("monitoring", false)
	var fx: Node2D = EXPLOSION.instantiate() as Node2D
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.scale = Vector2.ONE * 0.8
	Game.shake(1.5, 0.15)
	var tree: SceneTree = get_tree()
	for node: Node in tree.get_nodes_in_group("enemies"):
		var other: Node2D = node as Node2D
		if other != null and other.has_method("take_damage") and (other.global_position + Explosives.BODY_CENTER).distance_to(global_position) <= BURST_RADIUS:
			other.call("take_damage", FRIENDLY_DAMAGE, global_position)
	var player: Node2D = tree.get_first_node_in_group("player") as Node2D
	if player != null and not Game.in_safe_zone and (player.global_position + Explosives.BODY_CENTER).distance_to(global_position) <= BURST_RADIUS:
		if not (player.has_method("is_dead") and bool(player.call("is_dead"))):
			player.call("take_damage", damage, global_position)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.54, 0.88, 0.75, 0.9))
	draw_circle(Vector2(sin(_spin) * 1.5, cos(_spin) * 1.5), 2.0, Color(1.0, 0.48, 0.16))
	draw_rect(Rect2(-1.0, -7.0, 2.0, 3.0), Color(0.4, 0.28, 0.15))
	draw_circle(Vector2(0.0, -8.0), 1.2, Color(1.0, 0.85, 0.3))
