extends CharacterBody2D

signal died(enemy: Node)

enum State { SLEEP, WAKE, PATROL, CHASE, WINDUP, SPIT, HURT, DEAD }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/characters/llama.png")
const BALL_SCENE: PackedScene = preload("res://scenes/enemies/lava_ball.tscn")
const PUDDLE_SCENE: PackedScene = preload("res://scenes/level/lava_puddle.tscn")
const SPARK_SCENE: PackedScene = preload("res://scenes/fx/hit_spark.tscn")
const FRAME: Vector2i = Vector2i(72, 56)
const ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true},
	"walk": {"row": 1, "count": 6, "fps": 9.0, "loop": true},
	"windup": {"row": 2, "count": 3, "fps": 6.0, "loop": false},
	"spit": {"row": 3, "count": 2, "fps": 8.0, "loop": false},
	"hurt": {"row": 4, "count": 1, "fps": 1.0, "loop": false},
	"die": {"row": 5, "count": 4, "fps": 8.0, "loop": false},
	"sleep": {"row": 6, "count": 2, "fps": 1.5, "loop": true},
	"wake": {"row": 7, "count": 2, "fps": 4.0, "loop": false},
}
const SPIT_WINDUP: float = 0.8
const SPIT_ACTIVE: float = 0.3
const SPIT_INTERVAL: float = 2.6
const SPIT_RANGE_X: float = 250.0
const SPIT_RANGE_Y: float = 110.0
const BALL_SPEED_MAX: float = 360.0
const MOUTH: Vector2 = Vector2(30.0, -40.0)
const KEEP_DISTANCE: float = 70.0
const APPROACH_DISTANCE: float = 160.0
const HURT_TIME: float = 0.22
const KNOCKBACK: Vector2 = Vector2(70.0, -50.0)
const WAKE_TIME: float = 0.9
const WAKE_PROXIMITY: float = 64.0
const WAKE_CAST_RANGE: float = 380.0
const WAKE_CAST_DELAY: float = 0.45
const HEAD_HIT_HEIGHT: float = 20.0
const HEAD_HIT_FRONT: float = 14.0
const THROAT_BONUS_XP: int = 25
const PLATE_RANGE: float = 240.0
const PLATE_SECONDS: float = 4.0
const AWAKE_SIZE: Vector2 = Vector2(34.0, 32.0)
const LYING_SIZE: Vector2 = Vector2(38.0, 20.0)

@export var enemy_level: int = 3
@export var xp_value: int = -1
@export var is_boss: bool = false
@export var max_health: int = 6
@export var speed: float = 34.0
@export var chase_speed: float = 55.0
@export var detect_range: float = 260.0
@export var sight_height: float = 70.0
@export var spit_damage: int = 1
@export var patrol_distance: float = 40.0
@export var dormant: bool = false
@export var display_name: String = "BAD LLAMA"

var health: int = 0
var state: State = State.PATROL
var facing: int = -1
var spawn_x: float = 0.0
var state_timer: float = 0.0
var spit_cooldown: float = 1.0
var engaged: bool = false
var throat_open: bool = false
var ruptured: bool = false
var gravity_force: float = 980.0
var sprite: AnimatedSprite2D = null
var flash_tween: Tween = null

var _wake_delay: float = -1.0
var _plate: Label = null
var _plate_shown: bool = false

@onready var visual: Node2D = $Visual
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $Visual/LedgeCheck
@onready var health_bar: Node2D = $HealthBar


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	health = max_health
	spawn_x = global_position.x
	body_shape.shape = (body_shape.shape as RectangleShape2D).duplicate()
	sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	sprite.name = "Sprite"
	visual.add_child(sprite)
	visual.move_child(sprite, 0)
	_make_plate()
	_face(facing)
	if dormant:
		state = State.SLEEP
		_set_lying(true)
		sprite.play("sleep")
		Game.spell_cast.connect(_on_spell_cast)
	else:
		sprite.play("idle")


func _exit_tree() -> void:
	_set_engaged(false)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y += gravity_force * delta
	spit_cooldown = maxf(spit_cooldown - delta, 0.0)
	var player: CharacterBody2D = _get_player()
	_update_plate(player)
	match state:
		State.SLEEP:
			_sleep(delta, player)
		State.WAKE:
			_wake(delta)
		State.PATROL:
			_patrol(player)
		State.CHASE:
			_chase(player)
		State.WINDUP:
			_windup(delta, player)
		State.SPIT:
			_spit(delta)
		State.HURT:
			_hurt(delta, player)
	move_and_slide()
	_update_animation()


func is_dead() -> bool:
	return state == State.DEAD


func is_asleep() -> bool:
	return state == State.SLEEP


func wake_up() -> void:
	if state != State.SLEEP:
		return
	state = State.WAKE
	state_timer = WAKE_TIME
	_set_lying(false)
	Game.shake(1.5, 0.2)
	_show_plate()


func take_damage(amount: int, from: Vector2) -> void:
	if state == State.DEAD:
		return
	var was_asleep: bool = state == State.SLEEP
	if was_asleep:
		wake_up()
	if not was_asleep and _is_throat_hit(from):
		_rupture()
		return
	health = maxi(health - amount, 0)
	health_bar.call("update_health", health, max_health)
	_flash()
	if health <= 0:
		_die()
		return
	if was_asleep or state == State.WAKE:
		return
	var push: float = 1.0 if global_position.x >= from.x else -1.0
	velocity = Vector2(push * KNOCKBACK.x, KNOCKBACK.y)
	throat_open = false
	state = State.HURT
	state_timer = HURT_TIME


func neutralise() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	_set_engaged(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _is_throat_hit(from: Vector2) -> bool:
	if state == State.WINDUP or state == State.SPIT:
		return true
	var rel: Vector2 = from - global_position
	return rel.y <= -HEAD_HIT_HEIGHT and rel.x * float(facing) >= HEAD_HIT_FRONT


func _sleep(delta: float, player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if _wake_delay >= 0.0:
		_wake_delay -= delta
		if _wake_delay < 0.0:
			wake_up()
			return
	if player != null:
		var offset: Vector2 = player.global_position - global_position
		if absf(offset.x) <= WAKE_PROXIMITY and absf(offset.y) <= 40.0:
			wake_up()


func _wake(delta: float) -> void:
	velocity.x = 0.0
	var player: CharacterBody2D = _get_player()
	if player != null:
		_face_toward(player)
	state_timer -= delta
	if state_timer <= 0.0:
		spit_cooldown = 0.5
		_set_engaged(true)
		state = State.CHASE


func _patrol(player: CharacterBody2D) -> void:
	if player != null and _sees(player, 1.0, sight_height):
		_set_engaged(true)
		state = State.CHASE
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
	velocity.x = float(facing) * speed * 0.6


func _chase(player: CharacterBody2D) -> void:
	if player == null or not _sees(player, 1.4, sight_height * 1.5):
		_set_engaged(false)
		state = State.PATROL
		velocity.x = 0.0
		return
	var dx: float = player.global_position.x - global_position.x
	var dy: float = player.global_position.y - global_position.y
	_face_toward(player)
	if spit_cooldown <= 0.0 and absf(dx) <= SPIT_RANGE_X and absf(dy) <= SPIT_RANGE_Y and is_on_floor() and not Game.in_safe_zone:
		_start_windup()
		return
	var away: float = -float(facing)
	if absf(dx) < KEEP_DISTANCE and is_on_floor():
		velocity.x = 0.0 if _blocked_behind() else away * speed
	elif absf(dx) > APPROACH_DISTANCE and not _blocked_ahead():
		velocity.x = float(facing) * chase_speed
	else:
		velocity.x = 0.0


func _start_windup() -> void:
	state = State.WINDUP
	state_timer = SPIT_WINDUP
	throat_open = true
	velocity.x = 0.0


func _windup(delta: float, player: CharacterBody2D) -> void:
	velocity.x = 0.0
	if player != null:
		_face_toward(player)
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.SPIT
		state_timer = SPIT_ACTIVE
		_spit_ball()


func _spit(delta: float) -> void:
	velocity.x = 0.0
	state_timer -= delta
	if state_timer <= 0.0:
		throat_open = false
		spit_cooldown = maxf(SPIT_INTERVAL - SPIT_WINDUP - SPIT_ACTIVE, 0.2)
		state = State.CHASE


func _hurt(delta: float, player: CharacterBody2D) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	if state_timer > 0.0:
		return
	if player != null:
		_set_engaged(true)
		state = State.CHASE
	else:
		_set_engaged(false)
		state = State.PATROL


func _spit_ball() -> void:
	if Game.in_safe_zone:
		return
	var player: CharacterBody2D = _get_player()
	var holder: Node = get_tree().current_scene
	if player == null or holder == null:
		return
	var origin: Vector2 = visual.to_global(MOUTH)
	var target: Vector2 = player.global_position + Vector2(0.0, -14.0)
	var ball: Area2D = BALL_SCENE.instantiate() as Area2D
	holder.add_child(ball)
	ball.global_position = origin
	var g: float = float(ball.get("fall_gravity"))
	var offset: Vector2 = target - origin
	var flight: float = clampf(offset.length() / 280.0, 0.4, 1.0)
	var launch_velocity: Vector2 = Vector2(offset.x / flight, offset.y / flight - 0.5 * g * flight)
	if launch_velocity.length() > BALL_SPEED_MAX:
		launch_velocity = launch_velocity.normalized() * BALL_SPEED_MAX
	ball.call("launch", launch_velocity, spit_damage)


func _rupture() -> void:
	ruptured = true
	var at: Vector2 = visual.to_global(Vector2(14.0, -34.0))
	for i: int in 3:
		var spark: Node2D = SPARK_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(spark)
		spark.global_position = at + Vector2(float(i - 1) * 7.0, float(i % 2) * -6.0)
	Game.shake(3.0, 0.25)
	health = 0
	health_bar.call("update_health", 0, max_health)
	var paid: int = _die()
	if paid > 0:
		PlayerStats.add_xp(THROAT_BONUS_XP)
	_float_text("THROAT SHOT!" if paid <= 0 else "THROAT SHOT!  +%d XP" % (paid + THROAT_BONUS_XP), at)
	_drop_puddle()


func _drop_puddle() -> void:
	var puddle: Area2D = PUDDLE_SCENE.instantiate() as Area2D
	puddle.set("width", 32.0)
	puddle.set("lifetime", 4.0)
	puddle.position = global_position + Vector2(-16.0 + float(facing) * 14.0, 0.0)
	get_tree().current_scene.add_child.call_deferred(puddle)


func _die() -> int:
	state = State.DEAD
	throat_open = false
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	body_shape.set_deferred("disabled", true)
	_set_engaged(false)
	var paid: int = PlayerStats.award_kill(self)
	died.emit(self)
	sprite.speed_scale = 1.0
	sprite.modulate = Color.WHITE
	sprite.play("die")
	if _plate != null:
		_plate.visible = false
	var tween: Tween = create_tween()
	tween.tween_interval(0.9)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
	return paid


func _on_spell_cast() -> void:
	if state != State.SLEEP or _wake_delay >= 0.0:
		return
	var player: CharacterBody2D = _get_player()
	if player == null:
		return
	var offset: Vector2 = global_position - player.global_position
	if absf(offset.x) <= WAKE_CAST_RANGE and absf(offset.y) <= 90.0:
		_wake_delay = WAKE_CAST_DELAY


func _make_plate() -> void:
	_plate = Label.new()
	_plate.name = "Plate"
	_plate.text = "%s  LV %d\nSpits lava. Throat is soft." % [display_name, enemy_level]
	_plate.add_theme_font_size_override("font_size", 12)
	_plate.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_plate.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.04))
	_plate.add_theme_constant_override("outline_size", 3)
	_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate.position = Vector2(-70.0, -86.0)
	_plate.custom_minimum_size = Vector2(140.0, 0.0)
	_plate.z_index = 60
	_plate.modulate.a = 0.0
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)


func _update_plate(player: CharacterBody2D) -> void:
	if _plate_shown or player == null:
		return
	if absf(player.global_position.x - global_position.x) <= PLATE_RANGE and absf(player.global_position.y - global_position.y) <= 120.0:
		_show_plate()


func _show_plate() -> void:
	if _plate_shown or _plate == null:
		return
	_plate_shown = true
	var tween: Tween = create_tween()
	tween.tween_property(_plate, "modulate:a", 1.0, 0.3)
	tween.tween_interval(PLATE_SECONDS)
	tween.tween_property(_plate, "modulate:a", 0.0, 0.6)


func _float_text(text: String, at: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.04))
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 60
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(label)
	label.global_position = at + Vector2(-40.0, -22.0)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 18.0, 1.4)
	tween.tween_property(label, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tween.chain().tween_callback(label.queue_free)


func _set_lying(lying: bool) -> void:
	var rect: RectangleShape2D = body_shape.shape as RectangleShape2D
	rect.size = LYING_SIZE if lying else AWAKE_SIZE
	body_shape.position = Vector2(0.0, -rect.size.y * 0.5)


func _sees(player: CharacterBody2D, range_scale: float, height: float) -> bool:
	var delta_pos: Vector2 = player.global_position - global_position
	return absf(delta_pos.x) <= detect_range * range_scale and absf(delta_pos.y) <= height


func _blocked_ahead() -> bool:
	if is_on_wall() and get_wall_normal().x * float(facing) < 0.0:
		return true
	if is_on_floor():
		ledge_check.force_raycast_update()
		return not ledge_check.is_colliding()
	return false


func _blocked_behind() -> bool:
	if is_on_wall() and get_wall_normal().x * float(facing) > 0.0:
		return true
	if not is_on_floor():
		return false
	var ahead_x: float = absf(ledge_check.position.x)
	ledge_check.position.x = -ahead_x
	ledge_check.force_raycast_update()
	var found: bool = ledge_check.is_colliding()
	ledge_check.position.x = ahead_x
	ledge_check.force_raycast_update()
	return not found


func _face(dir: int) -> void:
	facing = dir
	visual.scale.x = float(dir)


func _face_toward(player: CharacterBody2D) -> void:
	var dx: float = player.global_position.x - global_position.x
	if absf(dx) > 2.0:
		_face(1 if dx > 0.0 else -1)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _play(anim: StringName, anim_speed: float = 1.0) -> void:
	sprite.speed_scale = anim_speed
	if sprite.animation != anim:
		sprite.play(anim)


func _update_animation() -> void:
	var pulse: bool = false
	match state:
		State.SLEEP:
			_play(&"sleep")
		State.WAKE:
			_play(&"wake")
		State.PATROL, State.CHASE:
			if is_on_floor() and absf(velocity.x) > 5.0:
				_play(&"walk", clampf(absf(velocity.x) / 40.0, 0.7, 1.6))
			else:
				_play(&"idle")
		State.WINDUP:
			_play(&"windup", (3.0 / 6.0) / SPIT_WINDUP)
			pulse = true
		State.SPIT:
			_play(&"spit", (2.0 / 8.0) / SPIT_ACTIVE)
		State.HURT:
			_play(&"hurt")
	if pulse:
		var t: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.03)
		sprite.modulate = Color(1.0, 1.0 - 0.3 * t, 1.0 - 0.55 * t, 1.0)
	elif sprite.modulate != Color.WHITE:
		sprite.modulate = Color.WHITE


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
