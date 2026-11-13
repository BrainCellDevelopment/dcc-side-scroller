@tool
extends Area2D

const TEX: Texture2D = preload("res://assets/tiles/spikes.png")
const TILE: float = 16.0
const HIT_HEIGHT: float = 10.0
const REPEAT_TIME: float = 0.6

@export var width: float = 32.0:
	set(value):
		width = maxf(value, 1.0)
		_refresh()
@export var damage: int = 2

var _shape: CollisionShape2D = null
var _inside: Array[Node2D] = []
var _cooldown: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.name = "CollisionShape2D"
		add_child(_shape)
	_update_shape()
	queue_redraw()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _refresh() -> void:
	if not is_node_ready():
		return
	_update_shape()
	queue_redraw()


func _update_shape() -> void:
	if _shape == null:
		return
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, HIT_HEIGHT)
	_shape.shape = rect
	_shape.position = Vector2(width * 0.5, -TILE + HIT_HEIGHT * 0.5)


func _draw() -> void:
	var count: int = ceili(width / TILE)
	for i: int in count:
		var x: float = float(i) * TILE
		var tw: float = minf(TILE, width - x)
		draw_texture_rect_region(TEX, Rect2(x, -TILE, tw, TILE), Rect2(0.0, 0.0, tw, TILE))


func _on_body_entered(body: Node2D) -> void:
	if not _inside.has(body):
		_inside.append(body)
	if _cooldown <= 0.0:
		_hurt()


func _on_body_exited(body: Node2D) -> void:
	_inside.erase(body)


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _cooldown <= 0.0 and not _inside.is_empty():
		_hurt()


func _hurt() -> void:
	var hit: bool = false
	for body: Node2D in _inside.duplicate():
		if not is_instance_valid(body):
			_inside.erase(body)
			continue
		if body.has_method("take_damage"):
			body.call("take_damage", damage, global_position + Vector2(width * 0.5, 0.0))
			hit = true
	if hit:
		_cooldown = REPEAT_TIME
