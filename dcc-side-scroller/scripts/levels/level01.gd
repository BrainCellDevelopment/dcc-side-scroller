extends Node2D

enum Phase { PLAY, BOSS, COMPLETE }

const VEIL_SCRIPT: GDScript = preload("res://scripts/level/area_veil.gd")
const GATE_SCENE: PackedScene = preload("res://scenes/props/gate_door.tscn")
const FRAME_NEAR_SCENE: PackedScene = preload("res://scenes/props/gate_frame_near.tscn")
const FRAME_FAR_SCENE: PackedScene = preload("res://scenes/props/gate_frame_far.tscn")
const FRAME_NEAR_Z: int = 38
const FRAME_FAR_Z: int = 46
const VEIL_PLAYER_Z: int = 41
const VEIL_NEAR: float = 320.0
const DOOR_OFFSET: float = -5.0
const DIRECTION: float = -1.0
const TITLE: String = "LEVEL 1"
const TITLE_SECONDS: float = 2.5
const FOCUS_ON_FLOOR: float = 40.0
const Targeting: GDScript = preload("res://scripts/combat/targeting.gd")
const MISSILE_HINT: String = "Out of reach? Press K to fire magic missiles"
const HINT_RANGE: float = 380.0
const CIGARETTE_LINES: Array[String] = [
	"Carl takes out his last cigarette.",
	"He lights it and looks down the stairs.",
	"Donut says nothing. For her, this is a record.",
]
const CIGARETTE_LINE_SECONDS: float = 2.4
const HEAL_TEXT: String = "THE STAIRS SET YOU RIGHT"
const COLLAPSE_SHAKE: float = 2.5
const COLLAPSE_STEPS: int = 20
const COLLAPSE_STEP_SECONDS: float = 0.12
const COLLAPSE_HUSH: float = 1.4
const COLLAPSE_NOTICE_TITLE: String = "LEVEL 1 IS CLOSED"
const COLLAPSE_NOTICE_BODY: String = "A floor's worth of people did not reach the stairs. The count is posted above."
const FADE_SECONDS: float = 0.8
const GREENROOM_HOLD: String = "TALK TO MORDECAI AND OPEN YOUR BOXES"

var section: int = 0
var complete: bool = false

var _phase: Phase = Phase.PLAY
var _section_areas: Dictionary = {}
var _seen: Dictionary = {}
var _hint_owner: Area2D = null
var _gate_edges: Array[float] = []
var _focus_y: float = 0.0
var _spell_used: bool = false
var _hint_shown: bool = false
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.01
var _cigarette_done: bool = false
var _healed: bool = false
var _fade: ColorRect = null
var _count_label: Label = null
var _greenroom: Node = null

@onready var _player: CharacterBody2D = $Player
@onready var _background: CanvasLayer = $Background
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: CanvasLayer = $HUD
@onready var _triggers: Node2D = $Triggers
@onready var _entry_door: Node2D = $Doors/EntryDoor
@onready var _intro_thrower: Node2D = $Goblins/IntroThrower


func _enter_tree() -> void:
	PlayerStats.enter_floor(1)


func _ready() -> void:
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_player.call("_set_facing", -1)
	_player.connect("died", _on_player_died)
	for node: Node in _triggers.get_children():
		var area: Area2D = node as Area2D
		if area == null:
			continue
		area.body_entered.connect(_on_trigger_entered.bind(area))
		area.body_exited.connect(_on_trigger_exited.bind(area))
		if str(area.get_meta("kind")) == "section":
			_section_areas[int(str(area.get_meta("arg")))] = area
	Game.screen_shake.connect(_on_screen_shake)
	Game.spell_cast.connect(_on_spell_cast)
	_player.call("enable_spell")
	Game.achievement_unlocked.connect(_on_achievement_unlocked)
	Game.loot_box_opened.connect(_on_loot_box_opened)
	Game.report_player_health(int(_player.get("health")), int(_player.get("max_health")))
	_greenroom = get_node_or_null("Greenroom")
	if _greenroom != null:
		_greenroom.connect("ready_to_leave", _try_end)
	_begin()
	_setup_gates()


func _physics_process(delta: float) -> void:
	_camera.global_position = _follow_target()
	_update_shake(delta)
	_update_hint()
	_update_player_z()
	if not complete:
		FloorHandoff.play_seconds += delta


func _begin() -> void:
	if Game.checkpoint_index < 0:
		FloorHandoff.start_floor()
		_seen[0] = true
		_enter_section(0)
		_snap_camera()
		_hud.call("show_banner", TITLE, TITLE_SECONDS)
		return
	var pos: Vector2 = Game.checkpoint_position
	_player.global_position = pos + Vector2(0.0, -2.0)
	_player.reset_physics_interpolation()
	_prune_passed(pos.x)
	_enter_section(_section_at(pos.x))
	_snap_camera()


func _prune_passed(x: float) -> void:
	for node: Node in $Goblins.get_children():
		var goblin: Node2D = node as Node2D
		if goblin != null and goblin.global_position.x > x + 64.0:
			goblin.queue_free()


func _section_at(x: float) -> int:
	for index: int in _section_areas.keys():
		var area: Area2D = _section_areas[index] as Area2D
		if x >= float(area.get_meta("x0")) and x < float(area.get_meta("x1")):
			return index
	return 0


func _enter_section(index: int) -> void:
	if complete or not _section_areas.has(index):
		return
	var area: Area2D = _section_areas[index] as Area2D
	section = index
	if _phase == Phase.PLAY:
		_camera.limit_left = int(area.get_meta("l"))
		_camera.limit_right = int(area.get_meta("r"))
		_camera.limit_top = int(area.get_meta("t"))
		_camera.limit_bottom = int(area.get_meta("b"))
		_background.call("set_style", int(area.get_meta("bg")))
	var title: String = str(area.get_meta("title"))
	if not title.is_empty() and not _seen.has(index):
		_hud.call("show_banner", title, TITLE_SECONDS)
	_seen[index] = true


func _setup_gates() -> void:
	for index: int in _section_areas.keys():
		var area: Area2D = _section_areas[index] as Area2D
		if int(area.get_meta("gate")) != 1:
			continue
		var edge: float = float(area.get_meta("edge"))
		var floor_y: float = float(area.get_meta("floor_y"))
		var door: Node2D = GATE_SCENE.instantiate() as Node2D
		door.position = Vector2(edge + DOOR_OFFSET * DIRECTION, floor_y)
		door.scale.x = DIRECTION
		door.name = "Gate%d" % index
		add_child(door)
		_wire_gate(door, edge, floor_y, str(index))


func _wire_gate(door: Node2D, edge: float, floor_y: float, tag: String) -> void:
	_gate_edges.append(edge)
	var veil: Node2D = Node2D.new()
	veil.set_script(VEIL_SCRIPT)
	veil.set("edge_x", edge)
	veil.set("direction", DIRECTION)
	veil.name = "Veil" + tag
	add_child(veil)
	for part: Dictionary in [{"scene": FRAME_NEAR_SCENE, "z": FRAME_NEAR_Z, "tag": "Near"}, {"scene": FRAME_FAR_SCENE, "z": FRAME_FAR_Z, "tag": "Far"}]:
		var half: Node2D = (part["scene"] as PackedScene).instantiate() as Node2D
		half.position = Vector2(edge, floor_y)
		half.scale.x = DIRECTION
		half.z_index = int(part["z"])
		half.name = "Frame%s%s" % [str(part["tag"]), tag]
		add_child(half)
	door.set("veil", veil)
	var passed: float = (_player.global_position.x - door.global_position.x) * DIRECTION
	if passed > float(door.get("close_distance")):
		door.call("open", false)
		door.call("close", false)
	elif passed > 0.0:
		door.call("open", false)


func _update_player_z() -> void:
	var near: bool = false
	for edge: float in _gate_edges:
		if absf(_player.global_position.x - edge) < VEIL_NEAR:
			near = true
			break
	_player.z_index = VEIL_PLAYER_Z if near else 0


func _follow_target() -> Vector2:
	var view: Vector2 = get_viewport().get_visible_rect().size / _camera.zoom
	var py: float = _player.global_position.y
	if _player.is_on_floor():
		_focus_y = py - FOCUS_ON_FLOOR
	else:
		var low: float = view.y * 0.28
		var high: float = view.y * 0.3
		if py > _focus_y + low:
			_focus_y = py - low
		elif py < _focus_y - high:
			_focus_y = py + high
	return Vector2(_player.global_position.x, _focus_y)


func _snap_camera() -> void:
	_focus_y = _player.global_position.y - FOCUS_ON_FLOOR
	_camera.global_position = _follow_target()
	_camera.reset_smoothing()
	_camera.reset_physics_interpolation()


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_shake_time -= delta
	var decay: float = clampf(_shake_time / _shake_total, 0.0, 1.0)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * decay


func _on_screen_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time = duration
	_shake_total = maxf(duration, 0.01)


func _update_hint() -> void:
	var show: bool = false
	if not _spell_used and not complete and is_instance_valid(_intro_thrower) and Targeting.is_valid(_intro_thrower):
		show = absf(_player.global_position.x - _intro_thrower.global_position.x) < HINT_RANGE
	if show == _hint_shown:
		return
	_hint_shown = show
	Game.set_hint(MISSILE_HINT if show else "")


func _on_spell_cast() -> void:
	_spell_used = true


func _on_trigger_entered(body: Node2D, area: Area2D) -> void:
	if body != _player:
		return
	match str(area.get_meta("kind")):
		"section":
			_enter_section(int(str(area.get_meta("arg"))))
		"bg":
			_background.call("set_style", int(str(area.get_meta("arg"))))
		"hint":
			_hint_owner = area
			Game.set_hint(str(area.get_meta("arg")))
		"cigarette":
			_last_cigarette()
		"heal":
			_heal_on_stairs()
		"end":
			_on_end_entered()


func _on_trigger_exited(body: Node2D, area: Area2D) -> void:
	if body == _player and _hint_owner == area:
		_hint_owner = null
		Game.set_hint("")


func _on_achievement_unlocked(title: String, _description: String) -> void:
	FloorHandoff.note_achievement(title)


func _on_loot_box_opened(_tier: String) -> void:
	FloorHandoff.note_box()


## Carl's last cigarette: a short text beat at the top of the stairs.
func _last_cigarette() -> void:
	if _cigarette_done or complete:
		return
	_cigarette_done = true
	Game.set_meta("last_cigarette", true)
	_player.set("control_enabled", false)
	for line: String in CIGARETTE_LINES:
		_hud.call("show_banner", line, CIGARETTE_LINE_SECONDS)
		await get_tree().create_timer(CIGARETTE_LINE_SECONDS).timeout
	if not complete:
		_player.set("control_enabled", true)


## Descending restores health (and stamina and mana).
func _heal_on_stairs() -> void:
	if _healed:
		return
	_healed = true
	var hurt: bool = int(_player.get("health")) < int(_player.get("max_health"))
	_player.call("restore_all")
	if hurt:
		_hud.call("show_banner", HEAL_TEXT, 1.8)


func _try_end() -> void:
	for body: Node2D in ($Triggers/EndZone as Area2D).get_overlapping_bodies():
		if body == _player:
			_on_end_entered()


func _on_end_entered() -> void:
	if complete:
		return
	if _greenroom != null and not bool(_greenroom.call("is_ready")):
		_hud.call("show_banner", GREENROOM_HOLD, 2.0)
		return
	complete = true
	_phase = Phase.COMPLETE
	Game.clear_checkpoint()
	Game.set_hint("")
	_player.set("control_enabled", false)
	await _collapse_beat()
	FloorHandoff.snapshot()
	FloorHandoff.carry(_player)
	await _fade_out()
	FloorHandoff.go(get_tree(), FloorHandoff.CABIN_SCENE)


## The floor collapse: a long shake, the survivor counter dropping by about 700,000, a quiet moment, then the
## System's notice and the patch notes. No gore and no jokes while the number moves.
func _collapse_beat() -> void:
	Game.shake(COLLAPSE_SHAKE, 1.6)
	await get_tree().create_timer(1.6).timeout
	_show_count()
	Game.shake(COLLAPSE_SHAKE * 0.4, COLLAPSE_STEPS * COLLAPSE_STEP_SECONDS)
	var per_step: int = FloorHandoff.SURVIVORS_LOST / COLLAPSE_STEPS
	for i: int in COLLAPSE_STEPS:
		SystemVoice.drop_survivors(per_step)
		await get_tree().create_timer(COLLAPSE_STEP_SECONDS).timeout
	SystemVoice.fire("collapse_survived")
	SystemVoice.fire("survivor_count_milestone")
	await get_tree().create_timer(COLLAPSE_HUSH).timeout
	_hide_count()
	SystemVoice.announce(COLLAPSE_NOTICE_TITLE, COLLAPSE_NOTICE_BODY, 3.5)
	SystemVoice.announce_patch_notes()
	await get_tree().create_timer(3.8 + 4.3).timeout


func _show_count() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CollapseCount"
	layer.layer = 60
	add_child(layer)
	_count_label = Label.new()
	_count_label.set_anchors_preset(Control.PRESET_CENTER)
	_count_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_count_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_count_label.offset_top = -60.0
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 22)
	_count_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.78))
	_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_count_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_count_label)
	SystemVoice.survivors_changed.connect(_refresh_count)
	_refresh_count(SystemVoice.survivors)


func _refresh_count(count: int) -> void:
	if _count_label != null:
		_count_label.text = SystemVoice.format_count(count)


func _hide_count() -> void:
	if _count_label == null:
		return
	SystemVoice.survivors_changed.disconnect(_refresh_count)
	_count_label.get_parent().queue_free()
	_count_label = null


func _fade_out() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	await tween.finished


func dev_sections() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for index: int in range(_section_areas.size()):
		names.append(str((_section_areas[index] as Area2D).get_meta("key")))
	return names


func dev_goto(target: String) -> bool:
	var index: int = -1
	for i: int in range(_section_areas.size()):
		if str((_section_areas[i] as Area2D).get_meta("key")) == target:
			index = i
	if index < 0 and target.begins_with("cp") and target.substr(2).is_valid_int():
		index = target.substr(2).to_int()
	if index < 0:
		return false
	if index == 0 and not target.begins_with("cp"):
		Game.clear_checkpoint()
		Game.reset_run()
		return true
	for node: Node in $Checkpoints.get_children():
		if int(node.get("index")) == index:
			Game.clear_checkpoint()
			Game.set_checkpoint(index, (node as Node2D).global_position, int(node.get("stage")))
			Game.reset_run()
			return true
	return false


func _on_player_died() -> void:
	_hud.call("show_banner", "YOU DIED", 0.0)
	await get_tree().create_timer(1.8).timeout
	Game.reset_run()
	get_tree().reload_current_scene()
