extends AnimatableBody2D

signal round_started(round_number: int)
signal round_cleared(round_number: int)
signal destroyed
signal vulnerable_changed(is_vulnerable: bool)

enum State { PARKED, PATROL, PIVOT, STALLED, DESTROYED }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const TRACKS_TEX: Texture2D = preload("res://assets/boss/dozer_tracks.png")
const WHEEL_TEX: Texture2D = preload("res://assets/boss/dozer_wheel.png")
const HATCH_TEX: Texture2D = preload("res://assets/boss/dozer_hatch.png")
const DRIVER_TEX: Texture2D = preload("res://assets/boss/dozer_driver.png")
const SPARK_FX: PackedScene = preload("res://scenes/fx/hit_spark.tscn")
const STEAM_FX: PackedScene = preload("res://scenes/fx/steam_puff.tscn")
const DUST_FX: PackedScene = preload("res://scenes/fx/dust.tscn")
const EXPLOSION_FX: PackedScene = preload("res://scenes/fx/explosion.tscn")
const PINEAPPLE_SCENE: PackedScene = preload("res://scenes/enemies/pineapple.tscn")

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
const HATCH_TIMES: Array[float] = [4.5, 4.0, 3.5]
const PATROL_SPEEDS: Array[float] = [90.0, 120.0, 150.0]
const CLOSED_TIMES: Array[float] = [3.0, 2.5, 2.0]
const STALL_TIME: float = 1.6
const STOMP_MIN_HEIGHT: float = 26.0
const LAND_WINDOW: float = 0.12
const TURN_PAUSE: float = 0.7
const TURN_WARN: float = 1.0
const ENTRY_WARN: float = 1.4
const THROW_ROUND: int = 1
const THROW_FIRST: float = 1.0
const THROW_INTERVAL: float = 0.7
const THROW_WINDUP: float = 0.3
const THROW_RANGE: float = 380.0
const THROW_BEHIND_WALL: float = 70.0
const THROW_SPEED_MAX: float = 380.0
const HAND_POINT: Vector2 = Vector2(34.0, -50.0)
const DRIVER_LEAN: float = -7.0
const DRIVER_DUCK: float = 16.0
const BEAM_POLYGON: PackedVector2Array = [Vector2(54.0, -30.0), Vector2(190.0, -62.0), Vector2(190.0, -2.0)]

@export var contact_damage: int = 2
@export var closed_hatch_damage: int = 1
@export var patrol_min_x: float = 0.0
@export var patrol_max_x: float = 0.0

var state: State = State.PARKED
var round_index: int = 0
var vulnerable: bool = false
var direction: int = 1

var _timer: float = 0.0
var _base_y: float = 0.0
var _hatch_timer: float = 0.0
var _pivot_stage: int = 0
var _throw_timer: float = 0.0
var _windup: float = -1.0
var _driver_tween: Tween
var _engaged: bool = false
var _was_on_floor: bool = false
var _land_timer: float = 0.0
var _bounce_cooldown: float = 0.0
var _steam_timer: float = 0.3
var _vent_timer: float = 0.0
var _dust_timer: float = 0.1
var _mirror_x: Dictionary = {}
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
	_driver.visible = false
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
	for node: Node2D in [_deck, _wheel_area, _grinder_area, _stomp_zone]:
		_mirror_x[node] = node.position.x


func begin_patrol(player: CharacterBody2D, floor_y: float, start_round: int = 0) -> void:
	_player = player
	_base_y = floor_y
	round_index = start_round
	_face(-1)
	z_index = 0
	_visual.position.x = 0.0
	_visual.modulate = Color.WHITE
	_wheel.modulate = Color(1.0, 0.4, 0.4)
	_hatch.play("closed")
	_set_vulnerable(false)
	global_position = Vector2(patrol_max_x, floor_y)
	reset_physics_interpolation()
	_deck.set_deferred("disabled", false)
	visible = true
	_driver.visible = true
	_hatch_timer = CLOSED_TIMES[round_index]
	_pivot_stage = 1
	_timer = ENTRY_WARN
	state = State.PIVOT
	_engage()
	Game.report_boss_health(BOSS_NAME, ROUNDS - round_index, ROUNDS)
	Game.shake(4.0, ENTRY_WARN)
	_apply_round_pose()
	round_started.emit(round_index + 1)


func _engage() -> void:
	if _engaged:
		return
	_engaged = true
	Game.enemy_engaged()


func _physics_process(delta: float) -> void:
	if state == State.PARKED or state == State.DESTROYED:
		return
	_bounce_cooldown = maxf(_bounce_cooldown - delta, 0.0)
	_patrol_step(delta)


func _patrol_step(delta: float) -> void:
	if state != State.PATROL:
		_cancel_throw()
	match state:
		State.PATROL:
			_throw_step(delta)
			_run_hatch(delta)
			var x: float = clampf(global_position.x + float(direction) * PATROL_SPEEDS[round_index] * delta, patrol_min_x, patrol_max_x)
			global_position.x = x
			if (direction < 0 and x <= patrol_min_x) or (direction > 0 and x >= patrol_max_x):
				state = State.PIVOT
				_pivot_stage = 0
				_timer = TURN_PAUSE
				Game.shake(3.0, TURN_PAUSE)
		State.PIVOT:
			_run_hatch(delta)
			_pivot_step(delta)
		State.STALLED:
			_timer -= delta
			if _timer <= 0.0:
				state = State.PATROL
	_update_effects(delta)
	_track_player(delta)
	if state == State.STALLED:
		return
	_check_stomp()
	if state != State.DESTROYED:
		_check_contact()


func _throw_step(delta: float) -> void:
	if round_index != THROW_ROUND or not _has_player():
		return
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_windup = -1.0
			_throw()
		return
	_throw_timer -= delta
	var dx: float = absf(_player.global_position.x - global_position.x)
	var behind_wall: bool = _player.global_position.x < patrol_min_x - THROW_BEHIND_WALL
	if _throw_timer <= 0.0 and dx <= THROW_RANGE and not behind_wall:
		_windup = THROW_WINDUP
		_tween_driver(DRIVER_POS.y + DRIVER_LEAN - 6.0, Color(1.0, 0.8, 0.5), THROW_WINDUP)


func _throw() -> void:
	_throw_timer = THROW_INTERVAL - THROW_WINDUP
	_tween_driver(DRIVER_POS.y + DRIVER_LEAN, Color.WHITE, 0.15)
	var holder: Node = get_tree().current_scene
	if holder == null:
		return
	var origin: Vector2 = _fx_point(HAND_POINT)
	var offset: Vector2 = _player.global_position + Vector2(0.0, -14.0) - origin
	var pineapple: Area2D = PINEAPPLE_SCENE.instantiate() as Area2D
	holder.add_child(pineapple)
	pineapple.global_position = origin
	var g: float = float(pineapple.get("fall_gravity"))
	var flight: float = clampf(offset.length() / 300.0, 0.35, 0.9)
	var launch_velocity: Vector2 = Vector2(offset.x / flight, offset.y / flight - 0.5 * g * flight)
	if launch_velocity.length() > THROW_SPEED_MAX:
		launch_velocity = launch_velocity.normalized() * THROW_SPEED_MAX
	pineapple.call("launch", launch_velocity, 1)


func _cancel_throw() -> void:
	if _windup > 0.0:
		_windup = -1.0
		_tween_driver(DRIVER_POS.y + DRIVER_LEAN, Color.WHITE, 0.15)
	_throw_timer = maxf(_throw_timer, THROW_FIRST)


func _apply_round_pose() -> void:
	_windup = -1.0
	_throw_timer = THROW_FIRST
	if round_index == THROW_ROUND:
		_tween_driver(DRIVER_POS.y + DRIVER_LEAN, Color.WHITE, 0.3)
	elif round_index > THROW_ROUND:
		_tween_driver(DRIVER_POS.y + DRIVER_DUCK, Color.WHITE, 0.3)


func _tween_driver(y: float, tint: Color, time: float) -> void:
	if _driver_tween != null and _driver_tween.is_valid():
		_driver_tween.kill()
	_driver_tween = create_tween().set_parallel(true)
	_driver_tween.tween_property(_driver, "position:y", y, time)
	_driver_tween.tween_property(_driver, "modulate", tint, time)


func _clear_pineapples() -> void:
	for node: Node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()


func _pivot_step(delta: float) -> void:
	_timer -= delta
	if _pivot_stage == 0:
		if _timer <= 0.0:
			_face(-direction)
			_pivot_stage = 1
			_timer = TURN_WARN
			_wheel.modulate = Color(1.0, 0.4, 0.4)
			_spawn_fx(DUST_FX, _fx_point(DUST_POINT))
			Game.shake(2.5, TURN_WARN)
		return
	_visual.position.x = randf_range(-1.5, 1.5)
	_beam.visible = int(_timer * 8.0) % 2 == 0
	if _timer <= 0.0:
		_visual.position.x = 0.0
		_wheel.modulate = Color.WHITE
		_beam.visible = false
		state = State.PATROL


func _run_hatch(delta: float) -> void:
	_hatch_timer -= delta
	if _hatch_timer > 0.0:
		return
	if vulnerable:
		_close_hatch()
		_hatch_timer = CLOSED_TIMES[round_index]
	else:
		_open_hatch()
		_hatch_timer = HATCH_TIMES[round_index]


func _add_sprite(sprite_name: String, texture: Texture2D, frame: Vector2i, anims: Dictionary, pos: Vector2) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(texture, frame, anims)
	sprite.name = sprite_name
	sprite.position = pos
	_visual.add_child(sprite)
	return sprite


func _face(dir: int) -> void:
	direction = dir
	_visual.scale.x = float(dir)
	for node: Node2D in _mirror_x.keys():
		node.position.x = float(_mirror_x[node]) * float(dir)


func _fx_point(point: Vector2) -> Vector2:
	return to_global(Vector2(point.x * _visual.scale.x, point.y))


func _has_player() -> bool:
	return is_instance_valid(_player)


func _update_effects(delta: float) -> void:
	_wheel.speed_scale = 2.4 if state == State.PIVOT and _pivot_stage == 1 else 1.0
	_tracks.speed_scale = PATROL_SPEEDS[round_index] / 60.0 if state == State.PATROL else 0.2
	_steam_timer -= delta
	if _steam_timer <= 0.0:
		_steam_timer = randf_range(0.35, 0.6)
		_spawn_fx(STEAM_FX, _fx_point(STACK_TOP))
	if vulnerable:
		_vent_timer -= delta
		if _vent_timer <= 0.0:
			_vent_timer = randf_range(0.12, 0.2)
			_spawn_fx(STEAM_FX, _fx_point(VENT_POINT + Vector2(randf_range(-8.0, 8.0), 0.0)))
	_dust_timer -= delta
	if _dust_timer <= 0.0:
		_dust_timer = randf_range(0.2, 0.32)
		_spawn_fx(DUST_FX, _fx_point(DUST_POINT + Vector2(randf_range(-3.0, 3.0), 0.0)))


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
			_player.call("take_damage", contact_damage, _fx_point(Vector2(-40.0, 0.0)))
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
	if closed_hatch_damage > 0:
		_player.call("take_damage", closed_hatch_damage, global_position)
	_spawn_fx(SPARK_FX, _player.global_position + Vector2(0.0, -2.0))


func _open_hatch() -> void:
	_vent_timer = 0.0
	_set_vulnerable(true)
	_hatch.play("opening")


func _close_hatch() -> void:
	_set_vulnerable(false)
	_hatch.play("closed")
	_spawn_fx(STEAM_FX, _fx_point(VENT_POINT))


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
	_player.velocity = Vector2(240.0 if _player.global_position.x >= global_position.x else -240.0, -300.0)
	_beam.visible = false
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
	_hatch_timer = CLOSED_TIMES[round_index]
	state = State.STALLED
	_timer = STALL_TIME
	_apply_round_pose()
	round_started.emit(cleared + 1)
	_visual.modulate = Color(3.0, 3.0, 3.0)
	var flash: Tween = create_tween()
	flash.tween_property(_visual, "modulate", Color.WHITE, 0.25)


func _explode() -> void:
	state = State.DESTROYED
	_cancel_throw()
	_clear_pineapples()
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
