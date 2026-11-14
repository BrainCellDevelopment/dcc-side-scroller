extends CanvasLayer

const SLOT_SIZE: Vector2 = Vector2(50, 38)
const GAP: float = 3.0
const BOTTOM_MARGIN: float = 6.0
const EMPTY_BORDER: Color = Color(0.25, 0.27, 0.35)
const WORN_COLOR: Color = Color(0.4, 0.9, 0.5)
const TIER_COLORS: Dictionary = {
	"Bronze": Color(0.8, 0.5, 0.2),
	"Silver": Color(0.75, 0.78, 0.82),
	"Gold": Color(1.0, 0.84, 0.2),
	"Platinum": Color(0.5, 0.9, 0.95),
	"Legendary": Color(0.8, 0.4, 1.0),
}

var _root: Control
var _cells: Array[PanelContainer] = []


func _ready() -> void:
	layer = 70
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	for i: int in Inventory.HOTBAR_SIZE:
		var cell: PanelContainer = PanelContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.size = SLOT_SIZE
		cell.clip_contents = true
		var box: VBoxContainer = VBoxContainer.new()
		box.name = "Box"
		box.add_theme_constant_override("separation", 0)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(box)
		var key: Label = Label.new()
		key.name = "Key"
		key.text = str(i + 1)
		key.add_theme_font_size_override("font_size", 7)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(key)
		var title: Label = Label.new()
		title.name = "Name"
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_size_override("font_size", 7)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(title)
		_root.add_child(cell)
		_cells.append(cell)
	get_viewport().size_changed.connect(_layout)
	Inventory.changed.connect(_refresh)
	PlayerStats.stats_changed.connect(_refresh)
	_layout()
	_refresh()


func _process(_delta: float) -> void:
	if not PlayerStats.active or DevConsole.visible_panel():
		return
	for i: int in Inventory.HOTBAR_SIZE:
		if Game.action_just_pressed(StringName("hotbar_%d" % (i + 1))):
			Inventory.use_hotbar(i)


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var total: float = SLOT_SIZE.x * _cells.size() + GAP * (_cells.size() - 1)
	var x: float = floorf((vp.x - total) * 0.5)
	var y: float = vp.y - SLOT_SIZE.y - BOTTOM_MARGIN
	for i: int in _cells.size():
		_cells[i].position = Vector2(x + (SLOT_SIZE.x + GAP) * i, y)
		_cells[i].size = SLOT_SIZE


func _refresh() -> void:
	_root.visible = PlayerStats.active
	for i: int in _cells.size():
		var item: Dictionary = Inventory.hotbar_item(i)
		var filled: bool = not item.is_empty()
		var worn: bool = filled and Inventory.is_equipped(str(item["id"]))
		var name_label: Label = _cells[i].get_node("Box/Name") as Label
		name_label.text = str(item["name"]) if filled else ""
		var border: Color = EMPTY_BORDER
		if filled:
			border = TIER_COLORS.get(str(item.get("tier", "")), Color(0.5, 0.5, 0.5))
		if worn:
			border = WORN_COLOR
		var s: StyleBoxFlat = StyleBoxFlat.new()
		s.bg_color = Color(0.1, 0.11, 0.17, 0.85) if filled else Color(0.05, 0.06, 0.1, 0.6)
		s.border_color = border
		s.set_border_width_all(2 if worn else 1)
		s.set_content_margin_all(2.0)
		_cells[i].add_theme_stylebox_override("panel", s)
