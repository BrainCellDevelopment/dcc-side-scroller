extends Node2D

enum Phase { PLAY, ARENA, FIGHT, AFTERMATH, COMPLETE }

const GOBLIN_SCENE: PackedScene = preload("res://scenes/enemies/goblin.tscn")
const VEIL_SCRIPT: GDScript = preload("res://scripts/level/area_veil.gd")
const SNOW_SCRIPT: GDScript = preload("res://scripts/level/snow.gd")
const GATE_SCENE: PackedScene = preload("res://scenes/props/gate_door.tscn")
const FRAME_NEAR_SCENE: PackedScene = preload("res://scenes/props/gate_frame_near.tscn")
const FRAME_FAR_SCENE: PackedScene = preload("res://scenes/props/gate_frame_far.tscn")
const FRAME_NEAR_Z: int = 38
const FRAME_FAR_Z: int = 46
const DOOR_OFFSET: float = -5.0
const GATES: Array[Dictionary] = [
	{"section": 1, "floor_y": 304.0},
]
const VEIL_PLAYER_Z: int = 41
const VEIL_NEAR: float = 320.0
const BOSS_ARENA: GDScript = preload("res://scripts/level/boss_arena.gd")
const ENGINEER_NAME: String = "Goblin Engineer"
const GOBLIN_THROWER: int = 1
const NEXT_LEVEL: String = "res://scenes/level01.tscn"
const EXIT_HINT: String = "Leave the way you came in"
const EXIT_DELAY: float = 1.4
const RUN_CHECKPOINT: int = 7
const STAGE_RUN: int = 1
const STAGE_AFTERMATH: int = 2
const OPENING_SCRIPT: GDScript = preload("res://scripts/cutscene/opening.gd")
const STAGE_ROUND2: int = 3
const STAGE_ROUND3: int = 4
const COUNTDOWN_SECONDS: float = 6.5
const DOOR_CLOSE_PAD: float = 30.0
const SHELTER_PAD: float = 12.0
const NEW_LOOK_TITLE: String = "NEW LOOK UNLOCKED"
const NEW_LOOK_QUIP: String = "Congratulations, crawler. You are now dressed for the occasion."
const NEW_LOOK_SECONDS: float = 3.5
const ENGINEER_RUN_SPEED: float = 170.0
const ENGINEER_RUN_DISTANCE: float = 1600.0
const ENGINEER_EXIT_PAD: float = 60.0
const CHECKPOINT_OFFSET: float = 56.0
const FOCUS_ON_FLOOR: float = 40.0
const KILLS_FOR_PEST: int = 10
const LOOT_BOX_COUNT: int = 2
const LOOT_BOX_SCENE: PackedScene = preload("res://scenes/props/loot_box.tscn")
const EARNED_BOX_KIT: String = "floor1"
const STARTER_BOX_SECTION: int = 2
const PET_BISCUIT_ID: String = "legendary_pet_biscuit"
const PET_BISCUIT_LINE: String = "Donut ate the Legendary Pet Biscuit. She is not the same cat, and your head is lighter."
const STARTER_BOX_TIERS: PackedStringArray = ["Bronze", "Legendary"]
const DOZER_ROUNDS: int = 3
const HATCH_HINT: String = "Wait for the hatch to glow, then land on it"
const FOLLOW_HINT: String = "After him!"
const ACHIEVEMENTS: Dictionary = {
	"welcome": ["Still Breathing", "The world ended and you kept your cat and your boxers. Pants were optional, apparently."],
	"first_goblin": ["Hands-On Learner", "You punched a goblin until it stopped. Its pineapple on a stick survived, and judges you."],
	"engineer_down": ["Performance Review", "The Engineer's work was sloppy and so was his knife. He has gone to get a bigger tool."],
	"dozer_stomp": ["Hood Ornament", "You jumped on heavy machinery while it was moving. Your insurance has been cancelled."],
	"dozer_down": ["Warranty Void", "Steam power: unstable, loud, and now all over the walls. Loot boxes are waiting."],
	"safe_room": ["Indoor Voice", "Nothing can attack you in here. Enjoy the rug. It is the nicest thing you own now."],
	"mind_gap": ["Mind The Gap", "A hole in the ground tried to eat you. You hopped it like an overdue library book."],
	"first_hurt": ["Learning Experience", "You took damage. The tutorial calls this feedback. The goblin calls it lunch."],
	"rebar": ["Poke Averse", "You went over the sharp metal instead of through it. Doctors hate this one trick."],
	"crater": ["Crater Tourist", "You walked into a hole in the world on purpose. Reviews are mixed."],
	"stairs": ["Stairway To Somewhere Worse", "Nineteen flights down and nobody offered an elevator. Typical."],
	"thrower_down": ["Rock, Paper, Fist", "You punched the guy throwing rocks. The rocks declined to comment."],
	"ambush": ["Surprise Party", "Three goblins dropped in without an invitation. You brought your own fists."],
	"secret_route": ["Off The Beaten Path", "You found the high road. The goblins down below are filing a complaint."],
	"gauntlet": ["Sharp Dressed Feet", "You crossed a corridor designed by someone who really hates shoes."],
	"pest_control": ["Pest Control", "Ten goblins down. The rest have started talking about a union."],
	"reinforcements": ["Management Escalation", "The Engineer called for backup. Backup arrived through the ceiling, unhappy and holding rocks."],
}

var section: int = 0
var complete: bool = false

var _phase: Phase = Phase.PLAY
var _boxes_opened: int = 0
var _talked: bool = false
var _exit_ready: bool = false
var _kills: int = 0
var _rounds_cleared: int = 0
var _reinforced: bool = false
var _engineer_fleeing: bool = false
var _boss_arena: Node2D = null
var _start_round: int = 0
var _countdown: float = -1.0
var _door_shut: bool = false
var _shake_tick: float = 0.0
var _focus_y: float = 0.0
var _bg_section: int = -1
var _hint_owner: Area2D = null
var _section_areas: Dictionary = {}
var _seen: Dictionary = {}
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.01
var _gate_edges: Array[float] = []

@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _background: CanvasLayer = $Background
@onready var _engineer: CharacterBody2D = $Engineer
@onready var _dozer: AnimatableBody2D = $Dozer
@onready var _hud: CanvasLayer = $HUD
@onready var _goblins: Node2D = $Goblins
@onready var _triggers: Node2D = $Triggers
@onready var _arena_left_body: Node2D = $Walls/ArenaLeftWall
@onready var _arena_right_body: Node2D = $Walls/ArenaRightWall
@onready var _arena_left: CollisionShape2D = $Walls/ArenaLeftWall/CollisionShape2D
@onready var _arena_right: CollisionShape2D = $Walls/ArenaRightWall/CollisionShape2D
@onready var _scroll_start: Marker2D = $Markers/ScrollStart
@onready var _dozer_arena: Marker2D = $Markers/DozerArena
@onready var _dozer_left: Marker2D = $Markers/DozerLeft
@onready var _dozer_right: Marker2D = $Markers/DozerRight
@onready var _dozer_wall: CollisionShape2D = $Walls/DozerWall/CollisionShape2D
@onready var _safe_zone: Area2D = $Guildhall/SafeZone
@onready var _mordecai: Area2D = $Guildhall/Mordecai
@onready var _exit_zone: Area2D = $Guildhall/ExitZone
@onready var _guild_entry_door: Node2D = $Doors/GuildEntryDoor
@onready var _boxes: Node2D = $Guildhall/LootBoxes


func _enter_tree() -> void:
	PlayerStats.enter_floor(0)


func _ready() -> void:
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_player.connect("died", _on_player_died)
	_boss_arena = BOSS_ARENA.new() as Node2D
	_boss_arena.set("boss_name", ENGINEER_NAME)
	_boss_arena.set("tooltip", "He fixes things. Mostly with a knife.")
	_boss_arena.set("hud", _hud)
	add_child(_boss_arena)
	var locks: Array[CollisionShape2D] = [_arena_left, _arena_right]
	_boss_arena.call("setup", _engineer, locks)
	_boss_arena.connect("boss_defeated", _on_engineer_defeated)
	_dozer.connect("round_cleared", _on_dozer_round_cleared)
	_dozer.connect("round_started", _on_dozer_round_started)
	_dozer.connect("destroyed", _on_dozer_destroyed)
	if _dozer.has_signal("vulnerable_changed"):
		_dozer.connect("vulnerable_changed", _on_vulnerable_changed)
	Game.screen_shake.connect(_on_screen_shake)
	Game.player_health_changed.connect(_on_player_health_changed)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	for goblin: Node in _goblins.get_children():
		_watch_goblin(goblin)
	for node: Node in _triggers.get_children():
		var area: Area2D = node as Area2D
		if area == null:
			continue
		area.body_entered.connect(_on_trigger_entered.bind(area))
		area.body_exited.connect(_on_trigger_exited.bind(area))
		if str(area.get_meta("kind")) == "section":
			_section_areas[int(str(area.get_meta("arg")))] = area
	_safe_zone.body_entered.connect(_on_safe_zone_entered)
	_safe_zone.body_exited.connect(_on_safe_zone_exited)
	for box: Node in _boxes.get_children():
		box.connect("opened", _on_loot_box_opened)
	_mordecai.connect("dialogue_finished", _on_mordecai_done)
	_exit_zone.body_entered.connect(_on_exit_entered)
	_dozer.visible = false
	_dozer.set("patrol_min_x", _dozer_left.global_position.x)
	_dozer.set("patrol_max_x", _dozer_right.global_position.x)
	_begin()
	_setup_doors()
	_setup_gates()
	_setup_snow()


func _physics_process(delta: float) -> void:
	var view: Vector2 = _view_size()
	var half: Vector2 = view * 0.5
	var target: Vector2 = _camera.global_position
	match _phase:
		Phase.ARENA:
			target = Vector2(_scroll_start.global_position.x + half.x, float(_camera.limit_bottom) - half.y)
		_:
			target = _follow_target(view)
	if _engineer_fleeing and is_instance_valid(_engineer) and _engineer.global_position.x > _camera.global_position.x + half.x + ENGINEER_EXIT_PAD:
		_finish_engineer_exit()
	_camera.global_position = target
	_update_shake(delta)
	_countdown_step(delta)
	_update_player_z()


func _setup_snow() -> void:
	var snow: CanvasLayer = CanvasLayer.new()
	snow.set_script(SNOW_SCRIPT)
	snow.set("edge_x", float((_section_areas[int(GATES[0]["section"])] as Area2D).get_meta("x0")))
	snow.name = "Snow"
	add_child(snow)
	var edge: float = float(snow.get("edge_x"))
	for node: Node in $Platforms.get_children():
		var platform: Node2D = node as Node2D
		if platform != null and platform.global_position.x < edge and platform.get("style") != null:
			platform.set("snow", true)


func _setup_gates() -> void:
	for gate: Dictionary in GATES:
		var area: Area2D = _section_areas[int(gate["section"])] as Area2D
		var edge: float = float(area.get_meta("x0"))
		var door: Node2D = GATE_SCENE.instantiate() as Node2D
		door.position = Vector2(edge + DOOR_OFFSET, float(gate["floor_y"]))
		door.name = "Gate%d" % int(gate["section"])
		add_child(door)
		_wire_gate(door, edge, float(gate["floor_y"]), str(gate["section"]))
	_wire_gate(_guild_entry_door, _guild_entry_door.global_position.x - DOOR_OFFSET, _guild_entry_door.global_position.y, "Guild")


func _wire_gate(door: Node2D, edge: float, floor_y: float, tag: String) -> void:
	_gate_edges.append(edge)
	var veil: Node2D = Node2D.new()
	veil.set_script(VEIL_SCRIPT)
	veil.set("edge_x", edge)
	veil.name = "Veil" + tag
	add_child(veil)
	for part: Dictionary in [{"scene": FRAME_NEAR_SCENE, "z": FRAME_NEAR_Z, "tag": "Near"}, {"scene": FRAME_FAR_SCENE, "z": FRAME_FAR_Z, "tag": "Far"}]:
		var half: Node2D = (part["scene"] as PackedScene).instantiate() as Node2D
		half.position = Vector2(edge, floor_y)
		half.z_index = int(part["z"])
		half.name = "Frame%s%s" % [str(part["tag"]), tag]
		add_child(half)
	door.set("veil", veil)
	var passed: float = _player.global_position.x - door.global_position.x
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


func _view_size() -> Vector2:
	return get_viewport().get_visible_rect().size / _camera.zoom


func _follow_target(view: Vector2) -> Vector2:
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


func _snap_camera() -> void:
	_focus_y = _player.global_position.y - FOCUS_ON_FLOOR
	_camera.global_position = _follow_target(_view_size())
	_camera.reset_smoothing()
	_camera.reset_physics_interpolation()


func _begin() -> void:
	if Game.checkpoint_index < 0:
		_enter_section(0)
		_snap_camera()
		if _should_play_opening():
			_play_opening()
		else:
			_unlock("welcome")
		return
	var pos: Vector2 = Game.checkpoint_position
	_player.global_position = pos + Vector2(0.0, -2.0)
	_player.reset_physics_interpolation()
	_prune_before(pos.x)
	_seen[_section_at(pos.x)] = true
	_enter_section(_section_at(pos.x))
	match Game.checkpoint_stage:
		STAGE_RUN, STAGE_ROUND2, STAGE_ROUND3:
			_engineer.queue_free()
			_start_round = {STAGE_RUN: 0, STAGE_ROUND2: 1, STAGE_ROUND3: 2}[Game.checkpoint_stage]
		STAGE_AFTERMATH:
			_engineer.queue_free()
			_dozer.queue_free()
			_phase = Phase.AFTERMATH
			_enter_section(section)
	_snap_camera()


func _should_play_opening() -> bool:
	return not Game.intro_played and DisplayServer.get_name() != "headless" and not OS.has_environment("DCC_SKIP_INTRO")


func _play_opening() -> void:
	Game.intro_played = true
	var opening: Node = Node.new()
	opening.set_script(OPENING_SCRIPT)
	add_child(opening)
	await opening.call("play", self, _player, _camera, _hud)
	Game.floor_time_left = Game.FLOOR_TIME
	_unlock("welcome")


func _prune_before(x: float) -> void:
	for node: Node in _goblins.get_children():
		var goblin: Node2D = node as Node2D
		if goblin != null and goblin.global_position.x < x - 64.0:
			goblin.queue_free()


func _section_at(x: float) -> int:
	for index: int in _section_areas.keys():
		var area: Area2D = _section_areas[index] as Area2D
		if x >= float(area.get_meta("x0")) and x < float(area.get_meta("x1")):
			return index
	return 0


func _enter_section(index: int) -> void:
	if complete:
		return
	if _phase >= Phase.FIGHT:
		index = maxi(index, 5)
	var area: Area2D = _section_areas[index] as Area2D
	section = index
	if index != _bg_section:
		_bg_section = index
		_background.call("set_style", int(area.get_meta("bg")))
	if _phase == Phase.PLAY or _phase == Phase.AFTERMATH:
		_camera.limit_left = int(area.get_meta("l"))
		_camera.limit_right = int(area.get_meta("r"))
		_camera.limit_top = int(area.get_meta("t"))
		_camera.limit_bottom = int(area.get_meta("b"))
		if _phase == Phase.AFTERMATH and index == 5:
			_camera.limit_right = int((_section_areas[6] as Area2D).get_meta("r"))
	if index >= STARTER_BOX_SECTION:
		_grant_starter_boxes()
	var title: String = str(area.get_meta("title"))
	if not title.is_empty() and not _seen.has(index):
		_hud.call("show_banner", title, 2.0)
	_seen[index] = true


func _grant_starter_boxes() -> void:
	if Game.starter_boxes_announced:
		return
	Game.starter_boxes_announced = true
	for tier: String in STARTER_BOX_TIERS:
		Game.announce_box(tier)


func _unlock(id: String) -> void:
	var entry: Array = ACHIEVEMENTS[id]
	Game.unlock_achievement(id, str(entry[0]), str(entry[1]))


func _on_trigger_entered(body: Node2D, area: Area2D) -> void:
	if body != _player:
		return
	match str(area.get_meta("kind")):
		"section":
			_enter_section(int(str(area.get_meta("arg"))))
		"hint":
			_hint_owner = area
			Game.set_hint(str(area.get_meta("arg")))
		"ach":
			_unlock(str(area.get_meta("arg")))
			area.set_deferred("monitoring", false)
		"ambush":
			_ambush(area)
			area.set_deferred("monitoring", false)
		"arena":
			_start_arena()
			area.set_deferred("monitoring", false)
		"dozer":
			_start_fight()
			area.set_deferred("monitoring", false)


func _on_trigger_exited(body: Node2D, area: Area2D) -> void:
	if body == _player and _hint_owner == area:
		_hint_owner = null
		Game.set_hint("")


func _watch_goblin(goblin: Node) -> void:
	goblin.connect("died", _on_goblin_died)


func _spawn_goblin(pos: Vector2, variant: int = 0) -> void:
	var goblin: Node2D = GOBLIN_SCENE.instantiate() as Node2D
	goblin.set("variant", variant)
	goblin.position = pos
	_goblins.add_child.call_deferred(goblin)
	_watch_goblin(goblin)


func _ambush(area: Area2D) -> void:
	var parts: PackedStringArray = str(area.get_meta("arg")).split(",")
	var y: float = float(parts[parts.size() - 1])
	for i: int in range(parts.size() - 1):
		_spawn_goblin(Vector2(float(parts[i]), y))
	_unlock("ambush")
	Game.shake(3.0, 0.3)


func _on_goblin_died(enemy: Node) -> void:
	_kills += 1
	_unlock("first_goblin")
	var variant: Variant = enemy.get("variant")
	if variant != null and int(variant) == 1:
		_unlock("thrower_down")
	if _kills >= KILLS_FOR_PEST:
		_unlock("pest_control")


func _on_player_health_changed(current: int, maximum: int) -> void:
	if current < maximum:
		_unlock("first_hurt")


func _start_arena() -> void:
	if _phase != Phase.PLAY:
		return
	_phase = Phase.ARENA
	var area: Area2D = _section_areas[4] as Area2D
	_camera.limit_left = int(_scroll_start.global_position.x)
	_camera.limit_right = int(_arena_right_body.global_position.x)
	_camera.limit_top = int(area.get_meta("t"))
	_camera.limit_bottom = int(area.get_meta("b"))
	_engineer.set("arena_left", _arena_left_body.global_position.x + 90.0)
	_engineer.set("arena_right", _arena_right_body.global_position.x - 12.0)
	_boss_arena.call("start")


func _on_boss_health_changed(boss_name: String, current: int, maximum: int) -> void:
	if boss_name != ENGINEER_NAME or _reinforced or _phase != Phase.ARENA:
		return
	if current <= 0 or current * 2 > maximum:
		return
	_reinforced = true
	var center: float = _scroll_start.global_position.x + 320.0
	var y: float = _scroll_start.global_position.y - 220.0
	_spawn_goblin(Vector2(center - 90.0, y), GOBLIN_THROWER)
	_spawn_goblin(Vector2(center + 90.0, y), GOBLIN_THROWER)
	_unlock("reinforcements")


func _on_engineer_defeated(_engineer_node: Node) -> void:
	if _phase != Phase.ARENA:
		return
	_phase = Phase.PLAY
	_unlock("engineer_down")
	_engineer.set("scripted", true)
	_enter_section(5)
	Game.set_checkpoint(RUN_CHECKPOINT, _arena_checkpoint(), STAGE_RUN)
	var visual: Node2D = _engineer.get_node("Visual") as Node2D
	visual.scale.x = 1.0
	_engineer.call("set_pose", "walk")
	_engineer_fleeing = true
	_player.set("control_enabled", false)
	var tween: Tween = create_tween()
	tween.tween_property(_engineer, "global_position:x", _engineer.global_position.x + ENGINEER_RUN_DISTANCE, ENGINEER_RUN_DISTANCE / ENGINEER_RUN_SPEED)
	tween.tween_callback(_finish_engineer_exit)


func _finish_engineer_exit() -> void:
	if is_instance_valid(_engineer):
		_engineer.queue_free()
	_engineer_fleeing = false
	_player.set("control_enabled", true)
	Game.set_hint(FOLLOW_HINT)


func _arena_checkpoint() -> Vector2:
	return _dozer_arena.global_position + Vector2(CHECKPOINT_OFFSET, 0.0)


func _start_fight() -> void:
	if _phase != Phase.PLAY:
		return
	_phase = Phase.FIGHT
	_engineer_fleeing = false
	_dozer_wall.set_deferred("disabled", false)
	Game.set_checkpoint(RUN_CHECKPOINT, _arena_checkpoint(), STAGE_RUN)
	var area: Area2D = _section_areas[5] as Area2D
	_camera.limit_left = int(_dozer_arena.global_position.x)
	_camera.limit_right = int(_guild_entry_door.global_position.x + 48.0)
	_camera.limit_top = int(area.get_meta("t"))
	_camera.limit_bottom = int(area.get_meta("b"))
	Game.set_hint(HATCH_HINT)
	_hud.call("show_banner", "GOBLIN MURDER DOZER", 2.0)
	_dozer.call("begin_patrol", _player, _dozer_arena.global_position.y, _start_round)


func _on_vulnerable_changed(is_vulnerable: bool) -> void:
	if _phase != Phase.FIGHT:
		return
	if is_vulnerable:
		Game.set_hint("Now! Land on the glowing hatch!")
	elif _rounds_cleared == 0:
		Game.set_hint(HATCH_HINT)
	else:
		Game.set_hint("")


func _on_dozer_round_cleared(round_number: int) -> void:
	_rounds_cleared = round_number
	Game.set_hint("")
	if round_number == 1:
		_unlock("dozer_stomp")
	if round_number < DOZER_ROUNDS - 1:
		_hud.call("show_banner", "ROUND %d" % (round_number + 1), 1.2)


func _on_dozer_round_started(round_number: int) -> void:
	if round_number != DOZER_ROUNDS or _phase != Phase.FIGHT:
		return
	_countdown = COUNTDOWN_SECONDS
	_door_shut = false
	Game.set_hint("")
	_hud.call("show_banner", "IT'S GONNA BLOW!\nGET TO MORDECAI'S DOOR!", 3.0)
	_guild_entry_door.call("unlock")
	_guild_entry_door.call("open")


func _countdown_step(delta: float) -> void:
	if _countdown < 0.0 or _phase != Phase.FIGHT:
		return
	_countdown -= delta
	var progress: float = clampf(1.0 - _countdown / COUNTDOWN_SECONDS, 0.0, 1.0)
	_dozer.set("alarm", maxf(progress, 0.05))
	_hud.call("show_countdown", _countdown)
	_shake_tick -= delta
	if _shake_tick <= 0.0:
		_shake_tick = 0.25
		Game.shake(0.6 + 3.0 * progress, 0.25)
	var door_x: float = _guild_entry_door.global_position.x
	if not _door_shut and _player.global_position.x > door_x + DOOR_CLOSE_PAD:
		_shut_door()
	if _countdown <= 0.0:
		_detonate()


func _shut_door() -> void:
	_door_shut = true
	_guild_entry_door.call("close")
	_camera.limit_right = int((_section_areas[6] as Area2D).get_meta("r"))


func _detonate() -> void:
	_countdown = -1.0
	_hud.call("hide_countdown")
	_hud.call("flash_screen")
	Game.shake(10.0, 0.8)
	var sheltered: bool = _player.global_position.x > _guild_entry_door.global_position.x + SHELTER_PAD
	if sheltered and not _door_shut:
		_shut_door()
	elif not sheltered:
		_player.call("kill", true)
	_dozer.call("detonate")


func _on_dozer_destroyed() -> void:
	if _phase != Phase.FIGHT or bool(_player.call("is_dead")):
		return
	_phase = Phase.AFTERMATH
	_dozer_wall.set_deferred("disabled", true)
	_camera.limit_right = int((_section_areas[6] as Area2D).get_meta("r"))
	Game.set_hint("Head right.")
	_unlock("dozer_down")
	if _player.global_position.x <= _guild_entry_door.global_position.x + SHELTER_PAD:
		_guild_entry_door.call("unlock")
		_guild_entry_door.call("open")


func _on_safe_zone_entered(body: Node2D) -> void:
	if body != _player:
		return
	Game.set_safe_zone(true)
	Game.set_hint("")
	_unlock("safe_room")


func _on_safe_zone_exited(body: Node2D) -> void:
	if body == _player:
		Game.set_safe_zone(false)


func _on_mordecai_done() -> void:
	_talked = true
	_grant_starter_boxes()
	for box: Node in _boxes.get_children():
		box.call("summon", _player, _mordecai.global_position + Vector2(0.0, -30.0))
	var slot: int = LOOT_BOX_COUNT
	for tier: String in Game.take_earned_boxes():
		var earned: Area2D = LOOT_BOX_SCENE.instantiate() as Area2D
		earned.set("tier", tier)
		earned.set("kit", EARNED_BOX_KIT)
		earned.set("slot", slot)
		slot += 1
		_boxes.add_child(earned)
		earned.call("summon", _player, _mordecai.global_position + Vector2(0.0, -30.0))
	_check_exit_ready()


func _on_loot_box_opened(_tier: String) -> void:
	_boxes_opened += 1
	_check_exit_ready()


func _check_exit_ready() -> void:
	if not _talked or _boxes_opened < LOOT_BOX_COUNT or _exit_ready:
		return
	_exit_ready = true
	Game.set_hint(EXIT_HINT)
	_guild_entry_door.set("close_behind", false)
	_guild_entry_door.call("unlock")
	_guild_entry_door.call("open")
	_try_exit()


func _try_exit() -> void:
	for body: Node2D in _exit_zone.get_overlapping_bodies():
		_on_exit_entered(body)


func _on_exit_entered(body: Node2D) -> void:
	if body != _player or complete or not _exit_ready:
		return
	_phase = Phase.COMPLETE
	complete = true
	section = 7
	Game.register_tutorial_complete()
	Game.set_hint("")
	_feed_donut_biscuit()
	Game.clear_checkpoint()
	Game.carry_player_state(_player)
	_player.set("control_enabled", false)
	_hud.call("show_banner", "LEVEL 0 COMPLETE", 0.0)
	await get_tree().create_timer(EXIT_DELAY).timeout
	get_tree().change_scene_to_file(NEXT_LEVEL)


func _feed_donut_biscuit() -> void:
	if Inventory.consume_item(PET_BISCUIT_ID) > 0:
		SystemVoice.announce("DONUT ATE IT", PET_BISCUIT_LINE, 3.5)


func _setup_doors() -> void:
	if Game.checkpoint_index >= 8:
		_guild_entry_door.call("open", false)


func dev_goto(target: String) -> bool:
	var index: int = -1
	match target:
		"surface":
			Game.clear_checkpoint()
			Game.reset_run()
			Game.reset_boxes()
			return true
		"stairtop":
			index = 0
		"stairs":
			index = 1
		"hall":
			index = 2
		"tunnels":
			index = 3
		"tunnels2":
			index = 4
		"tunnels3":
			index = 5
		"arena":
			index = 6
		"guildhall":
			index = 8
		"dozerfight", "chase":
			index = 7
		"dozerfight3":
			Game.clear_checkpoint()
			Game.set_checkpoint(RUN_CHECKPOINT, _arena_checkpoint(), STAGE_ROUND3)
			Game.reset_run()
			return true
		"dozerfight2":
			Game.clear_checkpoint()
			Game.set_checkpoint(RUN_CHECKPOINT, _arena_checkpoint(), STAGE_ROUND2)
			Game.reset_run()
			return true
		_:
			if target.begins_with("cp") and target.substr(2).is_valid_int():
				index = target.substr(2).to_int()
	if index < 0:
		return false
	for node: Node in $Checkpoints.get_children():
		if int(node.get("index")) == index:
			Game.clear_checkpoint()
			Game.set_checkpoint(index, (node as Node2D).global_position, int(node.get("stage")))
			Game.reset_run()
			return true
	return false


func _on_player_died() -> void:
	var switched: bool = Game.register_tutorial_death()
	_hud.call("show_banner", "YOU DIED", 0.0)
	if switched:
		await get_tree().create_timer(0.9).timeout
		_hud.call("hide_banner")
		_hud.call("show_system_message", NEW_LOOK_TITLE, NEW_LOOK_QUIP, NEW_LOOK_SECONDS)
		await get_tree().create_timer(NEW_LOOK_SECONDS + 0.3).timeout
	else:
		await get_tree().create_timer(1.8).timeout
	Game.reset_run()
	get_tree().reload_current_scene()
