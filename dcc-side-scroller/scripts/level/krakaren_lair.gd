extends Node2D
## The Krakaren Clone's lair (Level 2 boss): builds the boss, the arena lock, the entry trigger and the
## BossArena wiring. Origin is the arena centre on the floor line, +x is the boss end. The player enters
## from the left; the lock closes behind them, and opens again when the Krakaren dies.

const BOSS: GDScript = preload("res://scripts/enemies/krakaren.gd")
const BOSS_ARENA: GDScript = preload("res://scripts/level/boss_arena.gd")
const WALL_HEIGHT: float = 720.0
const WALL_RISE: float = 250.0
const DEFEAT_TITLE: String = "KRAKAREN CLONE"
const DEFEAT_BODY: String = "It paid for its own pyramid scheme. Nobody is checking the receipts."

@export var half_width: float = 320.0
@export var trigger_x: float = -296.0

var boss: Node2D = null
var boss_arena: Node2D = null
var started: bool = false

var _lock_shape: CollisionShape2D = null
var _exit_shape: CollisionShape2D = null


func _ready() -> void:
	add_to_group("krakaren_lair")
	_lock_shape = _make_wall(-half_width - 16.0, false)
	_exit_shape = _make_wall(half_width + 4.0, false)
	boss = BOSS.new() as Node2D
	boss.name = "Krakaren"
	boss.set("arena_left", global_position.x - half_width + 24.0)
	boss.set("arena_right", global_position.x + half_width - 24.0)
	add_child(boss)
	boss.position = Vector2(half_width - 60.0, 0.0)
	boss_arena = BOSS_ARENA.new() as Node2D
	boss_arena.name = "BossArena"
	boss_arena.set("boss_name", "Krakaren Clone")
	boss_arena.set("tooltip", "Level 10. A pyramid scheme with tentacles. Terms and conditions apply.")
	boss_arena.set("hud", get_parent().get_node_or_null("HUD"))
	boss_arena.set("intro_seconds", 1.2)
	boss_arena.set("card_seconds", 2.4)
	boss_arena.set("drop_tier", "Boss")
	boss_arena.set("drop_kit", "floor1")
	add_child(boss_arena)
	var locks: Array[CollisionShape2D] = [_lock_shape, _exit_shape]
	boss_arena.call("setup", boss, locks)
	boss_arena.connect("boss_defeated", _on_boss_defeated)
	_build_trigger()


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
	if started or not body.is_in_group("player"):
		return
	started = true
	boss_arena.call("start")


func _on_boss_defeated(_node: Node) -> void:
	SystemVoice.announce(DEFEAT_TITLE, DEFEAT_BODY, 4.0)
