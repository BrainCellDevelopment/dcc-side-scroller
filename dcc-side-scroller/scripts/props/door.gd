extends Node2D

signal opened
signal unlocked

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const SHEET: Texture2D = preload("res://assets/props/door.png")
const FRAME: Vector2i = Vector2i(96, 112)
const ANIMS: Dictionary = {
	"closed": {"row": 0, "count": 1, "fps": 1.0, "loop": false},
	"open": {"row": 0, "count": 5, "fps": 7.0, "loop": false},
}

@export var locked: bool = false
@export var start_open: bool = false
@export var interact_open: bool = true
@export var auto_open_range: float = 0.0
@export var locked_text: String = "Locked"
@export var open_text: String = "E: open"
@export var close_behind: bool = false
@export var close_side: float = 1.0
@export var close_distance: float = 90.0
@export var sealed_text: String = "Locked"

var is_open: bool = false

var _player_inside: bool = false
var _sprite: AnimatedSprite2D

@onready var _body_shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _zone: Area2D = $Zone
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	_sprite = SpriteUtil.make_sprite(SHEET, FRAME, ANIMS)
	_sprite.name = "Sprite"
	$Visual.add_child(_sprite)
	_prompt.visible = false
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)
	if start_open:
		open(false)
	else:
		_sprite.play("closed")


func _process(_delta: float) -> void:
	if is_open:
		_close_if_passed()
		return
	if auto_open_range > 0.0 and not locked:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null and absf(player.global_position.x - global_position.x) <= auto_open_range:
			open()
			return
	if not _player_inside:
		_prompt.visible = false
		return
	if locked:
		_prompt.text = locked_text
		_prompt.visible = true
		return
	if not interact_open:
		_prompt.visible = false
		return
	_prompt.text = open_text
	_prompt.visible = true
	if Game.action_just_pressed("interact"):
		open()


func _close_if_passed() -> void:
	if not close_behind:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if (player.global_position.x - global_position.x) * close_side > close_distance:
		close()


func unlock() -> void:
	if not locked:
		return
	locked = false
	unlocked.emit()


func open(animated: bool = true) -> void:
	if is_open:
		return
	is_open = true
	locked = false
	_prompt.visible = false
	_body_shape.set_deferred("disabled", true)
	if animated:
		_sprite.play("open")
		Game.shake(2.0, 0.4)
		await _sprite.animation_finished
	else:
		_sprite.play("open")
		_sprite.frame = ANIMS["open"]["count"] - 1
		_sprite.pause()
	opened.emit()


func close(animated: bool = true) -> void:
	if not is_open:
		return
	is_open = false
	locked = true
	if close_behind:
		locked_text = sealed_text
	_body_shape.set_deferred("disabled", false)
	if animated:
		_sprite.play_backwards("open")
		Game.shake(2.0, 0.4)
	else:
		_sprite.play("closed")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		_prompt.visible = false
