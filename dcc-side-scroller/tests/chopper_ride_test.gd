extends Node

const RIDE: PackedScene = preload("res://scenes/chopper_ride.tscn")
const Course: GDScript = preload("res://scripts/data/chopper_course.gd")

var _fails: int = 0
var _ride: Node2D
var _finished: Array[int] = [-1]
var _jumped_gap: int = -1
var _jump_hold: int = 0
var _shots: Array = [200.0, 1400.0, 3050.0, 4150.0, 5000.0, 9700.0]
var _last_falls: int = 0
var _fire_phase: int = 0


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _spawn() -> void:
	if is_instance_valid(_ride):
		_ride.queue_free()
		await _frames(2)
	Game.reset_run()
	_ride = RIDE.instantiate() as Node2D
	_ride.set("auto_change_scene", false)
	_finished[0] = -1
	_ride.connect("left", func(done: bool) -> void: _finished[0] = 1 if done else 0)
	add_child(_ride)
	await _frames(3)


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _course_sanity() -> void:
	var all_ok: bool = true
	for list: Array in [Course.STICKERS, Course.BARRICADES, Course.LLAMAS, Course.VALVES]:
		for d: float in list:
			if Course.in_gap(d) or d < 300.0 or d > Course.LENGTH:
				all_ok = false
	_check(all_ok, "no obstacle, valve or llama sits inside a gap or too close to the start")
	var gaps_ok: bool = true
	for gap: Array in Course.GAPS:
		if float(gap[1]) - float(gap[0]) - 2.0 * Course.GAP_MARGIN > 90.0:
			gaps_ok = false
	_check(gaps_ok, "every gap can be cleared by a base speed jump")
	_check(Course.ARROW_AT > Course.LENGTH and Course.CHECKPOINTS[0] == 0.0, "arrow sign past the finish, first checkpoint at the start")


func _bot_frame(_delta: float) -> void:
	var d: float = float(_ride.get("distance"))
	var speed: float = float(_ride.get("speed"))
	var flight: float = speed * 0.747
	if _jump_hold > 0:
		_jump_hold -= 1
		Input.action_press("jump")
		return
	Input.action_release("jump")
	for i: int in Course.GAPS.size():
		var a: float = float(Course.GAPS[i][0])
		var b: float = float(Course.GAPS[i][1])
		var takeoff: float = clampf(b - Course.GAP_MARGIN - flight + 24.0, a - 40.0, a + 8.0)
		if i != _jumped_gap and d >= takeoff and d <= a + 12.0 and _ride.call("grounded"):
			_jumped_gap = i
			_jump_hold = 3
			Input.action_press("jump")
			return
	var need_fire: bool = false
	for list: Array in [Course.STICKERS, Course.BARRICADES, Course.LLAMAS]:
		for o: float in list:
			if o > d + 60.0 and o < d + 330.0:
				need_fire = true
	for spit: Dictionary in _ride.get("_spits"):
		if bool(spit["alive"]) and float(spit["d"]) > d and float(spit["d"]) < d + 240.0:
			need_fire = true
	_fire_phase = (_fire_phase + 1) % 24
	if need_fire and _fire_phase < 3:
		Input.action_press("spell")
	else:
		Input.action_release("spell")


func _shoot_if_due() -> void:
	var dir: String = OS.get_environment("DCC_SHOT_DIR")
	if dir.is_empty() or _shots.is_empty():
		return
	if float(_ride.get("distance")) >= float(_shots[0]):
		var at: float = float(_shots.pop_front())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/ride_%05d.png" % [dir, int(at)])


func _run_bot(max_seconds: float) -> void:
	var t: float = 0.0
	while _finished[0] < 0 and t < max_seconds:
		_bot_frame(1.0 / 60.0)
		await get_tree().physics_frame
		t += 1.0 / 60.0
		_shoot_if_due()
		if int(_ride.get("falls")) != _last_falls:
			_last_falls = int(_ride.get("falls"))
			print("fall at t=%.2f d=%.0f" % [t, float(_ride.get("distance"))])
	Input.action_release("jump")
	Input.action_release("spell")


func _ready() -> void:
	_course_sanity()
	await _spawn()
	_check(bool(_ride.call("grounded")), "the chopper starts on the ground")
	var start: float = float(_ride.get("distance"))
	await _frames(30)
	_check(float(_ride.get("distance")) > start + 60.0, "the chopper runs on its own")
	await _tap("jump")
	await _frames(8)
	_check(float(_ride.get("height")) > 20.0, "jump lifts the chopper")
	await _spawn()
	_ride.set("distance", Course.GAPS[0][0] - 40.0)
	var waited: int = 0
	while int(_ride.get("falls")) < 1 and waited < 300:
		await _frames(1)
		waited += 1
	_check(int(_ride.get("falls")) == 1 and int(_ride.get("hearts")) == 2, "driving into a gap costs a heart (falls %d, hearts %d)" % [int(_ride.get("falls")), int(_ride.get("hearts"))])
	_check(float(_ride.get("distance")) < Course.GAPS[0][0], "a fall puts you back before the gap (%.0f)" % float(_ride.get("distance")))
	await _spawn()
	for i: int in 3:
		_ride.call("_hurt")
		_ride.set("_invuln", 0.0)
	_check(int(_ride.get("state")) == 2, "three hits wreck the chopper")
	_ride.set("distance", 3000.0)
	await _frames(100)
	_check(int(_ride.get("state")) == 0 and int(_ride.get("hearts")) == 3 and float(_ride.get("distance")) < 2600.0, "a wreck restarts at the last checkpoint with full hearts (distance %.0f)" % float(_ride.get("distance")))
	await _spawn()
	await _tap("spell")
	await _frames(5)
	_check(_ride.get("_missiles").size() >= 1, "K fires a missile")
	await _spawn()
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	_ride.call("_unhandled_input", key)
	_check(_finished[0] == 0 and not bool(_ride.get("completed")), "Esc walks instead without completing")
	await _spawn()
	var before: int = Game.checkpoint_index
	Game.chopper_return = Vector2(1660.0, 304.0)
	Game.set_checkpoint(4, Vector2(2336.0, 304.0), 4)
	_jumped_gap = -1
	await _run_bot(130.0)
	_check(_finished[0] == 1 and bool(_ride.get("completed")), "a bot clears the whole course (distance %.0f, hearts %d, falls %d, wrecks %d)" % [float(_ride.get("distance")), int(_ride.get("hearts")), int(_ride.get("falls")), int(_ride.get("wrecks"))])
	_check(Game.checkpoint_index == Course.RETURN_INDEX and Game.checkpoint_position == Course.RETURN_POSITION, "finishing sets the Level 1 return checkpoint (%d)" % Game.checkpoint_index)
	_check(Game.earned_boxes.get("Silver", 0) >= 1, "the ride earns its Silver achievement box %s" % str(Game.earned_boxes))
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)
