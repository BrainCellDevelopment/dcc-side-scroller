extends Node2D
## Goblin Copper Chopper ride (#69): an optional auto-run between the workshop and the Swine arena.
## Space jumps, K fires Donut's missiles from the sidecar, Esc walks instead. Everything is
## placed from chopper_course.gd; positions there are distances along the track, drawn at x = -distance.

signal left(completed: bool)

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const Course: GDScript = preload("res://scripts/data/chopper_course.gd")
const PROPS: String = "res://assets/props/"
const GROUND_Y: float = 296.0
const VIEW: Vector2 = Vector2(640.0, 360.0)
const LOOK_AHEAD: float = 150.0
const BASE_SPEED: float = 175.0
const BOOST_SPEED: float = 300.0
const EMPTY_SPEED: float = 95.0
const SMASH_SLOW: float = 0.55
const ACCEL: float = 520.0
const GRAVITY: float = 1500.0
const JUMP_VELOCITY: float = -560.0
const JUMP_BUFFER: float = 0.12
const FALL_DEPTH: float = 110.0
const HALF_WIDTH: float = 30.0
const BODY_HEIGHT: float = 34.0
const MAX_HEARTS: int = 3
const COAL_MAX: float = 100.0
const COAL_DRAIN: float = 4.0
const COAL_PICKUP: float = 30.0
const BARRICADE_COAL_COST: float = 12.0
const VALVE_COAL: float = 20.0
const BOOST_SECONDS: float = 2.4
const SMASH_SECONDS: float = 1.0
const INVULN_SECONDS: float = 1.3
const MISSILE_SPEED: float = 560.0
const MISSILE_RANGE: float = 520.0
const MISSILE_COOLDOWN: float = 0.35
const SPIT_SPEED: float = 230.0
const SPIT_TRIGGER: float = 460.0
const SPIT_COOLDOWN: float = 1.8
const SPIT_HEIGHT: float = 26.0
const WRECK_SECONDS: float = 1.4
const WRECKS_BEFORE_OFFER: int = 3
const FINISH_SECONDS: float = 1.6
const FADE_SECONDS: float = 0.45

enum State { RUNNING, FALLING, WRECKED, FINISHING, DONE }

@export var auto_change_scene: bool = true

var state: State = State.RUNNING
var distance: float = 0.0
var height: float = 0.0
var hearts: int = MAX_HEARTS
var coal: float = COAL_MAX
var wrecks: int = 0
var falls: int = 0
var speed: float = BASE_SPEED
var completed: bool = false
var checkpoint: float = 0.0

var _vy: float = 0.0
var _boost_left: float = 0.0
var _smash_left: float = 0.0
var _invuln: float = 0.0
var _fire_cooldown: float = 0.0
var _jump_buffer: float = 0.0
var _state_time: float = 0.0
var _last_cp_shown: float = 0.0
var _objects: Array[Dictionary] = []
var _missiles: Array[Dictionary] = []
var _spits: Array[Dictionary] = []
var _rig: Node2D
var _chopper: AnimatedSprite2D
var _camera: Camera2D
var _parallax: Array[Dictionary] = []
var _world: Node2D
var _hearts_boxes: Array[ColorRect] = []
var _coal_fill: ColorRect
var _progress_fill: ColorRect
var _message: Label
var _hint: Label
var _fade: ColorRect
var _tex: Dictionary = {}


func _ready() -> void:
	Game.menu_open = false
	_world = Node2D.new()
	add_child(_world)
	_build_background()
	_build_ground()
	_build_objects()
	_build_rig()
	_build_hud()
	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_update_view()
	_fade_in()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		leave(false)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)
	_boost_left = maxf(_boost_left - delta, 0.0)
	_smash_left = maxf(_smash_left - delta, 0.0)
	if state == State.DONE:
		return
	if state == State.WRECKED:
		if _state_time >= WRECK_SECONDS:
			_respawn_at_checkpoint()
		_update_view()
		return
	if state == State.FINISHING:
		speed = move_toward(speed, 0.0, 260.0 * delta)
		distance += speed * delta
		if speed <= 1.0 and _state_time >= FINISH_SECONDS:
			leave(true)
		_update_objects(delta)
		_update_view()
		return
	_read_input(delta)
	_update_speed(delta)
	distance += speed * delta
	_update_vertical(delta)
	_update_objects(delta)
	_check_checkpoint()
	if distance >= Course.LENGTH and state == State.RUNNING:
		_begin_finish()
	_update_view()


func leave(finished_ride: bool) -> void:
	if state == State.DONE:
		return
	state = State.DONE
	completed = finished_ride
	if finished_ride:
		Game.set_checkpoint(Course.RETURN_INDEX, Course.RETURN_POSITION, Course.RETURN_STAGE)
		SystemVoice.fire("chopper_ride")
	elif Game.chopper_return != Vector2.ZERO:
		Game.checkpoint_position = Game.chopper_return
	left.emit(finished_ride)
	if not auto_change_scene:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(_change_scene)


func _change_scene() -> void:
	get_tree().change_scene_to_file(Course.LEVEL_SCENE)


func grounded() -> bool:
	return state == State.RUNNING and height <= 0.5


func _read_input(delta: float) -> void:
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if Game.action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if _jump_buffer > 0.0 and grounded():
		_vy = JUMP_VELOCITY
		_jump_buffer = 0.0
		_dust()
	if Game.action_just_pressed("spell") and _fire_cooldown <= 0.0:
		_fire_missile()


func _update_speed(delta: float) -> void:
	var target: float = BOOST_SPEED if _boost_left > 0.0 else BASE_SPEED
	if coal <= 0.0:
		target = minf(target, EMPTY_SPEED)
	if _smash_left > 0.0:
		target *= SMASH_SLOW
	speed = move_toward(speed, target, ACCEL * delta)
	coal = maxf(coal - COAL_DRAIN * delta, 0.0)


func _update_vertical(delta: float) -> void:
	_vy += GRAVITY * delta
	height -= _vy * delta
	if state == State.FALLING:
		if height < -FALL_DEPTH:
			_fell()
		return
	if height <= 0.0 and _vy >= 0.0:
		if Course.in_gap(distance):
			state = State.FALLING
			return
		if _vy > 80.0:
			_dust()
		height = 0.0
		_vy = 0.0


func _update_objects(delta: float) -> void:
	for obj: Dictionary in _objects:
		if not bool(obj["alive"]):
			continue
		var d: float = float(obj["d"])
		var node: Node2D = obj["node"] as Node2D
		match str(obj["kind"]):
			"llama":
				_update_llama(obj, delta)
			"sticker", "barricade", "valve", "coal":
				if state == State.FINISHING or absf(d - distance) > HALF_WIDTH + 40.0:
					continue
				_collide_object(obj, node)
	_update_missiles(delta)
	_update_spits(delta)
	_animate_invuln()


func _collide_object(obj: Dictionary, node: Node2D) -> void:
	var d: float = float(obj["d"])
	var reach: float = HALF_WIDTH + float(obj["w"]) * 0.5
	if absf(d - distance) >= reach:
		return
	var low: float = height
	match str(obj["kind"]):
		"sticker":
			if low < float(obj["h"]):
				_kill_object(obj)
				_explode(node.global_position + Vector2(0.0, -6.0))
				_hurt()
		"barricade":
			if low < float(obj["h"]):
				_kill_object(obj)
				_explode(node.global_position + Vector2(0.0, -16.0))
				_smash_left = SMASH_SECONDS
				coal = maxf(coal - BARRICADE_COAL_COST, 0.0)
				Game.shake(4.0, 0.25)
		"valve":
			if low < float(obj["h"]) and not bool(obj.get("used", false)):
				obj["used"] = true
				_boost_left = BOOST_SECONDS
				coal = minf(coal + VALVE_COAL, COAL_MAX)
				_flash("STEAM!")
		"coal":
			var rise: float = float(obj["rise"])
			if absf(low + 14.0 - (rise + 6.0)) < 34.0:
				_kill_object(obj)
				coal = minf(coal + COAL_PICKUP, COAL_MAX)


func _update_llama(obj: Dictionary, delta: float) -> void:
	var d: float = float(obj["d"])
	var sprite: AnimatedSprite2D = obj["sprite"] as AnimatedSprite2D
	obj["cooldown"] = maxf(float(obj["cooldown"]) - delta, 0.0)
	var ahead: float = d - distance
	if ahead < 40.0 or ahead > SPIT_TRIGGER:
		return
	if float(obj["cooldown"]) > 0.0:
		return
	obj["cooldown"] = SPIT_COOLDOWN
	sprite.play("windup")
	var timer: SceneTreeTimer = get_tree().create_timer(0.35)
	timer.timeout.connect(_llama_spit.bind(obj))


func _llama_spit(obj: Dictionary) -> void:
	if state == State.DONE or not bool(obj["alive"]):
		return
	var sprite: AnimatedSprite2D = obj["sprite"] as AnimatedSprite2D
	sprite.play("spit")
	var ball: AnimatedSprite2D = SpriteUtil.make_sprite(_texture("res://assets/fx/lava_ball.png"), Vector2i(10, 10), {"fly": {"row": 0, "count": 4, "fps": 12.0, "loop": true}})
	ball.play("fly")
	ball.z_index = 6
	_world.add_child(ball)
	var d: float = float(obj["d"]) - 24.0
	ball.position = Vector2(-d, GROUND_Y - SPIT_HEIGHT + 5.0)
	_spits.append({"d": d, "node": ball, "alive": true})
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_instance_valid(sprite) and sprite.sprite_frames != null:
			sprite.play("idle"))


func _update_spits(delta: float) -> void:
	for spit: Dictionary in _spits:
		if not bool(spit["alive"]):
			continue
		spit["d"] = float(spit["d"]) - SPIT_SPEED * delta
		var node: Node2D = spit["node"] as Node2D
		node.position.x = -float(spit["d"])
		var gap: float = absf(float(spit["d"]) - distance)
		if gap < HALF_WIDTH + 5.0 and state == State.RUNNING:
			var ball_low: float = SPIT_HEIGHT - 5.0
			var ball_high: float = SPIT_HEIGHT + 5.0
			if height < ball_high and height + BODY_HEIGHT > ball_low:
				spit["alive"] = false
				node.queue_free()
				_hurt()
		if float(spit["d"]) < distance - 200.0:
			spit["alive"] = false
			node.queue_free()


func _fire_missile() -> void:
	_fire_cooldown = MISSILE_COOLDOWN
	var tex: Texture2D = _texture("res://assets/fx/magic_missile.png")
	var node: AnimatedSprite2D = SpriteUtil.make_sprite(tex, Vector2i(14, 8), {"fly": {"row": 0, "count": 4, "fps": 16.0, "loop": true}})
	node.play("fly")
	node.scale.x = -1.0
	node.z_index = 7
	_world.add_child(node)
	var start: float = distance + 34.0
	var low: float = height + 12.0
	node.position = Vector2(-start, GROUND_Y - low + 4.0)
	_missiles.append({"d": start, "start": start, "low": low, "node": node, "alive": true})
	Game.report_spell_cast()


func _update_missiles(delta: float) -> void:
	for missile: Dictionary in _missiles:
		if not bool(missile["alive"]):
			continue
		var node: Node2D = missile["node"] as Node2D
		missile["d"] = float(missile["d"]) + MISSILE_SPEED * delta
		node.position.x = -float(missile["d"])
		var d: float = float(missile["d"])
		var low: float = float(missile["low"])
		var hit: bool = false
		for obj: Dictionary in _objects:
			if not bool(obj["alive"]):
				continue
			var kind: String = str(obj["kind"])
			if kind != "sticker" and kind != "barricade" and kind != "llama":
				continue
			if absf(float(obj["d"]) - d) < float(obj["w"]) * 0.5 + 6.0 and low < float(obj["h"]):
				_kill_object(obj)
				_explode((obj["node"] as Node2D).global_position + Vector2(0.0, -10.0))
				hit = true
				break
		if not hit:
			for spit: Dictionary in _spits:
				if bool(spit["alive"]) and absf(float(spit["d"]) - d) < 12.0 and absf(low - SPIT_HEIGHT) < 18.0:
					spit["alive"] = false
					(spit["node"] as Node2D).queue_free()
					_explode(node.global_position)
					hit = true
					break
		if hit or d - float(missile["start"]) > MISSILE_RANGE:
			missile["alive"] = false
			node.queue_free()


func _kill_object(obj: Dictionary) -> void:
	obj["alive"] = false
	(obj["node"] as Node2D).visible = false


func _hurt() -> void:
	if _invuln > 0.0 or (state != State.RUNNING and state != State.FALLING):
		return
	hearts -= 1
	_invuln = INVULN_SECONDS
	Game.shake(6.0, 0.3)
	if hearts <= 0:
		_wreck()
	else:
		_refresh_hud()


func _wreck() -> void:
	state = State.WRECKED
	_state_time = 0.0
	wrecks += 1
	speed = 0.0
	_rig.visible = true
	_flash("WRECKED")
	if wrecks >= WRECKS_BEFORE_OFFER:
		_hint.text = "Esc: walk the rest instead"
	_refresh_hud()


func _respawn_at_checkpoint() -> void:
	distance = Course.last_checkpoint(distance)
	_reset_after(distance)
	hearts = MAX_HEARTS
	coal = maxf(coal, 60.0)
	_restore_run()


func _fell() -> void:
	falls += 1
	hearts -= 1
	if hearts <= 0:
		_wreck()
		return
	var cp: float = Course.last_checkpoint(distance)
	distance = maxf(cp, Course.gap_start_before(distance) - 160.0)
	_reset_after(distance)
	_restore_run()
	_invuln = INVULN_SECONDS * 1.4
	_refresh_hud()


func _restore_run() -> void:
	state = State.RUNNING
	height = 0.0
	_vy = 0.0
	speed = BASE_SPEED
	_boost_left = 0.0
	_smash_left = 0.0
	_state_time = 0.0
	_refresh_hud()


func _reset_after(from_distance: float) -> void:
	for obj: Dictionary in _objects:
		if float(obj["d"]) >= from_distance and not bool(obj["alive"]):
			obj["alive"] = true
			obj["used"] = false
			(obj["node"] as Node2D).visible = true
	for spit: Dictionary in _spits:
		if bool(spit["alive"]):
			spit["alive"] = false
			(spit["node"] as Node2D).queue_free()


func _check_checkpoint() -> void:
	var cp: float = Course.last_checkpoint(distance)
	if cp > checkpoint:
		checkpoint = cp
	if cp > _last_cp_shown and cp > 0.0:
		_last_cp_shown = cp
		_flash("CHECKPOINT")


func _begin_finish() -> void:
	state = State.FINISHING
	_state_time = 0.0
	_flash("END OF THE LINE")


func _update_view() -> void:
	_rig.position = Vector2(-distance, GROUND_Y - height)
	_chopper.speed_scale = clampf(speed / BASE_SPEED, 0.2, 2.2)
	_camera.global_position = Vector2(-distance - LOOK_AHEAD, VIEW.y * 0.5)
	for layer: Dictionary in _parallax:
		var sprite: Sprite2D = layer["sprite"] as Sprite2D
		var f: float = float(layer["factor"])
		sprite.position.x = _camera.global_position.x - VIEW.x * 0.5
		var region: Rect2 = sprite.region_rect
		region.position.x = _camera.global_position.x * f
		sprite.region_rect = region
	_refresh_hud()


func _animate_invuln() -> void:
	if _invuln > 0.0:
		_rig.modulate.a = 0.35 if int(_invuln * 14.0) % 2 == 0 else 1.0
	else:
		_rig.modulate.a = 1.0


func _texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path)
	return _tex[path] as Texture2D


func _build_background() -> void:
	var layers: Array = [
		["res://assets/bg/bg_floor1_corridor_far.png", 0.15, 640, -100],
		["res://assets/bg/bg_floor1_corridor_mid.png", 0.45, 960, -90],
		["res://assets/bg/bg_floor1_corridor_near.png", 0.75, 960, -80],
	]
	for entry: Array in layers:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = _texture(str(entry[0]))
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_rect = Rect2(0.0, 0.0, VIEW.x, VIEW.y)
		sprite.z_index = int(entry[3])
		_world.add_child(sprite)
		_parallax.append({"sprite": sprite, "factor": float(entry[1])})


func _build_ground() -> void:
	var tiles: Texture2D = _texture("res://assets/tiles/tiles_brick.png")
	var edges: Array[float] = [0.0]
	for gap: Array in Course.GAPS:
		edges.append(float(gap[0]))
		edges.append(float(gap[1]))
	edges.append(Course.LENGTH + 1200.0)
	for i: int in range(0, edges.size(), 2):
		var from_d: float = edges[i] - (900.0 if i == 0 else 0.0)
		var to_d: float = edges[i + 1]
		var ground: Sprite2D = Sprite2D.new()
		ground.texture = tiles
		ground.centered = false
		ground.region_enabled = true
		ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		ground.region_rect = Rect2(0.0, 0.0, to_d - from_d, 80.0)
		ground.position = Vector2(-to_d, GROUND_Y)
		ground.z_index = 1
		_world.add_child(ground)
		var lip: ColorRect = ColorRect.new()
		lip.color = Color(0.72, 0.36, 0.26)
		lip.size = Vector2(to_d - from_d, 2.0)
		lip.position = Vector2(-to_d, GROUND_Y)
		lip.z_index = 2
		_world.add_child(lip)
		var deep: ColorRect = ColorRect.new()
		deep.color = Color(0.1, 0.04, 0.06)
		deep.size = Vector2(to_d - from_d, 1600.0)
		deep.position = Vector2(-to_d, GROUND_Y + 80.0)
		deep.z_index = 1
		_world.add_child(deep)


func _add_object(kind: String, d: float, node: Node2D, w: float, h: float, rise: float = 0.0) -> Dictionary:
	node.z_index = 4
	node.position = Vector2(-d, GROUND_Y - rise)
	_world.add_child(node)
	var obj: Dictionary = {"kind": kind, "d": d, "node": node, "w": w, "h": h, "rise": rise, "alive": true, "used": false, "cooldown": 0.0}
	_objects.append(obj)
	return obj


func _prop_sprite(file: String, frame: Vector2i, count: int, fps: float) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(_texture(PROPS + file), frame, {"idle": {"row": 0, "count": count, "fps": fps, "loop": true}})
	sprite.play("idle")
	sprite.scale.x = -1.0
	return sprite


func _build_objects() -> void:
	for d: float in Course.STICKERS:
		_add_object("sticker", d, _prop_sprite("rot_sticker.png", Vector2i(24, 16), 2, 4.0), 22.0, 14.0)
	for d: float in Course.BARRICADES:
		_add_object("barricade", d, _prop_sprite("chopper_barricade.png", Vector2i(32, 40), 1, 1.0), 28.0, 38.0)
	for d: float in Course.VALVES:
		_add_object("valve", d, _prop_sprite("steam_valve.png", Vector2i(24, 32), 2, 5.0), 20.0, 30.0)
	for entry: Array in Course.COAL:
		_add_object("coal", float(entry[0]), _prop_sprite("coal.png", Vector2i(16, 12), 1, 1.0), 14.0, 20.0, float(entry[1]))
	for d: float in Course.LLAMAS:
		var llama: AnimatedSprite2D = SpriteUtil.make_sprite(_texture("res://assets/characters/llama.png"), Vector2i(72, 56), {
			"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true},
			"windup": {"row": 2, "count": 3, "fps": 6.0, "loop": false},
			"spit": {"row": 3, "count": 2, "fps": 8.0, "loop": false},
		})
		llama.play("idle")
		var obj: Dictionary = _add_object("llama", d, llama, 40.0, 40.0)
		obj["sprite"] = llama
	var arrow: Sprite2D = Sprite2D.new()
	arrow.texture = _texture("res://assets/props/spray_arrow.png")
	arrow.scale = Vector2(-2.0, 2.0)
	arrow.position = Vector2(-Course.ARROW_AT, GROUND_Y - 44.0)
	arrow.z_index = 3
	_world.add_child(arrow)
	for cp: float in Course.CHECKPOINTS:
		if cp <= 0.0:
			continue
		var post: Sprite2D = Sprite2D.new()
		post.texture = _texture("res://assets/props/checkpoint.png")
		post.centered = false
		post.position = Vector2(-cp - post.texture.get_width() * 0.5, GROUND_Y - post.texture.get_height())
		post.z_index = 3
		_world.add_child(post)


func _build_rig() -> void:
	_rig = Node2D.new()
	_rig.z_index = 5
	_world.add_child(_rig)
	var carl: AnimatedSprite2D = SpriteUtil.make_sprite(_texture("res://assets/cutscene/carl_nodonut.png"), Vector2i(136, 136), {"idle": {"row": 0, "count": 8, "fps": 10.0, "loop": true}})
	carl.play("idle")
	carl.scale = Vector2.ONE * 0.5
	carl.position = Vector2(-8.0, -24.0)
	carl.z_index = -1
	var donut: AnimatedSprite2D = SpriteUtil.make_sprite(_texture("res://assets/cutscene/donut_cat.png"), Vector2i(56, 48), {"sit": {"row": 0, "count": 3, "fps": 3.0, "loop": true}})
	donut.play("sit")
	donut.scale = Vector2.ONE * 0.5
	donut.position = Vector2(-34.0, -21.0)
	donut.z_index = -1
	_chopper = SpriteUtil.make_sprite(_texture(PROPS + "chopper.png"), Vector2i(104, 48), {"ride": {"row": 0, "count": 4, "fps": 12.0, "loop": true}})
	_chopper.play("ride")
	_rig.add_child(carl)
	_rig.add_child(donut)
	_rig.add_child(_chopper)
	_rig.scale.x = -1.0


func _build_hud() -> void:
	var hud: CanvasLayer = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	for i: int in MAX_HEARTS:
		var heart: ColorRect = ColorRect.new()
		heart.size = Vector2(10.0, 10.0)
		heart.position = Vector2(10.0 + float(i) * 14.0, 10.0)
		hud.add_child(heart)
		_hearts_boxes.append(heart)
	var coal_bg: ColorRect = ColorRect.new()
	coal_bg.color = Color(0.08, 0.06, 0.08, 0.9)
	coal_bg.size = Vector2(80.0, 6.0)
	coal_bg.position = Vector2(10.0, 26.0)
	hud.add_child(coal_bg)
	_coal_fill = ColorRect.new()
	_coal_fill.color = Color(0.96, 0.53, 0.16)
	_coal_fill.size = Vector2(80.0, 6.0)
	coal_bg.add_child(_coal_fill)
	var prog_bg: ColorRect = ColorRect.new()
	prog_bg.color = Color(0.08, 0.06, 0.08, 0.9)
	prog_bg.size = Vector2(180.0, 4.0)
	prog_bg.position = Vector2((VIEW.x - 180.0) * 0.5, 10.0)
	hud.add_child(prog_bg)
	_progress_fill = ColorRect.new()
	_progress_fill.color = Color(0.93, 0.89, 0.75)
	_progress_fill.size = Vector2(0.0, 4.0)
	prog_bg.add_child(_progress_fill)
	_message = Label.new()
	_message.position = Vector2(0.0, 120.0)
	_message.size = Vector2(VIEW.x, 40.0)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 20)
	_message.modulate.a = 0.0
	hud.add_child(_message)
	_hint = Label.new()
	_hint.position = Vector2(0.0, VIEW.y - 22.0)
	_hint.size = Vector2(VIEW.x, 16.0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.text = "Space: jump    K: Donut fires    Esc: walk instead"
	hud.add_child(_hint)
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.size = VIEW
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 100
	hud.add_child(_fade)


func _refresh_hud() -> void:
	for i: int in _hearts_boxes.size():
		_hearts_boxes[i].color = Color(0.86, 0.2, 0.26) if i < hearts else Color(0.25, 0.12, 0.16)
	_coal_fill.size.x = 80.0 * clampf(coal / COAL_MAX, 0.0, 1.0)
	_progress_fill.size.x = 180.0 * clampf(distance / Course.LENGTH, 0.0, 1.0)


func _flash(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(_message, "modulate:a", 0.0, 0.5)


func _fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)


func _explode(at: Vector2) -> void:
	var tex: Texture2D = _texture("res://assets/fx/explosion.png")
	var fx: AnimatedSprite2D = SpriteUtil.make_sprite(tex, Vector2i(64, 64), {"boom": {"row": 0, "count": 8, "fps": 24.0, "loop": false}})
	fx.scale = Vector2.ONE * 0.5
	fx.global_position = at + Vector2(0.0, 16.0)
	fx.z_index = 8
	_world.add_child(fx)
	fx.play("boom")
	fx.animation_finished.connect(fx.queue_free)


func _dust() -> void:
	var tex: Texture2D = _texture("res://assets/fx/dust.png")
	var fx: AnimatedSprite2D = SpriteUtil.make_sprite(tex, Vector2i(16, 16), {"puff": {"row": 0, "count": 5, "fps": 14.0, "loop": false}})
	fx.global_position = _rig.global_position + Vector2(0.0, 2.0)
	fx.z_index = 6
	_world.add_child(fx)
	fx.play("puff")
	fx.animation_finished.connect(fx.queue_free)
