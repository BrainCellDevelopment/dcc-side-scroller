extends CanvasLayer
## Level complete card (#68): time, kills, achievements, loot and survivors left, plus what Carl
## carries down. Built in code; call setup() before adding to the tree.

const FLAG_NAMES: Dictionary = {
	"neighborhood_map": "Neighborhood Map",
	"desperado_pass": "Desperado Pass",
	"borough_field_guide": "Borough Field Guide",
}
const HEADING: String = "LEVEL 1 COMPLETE"
const PROMPT: String = "Press E to take the stairs down"

var lines: Array[String] = []
var heading_text: String = HEADING


func setup(data: Dictionary) -> void:
	lines = FloorHandoff.summary_lines(data)
	lines.append(carried_line())


static func carried_line() -> String:
	var names: PackedStringArray = PackedStringArray()
	for flag: String in FLAG_NAMES.keys():
		if bool(Game.get_meta(flag, false)):
			names.append(str(FLAG_NAMES[flag]))
	if names.is_empty():
		return "Carried down:  health, items, XP"
	return "Carried down:  health, items, XP, " + ", ".join(names)


func _ready() -> void:
	layer = 40
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(380.0, 0.0)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var heading: Label = Label.new()
	heading.text = heading_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	box.add_child(heading)
	for line: String in lines:
		var label: Label = Label.new()
		label.name = "Line"
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 11)
		box.add_child(label)
	var prompt: Label = Label.new()
	prompt.text = PROMPT
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 9)
	prompt.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	box.add_child(prompt)
	add_child(panel)
