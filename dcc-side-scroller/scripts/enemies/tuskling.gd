extends CharacterBody2D
## Tuskling nobles (#67): warthog-faced, tuxedoed and mostly helpless. They spill out of the Ball of
## Swine, stagger about, trip over their own tails and flee. A cornered one flails for 1 damage.
## With decor = true the node is a harmless extra from the crowd: no body, no XP, it runs off and fades.

signal died(tuskling: Node)

enum State { STAGGER, FLEE, TRIPPED, FLAIL, DEAD }
enum Kind { KNIGHT, COURTESAN, DOMINATRIX }

const STAGGER_SPEED: float = 26.0
const FLEE_SPEED: float = 82.0
const FLEE_RANGE: float = 90.0
const CORNER_DISTANCE: float = 22.0
const FLAIL_TIME: float = 0.7
const FLAIL_REACH: float = 20.0
const TRIP_TIME: float = 1.1
const HURT_PUSH: float = 120.0
const NAMES: Array[String] = ["Tuskling Knight", "Tuskling Courtesan", "Tuskling Dominatrix"]
const LEVELS: Array[int] = [4, 5, 8]
const HEALTH: Array[int] = [2, 2, 3]
const SUIT: Color = Color(0.1, 0.09, 0.13)
const SHIRT: Color = Color(0.96, 0.94, 0.9)
const SKIN: Color = Color(0.86, 0.55, 0.52)
const SKIN_DARK: Color = Color(0.66, 0.38, 0.4)
const TUSK: Color = Color(1.0, 0.97, 0.85)

@export var kind: Kind = Kind.KNIGHT
@export var decor: bool = false
@export var enemy_level: int = 4
@export var xp_value: int = -1
@export var is_boss: bool = false
@export var attack_damage: int = 1

var health: int = 2
var state: State = State.STAGGER
var facing: int = 1
var gravity_force: float = 980.0
var flee_from: float = 0.0

var _timer: float = 0.0
var _clock: float = 0.0
var _wander_dir: float = 1.0
var _wander_timer: float = 0.0
var _flash: float = 0.0
var _has_hit: bool = false
var _alpha_tween: Tween = null


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	_clock = randf() * 10.0
	_wander_dir = 1.0 if randf() < 0.5 else -1.0
	health = HEALTH[kind]
	enemy_level = LEVELS[kind]
	z_index = 7
	if decor:
		collision_layer = 0
		collision_mask = 0
		return
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1


func display_name() -> String:
	return NAMES[kind]


func is_dead() -> bool:
	return state == State.DEAD


func launch(burst: Vector2) -> void:
	velocity = burst
	state = State.TRIPPED
	_timer = 0.6 + randf() * 0.4


func run_off(direction: float, lifetime: float) -> void:
	state = State.FLEE
	facing = 1 if direction > 0.0 else -1
	flee_from = global_position.x - direction * 1000.0
	_timer = lifetime
	if _alpha_tween != null:
		_alpha_tween.kill()
	_alpha_tween = create_tween()
	_alpha_tween.tween_interval(maxf(lifetime - 0.6, 0.1))
	_alpha_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	_alpha_tween.tween_callback(queue_free)


func take_damage(amount: int, from: Vector2) -> void:
	if state == State.DEAD or decor:
		return
	health = maxi(health - amount, 0)
	_flash = 0.2
	var push: float = signf(global_position.x - from.x)
	if is_zero_approx(push):
		push = -float(facing)
	if health <= 0:
		_faint(push)
		return
	velocity = Vector2(push * HURT_PUSH, -90.0)
	state = State.TRIPPED
	_timer = TRIP_TIME * 0.6


func _faint(push: float) -> void:
	state = State.DEAD
	velocity = Vector2(push * 70.0, -120.0)
	collision_layer = 0
	PlayerStats.award_kill(self)
	died.emit(self)
	var tween: Tween = create_tween()
	tween.tween_interval(0.9)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	if not is_on_floor() and not decor:
		velocity.y += gravity_force * delta
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.STAGGER:
			_stagger(delta, player)
		State.FLEE:
			_flee(delta, player)
		State.TRIPPED:
			_tripped(delta)
		State.FLAIL:
			_flail(delta, player)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	move_and_slide()
	queue_redraw()


func _stagger(delta: float, player: Node2D) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = 0.6 + randf() * 1.2
		_wander_dir = -_wander_dir if randf() < 0.6 else _wander_dir
		if randf() < 0.18:
			state = State.TRIPPED
			_timer = TRIP_TIME
			return
	velocity.x = _wander_dir * STAGGER_SPEED * (0.6 + 0.4 * sin(_clock * 5.0))
	facing = 1 if _wander_dir > 0.0 else -1
	if player != null and absf(player.global_position.x - global_position.x) < FLEE_RANGE and absf(player.global_position.y - global_position.y) < 60.0:
		state = State.FLEE
		flee_from = player.global_position.x


func _flee(delta: float, player: Node2D) -> void:
	if decor:
		_timer -= delta
		velocity.x = float(facing) * FLEE_SPEED * 1.2
		return
	if player != null:
		flee_from = player.global_position.x
		if absf(player.global_position.x - global_position.x) > FLEE_RANGE * 1.6:
			state = State.STAGGER
			return
	var away: float = signf(global_position.x - flee_from)
	if is_zero_approx(away):
		away = -float(facing)
	facing = 1 if away > 0.0 else -1
	velocity.x = away * FLEE_SPEED
	if is_on_wall():
		velocity.x = 0.0
		if player != null and absf(player.global_position.x - global_position.x) < CORNER_DISTANCE + 12.0:
			state = State.FLAIL
			_timer = FLAIL_TIME
			_has_hit = false
			facing = 1 if player.global_position.x > global_position.x else -1
		elif is_on_floor():
			velocity.y = -150.0


func _tripped(delta: float) -> void:
	_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
	if _timer <= 0.0:
		state = State.STAGGER


func _flail(delta: float, player: Node2D) -> void:
	_timer -= delta
	velocity.x = 0.0
	if player != null and not _has_hit and _timer < FLAIL_TIME * 0.5:
		var reach: float = absf(player.global_position.x - global_position.x)
		if reach < FLAIL_REACH and absf(player.global_position.y - global_position.y) < 24.0 and player.has_method("take_damage"):
			_has_hit = true
			player.call("take_damage", attack_damage, global_position)
	if _timer <= 0.0:
		state = State.FLEE


func _draw() -> void:
	var sway: float = sin(_clock * 6.0) * (0.12 if state == State.STAGGER else 0.04)
	var lie: float = 0.0
	if state == State.TRIPPED or state == State.DEAD:
		lie = 1.35 * float(facing)
	var flip: float = float(facing)
	draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2.ONE)
	var pivot: Vector2 = Vector2(0.0, -1.0)
	draw_set_transform(pivot, sway * flip + lie, Vector2(flip, 1.0))
	var tint: Color = Color(1.4, 1.4, 1.4) if _flash > 0.0 else Color.WHITE
	var bob: float = absf(sin(_clock * 9.0)) * 1.5 if state == State.FLEE else 0.0
	var y0: float = -bob
	draw_rect(Rect2(-4.0, y0 - 10.0, 3.0, 9.0), SUIT * tint)
	draw_rect(Rect2(1.0, y0 - 10.0, 3.0, 9.0), SUIT * tint)
	draw_rect(Rect2(-5.0, y0 - 2.0, 4.0, 2.0), Color(0.05, 0.04, 0.06))
	draw_rect(Rect2(1.0, y0 - 2.0, 4.0, 2.0), Color(0.05, 0.04, 0.06))
	_draw_outfit(y0, tint)
	draw_circle(Vector2(0.0, y0 - 21.0), 5.5, SKIN * tint)
	draw_circle(Vector2(-4.5, y0 - 25.0), 2.0, SKIN_DARK * tint)
	draw_circle(Vector2(4.5, y0 - 25.0), 2.0, SKIN_DARK * tint)
	draw_circle(Vector2(3.5, y0 - 19.0), 3.0, SKIN_DARK * tint)
	draw_rect(Rect2(2.6, y0 - 19.6, 1.0, 1.0), Color(0.15, 0.05, 0.08))
	draw_rect(Rect2(4.4, y0 - 19.6, 1.0, 1.0), Color(0.15, 0.05, 0.08))
	draw_rect(Rect2(1.5, y0 - 22.5, 1.5, 1.5), Color(0.1, 0.05, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(4.0, y0 - 17.0), Vector2(5.5, y0 - 21.0), Vector2(6.3, y0 - 16.5)]), TUSK)
	_draw_hat(y0, tint)
	if state == State.FLAIL:
		var swing: float = sin((FLAIL_TIME - _timer) * 22.0)
		draw_line(Vector2(5.0, y0 - 12.0), Vector2(11.0 + swing * 4.0, y0 - 18.0 + swing * 3.0), Color(0.75, 0.75, 0.8), 1.5)
	if state == State.DEAD:
		for i: int in 3:
			var a: float = _clock * 5.0 + float(i) * TAU / 3.0
			draw_circle(Vector2(cos(a) * 7.0, y0 - 30.0 + sin(a) * 2.0), 1.0, Color(1.0, 0.9, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_outfit(y0: float, tint: Color) -> void:
	match kind:
		Kind.KNIGHT:
			draw_rect(Rect2(-5.0, y0 - 18.0, 10.0, 9.0), SUIT * tint)
			draw_colored_polygon(PackedVector2Array([Vector2(-2.0, y0 - 18.0), Vector2(2.0, y0 - 18.0), Vector2(0.0, y0 - 11.0)]), SHIRT * tint)
			draw_rect(Rect2(-1.5, y0 - 17.0, 3.0, 1.5), Color(0.8, 0.15, 0.2))
			draw_rect(Rect2(6.0, y0 - 14.0, 1.5, 7.0), Color(0.8, 0.7, 0.45))
		Kind.COURTESAN:
			draw_colored_polygon(PackedVector2Array([Vector2(-4.0, y0 - 17.0), Vector2(4.0, y0 - 17.0), Vector2(7.0, y0 - 5.0), Vector2(-7.0, y0 - 5.0)]), Color(0.86, 0.34, 0.6) * tint)
			draw_rect(Rect2(-4.0, y0 - 17.0, 8.0, 2.0), SUIT * tint)
			draw_rect(Rect2(-1.0, y0 - 17.0, 2.0, 2.0), SHIRT * tint)
		_:
			draw_rect(Rect2(-5.0, y0 - 18.0, 10.0, 11.0), Color(0.18, 0.1, 0.2) * tint)
			draw_rect(Rect2(-5.0, y0 - 14.0, 10.0, 1.5), Color(0.8, 0.8, 0.85))
			draw_rect(Rect2(-5.0, y0 - 10.0, 10.0, 1.5), Color(0.8, 0.8, 0.85))
			draw_line(Vector2(5.0, y0 - 13.0), Vector2(10.0, y0 - 9.0), Color(0.6, 0.35, 0.2), 1.5)


func _draw_hat(y0: float, tint: Color) -> void:
	match kind:
		Kind.KNIGHT:
			draw_rect(Rect2(-5.0, y0 - 28.0, 10.0, 4.0), Color(0.62, 0.62, 0.68) * tint)
			draw_rect(Rect2(-1.0, y0 - 31.0, 2.0, 3.0), Color(0.8, 0.15, 0.2))
		Kind.COURTESAN:
			draw_rect(Rect2(-6.0, y0 - 27.0, 12.0, 2.0), Color(0.5, 0.2, 0.5) * tint)
			draw_line(Vector2(-2.0, y0 - 27.0), Vector2(-6.0, y0 - 33.0), Color(1.0, 0.7, 0.8), 2.0)
			draw_line(Vector2(0.0, y0 - 27.0), Vector2(0.0, y0 - 34.0), Color(1.0, 0.85, 0.9), 2.0)
		_:
			draw_rect(Rect2(-8.0, y0 - 27.0, 16.0, 2.0), SUIT * tint)
			draw_rect(Rect2(-4.0, y0 - 31.0, 8.0, 4.0), SUIT * tint)
