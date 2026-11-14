extends Node2D
## The Krakaren Clone (Level 2 boss, Lv10): a pyramid-scheme octopus behind the arena wall. Its tentacles
## burst up from the floor where the player stands (telegraphed), then sag stuck for a few seconds: hit them
## then. Every third attack it spits Taint mucus (no healing; the smoothie makes you immune). Below half
## health it strikes with two tentacles at once and faster.

signal defeated(boss: Node)

const TENTACLE: GDScript = preload("res://scripts/enemies/krakaren_tentacle.gd")
const ROCK_SCENE: PackedScene = preload("res://scenes/enemies/rock.tscn")
const Taint: GDScript = preload("res://scripts/combat/taint.gd")
const BOSS_NAME: String = "Krakaren Clone"
const WAIT_TIME: float = 1.3
const WAIT_ENRAGED: float = 0.8
const TELEGRAPH: float = 0.85
const TELEGRAPH_ENRAGED: float = 0.6
const SPIT_COUNT: int = 3
const SPIT_GAP: float = 0.4
const MOUTH: Vector2 = Vector2(-34.0, -64.0)
const TAINT_HINT: String = "THE TAINT STOPS ALL HEALING. A SMOOTHIE WOULD HELP"
const BODY: Color = Color(0.5, 0.2, 0.46)
const BODY_DARK: Color = Color(0.3, 0.1, 0.3)
const BODY_LIGHT: Color = Color(0.72, 0.4, 0.62)

enum State { IDLE, WAIT, STRIKE, SPIT, DEAD }

@export var max_health: int = 30
@export var enemy_level: int = 10
@export var xp_value: int = -1
@export var is_boss: bool = true
@export var arena_left: float = 0.0
@export var arena_right: float = 0.0

var active: bool = false
var health: int = 0
var state: State = State.IDLE
var cycles: int = 0
var engaged: bool = false

var _timer: float = 0.0
var _tentacles: Array[Node] = []
var _spits_left: int = 0
var _hint_shown: bool = false
var _flash: float = 0.0
var _clock: float = 0.0
var _fade: float = 1.0


func _ready() -> void:
	health = max_health
	z_index = -2
	for i: int in 2:
		var tentacle: StaticBody2D = TENTACLE.new() as StaticBody2D
		tentacle.name = "Tentacle%d" % (i + 1)
		tentacle.set("boss", self)
		add_child(tentacle)
		_tentacles.append(tentacle)


func _exit_tree() -> void:
	_set_engaged(false)


func activate() -> void:
	if active or state == State.DEAD:
		return
	active = true
	state = State.WAIT
	_timer = 1.0
	_set_engaged(true)
	Game.report_boss_health(BOSS_NAME, health, max_health)


func is_dead() -> bool:
	return state == State.DEAD


func is_enraged() -> bool:
	return health * 2 <= max_health


func tentacle_hit(amount: int) -> void:
	if state == State.DEAD:
		return
	health = maxi(health - amount, 0)
	_flash = 0.15
	Game.report_boss_health(BOSS_NAME, health, max_health)
	if health <= 0:
		_die()


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()
	if not active or state == State.DEAD:
		return
	match state:
		State.WAIT:
			_timer -= delta
			if _timer <= 0.0:
				_next_attack()
		State.STRIKE:
			if not _any_busy():
				_enter_wait()
		State.SPIT:
			_timer -= delta
			if _timer <= 0.0:
				_spit_one()


func _enter_wait() -> void:
	state = State.WAIT
	_timer = WAIT_ENRAGED if is_enraged() else WAIT_TIME


func _next_attack() -> void:
	cycles += 1
	if cycles % 3 == 0:
		state = State.SPIT
		_spits_left = SPIT_COUNT
		_timer = 0.5
		return
	var player: CharacterBody2D = _get_player()
	if player == null:
		_enter_wait()
		return
	state = State.STRIKE
	var tele: float = TELEGRAPH_ENRAGED if is_enraged() else TELEGRAPH
	var count: int = 2 if is_enraged() else 1
	for i: int in count:
		var x: float = player.global_position.x + (0.0 if i == 0 else 56.0 * (1.0 if randf() < 0.5 else -1.0))
		x = clampf(x, arena_left, arena_right)
		(_tentacles[i] as Node).call("strike", x, tele + 0.15 * float(i))


func _any_busy() -> bool:
	for tentacle: Node in _tentacles:
		if bool(tentacle.call("is_busy")):
			return true
	return false


func _spit_one() -> void:
	if _spits_left <= 0:
		_enter_wait()
		return
	_spits_left -= 1
	_timer = SPIT_GAP
	var player: CharacterBody2D = _get_player()
	var holder: Node = get_tree().current_scene
	if player == null or holder == null:
		return
	if not _hint_shown and not Taint.is_immune():
		_hint_shown = true
		var hud: Node = holder.get_node_or_null("HUD")
		if hud != null:
			hud.call("show_banner", TAINT_HINT, 2.6)
	var origin: Vector2 = global_position + MOUTH
	var target: Vector2 = player.global_position + Vector2(randf_range(-14.0, 14.0), -14.0)
	var glob: Area2D = ROCK_SCENE.instantiate() as Area2D
	holder.add_child(glob)
	glob.global_position = origin
	glob.scale = Vector2(1.6, 1.6)
	glob.modulate = Color(0.7, 1.0, 0.4)
	glob.set("taints", true)
	var g: float = float(glob.get("fall_gravity"))
	var offset: Vector2 = target - origin
	var flight: float = clampf(offset.length() / 240.0, 0.5, 1.2)
	glob.call("launch", Vector2(offset.x / flight, offset.y / flight - 0.5 * g * flight), 1)


func _die() -> void:
	state = State.DEAD
	for tentacle: Node in _tentacles:
		tentacle.call("retract_now")
	_set_engaged(false)
	PlayerStats.award_kill(self)
	Game.report_mob_kill(self)
	Game.shake(3.0, 0.8)
	var tween: Tween = create_tween()
	tween.tween_property(self, "_fade", 0.0, 1.2)
	defeated.emit.call_deferred(self)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player) or bool(player.call("is_dead")):
		return null
	return player


func _draw() -> void:
	var alpha: float = _fade
	var body: Color = Color(1.6, 1.4, 1.2, alpha) if _flash > 0.0 else Color(BODY.r, BODY.g, BODY.b, alpha)
	var bob: float = sin(_clock * 1.6) * 3.0
	draw_circle(Vector2(0.0, -96.0 + bob), 74.0, body)
	draw_circle(Vector2(-10.0, -112.0 + bob), 40.0, Color(BODY_LIGHT.r, BODY_LIGHT.g, BODY_LIGHT.b, alpha * 0.5))
	for i: int in 5:
		draw_circle(Vector2(-60.0 + 22.0 * float(i), -40.0 + bob * 0.5), 14.0, Color(BODY_DARK.r, BODY_DARK.g, BODY_DARK.b, alpha))
	# big angry eyes
	for ex: float in [-38.0, -8.0]:
		draw_circle(Vector2(ex, -88.0 + bob), 12.0, Color(1.0, 0.96, 0.8, alpha))
		draw_circle(Vector2(ex - 3.0, -88.0 + bob), 5.0, Color(0.1, 0.04, 0.1, alpha))
	# mouths along the dome (screaming tentacle mouths)
	for mx: float in [-52.0, -20.0, 12.0]:
		draw_rect(Rect2(mx, -62.0 + bob, 10.0, 6.0), Color(0.2, 0.02, 0.08, alpha))
	# health pip line over the dome is drawn by the HUD boss bar
