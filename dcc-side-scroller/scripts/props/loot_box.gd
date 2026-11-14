extends Area2D

signal opened(tier: String)

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")
const LootTables: GDScript = preload("res://scripts/data/loot_tables.gd")
const SHEET: Texture2D = preload("res://assets/props/loot_box.png")
const HIT_SPARK: PackedScene = preload("res://scenes/fx/hit_spark.tscn")
const FRAME: Vector2i = Vector2i(32, 32)
const ANIMS: Dictionary = {
	"bronze_idle": {"row": 0, "count": 2, "fps": 3.0, "loop": true},
	"bronze_open": {"row": 1, "count": 5, "fps": 10.0, "loop": false},
	"silver_idle": {"row": 2, "count": 2, "fps": 3.0, "loop": true},
	"silver_open": {"row": 3, "count": 5, "fps": 10.0, "loop": false},
	"gold_idle": {"row": 4, "count": 2, "fps": 3.0, "loop": true},
	"gold_open": {"row": 5, "count": 5, "fps": 10.0, "loop": false},
	"legendary_idle": {"row": 6, "count": 2, "fps": 3.0, "loop": true},
	"legendary_open": {"row": 7, "count": 5, "fps": 10.0, "loop": false},
}

const ACHIEVEMENTS: Dictionary = {
	"Bronze": ["Participation Trophy, Boxed", "You opened a Bronze box. The contents are worth slightly less than the box."],
	"Silver": ["Aggressively Mediocre", "A Silver box. Not good, not bad, exactly like your odds of surviving."],
	"Gold": ["Shiny Object Syndrome", "A Gold box! Try not to get stabbed while you admire it."],
	"Boss": ["Participation Trophy, Bloody", "A Boss box. You killed something to get it. The System would like you to feel nothing about that."],
	"Legendary": ["Peaked Early", "A Legendary box this soon, and it holds a biscuit. Donut approves. Statistically, it is all downhill from here."],
}

const FACE_HEIGHT: float = 24.0
const FIRST_DISTANCE: float = 34.0
const LINE_SPACING: float = 32.0
const START_EXTRA: float = 50.0
const DRIFT_SECONDS: float = 2.5
const FOLLOW_RATE: float = 5.0
const INTERACT_RANGE: float = 160.0
const ARM_SECONDS: float = 0.5

@export_enum("Bronze", "Silver", "Gold", "Legendary", "Boss") var tier: String = "Bronze"
## Loot table set, see loot_tables.gd. Empty is the fixed tutorial kit.
@export var kit: String = ""
@export var start_hidden: bool = true
@export var slot: int = 0

static var _last_open_frame: int = -1

## Item rolled by the last open, for tests and the HUD.
var rewarded_id: String = ""

var is_open: bool = false
var summoned: bool = false

var _target: Node2D = null
var _age: float = 0.0
var _sprite: AnimatedSprite2D

@onready var _visual: Node2D = $Visual
@onready var prompt: Label = $Prompt


func _ready() -> void:
	add_to_group("loot_boxes")
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.name = "Sprite"
	_visual.add_child(_sprite)
	_visual.position = Vector2(0.0, 16.0)
	_sprite.play(_look() + "_idle")
	prompt.visible = false
	prompt.position.y = -52.0
	prompt.z_index = 50
	prompt.z_as_relative = false
	if start_hidden:
		visible = false
	else:
		summon(get_tree().get_first_node_in_group("player") as Node2D, global_position)


func summon(target: Node2D, from: Vector2) -> void:
	if target == null or summoned:
		return
	_target = target
	summoned = true
	_age = 0.0
	global_position = from
	visible = true


func _process(delta: float) -> void:
	if not summoned or _target == null:
		return
	_age += delta
	_visual.position.y = 16.0 + sin(_age * 3.0 + float(slot)) * 2.0
	if is_open:
		return
	var facing: float = float(_target.get("facing")) if _target.get("facing") != null else 1.0
	var progress: float = clampf(_age / DRIFT_SECONDS, 0.0, 1.0)
	var layout: Vector2 = _layout()
	z_index = 12 - mini(int(layout.x), 10)
	var dist: float = FIRST_DISTANCE + layout.x * LINE_SPACING + START_EXTRA * (1.0 - progress)
	var desired: Vector2 = _target.global_position + Vector2(facing * dist, -FACE_HEIGHT)
	global_position = global_position.lerp(desired, 1.0 - exp(-FOLLOW_RATE * delta))
	var focused: bool = _is_focused() and global_position.distance_to(_target.global_position) <= INTERACT_RANGE
	prompt.visible = focused
	if not focused:
		return
	prompt.text = "E: open" if Game.in_safe_zone else "Safe zones only"
	if Game.in_safe_zone and _age > ARM_SECONDS and _last_open_frame != Engine.get_process_frames() and Game.action_just_pressed("interact"):
		_open()


func _layout() -> Vector2:
	var rank: int = 0
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(node.get("is_open")) or not bool(node.get("summoned")):
			continue
		count += 1
		if int(node.get("slot")) < slot or (int(node.get("slot")) == slot and node.get_instance_id() < get_instance_id()):
			rank += 1
	return Vector2(float(rank), float(count))


func _is_focused() -> bool:
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		var other: Node = node
		if other == self or bool(other.get("is_open")) or not bool(other.get("summoned")):
			continue
		if int(other.get("slot")) < slot:
			return false
	return true


func _look() -> String:
	return "legendary" if tier == "Boss" else tier.to_lower()


func _open() -> void:
	is_open = true
	_last_open_frame = Engine.get_process_frames()
	prompt.visible = false
	_sprite.play(_look() + "_open")
	var spark: Node2D = HIT_SPARK.instantiate() as Node2D
	get_tree().current_scene.add_child(spark)
	spark.global_position = global_position
	var reward: Dictionary = LootTables.roll(kit, tier)
	rewarded_id = str(reward["id"])
	ItemDefs.give(rewarded_id, int(reward["count"]))
	Game.report_loot_box_opened(tier)
	opened.emit(tier)
	var entry: Array = ACHIEVEMENTS.get(tier, ACHIEVEMENTS["Bronze"])
	Game.unlock_achievement("loot_" + tier.to_lower(), str(entry[0]), str(entry[1]))
	var tween: Tween = create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(self, "position:y", position.y - 24.0, 0.8)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(hide)
