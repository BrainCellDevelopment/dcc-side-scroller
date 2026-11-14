extends Node2D
## The Level 2 reward room (end of the dog pound): a small menagerie where Donut picks a pet. The
## only choice on offer is Mongo the Mongoliensis, who then follows Carl and bites Donut's nose.
## Origin is the middle of the room on the floor line. Sets Game meta "pet_mongo".

signal pet_chosen

const MONGO: GDScript = preload("res://scripts/props/mongo.gd")
const RANGE: float = 34.0
const FLAG: String = "pet_mongo"
const TITLE: String = "PET ADOPTED: MONGO"
const BODY: String = "A Mongoliensis, seven inches tall and furious about it. Donut named him. He has already bitten her nose."
const PROMPT: String = "E: pick a pet"
const WALL: Color = Color(0.58, 0.56, 0.52)
const WALL_LINE: Color = Color(0.5, 0.48, 0.45)
const BEAM: Color = Color(0.2, 0.18, 0.18)
const BARS: Color = Color(0.5, 0.54, 0.6)
const PINK: Color = Color(1.0, 0.66, 0.74)
const HALF: float = 130.0

var chosen: bool = false
var mongo: Node2D = null

var _prompt: Label = null
var _clock: float = 0.0


func _ready() -> void:
	z_index = -1
	_prompt = Label.new()
	_prompt.text = PROMPT
	_prompt.position = Vector2(-40.0, -66.0)
	_prompt.size = Vector2(80.0, 12.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.z_index = 50
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var near: bool = player != null and not chosen and absf(player.global_position.x - global_position.x) <= RANGE and absf(player.global_position.y - global_position.y) <= 50.0
	_prompt.visible = near
	if near and Game.action_just_pressed("interact"):
		choose(player)


func choose(player: Node2D) -> void:
	if chosen:
		return
	chosen = true
	Game.set_meta(FLAG, true)
	SystemVoice.announce(TITLE, BODY, 4.0)
	mongo = MONGO.new() as Node2D
	mongo.name = "Mongo"
	get_parent().add_child(mongo)
	mongo.global_position = global_position + Vector2(0.0, -4.0)
	mongo.set("target", player)
	pet_chosen.emit()


func _draw() -> void:
	draw_rect(Rect2(-HALF, -100.0, HALF * 2.0, 100.0), WALL)
	for i: int in 9:
		draw_rect(Rect2(-HALF + 30.0 * float(i), -100.0, 1.0, 100.0), WALL_LINE)
	draw_rect(Rect2(-HALF, -100.0, HALF * 2.0, 6.0), BEAM)
	draw_rect(Rect2(-HALF, -6.0, HALF * 2.0, 6.0), BEAM)
	# pedestal and glass cloche
	draw_rect(Rect2(-14.0, -22.0, 28.0, 22.0), Color(0.34, 0.3, 0.3))
	draw_rect(Rect2(-16.0, -24.0, 32.0, 3.0), Color(0.5, 0.46, 0.44))
	if not chosen:
		var hop: float = absf(sin(_clock * 5.0)) * 3.0
		draw_circle(Vector2(0.0, -32.0 - hop), 6.0, PINK)
		draw_circle(Vector2(5.0, -38.0 - hop), 3.6, PINK)
		draw_circle(Vector2(6.0, -39.0 - hop), 0.8, Color(0.1, 0.04, 0.08))
		draw_arc(Vector2(0.0, -34.0), 13.0, PI, TAU, 16, Color(0.7, 0.9, 1.0, 0.6), 1.0)
	# empty pet cages along the wall
	for x: float in [-110.0, -74.0, 74.0, 110.0]:
		draw_rect(Rect2(x - 14.0, -66.0, 28.0, 30.0), Color(0.12, 0.1, 0.12))
		for i: int in 5:
			draw_rect(Rect2(x - 12.0 + 6.0 * float(i), -66.0, 1.2, 30.0), BARS)
	draw_string(ThemeDB.fallback_font, Vector2(-60.0, -88.0), "PET MENAGERIE", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 8, Color(0.95, 0.9, 0.8))
