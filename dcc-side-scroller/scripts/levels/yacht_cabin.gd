extends Node2D
## The production yacht cabin (#68): a code-drawn set (blue velvet couch, bar, porthole), a short
## text-driven interview with the host Odette, then the level summary and the hand-off to Level 2.
## advance() moves the exchange along (E, jump or attack in play; tests call it directly).

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SUMMARY: GDScript = preload("res://scripts/ui/level_summary.gd")
const TYPE_SPEED: float = 70.0
const FADE_SECONDS: float = 0.6
const FLOOR_Y: float = 172.0
const ROOM_H: float = 252.0
const BOX_TOP: float = 258.0
const CARL_X: float = 120.0
const DONUT_X: float = 176.0
const ODETTE_X: float = 436.0
const CAMERA_X: float = 300.0
const FEET_Y: float = 232.0

const WALL: Color = Color(0.078, 0.137, 0.227)
const WALL_LINE: Color = Color(0.105, 0.18, 0.285)
const WOOD_DARK: Color = Color(0.2, 0.11, 0.07)
const WOOD: Color = Color(0.29, 0.165, 0.094)
const WOOD_LIGHT: Color = Color(0.42, 0.26, 0.15)
const BRASS: Color = Color(0.86, 0.66, 0.26)
const VELVET_DARK: Color = Color(0.09, 0.19, 0.5)
const VELVET: Color = Color(0.13, 0.27, 0.68)
const VELVET_LIGHT: Color = Color(0.22, 0.4, 0.86)
const RUG: Color = Color(0.36, 0.1, 0.14)

## Each step is {who, text} or {choice: [a, b], replies: [[who, text], [who, text]]}. "needs" gates a step on a Game flag.
const STEPS: Array[Dictionary] = [
	{"who": "", "text": "THE PRODUCTION YACHT\nSomewhere above the floor you just left."},
	{"who": "ODETTE", "text": "Carl. Donut. Sit. The couch is velvet and it has heard worse than anything you are about to say."},
	{"who": "ODETTE", "text": "You came down a flight of stairs and the floor behind you stopped existing. Take a breath. Then tell the audience how that was."},
	{"choice": ["Quiet. Then loud. Then quiet.", "Ask me when I am not tired."], "replies": [
		["ODETTE", "Quiet is the honest answer. We will keep that one."],
		["ODETTE", "Fair. Tired is honest too. We will keep that one."],
	]},
	{"who": "DONUT", "text": "He is being brave and it is very dull. Ask me. I was fabulous, and I have notes on the lighting."},
	{"who": "ODETTE", "text": "The audience liked the pig. They liked what you did with the pig more. A few of them asked about the cigarette."},
	{"who": "CARL", "text": "It was the last one.", "needs": "last_cigarette"},
	{"who": "ODETTE", "text": "Floor two is the same building with whiter paint and worse lighting. Try not to get sentimental about the walls."},
	{"who": "SYSTEM", "text": "Interview complete. Please exit by the stairs. There are always stairs."},
]

var finished: bool = false
var summary_shown: bool = false
var handoff_started: bool = false
var step_index: int = -1
var choice_made: int = -1
## Seconds before the next line moves on by itself; 0 waits for the player.
var auto_seconds: float = 0.0

var _steps: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _speaker: Label = null
var _text: Label = null
var _prompt: Label = null
var _box: Control = null
var _shown: float = 0.0
var _typing: bool = false
var _choosing: bool = false
var _highlight: int = 0
var _auto_left: float = 0.0
var _time: float = 0.0
var _carl: AnimatedSprite2D = null
var _fade: ColorRect = null
var _layer: CanvasLayer = null
var _summary_layer: CanvasLayer = null


func _ready() -> void:
	z_index = 0
	_build_actors()
	_build_ui()
	if FloorHandoff.summary.is_empty():
		FloorHandoff.snapshot()
	for step: Dictionary in STEPS:
		if step.has("needs") and not bool(Game.get_meta(str(step["needs"]), false)):
			continue
		_steps.append(step)
	_next_step()
	_fade_in()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _typing and _text != null:
		_shown += TYPE_SPEED * delta
		_text.visible_characters = int(_shown)
		if _shown >= float(_text.text.length()):
			_finish_typing()
	elif auto_seconds > 0.0 and not _choosing and not finished and not handoff_started:
		_auto_left -= delta
		if _auto_left <= 0.0:
			advance()
	if _choosing:
		if Game.action_just_pressed(&"move_left") or Game.action_just_pressed(&"move_right"):
			_highlight = 1 - _highlight
			_show_choice()
	for action: StringName in [&"interact", &"jump", &"attack"]:
		if Game.action_just_pressed(action):
			advance()
			break


## One press: finish the line being typed, pick the highlighted answer, or go to the next line.
func advance() -> void:
	if handoff_started:
		return
	if summary_shown:
		_leave()
		return
	if _typing:
		_finish_typing()
		return
	if _choosing:
		choose(_highlight)
		return
	_next_step()


func choose(index: int) -> void:
	if not _choosing:
		return
	_choosing = false
	choice_made = clampi(index, 0, 1)
	Game.set_meta("interview_answer", choice_made)
	var step: Dictionary = _steps[step_index]
	var reply: Array = (step["replies"] as Array)[choice_made]
	_queue.push_front({"who": str(reply[0]), "text": str(reply[1])})
	_next_step()


func _next_step() -> void:
	if not _queue.is_empty():
		_show_line(_queue.pop_front())
		return
	step_index += 1
	if step_index >= _steps.size():
		finished = true
		_show_summary()
		return
	var step: Dictionary = _steps[step_index]
	if step.has("choice"):
		_choosing = true
		_highlight = 0
		_show_choice()
		return
	_show_line(step)


func _show_line(step: Dictionary) -> void:
	_speaker.text = str(step.get("who", ""))
	_speaker.add_theme_color_override("font_color", _speaker_color(_speaker.text))
	_text.text = str(step["text"])
	_text.visible_characters = 0
	_shown = 0.0
	_typing = true
	_prompt.text = "E"
	_auto_left = auto_seconds


func _show_choice() -> void:
	var step: Dictionary = _steps[step_index]
	var options: Array = step["choice"]
	_speaker.text = "CARL"
	_speaker.add_theme_color_override("font_color", _speaker_color("CARL"))
	var parts: PackedStringArray = PackedStringArray()
	for i: int in options.size():
		parts.append(("> " if i == _highlight else "   ") + str(options[i]))
	_text.text = "\n".join(parts)
	_text.visible_characters = -1
	_typing = false
	_prompt.text = "A / D to pick, E to answer"


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_auto_left = auto_seconds


func _speaker_color(who: String) -> Color:
	match who:
		"ODETTE":
			return Color(0.45, 0.9, 0.78)
		"DONUT":
			return Color(1.0, 0.7, 0.85)
		"CARL":
			return Color(0.95, 0.85, 0.55)
		"SYSTEM":
			return Color(1.0, 0.82, 0.25)
	return Color(0.8, 0.8, 0.85)


func _show_summary() -> void:
	summary_shown = true
	_box.visible = false
	_summary_layer = SUMMARY.new() as CanvasLayer
	_summary_layer.call("setup", FloorHandoff.summary)
	add_child(_summary_layer)


func _leave() -> void:
	if handoff_started:
		return
	handoff_started = true
	await _fade_out()
	FloorHandoff.go(get_tree(), FloorHandoff.LEVEL2_SCENE)


func _fade_in() -> void:
	_fade.color.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)


func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	await tween.finished


func _build_actors() -> void:
	_carl = SpriteUtil.make_sprite(Game.skin_sheet(), Game.skin_frame(), Game.skin_anims())
	_carl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_carl.scale = Vector2.ONE * Game.skin_scale()
	_carl.position = Vector2(CARL_X, FEET_Y)
	_carl.play("idle")
	add_child(_carl)


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)
	_box = Control.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_box)
	var panel: ColorRect = ColorRect.new()
	panel.color = Color(0.04, 0.05, 0.1, 0.96)
	panel.position = Vector2(0.0, BOX_TOP)
	panel.size = Vector2(640.0, 360.0 - BOX_TOP)
	_box.add_child(panel)
	_speaker = Label.new()
	_speaker.position = Vector2(20.0, BOX_TOP + 6.0)
	_speaker.add_theme_font_size_override("font_size", 11)
	_box.add_child(_speaker)
	_text = Label.new()
	_text.position = Vector2(20.0, BOX_TOP + 22.0)
	_text.size = Vector2(600.0, 70.0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 11)
	_box.add_child(_text)
	_prompt = Label.new()
	_prompt.position = Vector2(560.0, 336.0)
	_prompt.size = Vector2(70.0, 14.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_box.add_child(_prompt)
	var fade_layer: CanvasLayer = CanvasLayer.new()
	fade_layer.layer = 90
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


# ------------------------------------------------------------------ the set (all code-drawn)

func _draw() -> void:
	_draw_room()
	_draw_porthole(Vector2(330.0, 70.0), 34.0)
	_draw_bar()
	_draw_couch()
	_draw_camera()
	_draw_donut(Vector2(DONUT_X, FEET_Y))
	_draw_odette(Vector2(ODETTE_X, FEET_Y))
	_draw_lamp()


func _draw_room() -> void:
	draw_rect(Rect2(0.0, 0.0, 640.0, FLOOR_Y), WALL)
	for x: int in range(0, 640, 40):
		draw_rect(Rect2(float(x), 0.0, 2.0, FLOOR_Y), WALL_LINE)
	draw_rect(Rect2(0.0, 118.0, 640.0, FLOOR_Y - 118.0), Color(0.13, 0.08, 0.06))
	draw_rect(Rect2(0.0, 116.0, 640.0, 3.0), WOOD_LIGHT)
	draw_rect(Rect2(0.0, FLOOR_Y, 640.0, ROOM_H - FLOOR_Y), WOOD_DARK)
	var y: float = FLOOR_Y + 8.0
	while y < ROOM_H:
		draw_rect(Rect2(0.0, y, 640.0, 1.0), Color(0.11, 0.06, 0.04))
		y += 10.0
	draw_rect(Rect2(96.0, 196.0, 380.0, 50.0), RUG)
	draw_rect(Rect2(96.0, 196.0, 380.0, 50.0), BRASS, false, 1.0)
	draw_rect(Rect2(104.0, 202.0, 364.0, 38.0), Color(0.5, 0.18, 0.2), false, 1.0)


func _draw_porthole(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 5.0, BRASS)
	draw_circle(center, radius + 2.0, Color(0.5, 0.36, 0.14))
	draw_circle(center, radius, Color(0.04, 0.14, 0.26))
	for i: int in 7:
		var dy: float = -radius * 0.7 + float(i) * radius * 0.23
		var half: float = sqrt(maxf(radius * radius - dy * dy, 0.0)) * 0.8
		var wobble: float = sin(_time * 0.8 + float(i) * 1.7) * 6.0
		draw_line(center + Vector2(-half * 0.5 + wobble, dy), center + Vector2(half * 0.3 + wobble, dy), Color(0.2, 0.42, 0.6, 0.55), 1.0)
	draw_circle(center + Vector2(14.0, -14.0), 4.0, Color(0.95, 0.93, 0.8, 0.9))
	for k: int in 8:
		var a: float = float(k) * TAU / 8.0
		draw_circle(center + Vector2(cos(a), sin(a)) * (radius + 3.5), 1.6, Color(0.3, 0.2, 0.08))


func _draw_bar() -> void:
	draw_rect(Rect2(474.0, 96.0, 150.0, 4.0), WOOD_LIGHT)
	var colors: Array[Color] = [Color(0.2, 0.55, 0.3), Color(0.7, 0.35, 0.1), Color(0.55, 0.15, 0.2), Color(0.25, 0.4, 0.7), Color(0.8, 0.7, 0.3)]
	for i: int in 10:
		var height: float = 14.0 + float((i * 7) % 5) * 2.0
		var x: float = 480.0 + float(i) * 14.0
		draw_rect(Rect2(x, 96.0 - height, 7.0, height), colors[i % colors.size()])
		draw_rect(Rect2(x + 2.0, 96.0 - height - 4.0, 3.0, 4.0), colors[i % colors.size()].darkened(0.3))
	draw_rect(Rect2(470.0, 150.0, 162.0, 80.0), WOOD)
	draw_rect(Rect2(470.0, 150.0, 162.0, 5.0), WOOD_LIGHT)
	draw_rect(Rect2(466.0, 146.0, 170.0, 5.0), BRASS)
	for x: int in range(478, 628, 30):
		draw_rect(Rect2(float(x), 162.0, 22.0, 60.0), WOOD_DARK, false, 1.0)
	for x: int in [502, 566]:
		draw_circle(Vector2(float(x), 236.0), 9.0, VELVET_DARK)
		draw_rect(Rect2(float(x) - 1.0, 238.0, 2.0, 12.0), BRASS)


func _draw_couch() -> void:
	draw_rect(Rect2(28.0, 112.0, 188.0, 70.0), VELVET_DARK)
	draw_rect(Rect2(34.0, 118.0, 176.0, 56.0), VELVET)
	for i: int in 5:
		for j: int in 2:
			draw_circle(Vector2(54.0 + float(i) * 36.0, 134.0 + float(j) * 22.0), 1.8, VELVET_DARK)
	draw_rect(Rect2(34.0, 170.0, 176.0, 28.0), VELVET_LIGHT)
	draw_rect(Rect2(34.0, 190.0, 176.0, 8.0), VELVET_DARK)
	draw_rect(Rect2(20.0, 134.0, 24.0, 66.0), VELVET_DARK)
	draw_rect(Rect2(200.0, 134.0, 24.0, 66.0), VELVET_DARK)
	draw_rect(Rect2(24.0, 136.0, 16.0, 6.0), VELVET)
	draw_rect(Rect2(204.0, 136.0, 16.0, 6.0), VELVET)
	for x: int in [30, 206]:
		draw_rect(Rect2(float(x), 200.0, 6.0, 8.0), BRASS)


func _draw_camera() -> void:
	var base: Vector2 = Vector2(CAMERA_X, FEET_Y)
	draw_line(base + Vector2(0.0, -26.0), base + Vector2(-10.0, 0.0), Color(0.1, 0.1, 0.12), 2.0)
	draw_line(base + Vector2(0.0, -26.0), base + Vector2(10.0, 0.0), Color(0.1, 0.1, 0.12), 2.0)
	draw_line(base + Vector2(0.0, -26.0), base + Vector2(0.0, 0.0), Color(0.1, 0.1, 0.12), 2.0)
	draw_rect(Rect2(base + Vector2(-10.0, -40.0), Vector2(20.0, 14.0)), Color(0.12, 0.12, 0.15))
	draw_rect(Rect2(base + Vector2(-14.0, -37.0), Vector2(5.0, 8.0)), Color(0.2, 0.2, 0.26))
	if int(_time * 1.6) % 2 == 0:
		draw_circle(base + Vector2(6.0, -37.0), 1.6, Color(0.95, 0.15, 0.12))


func _draw_donut(feet: Vector2) -> void:
	var body: Color = Color(0.96, 0.9, 0.8)
	draw_circle(feet + Vector2(0.0, -9.0), 9.0, body)
	draw_circle(feet + Vector2(0.0, -22.0), 7.0, body)
	var ear: PackedVector2Array = PackedVector2Array([feet + Vector2(-7.0, -26.0), feet + Vector2(-5.0, -33.0), feet + Vector2(-2.0, -27.0)])
	draw_colored_polygon(ear, body)
	ear = PackedVector2Array([feet + Vector2(7.0, -26.0), feet + Vector2(5.0, -33.0), feet + Vector2(2.0, -27.0)])
	draw_colored_polygon(ear, body)
	draw_circle(feet + Vector2(-2.5, -22.0), 1.0, Color(0.1, 0.1, 0.15))
	draw_circle(feet + Vector2(2.5, -22.0), 1.0, Color(0.1, 0.1, 0.15))
	draw_circle(feet + Vector2(0.0, -26.0), 2.0, Color(1.0, 0.55, 0.75))
	draw_line(feet + Vector2(8.0, -4.0), feet + Vector2(16.0, -12.0 + sin(_time * 2.0) * 3.0), body, 2.0)


func _draw_odette(feet: Vector2) -> void:
	var dress: Color = Color(0.1, 0.45, 0.4)
	draw_rect(Rect2(feet + Vector2(-5.0, -14.0), Vector2(4.0, 14.0)), Color(0.08, 0.06, 0.08))
	draw_rect(Rect2(feet + Vector2(1.0, -14.0), Vector2(4.0, 14.0)), Color(0.08, 0.06, 0.08))
	var skirt: PackedVector2Array = PackedVector2Array([feet + Vector2(-9.0, -14.0), feet + Vector2(9.0, -14.0), feet + Vector2(6.0, -38.0), feet + Vector2(-6.0, -38.0)])
	draw_colored_polygon(skirt, dress)
	draw_rect(Rect2(feet + Vector2(-6.0, -52.0), Vector2(12.0, 14.0)), dress.lightened(0.1))
	draw_circle(feet + Vector2(0.0, -58.0), 6.5, Color(0.85, 0.62, 0.46))
	draw_circle(feet + Vector2(0.0, -62.0), 6.5, Color(0.1, 0.07, 0.1))
	draw_arc(feet + Vector2(0.0, -59.0), 7.0, PI * 1.1, PI * 1.9, 8, Color(0.75, 0.75, 0.8), 1.0)
	draw_rect(Rect2(feet + Vector2(-9.0, -50.0), Vector2(3.0, 16.0)), Color(0.85, 0.62, 0.46))
	draw_rect(Rect2(feet + Vector2(-17.0, -48.0), Vector2(10.0, 3.0)), Color(0.85, 0.62, 0.46))


func _draw_lamp() -> void:
	for i: int in 6:
		draw_circle(Vector2(320.0, 0.0), 120.0 - float(i) * 18.0, Color(1.0, 0.85, 0.5, 0.03))
