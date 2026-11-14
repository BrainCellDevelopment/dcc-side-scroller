extends CharacterBody2D
## Floor 1 Borough boss (#67). A rolling ball of fused nobles that sweeps the arena lane by lane.
## Melee and missiles only count while it is wedged in the Speedbump fortress; dynamite blasts always do.

signal defeated(boss: Node)
signal wedged
signal freed
signal rebounded

enum State { DORMANT, DIZZY, SWITCH, WINDUP, ROLL, WEDGED, POPPED }

const BOSS_NAME: String = "Ball of Swine"
const RADIUS: float = 22.0
const ROLL_SPEED: float = 200.0
const WINDUP_TIME: float = 1.5
const FIRST_WINDUP_TIME: float = 2.2
const DIZZY_TIME: float = 1.0
const STAGGER_TIME: float = 1.4
const SWITCH_TIME: float = 0.45
const WEDGE_TIME: float = 7.0
const WEDGE_MULTIPLIER: int = 2
const BLAST_DAMAGE: int = 3
const CONTACT_DAMAGE: int = 2
const LANE_ORDER: Array[int] = [0, 1, 2, 0, 2, 1]
const PLAYER_HALF: Vector2 = Vector2(7.0, 15.0)
const PLAYER_CENTER: Vector2 = Vector2(0.0, -15.0)
const HOP_TIME: float = 0.34
const HOP_HEIGHT: float = 12.0
const PINK: Color = Color(0.93, 0.56, 0.62)
const PINK_DARK: Color = Color(0.72, 0.34, 0.44)
const PINK_LIGHT: Color = Color(1.0, 0.78, 0.8)
const OUTLINE: Color = Color(0.3, 0.1, 0.18)
const NEON: Color = Color(1.0, 0.85, 0.2)

@export var max_health: int = 9
@export var enemy_level: int = 15
@export var xp_value: int = -1
@export var is_boss: bool = true

var health: int = 0
var active: bool = false
var state: State = State.DORMANT
var lane: int = 0
var heading: int = 1
var lane_ys: Array[float] = []
var rim_left: float = 0.0
var rim_right: float = 0.0
var gate_x: float = 0.0
var gate_armed: bool = false
var bump_xs: Array[float] = []
var pass_count: int = 0
var wedge_left: float = 0.0
var times_wedged: int = 0

var _timer: float = 0.0
var _spin: float = 0.0
var _hop_t: float = 0.0
var _hop_done: Array[float] = []
var _hurt_flash: float = 0.0
var _clock: float = 0.0
var _gate_passed: bool = false
var _lane_from_y: float = 0.0
var _lane_to_y: float = 0.0
var _pending_switch: bool = false
var _body_shape: CollisionShape2D = null


func _ready() -> void:
	add_to_group("destructibles")
	add_to_group("swine_ball")
	collision_layer = 4
	collision_mask = 0
	z_index = 20
	_body_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _body_shape != null:
		_body_shape.disabled = true
	health = max_health


func configure(ys: Array[float], left: float, right: float) -> void:
	lane_ys = ys
	rim_left = left
	rim_right = right


func activate() -> void:
	if active or state == State.POPPED:
		return
	active = true
	heading = 1
	lane = LANE_ORDER[0]
	global_position = Vector2(rim_left + RADIUS, lane_ys[lane])
	_set_state(State.DIZZY)
	_timer = 1.0
	Game.enemy_engaged()
	Game.report_boss_health(BOSS_NAME, health, max_health)


func _exit_tree() -> void:
	if active and state != State.POPPED:
		Game.enemy_disengaged()


func is_dead() -> bool:
	return state == State.POPPED


func is_vulnerable() -> bool:
	return state == State.WEDGED


func center() -> Vector2:
	return global_position + Vector2(0.0, -RADIUS - _lift())


func _lift() -> float:
	if _hop_t > 0.0:
		return sin((1.0 - _hop_t / HOP_TIME) * PI) * HOP_HEIGHT
	if state == State.WEDGED:
		return 12.0
	return 0.0


func take_damage(amount: int, _from: Vector2) -> void:
	if state != State.WEDGED:
		return
	_hurt(amount * WEDGE_MULTIPLIER)


## Called by Explosives.blast (the ball is a "destructible").
func blast(_center: Vector2) -> void:
	if state == State.DORMANT or state == State.POPPED:
		return
	_hurt(BLAST_DAMAGE)
	if state == State.WINDUP or state == State.ROLL:
		_set_state(State.DIZZY)
		_timer = STAGGER_TIME


func _hurt(amount: int) -> void:
	health = maxi(health - amount, 0)
	_hurt_flash = 0.25
	Game.report_boss_health(BOSS_NAME, health, max_health)
	Game.shake(3.0, 0.2)
	if health <= 0:
		_pop()


func _pop() -> void:
	if state == State.POPPED:
		return
	_set_state(State.POPPED)
	if active:
		Game.enemy_disengaged()
	PlayerStats.award_kill(self)
	Game.report_mob_kill(self)
	Game.shake(6.0, 0.5)
	defeated.emit.call_deferred(self)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _set_state(value: State) -> void:
	state = value
	if _body_shape != null:
		_body_shape.set_deferred("disabled", value != State.WEDGED)
		_body_shape.position = Vector2(0.0, -RADIUS - 12.0)


func _physics_process(delta: float) -> void:
	_clock += delta
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	_hop_t = maxf(_hop_t - delta, 0.0)
	if not active or state == State.POPPED:
		queue_redraw()
		return
	match state:
		State.DIZZY:
			_dizzy(delta)
		State.SWITCH:
			_switch(delta)
		State.WINDUP:
			_windup(delta)
		State.ROLL:
			_roll(delta)
		State.WEDGED:
			_wedged(delta)
	queue_redraw()


func _dizzy(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	if _pending_switch:
		_pending_switch = false
		_lane_from_y = lane_ys[lane]
		lane = LANE_ORDER[pass_count % LANE_ORDER.size()]
		_lane_to_y = lane_ys[lane]
		_set_state(State.SWITCH)
		_timer = SWITCH_TIME
		return
	_set_state(State.WINDUP)
	_timer = FIRST_WINDUP_TIME if pass_count == 0 else WINDUP_TIME


func _switch(delta: float) -> void:
	_timer -= delta
	var t: float = clampf(1.0 - _timer / SWITCH_TIME, 0.0, 1.0)
	global_position.y = lerpf(_lane_from_y, _lane_to_y, ease(t, -2.0))
	if _timer <= 0.0:
		global_position.y = _lane_to_y
		_set_state(State.WINDUP)
		_timer = WINDUP_TIME


func _windup(delta: float) -> void:
	_timer -= delta
	_spin += float(heading) * delta * 6.0 * (1.0 + (1.0 - _timer / WINDUP_TIME) * 3.0)
	if _timer <= 0.0:
		_set_state(State.ROLL)
		_gate_passed = false
		_hop_done.clear()
		Game.shake(2.0, 0.2)


func _roll(delta: float) -> void:
	var previous: float = global_position.x
	global_position.x += float(heading) * ROLL_SPEED * delta
	_spin += float(heading) * ROLL_SPEED * delta / RADIUS
	if lane == 0:
		if _check_wedge(previous):
			return
		_check_hops()
	_check_contact()
	var limit: float = rim_right - RADIUS if heading > 0 else rim_left + RADIUS
	if (heading > 0 and global_position.x >= limit) or (heading < 0 and global_position.x <= limit):
		global_position.x = limit
		_rebound()


func _check_wedge(previous: float) -> bool:
	if not gate_armed or _gate_passed:
		return false
	var crossed: bool = (previous - gate_x) * (global_position.x - gate_x) <= 0.0
	if not crossed:
		return false
	global_position.x = gate_x
	_set_state(State.WEDGED)
	wedge_left = WEDGE_TIME
	times_wedged += 1
	Game.shake(5.0, 0.35)
	wedged.emit()
	return true


func _check_hops() -> void:
	for bx: float in bump_xs:
		if _hop_done.has(bx):
			continue
		if absf(global_position.x - bx) < 8.0:
			_hop_done.append(bx)
			_hop_t = HOP_TIME
			Game.shake(1.5, 0.12)


func _wedged(delta: float) -> void:
	wedge_left -= delta
	_spin += delta * 14.0 * float(heading)
	if wedge_left > 0.0:
		return
	_gate_passed = true
	_set_state(State.ROLL)
	freed.emit()


func _rebound() -> void:
	Game.shake(4.0, 0.3)
	rebounded.emit()
	pass_count += 1
	heading = -heading
	_pending_switch = true
	_set_state(State.DIZZY)
	_timer = DIZZY_TIME


func _check_contact() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player) or Game.in_safe_zone:
		return
	var c: Vector2 = center()
	var p: Vector2 = player.global_position + PLAYER_CENTER
	var nearest: Vector2 = Vector2(clampf(c.x, p.x - PLAYER_HALF.x, p.x + PLAYER_HALF.x), clampf(c.y, p.y - PLAYER_HALF.y, p.y + PLAYER_HALF.y))
	if nearest.distance_to(c) < RADIUS - 2.0 and player.has_method("take_damage"):
		player.call("take_damage", CONTACT_DAMAGE, c)


func rim_distance_ahead() -> float:
	var target: float = rim_right if heading > 0 else rim_left
	return absf(target - global_position.x)


func _draw() -> void:
	if state == State.DORMANT:
		return
	var lift: float = _lift()
	var shake: Vector2 = Vector2.ZERO
	if state == State.WINDUP:
		var amount: float = 1.0 + (1.0 - _timer / WINDUP_TIME) * 2.0
		shake = Vector2(sin(_clock * 70.0), cos(_clock * 83.0)) * amount * 0.5
	if state == State.WEDGED:
		shake = Vector2(sin(_clock * 55.0), 0.0) * 1.2
	if state == State.WINDUP or state == State.ROLL:
		_draw_telegraph()
	var c: Vector2 = Vector2(0.0, -RADIUS - lift) + shake
	draw_circle(Vector2(0.0, -2.0), RADIUS * 0.7, Color(0.0, 0.0, 0.0, 0.25))
	var body: Color = PINK
	if _hurt_flash > 0.0:
		body = Color(1.0, 0.95, 0.9)
	draw_circle(c, RADIUS + 1.5, OUTLINE)
	draw_circle(c, RADIUS, body)
	draw_arc(c, RADIUS - 5.0, _spin, _spin + PI * 0.8, 12, PINK_DARK, 2.0)
	draw_arc(c, RADIUS - 5.0, _spin + PI, _spin + PI * 1.8, 12, PINK_DARK, 2.0)
	for i: int in 6:
		var a: float = _spin + float(i) * TAU / 6.0
		var depth: float = cos(a)
		if depth <= 0.05:
			continue
		var at: Vector2 = c + Vector2(sin(a) * RADIUS * 0.72, sin(a * 2.0 + 1.0) * RADIUS * 0.35)
		_draw_face(at, 3.0 + 3.0 * depth, depth)
	draw_arc(c, RADIUS - 1.0, PI * 1.15, PI * 1.6, 10, PINK_LIGHT, 2.0)
	if state == State.WEDGED:
		var left_ratio: float = clampf(wedge_left / WEDGE_TIME, 0.0, 1.0)
		draw_rect(Rect2(-14.0, -RADIUS * 2.0 - 12.0 - lift, 28.0, 3.0), Color(0.1, 0.05, 0.12))
		draw_rect(Rect2(-14.0, -RADIUS * 2.0 - 12.0 - lift, 28.0 * left_ratio, 3.0), NEON)


func _draw_face(at: Vector2, size: float, depth: float) -> void:
	draw_circle(at, size, Color(PINK_LIGHT, 0.5 + 0.5 * depth))
	draw_circle(at + Vector2(0.0, size * 0.25), size * 0.55, Color(0.98, 0.65, 0.7))
	draw_circle(at + Vector2(-size * 0.2, size * 0.25), size * 0.12, OUTLINE)
	draw_circle(at + Vector2(size * 0.2, size * 0.25), size * 0.12, OUTLINE)
	draw_circle(at + Vector2(-size * 0.4, -size * 0.3), size * 0.14, OUTLINE)
	draw_circle(at + Vector2(size * 0.4, -size * 0.3), size * 0.14, OUTLINE)
	draw_line(at + Vector2(-size * 0.5, size * 0.55), at + Vector2(-size * 0.55, size * 0.95), Color(1.0, 0.97, 0.85), 1.0)
	draw_line(at + Vector2(size * 0.5, size * 0.55), at + Vector2(size * 0.55, size * 0.95), Color(1.0, 0.97, 0.85), 1.0)


func _draw_telegraph() -> void:
	var blink: float = 0.5 + 0.5 * sin(_clock * (14.0 if state == State.WINDUP else 6.0))
	var length: float = rim_distance_ahead()
	var y: float = -RADIUS
	var color: Color = Color(NEON, 0.25 + 0.5 * blink)
	var step: float = 26.0
	var x: float = float(heading) * (RADIUS + 10.0)
	while absf(x) < length - 8.0:
		var tip: Vector2 = Vector2(x + float(heading) * 7.0, y)
		draw_line(Vector2(x, y - 6.0), tip, color, 2.0)
		draw_line(Vector2(x, y + 6.0), tip, color, 2.0)
		x += float(heading) * step
