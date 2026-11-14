extends CanvasLayer

signal finished(took_item: bool)

const SYSTEM_LINE: String = "Your views just dropped. Nobody wants this."
const LEAVE_TEXT: String = "E: leave"
const FADE: float = 0.3
const ARM_SECONDS: float = 0.5

var item_name: String = ""
var ready_to_leave: bool = false
var closed: bool = false

var _fade: ColorRect
var _prompt: Label


func _ready() -> void:
	layer = 80
	_build()


func begin(hidden_item: String) -> void:
	item_name = hidden_item
	if _prompt != null:
		_refresh_prompt()


func _process(_delta: float) -> void:
	if ready_to_leave and not closed and Game.action_just_pressed("interact"):
		leave()


func leave() -> void:
	if closed:
		return
	closed = true
	ready_to_leave = false
	var took: bool = not item_name.is_empty()
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE)
	tween.tween_callback(func() -> void: finished.emit(took))


func _refresh_prompt() -> void:
	if item_name.is_empty():
		_prompt.text = LEAVE_TEXT
	else:
		_prompt.text = "Taped under the cistern: %s.\n%s (take it)" % [item_name, LEAVE_TEXT]


func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


func _label(text: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label


func _build() -> void:
	var room: Control = Control.new()
	room.name = "Room"
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(room)
	_rect(room, Vector2.ZERO, Vector2(640.0, 360.0), Color(0.07, 0.08, 0.09))
	_rect(room, Vector2(160.0, 40.0), Vector2(320.0, 240.0), Color(0.55, 0.62, 0.6))
	_rect(room, Vector2(160.0, 280.0), Vector2(320.0, 20.0), Color(0.25, 0.27, 0.28))
	var toilet: Control = Control.new()
	toilet.name = "Toilet"
	toilet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(toilet)
	_rect(toilet, Vector2(290.0, 150.0), Vector2(60.0, 60.0), Color(0.78, 0.8, 0.82))
	_rect(toilet, Vector2(280.0, 208.0), Vector2(80.0, 20.0), Color(0.83, 0.85, 0.87))
	_rect(toilet, Vector2(296.0, 228.0), Vector2(48.0, 52.0), Color(0.7, 0.72, 0.74))
	_rect(toilet, Vector2(284.0, 205.0), Vector2(72.0, 4.0), Color(0.16, 0.18, 0.2))
	var line: Label = _label(SYSTEM_LINE, Vector2(140.0, 304.0), Vector2(360.0, 24.0), 10)
	line.name = "SystemLine"
	_prompt = _label(LEAVE_TEXT, Vector2(140.0, 322.0), Vector2(360.0, 34.0), 8)
	_prompt.name = "Prompt"
	_refresh_prompt()
	_fade = _rect(self, Vector2.ZERO, Vector2(640.0, 360.0), Color(0.0, 0.0, 0.0, 1.0))
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE)
	tween.tween_interval(ARM_SECONDS)
	tween.tween_callback(func() -> void: ready_to_leave = true)
