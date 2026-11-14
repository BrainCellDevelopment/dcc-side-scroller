extends CharacterBody2D
## Ralph, the Frenzied Gerbil (Level 2 boss, Lv11): a fist-sized gerbil with a dog-sized mouth when he
## screams. He skitters around the pit, dashes across it (telegraphed) and screams rockets at your throat.
## After a dash that ends against the wall he is dizzy: stomp or punch him then (hits count double).

signal defeated(boss: Node)

enum State { IDLE, SKITTER, DASH_WIND, DASH, SCREAM_WIND, SCREAM, RECOVER, STUNNED, DEAD }
enum Attack { DASH, SCREAM }

const ROCK_SCENE: PackedScene = preload("res://scenes/enemies/rock.tscn")
const BOSS_NAME: String = "Ralph, the Frenzied Gerbil"
const ORDER: Array[int] = [Attack.DASH, Attack.SCREAM, Attack.DASH, Attack.SCREAM, Attack.SCREAM]
const SKITTER_TIME: float = 1.0
const DASH_WINDUP: float = 0.75
const DASH_SPEED: float = 250.0
const DASH_MAX: float = 2.6
const DASH_DAMAGE: int = 2
const SCREAM_WINDUP: float = 0.7
const SCREAM_RECOVER: float = 1.0
const ROCKETS: int = 3
const ROCKET_SPEED: float = 210.0
const STUN_TIME: float = 2.8
const BODY: Color = Color(0.78, 0.6, 0.38)
const BODY_DARK: Color = Color(0.5, 0.36, 0.22)
const BODY_LIGHT: Color = Color(0.94, 0.8, 0.6)
const MOUTH_COLOR: Color = Color(0.32, 0.04, 0.1)
const STAR: Color = Color(1.0, 0.9, 0.3)

@export var max_health: int = 24
@export var enemy_level: int = 11
@export var xp_value: int = -1
@export var is_boss: bool = true
@export var speed: float = 80.0
@export var arena_left: float = 0.0
@export var arena_right: float = 0.0

var active: bool = false
var health: int = 0
var state: State = State.IDLE
var facing: int = -1
var engaged: bool = false
var order_index: int = 0
var current_attack: Attack = Attack.DASH

var _timer: float = 0.0
var _clock: float = 0.0
var _flash: float = 0.0
var _hit_this_dash: bool = false
var _fade: float = 1.0
var _gravity: float = 980.0


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	collision_layer = 12
	collision_mask = 1
	add_to_group("enemies")
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(20.0, 14.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -7.0)
	add_child(shape)
	z_index = 4


func _exit_tree() -> void:
	_set_engaged(false)


func activate() -> void:
	if active or state == State.DEAD:
		return
	active = true
	state = State.SKITTER
	_timer = 0.8
	_set_engaged(true)
	Game.report_boss_health(BOSS_NAME, health, max_health)


func is_dead() -> bool:
	return state == State.DEAD


func is_vulnerable() -> bool:
	return state == State.STUNNED


func take_damage(amount: int, _from: Vector2) -> void:
	if not active or state == State.DEAD:
		return
	var dealt: int = amount * 2 if state == State.STUNNED else maxi(ceili(float(amount) / 2.0), 1)
	health = maxi(health - dealt, 0)
	_flash = 0.15
	Game.report_boss_health(BOSS_NAME, health, max_health)
	if health <= 0:
		_die()


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	if not is_on_floor():
		velocity.y += _gravity * delta
	if not active or state == State.DEAD:
		move_and_slide()
		queue_redraw()
		return
	var player: CharacterBody2D = _get_player()
	_timer -= delta
	match state:
		State.SKITTER:
			_skitter(player)
		State.DASH_WIND:
			velocity.x = 0.0
			_face_player(player)
			if _timer <= 0.0:
				state = State.DASH
				_timer = DASH_MAX
				_hit_this_dash = false
		State.DASH:
			_dash(player)
		State.SCREAM_WIND:
			velocity.x = 0.0
			_face_player(player)
			if _timer <= 0.0:
				_scream(player)
		State.SCREAM, State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_skitter()
		State.STUNNED:
			velocity.x = 0.0
			if _timer <= 0.0:
				_begin_skitter()
	move_and_slide()
	queue_redraw()


func _begin_skitter() -> void:
	state = State.SKITTER
	_timer = SKITTER_TIME


func _skitter(player: CharacterBody2D) -> void:
	if player != null:
		var dx: float = player.global_position.x - global_position.x
		_face(1 if dx > 0.0 else -1)
		velocity.x = float(facing) * speed * (1.0 if absf(dx) > 70.0 else -0.6)
	else:
		velocity.x = 0.0
	global_position.x = clampf(global_position.x, arena_left, arena_right)
	if _timer <= 0.0:
		current_attack = ORDER[order_index % ORDER.size()] as Attack
		order_index += 1
		if current_attack == Attack.DASH:
			state = State.DASH_WIND
			_timer = DASH_WINDUP
		else:
			state = State.SCREAM_WIND
			_timer = SCREAM_WINDUP


func _dash(player: CharacterBody2D) -> void:
	velocity.x = float(facing) * DASH_SPEED
	if player != null and not _hit_this_dash and not Game.in_safe_zone:
		var offset: Vector2 = player.global_position - global_position
		if absf(offset.x) <= 14.0 and offset.y > -22.0 and offset.y < 8.0:
			_hit_this_dash = true
			player.call("take_damage", DASH_DAMAGE, global_position)
	var at_edge: bool = (facing < 0 and global_position.x <= arena_left + 2.0) or (facing > 0 and global_position.x >= arena_right - 2.0)
	if at_edge:
		global_position.x = clampf(global_position.x, arena_left, arena_right)
		Game.shake(2.0, 0.2)
		state = State.STUNNED
		_timer = STUN_TIME
		velocity.x = 0.0
	elif _timer <= 0.0:
		state = State.RECOVER
		_timer = 0.6


func _scream(player: CharacterBody2D) -> void:
	state = State.SCREAM
	_timer = SCREAM_RECOVER
	var holder: Node = get_tree().current_scene
	if player == null or holder == null or Game.in_safe_zone:
		return
	var origin: Vector2 = global_position + Vector2(float(facing) * 10.0, -10.0)
	var aim: Vector2 = (player.global_position + Vector2(0.0, -24.0) - origin).normalized()
	for i: int in ROCKETS:
		var angle: float = aim.angle() + (float(i) - 1.0) * 0.17
		var rocket: Area2D = ROCK_SCENE.instantiate() as Area2D
		holder.add_child(rocket)
		rocket.global_position = origin
		rocket.set("fall_gravity", 0.0)
		rocket.scale = Vector2(1.5, 1.5)
		rocket.modulate = Color(1.0, 0.6, 0.3)
		rocket.call("launch", Vector2(cos(angle), sin(angle)) * ROCKET_SPEED, 1)
	Game.shake(1.5, 0.15)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	_set_engaged(false)
	PlayerStats.award_kill(self)
	var tween: Tween = create_tween()
	tween.tween_property(self, "_fade", 0.0, 0.9)
	defeated.emit.call_deferred(self)


func _face(dir: int) -> void:
	facing = dir


func _face_player(player: CharacterBody2D) -> void:
	if player != null:
		_face(1 if player.global_position.x > global_position.x else -1)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player) or bool(player.call("is_dead")):
		return null
	return player


func _draw() -> void:
	var f: float = float(facing)
	var a: float = _fade
	var wobble: float = sin(_clock * 28.0) * (1.5 if state == State.DASH_WIND else 0.0)
	var fur: Color = Color(1.7, 1.5, 1.2, a) if _flash > 0.0 else Color(BODY.r, BODY.g, BODY.b, a)
	var crouch: float = 2.0 if state == State.DASH_WIND else 0.0
	# tail
	draw_line(Vector2(-9.0 * f, -5.0), Vector2(-17.0 * f, -9.0), Color(BODY_DARK.r, BODY_DARK.g, BODY_DARK.b, a), 2.0)
	# body
	draw_circle(Vector2(wobble, -8.0 + crouch), 9.0, fur)
	draw_circle(Vector2(wobble - 1.0 * f, -4.0 + crouch), 6.0, Color(BODY_LIGHT.r, BODY_LIGHT.g, BODY_LIGHT.b, a))
	# head
	var head: Vector2 = Vector2(8.0 * f + wobble, -12.0 + crouch)
	draw_circle(head, 6.0, fur)
	draw_circle(head + Vector2(-2.0 * f, -6.0), 2.4, Color(BODY_DARK.r, BODY_DARK.g, BODY_DARK.b, a))
	var eye: Color = Color(0.1, 0.04, 0.06, a)
	if state == State.STUNNED:
		draw_string(ThemeDB.fallback_font, head + Vector2(-5.0, -8.0), "* *", HORIZONTAL_ALIGNMENT_CENTER, 12.0, 7, Color(STAR.r, STAR.g, STAR.b, a))
	else:
		draw_circle(head + Vector2(2.0 * f, -2.0), 1.4, eye)
		draw_circle(head + Vector2(2.4 * f, -2.4), 0.5, Color(1.0, 1.0, 1.0, a))
	# the mouth: tiny normally, enormous when he screams
	var open: float = 1.5
	if state == State.SCREAM_WIND:
		open = 2.0 + 12.0 * (1.0 - clampf(_timer / SCREAM_WINDUP, 0.0, 1.0))
	elif state == State.SCREAM:
		open = 14.0
	draw_circle(head + Vector2(5.0 * f, 2.0), open, Color(MOUTH_COLOR.r, MOUTH_COLOR.g, MOUTH_COLOR.b, a))
	if open > 6.0:
		draw_circle(head + Vector2(5.0 * f, 4.0 + open * 0.2), open * 0.4, Color(0.8, 0.3, 0.4, a))
