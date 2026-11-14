extends Node2D
## The Speedbump fortress (#67): two barricade pieces the player carries to two sockets on the floor
## lane. With both placed the rolling Ball of Swine wedges between them. The pieces always come
## back to their depots when the fortress breaks, so a failed attempt can be repeated.

signal armed_changed(armed: bool)
signal piece_picked(index: int)
signal piece_placed(index: int, socket: int)
signal broken

enum PieceState { HOME, CARRIED, DROPPED, PLACED }

const PICK_RANGE: float = 26.0
const PLACE_RANGE: float = 30.0
const PIECE_SIZE: Vector2 = Vector2(28.0, 22.0)
const CARRY_LIFT: float = 32.0
const HAZARD: Color = Color(0.98, 0.8, 0.1)
const DARK: Color = Color(0.12, 0.1, 0.14)
const CONCRETE: Color = Color(0.5, 0.48, 0.52)
const SOCKET_GLOW: Color = Color(0.35, 1.0, 0.9)

var armed: bool = false
var carried: int = -1
var pieces: Array[Dictionary] = []
var sockets: Array[Dictionary] = []
var gate_x: float = 0.0
var floor_y: float = 0.0

var _bodies: Array[StaticBody2D] = []
var _player: Node2D = null
var _clock: float = 0.0
var _prompt: String = ""
var _prompt_at: Vector2 = Vector2.ZERO


func setup(gate: float, floor_world_y: float, homes: Array[float], socket_offset: float = 22.0) -> void:
	gate_x = gate
	floor_y = floor_world_y
	sockets = [
		{"pos": Vector2(gate - socket_offset, floor_world_y), "piece": -1},
		{"pos": Vector2(gate + socket_offset, floor_world_y), "piece": -1},
	]
	for x: float in homes:
		var home: Vector2 = Vector2(x, floor_world_y)
		pieces.append({"home": home, "pos": home, "state": PieceState.HOME, "socket": -1})
		var body: StaticBody2D = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = PIECE_SIZE
		shape.shape = rect
		shape.position = Vector2(0.0, -PIECE_SIZE.y * 0.5)
		shape.disabled = true
		body.add_child(shape)
		add_child(body)
		body.global_position = home
		_bodies.append(body)
	z_index = 6


func placed_xs() -> Array[float]:
	var result: Array[float] = []
	for piece: Dictionary in pieces:
		if int(piece["state"]) == PieceState.PLACED:
			result.append((piece["pos"] as Vector2).x)
	return result


func placed_count() -> int:
	return placed_xs().size()


func is_carrying() -> bool:
	return carried >= 0


func piece_state(index: int) -> int:
	return int(pieces[index]["state"])


func piece_position(index: int) -> Vector2:
	return pieces[index]["pos"] as Vector2


func free_piece_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in pieces.size():
		var state: int = piece_state(i)
		if state == PieceState.HOME or state == PieceState.DROPPED:
			result.append(i)
	return result


func empty_socket_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in sockets.size():
		if int(sockets[i]["piece"]) < 0:
			result.append(i)
	return result


func socket_position(index: int) -> Vector2:
	return sockets[index]["pos"] as Vector2


func _physics_process(delta: float) -> void:
	_clock += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return
	if carried >= 0:
		pieces[carried]["pos"] = _player.global_position + Vector2(0.0, -CARRY_LIFT)
	_update_prompt()
	if Game.action_just_pressed("interact"):
		try_interact(_player.global_position)
	queue_redraw()


func _update_prompt() -> void:
	_prompt = ""
	var at: Vector2 = _player.global_position
	if carried >= 0:
		var socket: int = _nearest_empty_socket(at)
		_prompt = "E: PLACE" if socket >= 0 else "E: DROP"
		_prompt_at = at + Vector2(0.0, -CARRY_LIFT - PIECE_SIZE.y - 10.0)
		return
	var piece: int = _nearest_free_piece(at)
	if piece >= 0:
		_prompt = "E: LIFT"
		_prompt_at = piece_position(piece) + Vector2(0.0, -PIECE_SIZE.y - 10.0)


## Pick up, place or drop. Returns true when something happened.
func try_interact(at: Vector2) -> bool:
	if carried >= 0:
		var socket: int = _nearest_empty_socket(at)
		if socket >= 0:
			place(carried, socket)
		else:
			_drop(at)
		return true
	var piece: int = _nearest_free_piece(at)
	if piece < 0:
		return false
	pick_up(piece)
	return true


func pick_up(index: int) -> void:
	if carried >= 0:
		return
	carried = index
	pieces[index]["state"] = PieceState.CARRIED
	piece_picked.emit(index)


func place(index: int, socket: int) -> void:
	if int(sockets[socket]["piece"]) >= 0:
		return
	sockets[socket]["piece"] = index
	pieces[index]["state"] = PieceState.PLACED
	pieces[index]["socket"] = socket
	pieces[index]["pos"] = socket_position(socket)
	if carried == index:
		carried = -1
	_bodies[index].global_position = socket_position(socket)
	(_bodies[index].get_child(0) as CollisionShape2D).set_deferred("disabled", false)
	Game.shake(2.0, 0.15)
	piece_placed.emit(index, socket)
	_refresh_armed()


func _drop(at: Vector2) -> void:
	var index: int = carried
	carried = -1
	pieces[index]["state"] = PieceState.DROPPED
	pieces[index]["pos"] = Vector2(at.x, floor_y)


## The ball breaks free: both pieces go back to their depots.
func break_fortress() -> void:
	carried = -1
	for i: int in pieces.size():
		pieces[i]["state"] = PieceState.HOME
		pieces[i]["socket"] = -1
		pieces[i]["pos"] = pieces[i]["home"]
		_bodies[i].global_position = pieces[i]["home"] as Vector2
		(_bodies[i].get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	for socket: Dictionary in sockets:
		socket["piece"] = -1
	Game.shake(3.0, 0.25)
	broken.emit()
	_refresh_armed()


func _refresh_armed() -> void:
	var now: bool = empty_socket_indices().is_empty()
	if now == armed:
		return
	armed = now
	armed_changed.emit(armed)


func _nearest_free_piece(at: Vector2) -> int:
	var best: int = -1
	var best_dist: float = PICK_RANGE
	for i: int in free_piece_indices():
		var dist: float = absf(piece_position(i).x - at.x)
		if dist <= best_dist and absf(piece_position(i).y - at.y) < 40.0:
			best = i
			best_dist = dist
	return best


func _nearest_empty_socket(at: Vector2) -> int:
	var best: int = -1
	var best_dist: float = PLACE_RANGE
	for i: int in empty_socket_indices():
		var dist: float = absf(socket_position(i).x - at.x)
		if dist <= best_dist and absf(socket_position(i).y - at.y) < 40.0:
			best = i
			best_dist = dist
	return best


func _draw() -> void:
	for i: int in sockets.size():
		if int(sockets[i]["piece"]) >= 0:
			continue
		var at: Vector2 = to_local(socket_position(i))
		var pulse: float = 0.45 + 0.35 * sin(_clock * 4.0 + float(i))
		draw_rect(Rect2(at.x - PIECE_SIZE.x * 0.5, at.y - PIECE_SIZE.y, PIECE_SIZE.x, PIECE_SIZE.y), Color(SOCKET_GLOW, 0.12 * pulse + 0.05))
		var dash: float = 6.0
		var x: float = at.x - PIECE_SIZE.x * 0.5
		while x < at.x + PIECE_SIZE.x * 0.5:
			draw_line(Vector2(x, at.y - 1.0), Vector2(minf(x + dash * 0.6, at.x + PIECE_SIZE.x * 0.5), at.y - 1.0), Color(SOCKET_GLOW, pulse), 2.0)
			x += dash
	for i: int in pieces.size():
		_draw_piece(to_local(piece_position(i)), piece_state(i) == PieceState.CARRIED, piece_state(i) == PieceState.PLACED)
	if _prompt != "":
		var font: Font = ThemeDB.fallback_font
		var at: Vector2 = to_local(_prompt_at)
		draw_string(font, at + Vector2(-20.0, 1.0), _prompt, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color(0.05, 0.02, 0.08))
		draw_string(font, at + Vector2(-20.0, 0.0), _prompt, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color(1.0, 0.95, 0.7))


func _draw_piece(at: Vector2, lifted: bool, placed: bool) -> void:
	var w: float = PIECE_SIZE.x
	var h: float = PIECE_SIZE.y
	var base: Vector2 = at + Vector2(0.0, 0.0)
	var body: PackedVector2Array = PackedVector2Array([
		base + Vector2(-w * 0.5, 0.0), base + Vector2(-w * 0.38, -h * 0.7), base + Vector2(w * 0.38, -h * 0.7), base + Vector2(w * 0.5, 0.0)])
	draw_colored_polygon(body, CONCRETE)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3]]), DARK, 2.0)
	for k: int in 3:
		var sx: float = base.x - w * 0.3 + float(k) * w * 0.3
		var stripe: PackedVector2Array = PackedVector2Array([
			Vector2(sx - 3.0, base.y), Vector2(sx + 1.0, base.y), Vector2(sx + 3.0, base.y - h * 0.7), Vector2(sx - 1.0, base.y - h * 0.7)])
		draw_colored_polygon(stripe, HAZARD)
	for k: int in 4:
		var sx2: float = base.x - w * 0.3 + float(k) * w * 0.2
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx2 - 2.5, base.y - h * 0.7), Vector2(sx2, base.y - h), Vector2(sx2 + 2.5, base.y - h * 0.7)]), Color(0.78, 0.78, 0.84))
	if placed:
		draw_line(base + Vector2(-w * 0.5, 1.0), base + Vector2(w * 0.5, 1.0), Color(SOCKET_GLOW, 0.5), 1.0)
	if lifted:
		draw_circle(base + Vector2(0.0, 3.0), 3.0, Color(0.0, 0.0, 0.0, 0.2))
