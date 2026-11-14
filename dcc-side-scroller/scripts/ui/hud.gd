extends CanvasLayer

const HEALTH_BAR_WIDTH: float = 80.0
const STAMINA_BAR_WIDTH: float = 80.0
const STAMINA_COLOR: Color = Color(0.95, 0.78, 0.2)
const STAMINA_DENIED_COLOR: Color = Color(0.9, 0.2, 0.2)
const MANA_BAR_WIDTH: float = 80.0
const MANA_COLOR: Color = Color(0.55, 0.35, 0.95)
const MANA_DENIED_COLOR: Color = Color(0.95, 0.9, 1.0)
const XP_BAR_WIDTH: float = 80.0
const XP_COLOR: Color = Color(0.45, 0.85, 0.55)
const BOSS_BAR_WIDTH: float = 240.0
const TOAST_WIDTH: float = 220.0
const TOAST_MAX: int = 3
const TOAST_MIN_SECONDS: float = 3.0
const TOAST_PER_CHAR: float = 0.05
const TOAST_FADE_IN: float = 0.2
const TOAST_FADE_OUT: float = 0.5
const TOAST_GOLD: Color = Color(1.0, 0.82, 0.25)

var _toast_queue: Array[Dictionary] = []
var _toast_box: VBoxContainer = null
var _toast_count: int = 0
var _banner_token: int = 0
var _announce_queue: Array[Dictionary] = []
var _announce_busy: bool = false
var _survivor_label: Label = null
var _item_queue: Array[String] = []
var _item_busy: bool = false
var _item_label: Label = null
var _god_label: Label = null
var _countdown_label: Label = null
var _flash_rect: ColorRect = null
var _mana_bg: ColorRect = null
var _mana_fill: ColorRect = null
var _xp_bg: ColorRect = null
var _xp_fill: ColorRect = null
var _level_label: Label = null
var _charm_label: Label = null

@onready var health_fill: ColorRect = $HealthBarBg/HealthFill
@onready var stamina_fill: ColorRect = $StaminaBarBg/StaminaFill
@onready var health_label: Label = $HealthLabel
@onready var timer_label: Label = $TimerLabel
@onready var boss_bar: Control = $BossBar
@onready var boss_name_label: Label = $BossBar/BossName
@onready var boss_fill: ColorRect = $BossBar/BossBarBg/BossFill
@onready var hint_label: Label = $HintLabel
@onready var banner: Label = $Banner


func _ready() -> void:
	boss_bar.visible = false
	hint_label.visible = false
	banner.visible = false
	Game.achievement_unlocked.connect(_on_achievement_unlocked)
	Game.player_health_changed.connect(_on_player_health_changed)
	Game.player_stamina_changed.connect(_on_player_stamina_changed)
	Game.stamina_denied.connect(_on_stamina_denied)
	Game.player_mana_changed.connect(_on_player_mana_changed)
	Game.mana_denied.connect(_on_mana_denied)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	Game.boss_cleared.connect(_on_boss_cleared)
	Game.hint_changed.connect(_on_hint_changed)
	Game.item_added.connect(_on_item_added)
	_build_item_label()
	_build_god_label()
	_build_mana_bar()
	_build_xp_bar()
	_build_charm_label()
	_build_countdown()
	_build_survivors()
	_build_toasts()
	SystemVoice.announced_ex.connect(_on_announced)
	_update_timer()


func _process(_delta: float) -> void:
	_update_timer()
	_update_charm_label()


func _build_charm_label() -> void:
	_charm_label = Label.new()
	_charm_label.name = "CharmLabel"
	_charm_label.position = Vector2(8.0, 33.0)
	_charm_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charm_label.add_theme_font_size_override("font_size", 12)
	_charm_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.75))
	_charm_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_charm_label.add_theme_constant_override("outline_size", 3)
	_charm_label.visible = false
	add_child(_charm_label)


## Shows how many goblins are currently charmed and whether the Goblin Pass is held.
func _update_charm_label() -> void:
	var charmed: int = get_tree().get_nodes_in_group("charmed").size()
	var parts: PackedStringArray = PackedStringArray()
	if charmed > 0:
		parts.append("Charmed: %d" % charmed)
	if Inventory.has_item("goblin_pass"):
		parts.append("Goblin Pass")
	_charm_label.text = "  ".join(parts)
	_charm_label.visible = not parts.is_empty()


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


func _build_survivors() -> void:
	_survivor_label = Label.new()
	_survivor_label.theme_type_variation = &"HudLabel"
	_survivor_label.name = "SurvivorLabel"
	_survivor_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_survivor_label.anchor_left = 1.0
	_survivor_label.anchor_right = 1.0
	_survivor_label.offset_left = -200.0
	_survivor_label.offset_right = -8.0
	_survivor_label.offset_top = 19.0
	_survivor_label.offset_bottom = 31.0
	_survivor_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_survivor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_survivor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_survivor_label.add_theme_font_size_override("font_size", 8)
	_survivor_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.5))
	_survivor_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_survivor_label.add_theme_constant_override("outline_size", 3)
	add_child(_survivor_label)
	SystemVoice.survivors_changed.connect(_refresh_survivors)
	SystemVoice.survivors_visibility_changed.connect(func(_shown: bool) -> void: _refresh_survivors(SystemVoice.survivors))
	_refresh_survivors(SystemVoice.survivors)


func _refresh_survivors(count: int) -> void:
	_survivor_label.visible = SystemVoice.survivors_visible and SystemVoice.floor_active
	_survivor_label.text = "Survivors: %s" % SystemVoice.format_count(count)


func _on_announced(title: String, body: String, seconds: float, major: bool) -> void:
	if not major:
		show_toast(title, body, seconds)
		return
	_announce_queue.append({"title": title, "body": body, "seconds": seconds})
	_show_next_announcement()


func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.name = "Toasts"
	_toast_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toast_box.anchor_left = 1.0
	_toast_box.anchor_right = 1.0
	_toast_box.offset_left = -TOAST_WIDTH - 8.0
	_toast_box.offset_right = -8.0
	_toast_box.offset_top = 36.0
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 3)
	add_child(_toast_box)


## A small notification in the top-right corner (level-ups, achievements, System notices). Up to TOAST_MAX show
## at once; the rest queue. It stays up long enough to read, scaled by its length (seconds is a minimum).
func show_toast(title: String, body: String = "", seconds: float = 0.0) -> void:
	_toast_queue.append({"title": title, "body": body, "seconds": seconds})
	_pump_toasts()


func _pump_toasts() -> void:
	while _toast_count < TOAST_MAX and not _toast_queue.is_empty():
		_spawn_toast(_toast_queue.pop_front())


func _spawn_toast(data: Dictionary) -> void:
	var title: String = str(data["title"])
	var body: String = str(data["body"])
	_toast_count += 1
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(TOAST_WIDTH, 0.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.82)
	style.border_color = TOAST_GOLD
	style.border_width_left = 2
	style.content_margin_left = 6.0
	style.content_margin_right = 4.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	panel.add_child(column)
	var heading: Label = Label.new()
	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_font_size_override("font_size", 10)
	heading.add_theme_color_override("font_color", TOAST_GOLD)
	column.add_child(heading)
	if not body.is_empty():
		var text: Label = Label.new()
		text.text = body
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_font_size_override("font_size", 10)
		text.add_theme_constant_override("line_spacing", -1)
		column.add_child(text)
	panel.modulate.a = 0.0
	_toast_box.add_child(panel)
	var hold: float = maxf(float(data["seconds"]), TOAST_MIN_SECONDS) + TOAST_PER_CHAR * float(title.length() + body.length())
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, TOAST_FADE_IN)
	tween.tween_interval(hold)
	tween.tween_property(panel, "modulate:a", 0.0, TOAST_FADE_OUT)
	tween.tween_callback(_on_toast_finished.bind(panel))


func _on_toast_finished(panel: Control) -> void:
	panel.queue_free()
	_toast_count = maxi(_toast_count - 1, 0)
	_pump_toasts()


func _show_next_announcement() -> void:
	if _announce_busy or _announce_queue.is_empty():
		return
	_announce_busy = true
	var next: Dictionary = _announce_queue.pop_front()
	show_system_message(str(next["title"]), str(next["body"]), float(next["seconds"]))
	await get_tree().create_timer(float(next["seconds"]) + 0.3).timeout
	_announce_busy = false
	_show_next_announcement()


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
	_god_label.add_theme_font_size_override("font_size", 12)
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
	_item_label.add_theme_font_size_override("font_size", 12)
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
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if not body.is_empty():
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


func _build_mana_bar() -> void:
	_mana_bg = ColorRect.new()
	_mana_bg.name = "ManaBarBg"
	_mana_bg.color = Color(0.08, 0.06, 0.08, 0.9)
	_mana_bg.position = Vector2(8.0, 22.0)
	_mana_bg.size = Vector2(MANA_BAR_WIDTH, 4.0)
	_mana_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mana_bg.visible = false
	add_child(_mana_bg)
	_mana_fill = ColorRect.new()
	_mana_fill.name = "ManaFill"
	_mana_fill.color = MANA_COLOR
	_mana_fill.size = Vector2(MANA_BAR_WIDTH, 4.0)
	_mana_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mana_bg.add_child(_mana_fill)


func _build_xp_bar() -> void:
	_xp_bg = ColorRect.new()
	_xp_bg.name = "XpBarBg"
	_xp_bg.color = Color(0.08, 0.06, 0.08, 0.9)
	_xp_bg.position = Vector2(8.0, 28.0)
	_xp_bg.size = Vector2(XP_BAR_WIDTH, 3.0)
	_xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_xp_bg)
	_xp_fill = ColorRect.new()
	_xp_fill.name = "XpFill"
	_xp_fill.color = XP_COLOR
	_xp_fill.size = Vector2(0.0, 3.0)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bg.add_child(_xp_fill)
	_level_label = Label.new()
	_level_label.theme_type_variation = &"HudLabel"
	_level_label.name = "LevelLabel"
	_level_label.position = Vector2(92.0, 24.0)
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_label.add_theme_font_size_override("font_size", 8)
	_level_label.add_theme_color_override("font_color", XP_COLOR)
	_level_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_level_label.add_theme_constant_override("outline_size", 3)
	add_child(_level_label)
	PlayerStats.stats_changed.connect(_refresh_xp)
	_refresh_xp()


func _refresh_xp() -> void:
	var shown: bool = PlayerStats.active
	_xp_bg.visible = shown
	_level_label.visible = shown
	if not shown:
		return
	var need: int = PlayerStats.xp_to_next()
	_xp_fill.size.x = XP_BAR_WIDTH * clampf(float(PlayerStats.xp) / float(maxi(need, 1)), 0.0, 1.0)
	_level_label.text = "LV %d  %d/%d" % [PlayerStats.character_level, PlayerStats.xp, need]




func _on_player_mana_changed(current: int, maximum: int) -> void:
	if maximum <= 0:
		return
	_mana_bg.visible = true
	_mana_fill.size.x = MANA_BAR_WIDTH * clampf(float(current) / float(maximum), 0.0, 1.0)


func _on_mana_denied() -> void:
	_mana_fill.color = MANA_DENIED_COLOR
	var tween: Tween = create_tween()
	tween.tween_property(_mana_fill, "color", MANA_COLOR, 0.25)


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
	show_toast("Achievement: %s" % title, description)
