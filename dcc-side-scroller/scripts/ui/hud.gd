extends CanvasLayer

const HEALTH_BAR_WIDTH: float = 80.0
const STAMINA_BAR_WIDTH: float = 80.0
const STAMINA_COLOR: Color = Color(0.95, 0.78, 0.2)
const STAMINA_DENIED_COLOR: Color = Color(0.9, 0.2, 0.2)
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
var _god_label: Label = null
var _countdown_label: Label = null
var _flash_rect: ColorRect = null

@onready var health_fill: ColorRect = $HealthBarBg/HealthFill
@onready var stamina_fill: ColorRect = $StaminaBarBg/StaminaFill
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
	Game.player_stamina_changed.connect(_on_player_stamina_changed)
	Game.stamina_denied.connect(_on_stamina_denied)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	Game.boss_cleared.connect(_on_boss_cleared)
	Game.combat_changed.connect(_on_combat_changed)
	Game.hint_changed.connect(_on_hint_changed)
	Game.item_added.connect(_on_item_added)
	_build_item_label()
	_build_god_label()
	_build_countdown()
	_update_timer()


func _process(_delta: float) -> void:
	_update_timer()


func _build_countdown() -> void:
	_countdown_label = Label.new()
	_countdown_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_countdown_label.anchor_left = 0.5
	_countdown_label.anchor_right = 0.5
	_countdown_label.offset_left = -120.0
	_countdown_label.offset_right = 120.0
	_countdown_label.offset_top = 22.0
	_countdown_label.offset_bottom = 70.0
	_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 40)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	_countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_countdown_label.add_theme_constant_override("outline_size", 8)
	_countdown_label.visible = false
	add_child(_countdown_label)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color.WHITE
	_flash_rect.modulate.a = 0.0
	add_child(_flash_rect)


func show_countdown(seconds: float) -> void:
	_countdown_label.visible = true
	_countdown_label.text = "%.1f" % maxf(seconds, 0.0)
	var pulse: float = 0.5 + 0.5 * sin(seconds * lerpf(6.0, 20.0, clampf(1.0 - seconds / 15.0, 0.0, 1.0)))
	_countdown_label.modulate = Color.WHITE.lerp(Color(1.0, 0.7, 0.6), pulse)
	_countdown_label.scale = Vector2.ONE * (1.0 + 0.12 * pulse)
	_countdown_label.pivot_offset = _countdown_label.size * 0.5


func hide_countdown() -> void:
	_countdown_label.visible = false


func flash_screen() -> void:
	_flash_rect.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(0.12)
	tween.tween_property(_flash_rect, "modulate:a", 0.0, 0.7)


func _build_god_label() -> void:
	_god_label = Label.new()
	_god_label.text = "GOD MODE"
	_god_label.position = Vector2(92.0, 14.0)
	_god_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_god_label.add_theme_font_size_override("font_size", 8)
	_god_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_god_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_god_label.add_theme_constant_override("outline_size", 3)
	_god_label.visible = Game.god_mode
	add_child(_god_label)
	Game.god_mode_changed.connect(_on_god_mode_changed)


func _on_god_mode_changed(active: bool) -> void:
	_god_label.visible = active


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


func show_system_message(title: String, body: String, seconds: float = 3.0) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size = Vector2(520.0, 0.0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	var heading: Label = Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	heading.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	heading.add_theme_constant_override("outline_size", 8)
	var text: Label = Label.new()
	text.text = body
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	text.add_theme_constant_override("outline_size", 5)
	box.add_child(heading)
	box.add_child(text)
	box.modulate.a = 0.0
	add_child(box)
	box.pivot_offset = box.custom_minimum_size * 0.5
	box.scale = Vector2.ONE * 1.4
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(box, "modulate:a", 1.0, 0.2)
	tween.tween_property(box, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(maxf(seconds - 0.7, 0.1))
	tween.chain().tween_property(box, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(box.queue_free)


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


func _on_player_stamina_changed(current: int, maximum: int) -> void:
	var ratio: float = 0.0
	if maximum > 0:
		ratio = clampf(float(current) / float(maximum), 0.0, 1.0)
	stamina_fill.size.x = STAMINA_BAR_WIDTH * ratio


func _on_stamina_denied() -> void:
	stamina_fill.color = STAMINA_DENIED_COLOR
	var tween: Tween = create_tween()
	tween.tween_property(stamina_fill, "color", STAMINA_COLOR, 0.25)


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
