extends Node

const TICKS: int = 3
const INTERVAL: float = 1.0
const TINT: Color = Color(0.7, 1.0, 0.7)

var _left: int = TICKS
var _timer: float = INTERVAL
var _player: CharacterBody2D = null
var _visual: Node2D = null


static func apply(player: CharacterBody2D) -> void:
	var existing: Node = player.get_node_or_null("Poison")
	if existing != null:
		existing.call("refresh")
		return
	var poison: Node = (load("res://scripts/combat/poison.gd") as GDScript).new() as Node
	poison.name = "Poison"
	player.add_child(poison)


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_visual = _player.get_node_or_null("Visual") as Node2D
	if _visual != null:
		_visual.modulate = Color(TINT.r, TINT.g, TINT.b, _visual.modulate.a)


func _exit_tree() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.modulate = Color(1.0, 1.0, 1.0, _visual.modulate.a)


func refresh() -> void:
	_left = TICKS
	_timer = INTERVAL


func _physics_process(delta: float) -> void:
	if _player == null or bool(_player.call("is_dead")):
		queue_free()
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL
	_left -= 1
	var health: int = int(_player.get("health"))
	if health > 1 and not Game.god_mode and not Game.in_safe_zone:
		_player.set("health", health - 1)
		Game.report_player_health(health - 1, int(_player.get("max_health")))
		Game.shake(1.0, 0.08)
	if _left <= 0:
		queue_free()
