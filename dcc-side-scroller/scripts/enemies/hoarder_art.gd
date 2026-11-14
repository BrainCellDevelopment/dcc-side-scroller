extends Node2D
## Sprite art for the Hoarder (faces +x; hoarder.gd flips Visual.scale.x and tints Visual.modulate).
## Hand-supplied pixel art: assets/characters/hoarder_{idle,roar,run}.png (see
## art-src/floor1/import_hoarder.py). Frames are 192x160 texels, feet at the bottom centre,
## shown at half size so the figure is about 72 px tall. Pose follows the boss state.

const IDLE_TEX: Texture2D = preload("res://assets/characters/hoarder_idle.png")
const ROAR_TEX: Texture2D = preload("res://assets/characters/hoarder_roar.png")
const RUN_TEX: Texture2D = preload("res://assets/characters/hoarder_run.png")
const FRAME_SIZE: Vector2 = Vector2(192.0, 160.0)
const FEET_ROW: float = 158.0
const TEXEL: float = 0.5
const WALK_FPS: float = 8.0
const CHARGE_FPS: float = 16.0
const RUN_FRAMES: int = 8

enum State { IDLE, WALK, STOMP_WIND, STOMP_SLAM, VOMIT, CHARGE_WIND, CHARGE, RECOVER, STUNNED, DEAD }

var _boss: CharacterBody2D = null
var _t: float = 0.0
var _pivot: Node2D = null
var _idle: Sprite2D = null
var _roar: Sprite2D = null
var _run: Sprite2D = null
var _squash: float = 1.0
var _lift: float = 0.0
var _shift_x: float = 0.0
var _tilt: float = 0.0
var _fade: float = 1.0


func _ready() -> void:
	_boss = get_parent() as CharacterBody2D
	z_index = 3
	_pivot = Node2D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	_idle = _make_sprite(IDLE_TEX, 1)
	_roar = _make_sprite(ROAR_TEX, 1)
	_run = _make_sprite(RUN_TEX, RUN_FRAMES)
	_show(_idle)


func _make_sprite(tex: Texture2D, frames: int) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = frames
	sprite.centered = false
	sprite.offset = Vector2(-FRAME_SIZE.x * 0.5, -FEET_ROW)
	sprite.scale = Vector2(TEXEL, TEXEL)
	sprite.visible = false
	_pivot.add_child(sprite)
	return sprite


func _show(which: Sprite2D) -> void:
	_idle.visible = which == _idle
	_roar.visible = which == _roar
	_run.visible = which == _run


func _process(delta: float) -> void:
	_t += delta
	if _boss == null:
		return
	var st: int = int(_boss.get("state"))
	var pose: Sprite2D = _idle
	var squash: float = 1.0
	var lift: float = 0.0
	var shift_x: float = 0.0
	var tilt: float = 0.0
	var fade: float = 1.0
	match st:
		State.IDLE, State.RECOVER:
			lift = absf(sin(_t * 2.6)) * 1.2
		State.WALK, State.CHARGE:
			pose = _run
			_run.frame = int(_t * (CHARGE_FPS if st == State.CHARGE else WALK_FPS)) % RUN_FRAMES
		State.STOMP_WIND:
			pose = _roar
			lift = 4.0
		State.STOMP_SLAM:
			squash = 0.88
		State.VOMIT:
			pose = _roar
		State.CHARGE_WIND:
			shift_x = sin(_t * 70.0) * 1.2
			squash = 0.96
		State.STUNNED:
			squash = 0.9
			tilt = 0.12 + sin(_t * 3.0) * 0.02
		State.DEAD:
			tilt = -1.45
			fade = 0.0
	_show(pose)
	var k: float = clampf(delta * (6.0 if st == State.DEAD else 16.0), 0.0, 1.0)
	_squash = lerpf(_squash, squash, k)
	_lift = lerpf(_lift, lift, k)
	_shift_x = shift_x if st == State.CHARGE_WIND else lerpf(_shift_x, shift_x, k)
	_tilt = lerpf(_tilt, tilt, k)
	_fade = lerpf(_fade, fade, clampf(delta * 1.2, 0.0, 1.0)) if st == State.DEAD else 1.0
	_pivot.position = Vector2(_shift_x, -_lift)
	_pivot.scale = Vector2(1.0 / _squash if _squash < 1.0 else 1.0, _squash)
	_pivot.rotation = _tilt
	_pivot.modulate = Color(1.0, 1.0, 1.0, _fade)
