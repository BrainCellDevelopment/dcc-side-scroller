extends Node2D
## The greenroom (Level 1): the stairwell landing after the Ball of Swine, dressed like the waiting room
## behind Odette's show. Mordecai waits here. The whole landing is a safe zone, so the boss boxes (the
## Hoarder's and the Swine's, which cannot be opened anywhere else on the floor) can finally be opened.
## The level holds the end-of-floor trigger until is_ready() is true.
## Origin is the middle of the landing on the floor line. Mordecai stands at MORDECAI_X. The set (back wall, door, couch, vanity, rack) is drawn in code.

signal ready_to_leave

const SET: GDScript = preload("res://scripts/level/greenroom_set.gd")
const LOOT_BOX: PackedScene = preload("res://scenes/props/loot_box.tscn")
const MORDECAI: PackedScene = preload("res://scenes/props/mordecai.tscn")
const ZONE_SIZE: Vector2 = Vector2(288.0, 140.0)
const MORDECAI_X: float = 26.0
const LINES: PackedStringArray = [
	"There you are. Intermission. The crew calls this the greenroom. It is a stairwell with a lamp.",
	"Nobody is watching for the next five minutes. That is the only privacy a crawler gets. Open your boxes.",
	"Then go down and be interviewed. Smile. Do not mention me.",
]
const REPEAT_LINE: String = "Boxes first. Odette keeps a schedule and I am not the reason you are late."
const HOLD_TEXT: String = "TALK TO MORDECAI AND OPEN YOUR BOXES"

var mordecai: Area2D = null
var talked: bool = false
var announced: bool = false
var player_inside: bool = false


func _ready() -> void:
	var set_piece: Node2D = SET.new() as Node2D
	set_piece.name = "Set"
	set_piece.z_index = -3
	add_child(set_piece)
	var glow: Node2D = SET.new() as Node2D
	glow.name = "Glow"
	glow.set("glow_only", true)
	glow.z_index = 3
	add_child(glow)
	mordecai = MORDECAI.instantiate() as Area2D
	mordecai.set("lines", LINES)
	mordecai.set("repeat_line", REPEAT_LINE)
	mordecai.position = Vector2(MORDECAI_X, 0.0)
	add_child(mordecai)
	mordecai.connect("dialogue_finished", _on_talked)
	var zone: Area2D = Area2D.new()
	zone.name = "SafeZone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = ZONE_SIZE
	shape.shape = rect
	shape.position = Vector2(0.0, -60.0)
	zone.add_child(shape)
	add_child(zone)
	zone.body_entered.connect(_on_zone_entered)
	zone.body_exited.connect(_on_zone_exited)


func _process(_delta: float) -> void:
	if announced or not is_ready():
		return
	announced = true
	ready_to_leave.emit()


## True once Mordecai has been spoken to and no summoned box is left unopened.
func is_ready() -> bool:
	if not talked:
		return false
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(node.get("summoned")) and not bool(node.get("is_open")):
			return false
	return true


func _on_talked() -> void:
	talked = true


func _on_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		Game.set_safe_zone(true)
		_give_earned_boxes.call_deferred()


func _on_zone_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		Game.set_safe_zone(false)


func _exit_tree() -> void:
	if player_inside:
		Game.set_safe_zone(false)


func _give_earned_boxes() -> void:
	for tier: String in Game.take_earned_boxes():
		var box: Area2D = LOOT_BOX.instantiate() as Area2D
		box.set("tier", tier)
		box.set("kit", "floor1")
		box.set("slot", get_tree().get_nodes_in_group("loot_boxes").size())
		add_child(box)
		var spot: Vector2 = global_position + Vector2(MORDECAI_X - 30.0, -20.0)
		box.global_position = spot
		box.call("summon", get_tree().get_first_node_in_group("player"), spot)
