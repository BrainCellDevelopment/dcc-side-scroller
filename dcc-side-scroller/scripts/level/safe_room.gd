extends Node2D
## Reusable safe room. Origin is the floor at the room centre; the room spans
## -width/2 .. +width/2. Entry door on the right, exit door on the left (the
## level runs right to left). Dress it through the PropSlots markers.

signal entered
signal exited
signal enemy_neutralised(enemy: Node)

const LOOT_BOX: PackedScene = preload("res://scenes/props/loot_box.tscn")
const ZONE_HEIGHT: float = 120.0
const DOOR_OPEN_RANGE: float = 70.0
const DOOR_CLOSE_RANGE: float = 48.0
const DOOR_STAND_CLEAR: float = 20.0
const HALL_TEXT: String = "Mobs in the hallway"
const ENEMY_MASK: int = 12
const PLAYER_MASK: int = 2

@export var width: float = 480.0
## How far outside each door counts as the hallway. Keep it inside any gate that seals the room.
@export var hall_depth: float = 160.0
@export var checkpoint_index: int = 0
@export var checkpoint_stage: int = 0
@export var box_tiers: PackedStringArray = PackedStringArray()
## Loot table set for this room's boxes (see loot_tables.gd).
@export var box_kit: String = "floor1"

var player_inside: bool = false
var visited: bool = false

var _boxes_given: bool = false

@onready var zone: Area2D = $Zone
@onready var hall_entry: Area2D = $HallEntry
@onready var hall_exit: Area2D = $HallExit
@onready var entry_door: Node2D = $EntryDoor
@onready var exit_door: Node2D = $ExitDoor
@onready var checkpoint: Node2D = $Checkpoint
@onready var caretaker: Node2D = $Caretaker
@onready var box_spot: Marker2D = $BoxSpot
@onready var prop_slots: Node2D = $PropSlots


func _ready() -> void:
	var half: float = width * 0.5
	_set_box(zone, Vector2(width - 16.0, ZONE_HEIGHT), Vector2(0.0, -ZONE_HEIGHT * 0.5), PLAYER_MASK | ENEMY_MASK)
	_set_box(hall_entry, Vector2(hall_depth, ZONE_HEIGHT), Vector2(half + hall_depth * 0.5, -ZONE_HEIGHT * 0.5), ENEMY_MASK)
	_set_box(hall_exit, Vector2(hall_depth, ZONE_HEIGHT), Vector2(-half - hall_depth * 0.5, -ZONE_HEIGHT * 0.5), ENEMY_MASK)
	entry_door.position = Vector2(half, 0.0)
	entry_door.scale.x = -1.0
	exit_door.position = Vector2(-half, 0.0)
	for door: Node2D in [entry_door, exit_door]:
		door.set("auto_open_range", 0.0)
		door.set("close_behind", false)
		door.set("locked_text", HALL_TEXT)
		door.set("sealed_text", HALL_TEXT)
	checkpoint.set("index", checkpoint_index)
	checkpoint.set("stage", checkpoint_stage)
	zone.body_entered.connect(_on_zone_entered)
	zone.body_exited.connect(_on_zone_exited)


func _physics_process(_delta: float) -> void:
	for body: Node2D in zone.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			neutralise(body)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	_update_door(entry_door, hall_entry, player)
	_update_door(exit_door, hall_exit, player)


func hall_enemies(hall: Area2D) -> int:
	var count: int = 0
	for body: Node2D in hall.get_overlapping_bodies():
		if body.is_in_group("enemies") and not _is_dead(body):
			count += 1
	return count


func neutralise(enemy: Node) -> void:
	if _is_dead(enemy):
		return
	if enemy.has_method("neutralise"):
		enemy.call("neutralise")
	else:
		enemy.queue_free()
	enemy_neutralised.emit(enemy)


func restore(player: Node) -> void:
	if player != null and player.has_method("restore_all"):
		player.call("restore_all")


func add_box(tier: String = "Bronze") -> Area2D:
	var box: Area2D = LOOT_BOX.instantiate() as Area2D
	box.set("tier", tier)
	box.set("kit", box_kit)
	box.set("slot", get_tree().get_nodes_in_group("loot_boxes").size())
	add_child(box)
	box.global_position = box_spot.global_position
	box.call("summon", get_tree().get_first_node_in_group("player"), box_spot.global_position)
	return box


func dress(slot_name: String, scene: PackedScene) -> Node2D:
	var slot: Node2D = prop_slots.get_node_or_null(slot_name) as Node2D
	if slot == null or scene == null:
		return null
	var prop: Node2D = scene.instantiate() as Node2D
	slot.add_child(prop)
	return prop


func _on_zone_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		neutralise(body)
		return
	if not body.is_in_group("player"):
		return
	player_inside = true
	visited = true
	Game.set_safe_zone(true)
	restore(body)
	Game.set_checkpoint(checkpoint_index, checkpoint.global_position, checkpoint_stage)
	if checkpoint.has_method("_set_lit") and not bool(checkpoint.get("lit")):
		checkpoint.call("_set_lit", true, true)
	if not _boxes_given:
		_boxes_given = true
		for tier: String in box_tiers:
			add_box.call_deferred(tier)
	_give_earned_boxes.call_deferred()
	SystemVoice.fire("first_safe_room")
	entered.emit()


func _give_earned_boxes() -> void:
	for tier: String in Game.take_earned_boxes():
		add_box(tier)


func _on_zone_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	Game.set_safe_zone(false)
	exited.emit()


func _update_door(door: Node2D, hall: Area2D, player: Node2D) -> void:
	if bool(door.get("_busy")) or player == null:
		return
	var blocked: bool = hall_enemies(hall) > 0
	var dx: float = absf(player.global_position.x - door.global_position.x)
	var is_open: bool = bool(door.get("is_open"))
	if is_open:
		if dx > DOOR_STAND_CLEAR and (blocked or (player_inside and dx > DOOR_CLOSE_RANGE)):
			door.call("close")
		return
	if blocked:
		door.set("locked", true)
		door.set("locked_text", HALL_TEXT)
		return
	door.set("locked", false)
	if dx <= DOOR_OPEN_RANGE:
		door.call("open")


func _is_dead(node: Node) -> bool:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return true
	if node.has_method("is_dead") and bool(node.call("is_dead")):
		return true
	var state: Variant = node.get("state")
	var script: Script = node.get_script()
	if state != null and script is GDScript:
		var states: Variant = (script as GDScript).get_script_constant_map().get("State")
		if states is Dictionary and states.has("DEAD") and int(state) == int(states["DEAD"]):
			return true
	return false


func _set_box(area: Area2D, size: Vector2, pos: Vector2, mask: int) -> void:
	area.collision_layer = 0
	area.collision_mask = mask
	var shape: CollisionShape2D = area.get_node("CollisionShape2D") as CollisionShape2D
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
