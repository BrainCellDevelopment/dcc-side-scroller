extends CanvasLayer

const SECTIONS: PackedStringArray = ["surface", "stairs", "hall", "tunnels", "tunnels2", "tunnels3", "arena", "chase", "guildhall"]

var _panel: PanelContainer
var _log: RichTextLabel
var _line: LineEdit
var _history: PackedStringArray = PackedStringArray()
var _history_index: int = 0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.custom_minimum_size = Vector2(0.0, 110.0)
	var box: VBoxContainer = VBoxContainer.new()
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.bbcode_enabled = false
	_log.add_theme_font_size_override("normal_font_size", 8)
	_line = LineEdit.new()
	_line.placeholder_text = "dev console: help"
	_line.add_theme_font_size_override("font_size", 8)
	_line.text_submitted.connect(_on_submitted)
	box.add_child(_log)
	box.add_child(_line)
	_panel.add_child(box)
	add_child(_panel)
	_panel.visible = false


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_QUOTELEFT:
		_toggle()
		get_viewport().set_input_as_handled()
	elif _panel.visible and key.keycode == KEY_ESCAPE:
		_toggle()
		get_viewport().set_input_as_handled()
	elif _panel.visible and key.keycode == KEY_UP and not _history.is_empty():
		_history_index = maxi(_history_index - 1, 0)
		_line.text = _history[_history_index]
		_line.caret_column = _line.text.length()
		get_viewport().set_input_as_handled()
	elif _panel.visible and key.keycode == KEY_DOWN and not _history.is_empty():
		_history_index = mini(_history_index + 1, _history.size())
		_line.text = _history[_history_index] if _history_index < _history.size() else ""
		_line.caret_column = _line.text.length()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_panel.visible = not _panel.visible
	get_tree().paused = _panel.visible
	if _panel.visible:
		_line.clear()
		_line.grab_focus()
	else:
		_line.release_focus()


func _print(text: String) -> void:
	_log.append_text(text + "\n")


func _on_submitted(text: String) -> void:
	_line.clear()
	var line: String = text.strip_edges()
	if line.is_empty():
		return
	_history.append(line)
	_history_index = _history.size()
	_print("> " + line)
	var parts: PackedStringArray = line.split(" ", false)
	var command: String = parts[0].to_lower()
	var argument: String = parts[1].to_lower() if parts.size() > 1 else ""
	match command:
		"help":
			_print("goto <section>  list  heal  skins  skin <id>  unlockskin <id>  resetprofile  help  (` or esc closes)")
		"list":
			_print("sections: " + ", ".join(SECTIONS) + ", cp<N>")
		"heal":
			_heal()
		"goto":
			_goto(argument)
		"skins":
			_print("unlocked: " + ", ".join(Game.unlocked_skins) + " | selected: " + Game.selected_skin + " | all: " + ", ".join(Game.SKINS.keys()) + " | tutorial death streak: " + str(Game.tutorial_death_streak))
		"skin":
			_skin(argument)
		"unlockskin":
			if Game.unlock_skin(argument):
				_print("unlocked " + argument)
			else:
				_print("unknown or already unlocked: " + argument)
		"resetprofile":
			Game.reset_profile()
			_print("profile reset")
		_:
			_print("unknown command: " + command)


func _heal() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		_print("no player")
		return
	player.set("health", player.get("max_health"))
	Game.report_player_health(int(player.get("health")), int(player.get("max_health")))
	_print("healed")


func _skin(skin_id: String) -> void:
	if not Game.select_skin(skin_id):
		_print("skin not available: " + skin_id)
		return
	_print("equipped " + skin_id)
	_panel.visible = false
	_line.release_focus()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _goto(target: String) -> void:
	if target.is_empty():
		_print("usage: goto <section>")
		return
	var level: Node = get_tree().current_scene
	if level == null or not level.has_method("dev_goto"):
		_print("this scene has no dev_goto")
		return
	if not bool(level.call("dev_goto", target)):
		_print("unknown target: " + target)
		return
	_print("going to " + target)
	_panel.visible = false
	_line.release_focus()
	get_tree().paused = false
	get_tree().reload_current_scene()
