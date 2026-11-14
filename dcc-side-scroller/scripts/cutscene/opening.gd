extends Node

signal finished

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const DIR: String = "res://assets/cutscene/"
const ROOM_SIZE: Vector2 = Vector2(640.0, 360.0)
const DONUT_FRAME: Vector2i = Vector2i(56, 48)
const DONUT_SCALE: float = 0.5
const HEAD_TOP: float = 78.0
const DONUT_ANIMS: Dictionary = {
	"sit": {"row": 0, "count": 3, "fps": 3.0, "loop": true},
	"leap": {"row": 0, "count": 2, "fps": 6.0, "loop": false},
	"head": {"row": 0, "count": 1, "fps": 1.0, "loop": false},
	"tree": {"row": 0, "count": 1, "fps": 1.0, "loop": false},
}
const CARL_SIT_POS: Vector2 = Vector2(215.0, 318.0)
const CARL_ROOM_SCALE: float = 2.0
const CARL_WALK_Y: float = 308.0
const DONUT_SILL_POS: Vector2 = Vector2(510.0, 215.0)
const DOOR_X: float = 48.0
const BUILDINGS: Array = [["bld_a", 135.0], ["bld_b", 270.0], ["bld_c", 415.0], ["bld_d", 565.0]]
const TREE_SIZE: Vector2 = Vector2(90.0, 150.0)
const TREE_BRANCH: Vector2 = Vector2(62.0, 65.0)
const TREE_OFFSET: float = 75.0
const GLYPH_LETTERS: String = "DUNGEOSCRLA"
const GLYPH_SMALL: Dictionary = {"y": 0, "cell": Vector2(100.0, 85.0), "n": 5.0, "advance": [65, 65, 65, 65, 60, 70, 60, 65, 70, 55, 75]}
const GLYPH_LARGE: Dictionary = {"y": 85, "cell": Vector2(160.0, 136.0), "n": 8.0, "advance": [104, 104, 104, 104, 96, 112, 96, 104, 112, 88, 120]}
const TITLE_LINES: Array = [["DUNGEON", "small", -126.0], ["SCROLLER", "small", -44.0], ["CARL", "large", 66.0]]
const TITLE_CENTER_OFFSET: float = 8.0
const TITLE_FALL: float = 280.0
const TITLE_LETTER_STEP: float = 0.055
const SKY_SIZE: Vector2 = Vector2(640.0, 720.0)
const SKIP_GRACE: float = 0.4
const WELCOME_TITLE: String = "WELCOME TO\nDUNGEON SCROLLER WORLD"
const WELCOME_SECONDS: float = 4.0
const DUST_COLOR: Color = Color(0.72, 0.68, 0.7, 0.85)

var _level: Node2D
var _player: CharacterBody2D
var _camera: Camera2D
var _hud: CanvasLayer
var _start: Vector2 = Vector2.ZERO
var _vp: Vector2 = ROOM_SIZE
var _skipped: bool = false
var _age: float = 0.0
var _tweens: Array[Tween] = []
var _layers: Array[Node] = []
var _actors: Node2D
var _fade: ColorRect
var _flash: ColorRect
var _room: Node2D
var _carl: AnimatedSprite2D
var _donut: AnimatedSprite2D
var _title_letters: Array[Sprite2D] = []
var _title_base: Array[float] = []
var _title_ready: bool = false


func play(level: Node2D, player: CharacterBody2D, camera: Camera2D, hud: CanvasLayer) -> void:
	_level = level
	_player = player
	_camera = camera
	_hud = hud
	_start = player.global_position
	_vp = get_viewport().get_visible_rect().size
	player.visible = false
	player.set("control_enabled", false)
	hud.visible = false
	_build_overlay_layers()
	await _run()
	_cleanup()
	finished.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if _skipped or _age < SKIP_GRACE:
		return
	var pressed: bool = false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		_skipped = true
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_age += delta
	if _title_ready:
		for index: int in _title_letters.size():
			var letter: Sprite2D = _title_letters[index]
			if is_instance_valid(letter):
				letter.position.y = _title_base[index] + sin(_age * 2.6 + float(index) * 0.55) * 1.6


func _run() -> void:
	await _interior()
	if _skipped:
		return
	await _street()
	if _skipped:
		return
	await _logo_and_pan()


func _wait(seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and not _skipped:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _tween() -> Tween:
	var tween: Tween = create_tween()
	_tweens.append(tween)
	return tween


func _layer(order: int) -> CanvasLayer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = order
	add_child(layer)
	_layers.append(layer)
	return layer


func _tex(file: String, fallback_size: Vector2i, fallback_color: Color) -> Texture2D:
	var path: String = DIR + file + ".png"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image: Image = Image.create(fallback_size.x, fallback_size.y, false, Image.FORMAT_RGBA8)
	image.fill(fallback_color)
	return ImageTexture.create_from_image(image)


func _build_overlay_layers() -> void:
	var fade_layer: CanvasLayer = _layer(95)
	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.modulate.a = 0.0
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_flash)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 1.0
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


func _fade_to(alpha: float, seconds: float) -> void:
	_tween().tween_property(_fade, "modulate:a", alpha, seconds)
	await _wait(seconds)


func _flash_white(strength: float, seconds: float) -> void:
	_flash.modulate.a = strength
	_tween().tween_property(_flash, "modulate:a", 0.0, seconds)


func _bubble(parent: Node, text: String, pos: Vector2) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	parent.add_child(label)
	return label


func _interior() -> void:
	var layer: CanvasLayer = _layer(80)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)
	_room = Node2D.new()
	_room.position = (_vp - ROOM_SIZE) * 0.5
	layer.add_child(_room)
	var room_sprite: Sprite2D = Sprite2D.new()
	room_sprite.texture = _tex("apt_room", Vector2i(640, 360), Color(0.12, 0.1, 0.2))
	room_sprite.centered = false
	_room.add_child(room_sprite)
	_carl = _gameplay_carl()
	_carl.position = CARL_SIT_POS
	_carl.scale = Vector2.ONE * CARL_ROOM_SCALE * Game.skin_scale()
	_room.add_child(_carl)
	_carl.play("idle")
	_donut = _gameplay_donut()
	_donut.position = DONUT_SILL_POS
	_donut.scale = Vector2.ONE * CARL_ROOM_SCALE * DONUT_SCALE
	_room.add_child(_donut)
	_donut.play("sit")
	var caption: Label = _bubble(_room, "SEATTLE  -  2:23 AM", Vector2(18.0, 14.0))
	caption.modulate.a = 0.0
	_tween().tween_property(caption, "modulate:a", 1.0, 0.6).set_delay(0.6)
	await _fade_to(0.0, 0.8)
	await _wait(2.4)
	if _skipped:
		return
	_donut.play("leap")
	_donut.frame = 0
	await _wait(0.35)
	_donut.frame = 1
	var leap: Tween = _tween()
	leap.tween_property(_donut, "position:x", 548.0, 0.55).set_trans(Tween.TRANS_SINE)
	leap.parallel().tween_property(_donut, "position:y", 128.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.tween_property(_donut, "position:y", 150.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	leap.parallel().tween_property(_donut, "scale", Vector2.ONE * CARL_ROOM_SCALE * DONUT_SCALE * 0.55, 0.3)
	leap.parallel().tween_property(_donut, "modulate:a", 0.0, 0.3)
	await _wait(1.2)
	if _skipped:
		return
	var shout: Label = _bubble(_room, "Goddamnit, Donut.", CARL_SIT_POS + Vector2(-60.0, -128.0))
	await _wait(1.5)
	shout.queue_free()
	await _wait(0.5)
	_carl.scale.x = -absf(_carl.scale.x)
	_carl.play("run")
	var walk: Tween = _tween()
	walk.tween_property(_carl, "position:x", DOOR_X, 1.15)
	walk.parallel().tween_property(_carl, "position:y", CARL_WALK_Y, 0.3)
	await _wait(1.15)
	_tween().tween_property(_carl, "modulate:a", 0.0, 0.2)
	_tween().tween_property(_room, "position:x", _room.position.x + 4.0, 0.05).set_trans(Tween.TRANS_BOUNCE)
	await _wait(0.5)
	await _fade_to(1.0, 0.4)
	layer.queue_free()


func _street() -> void:
	_actors = Node2D.new()
	_actors.z_index = 200
	_level.add_child(_actors)
	var ground: float = _start.y
	var cam_left: float = _camera.global_position.x - _vp.x * 0.5 + (_vp.x - ROOM_SIZE.x) * 0.5
	var buildings: Array[Sprite2D] = []
	for entry: Array in BUILDINGS:
		var tex: Texture2D = _tex(str(entry[0]), Vector2i(140, 440), Color(0.16, 0.14, 0.24))
		var building: Sprite2D = Sprite2D.new()
		building.texture = tex
		building.centered = false
		building.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
		building.position = Vector2(cam_left + float(entry[1]), ground)
		building.z_index = -40
		_actors.add_child(building)
		buildings.append(building)
	var tree_tex: Texture2D = _tex("tree", Vector2i(90, 150), Color(0.2, 0.12, 0.1))
	var tree: Sprite2D = Sprite2D.new()
	tree.texture = tree_tex
	tree.centered = false
	tree.offset = Vector2(-tree_tex.get_width() * 0.5, -tree_tex.get_height())
	tree.position = Vector2(_start.x + TREE_OFFSET, ground)
	tree.z_index = -20
	_actors.add_child(tree)
	var cat: AnimatedSprite2D = _gameplay_donut()
	cat.scale = Vector2.ONE * DONUT_SCALE
	cat.position = tree.position + Vector2(TREE_BRANCH.x - tree_tex.get_width() * 0.5, TREE_BRANCH.y - tree_tex.get_height())
	_actors.add_child(cat)
	cat.play("tree")
	var carl: AnimatedSprite2D = _gameplay_carl()
	carl.scale = Vector2.ONE * Game.skin_scale()
	carl.position = Vector2(cam_left - 50.0, ground)
	_actors.add_child(carl)
	carl.play("run")
	_donut = cat
	_carl = carl
	await _fade_to(0.0, 0.7)
	_tween().tween_property(carl, "position:x", _start.x, 1.5)
	await _wait(1.5)
	carl.play("shock")
	await _wait(1.1)
	if _skipped:
		return
	_flash_white(0.95, 0.3)
	Game.shake(16.0, 1.4)
	carl.play("stagger")
	_tween().tween_property(carl, "position:x", _start.x - 14.0, 0.25)
	for index: int in buildings.size():
		var building: Sprite2D = buildings[index]
		var crush: Tween = _tween()
		crush.tween_interval(0.05 + float(index) * 0.09)
		crush.tween_property(building, "scale:y", 0.04, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		crush.tween_callback(_dust.bind(building.position, float(building.texture.get_width())))
		crush.tween_interval(1.4)
		crush.tween_property(building, "modulate:a", 0.0, 0.6)
	await _wait(2.2)
	if _skipped:
		return
	_tween().tween_property(carl, "position:x", _start.x, 0.3)
	carl.play("stand")


func _gameplay_carl() -> AnimatedSprite2D:
	var sheet: Texture2D = Game.skin_sheet()
	if Game.selected_skin == Game.DEFAULT_SKIN:
		sheet = load(DIR + "carl_nodonut.png") as Texture2D
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(sheet, Game.skin_frame(), Game.skin_anims())
	var frames: SpriteFrames = sprite.sprite_frames
	_alias_pose(frames, &"stand", &"idle", 0)
	_alias_pose(frames, &"shock", &"hurt", 0)
	_alias_pose(frames, &"stagger", &"hurt", frames.get_frame_count(&"hurt") - 1)
	return sprite


func _gameplay_donut() -> AnimatedSprite2D:
	var tex: Texture2D = load(DIR + "donut_cat.png") as Texture2D
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(tex, DONUT_FRAME, DONUT_ANIMS)
	sprite.play("sit")
	return sprite


func _alias_pose(frames: SpriteFrames, pose: StringName, source: StringName, index: int) -> void:
	frames.add_animation(pose)
	frames.set_animation_speed(pose, 1.0)
	frames.set_animation_loop(pose, false)
	frames.add_frame(pose, frames.get_frame_texture(source, index))


func _dust(at: Vector2, width: float) -> void:
	var puff: CPUParticles2D = CPUParticles2D.new()
	puff.position = at + Vector2(0.0, -6.0)
	puff.z_index = 30
	puff.amount = 46
	puff.lifetime = 1.6
	puff.one_shot = true
	puff.explosiveness = 0.9
	puff.direction = Vector2.UP
	puff.spread = 75.0
	puff.initial_velocity_min = 40.0
	puff.initial_velocity_max = 150.0
	puff.gravity = Vector2(0.0, -8.0)
	puff.scale_amount_min = 3.0
	puff.scale_amount_max = 7.0
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	puff.emission_rect_extents = Vector2(width * 0.4, 3.0)
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, DUST_COLOR)
	ramp.set_color(1, Color(DUST_COLOR.r, DUST_COLOR.g, DUST_COLOR.b, 0.0))
	puff.color_ramp = ramp
	_actors.add_child(puff)
	puff.emitting = true
	get_tree().create_timer(2.5).timeout.connect(puff.queue_free)


func _logo_and_pan() -> void:
	var scale_cover: float = maxf(_vp.x / SKY_SIZE.x, _vp.y / ROOM_SIZE.y)
	var sky_layer: CanvasLayer = _layer(85)
	var sky: TextureRect = TextureRect.new()
	sky.texture = _tex("sky_pan", Vector2i(640, 720), Color(0.05, 0.03, 0.12))
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.size = SKY_SIZE * scale_cover
	sky.position = Vector2((_vp.x - sky.size.x) * 0.5, 0.0)
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sky.modulate.a = 0.0
	sky_layer.add_child(sky)
	var logo_layer: CanvasLayer = _layer(90)
	_flash_white(1.0, 0.35)
	sky.modulate.a = 1.0
	await _wait(0.5)
	if _skipped:
		return
	var title: Node2D = _build_title(logo_layer)
	await _drop_title()
	if _skipped:
		return
	await _wait(0.5)
	_shine_title()
	await _wait(2.0)
	if _skipped:
		return
	var pan_distance: float = sky.size.y
	var pan: Tween = _tween()
	pan.tween_property(sky, "position:y", -pan_distance, 4.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.parallel().tween_property(title, "modulate:a", 0.0, 1.6).set_delay(3.0)
	await _wait(4.7)
	if _skipped:
		return
	await _donut_hops_onto_head()


func _build_title(layer: CanvasLayer) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = Vector2(_vp.x * 0.5, _vp.y * 0.5 + TITLE_CENTER_OFFSET)
	layer.add_child(root)
	var embers: CPUParticles2D = CPUParticles2D.new()
	embers.position = Vector2(0.0, 120.0)
	embers.amount = 60
	embers.lifetime = 3.2
	embers.explosiveness = 0.0
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.initial_velocity_min = 25.0
	embers.initial_velocity_max = 60.0
	embers.gravity = Vector2.ZERO
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(260.0, 4.0)
	var glow: Gradient = Gradient.new()
	glow.set_color(0, Color(1.0, 0.7, 0.2, 0.95))
	glow.set_color(1, Color(1.0, 0.2, 0.1, 0.0))
	embers.color_ramp = glow
	embers.emitting = true
	root.add_child(embers)
	var atlas: Texture2D = _tex("title_glyphs", Vector2i(1672, 195), Color(1.0, 0.8, 0.1))
	_title_letters.clear()
	_title_base.clear()
	for line_index: int in TITLE_LINES.size():
		var line: Array = TITLE_LINES[line_index]
		var info: Dictionary = GLYPH_LARGE if str(line[1]) == "large" else GLYPH_SMALL
		var cell: Vector2 = info["cell"]
		var n: float = float(info["n"])
		var advance: Array = info["advance"]
		var word: String = str(line[0])
		var total: float = 0.0
		for ch: String in word:
			total += float(advance[GLYPH_LETTERS.find(ch)]) + n
		total -= n
		var cursor: float = -total * 0.5
		for ch: String in word:
			var col: int = GLYPH_LETTERS.find(ch)
			var letter: Sprite2D = Sprite2D.new()
			var region: AtlasTexture = AtlasTexture.new()
			region.atlas = atlas
			region.region = Rect2(float(col) * cell.x, float(info["y"]), cell.x, cell.y)
			letter.texture = region
			letter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var target_y: float = float(line[2])
			letter.position = Vector2(cursor - n * 2.0 + cell.x * 0.5, target_y - TITLE_FALL)
			letter.modulate.a = 0.0
			letter.scale = Vector2(0.8, 1.25)
			letter.z_index = TITLE_LINES.size() - line_index
			root.add_child(letter)
			_title_letters.append(letter)
			_title_base.append(target_y)
			cursor += float(advance[col]) + n
	return root


func _drop_title() -> void:
	var index: int = 0
	var delay: float = 0.0
	var last_time: float = 0.0
	for line_index: int in TITLE_LINES.size():
		var word: String = str(TITLE_LINES[line_index][0])
		var is_big: bool = line_index == TITLE_LINES.size() - 1
		for letter_index: int in word.length():
			var letter: Sprite2D = _title_letters[index]
			var fall: float = 0.16 if is_big else 0.22
			var last_in_word: bool = letter_index == word.length() - 1
			var tween: Tween = _tween()
			tween.tween_interval(delay)
			tween.tween_property(letter, "modulate:a", 1.0, 0.02)
			tween.tween_property(letter, "position:y", _title_base[index], fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if last_in_word:
				tween.tween_callback(_word_landed.bind(is_big))
			tween.tween_property(letter, "scale", Vector2(1.22, 0.78), 0.05)
			tween.tween_property(letter, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			last_time = delay + fall + 0.4
			delay += TITLE_LETTER_STEP
			index += 1
		delay += 0.22
	await _wait(last_time + 0.1)
	_title_ready = true


func _word_landed(big: bool) -> void:
	if big:
		Game.shake(15.0, 0.8)
		_flash_white(0.85, 0.3)
	else:
		Game.shake(5.0, 0.25)


func _shine_title() -> void:
	for index: int in _title_letters.size():
		var letter: Sprite2D = _title_letters[index]
		var tween: Tween = _tween()
		tween.tween_interval(float(index) * 0.06)
		tween.tween_property(letter, "self_modulate", Color(2.4, 2.4, 1.8), 0.07)
		tween.tween_property(letter, "self_modulate", Color.WHITE, 0.25)


func _donut_hops_onto_head() -> void:
	var landing: Vector2 = _carl.position + Vector2(0.0, -HEAD_TOP * Game.skin_scale())
	_donut.play("leap")
	_donut.frame = 0
	await _wait(0.2)
	_donut.frame = 1
	var hop: Tween = _tween()
	hop.tween_property(_donut, "position:x", landing.x, 0.5).set_trans(Tween.TRANS_SINE)
	hop.parallel().tween_property(_donut, "position:y", minf(_donut.position.y, landing.y) - 18.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(_donut, "position:y", landing.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(0.6)
	_donut.play("head")
	await _wait(0.3)
	var original: AnimatedSprite2D = SpriteUtil.make_sprite(Game.skin_sheet(), Game.skin_frame(), Game.skin_anims())
	original.position = _carl.position
	original.scale = _carl.scale
	_carl.get_parent().add_child(original)
	_carl.queue_free()
	_donut.queue_free()
	_carl = original
	_carl.play("idle")
	await _wait(0.5)


func _cleanup() -> void:
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	if is_instance_valid(_actors):
		_actors.queue_free()
	for layer: Node in _layers:
		if is_instance_valid(layer):
			layer.queue_free()
	_player.visible = true
	_hud.visible = true
	_player.set("control_enabled", true)
	if not _skipped:
		_hud.call("show_system_message", WELCOME_TITLE, "", WELCOME_SECONDS)
