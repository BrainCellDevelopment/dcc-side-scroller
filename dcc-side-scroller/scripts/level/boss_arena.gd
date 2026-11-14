extends Node2D
## Reusable neighborhood boss framework: arena lock, intro (audio cue and the
## "Carl vs <Boss>" VS card, which is the only intro text), boss bar via Game.report_boss_health, defeat flow and
## the boss box drop. The boss scene needs `activate()` and a `defeated` signal.

signal intro_started
signal fight_started
signal boss_defeated(boss: Node)
signal audio_cue(cue: StringName)

const LOCK_BARS: GDScript = preload("res://scripts/level/boss_lock_bars.gd")
const LOOT_BOX: PackedScene = preload("res://scenes/props/loot_box.tscn")
const CARD_FADE: float = 0.3

@export var boss_name: String = "Boss"
@export var tooltip: String = ""
@export var player_name: String = "CARL"
@export var mugshot: Texture2D = null
@export var intro_seconds: float = 0.0
@export var card_seconds: float = 2.5
@export var drop_tier: String = ""
## Loot table set for the boss box (see loot_tables.gd). Use drop_tier "Boss" for the real drop.
@export var drop_kit: String = "floor1"
@export var map_reward: bool = false

var boss: Node = null
var hud: Node = null
var locked: bool = false
var started: bool = false
var finished: bool = false
var dropped_box: Node = null

var _lock_shapes: Array[CollisionShape2D] = []
var _bars: Array[Node2D] = []
var _card_layer: CanvasLayer = null


func setup(boss_node: Node, lock_shapes: Array[CollisionShape2D]) -> void:
	boss = boss_node
	_lock_shapes = lock_shapes
	for shape: CollisionShape2D in _lock_shapes:
		var bars: Node2D = LOCK_BARS.new() as Node2D
		var rect: RectangleShape2D = shape.shape as RectangleShape2D
		if rect != null:
			bars.set("size", rect.size)
		shape.get_parent().add_child(bars)
		bars.position = shape.position
		_bars.append(bars)
	boss.connect("defeated", _on_boss_defeated)


func start() -> void:
	if started:
		return
	started = true
	set_lock(true)
	audio_cue.emit(&"boss_intro")
	intro_started.emit()
	_show_card()
	if intro_seconds > 0.0:
		await get_tree().create_timer(intro_seconds).timeout
		if finished or not is_instance_valid(boss):
			return
	audio_cue.emit(&"boss_fight")
	boss.call("activate")
	fight_started.emit()


func set_lock(value: bool) -> void:
	locked = value
	for shape: CollisionShape2D in _lock_shapes:
		shape.set_deferred("disabled", not value)
	for bars: Node2D in _bars:
		bars.call("set_locked", value)


func _on_boss_defeated(node: Node) -> void:
	if finished:
		return
	finished = true
	audio_cue.emit(&"boss_defeated")
	Game.clear_boss()
	set_lock(false)
	_hide_card()
	if map_reward:
		Game.set_meta("neighborhood_map", true)
	var at: Vector2 = (node as Node2D).global_position if node is Node2D else global_position
	if drop_tier != "":
		_drop_box(at)
	boss_defeated.emit(node)


func _drop_box(at: Vector2) -> void:
	var box: Node2D = LOOT_BOX.instantiate() as Node2D
	box.set("tier", drop_tier)
	box.set("kit", drop_kit)
	box.add_to_group("boss_boxes")
	get_tree().current_scene.add_child(box)
	box.global_position = at
	box.call("summon", get_tree().get_first_node_in_group("player") as Node2D, at)
	dropped_box = box


func _show_card() -> void:
	if card_seconds <= 0.0:
		return
	_card_layer = CanvasLayer.new()
	_card_layer.layer = 30
	add_child(_card_layer)
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_layer.add_child(root)
	var band: ColorRect = ColorRect.new()
	band.color = Color(0.05, 0.02, 0.06, 0.82)
	band.anchor_right = 1.0
	band.offset_top = 70.0
	band.offset_bottom = 170.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(row)
	row.add_child(_name_label(player_name, Color(0.9, 0.9, 0.8)))
	row.add_child(_name_label("VS", Color(1.0, 0.3, 0.2)))
	row.add_child(_mugshot_node())
	var text: VBoxContainer = VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_child(_name_label(boss_name.to_upper(), Color(1.0, 0.85, 0.3)))
	if tooltip != "":
		var tip: Label = _name_label(tooltip, Color(0.8, 0.8, 0.85))
		tip.theme_type_variation = &"ShadowText"
		tip.add_theme_font_size_override("font_size", 12)
		text.add_child(tip)
	row.add_child(text)
	root.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(root, "modulate:a", 1.0, CARD_FADE)
	tween.tween_interval(maxf(card_seconds - CARD_FADE * 2.0, 0.0))
	tween.tween_property(root, "modulate:a", 0.0, CARD_FADE)
	tween.tween_callback(_hide_card)


func _name_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	return label


func _mugshot_node() -> Control:
	if mugshot != null:
		var pic: TextureRect = TextureRect.new()
		pic.texture = mugshot
		pic.custom_minimum_size = Vector2(72.0, 72.0)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		return pic
	var frame: ColorRect = ColorRect.new()
	frame.color = Color(0.25, 0.1, 0.12)
	frame.custom_minimum_size = Vector2(72.0, 72.0)
	var initial: Label = _name_label(boss_name.substr(0, 1).to_upper(), Color(1.0, 0.85, 0.3))
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(initial)
	return frame


func _hide_card() -> void:
	if _card_layer != null and is_instance_valid(_card_layer):
		_card_layer.queue_free()
	_card_layer = null
