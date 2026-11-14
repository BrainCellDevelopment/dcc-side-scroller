extends CharacterBody2D

signal died
signal attacked

const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.1
const HURT_STUN_TIME: float = 0.2
const JUMP_CUT: float = 0.45
const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const HIT_SPARK: PackedScene = preload("res://scenes/fx/hit_spark.tscn")
const DUST: PackedScene = preload("res://scenes/fx/dust.tscn")
const CARL_SHEET: Texture2D = preload("res://assets/characters/carl.png")
const FRAME: Vector2i = Vector2i(80, 80)
const ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 8, "fps": 10.0, "loop": true},
	"run": {"row": 1, "count": 8, "fps": 16.0, "loop": true},
	"jump": {"row": 2, "count": 1, "fps": 1.0, "loop": false},
	"fall": {"row": 3, "count": 1, "fps": 1.0, "loop": false},
	"punch": {"row": 4, "count": 8, "fps": 44.0, "loop": false},
	"hurt": {"row": 5, "count": 3, "fps": 15.0, "loop": false},
	"die": {"row": 6, "count": 8, "fps": 8.0, "loop": false},
}
const DUST_COOLDOWN: float = 0.18
const LAND_SPEED: float = 140.0

@export var speed: float = 130.0
@export var acceleration: float = 1100.0
@export var friction: float = 1400.0
@export var jump_velocity: float = -330.0
@export var max_health: int = 10
@export var attack_damage: int = 1
@export var attack_time: float = 0.32
@export var attack_cooldown: float = 0.42
@export var knockback: Vector2 = Vector2(160.0, -140.0)

var health: int = 0
var control_enabled: bool = true
var facing: int = 1

var _dead: bool = false
var _jumping: bool = false
var _attacking: bool = false
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _hurt_left: float = 0.0
var _attack_left: float = 0.0
var _cooldown_left: float = 0.0
var _hit_bodies: Array[Node2D] = []
var _blink_tween: Tween = null
var _gravity: float = 980.0
var _body: AnimatedSprite2D = null
var _dust_left: float = 0.0
var _was_on_floor: bool = true
var _prev_vy: float = 0.0
var _standstill: bool = true

@onready var _visual: Node2D = $Visual
@onready var _attack_area: Area2D = $Visual/AttackArea
@onready var _attack_shape: CollisionShape2D = $Visual/AttackArea/CollisionShape2D
@onready var _invuln_timer: Timer = $InvulnTimer


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	_body = SpriteUtil.make_sprite(CARL_SHEET, FRAME, ANIMS)
	_body.name = "Body"
	_visual.add_child(_body)
	_visual.move_child(_body, 0)
	_body.play("idle")
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_area_body_entered)
	_invuln_timer.timeout.connect(_on_invuln_timeout)
	Game.report_player_health(health, max_health)


func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote_left = COYOTE_TIME
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)
		velocity.y += _gravity * delta
	if velocity.y >= 0.0:
		_jumping = false

	_hurt_left = maxf(_hurt_left - delta, 0.0)
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)

	var can_act: bool = control_enabled and not _dead
	if can_act and _hurt_left <= 0.0:
		_handle_input(delta)
	elif _hurt_left <= 0.0 or _dead:
		_jump_buffer_left = 0.0
		if on_floor or _dead:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_update_attack(delta)
	_prev_vy = velocity.y
	move_and_slide()
	_slide_off_enemies()
	_update_fx(delta)
	_update_animation()


func _slide_off_enemies() -> void:
	for i: int in get_slide_collision_count():
		var c: KinematicCollision2D = get_slide_collision(i)
		var other: Node2D = c.get_collider() as Node2D
		if other != null and other.is_in_group("enemies") and c.get_normal().y < -0.5:
			var away: float = signf(global_position.x - other.global_position.x)
			if is_zero_approx(away):
				away = -float(facing)
			velocity = Vector2(away * 110.0, -140.0)
			return


func take_damage(amount: int, from: Vector2) -> void:
	if _dead or amount <= 0 or not _invuln_timer.is_stopped():
		return
	health = maxi(health - amount, 0)
	Game.report_player_health(health, max_health)
	var direction: float = signf(global_position.x - from.x)
	if is_zero_approx(direction):
		direction = -float(facing)
	velocity = Vector2(knockback.x * direction, knockback.y)
	_jumping = false
	_hurt_left = HURT_STUN_TIME
	Game.shake(2.0, 0.12)
	if health <= 0:
		_die()
		return
	_invuln_timer.start()
	_start_blink()


func bounce(strength: float = 260.0) -> void:
	velocity.y = -strength
	_jumping = false


func kill() -> void:
	if _dead:
		return
	health = 0
	Game.report_player_health(health, max_health)
	velocity = Vector2(0.0, minf(velocity.y, 0.0))
	_hurt_left = 0.0
	_die()


func is_dead() -> bool:
	return _dead


func _handle_input(delta: float) -> void:
	var axis: float = Input.get_axis("move_left", "move_right")
	if is_zero_approx(axis):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, axis * speed, acceleration * delta)
		_set_facing(1 if axis > 0.0 else -1)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = JUMP_BUFFER_TIME
	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_jumping = true
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	elif _jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= JUMP_CUT
		_jumping = false

	if Input.is_action_just_pressed("attack") and _cooldown_left <= 0.0 and not _attacking:
		_start_attack()


func _set_facing(direction: int) -> void:
	if direction == facing:
		return
	facing = direction
	_visual.scale.x = float(facing)


func _start_attack() -> void:
	_attacking = true
	_attack_left = attack_time
	_cooldown_left = attack_cooldown
	_hit_bodies.clear()
	_attack_shape.set_deferred("disabled", false)
	_punch()
	attacked.emit()


func _update_attack(delta: float) -> void:
	if not _attacking:
		return
	if _dead:
		_end_attack()
		return
	# Overlaps only appear a physics frame after the shape is enabled, so poll as well as listening to body_entered.
	for body: Node2D in _attack_area.get_overlapping_bodies():
		_try_hit(body)
	_attack_left -= delta
	if _attack_left <= 0.0:
		_end_attack()


func _end_attack() -> void:
	_attacking = false
	_attack_left = 0.0
	_attack_shape.set_deferred("disabled", true)
	_hit_bodies.clear()


func _try_hit(body: Node2D) -> void:
	if not _attacking or _dead:
		return
	if body == self or not is_instance_valid(body):
		return
	if _hit_bodies.has(body):
		return
	if not body.has_method("take_damage"):
		return
	_hit_bodies.append(body)
	body.call("take_damage", attack_damage, global_position)
	_spawn_fx(HIT_SPARK, _visual.to_global(Vector2(24.0, -22.0)))


func _punch() -> void:
	_body.speed_scale = (8.0 / 44.0) / maxf(attack_time, 0.01)
	_body.play("punch")
	_body.frame = 0
	_body.frame_progress = 0.0


func _play(anim: StringName, anim_speed: float = 1.0) -> void:
	_body.speed_scale = anim_speed
	if _body.animation != anim:
		_body.play(anim)


func _update_animation() -> void:
	if _dead:
		return
	if _hurt_left > 0.0:
		_play(&"hurt")
	elif _attacking:
		if _body.animation != &"punch":
			_punch()
	elif not is_on_floor():
		_play(&"jump" if velocity.y < 0.0 else &"fall")
	elif absf(velocity.x) > 12.0:
		_play(&"run", clampf(absf(velocity.x) / maxf(speed, 1.0), 0.5, 1.3))
	else:
		_play(&"idle")


func _update_fx(delta: float) -> void:
	_dust_left = maxf(_dust_left - delta, 0.0)
	var on_floor: bool = is_on_floor()
	var spd: float = absf(velocity.x)
	if on_floor and not _was_on_floor and _prev_vy > LAND_SPEED:
		_spawn_dust()
	if not on_floor:
		_standstill = false
	elif spd < 15.0:
		_standstill = true
	elif _standstill and spd > 35.0 and control_enabled and not _dead:
		_standstill = false
		_spawn_dust()
	_was_on_floor = on_floor


func _spawn_dust() -> void:
	if _dust_left > 0.0:
		return
	_dust_left = DUST_COOLDOWN
	_spawn_fx(DUST, global_position + Vector2(-float(facing) * 2.0, -5.0))


func _spawn_fx(scene: PackedScene, pos: Vector2) -> void:
	var holder: Node = get_tree().current_scene
	if holder == null:
		return
	var fx: Node2D = scene.instantiate() as Node2D
	holder.add_child(fx)
	fx.global_position = pos


func _start_blink() -> void:
	_stop_blink()
	_blink_tween = create_tween()
	_blink_tween.set_loops()
	_blink_tween.tween_property(_visual, "modulate:a", 0.25, 0.07)
	_blink_tween.tween_property(_visual, "modulate:a", 1.0, 0.07)


func _stop_blink() -> void:
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = null
	_visual.modulate.a = 1.0


func _die() -> void:
	if _dead:
		return
	_dead = true
	control_enabled = false
	_stop_blink()
	_end_attack()
	_body.speed_scale = 1.0
	_body.play("die")
	died.emit()


func _on_attack_area_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _on_invuln_timeout() -> void:
	_stop_blink()
