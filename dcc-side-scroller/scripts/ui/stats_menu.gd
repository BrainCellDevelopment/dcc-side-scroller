extends CanvasLayer

const LABELS: Dictionary = {
	"strength": "Strength",
	"intelligence": "Intelligence",
	"constitution": "Constitution",
	"dexterity": "Dexterity",
	"charisma": "Charisma",
}

var _panel: PanelContainer
var _text: RichTextLabel
var _selected: int = 0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(260.0, 0.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.95)
	style.border_color = Color(0.85, 0.7, 0.3)
	style.set_border_width_all(1)
	style.set_content_margin_all(10.0)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.add_theme_font_size_override("normal_font_size", 10)
	_text.add_theme_font_size_override("bold_font_size", 10)
	_panel.add_child(_text)
	add_child(_panel)
	_panel.visible = false
	PlayerStats.stats_changed.connect(_refresh)
	PlayerStats.mana_changed.connect(func(_c: int, _m: int) -> void: _refresh())


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_TAB:
		if _panel.visible:
			_close()
		elif PlayerStats.active and not DevConsole.visible_panel():
			_open()
		get_viewport().set_input_as_handled()
	elif _panel.visible:
		match key.keycode:
			KEY_ESCAPE:
				_close()
			KEY_UP, KEY_W:
				_selected = posmod(_selected - 1, PlayerStats.STAT_NAMES.size())
				_refresh()
			KEY_DOWN, KEY_S:
				_selected = posmod(_selected + 1, PlayerStats.STAT_NAMES.size())
				_refresh()
			KEY_ENTER, KEY_KP_ENTER, KEY_E:
				PlayerStats.spend_point(PlayerStats.STAT_NAMES[_selected])
		get_viewport().set_input_as_handled()


func _open() -> void:
	_panel.visible = true
	get_tree().paused = true
	_refresh()


func _close() -> void:
	_panel.visible = false
	get_tree().paused = false


func _refresh() -> void:
	if not _panel.visible:
		return
	var t: String = "[b]CRAWLER STATS[/b]   Floor %d   Level %d\n" % [PlayerStats.floor_number, PlayerStats.character_level]
	t += "XP %d / %d\n\n" % [PlayerStats.xp, PlayerStats.XP_PER_LEVEL]
	t += "[table=3]"
	for i: int in PlayerStats.STAT_NAMES.size():
		var stat_name: String = PlayerStats.STAT_NAMES[i]
		var cursor: String = ">" if i == _selected else ""
		t += "[cell]%s [/cell][cell]%s    [/cell][cell]%d[/cell]" % [cursor, LABELS[stat_name], PlayerStats.get_stat(stat_name)]
	t += "[/table]\n"
	t += "\nHealth max %d   Mana %d/%d   Melee +%d\n" % [PlayerStats.max_health(), PlayerStats.mana, PlayerStats.max_mana(), PlayerStats.damage_bonus()]
	if PlayerStats.class_chosen:
		t += "Unspent points: %d  (Up/Down, Enter to spend)\n" % PlayerStats.unspent_points
	else:
		t += "Unspent points: %d  (locked until floor %d)\n" % [PlayerStats.unspent_points, PlayerStats.CLASS_SELECT_FLOOR]
	t += "\nTab or Esc closes"
	_text.text = t
