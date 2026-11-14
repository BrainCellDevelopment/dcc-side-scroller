extends Node
## The Taint (Floor 2 clurichaun and Krakaren mucus): no healing while it lasts, whether from potions,
## spells or natural regeneration. The immunity smoothie (Game meta "smoothie_immune") blocks it entirely.

const SECONDS: float = 8.0
const TINT: Color = Color(0.85, 0.95, 0.6)
const IMMUNE_FLAG: String = "smoothie_immune"

var _left: float = SECONDS
var _visual: Node2D = null


static func is_tainted(player: Node) -> bool:
	return player != null and player.get_node_or_null("Taint") != null


static func is_immune() -> bool:
	return bool(Game.get_meta(IMMUNE_FLAG, false))


static func apply(player: CharacterBody2D) -> void:
	if is_immune():
		return
	var existing: Node = player.get_node_or_null("Taint")
	if existing != null:
		existing.call("refresh")
		return
	var taint: Node = (load("res://scripts/combat/taint.gd") as GDScript).new() as Node
	taint.name = "Taint"
	player.add_child(taint)


func _ready() -> void:
	_visual = get_parent().get_node_or_null("Visual") as Node2D
	if _visual != null:
		_visual.modulate = Color(TINT.r, TINT.g, TINT.b, _visual.modulate.a)


func _exit_tree() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.modulate = Color(1.0, 1.0, 1.0, _visual.modulate.a)


func refresh() -> void:
	_left = SECONDS


func _physics_process(delta: float) -> void:
	var player: Node = get_parent()
	if player == null or bool(player.call("is_dead")):
		queue_free()
		return
	_left -= delta
	if _left <= 0.0:
		queue_free()
