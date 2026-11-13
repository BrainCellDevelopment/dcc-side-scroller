extends CanvasLayer

const HEALTH_BAR_WIDTH: float = 80.0
const BOSS_BAR_WIDTH: float = 240.0
const POPUP_SECONDS: float = 3.5
const POPUP_FADE: float = 0.25

var _popup_queue: Array[Dictionary] = []
var _current_popup: Dictionary = {}
var _popup_showing: bool = false
var _popup_tween: Tween = null
var _banner_token: int = 0
var _item_queue: Array[String] = []
var _item_busy: bool = false
var _item_label: Label = null

@onready var health_fill: ColorRect = $HealthBarBg/HealthFill
@onready var health_label: Label = $HealthLabel
@onready var timer_label: Label = $TimerLabel
@onready var achievement_panel: ColorRect = $AchievementPanel
@onready var achievement_title: Label = $AchievementPanel/Title
@onready var achievement_description: Label = $AchievementPanel/Description
@onready var boss_bar: Control = $BossBar
@onready var boss_name_label: Label = $BossBar/BossName
@onready var boss_fill: ColorRect = $BossBar/BossBarBg/BossFill
@onready var hint_label: Label = $HintLabel
@onready var banner: Label = $Banner


func _ready() -> void:
	achievement_panel.visible = false
	boss_bar.visible = false
	hint_label.visible = false
	banner.visible = false
	Game.achievement_unlocked.connect(_on_achievement_unlocked)
	Game.player_health_changed.connect(_on_player_health_changed)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	Game.boss_cleared.connect(_on_boss_cleared)
	Game.combat_changed.connect(_on_combat_changed)
	Game.hint_changed.connect(_on_hint_changed)
	Game.item_added.connect(_on_item_added)
	_build_item_label()
	_update_timer()


func _process(_delta: float) -> void:
	_update_timer()


func _build_item_label() -> void:
	_item_label = Label.new()
	_item_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	_item_label.anchor_left = 0.5
	_item_label.anchor_right = 0.5
	_item_label.offset_left = -200.0
	_item_label.offset_right = 200.0
	_item_label.offset_top = -86.0
	_item_label.offset_bottom = -70.0
	_item_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_label.add_theme_font_size_override("font_size", 10)
	_item_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_item_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_item_label.add_theme_constant_override("outline_size", 3)
	_item_label.modulate.a = 0.0
	add_child(_item_label)


func _on_item_added(item: Dictionary) -> void:
	_item_queue.append("+ %s" % str(item["name"]))
	_show_next_item()


func _show_next_item() -> void:
	if _item_busy or _item_queue.is_empty():
		return
	_item_busy = true
	_item_label.text = _item_queue.pop_front()
	var tween: Tween = create_tween()
	tween.tween_property(_item_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.8)
	tween.tween_property(_item_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_on_item_finished)


func _on_item_finished() -> void:
	_item_busy = false
	_show_next_item()


func show_banner(text: String, seconds: float = 2.0) -> void:
	_banner_token += 1
	var token: int = _banner_token
	banner.text = text
	banner.visible = true
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds).timeout
	if token == _banner_token:
		banner.visible = false


func hide_banner() -> void:
	_banner_token += 1
	banner.visible = false


func _update_timer() -> void:
	var total: int = ceili(Game.floor_time_left)
	var days: int = floori(total / 86400.0)
	var rest: int = total - days * 86400
	var hours: int = floori(rest / 3600.0)
	rest -= hours * 3600
	var minutes: int = floori(rest / 60.0)
	var seconds: int = rest - minutes * 60
	timer_label.text = "%dd %02d:%02d:%02d" % [days, hours, minutes, seconds]


func _on_player_health_changed(current: int, maximum: int) -> void:
	var ratio: float = 0.0
	if maximum > 0:
		ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	health_fill.size.x = HEALTH_BAR_WIDTH * ratio
	health_label.text = "HP %d/%d" % [current, maximum]


func _on_boss_health_changed(boss_name: String, current: int, maximum: int) -> void:
	var ratio: float = 0.0
	if maximum > 0:
		ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	boss_name_label.text = boss_name
	boss_fill.size.x = BOSS_BAR_WIDTH * ratio
	boss_bar.visible = true


func _on_boss_cleared() -> void:
	boss_bar.visible = false


func _on_hint_changed(text: String) -> void:
	hint_label.text = text
	hint_label.visible = not text.is_empty()


func _on_achievement_unlocked(title: String, description: String) -> void:
	_popup_queue.append({"title": title, "description": description})
	_show_next_popup()


func _on_combat_changed(active: bool) -> void:
	if not active:
		_show_next_popup()
		return
	if _popup_showing:
		if _popup_tween != null and _popup_tween.is_valid():
			_popup_tween.kill()
		_popup_queue.push_front(_current_popup)
		_popup_showing = false
		achievement_panel.visible = false


func _show_next_popup() -> void:
	if _popup_showing or _popup_queue.is_empty() or Game.in_combat:
		return
	_current_popup = _popup_queue.pop_front()
	_popup_showing = true
	achievement_title.text = "New Achievement! %s" % str(_current_popup["title"])
	achievement_description.text = str(_current_popup["description"])
	achievement_panel.modulate.a = 0.0
	achievement_panel.visible = true
	_popup_tween = create_tween()
	_popup_tween.tween_property(achievement_panel, "modulate:a", 1.0, POPUP_FADE)
	_popup_tween.tween_interval(POPUP_SECONDS)
	_popup_tween.tween_property(achievement_panel, "modulate:a", 0.0, POPUP_FADE)
	_popup_tween.tween_callback(_on_popup_finished)


func _on_popup_finished() -> void:
	_popup_showing = false
	achievement_panel.visible = false
	_show_next_popup()
