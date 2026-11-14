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
const DUST_COOLDOWN: float = 0.18
const LAND_SPEED: float = 140.0
const STOMP_MIN_FALL: float = 40.0
const SAFE_SPOT_INTERVAL: float = 0.25
const SAFE_SPOT_COUNT: int = 4

@export var speed: float = 130.0
@export var sprint_multiplier: float = 1.5
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 40.0
@export var stamina_regen_delay: float = 0.5
@export var stamina_exhaust_recover: float = 30.0
@export var sprint_drain: float = 22.0
@export var max_mana: float = 10.0
@export var mana_regen: float = 1.5
@export var mana_regen_delay: float = 1.0
@export var spell_cost: float = 3.0
@export var missile_count: int = 1
@export var missile_damage: int = 1
@export var spell_enabled: bool = false
@export var jump_cost: float = 10.0
@export var attack_cost: float = 12.0
@export var acceleration: float = 1100.0
@export var friction: float = 1400.0
@export var jump_velocity: float = -330.0
@export var max_health: int = 10
@export var attack_damage: int = 1
@export var stomp_damage: int = 1
@export var stomp_bounce: float = 250.0
@export var attack_time: float = 0.32
@export var attack_cooldown: float = 0.42
@export var knockback: Vector2 = Vector2(160.0, -140.0)

const MISSILE_SCENE: PackedScene = preload("res://scenes/combat/magic_missile.tscn")
const CAST_FLASH: PackedScene = preload("res://scenes/fx/magic_impact.tscn")
const SPELL_COOLDOWN: float = 0.35
const CAST_ORIGIN: Vector2 = Vector2(3.0, -47.0)
const SPELL_RANGE: float = 280.0
const SPELL_ARC: float = 75.0
const MISSILE_FAN: float = 0.3
const Targeting: GDScript = preload("res://scripts/combat/targeting.gd")

var health: int = 0
var stamina: float = 0.0
var control_enabled: bool = true
var facing: int = 1

var _dead: bool = false
var mana: float = 0.0
var _mana_delay: float = 0.0
var _mana_shown: int = -1
var _spell_cooldown: float = 0.0
var _exhausted: bool = false
var _stamina_delay: float = 0.0
var _stamina_shown: int = -1
var _safe_spots: Array[Vector2] = []
var _safe_spot_timer: float = 0.0
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
	max_health += PlayerStats.max_health() - PlayerStats.BASE_HEALTH
	health = Game.take_carried_health(max_health)
	stamina = max_stamina
	_body = SpriteUtil.make_sprite(Game.skin_sheet(), Game.skin_frame(), Game.skin_anims())
	_body.name = "Body"
	_body.scale = Vector2.ONE * Game.skin_scale()
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_visual.add_child(_body)
	_visual.move_child(_body, 0)
	_body.play("idle")
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_area_body_entered)
	_invuln_timer.timeout.connect(_on_invuln_timeout)
	Game.god_mode_changed.connect(_on_god_mode_changed)
	Game.report_player_health(health, max_health)
	_report_stamina()


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

	_regen_stamina(delta)
	_regen_mana(delta)
	_track_safe_spot(delta, on_floor)
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
			if _prev_vy >= STOMP_MIN_FALL and other.has_method("take_damage"):
				_stomp(other)
				return
			var away: float = signf(global_position.x - other.global_position.x)
			if is_zero_approx(away):
				away = -float(facing)
			velocity = Vector2(away * 110.0, -140.0)
			return


func _stomp(enemy: Node2D) -> void:
	enemy.call("take_damage", stomp_damage, global_position)
	var holding_jump: bool = Input.is_action_pressed("jump")
	velocity.y = jump_velocity * 0.85 if holding_jump else -stomp_bounce
	_jumping = holding_jump
	_coyote_left = 0.0
	_spawn_fx(HIT_SPARK, global_position + Vector2(0.0, -2.0))


func take_damage(amount: int, from: Vector2) -> void:
	if Game.god_mode or _dead or amount <= 0 or not _invuln_timer.is_stopped():
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


func kill(force: bool = false) -> void:
	if _dead:
		return
	if Game.god_mode and not force:
		_rescue()
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
		var top_speed: float = speed
		if Input.is_action_pressed("sprint") and not _exhausted:
			top_speed *= sprint_multiplier
			_drain_stamina(sprint_drain * delta)
		velocity.x = move_toward(velocity.x, axis * top_speed, acceleration * delta)
		_set_facing(1 if axis > 0.0 else -1)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = JUMP_BUFFER_TIME
	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		if _spend_stamina(jump_cost):
			velocity.y = jump_velocity
			_jumping = true
			_coyote_left = 0.0
		_jump_buffer_left = 0.0
	elif _jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= JUMP_CUT
		_jumping = false

	if Input.is_action_just_pressed("attack") and _cooldown_left <= 0.0 and not _attacking:
		if _spend_stamina(attack_cost):
			_start_attack()
	if Input.is_action_just_pressed("spell"):
		_try_cast()


func enable_spell() -> void:
	spell_enabled = true
	mana = max_mana
	_mana_shown = -1
	_report_mana()


func _try_cast() -> void:
	if not spell_enabled or _dead or _spell_cooldown > 0.0:
		return
	if not _spend_mana(spell_cost):
		return
	_spell_cooldown = SPELL_COOLDOWN
	Game.report_spell_cast()
	var origin: Vector2 = global_position + Vector2(float(facing) * CAST_ORIGIN.x, CAST_ORIGIN.y)
	var anchor_offset: Vector2 = Vector2(float(facing) * CAST_ORIGIN.x, CAST_ORIGIN.y)
	var flash: Node2D = CAST_FLASH.instantiate() as Node2D
	flash.scale = Vector2.ONE * 0.45
	flash.position = anchor_offset
	add_child(flash)
	var forward: Vector2 = Vector2(float(facing), 0.0)
	var aim: float = forward.angle()
	var target: Node2D = Targeting.nearest(origin, forward, get_tree().get_nodes_in_group("enemies"), SPELL_RANGE, SPELL_ARC)
	if target != null:
		aim = (target.global_position + Targeting.AIM_OFFSET - origin).angle()
	for index: int in missile_count:
		var fan: float = 0.0
		if missile_count > 1:
			fan = lerpf(-MISSILE_FAN, MISSILE_FAN, float(index) / float(missile_count - 1))
		var missile: Area2D = MISSILE_SCENE.instantiate() as Area2D
		missile.set("damage", missile_damage)
		missile.set("anchor", self)
		missile.set("anchor_offset", anchor_offset)
		missile.position = origin
		missile.call("fire", Vector2.from_angle(aim + fan))
		get_parent().add_child(missile)


func _spend_mana(cost: float) -> bool:
	if Game.god_mode:
		return true
	if mana < cost:
		Game.deny_mana()
		return false
	mana -= cost
	_mana_delay = mana_regen_delay
	_report_mana()
	return true


func _regen_mana(delta: float) -> void:
	_spell_cooldown = maxf(_spell_cooldown - delta, 0.0)
	if not spell_enabled:
		return
	if Game.god_mode:
		mana = max_mana
		_report_mana()
		return
	_mana_delay = maxf(_mana_delay - delta, 0.0)
	if _mana_delay > 0.0 or mana >= max_mana:
		return
	mana = minf(mana + mana_regen * delta, max_mana)
	_report_mana()


func _report_mana() -> void:
	if not spell_enabled:
		return
	var shown: int = roundi(mana)
	if shown == _mana_shown:
		return
	_mana_shown = shown
	Game.report_player_mana(shown, roundi(max_mana))


func _spend_stamina(cost: float) -> bool:
	if Game.god_mode:
		return true
	if stamina < cost:
		Game.deny_stamina()
		return false
	stamina -= cost
	_stamina_delay = stamina_regen_delay
	_report_stamina()
	return true


func _drain_stamina(amount: float) -> void:
	if Game.god_mode:
		return
	stamina = maxf(stamina - amount, 0.0)
	_stamina_delay = stamina_regen_delay
	if stamina <= 0.0:
		_exhausted = true
		Game.deny_stamina()
	_report_stamina()


func _regen_stamina(delta: float) -> void:
	if Game.god_mode:
		stamina = max_stamina
		_exhausted = false
		_report_stamina()
		return
	_stamina_delay = maxf(_stamina_delay - delta, 0.0)
	if _stamina_delay > 0.0 or stamina >= max_stamina:
		return
	stamina = minf(stamina + stamina_regen * delta, max_stamina)
	if _exhausted and stamina >= stamina_exhaust_recover and not Input.is_action_pressed("sprint"):
		_exhausted = false
	_report_stamina()


func _track_safe_spot(delta: float, on_floor: bool) -> void:
	if not on_floor or _dead:
		return
	_safe_spot_timer -= delta
	if _safe_spot_timer > 0.0:
		return
	_safe_spot_timer = SAFE_SPOT_INTERVAL
	_safe_spots.append(global_position)
	if _safe_spots.size() > SAFE_SPOT_COUNT:
		_safe_spots.remove_at(0)


func _rescue() -> void:
	if not _safe_spots.is_empty():
		global_position = _safe_spots[0]
		reset_physics_interpolation()
	velocity = Vector2.ZERO


func _on_god_mode_changed(active: bool) -> void:
	if not active:
		return
	health = max_health
	stamina = max_stamina
	mana = max_mana
	_exhausted = false
	Game.report_player_health(health, max_health)
	_report_stamina()
	_report_mana()


func _report_stamina() -> void:
	var shown: int = roundi(stamina)
	if shown == _stamina_shown:
		return
	_stamina_shown = shown
	Game.report_player_stamina(shown, roundi(max_stamina))


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
	body.call("take_damage", attack_damage + PlayerStats.damage_bonus(), global_position)
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
		_play(&"run", clampf(absf(velocity.x) / maxf(speed, 1.0), 0.5, sprint_multiplier + 0.1))
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
