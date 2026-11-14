extends CharacterBody2D
## The Hoarder (Level 1 neighborhood boss, Lv7). Stomp shockwave, roach vomit that
## spawns Scatterers, and a charge through the garbage piles. Hits are halved until
## the roach in her mouth is killed; that stuns her and opens a damage window.

signal defeated(boss: Node)

enum State { IDLE, WALK, STOMP_WIND, STOMP_SLAM, VOMIT, CHARGE_WIND, CHARGE, RECOVER, STUNNED, DEAD }
enum Attack { STOMP, VOMIT, CHARGE }

const SCATTERER: PackedScene = preload("res://scenes/enemies/scatterer.tscn")
const Roach: GDScript = preload("res://scripts/enemies/hoarder_roach.gd")
const Shockwave: GDScript = preload("res://scripts/enemies/hoarder_shockwave.gd")
const BOSS_NAME: String = "The Hoarder"
const ORDER: Array[int] = [Attack.STOMP, Attack.VOMIT, Attack.CHARGE, Attack.VOMIT, Attack.STOMP, Attack.VOMIT]
const WALK_TIME: float = 1.1
const STOMP_WINDUP: float = 0.75
const STOMP_RECOVER: float = 0.8
const WAVE_SPEED: float = 150.0
const WAVE_RANGE: float = 250.0
const SLAM_REACH: float = 36.0
const VOMIT_WINDUP: float = 0.5
const VOMIT_WINDOW: float = 2.4
const VOMIT_SPAWN: int = 2
const SPAWN_CAP: int = 4
const CHARGE_WINDUP: float = 0.8
const CHARGE_MAX: float = 1.4
const CHARGE_RECOVER: float = 1.2
const STUN_TIME: float = 3.5
const PILE_REACH: float = 34.0
const MOUTH_HIGH: Vector2 = Vector2(10.0, -50.0)
const MOUTH_LOW: Vector2 = Vector2(12.0, -51.0)
const ROACH_HINT: String = "Kill the roach in her mouth!"

@export var max_health: int = 40
@export var enemy_level: int = 7
@export var xp_value: int = -1
@export var is_boss: bool = true
@export var speed: float = 36.0
@export var charge_speed: float = 215.0
@export var stomp_damage: int = 1
@export var charge_damage: int = 2
@export var arena_left: float = 0.0
@export var arena_right: float = 0.0

var active: bool = false
var health: int = 0
var state: State = State.IDLE
var facing: int = -1
var state_timer: float = 0.0
var engaged: bool = false
var has_hit: bool = false
var order_index: int = 0
var current_attack: Attack = Attack.STOMP
var roach: Node2D = null
var roach_time: float = 0.0
var stuns: int = 0
var vomits: int = 0
var gravity_force: float = 980.0

var _roach_shown: bool = false
var _blocked_time: float = 0.0
var _flash_tween: Tween = null
var _hint_shown: bool = false

@onready var visual: Node2D = $Visual
@onready var attack_area: Area2D = $Visual/AttackArea
@onready var attack_shape: CollisionShape2D = $Visual/AttackArea/CollisionShape2D


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	visual.scale.x = float(facing)
	attack_area.body_entered.connect(_on_attack_body_entered)


func _exit_tree() -> void:
	_set_engaged(false)


func activate() -> void:
	if active or state == State.DEAD:
		return
	active = true
	state = State.IDLE
	state_timer = 0.7
	_set_engaged(true)
	Game.report_boss_health(BOSS_NAME, health, max_health)


func is_vulnerable() -> bool:
	return state == State.STUNNED


func mouth_position() -> Vector2:
	var offset: Vector2 = MOUTH_LOW if state == State.VOMIT else MOUTH_HIGH
	return global_position + Vector2(offset.x * float(facing), offset.y)


func take_damage(amount: int, _from: Vector2) -> void:
	if not active or state == State.DEAD:
		return
	var dealt: int = amount * 2 if state == State.STUNNED else maxi(ceili(float(amount) / 2.0), 1)
	health = maxi(health - dealt, 0)
	Game.report_boss_health(BOSS_NAME, health, max_health)
	if health <= 0:
		_die()
		return
	_flash()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity_force * delta
	if not active or state == State.DEAD:
		velocity.x = 0.0
		move_and_slide()
		return
	var player: CharacterBody2D = _get_player()
	state_timer -= delta
	match state:
		State.IDLE:
			_idle()
		State.WALK:
			_walk(player, delta)
		State.STOMP_WIND:
			_stomp_wind(player)
		State.STOMP_SLAM:
			_stomp_slam()
		State.VOMIT:
			_vomit(player, delta)
		State.CHARGE_WIND:
			_charge_wind(player)
		State.CHARGE:
			_charge()
		State.RECOVER:
			_recover()
		State.STUNNED:
			_stunned()
	move_and_slide()
	if arena_left != 0.0 or arena_right != 0.0:
		global_position.x = clampf(global_position.x, arena_left, arena_right)


func _idle() -> void:
	velocity.x = 0.0
	if state_timer <= 0.0:
		_begin_walk()


func _begin_walk() -> void:
	state = State.WALK
	state_timer = WALK_TIME
	_blocked_time = 0.0


func _walk(player: CharacterBody2D, delta: float) -> void:
	if player == null:
		velocity.x = 0.0
		return
	var dx: float = player.global_position.x - global_position.x
	_face_toward(dx)
	var close: bool = absf(dx) <= 70.0
	velocity.x = 0.0 if close else float(facing) * speed
	if _pile_ahead(PILE_REACH):
		_blocked_time += delta
		if _blocked_time > 0.35:
			_smash_piles_ahead()
	if state_timer <= 0.0 or close:
		_begin_attack()


func _begin_attack() -> void:
	current_attack = ORDER[order_index % ORDER.size()] as Attack
	order_index += 1
	velocity.x = 0.0
	match current_attack:
		Attack.STOMP:
			state = State.STOMP_WIND
			state_timer = STOMP_WINDUP * _pace()
			_pulse(state_timer)
		Attack.VOMIT:
			state = State.VOMIT
			state_timer = VOMIT_WINDUP
			roach = null
			_roach_shown = false
		Attack.CHARGE:
			state = State.CHARGE_WIND
			state_timer = CHARGE_WINDUP * _pace()
			_pulse(state_timer)


func _stomp_wind(player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if player != null:
		_face_toward(player.global_position.x - global_position.x)
	if state_timer > 0.0:
		return
	state = State.STOMP_SLAM
	state_timer = 0.25
	Game.shake(4.0, 0.3)
	for dir: float in [-1.0, 1.0]:
		var wave: Area2D = Shockwave.new() as Area2D
		wave.set("direction", dir)
		wave.set("speed", WAVE_SPEED * (1.2 if _is_enraged() else 1.0))
		wave.set("distance_left", WAVE_RANGE)
		wave.set("damage", stomp_damage)
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(dir * 22.0, 0.0)
	if player != null and absf(player.global_position.x - global_position.x) < SLAM_REACH and absf(player.global_position.y - global_position.y) < 22.0:
		_hurt_player(player, stomp_damage)


func _stomp_slam() -> void:
	velocity.x = 0.0
	if state_timer <= 0.0:
		_enter_recover(STOMP_RECOVER)


func _vomit(player: CharacterBody2D, _delta: float) -> void:
	velocity.x = 0.0
	if player != null:
		_face_toward(player.global_position.x - global_position.x)
	if not _roach_shown:
		if state_timer <= 0.0:
			_show_roach()
		return
	roach_time -= get_physics_process_delta_time()
	if roach_time <= 0.0:
		_roach_escapes()


func _show_roach() -> void:
	_roach_shown = true
	vomits += 1
	roach_time = VOMIT_WINDOW
	roach = Roach.new() as Node2D
	roach.connect("killed", _on_roach_killed)
	get_parent().add_child(roach)
	roach.global_position = mouth_position()
	if not _hint_shown:
		_hint_shown = true
		Game.set_hint(ROACH_HINT)


func _on_roach_killed(_node: Node) -> void:
	roach = null
	if state != State.VOMIT:
		return
	_clear_hint()
	stuns += 1
	state = State.STUNNED
	state_timer = STUN_TIME
	Game.shake(3.0, 0.2)
	_kill_flash()
	visual.modulate = Color(1.0, 0.9, 0.5, 1.0)


func _roach_escapes() -> void:
	var pos: Vector2 = mouth_position()
	if roach != null and is_instance_valid(roach):
		pos = roach.global_position
		roach.queue_free()
	roach = null
	_clear_hint()
	_spawn_scatterers(pos)
	_enter_recover(0.9)


func _spawn_scatterers(pos: Vector2) -> void:
	var alive: int = get_tree().get_nodes_in_group("hoarder_spawn").size()
	for i: int in VOMIT_SPAWN:
		if alive >= SPAWN_CAP:
			break
		var bug: CharacterBody2D = SCATTERER.instantiate() as CharacterBody2D
		bug.set("xp_value", 0)
		bug.add_to_group("hoarder_spawn")
		get_parent().add_child(bug)
		bug.global_position = pos + Vector2(float(facing) * float(i) * 6.0, 0.0)
		bug.velocity = Vector2(float(facing) * (60.0 + 40.0 * float(i)), -140.0)
		alive += 1


func _charge_wind(player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if player != null:
		_face_toward(player.global_position.x - global_position.x)
	if state_timer > 0.0:
		return
	state = State.CHARGE
	state_timer = CHARGE_MAX
	has_hit = false
	attack_shape.set_deferred("disabled", false)
	_kill_flash()
	visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _charge() -> void:
	velocity.x = float(facing) * charge_speed
	_smash_piles_ahead()
	for body: Node2D in attack_area.get_overlapping_bodies():
		_try_hit(body)
	var blocked: bool = is_on_wall() and get_wall_normal().x * float(facing) < 0.0
	if blocked or state_timer <= 0.0 or _at_arena_edge():
		attack_shape.set_deferred("disabled", true)
		if blocked or _at_arena_edge():
			Game.shake(4.0, 0.3)
		_enter_recover(CHARGE_RECOVER)


func _enter_recover(seconds: float) -> void:
	velocity.x = 0.0
	state = State.RECOVER
	state_timer = seconds * (0.7 if _is_enraged() else 1.0)


func _recover() -> void:
	velocity.x = 0.0
	if state_timer <= 0.0:
		_begin_walk()


func _stunned() -> void:
	velocity.x = 0.0
	if state_timer <= 0.0:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_enter_recover(0.5)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	attack_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	_kill_flash()
	visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_clear_hint()
	if roach != null and is_instance_valid(roach):
		roach.queue_free()
	roach = null
	for node: Node in get_tree().get_nodes_in_group("hoarder_spawn"):
		if node.has_method("neutralise"):
			node.call("neutralise")
	_set_engaged(false)
	PlayerStats.award_kill(self)
	Game.report_mob_kill(self)
	defeated.emit.call_deferred(self)


func _try_hit(body: Node2D) -> void:
	if has_hit or state != State.CHARGE:
		return
	if body == null or not body.is_in_group("player"):
		return
	has_hit = true
	_hurt_player(body, charge_damage)


func _on_attack_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _hurt_player(body: Node2D, amount: int) -> void:
	if Game.in_safe_zone or not body.has_method("take_damage"):
		return
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return
	body.call("take_damage", amount, global_position)


func _pile_ahead(reach: float) -> bool:
	for node: Node in get_tree().get_nodes_in_group("garbage_piles"):
		var pile: Node2D = node as Node2D
		if pile == null or bool(pile.get("smashed")):
			continue
		var ahead: float = (pile.global_position.x - global_position.x) * float(facing)
		if ahead > 0.0 and ahead < reach + float(pile.get("width")) * 0.5 and absf(pile.global_position.y - global_position.y) < 8.0:
			return true
	return false


func _smash_piles_ahead() -> void:
	for node: Node in get_tree().get_nodes_in_group("garbage_piles"):
		var pile: Node2D = node as Node2D
		if pile == null or bool(pile.get("smashed")):
			continue
		var ahead: float = (pile.global_position.x - global_position.x) * float(facing)
		if ahead > -4.0 and ahead < PILE_REACH + float(pile.get("width")) * 0.5 and absf(pile.global_position.y - global_position.y) < 8.0:
			pile.call("smash")


func _pace() -> float:
	return 0.8 if _is_enraged() else 1.0


func _is_enraged() -> bool:
	return health * 2 < max_health


func _at_arena_edge() -> bool:
	if arena_left == 0.0 and arena_right == 0.0:
		return false
	if facing > 0:
		return global_position.x >= arena_right - 0.5
	return global_position.x <= arena_left + 0.5


func _face_toward(dx: float) -> void:
	if absf(dx) < 1.0:
		return
	facing = 1 if dx > 0.0 else -1
	visual.scale.x = float(facing)


func _clear_hint() -> void:
	Game.set_hint("")


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _pulse(seconds: float) -> void:
	_kill_flash()
	_flash_tween = create_tween()
	_flash_tween.set_loops(2)
	_flash_tween.tween_property(visual, "modulate", Color(3.0, 2.2, 1.6, 1.0), seconds * 0.25)
	_flash_tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), seconds * 0.25)


func _flash() -> void:
	_kill_flash()
	var rest: Color = Color(1.0, 0.9, 0.5, 1.0) if state == State.STUNNED else Color(1.0, 1.0, 1.0, 1.0)
	visual.modulate = Color(4.0, 4.0, 4.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", rest, 0.15)


func _kill_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return null
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return null
	return player
