extends Node2D
## Floor 1 Borough boss arena (#67). Origin is the arena centre on the floor line; +x is the entry
## side (the level runs right to left). Builds the boss, the BossArena framework, the Speedbump
## fortress, the rave hazards, a dynamite cache, the exit forcefield and the Tuskling mop-up.
##
## Two ways to win: wedge the ball in the Speedbump fortress and hit it, or blow it up with dynamite.

signal fight_started
signal ball_popped
signal forcefield_dropped

const BOSS_ARENA: GDScript = preload("res://scripts/level/boss_arena.gd")
const LOCK_BARS: GDScript = preload("res://scripts/level/boss_lock_bars.gd")
const DOME: GDScript = preload("res://scripts/level/swine_dome.gd")
const FORTRESS: GDScript = preload("res://scripts/level/swine_fortress.gd")
const HAZARDS: GDScript = preload("res://scripts/level/rave_hazards.gd")
const BALL: PackedScene = preload("res://scenes/enemies/ball_of_swine.tscn")
const TUSKLING: PackedScene = preload("res://scenes/enemies/tuskling.tscn")
const DYNAMITE_PICKUP: PackedScene = preload("res://scenes/props/dynamite_pickup.tscn")
const LANE_GAP: float = 48.0
const WALL_HEIGHT: float = 720.0
const WALL_RISE: float = 250.0
const FIELD_GUIDE_FLAG: String = "borough_field_guide"
const FIELD_GUIDE_TITLE: String = "FIELD GUIDE UPDATED"
const FIELD_GUIDE_LINE: String = "Entry added: Borough Boss. Cause of death: its own guests. Rating: poor party, good loot."
const MOPUP: Array[int] = [0, 0, 0, 1, 1, 2]
const CROWD_SIZE: int = 26
const RESET_REVEAL: float = 1.4

@export var half_width: float = 352.0
@export var entry_x: float = 368.0
@export var forcefield_x: float = -368.0
@export var trigger_x: float = 330.0
@export var corridor_length: float = 160.0
@export var dynamite_sticks: int = 2

var boss: CharacterBody2D = null
var boss_arena: Node2D = null
var fortress: Node2D = null
var hazards: Node2D = null
var dome: Node2D = null
var floor_dome: Node2D = null
var started: bool = false
var won: bool = false
var field_dropped: bool = false
var mopup: Array[Node] = []
var crowd: Array[Node] = []

var _entry_shape: CollisionShape2D = null
var _field_shape: CollisionShape2D = null
var _field_bars: Node2D = null
var _camera: Camera2D = null
var _hud: Node = null


func _ready() -> void:
	add_to_group("swine_arena")
	Game.clear_boss()
	var lanes: Array[float] = lane_ys()
	_build_dome()
	_entry_shape = _make_wall(entry_x, false)
	_field_shape = _make_wall(forcefield_x, true)
	_field_bars = LOCK_BARS.new() as Node2D
	_field_shape.get_parent().add_child(_field_bars)
	_field_bars.position = _field_shape.position
	_field_bars.call("set_locked", true)
	boss = BALL.instantiate() as CharacterBody2D
	add_child(boss)
	boss.global_position = Vector2(global_position.x - half_width + 40.0, global_position.y)
	boss.call("configure", lanes, global_position.x - half_width, global_position.x + half_width)
	boss.visible = false
	_build_fortress()
	hazards = HAZARDS.new() as Node2D
	hazards.name = "Hazards"
	add_child(hazards)
	hazards.call("configure", global_position.x - half_width, global_position.x + half_width, lanes, boss)
	_build_boss_arena()
	_build_cache()
	_build_trigger()
	_hud = get_parent().get_node_or_null("HUD")
	boss_arena.set("hud", _hud)
	fortress.connect("armed_changed", _on_armed_changed)
	fortress.connect("piece_placed", _on_piece_placed)
	fortress.connect("broken", _on_fortress_broken)
	boss.connect("wedged", _on_ball_wedged)
	boss.connect("freed", _on_ball_freed)
	boss.connect("defeated", _on_ball_defeated)


func lane_ys() -> Array[float]:
	var floor_y: float = global_position.y
	return [floor_y, floor_y - LANE_GAP, floor_y - LANE_GAP * 2.0]


func rim_left() -> float:
	return global_position.x - half_width


func rim_right() -> float:
	return global_position.x + half_width


func _build_dome() -> void:
	dome = DOME.new() as Node2D
	dome.name = "Dome"
	dome.set("layer", 0)
	dome.set("half_width", half_width)
	dome.set("corridor_left", forcefield_x)
	dome.set("corridor_length", corridor_length)
	add_child(dome)
	floor_dome = DOME.new() as Node2D
	floor_dome.name = "FloorGrooves"
	floor_dome.set("layer", 1)
	floor_dome.set("half_width", half_width)
	add_child(floor_dome)


func _make_wall(x: float, enabled: bool) -> CollisionShape2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(x, -WALL_RISE)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, WALL_HEIGHT)
	shape.shape = rect
	shape.disabled = not enabled
	body.add_child(shape)
	add_child(body)
	return shape


func _build_fortress() -> void:
	fortress = FORTRESS.new() as Node2D
	fortress.name = "Fortress"
	add_child(fortress)
	var homes: Array[float] = [global_position.x + 224.0, global_position.x - 224.0]
	fortress.call("setup", global_position.x, global_position.y, homes)
	boss.set("gate_x", global_position.x)


func _build_boss_arena() -> void:
	boss_arena = BOSS_ARENA.new() as Node2D
	boss_arena.name = "BossArena"
	boss_arena.set("boss_name", "Ball of Swine")
	boss_arena.set("tooltip", "Seven hundred pounds of nobles in one very rude ball.")
	boss_arena.set("intro_seconds", 2.2)
	boss_arena.set("card_seconds", 2.2)
	boss_arena.set("drop_tier", "Boss")
	boss_arena.set("drop_kit", "floor1")
	add_child(boss_arena)
	var locks: Array[CollisionShape2D] = [_entry_shape]
	boss_arena.call("setup", boss, locks)
	boss_arena.connect("fight_started", _on_fight_started)


func _build_cache() -> void:
	for x: float in [128.0, -128.0]:
		var pickup: Node2D = DYNAMITE_PICKUP.instantiate() as Node2D
		pickup.set("count", dynamite_sticks)
		pickup.name = "DynamiteCache%d" % (1 if x > 0.0 else 2)
		add_child(pickup)
		pickup.position = Vector2(x, 0.0)


func _build_trigger() -> void:
	var area: Area2D = Area2D.new()
	area.name = "FightTrigger"
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = Vector2(trigger_x, -150.0)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16.0, 420.0)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_trigger_entered)


func _on_trigger_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		begin_fight()


func begin_fight() -> void:
	if started:
		return
	started = true
	_camera = get_viewport().get_camera_2d()
	if _camera != null:
		_camera.limit_left = int(global_position.x + forcefield_x - corridor_length)
		_camera.limit_right = int(global_position.x + entry_x + 16.0)
	boss.visible = true
	dome.set("beating", true)
	floor_dome.set("beating", true)
	var tween: Tween = create_tween()
	tween.tween_method(_set_reveal, 0.0, 1.0, RESET_REVEAL)
	Game.shake(3.0, RESET_REVEAL)
	boss_arena.call("start")


func _set_reveal(value: float) -> void:
	dome.set("reveal", value)
	floor_dome.set("reveal", value)


func _on_fight_started() -> void:
	hazards.call("start")
	fight_started.emit()


func _on_armed_changed(armed: bool) -> void:
	boss.set("gate_armed", armed)
	if armed and _hud != null and not won:
		_hud.call("show_banner", "FORTRESS READY. LURE IT ONTO THE FLOOR LANE", 2.5)


func _on_piece_placed(_index: int, _socket: int) -> void:
	boss.set("bump_xs", fortress.call("placed_xs"))


func _on_fortress_broken() -> void:
	boss.set("gate_armed", false)
	boss.set("bump_xs", [] as Array[float])


func _on_ball_wedged() -> void:
	if _hud != null:
		_hud.call("show_banner", "WEDGED! HIT IT NOW", 1.6)


func _on_ball_freed() -> void:
	fortress.call("break_fortress")
	if _hud != null:
		_hud.call("show_banner", "IT BROKE FREE. REBUILD OR USE DYNAMITE", 2.2)


func _on_ball_defeated(node: Node) -> void:
	if won:
		return
	won = true
	hazards.call("stop")
	dome.set("beating", false)
	floor_dome.set("beating", false)
	var at: Vector2 = (node as Node2D).global_position
	Game.set_meta(FIELD_GUIDE_FLAG, true)
	SystemVoice.fire("borough_boss")
	SystemVoice.announce(FIELD_GUIDE_TITLE, FIELD_GUIDE_LINE, 4.0)
	_drop_forcefield()
	_spawn_mopup(at)
	ball_popped.emit()


func _drop_forcefield() -> void:
	field_dropped = true
	_field_shape.set_deferred("disabled", true)
	_field_bars.call("set_locked", false)
	forcefield_dropped.emit()


func _spawn_mopup(at: Vector2) -> void:
	var index: int = 0
	for kind: int in MOPUP:
		index += 1
		var noble: CharacterBody2D = TUSKLING.instantiate() as CharacterBody2D
		noble.name = "Tuskling%d" % index
		noble.set("kind", kind)
		add_child(noble)
		noble.global_position = Vector2(at.x + float(index - 3) * 6.0, global_position.y - 8.0)
		var side: float = 1.0 if index % 2 == 0 else -1.0
		noble.call("launch", Vector2(side * (60.0 + 25.0 * float(index)), -210.0 - 15.0 * float(index)))
		mopup.append(noble)
	for i: int in CROWD_SIZE:
		var guest: CharacterBody2D = TUSKLING.instantiate() as CharacterBody2D
		guest.name = "Guest%d" % (i + 1)
		guest.set("decor", true)
		guest.set("kind", i % 3)
		add_child(guest)
		var direction: float = 1.0 if i % 2 == 0 else -1.0
		guest.global_position = Vector2(at.x + float(i) * 3.0 * direction, global_position.y - float(i % 3) * 0.0)
		guest.call("run_off", direction, 3.0 + float(i) * 0.12)
		crowd.append(guest)


## Mop-up Tusklings that are still around.
func mopup_alive() -> int:
	var alive: int = 0
	for noble: Node in mopup:
		if is_instance_valid(noble) and not bool(noble.call("is_dead")):
			alive += 1
	return alive
