extends Node2D

const TITLE: String = "LEVEL 1"
const END_TEXT: String = "LEVEL 1\nTo be continued"
const TITLE_SECONDS: float = 2.5
const FOCUS_ON_FLOOR: float = 40.0
const Targeting: GDScript = preload("res://scripts/combat/targeting.gd")
const MISSILE_HINT: String = "Out of reach? Press K to fire magic missiles"
const HINT_RANGE: float = 380.0

var complete: bool = false

var _focus_y: float = 0.0
var _spell_used: bool = false
var _hint_shown: bool = false
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_total: float = 0.01

@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: CanvasLayer = $HUD
@onready var _end_zone: Area2D = $Triggers/EndZone
@onready var _intro_thrower: Node2D = $Goblins/IntroThrower


func _ready() -> void:
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_player.call("_set_facing", -1)
	_player.connect("died", _on_player_died)
	_end_zone.body_entered.connect(_on_end_entered)
	Game.screen_shake.connect(_on_screen_shake)
	Game.spell_cast.connect(_on_spell_cast)
	_player.call("enable_spell")
	Game.report_player_health(int(_player.get("health")), int(_player.get("max_health")))
	_snap_camera()
	_hud.call("show_banner", TITLE, TITLE_SECONDS)


func _physics_process(delta: float) -> void:
	_camera.global_position = _follow_target()
	_update_shake(delta)
	_update_hint()


func _follow_target() -> Vector2:
	var view: Vector2 = get_viewport().get_visible_rect().size / _camera.zoom
	var py: float = _player.global_position.y
	if _player.is_on_floor():
		_focus_y = py - FOCUS_ON_FLOOR
	else:
		var low: float = view.y * 0.28
		var high: float = view.y * 0.3
		if py > _focus_y + low:
			_focus_y = py - low
		elif py < _focus_y - high:
			_focus_y = py + high
	return Vector2(_player.global_position.x, _focus_y)


func _snap_camera() -> void:
	_focus_y = _player.global_position.y - FOCUS_ON_FLOOR
	_camera.global_position = _follow_target()
	_camera.reset_smoothing()
	_camera.reset_physics_interpolation()


func _update_shake(delta: float) -> void:
	if _shake_time <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	_shake_time -= delta
	var decay: float = clampf(_shake_time / _shake_total, 0.0, 1.0)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * decay


func _on_screen_shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_time = duration
	_shake_total = maxf(duration, 0.01)


func _update_hint() -> void:
	var show: bool = false
	if not _spell_used and not complete and Targeting.is_valid(_intro_thrower):
		show = absf(_player.global_position.x - _intro_thrower.global_position.x) < HINT_RANGE
	if show == _hint_shown:
		return
	_hint_shown = show
	Game.set_hint(MISSILE_HINT if show else "")


func _on_spell_cast() -> void:
	_spell_used = true


func _on_end_entered(body: Node2D) -> void:
	if body != _player or complete:
		return
	complete = true
	_player.set("control_enabled", false)
	_hud.call("show_banner", END_TEXT, 0.0)


func _on_player_died() -> void:
	_hud.call("show_banner", "YOU DIED", 0.0)
	await get_tree().create_timer(1.8).timeout
	Game.reset_run()
	get_tree().reload_current_scene()
