extends Node2D
## The Clurichaun filling room's bicycle blender. Press E to blend the immunity smoothie (moonshine and
## something that used to be a fairy). It grants immunity to the Taint for the rest of the floor, which
## the Krakaren Clone's mucus needs. Origin is the floor line under the bench.

signal blended

const Taint: GDScript = preload("res://scripts/combat/taint.gd")
const RANGE: float = 34.0
const TITLE: String = "IMMUNITY SMOOTHIE"
const BODY: String = "Moonshine, a recently retired fairy, and a bicycle. You are now immune to the Taint. Do not ask what else."

var done: bool = false
var _prompt: Label = null
var _spin: float = 0.0


func _ready() -> void:
	z_index = -1
	_prompt = Label.new()
	_prompt.text = "E: blend a smoothie"
	_prompt.position = Vector2(-50.0, -62.0)
	_prompt.size = Vector2(100.0, 12.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.z_index = 50
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	_spin += delta * (14.0 if done else 0.0)
	queue_redraw()
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var near: bool = player != null and not done and absf(player.global_position.x - global_position.x) <= RANGE and absf(player.global_position.y - global_position.y) <= 50.0
	_prompt.visible = near
	if near and Game.action_just_pressed("interact"):
		_blend()


func _blend() -> void:
	done = true
	Game.set_meta(Taint.IMMUNE_FLAG, true)
	SystemVoice.announce(TITLE, BODY, 4.0)
	blended.emit()


func _draw() -> void:
	# stacked jugs
	for i: int in 3:
		draw_rect(Rect2(-44.0 + 11.0 * float(i), -16.0, 9.0, 16.0), Color(0.46, 0.34, 0.2))
		draw_rect(Rect2(-42.0 + 11.0 * float(i), -20.0, 5.0, 4.0), Color(0.3, 0.22, 0.14))
	# tub
	draw_rect(Rect2(-8.0, -12.0, 34.0, 12.0), Color(0.62, 0.64, 0.66))
	draw_rect(Rect2(-8.0, -12.0, 34.0, 2.0), Color(0.82, 0.84, 0.86))
	# bicycle blender
	draw_arc(Vector2(34.0, -9.0), 9.0, 0.0, TAU, 20, Color(0.2, 0.2, 0.22), 2.0)
	draw_arc(Vector2(60.0, -9.0), 9.0, 0.0, TAU, 20, Color(0.2, 0.2, 0.22), 2.0)
	for i: int in 3:
		var a: float = _spin + TAU * float(i) / 3.0
		draw_line(Vector2(34.0, -9.0), Vector2(34.0, -9.0) + Vector2(cos(a), sin(a)) * 8.0, Color(0.5, 0.5, 0.52), 1.0)
	draw_line(Vector2(34.0, -9.0), Vector2(47.0, -26.0), Color(0.3, 0.3, 0.34), 2.0)
	draw_line(Vector2(47.0, -26.0), Vector2(60.0, -9.0), Color(0.3, 0.3, 0.34), 2.0)
	draw_rect(Rect2(40.0, -46.0, 14.0, 18.0), Color(0.7, 0.86, 0.9, 0.7))
	draw_rect(Rect2(40.0, -38.0, 14.0, 10.0), Color(0.5, 0.82, 0.4, 0.85) if not done else Color(0.9, 0.55, 0.2, 0.9))
	draw_rect(Rect2(38.0, -48.0, 18.0, 3.0), Color(0.15, 0.15, 0.18))
	# banner
	draw_rect(Rect2(-40.0, -80.0, 108.0, 14.0), Color(0.1, 0.3, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(-40.0, -70.0), "REV-UP SMOOTHIES", HORIZONTAL_ALIGNMENT_CENTER, 108.0, 8, Color(0.85, 0.95, 1.0))
