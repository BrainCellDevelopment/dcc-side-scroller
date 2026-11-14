extends CharacterBody2D

signal died(enemy: Node)

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
enum AttackPhase { WINDUP, ACTIVE, COOLDOWN }

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const GRUNT_SHEET: Texture2D = preload("res://assets/characters/goblin.png")
const THROWER_SHEET: Texture2D = preload("res://assets/characters/goblin_thrower.png")
const BARD_SHEET: Texture2D = preload("res://assets/characters/goblin_bard.png")
const CLURICHAUN_SHEET: Texture2D = preload("res://assets/characters/clurichaun.png")
const SHAMANKA_SHEET: Texture2D = preload("res://assets/characters/goblin_shamanka.png")
const BOMB_SCENE: PackedScene = preload("res://scenes/enemies/glass_bomb.tscn")
const ROCK_SCENE: PackedScene = preload("res://scenes/enemies/rock.tscn")
const ItemEffects: GDScript = preload("res://scripts/combat/item_effects.gd")
const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")
const CharmMark: GDScript = preload("res://scripts/fx/charm_mark.gd")
const ANGUISH_RING: GDScript = preload("res://scripts/fx/anguish_ring.gd")
const FRAME: Vector2i = Vector2i(32, 32)
const ANIMS: Dictionary = {
	"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true},
	"walk": {"row": 1, "count": 6, "fps": 10.0, "loop": true},
	"windup": {"row": 2, "count": 2, "fps": 6.0, "loop": false},
	"attack": {"row": 3, "count": 3, "fps": 16.0, "loop": false},
	"hurt": {"row": 4, "count": 1, "fps": 1.0, "loop": false},
	"die": {"row": 5, "count": 4, "fps": 10.0, "loop": false},
}
const THROW_WINDUP: float = 0.5
const THROW_ACTIVE: float = 0.2
const THROW_INTERVAL: float = 2.2
const KEEP_DISTANCE: float = 70.0
const THROW_RANGE_X: float = 230.0
const THROW_RANGE_Y: float = 90.0
const ROCK_SPEED_MAX: float = 380.0
const BARD_INTERVAL: float = 2.8
const BARD_AIM_ERROR: float = 46.0
const SHAMANKA_INTERVAL: float = 3.4
const ANGUISH_RADIUS: float = 150.0
const ANGUISH_SECONDS: float = 5.0
const ANGUISH_SPEED: float = 1.4
const HURT_TIME: float = 0.2
const KNOCKBACK: Vector2 = Vector2(120.0, -90.0)
const HEIGHT_TOLERANCE: float = 40.0

@export_enum("Grunt", "Thrower", "BombBard", "Shamanka", "Clurichaun") var variant: int = 0
@export var enemy_level: int = 2
@export var xp_value: int = -1
@export var is_boss: bool = false
@export var max_health: int = 2
@export var speed: float = 55.0
@export var chase_speed: float = 80.0
@export var detect_range: float = 150.0
@export var attack_range: float = 18.0
@export var attack_damage: int = 1
@export var attack_windup: float = 0.35
@export var attack_active: float = 0.15
@export var attack_cooldown: float = 0.9
@export var patrol_distance: float = 40.0
## Red marker: a marked goblin cannot be charmed and ignores the Goblin Pass.
@export var charmable: bool = true
## Item handed over the first time this goblin is charmed (empty = none).
@export var charm_gift: String = ""

var health: int = 0
var state: State = State.PATROL
var attack_phase: AttackPhase = AttackPhase.WINDUP
var facing: int = 1
var spawn_x: float = 0.0
var state_timer: float = 0.0
var engaged: bool = false
var has_hit: bool = false
var gravity_force: float = 980.0
var sight_height: float = HEIGHT_TOLERANCE
var throw_cooldown: float = 0.0
var windup_time: float = 0.35
var active_time: float = 0.15
var sprite: AnimatedSprite2D = null
var flash_tween: Tween = null
var charm_left: float = 0.0
var charm_permanent: bool = false
var charm_mark: Node2D = null
var anguish_left: float = 0.0
var cast_count: int = 0

@onready var visual: Node2D = $Visual
@onready var attack_area: Area2D = $Visual/AttackArea
@onready var attack_shape: CollisionShape2D = $Visual/AttackArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $Visual/LedgeCheck
@onready var health_bar: Node2D = $HealthBar


func _ready() -> void:
	gravity_force = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	if variant == 2:
		max_health = 3
		speed = 36.0
		chase_speed = 36.0
		detect_range = 260.0
		sight_height = THROW_RANGE_Y
		windup_time = 0.6
		active_time = THROW_ACTIVE
		throw_cooldown = 1.0
	elif variant == 3:
		max_health = 4
		speed = 34.0
		chase_speed = 34.0
		detect_range = 260.0
		sight_height = THROW_RANGE_Y
		windup_time = 0.7
		active_time = THROW_ACTIVE
		throw_cooldown = 1.2
	elif variant == 1 or variant == 4:
		max_health = 3 if variant == 4 else 2
		if variant == 4:
			enemy_level = 3
		speed = 40.0
		chase_speed = 40.0
		detect_range = 250.0
		sight_height = THROW_RANGE_Y
		windup_time = THROW_WINDUP
		active_time = THROW_ACTIVE
		throw_cooldown = 0.8
	health = max_health
	spawn_x = global_position.x
	sprite = SpriteUtil.make_sprite(_sheet(), FRAME, ANIMS)
	sprite.name = "Sprite"
	visual.add_child(sprite)
	visual.move_child(sprite, 0)
	sprite.play("idle")
	attack_area.body_entered.connect(_on_attack_body_entered)


func _exit_tree() -> void:
	_set_engaged(false)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y += gravity_force * delta
	throw_cooldown = maxf(throw_cooldown - delta, 0.0)
	_tick_charm(delta)
	_tick_anguish(delta)
	var player: CharacterBody2D = _get_player()
	if is_passive():
		player = null
		if state == State.CHASE or state == State.ATTACK:
			_calm_down()
	match state:
		State.PATROL:
			_patrol(player)
		State.CHASE:
			_chase(player)
		State.ATTACK:
			_attack(delta)
		State.HURT:
			_hurt(delta, player)
	move_and_slide()
	_update_animation()


## True when this goblin will not fight Carl: charmed, or a plain goblin and Carl holds a Goblin Pass.
func is_passive() -> bool:
	if state == State.DEAD:
		return false
	return charm_permanent or charm_left > 0.0 or has_pass_effect()


func is_charmed() -> bool:
	return charm_permanent or charm_left > 0.0


## Bosses and marked goblins are immune to both charm and the pass.
func can_be_charmed() -> bool:
	return charmable and not is_boss and state != State.DEAD


func has_pass_effect() -> bool:
	return can_be_charmed() and ItemEffects.has_goblin_pass()


## Charm for `seconds`; a negative value is permanent. Returns false when immune.
func charm(seconds: float) -> bool:
	if not can_be_charmed():
		return false
	var fresh: bool = not is_charmed()
	if seconds < 0.0:
		charm_permanent = true
	else:
		charm_left = maxf(charm_left, seconds)
	add_to_group("charmed")
	_calm_down()
	if charm_mark == null:
		charm_mark = CharmMark.new()
		charm_mark.position = Vector2(0.0, -34.0)
		add_child(charm_mark)
	charm_mark.set("faint", false)
	charm_mark.call("pulse")
	if fresh and not charm_gift.is_empty():
		var gift: String = charm_gift
		charm_gift = ""
		ItemDefs.give(gift)
	return true


func end_charm() -> void:
	charm_left = 0.0
	charm_permanent = false
	remove_from_group("charmed")
	if charm_mark != null:
		charm_mark.queue_free()
		charm_mark = null


func _tick_charm(delta: float) -> void:
	if charm_left > 0.0:
		charm_left -= delta
		if charm_left <= 0.0:
			end_charm()
	if charm_mark != null and is_instance_valid(charm_mark):
		charm_mark.visible = is_passive()
	elif has_pass_effect():
		charm_mark = CharmMark.new()
		charm_mark.position = Vector2(0.0, -34.0)
		charm_mark.set("faint", true)
		add_child(charm_mark)


func _calm_down() -> void:
	attack_shape.set_deferred("disabled", true)
	_set_engaged(false)
	if state == State.CHASE or state == State.ATTACK:
		state = State.PATROL
	velocity.x = 0.0


func take_damage(amount: int, from: Vector2) -> void:
	if state == State.DEAD:
		return
	health = maxi(health - amount, 0)
	health_bar.call("update_health", health, max_health)
	attack_shape.set_deferred("disabled", true)
	_flash()
	if health <= 0:
		_die()
		return
	var push: float = -float(facing)
	if global_position.x > from.x:
		push = 1.0
	elif global_position.x < from.x:
		push = -1.0
	velocity = Vector2(push * KNOCKBACK.x, KNOCKBACK.y)
	state = State.HURT
	state_timer = HURT_TIME


func _patrol(player: CharacterBody2D) -> void:
	if player != null and _sees(player, 1.0, sight_height):
		_set_engaged(true)
		state = State.CHASE
		return
	var offset: float = global_position.x - spawn_x
	if offset > patrol_distance:
		_face(-1)
	elif offset < -patrol_distance:
		_face(1)
	if _blocked_ahead():
		if absf(offset) > patrol_distance:
			spawn_x = global_position.x
		_face(-facing)
		if _blocked_ahead():
			velocity.x = 0.0
			return
	velocity.x = float(facing) * speed * _pace()


func _chase(player: CharacterBody2D) -> void:
	if _ranged():
		_chase_thrower(player)
		return
	if player == null or not _sees(player, 1.25, HEIGHT_TOLERANCE * 1.5):
		_set_engaged(false)
		state = State.PATROL
		return
	var dx: float = player.global_position.x - global_position.x
	if absf(dx) > 2.0:
		_face(1 if dx > 0.0 else -1)
	if absf(dx) <= attack_range and is_on_floor():
		_start_attack()
		return
	if _blocked_ahead() or absf(dx) <= 2.0:
		velocity.x = 0.0
	else:
		velocity.x = float(facing) * chase_speed * _pace()


func _chase_thrower(player: CharacterBody2D) -> void:
	if player == null or not _sees(player, 1.25, THROW_RANGE_Y * 1.5):
		_set_engaged(false)
		state = State.PATROL
		velocity.x = 0.0
		return
	var dx: float = player.global_position.x - global_position.x
	var dy: float = player.global_position.y - global_position.y
	if absf(dx) > 2.0:
		_face(1 if dx > 0.0 else -1)
	var keep: float = KEEP_DISTANCE * (1.5 if variant == 3 else 1.0)
	if absf(dx) < keep and is_on_floor():
		if _blocked_behind():
			velocity.x = 0.0
		else:
			velocity.x = -float(facing) * speed
	else:
		velocity.x = 0.0
	if throw_cooldown <= 0.0 and absf(dx) <= THROW_RANGE_X and absf(dy) <= THROW_RANGE_Y and is_on_floor():
		_start_attack()


func _sheet() -> Texture2D:
	match variant:
		1:
			return THROWER_SHEET
		2:
			return BARD_SHEET
		3:
			return SHAMANKA_SHEET
		4:
			return CLURICHAUN_SHEET
	return GRUNT_SHEET


func _ranged() -> bool:
	return variant >= 1


func _interval() -> float:
	match variant:
		2:
			return BARD_INTERVAL
		3:
			return SHAMANKA_INTERVAL
	return THROW_INTERVAL


## Anguish (Shamanka buff): faster and angrier for a few seconds.
func apply_anguish(seconds: float) -> void:
	if state == State.DEAD or variant == 3:
		return
	anguish_left = maxf(anguish_left, seconds)


func is_anguished() -> bool:
	return anguish_left > 0.0


func _tick_anguish(delta: float) -> void:
	if anguish_left <= 0.0:
		return
	anguish_left = maxf(anguish_left - delta, 0.0)
	if is_passive():
		anguish_left = 0.0
	sprite.modulate = Color(1.6, 0.6, 0.6, 1.0) if anguish_left > 0.0 else Color(1.0, 1.0, 1.0, 1.0)


func _pace() -> float:
	return ANGUISH_SPEED if anguish_left > 0.0 else 1.0


func _cast_anguish() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var other: Node2D = node as Node2D
		if other == null or other == self or not other.has_method("apply_anguish"):
			continue
		if other.global_position.distance_to(global_position) <= ANGUISH_RADIUS:
			other.call("apply_anguish", ANGUISH_SECONDS)
	var ring: Node2D = ANGUISH_RING.new() as Node2D
	ring.position = Vector2(0.0, -12.0)
	ring.set("radius", ANGUISH_RADIUS)
	add_child(ring)


func _release_attack() -> void:
	match variant:
		1:
			_throw_rock()
		4:
			_throw_rock()
		2:
			_throw_bomb()
		3:
			cast_count += 1
			if cast_count % 2 == 1:
				_cast_anguish()
			else:
				_throw_rock()


func _throw_bomb() -> void:
	if Game.in_safe_zone:
		return
	var player: CharacterBody2D = _get_player()
	var holder: Node = get_tree().current_scene
	if player == null or holder == null:
		return
	var origin: Vector2 = visual.to_global(Vector2(11.0, -19.0))
	var target: Vector2 = player.global_position + Vector2(randf_range(-BARD_AIM_ERROR, BARD_AIM_ERROR), -8.0)
	var bomb: Area2D = BOMB_SCENE.instantiate() as Area2D
	holder.add_child(bomb)
	bomb.global_position = origin
	var g: float = float(bomb.get("fall_gravity"))
	var offset: Vector2 = target - origin
	var flight: float = clampf(offset.length() / 260.0, 0.45, 1.0)
	bomb.call("launch", Vector2(offset.x / flight, offset.y / flight - 0.5 * g * flight), attack_damage)


func _start_attack() -> void:
	state = State.ATTACK
	attack_phase = AttackPhase.WINDUP
	if variant == 0:
		windup_time = attack_windup
		active_time = attack_active
	state_timer = windup_time / _pace()
	has_hit = false
	velocity.x = 0.0


func _attack(delta: float) -> void:
	velocity.x = 0.0
	state_timer -= delta * _pace()
	match attack_phase:
		AttackPhase.WINDUP:
			if _ranged():
				var target: CharacterBody2D = _get_player()
				if target != null:
					var tx: float = target.global_position.x - global_position.x
					if absf(tx) > 2.0:
						_face(1 if tx > 0.0 else -1)
			if state_timer <= 0.0:
				attack_phase = AttackPhase.ACTIVE
				state_timer = active_time
				if _ranged():
					_release_attack()
				else:
					attack_shape.set_deferred("disabled", false)
		AttackPhase.ACTIVE:
			if _ranged():
				if state_timer <= 0.0:
					throw_cooldown = maxf(_interval() - windup_time - THROW_ACTIVE, 0.1) / _pace()
					state = State.CHASE
				return
			for body: Node2D in attack_area.get_overlapping_bodies():
				_try_hit(body)
			if state_timer <= 0.0:
				attack_phase = AttackPhase.COOLDOWN
				state_timer = attack_cooldown
				attack_shape.set_deferred("disabled", true)
		AttackPhase.COOLDOWN:
			if state_timer <= 0.0:
				state = State.CHASE


func _hurt(delta: float, player: CharacterBody2D) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	if state_timer > 0.0:
		return
	if player != null:
		_set_engaged(true)
		state = State.CHASE
	else:
		_set_engaged(false)
		state = State.PATROL


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	body_shape.set_deferred("disabled", true)
	_set_engaged(false)
	PlayerStats.award_kill(self)
	Game.report_mob_kill(self)
	died.emit(self)
	sprite.speed_scale = 1.0
	sprite.play("die")
	var tween: Tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func neutralise() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	attack_shape.set_deferred("disabled", true)
	_set_engaged(false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _try_hit(body: Node2D) -> void:
	if Game.in_safe_zone:
		return
	if has_hit or state != State.ATTACK or attack_phase != AttackPhase.ACTIVE:
		return
	if body == null or not body.is_in_group("player") or not body.has_method("take_damage"):
		return
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return
	has_hit = true
	body.call("take_damage", attack_damage, global_position)


func _on_attack_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _sees(player: CharacterBody2D, range_scale: float, height: float) -> bool:
	var delta_pos: Vector2 = player.global_position - global_position
	return absf(delta_pos.x) <= detect_range * range_scale and absf(delta_pos.y) <= height


func _blocked_ahead() -> bool:
	if is_on_wall() and get_wall_normal().x * float(facing) < 0.0:
		return true
	if is_on_floor():
		ledge_check.force_raycast_update()
		return not ledge_check.is_colliding()
	return false


func _face(dir: int) -> void:
	facing = dir
	visual.scale.x = float(dir)


func _set_engaged(value: bool) -> void:
	if engaged == value:
		return
	engaged = value
	if value:
		Game.enemy_engaged()
	else:
		Game.enemy_disengaged()


func _blocked_behind() -> bool:
	if is_on_wall() and get_wall_normal().x * float(facing) > 0.0:
		return true
	if not is_on_floor():
		return false
	var ahead_x: float = absf(ledge_check.position.x)
	ledge_check.position.x = -ahead_x
	ledge_check.force_raycast_update()
	var found: bool = ledge_check.is_colliding()
	ledge_check.position.x = ahead_x
	ledge_check.force_raycast_update()
	return not found


func _throw_rock() -> void:
	if Game.in_safe_zone:
		return
	var player: CharacterBody2D = _get_player()
	var holder: Node = get_tree().current_scene
	if player == null or holder == null:
		return
	var origin: Vector2 = visual.to_global(Vector2(11.0, -19.0))
	var target: Vector2 = player.global_position + Vector2(0.0, -14.0)
	var rock: Area2D = ROCK_SCENE.instantiate() as Area2D
	holder.add_child(rock)
	rock.global_position = origin
	var g: float = float(rock.get("fall_gravity"))
	var offset: Vector2 = target - origin
	var flight: float = clampf(offset.length() / 300.0, 0.35, 0.9)
	var launch_velocity: Vector2 = Vector2(offset.x / flight, offset.y / flight - 0.5 * g * flight)
	if launch_velocity.length() > ROCK_SPEED_MAX:
		launch_velocity = launch_velocity.normalized() * ROCK_SPEED_MAX
	rock.set("taints", variant == 4)
	rock.call("launch", launch_velocity, attack_damage)


func _play(anim: StringName, anim_speed: float = 1.0) -> void:
	sprite.speed_scale = anim_speed
	if sprite.animation != anim:
		sprite.play(anim)


func _update_animation() -> void:
	match state:
		State.PATROL, State.CHASE:
			if is_on_floor() and absf(velocity.x) > 5.0:
				_play(&"walk", clampf(absf(velocity.x) / 50.0, 0.7, 1.8))
			else:
				_play(&"idle")
		State.ATTACK:
			match attack_phase:
				AttackPhase.WINDUP:
					_play(&"windup", (2.0 / 6.0) / maxf(windup_time, 0.05))
				AttackPhase.ACTIVE:
					_play(&"attack", (3.0 / 16.0) / maxf(active_time, 0.05))
				AttackPhase.COOLDOWN:
					if state_timer < attack_cooldown * 0.6:
						_play(&"idle")
		State.HURT:
			_play(&"hurt")


func _flash() -> void:
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	visual.modulate = Color(4.0, 4.0, 4.0, 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _get_player() -> CharacterBody2D:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_instance_valid(player):
		return null
	if player.has_method("is_dead") and bool(player.call("is_dead")):
		return null
	return player
