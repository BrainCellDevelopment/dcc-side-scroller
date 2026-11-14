extends CharacterBody2D

signal died(enemy: Node)

enum State { PATROL, CHASE, ATTACK, DEAD }
enum AttackPhase { WINDUP, ACTIVE, COOLDOWN }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const Poison: GDScript = preload("res://scripts/combat/poison.gd")
const RAT_SHEET: Texture2D = preload("res://assets/characters/rat.png")
const SCATTERER_SHEET: Texture2D = preload("res://assets/characters/scatterer.png")
const FRAME: Vector2i = Vector2i(32, 32)
const RAT_ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 2, "fps": 4.0, "loop": true},
	"walk": {"row": 1, "count": 4, "fps": 12.0, "loop": true},
	"windup": {"row": 2, "count": 2, "fps": 8.0, "loop": false},
	"attack": {"row": 3, "count": 2, "fps": 12.0, "loop": false},
	"die": {"row": 4, "count": 4, "fps": 12.0, "loop": false},
}
const SCATTERER_ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 2, "fps": 5.0, "loop": true},
	"walk": {"row": 1, "count": 4, "fps": 12.0, "loop": true},
	"die": {"row": 2, "count": 3, "fps": 10.0, "loop": false},
}
const HEIGHT_TOLERANCE: float = 40.0
const KNOCKBACK: Vector2 = Vector2(100.0, -70.0)
const SWARM_INTERVAL: float = 2.4
const SCURRY_TIME: float = 0.8
const SCURRY_SPEED_MULT: float = 2.4
const ALERT_RANGE: float = 240.0
const ALERT_TIME: float = 5.0
const DROPLETS: int = 9
const DROP_COLOR: Color = Color(0.49, 0.69, 0.7, 1.0)

@export_enum("Rat", "Scatterer") var kind: int = 0
@export var enemy_level: int = 2
@export var xp_value: int = -1
@export var is_boss: bool = false
@export var max_health: int = 1
@export var speed: float = 40.0
@export var chase_speed: float = 120.0
@export var detect_range: float = 170.0
@export var attack_range: float = 15.0
@export var attack_damage: int = 1
@export var attack_windup: float = 0.2
@export var attack_active: float = 0.12
@export var attack_cooldown: float = 0.7
@export var patrol_distance: float = 40.0
@export var poisonous: bool = true

var health: int = 0
var state: State = State.PATROL
var attack_phase: AttackPhase = AttackPhase.WINDUP
var facing: int = 1
var spawn_x: float = 0.0
var state_timer: float = 0.0
var engaged: bool = false
var has_hit: bool = false
var gravity_force: float = 980.0
var sprite: AnimatedSprite2D = null
var flash_tween: Tween = null

var _swarm_timer: float = SWARM_INTERVAL
var _scurry_left: float = 0.0
var _alert_left: float = 0.0

@onready var visual: Node2D = $Visual
@onready var attack_area: Area2D = $Visual/AttackArea
@onready var attack_shape: CollisionShape2D = $Visual/AttackArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $Visual/LedgeCheck
@onready var health_bar: Node2D = $HealthBar


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	spawn_x = global_position.x
	if kind == 1:
		poisonous = false
		add_to_group("scatterers")
		sprite = SpriteUtil.make_sprite(SCATTERER_SHEET, FRAME, SCATTERER_ANIMS)
	else:
		sprite = SpriteUtil.make_sprite(RAT_SHEET, FRAME, RAT_ANIMS)
	sprite.name = "Sprite"
	visual.add_child(sprite)
	visual.move_child(sprite, 0)
	sprite.play("idle")
	attack_area.body_entered.connect(_on_attack_body_entered)
	_face(1 if randf() < 0.5 else -1)


func _exit_tree() -> void:
	_set_engaged(false)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y += gravity_force * delta
	_alert_left = maxf(_alert_left - delta, 0.0)
	_scurry_left = maxf(_scurry_left - delta, 0.0)
	var player: CharacterBody2D = _get_player()
	match state:
		State.PATROL:
			_patrol(player)
		State.CHASE:
			_chase(player, delta)
		State.ATTACK:
			_attack(delta)
	move_and_slide()
	_update_animation()


func take_damage(amount: int, from: Vector2) -> void:
	if state == State.DEAD:
		return
	health = maxi(health - amount, 0)
	health_bar.call("update_health", health, max_health)
	attack_shape.set_deferred("disabled", true)
	_flash()
	if health <= 0:
		_die()
		return
	var push: float = 1.0 if global_position.x >= from.x else -1.0
	velocity = Vector2(push * KNOCKBACK.x, KNOCKBACK.y)
	state = State.CHASE
	_set_engaged(true)


func alert() -> void:
	if state == State.DEAD:
		return
	_alert_left = ALERT_TIME
	if state == State.PATROL:
		_set_engaged(true)
		state = State.CHASE


func _patrol(player: CharacterBody2D) -> void:
	if player != null and (_sees(player, 1.0) or _alert_left > 0.0):
		_set_engaged(true)
		state = State.CHASE
		if kind == 1:
			_alert_swarm()
		return
	var offset: float = global_position.x - spawn_x
	if offset > patrol_distance:
		_face(-1)
	elif offset < -patrol_distance:
		_face(1)
	if _blocked_ahead():
		if absf(offset) > patrol_distance:
			spawn_x = global_position.x
		_face(-facing)
		if _blocked_ahead():
			velocity.x = 0.0
			return
	velocity.x = float(facing) * speed


func _chase(player: CharacterBody2D, delta: float) -> void:
	var reach: float = 2.0 if _alert_left > 0.0 else 1.25
	if player == null or not _sees(player, reach):
		_set_engaged(false)
		state = State.PATROL
		return
	var dx: float = player.global_position.x - global_position.x
	if absf(dx) > 2.0:
		_face(1 if dx > 0.0 else -1)
	if absf(dx) <= attack_range and is_on_floor():
		_start_attack()
		return
	var run: float = chase_speed
	if kind == 1:
		_swarm_timer -= delta
		if _swarm_timer <= 0.0:
			_swarm_timer = SWARM_INTERVAL
			_scurry_left = SCURRY_TIME
		if _scurry_left > 0.0:
			run = chase_speed * SCURRY_SPEED_MULT
	if _blocked_ahead() or absf(dx) <= 2.0:
		velocity.x = 0.0
	else:
		velocity.x = float(facing) * run


func _alert_swarm() -> void:
	for node: Node in get_tree().get_nodes_in_group("scatterers"):
		var other: Node2D = node as Node2D
		if other != null and other != self and other.global_position.distance_to(global_position) <= ALERT_RANGE:
			other.call("alert")


func _start_attack() -> void:
	state = State.ATTACK
	attack_phase = AttackPhase.WINDUP
	state_timer = attack_windup
	has_hit = false
	velocity.x = 0.0


func _attack(delta: float) -> void:
	velocity.x = 0.0
	state_timer -= delta
	match attack_phase:
		AttackPhase.WINDUP:
			if state_timer <= 0.0:
				attack_phase = AttackPhase.ACTIVE
				state_timer = attack_active
				attack_shape.set_deferred("disabled", false)
		AttackPhase.ACTIVE:
			for body: Node2D in attack_area.get_overlapping_bodies():
				_try_hit(body)
			if state_timer <= 0.0:
				attack_phase = AttackPhase.COOLDOWN
				state_timer = attack_cooldown
				attack_shape.set_deferred("disabled", true)
		AttackPhase.COOLDOWN:
			if state_timer <= 0.0:
				state = State.CHASE


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	body_shape.set_deferred("disabled", true)
	_set_engaged(false)
	PlayerStats.award_kill(self)
	died.emit(self)
	sprite.speed_scale = 1.0
	sprite.play("die")
	if kind == 0:
		_burst()
	var tween: Tween = create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func neutralise() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	attack_shape.set_deferred("disabled", true)
	_set_engaged(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _burst() -> void:
	for i: int in DROPLETS:
		var drop: ColorRect = ColorRect.new()
		drop.color = DROP_COLOR
		drop.size = Vector2(2.0, 2.0)
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drop.position = Vector2(randf_range(-6.0, 6.0), -10.0)
		add_child(drop)
		var angle: float = randf_range(-PI, 0.0)
		var target: Vector2 = drop.position + Vector2(cos(angle), sin(angle)) * randf_range(8.0, 22.0)
		var tween: Tween = drop.create_tween()
		tween.tween_property(drop, "position", target, 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "position:y", 0.0, 0.18).set_ease(Tween.EASE_IN)
		tween.tween_property(drop, "modulate:a", 0.0, 0.25)
		tween.tween_callback(drop.queue_free)


func _try_hit(body: Node2D) -> void:
	if Game.in_safe_zone:
		return
	if has_hit or state != State.ATTACK or attack_phase != AttackPhase.ACTIVE:
		return
	if body == null or not body.is_in_group("player") or not body.has_method("take_damage"):
		return
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return
	has_hit = true
	body.call("take_damage", attack_damage, global_position)
	if poisonous and int(body.get("health")) > 0:
		Poison.apply(body as CharacterBody2D)


func _on_attack_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _sees(player: CharacterBody2D, range_scale: float) -> bool:
	var delta_pos: Vector2 = player.global_position - global_position
	return absf(delta_pos.x) <= detect_range * range_scale and absf(delta_pos.y) <= HEIGHT_TOLERANCE


func _blocked_ahead() -> bool:
	if is_on_wall() and get_wall_normal().x * float(facing) < 0.0:
		return true
	if is_on_floor():
		ledge_check.force_raycast_update()
		return not ledge_check.is_colliding()
	return false


func _face(dir: int) -> void:
	facing = dir
	visual.scale.x = float(dir)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _play(anim: StringName, anim_speed: float = 1.0) -> void:
	var target: StringName = anim
	if not sprite.sprite_frames.has_animation(target):
		target = &"walk"
	sprite.speed_scale = anim_speed
	if sprite.animation != target:
		sprite.play(target)


func _update_animation() -> void:
	match state:
		State.PATROL, State.CHASE:
			if is_on_floor() and absf(velocity.x) > 5.0:
				_play(&"walk", clampf(absf(velocity.x) / 60.0, 0.7, 2.0))
			else:
				_play(&"idle")
		State.ATTACK:
			match attack_phase:
				AttackPhase.WINDUP:
					_play(&"windup")
				AttackPhase.ACTIVE:
					_play(&"attack")
				AttackPhase.COOLDOWN:
					_play(&"idle")


func _flash() -> void:
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	visual.modulate = Color(4.0, 4.0, 4.0, 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return null
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return null
	return player
