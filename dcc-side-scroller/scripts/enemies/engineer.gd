extends CharacterBody2D

signal defeated(engineer: Node)

enum State { IDLE, APPROACH, WINDUP, DASH, HOP, RECOVER, HURT, DEFEATED }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/characters/engineer.png")
const FRAME: Vector2i = Vector2i(40, 40)
const ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true},
	"walk": {"row": 1, "count": 6, "fps": 10.0, "loop": true},
	"windup": {"row": 2, "count": 3, "fps": 8.0, "loop": false},
	"dash": {"row": 3, "count": 2, "fps": 14.0, "loop": true},
	"crouch": {"row": 4, "count": 2, "fps": 10.0, "loop": false},
	"air": {"row": 5, "count": 1, "fps": 1.0, "loop": false},
	"recover": {"row": 6, "count": 2, "fps": 4.0, "loop": true},
	"hurt": {"row": 7, "count": 1, "fps": 1.0, "loop": false},
	"defeated": {"row": 8, "count": 3, "fps": 6.0, "loop": false},
}
const BOSS_NAME: String = "Goblin Engineer"
const APPROACH_DISTANCE: float = 60.0
const APPROACH_TIMEOUT: float = 1.5
const DASH_TIME: float = 0.35
const DASH_WINDUP: float = 0.4
const DASH_WINDUP_FAST: float = 0.3
const HOP_CROUCH: float = 0.2
const HOP_CHANCE: float = 0.4
const RECOVER_TIME: float = 0.7
const RECOVER_TIME_FAST: float = 0.5
const HURT_TIME: float = 0.15
const MAX_STAGGERS: int = 3
## After any hit, stomps are ignored for this long, so a bounce cannot chain stomps into a cheap stun-lock.
const STOMP_LOCK: float = 0.8

@export var max_health: int = 12
@export var speed: float = 95.0
@export var dash_speed: float = 260.0
@export var hop_velocity: float = -280.0
@export var attack_damage: int = 1
@export var arena_left: float = 0.0
@export var arena_right: float = 0.0

var active: bool = false
var scripted: bool = false
var health: int = 0
var state: State = State.IDLE
var facing: int = 1
var state_timer: float = 0.0
var resume_recover: float = 0.0
var stagger_count: int = 0
var _stomp_lock: float = 0.0
var engaged: bool = false
var has_hit: bool = false
var attack_enabled: bool = false
var pending_hop: bool = false
var hop_airborne: bool = false
var gravity_force: float = 980.0
var sprite: AnimatedSprite2D = null
var windup_scale: float = 1.0
var pose_hold: String = ""
var flash_tween: Tween = null

@onready var visual: Node2D = $Visual
@onready var attack_area: Area2D = $Visual/AttackArea
@onready var attack_shape: CollisionShape2D = $Visual/AttackArea/CollisionShape2D


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	sprite.name = "Sprite"
	visual.add_child(sprite)
	visual.move_child(sprite, 0)
	sprite.play("idle")
	attack_area.body_entered.connect(_on_attack_body_entered)


func _exit_tree() -> void:
	_set_engaged(false)


func activate() -> void:
	if active or state == State.DEFEATED:
		return
	active = true
	pose_hold = ""
	state = State.IDLE
	state_timer = 0.5
	_set_engaged(true)
	Game.report_boss_health(BOSS_NAME, health, max_health)


## Carl landing on the Engineer's head only counts as a stomp while this is true (see player._slide_off_enemies).
func can_be_stomped() -> bool:
	return active and state != State.DEFEATED and _stomp_lock <= 0.0


func take_damage(amount: int, from: Vector2) -> void:
	if not active or state == State.DEFEATED:
		return
	_stomp_lock = STOMP_LOCK
	health = maxi(health - amount, 0)
	Game.report_boss_health(BOSS_NAME, health, max_health)
	if health <= 0:
		_defeat()
		return
	if state != State.DASH and stagger_count < MAX_STAGGERS:
		stagger_count += 1
		if state == State.RECOVER:
			resume_recover = maxf(state_timer, 0.0)
		elif state != State.HURT:
			resume_recover = 0.0
		_set_attack_enabled(false)
		_reset_pose()
		var push: float = -float(facing)
		if global_position.x > from.x:
			push = 1.0
		elif global_position.x < from.x:
			push = -1.0
		velocity.x = push * 140.0
		if is_on_floor():
			velocity.y = -60.0
		state = State.HURT
		state_timer = HURT_TIME
	_flash()


func set_pose(pose: String) -> void:
	if sprite == null or not sprite.sprite_frames.has_animation(pose):
		push_warning("Engineer.set_pose: unknown pose " + pose)
		return
	pose_hold = pose
	sprite.speed_scale = 1.0
	sprite.play(pose)


func _physics_process(delta: float) -> void:
	if scripted:
		return
	_stomp_lock = maxf(_stomp_lock - delta, 0.0)
	if not is_on_floor():
		velocity.y += gravity_force * delta
	if not active or state == State.DEFEATED:
		velocity.x = 0.0
		move_and_slide()
		_update_animation()
		return
	var player: CharacterBody2D = _get_player()
	state_timer -= delta
	match state:
		State.IDLE:
			_idle(player)
		State.APPROACH:
			_approach(player)
		State.WINDUP:
			_windup(player)
		State.DASH:
			_dash()
		State.HOP:
			_hop()
		State.RECOVER:
			_recover()
		State.HURT:
			_hurt(delta)
	move_and_slide()
	_update_animation()
	if _has_arena():
		global_position.x = clampf(global_position.x, arena_left, arena_right)


func _idle(player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if state_timer <= 0.0 and player != null:
		state = State.APPROACH
		state_timer = APPROACH_TIMEOUT


func _approach(player: CharacterBody2D) -> void:
	if player == null:
		velocity.x = 0.0
		state = State.IDLE
		state_timer = 0.3
		return
	var dx: float = player.global_position.x - global_position.x
	_face_toward(dx)
	var in_range: bool = absf(dx) <= APPROACH_DISTANCE + 4.0
	if in_range:
		velocity.x = 0.0
	else:
		velocity.x = float(facing) * speed
	if is_on_floor() and (in_range or state_timer <= 0.0):
		_begin_windup()


func _begin_windup() -> void:
	velocity.x = 0.0
	pending_hop = randf() < HOP_CHANCE
	state = State.WINDUP
	if pending_hop:
		state_timer = HOP_CROUCH
		windup_scale = (2.0 / 10.0) / HOP_CROUCH
		return
	state_timer = DASH_WINDUP_FAST if _is_enraged() else DASH_WINDUP
	windup_scale = (3.0 / 8.0) / state_timer
	_kill_tween(flash_tween)
	flash_tween = create_tween()
	flash_tween.set_loops(2)
	flash_tween.tween_property(visual, "modulate", Color(3.0, 3.0, 2.0, 1.0), state_timer * 0.25)
	flash_tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), state_timer * 0.25)


func _windup(player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if state_timer > 0.0:
		return
	_reset_pose()
	if player == null:
		_enter_recover()
	elif pending_hop:
		_start_hop(player)
	else:
		_start_dash()


func _start_dash() -> void:
	has_hit = false
	state = State.DASH
	state_timer = DASH_TIME
	velocity.x = float(facing) * dash_speed
	_set_attack_enabled(true)


func _dash() -> void:
	velocity.x = float(facing) * dash_speed
	_check_hits()
	var blocked: bool = is_on_wall() and get_wall_normal().x * float(facing) < 0.0
	if state_timer <= 0.0 or blocked or _at_arena_edge():
		_enter_recover()


func _start_hop(player: CharacterBody2D) -> void:
	var dx: float = player.global_position.x - global_position.x
	_face_toward(dx)
	var air_time: float = maxf(2.0 * absf(hop_velocity) / gravity_force, 0.1)
	var target: float = dx - float(facing) * 10.0
	velocity.x = clampf(target / air_time, -dash_speed, dash_speed)
	velocity.y = hop_velocity
	has_hit = false
	hop_airborne = false
	state = State.HOP
	state_timer = 1.5


func _hop() -> void:
	if not is_on_floor():
		hop_airborne = true
	if hop_airborne and velocity.y > 0.0 and not attack_enabled:
		_set_attack_enabled(true)
	_check_hits()
	if (hop_airborne and is_on_floor()) or state_timer <= 0.0:
		_enter_recover()


func _enter_recover() -> void:
	_set_attack_enabled(false)
	_reset_pose()
	velocity.x = 0.0
	stagger_count = 0
	resume_recover = 0.0
	state = State.RECOVER
	state_timer = RECOVER_TIME_FAST if _is_enraged() else RECOVER_TIME


func _recover() -> void:
	velocity.x = 0.0
	if state_timer <= 0.0:
		state = State.APPROACH
		state_timer = APPROACH_TIMEOUT


func _hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if state_timer > 0.0:
		return
	if resume_recover > 0.0:
		state = State.RECOVER
		state_timer = resume_recover
		resume_recover = 0.0
	else:
		state = State.APPROACH
		state_timer = APPROACH_TIMEOUT


func _defeat() -> void:
	state = State.DEFEATED
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_set_attack_enabled(false)
	_reset_pose()
	_flash()
	_set_engaged(false)
	defeated.emit(self)


func _check_hits() -> void:
	if not attack_enabled or has_hit:
		return
	for body: Node2D in attack_area.get_overlapping_bodies():
		_try_hit(body)


func _try_hit(body: Node2D) -> void:
	if not attack_enabled or has_hit or not active:
		return
	if state != State.DASH and state != State.HOP:
		return
	if body == null or not body.is_in_group("player") or not body.has_method("take_damage"):
		return
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return
	has_hit = true
	body.call("take_damage", attack_damage, global_position)


func _on_attack_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _set_attack_enabled(value: bool) -> void:
	attack_enabled = value
	attack_shape.set_deferred("disabled", not value)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _is_enraged() -> bool:
	return health * 2 < max_health


func _has_arena() -> bool:
	return arena_left != 0.0 or arena_right != 0.0


func _at_arena_edge() -> bool:
	if not _has_arena():
		return false
	if facing > 0:
		return global_position.x >= arena_right - 0.5
	return global_position.x <= arena_left + 0.5


func _face_toward(dx: float) -> void:
	if absf(dx) < 1.0:
		return
	facing = 1 if dx > 0.0 else -1
	visual.scale.x = float(facing)


func _reset_pose() -> void:
	_kill_tween(flash_tween)
	visual.rotation = 0.0
	visual.scale = Vector2(float(facing), 1.0)
	visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_animation() -> void:
	if pose_hold != "":
		return
	match state:
		State.IDLE:
			_play(&"idle")
		State.APPROACH:
			if is_on_floor() and absf(velocity.x) > 5.0:
				_play(&"walk")
			else:
				_play(&"idle")
		State.WINDUP:
			_play(&"crouch" if pending_hop else &"windup", windup_scale)
		State.DASH:
			_play(&"dash")
		State.HOP:
			_play(&"air" if not is_on_floor() else &"crouch")
		State.RECOVER:
			_play(&"recover")
		State.HURT:
			_play(&"hurt")
		State.DEFEATED:
			_play(&"defeated")


func _play(anim: StringName, anim_speed: float = 1.0) -> void:
	sprite.speed_scale = anim_speed
	if sprite.animation != anim:
		sprite.play(anim)


func _flash() -> void:
	_kill_tween(flash_tween)
	visual.modulate = Color(4.0, 4.0, 4.0, 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return null
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return null
	return player
