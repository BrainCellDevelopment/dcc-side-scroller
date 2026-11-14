extends Node2D
## Wires the Hoarder's lair in Level 1 (#60): boss arena lock and intro, the Spanish-signed
## sealed door (opened only by dynamite), the map reward, achievements and the grief line.
## Sibling nodes are looked up by the names the generator gives them (section_hoarder.py).

const BOSS_ARENA: GDScript = preload("res://scripts/level/boss_arena.gd")
const BOSS_NAME: String = "The Hoarder"
const TOOLTIP: String = "Level 7. She kept everything. Nothing kept her."
const GRIEF_TITLE: String = "THE HOARDER"
const GRIEF_BODY: String = "Her name was on a mailbox once. The System kept the mailbox and threw away the rest."
const GRIEF_DELAY: float = 1.4
const GRIEF_SECONDS: float = 6.0
const NOTICE_LINES: String = "AVISO\nSANIDAD\nCLAUSURADO"
const LOCK_PAD: float = 12.0

var arena: Node2D = null
var boss: Node2D = null
var door: Node2D = null


func _ready() -> void:
	var level: Node = get_parent()
	boss = level.get_node("Bosses/Hoarder") as Node2D
	door = level.get_node("Doors/HoarderDoor") as Node2D
	var start: Area2D = level.get_node("Triggers/HoarderStart") as Area2D
	var lock_a: StaticBody2D = level.get_node("Walls/HoarderLockA") as StaticBody2D
	var lock_b: StaticBody2D = level.get_node("Walls/HoarderLockB") as StaticBody2D
	var locks: Array[CollisionShape2D] = [lock_a.get_node("CollisionShape2D") as CollisionShape2D, lock_b.get_node("CollisionShape2D") as CollisionShape2D]
	var left: float = minf(lock_a.global_position.x, lock_b.global_position.x)
	var right: float = maxf(lock_a.global_position.x, lock_b.global_position.x)
	boss.set("arena_left", left + LOCK_PAD)
	boss.set("arena_right", right - LOCK_PAD)
	arena = BOSS_ARENA.new() as Node2D
	arena.set("boss_name", BOSS_NAME)
	arena.set("tooltip", TOOLTIP)
	arena.set("announcement", GRIEF_TITLE)
	arena.set("hud", level.get_node_or_null("HUD"))
	arena.set("intro_seconds", 1.0)
	arena.set("drop_tier", "Boss")
	arena.set("drop_kit", "floor1")
	arena.set("map_reward", true)
	add_child(arena)
	arena.call("setup", boss, locks)
	arena.connect("boss_defeated", _on_boss_defeated)
	start.body_entered.connect(_on_start_entered)
	_add_notice()


func _add_notice() -> void:
	var paper: ColorRect = ColorRect.new()
	paper.color = Color("c8b692")
	paper.position = Vector2(-7.0, -100.0)
	paper.size = Vector2(14.0, 20.0)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(paper)
	var text: Label = Label.new()
	text.text = NOTICE_LINES
	text.add_theme_font_size_override("font_size", 4)
	text.add_theme_color_override("font_color", Color("4a1c20"))
	text.position = Vector2(1.0, 1.0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(text)


func _on_start_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		arena.call("start")


func _on_boss_defeated(_node: Node) -> void:
	SystemVoice.fire("neighborhood_boss")
	SystemVoice.fire("map_upgrade")
	await get_tree().create_timer(GRIEF_DELAY).timeout
	SystemVoice.announce(GRIEF_TITLE, GRIEF_BODY, GRIEF_SECONDS)
