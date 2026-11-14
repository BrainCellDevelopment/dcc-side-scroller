extends CanvasLayer

const LABELS: Dictionary = {
	"strength": "Strength",
	"intelligence": "Intelligence",
	"constitution": "Constitution",
	"dexterity": "Dexterity",
	"charisma": "Charisma",
}
const TIER_COLORS: Dictionary = {
	"Bronze": Color(0.8, 0.5, 0.2),
	"Silver": Color(0.75, 0.78, 0.82),
	"Gold": Color(1.0, 0.84, 0.2),
	"Platinum": Color(0.5, 0.9, 0.95),
	"Legendary": Color(0.8, 0.4, 1.0),
}
const GOLD: Color = Color(0.85, 0.7, 0.3)
const COLS: int = 6
const ROWS: int = 4
const SIZE_FRACTION: float = 0.88
const HEIGHT_FRACTION: float = 0.78
const STAT_COLS: int = 3
const GRID_FRACTION: float = 0.70
const GAP: float = 3.0
const DEFAULT_SLOTS: PackedStringArray = ["head", "left_hand", "right_hand", "left_foot", "right_foot"]
const SLOT_CAPTIONS: Dictionary = {
	"head": "HEAD",
	"left_hand": "L.HAND",
	"right_hand": "R.HAND",
	"left_foot": "L.FOOT",
	"right_foot": "R.FOOT",
}
const DOLL_GRID: Dictionary = {
	"head": Vector2i(0, 0),
	"left_hand": Vector2i(0, 1),
	"right_hand": Vector2i(1, 1),
	"left_foot": Vector2i(0, 2),
	"right_foot": Vector2i(1, 2),
}
const DOLL_TEXTURE_PATH: String = "res://assets/ui/carl_doll.png"
const FIGURE_COLOR: Color = Color(0.78, 0.84, 0.92)
const EMPTY_BORDER: Color = Color(0.25, 0.27, 0.35)

enum Focus { INVENTORY, DOLL, STATS }

var _panel: PanelContainer
var _inv_region: VBoxContainer
var _inv_title: Label
var _body: HBoxContainer
var _grid: GridContainer
var _cells: Array[PanelContainer] = []
var _doll: Control
var _doll_tex: Texture2D
var _doll_boxes: Array[PanelContainer] = []
var _detail: Label
var _stats_text: RichTextLabel
var _stats_region: VBoxContainer
var _focus: Focus = Focus.INVENTORY
var _selected_slot: int = 0
var _selected_doll: int = 0
var _selected_stat: int = 0
var _cell_size: Vector2 = Vector2(60, 36)
var _box_size: Vector2 = Vector2(48, 30)


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.88)
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_content_margin_all(8.0)
	_panel.add_theme_stylebox_override("panel", style)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	_panel.add_child(vbox)

	_inv_region = VBoxContainer.new()
	_inv_region.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inv_region.size_flags_stretch_ratio = 4.0
	_inv_region.add_theme_constant_override("separation", 4)
	vbox.add_child(_inv_region)
	_inv_title = _make_label("INVENTORY", 10, GOLD)
	_inv_region.add_child(_inv_title)
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_inv_region.add_child(_body)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", int(GAP))
	_grid.add_theme_constant_override("v_separation", int(GAP))
	_body.add_child(_grid)
	for i: int in COLS * ROWS:
		var cell: PanelContainer = PanelContainer.new()
		cell.clip_contents = true
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.name = "Box"
		cell.add_child(box)
		var label: Label = _make_label("", 8, Color.WHITE)
		label.name = "Name"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(label)
		var count: Label = _make_label("", 7, Color.WHITE)
		count.name = "Count"
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		box.add_child(count)
		_grid.add_child(cell)
		_cells.append(cell)

	_doll = Control.new()
	_doll.draw.connect(_draw_doll)
	_doll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_doll_tex = load(DOLL_TEXTURE_PATH) as Texture2D
	_body.add_child(_doll)
	for i: int in DEFAULT_SLOTS.size():
		var eq: PanelContainer = PanelContainer.new()
		eq.clip_contents = true
		var eq_box: VBoxContainer = VBoxContainer.new()
		eq_box.add_theme_constant_override("separation", 0)
		eq_box.name = "Box"
		eq.add_child(eq_box)
		var cap: Label = _make_label(SLOT_CAPTIONS[DEFAULT_SLOTS[i]], 6, Color(0.6, 0.62, 0.7))
		cap.name = "Caption"
		eq_box.add_child(cap)
		var nm: Label = _make_label("", 7, Color.WHITE)
		nm.name = "Name"
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
		eq_box.add_child(nm)
		_doll.add_child(eq)
		_doll_boxes.append(eq)

	_detail = _make_label(" ", 8, Color(0.8, 0.82, 0.9))
	_detail.clip_text = true
	_detail.custom_minimum_size.y = 12.0
	_inv_region.add_child(_detail)

	_stats_region = VBoxContainer.new()
	_stats_region.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_region.size_flags_stretch_ratio = 2.0
	_stats_region.add_theme_constant_override("separation", 2)
	vbox.add_child(_stats_region)
	var sep: HSeparator = HSeparator.new()
	_stats_region.add_child(sep)
	_stats_text = RichTextLabel.new()
	_stats_text.bbcode_enabled = true
	_stats_text.scroll_active = false
	_stats_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_text.add_theme_font_size_override("normal_font_size", 8)
	_stats_text.add_theme_font_size_override("bold_font_size", 8)
	_stats_region.add_child(_stats_text)

	add_child(_panel)
	_panel.visible = false
	get_viewport().size_changed.connect(_layout)
	_layout()
	PlayerStats.stats_changed.connect(_refresh)
	PlayerStats.mana_changed.connect(func(_c: int, _m: int) -> void: _refresh())
	var inv: Node = _inventory()
	if inv != null and inv.has_signal("changed"):
		inv.connect("changed", _refresh)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _inventory() -> Node:
	return get_node_or_null("/root/Inventory")


func _equip_slots() -> PackedStringArray:
	var inv: Node = _inventory()
	if inv != null and "EQUIP_SLOTS" in inv:
		return inv.get("EQUIP_SLOTS")
	return DEFAULT_SLOTS


func _slot(i: int) -> Dictionary:
	var inv: Node = _inventory()
	if inv == null or not ("slots" in inv):
		return {}
	var slots: Array = inv.get("slots")
	if i < slots.size():
		return slots[i]
	return {}


func _equipped(slot_name: String) -> Dictionary:
	var inv: Node = _inventory()
	if inv == null or not ("equipped" in inv):
		return {}
	var eq: Dictionary = inv.get("equipped")
	var item: Variant = eq.get(slot_name, {})
	return item if item is Dictionary else {}


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var size: Vector2 = Vector2(vp.x * SIZE_FRACTION, vp.y * HEIGHT_FRACTION).floor()
	_panel.size = size
	_panel.position = Vector2(floorf((vp.x - size.x) * 0.5), floorf(vp.y * 0.02))
	var inner_w: float = size.x - 16.0
	var region_h: float = (size.y - 16.0) * 4.0 / 6.0
	var title_h: float = _inv_title.get_combined_minimum_size().y
	var body_h: float = floorf(region_h - title_h - 12.0 - 8.0)
	var grid_w: float = floorf(inner_w * GRID_FRACTION)
	var cell_w: float = floorf((grid_w - GAP * (COLS - 1)) / COLS)
	var cell_h: float = floorf((body_h - GAP * (ROWS - 1)) / ROWS)
	_cell_size = Vector2(cell_w, cell_h)
	for c: PanelContainer in _cells:
		c.custom_minimum_size = _cell_size
	var doll_w: float = inner_w - (cell_w * COLS + GAP * (COLS - 1)) - 6.0
	_doll.custom_minimum_size = Vector2(doll_w, body_h)
	_doll.size = Vector2(doll_w, body_h)
	_layout_doll(Vector2(doll_w, body_h))
	_doll.queue_redraw()


func _doll_center(sz: Vector2) -> float:
	return roundf(sz.x * 0.5)


func _layout_doll(sz: Vector2) -> void:
	var bw: float = floorf(sz.x * 0.32)
	var bh: float = clampf(floorf(sz.y * 0.2), 24.0, 34.0)
	_box_size = Vector2(bw, bh)
	var rows_y: Array[float] = [0.0, roundf(sz.y * 0.6), sz.y - bh]
	var slots: PackedStringArray = _equip_slots()
	for i: int in _doll_boxes.size():
		var g: Vector2i = DOLL_GRID.get(slots[i] if i < slots.size() else DEFAULT_SLOTS[i], Vector2i(0, 0))
		var x: float = 0.0 if g.x == 0 else sz.x - bw
		var y: float = rows_y[g.y]
		_doll_boxes[i].position = Vector2(x, y)
		_doll_boxes[i].custom_minimum_size = _box_size
		_doll_boxes[i].size = _box_size


func _draw_doll() -> void:
	var sz: Vector2 = _doll.size
	if _doll_tex != null:
		var ts: Vector2 = _doll_tex.get_size()
		var k: float = minf(sz.x / ts.x, sz.y / ts.y)
		var ds: Vector2 = (ts * k).floor()
		_doll.draw_texture_rect(_doll_tex, Rect2(((sz - ds) * 0.5).floor(), ds), false)
		return
	var cx: float = _doll_center(sz)
	var r: float = clampf(sz.y * 0.08, 6.0, 14.0)
	var head_c: Vector2 = Vector2(cx, r + 2.0)
	var neck: Vector2 = Vector2(cx, head_c.y + r)
	var hip: Vector2 = Vector2(cx, sz.y * 0.58)
	var shoulder_y: float = neck.y + sz.y * 0.07
	var reach: float = sz.x * 0.17
	var hand_y: float = sz.y * 0.5
	var foot_y: float = sz.y - _box_size.y * 0.45
	var foot_dx: float = sz.x * 0.09
	var col: Color = FIGURE_COLOR
	_doll.draw_arc(head_c, r, 0.0, TAU, 20, col, 2.0, false)
	_doll.draw_line(neck, hip, col, 2.0, false)
	_doll.draw_line(Vector2(cx, shoulder_y), Vector2(cx - reach, hand_y), col, 2.0, false)
	_doll.draw_line(Vector2(cx, shoulder_y), Vector2(cx + reach, hand_y), col, 2.0, false)
	_doll.draw_line(hip, Vector2(cx - foot_dx, foot_y), col, 2.0, false)
	_doll.draw_line(hip, Vector2(cx + foot_dx, foot_y), col, 2.0, false)
	for hx: float in [cx - reach, cx + reach]:
		_doll.draw_rect(Rect2(hx - 1.0, hand_y - 1.0, 3.0, 3.0), col)
	for fx: float in [cx - foot_dx, cx + foot_dx]:
		_doll.draw_rect(Rect2(fx - 2.0, foot_y - 1.0, 5.0, 3.0), col)


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
			KEY_Q:
				_focus = ((_focus as int) + 1) % Focus.size() as Focus
				_refresh()
			KEY_UP, KEY_W:
				_move(0, -1)
			KEY_DOWN, KEY_S:
				_move(0, 1)
			KEY_LEFT, KEY_A:
				_move(-1, 0)
			KEY_RIGHT, KEY_D:
				_move(1, 0)
			KEY_ENTER, KEY_KP_ENTER, KEY_E:
				_activate()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				_assign_hotbar(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()


func _selected_item() -> Dictionary:
	if _focus == Focus.INVENTORY:
		return _slot(_selected_slot)
	if _focus == Focus.DOLL:
		return _equipped(_equip_slots()[_selected_doll])
	return {}


func _assign_hotbar(index: int) -> void:
	var item: Dictionary = _selected_item()
	if item.is_empty():
		Inventory.clear_hotbar(index)
	else:
		Inventory.assign_hotbar(index, str(item["id"]))
	_refresh()


func _activate() -> void:
	var inv: Node = _inventory()
	match _focus:
		Focus.STATS:
			PlayerStats.spend_point(PlayerStats.STAT_NAMES[_selected_stat])
		Focus.INVENTORY:
			if inv != null and inv.has_method("equip_from"):
				inv.call("equip_from", _selected_slot)
		Focus.DOLL:
			if inv != null and inv.has_method("unequip"):
				inv.call("unequip", _equip_slots()[_selected_doll])
	_refresh()


func _move(dx: int, dy: int) -> void:
	match _focus:
		Focus.INVENTORY:
			var n: int = _cells.size()
			var col: int = posmod(_selected_slot % COLS + dx, COLS)
			var row: int = posmod(_selected_slot / COLS + dy, ceili(float(n) / COLS))
			_selected_slot = mini(row * COLS + col, n - 1)
		Focus.DOLL:
			_move_doll(dx, dy)
		Focus.STATS:
			var n: int = PlayerStats.STAT_NAMES.size()
			if dx != 0:
				_selected_stat = posmod(_selected_stat + dx, n)
			elif dy != 0:
				var target: int = _selected_stat + STAT_COLS * dy
				if target < 0 or target >= n:
					target = _selected_stat - STAT_COLS * dy if (_selected_stat - STAT_COLS * dy) >= 0 and (_selected_stat - STAT_COLS * dy) < n else _selected_stat
				_selected_stat = target
	_refresh()


func _move_doll(dx: int, dy: int) -> void:
	var slots: PackedStringArray = _equip_slots()
	var cur: Vector2i = DOLL_GRID.get(slots[_selected_doll], Vector2i(0, 0))
	var best: int = _selected_doll
	var best_score: int = 1000
	for i: int in slots.size():
		if i == _selected_doll:
			continue
		var g: Vector2i = DOLL_GRID.get(slots[i], Vector2i(0, 0))
		var score: int = 1000
		if dx != 0 and g.x == cur.x + dx:
			score = absi(g.y - cur.y)
		elif dy != 0 and g.x == cur.x and signi(g.y - cur.y) == dy:
			score = absi(g.y - cur.y)
		if score < best_score:
			best_score = score
			best = i
	if best_score == 1000 and dy != 0:
		for i: int in slots.size():
			var g: Vector2i = DOLL_GRID.get(slots[i], Vector2i(0, 0))
			if i != _selected_doll and g.x == cur.x and (best_score == 1000 or (g.y < DOLL_GRID.get(slots[best], Vector2i(0, 0)).y) == (dy > 0)):
				best = i
				best_score = 0
	_selected_doll = best


func _process(_delta: float) -> void:
	if _panel.visible and not PlayerStats.active:
		_close()


func _open() -> void:
	_panel.visible = true
	Game.menu_open = true
	_layout()
	_refresh()


func _close() -> void:
	_panel.visible = false
	Game.menu_open = false


func _cell_style(border: Color, selected: bool, filled: bool) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.15, 0.22) if selected else (Color(0.1, 0.11, 0.17) if filled else Color(0.07, 0.08, 0.12))
	s.border_color = border
	s.set_border_width_all(2 if selected else 1)
	s.set_content_margin_all(2.0)
	return s


func _fit_name(label: Label, text: String, avail: Vector2, max_size: int) -> void:
	var font: Font = label.get_theme_font("font")
	var chosen: int = 6
	for fs: int in range(max_size, 5, -1):
		var sz: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, avail.x, fs, -1, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_MANDATORY)
		if sz.y + 3.0 <= avail.y:
			chosen = fs
			break
	label.add_theme_font_size_override("font_size", chosen)
	label.text = text


func _tier_color(item: Dictionary) -> Color:
	return TIER_COLORS.get(str(item.get("tier", "")), Color(0.5, 0.5, 0.5))


func _refresh() -> void:
	if not _panel.visible:
		return
	_inv_title.add_theme_color_override("font_color", GOLD if _focus == Focus.INVENTORY else Color(0.5, 0.45, 0.3))
	var name_avail: Vector2 = Vector2(_cell_size.x - 6.0, _cell_size.y - 4.0 - 9.0)
	for i: int in _cells.size():
		var item: Dictionary = _slot(i)
		var filled: bool = not item.is_empty()
		var selected: bool = _focus == Focus.INVENTORY and i == _selected_slot
		var border: Color = EMPTY_BORDER
		var name_label: Label = _cells[i].get_node("Box/Name") as Label
		var count_label: Label = _cells[i].get_node("Box/Count") as Label
		if filled:
			border = _tier_color(item)
			_fit_name(name_label, str(item.get("name", "?")), name_avail, 8)
			var n: int = int(item.get("count", 1))
			count_label.text = "x%d" % n if n > 1 else " "
		else:
			name_label.text = ""
			count_label.text = " "
		if selected:
			border = Color.WHITE if not filled else border.lightened(0.4)
		_cells[i].add_theme_stylebox_override("panel", _cell_style(border, selected, filled))
	var slots: PackedStringArray = _equip_slots()
	var box_avail: Vector2 = Vector2(_box_size.x - 6.0, _box_size.y - 4.0 - 8.0)
	for i: int in _doll_boxes.size():
		var item: Dictionary = _equipped(slots[i])
		var filled: bool = not item.is_empty()
		var selected: bool = _focus == Focus.DOLL and i == _selected_doll
		var border: Color = _tier_color(item) if filled else EMPTY_BORDER
		var nm: Label = _doll_boxes[i].get_node("Box/Name") as Label
		if filled:
			_fit_name(nm, str(item.get("name", "?")), box_avail, 7)
		else:
			nm.text = ""
		if selected:
			border = Color.WHITE if not filled else border.lightened(0.4)
		_doll_boxes[i].add_theme_stylebox_override("panel", _cell_style(border, selected, filled))
	_detail.text = _detail_text()
	_stats_text.text = _stats_bbcode(_focus == Focus.STATS)


func _detail_text() -> String:
	var item: Dictionary = {}
	if _focus == Focus.INVENTORY:
		item = _slot(_selected_slot)
	elif _focus == Focus.DOLL:
		item = _equipped(_equip_slots()[_selected_doll])
	if item.is_empty():
		return "Empty"
	var parts: PackedStringArray = [str(item.get("name", "?"))]
	var tier: String = str(item.get("tier", ""))
	if tier != "":
		parts.append(tier)
	var slot_name: String = str(item.get("slot", ""))
	if slot_name != "":
		parts.append(str(SLOT_CAPTIONS.get(slot_name, slot_name)))
	var bonuses: Variant = item.get("bonuses", {})
	if bonuses is Dictionary:
		for k: Variant in (bonuses as Dictionary).keys():
			parts.append("%+d %s" % [int((bonuses as Dictionary)[k]), LABELS.get(str(k), str(k).capitalize())])
	var hint: String = "  [E: equip, 1-5: hotbar]" if _focus == Focus.INVENTORY and slot_name != "" else ("  [E: unequip, 1-5: hotbar]" if _focus == Focus.DOLL else "")
	return "  |  ".join(parts) + hint


func _stats_bbcode(focused: bool) -> String:
	var head: String = "[b]CRAWLER STATS[/b]" if focused else "CRAWLER STATS"
	var t: String = "%s   Floor %d   Level %d   XP %d / %d\n" % [head, PlayerStats.floor_number, PlayerStats.character_level, PlayerStats.xp, PlayerStats.XP_PER_LEVEL]
	t += "[table=9]"
	var names: Array = PlayerStats.STAT_NAMES
	var rows: int = ceili(float(names.size()) / STAT_COLS)
	for r: int in rows:
		for c: int in STAT_COLS:
			var i: int = r * STAT_COLS + c
			if i >= names.size():
				t += "[cell][/cell][cell][/cell][cell][/cell]"
				continue
			var cursor: String = ">" if (focused and i == _selected_stat) else ""
			t += "[cell]%s [/cell][cell]%s  [/cell][cell]%d      [/cell]" % [cursor, LABELS[names[i]], PlayerStats.get_stat(names[i])]
	t += "[/table]\n"
	t += "Health max %d   Mana %d/%d   Melee +%d\n" % [PlayerStats.max_health(), PlayerStats.mana, PlayerStats.max_mana(), PlayerStats.damage_bonus()]
	if PlayerStats.class_chosen:
		t += "Unspent points: %d  (Enter to spend)" % PlayerStats.unspent_points
	else:
		t += "Unspent points: %d  (locked until floor %d)" % [PlayerStats.unspent_points, PlayerStats.CLASS_SELECT_FLOOR]
	t += "     [color=#888]Arrows move  Q switch  Tab/Esc close[/color]"
	return t
