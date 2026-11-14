extends Node2D
## Rave dome hazards for the Ball of Swine arena (#67): lane lasers and floor grooves.
## Every hazard flashes a warning first and only hurts after it. They pause while the ball is wedged.

signal hazard_fired(kind: String)

const LASER_WARN: float = 1.3
const LASER_ACTIVE: float = 0.5
const GROOVE_WARN: float = 1.1
const GROOVE_ACTIVE: float = 0.6
const GROOVE_WIDTH: float = 64.0
const DAMAGE: int = 1
const BAND_HEIGHT: float = 44.0
const PLAYER_HALF: Vector2 = Vector2(7.0, 15.0)
const PLAYER_CENTER: Vector2 = Vector2(0.0, -15.0)
const FIRST_DELAY: float = 5.0
const GAP: float = 4.5
const LASER_COLOR: Color = Color(1.0, 0.2, 0.6)
const GROOVE_COLOR: Color = Color(0.75, 0.3, 1.0)

var enabled: bool = false
var paused: bool = false
var rim_left: float = 0.0
var rim_right: float = 0.0
var lane_ys: Array[float] = []
var ball: Node = null
var hits: int = 0

var _items: Array[Dictionary] = []
var _next_in: float = FIRST_DELAY
var _toggle: bool = false
var _clock: float = 0.0
var _player: Node2D = null


func configure(left: float, right: float, ys: Array[float], boss: Node) -> void:
	rim_left = left
	rim_right = right
	lane_ys = ys
	ball = boss
	z_index = 12


func start() -> void:
	enabled = true
	_next_in = FIRST_DELAY


func stop() -> void:
	enabled = false
	_items.clear()
	queue_redraw()


func fire_laser(lane: int) -> void:
	_items.append({"kind": "laser", "lane": lane, "x": 0.0, "t": 0.0, "warn": LASER_WARN, "active": LASER_ACTIVE, "hit": false})
	hazard_fired.emit("laser")


func fire_groove(x: float) -> void:
	_items.append({"kind": "groove", "lane": 0, "x": x, "t": 0.0, "warn": GROOVE_WARN, "active": GROOVE_ACTIVE, "hit": false})
	hazard_fired.emit("groove")


func _physics_process(delta: float) -> void:
	_clock += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var frozen: bool = paused or (ball != null and is_instance_valid(ball) and bool(ball.call("is_vulnerable")))
	if enabled and not frozen:
		_schedule(delta)
	if not frozen:
		for item: Dictionary in _items:
			item["t"] = float(item["t"]) + delta
			if _is_active(item):
				_try_hit(item)
		_items = _items.filter(func(item: Dictionary) -> bool: return float(item["t"]) < float(item["warn"]) + float(item["active"]))
	queue_redraw()


func _schedule(delta: float) -> void:
	_next_in -= delta
	if _next_in > 0.0:
		return
	_next_in = GAP
	_toggle = not _toggle
	if _toggle:
		var lanes: Array[int] = [1, 2]
		if ball != null and is_instance_valid(ball):
			lanes.erase(int(ball.get("lane")))
		fire_laser(lanes[randi() % lanes.size()])
	else:
		var span: float = (rim_right - rim_left) - 160.0
		fire_groove(rim_left + 80.0 + randf() * span)


func _is_active(item: Dictionary) -> bool:
	return float(item["t"]) >= float(item["warn"])


func _try_hit(item: Dictionary) -> void:
	if _player == null or not is_instance_valid(_player) or Game.in_safe_zone:
		return
	var feet: Vector2 = _player.global_position
	var hurt: bool = false
	if str(item["kind"]) == "laser":
		var y: float = lane_ys[int(item["lane"])]
		var center_y: float = feet.y + PLAYER_CENTER.y
		hurt = center_y + PLAYER_HALF.y > y - BAND_HEIGHT and center_y - PLAYER_HALF.y < y
	else:
		hurt = absf(feet.x - float(item["x"])) < GROOVE_WIDTH * 0.5 and feet.y > lane_ys[0] - 6.0
	if hurt and _player.has_method("take_damage"):
		hits += 1
		_player.call("take_damage", DAMAGE, feet + Vector2(0.0, 20.0) if str(item["kind"]) == "groove" else Vector2(rim_right, feet.y))


func _draw() -> void:
	for item: Dictionary in _items:
		var warning: bool = not _is_active(item)
		var blink: float = 0.5 + 0.5 * sin(_clock * 30.0)
		if str(item["kind"]) == "laser":
			var y: float = to_local(Vector2(0.0, lane_ys[int(item["lane"])])).y
			var x0: float = to_local(Vector2(rim_left, 0.0)).x
			var x1: float = to_local(Vector2(rim_right, 0.0)).x
			var mid: float = y - BAND_HEIGHT * 0.5
			draw_rect(Rect2(x0 - 10.0, mid - 7.0, 12.0, 14.0), Color(0.2, 0.15, 0.25))
			draw_rect(Rect2(x1 - 2.0, mid - 7.0, 12.0, 14.0), Color(0.2, 0.15, 0.25))
			if warning:
				draw_line(Vector2(x0, mid), Vector2(x1, mid), Color(LASER_COLOR, 0.15 + 0.35 * blink), 1.0)
			else:
				draw_line(Vector2(x0, mid), Vector2(x1, mid), Color(LASER_COLOR, 0.35), 9.0)
				draw_line(Vector2(x0, mid), Vector2(x1, mid), Color(1.0, 0.85, 0.95), 3.0)
		else:
			var gx: float = to_local(Vector2(float(item["x"]), 0.0)).x
			var gy: float = to_local(Vector2(0.0, lane_ys[0])).y
			var rect: Rect2 = Rect2(gx - GROOVE_WIDTH * 0.5, gy - 1.0, GROOVE_WIDTH, 4.0)
			if warning:
				draw_rect(rect, Color(GROOVE_COLOR, 0.25 + 0.4 * blink))
			else:
				draw_rect(Rect2(rect.position.x, gy - 14.0, rect.size.x, 16.0), Color(GROOVE_COLOR, 0.35))
				draw_rect(rect, Color(1.0, 0.9, 1.0))
