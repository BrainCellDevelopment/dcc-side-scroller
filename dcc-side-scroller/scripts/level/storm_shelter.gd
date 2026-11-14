extends Node2D
## The Floor 2 storm shelter: a concrete bunker with dusty cots, old TVs and a mailbox. Mordecai (now a
## Bugaboo) waits here, the whole room is a safe zone (so any unopened loot box can be opened), and the
## mailbox hands Donut her Floor 2 spell, Second Chance. Origin is the middle of the room on the floor line.

signal mail_collected
signal ready_to_leave

const LOOT_BOX: PackedScene = preload("res://scenes/props/loot_box.tscn")
const MORDECAI: PackedScene = preload("res://scenes/props/mordecai.tscn")
const SET: GDScript = preload("res://scripts/level/storm_shelter_set.gd")
const BUGABOO: Texture2D = preload("res://assets/characters/bugaboo.png")
const ZONE_SIZE: Vector2 = Vector2(700.0, 140.0)
const MORDECAI_X: float = 40.0
const MAILBOX_X: float = 250.0
const MAIL_RANGE: float = 30.0
const SPELL_FLAG: String = "second_chance"
const SPELL_TITLE: String = "NEW SPELL: SECOND CHANCE"
const SPELL_BODY: String = "Donut now knows a spell that reanimates a foe. The mailbox is, as far as anyone can tell, not a metaphor."
const LINES: PackedStringArray = [
	"Floor two. Same building, whiter paint. I was a rat last floor. This is what the System calls growth.",
	"The bunker is a safe room. Open your boxes, check the mailbox, and do not touch the cots. They have opinions.",
	"Bring me the receipts later. Go on. Be useful.",
]
const REPEAT_LINE: String = "Mailbox, boxes, door. In that order. I am not a tour guide."

var mordecai: Area2D = null
var talked: bool = false
var mail_taken: bool = false
var player_inside: bool = false

var _prompt: Label = null
var _announced: bool = false


func _ready() -> void:
	var set_piece: Node2D = SET.new() as Node2D
	set_piece.name = "Set"
	set_piece.z_index = -3
	set_piece.set("mailbox_x", MAILBOX_X)
	add_child(set_piece)
	mordecai = MORDECAI.instantiate() as Area2D
	mordecai.set("sheet", BUGABOO)
	mordecai.set("frame_size", Vector2i(40, 52))
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
	_prompt = Label.new()
	_prompt.text = "E: check the mail"
	_prompt.position = Vector2(MAILBOX_X - 40.0, -62.0)
	_prompt.size = Vector2(80.0, 12.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.z_index = 50
	_prompt.visible = false
	add_child(_prompt)


func _process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var near: bool = false
	if player != null and not mail_taken:
		var mailbox: Vector2 = global_position + Vector2(MAILBOX_X, -10.0)
		near = player.global_position.distance_to(mailbox) <= MAIL_RANGE
	_prompt.visible = near
	if near and Game.action_just_pressed("interact"):
		_collect_mail()
	if not _announced and is_ready():
		_announced = true
		ready_to_leave.emit()


func _collect_mail() -> void:
	mail_taken = true
	Game.set_meta(SPELL_FLAG, true)
	SystemVoice.announce(SPELL_TITLE, SPELL_BODY, 4.0)
	(get_node("Set") as Node2D).set("mail_open", true)
	(get_node("Set") as Node2D).queue_redraw()
	mail_collected.emit()


## True once Mordecai has been spoken to, the mail is taken and no summoned box is left unopened.
func is_ready() -> bool:
	if not talked or not mail_taken:
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
