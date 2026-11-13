extends AnimatableBody2D

signal round_cleared(round_number: int)
signal destroyed
signal vulnerable_changed(is_vulnerable: bool)
signal pass_finished
signal turn_finished

enum State { PARKED, IDLE, TELEGRAPH, LUNGE, HOLD, RETREAT, STALLED, DESTROYED, VENT, PASS, TURN }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const TRACKS_TEX: Texture2D = preload("res://assets/boss/dozer_tracks.png")
const WHEEL_TEX: Texture2D = preload("res://assets/boss/dozer_wheel.png")
const HATCH_TEX: Texture2D = preload("res://assets/boss/dozer_hatch.png")
const DRIVER_TEX: Texture2D = preload("res://assets/boss/dozer_driver.png")
const SPARK_FX: PackedScene = preload("res://scenes/fx/hit_spark.tscn")
const STEAM_FX: PackedScene = preload("res://scenes/fx/steam_puff.tscn")
const DUST_FX: PackedScene = preload("res://scenes/fx/dust.tscn")
const EXPLOSION_FX: PackedScene = preload("res://scenes/fx/explosion.tscn")

const TRACKS_FRAME: Vector2i = Vector2i(88, 16)
const WHEEL_FRAME: Vector2i = Vector2i(28, 28)
const HATCH_FRAME: Vector2i = Vector2i(40, 24)
const DRIVER_FRAME: Vector2i = Vector2i(24, 24)
const TRACKS_ANIMS: Dictionary = {"run": {"row": 0, "count": 4, "fps": 12.0, "loop": true}}
const WHEEL_ANIMS: Dictionary = {"spin": {"row": 0, "count": 6, "fps": 14.0, "loop": true}}
const HATCH_ANIMS: Dictionary = {
	"closed": {"row": 0, "count": 1, "fps": 1.0, "loop": false},
	"opening": {"row": 1, "count": 3, "fps": 14.0, "loop": false},
	"open": {"row": 2, "count": 3, "fps": 8.0, "loop": true},
}
const DRIVER_ANIMS: Dictionary = {"idle": {"row": 0, "count": 2, "fps": 6.0, "loop": true}}
const TRACKS_POS: Vector2 = Vector2(-10.0, 0.0)
const WHEEL_POS: Vector2 = Vector2(44.0, 0.0)
const HATCH_POS: Vector2 = Vector2(-12.0, -27.0)
const DRIVER_POS: Vector2 = Vector2(21.0, -30.0)
const STACK_TOP: Vector2 = Vector2(-43.0, -62.0)
const VENT_POINT: Vector2 = Vector2(-12.0, -38.0)
const DUST_POINT: Vector2 = Vector2(-50.0, -3.0)
const BLAST_POINTS: Array[Vector2] = [Vector2(-40.0, -32.0), Vector2(20.0, -40.0), Vector2(40.0, -14.0), Vector2(-10.0, -20.0)]

const BOSS_NAME: String = "Goblin Murder Dozer"
const ROUNDS: int = 3
const LUNGES: Array[int] = [2, 3, 4]
const HATCH_TIMES: Array[float] = [4.5, 4.0, 3.5]
const SCROLL_SPEEDS: Array[float] = [60.0, 80.0, 100.0]
const IDLE_TIMES: Array[float] = [2.2, 1.8, 1.4]
const HOLD_TIMES: Array[float] = [1.1, 0.9, 0.7]
const LUNGE_OFFSETS: Array[float] = [190.0, 220.0, 250.0]
const IDLE_OFFSET: float = 10.0
const STALL_OFFSET: float = -90.0
const TELEGRAPH_TIME: float = 0.6
const STALL_TIME: float = 1.6
const STOMP_MIN_HEIGHT: float = 26.0
const LAND_WINDOW: float = 0.12
const PASS_SPEED: float = 560.0
const CREEP_SPEED: float = 150.0
const TURN_PAUSE: float = 0.7
const TURN_WARN: float = 1.0
const BEAM_POLYGON: PackedVector2Array = [Vector2(54.0, -30.0), Vector2(190.0, -62.0), Vector2(190.0, -2.0)]

@export var contact_damage: int = 2
@export var max_scroll_x: float = 14000.0

var scroll_x: float = 0.0
var state: State = State.PARKED
var round_index: int = 0
var vulnerable: bool = false

var _offset: float = IDLE_OFFSET
var _timer: float = 0.0
var _base_y: float = 0.0
var _lunges_done: int = 0
var _driver_present: bool = false
var _was_on_floor: bool = false
var _land_timer: float = 0.0
var _bounce_cooldown: float = 0.0
var _steam_timer: float = 0.3
var _vent_timer: float = 0.0
var _dust_timer: float = 0.1
var _pass_to: float = 0.0
var _stop_x: float = 0.0
var _turn_stage: int = 0
var _rumble_timer: float = 0.0
var _beam: Polygon2D
var _player: CharacterBody2D
var _tracks: AnimatedSprite2D
var _wheel: AnimatedSprite2D
var _hatch: AnimatedSprite2D
var _driver: AnimatedSprite2D

@onready var _visual: Node2D = $Visual
@onready var _deck: CollisionShape2D = $Deck
@onready var _wheel_area: Area2D = $WheelArea
@onready var _grinder_area: Area2D = $GrinderArea
@onready var _stomp_zone: Area2D = $StompZone


func _ready() -> void:
	_tracks = _add_sprite("Tracks", TRACKS_TEX, TRACKS_FRAME, TRACKS_ANIMS, TRACKS_POS)
	_hatch = _add_sprite("Hatch", HATCH_TEX, HATCH_FRAME, HATCH_ANIMS, HATCH_POS)
	_driver = _add_sprite("Driver", DRIVER_TEX, DRIVER_FRAME, DRIVER_ANIMS, DRIVER_POS)
	_wheel = _add_sprite("Wheel", WHEEL_TEX, WHEEL_FRAME, WHEEL_ANIMS, WHEEL_POS)
	_driver.visible = _driver_present
	_beam = Polygon2D.new()
	_beam.polygon = BEAM_POLYGON
	_beam.color = Color(1.0, 0.95, 0.55, 0.4)
	_beam.visible = false
	_visual.add_child(_beam)
	_deck.set_deferred("disabled", true)
	_tracks.play("run")
	_hatch.play("closed")
	_driver.play("idle")
	_wheel.play("spin")
	_hatch.animation_finished.connect(_on_hatch_animation_finished)


func set_driver(present: bool) -> void:
	_driver_present = present
	if _driver != null:
		_driver.visible = present


func roar_pass(from_x: float, to_x: float, player: CharacterBody2D) -> void:
	_player = player
	_base_y = global_position.y
	global_position.x = from_x
	_pass_to = to_x
	_rumble_timer = 0.0
	_visual.scale.x = -1.0 if to_x < from_x else 1.0
	_visual.modulate = Color(0.78, 0.78, 0.86)
	z_index = -1
	visible = true
	state = State.PASS


func turn_around(stop_x: float) -> void:
	_stop_x = stop_x
	_turn_stage = 0
	_timer = TURN_PAUSE
	state = State.TURN
	Game.shake(3.0, TURN_PAUSE)


func start(player: CharacterBody2D, start_scroll_x: float) -> void:
	z_index = 0
	_visual.scale.x = 1.0
	_visual.modulate = Color.WHITE
	_beam.visible = false
	_deck.set_deferred("disabled", false)
	_player = player
	scroll_x = start_scroll_x
	_base_y = global_position.y
	_offset = global_position.x - scroll_x
	round_index = 0
	_lunges_done = 0
	state = State.IDLE
	_timer = IDLE_TIMES[0]
	Game.enemy_engaged()
	Game.report_boss_health(BOSS_NAME, ROUNDS, ROUNDS)


func _physics_process(delta: float) -> void:
	if state == State.PARKED or state == State.DESTROYED:
		return
	if state == State.PASS or state == State.TURN:
		_scripted_step(delta)
		return
	scroll_x = minf(scroll_x + SCROLL_SPEEDS[round_index] * delta, max_scroll_x)
	_timer -= delta
	_bounce_cooldown = maxf(_bounce_cooldown - delta, 0.0)
	match state:
		State.IDLE:
			_offset = move_toward(_offset, IDLE_OFFSET, 200.0 * delta)
			if _timer <= 0.0:
				state = State.TELEGRAPH
				_timer = TELEGRAPH_TIME
				_wheel.modulate = Color(1.0, 0.4, 0.4)
		State.TELEGRAPH:
			_visual.position.x = randf_range(-1.5, 1.5)
			if _timer <= 0.0:
				_visual.position.x = 0.0
				_wheel.modulate = Color.WHITE
				state = State.LUNGE
		State.LUNGE:
			_offset = move_toward(_offset, LUNGE_OFFSETS[round_index], 320.0 * delta)
			if is_equal_approx(_offset, LUNGE_OFFSETS[round_index]):
				state = State.HOLD
				_timer = HOLD_TIMES[round_index]
		State.HOLD:
			if _timer <= 0.0:
				state = State.RETREAT
		State.RETREAT:
			_offset = move_toward(_offset, IDLE_OFFSET, 220.0 * delta)
			if is_equal_approx(_offset, IDLE_OFFSET):
				_lunges_done += 1
				if _lunges_done >= LUNGES[round_index]:
					_open_hatch()
				else:
					state = State.IDLE
					_timer = IDLE_TIMES[round_index]
		State.VENT:
			_offset = move_toward(_offset, IDLE_OFFSET, 200.0 * delta)
			if _timer <= 0.0:
				_close_hatch()
				_lunges_done = 0
				state = State.IDLE
				_timer = IDLE_TIMES[round_index]
		State.STALLED:
			_offset = move_toward(_offset, STALL_OFFSET, 260.0 * delta)
			if _timer <= 0.0:
				state = State.IDLE
				_timer = IDLE_TIMES[round_index]
	global_position = Vector2(scroll_x + _offset, _base_y)
	_update_effects(delta)
	_track_player(delta)
	if state == State.STALLED:
		return
	_check_stomp()
	if state != State.STALLED and state != State.DESTROYED:
		_check_contact()


func _scripted_step(delta: float) -> void:
	_rumble_timer -= delta
	if state == State.PASS:
		global_position.x = move_toward(global_position.x, _pass_to, PASS_SPEED * delta)
		if _rumble_timer <= 0.0:
			_rumble_timer = 0.2
			var near: bool = _has_player() and absf(_player.global_position.x - global_position.x) < 140.0
			Game.shake(5.0 if near else 2.5, 0.3)
		if is_equal_approx(global_position.x, _pass_to):
			state = State.TURN
			_turn_stage = -1
			_timer = 0.0
			pass_finished.emit()
	else:
		_turn_step(delta)
	_update_effects(delta)


func _turn_step(delta: float) -> void:
	if _turn_stage < 0:
		return
	_timer -= delta
	match _turn_stage:
		0:
			if _timer <= 0.0:
				_turn_stage = 1
				_visual.scale.x = 1.0
				_spawn_fx(DUST_FX, to_global(DUST_POINT))
		1:
			global_position.x = move_toward(global_position.x, _stop_x, CREEP_SPEED * delta)
			if is_equal_approx(global_position.x, _stop_x):
				_turn_stage = 2
				_timer = TURN_WARN
				_wheel.modulate = Color(1.0, 0.4, 0.4)
				Game.shake(2.5, TURN_WARN)
		2:
			_visual.position.x = randf_range(-1.5, 1.5)
			_beam.visible = int(_timer * 8.0) % 2 == 0
			if _timer <= 0.0:
				_visual.position.x = 0.0
				_wheel.modulate = Color.WHITE
				_beam.visible = false
				_turn_stage = 3
				turn_finished.emit()


func _add_sprite(sprite_name: String, texture: Texture2D, frame: Vector2i, anims: Dictionary, pos: Vector2) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(texture, frame, anims)
	sprite.name = sprite_name
	sprite.position = pos
	_visual.add_child(sprite)
	return sprite


func _has_player() -> bool:
	return is_instance_valid(_player)


func _update_effects(delta: float) -> void:
	var fast: bool = state == State.TELEGRAPH or state == State.LUNGE or state == State.PASS or (state == State.TURN and _turn_stage == 2)
	_wheel.speed_scale = 2.4 if fast else 1.0
	_tracks.speed_scale = 4.0 if state == State.PASS else SCROLL_SPEEDS[round_index] / 60.0
	_steam_timer -= delta
	if _steam_timer <= 0.0:
		_steam_timer = randf_range(0.35, 0.6)
		_spawn_fx(STEAM_FX, to_global(STACK_TOP))
	if vulnerable:
		_vent_timer -= delta
		if _vent_timer <= 0.0:
			_vent_timer = randf_range(0.12, 0.2)
			_spawn_fx(STEAM_FX, to_global(VENT_POINT + Vector2(randf_range(-8.0, 8.0), 0.0)))
	_dust_timer -= delta
	if _dust_timer <= 0.0:
		_dust_timer = 0.14 if state == State.LUNGE else randf_range(0.2, 0.32)
		_spawn_fx(DUST_FX, to_global(DUST_POINT + Vector2(randf_range(-3.0, 3.0), 0.0)))


func _spawn_fx(scene: PackedScene, world_pos: Vector2) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var fx: Node2D = scene.instantiate() as Node2D
	root.add_child(fx)
	fx.global_position = world_pos


func _track_player(delta: float) -> void:
	_land_timer = maxf(_land_timer - delta, 0.0)
	if not _has_player():
		return
	var on_floor: bool = _player.is_on_floor()
	if on_floor and not _was_on_floor:
		_land_timer = LAND_WINDOW
	_was_on_floor = on_floor


func _check_contact() -> void:
	if not _has_player():
		return
	for area: Area2D in [_wheel_area, _grinder_area]:
		if area.overlaps_body(_player):
			_player.call("take_damage", contact_damage, global_position + Vector2(-40.0, 0.0))
			return


func _check_stomp() -> void:
	if not _has_player() or _land_timer <= 0.0:
		return
	if not _stomp_zone.overlaps_body(_player):
		return
	if not _player.is_on_floor():
		return
	if _player.global_position.y > global_position.y - STOMP_MIN_HEIGHT:
		return
	_land_timer = 0.0
	if vulnerable:
		_hit()
	elif _bounce_cooldown <= 0.0:
		_bounce()


func _bounce() -> void:
	_bounce_cooldown = 0.25
	_player.velocity = Vector2(_player.velocity.x, -230.0)
	_spawn_fx(SPARK_FX, _player.global_position + Vector2(0.0, -2.0))


func _open_hatch() -> void:
	state = State.VENT
	_timer = HATCH_TIMES[round_index]
	_vent_timer = 0.0
	_set_vulnerable(true)
	_hatch.play("opening")


func _close_hatch() -> void:
	_set_vulnerable(false)
	_hatch.play("closed")
	_spawn_fx(STEAM_FX, to_global(VENT_POINT))


func _set_vulnerable(value: bool) -> void:
	if vulnerable == value:
		return
	vulnerable = value
	vulnerable_changed.emit(value)


func _on_hatch_animation_finished() -> void:
	if vulnerable and _hatch.animation == &"opening":
		_hatch.play("open")


func _hit() -> void:
	var cleared: int = round_index + 1
	Game.report_boss_health(BOSS_NAME, ROUNDS - cleared, ROUNDS)
	_player.velocity = Vector2(240.0, -300.0)
	_visual.position.x = 0.0
	_wheel.modulate = Color.WHITE
	_set_vulnerable(false)
	_hatch.play("closed")
	_spawn_fx(SPARK_FX, _player.global_position + Vector2(0.0, -2.0))
	Game.shake(3.0, 0.2)
	round_cleared.emit(cleared)
	if cleared >= ROUNDS:
		_explode()
		return
	round_index = cleared
	_lunges_done = 0
	state = State.STALLED
	_timer = STALL_TIME
	_visual.modulate = Color(3.0, 3.0, 3.0)
	var flash: Tween = create_tween()
	flash.tween_property(_visual, "modulate", Color.WHITE, 0.25)


func _explode() -> void:
	state = State.DESTROYED
	_set_vulnerable(false)
	_deck.set_deferred("disabled", true)
	Game.enemy_disengaged()
	Game.clear_boss()
	Game.shake(6.0, 0.6)
	_spawn_fx(EXPLOSION_FX, to_global(Vector2(-10.0, -24.0)))
	var boom: Tween = create_tween()
	boom.tween_property(_visual, "modulate", Color(3.0, 2.0, 1.0), 0.08)
	for point: Vector2 in BLAST_POINTS:
		boom.tween_callback(_spawn_fx.bind(EXPLOSION_FX, to_global(point)))
		boom.tween_interval(0.12)
	boom.tween_property(_visual, "modulate:a", 0.0, 0.2)
	boom.tween_callback(_finish_explosion)


func _finish_explosion() -> void:
	visible = false
	destroyed.emit()
