extends StaticBody2D
## One Krakaren tentacle. It telegraphs at a spot on the floor, bursts up (hurts the player), then sags
## stuck for a few seconds: that is the only time it can be hit. Hits are passed to the boss.

signal finished(tentacle: Node)

enum State { HIDDEN, TELEGRAPH, SLAM, STUCK, RETRACT }

const SLAM_TIME: float = 0.22
const RETRACT_TIME: float = 0.35
const REACH_X: float = 16.0
const TALL: float = 74.0
const SAG: float = 34.0
const SKIN: Color = Color(0.56, 0.24, 0.5)
const SKIN_DARK: Color = Color(0.34, 0.12, 0.34)
const SUCKER: Color = Color(0.94, 0.62, 0.74)
const WARN: Color = Color(1.0, 0.3, 0.25)

var boss: Node = null
var state: State = State.HIDDEN
var damage: int = 2
var stuck_time: float = 2.8

var _timer: float = 0.0
var _height: float = 0.0
var _flash: float = 0.0
var _clock: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(18.0, 54.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -27.0)
	add_child(shape)
	z_index = 8


func strike(x: float, telegraph: float) -> void:
	global_position.x = x
	state = State.TELEGRAPH
	_timer = telegraph
	_height = 0.0


func is_busy() -> bool:
	return state != State.HIDDEN


func retract_now() -> void:
	if state == State.HIDDEN:
		return
	state = State.RETRACT
	_timer = RETRACT_TIME
	collision_layer = 0


func take_damage(amount: int, _from: Vector2) -> void:
	if state != State.STUCK or boss == null:
		return
	_flash = 0.15
	boss.call("tentacle_hit", amount)


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	match state:
		State.HIDDEN:
			return
		State.TELEGRAPH:
			_timer -= delta
			if _timer <= 0.0:
				_slam()
		State.SLAM:
			_timer -= delta
			_height = TALL * (1.0 - maxf(_timer, 0.0) / SLAM_TIME)
			if _timer <= 0.0:
				state = State.STUCK
				_timer = stuck_time
				_height = SAG
				collision_layer = 4
		State.STUCK:
			_timer -= delta
			if _timer <= 0.0:
				retract_now()
		State.RETRACT:
			_timer -= delta
			_height = SAG * maxf(_timer, 0.0) / RETRACT_TIME
			if _timer <= 0.0:
				state = State.HIDDEN
				_height = 0.0
				finished.emit(self)
	queue_redraw()


func _slam() -> void:
	state = State.SLAM
	_timer = SLAM_TIME
	Game.shake(2.0, 0.15)
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or Game.in_safe_zone or bool(player.call("is_dead")):
		return
	var near_x: bool = absf(player.global_position.x - global_position.x) <= REACH_X
	var near_y: bool = player.global_position.y >= global_position.y - TALL
	if near_x and near_y:
		player.call("take_damage", damage, global_position)


func _draw() -> void:
	if state == State.HIDDEN:
		return
	if state == State.TELEGRAPH:
		var pulse: float = 0.5 + 0.5 * sin(_clock * 18.0)
		draw_rect(Rect2(-REACH_X - 4.0, -3.0, (REACH_X + 4.0) * 2.0, 3.0), Color(WARN.r, WARN.g, WARN.b, 0.35 + 0.5 * pulse))
		for i: int in 5:
			var cx: float = -12.0 + 6.0 * float(i)
			draw_line(Vector2(cx, 0.0), Vector2(cx + sin(_clock * 30.0 + float(i)) * 2.0, -6.0 - 3.0 * pulse), WARN, 1.0)
		return
	var h: float = _height
	var sway: float = sin(_clock * 3.0) * (3.0 if state == State.STUCK else 1.0)
	var steps: int = 8
	var skin: Color = Color(1.6, 1.5, 0.9) if _flash > 0.0 else SKIN
	for i: int in steps:
		var t0: float = float(i) / float(steps)
		var t1: float = float(i + 1) / float(steps)
		var w0: float = lerpf(9.0, 3.0, t0)
		var bend0: float = sway * t0 * t0 * (1.0 if state != State.STUCK else 2.0)
		var y0: float = -h * t0
		var y1: float = -h * t1
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(-w0 + bend0, y0), Vector2(w0 + bend0, y0),
			Vector2(lerpf(9.0, 3.0, t1) + sway * t1 * t1 * 1.5, y1), Vector2(-lerpf(9.0, 3.0, t1) + sway * t1 * t1 * 1.5, y1)])
		draw_colored_polygon(pts, skin if i % 2 == 0 else SKIN_DARK)
		if i % 2 == 1:
			draw_circle(Vector2(bend0 - w0 * 0.4, (y0 + y1) * 0.5), 1.2, SUCKER)
	draw_circle(Vector2(sway * 1.5, -h), 3.5, skin)
	if state == State.STUCK:
		draw_arc(Vector2(sway * 1.5, -h * 0.5), 14.0, 0.0, TAU, 20, Color(1.0, 0.9, 0.3, 0.5 + 0.3 * sin(_clock * 10.0)), 1.0)
