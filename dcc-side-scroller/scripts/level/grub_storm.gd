extends Node2D
## The grub storm (Level 2 beat 5): after the big fights the corridor fills with Brindle Grubs. While the
## player is inside the zone, waves of grubs spawn ahead of and behind them (capped), until the zone is
## crossed. Pupae mounds with flashing lights ring the walls. Grubs are ordinary enemies (dynamite and
## punches both work). Origin is the floor line at the zone's left edge.

const GRUB: PackedScene = preload("res://scenes/enemies/grub.tscn")
const WAVE_INTERVAL: float = 2.2
const MAX_ALIVE: int = 7
const MAX_TOTAL: int = 22
const SPAWN_AHEAD: float = 230.0
const SPAWN_BEHIND: float = 190.0
const EDGE_PAD: float = 64.0
const WAVE_SIZE: int = 2
const MOUND: Color = Color(0.78, 0.7, 0.62)
const MOUND_DARK: Color = Color(0.5, 0.42, 0.38)
const LIGHT: Color = Color(0.4, 0.9, 1.0)

@export var zone_length: float = 1024.0

var spawned: int = 0
var active: bool = false

var _timer: float = 1.0
var _clock: float = 0.0
var _flip: bool = false


func _ready() -> void:
	add_to_group("grub_storm")
	z_index = -1


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _physics_process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var rel: float = player.global_position.x - global_position.x
	active = rel >= EDGE_PAD and rel <= zone_length - EDGE_PAD and not Game.in_safe_zone
	if not active or spawned >= MAX_TOTAL:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = WAVE_INTERVAL
	for i: int in WAVE_SIZE:
		if alive_count() >= MAX_ALIVE:
			break
		_spawn(player.global_position.x)


func alive_count() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("grubs"):
		if is_instance_valid(node) and int(node.get("state")) != 3:
			count += 1
	return count


func _spawn(player_x: float) -> void:
	_flip = not _flip
	var x: float = player_x + (SPAWN_AHEAD if _flip else -SPAWN_BEHIND) + randf_range(-30.0, 30.0)
	x = clampf(x, global_position.x + 24.0, global_position.x + zone_length - 24.0)
	var grub: CharacterBody2D = GRUB.instantiate() as CharacterBody2D
	grub.name = "StormGrub%d" % spawned
	get_parent().add_child(grub)
	grub.global_position = Vector2(x, global_position.y - 2.0)
	grub.call("alert")
	spawned += 1


func _draw() -> void:
	var x: float = 40.0
	var index: int = 0
	while x < zone_length - 24.0:
		var w: float = 22.0 + float((index * 7) % 3) * 6.0
		var h: float = 20.0 + float((index * 5) % 4) * 5.0
		draw_rect(Rect2(x - w * 0.5, -h, w, h), MOUND)
		draw_rect(Rect2(x - w * 0.5, -h, w, 3.0), MOUND_DARK)
		draw_rect(Rect2(x - w * 0.5 + 2.0, -h * 0.6, w - 4.0, 2.0), MOUND_DARK)
		var on: bool = int(_clock * 2.0 + float(index)) % 2 == 0
		draw_circle(Vector2(x, -h * 0.5), 1.8, LIGHT if on else MOUND_DARK)
		x += 118.0 + float((index * 11) % 4) * 14.0
		index += 1
