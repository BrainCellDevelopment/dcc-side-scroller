extends Area2D

signal dialogue_started
signal dialogue_finished

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")

const LootBox: GDScript = preload("res://scripts/props/loot_box.gd")

@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(32, 40)
@export var frame_count: int = 4
@export var fps: float = 3.0
@export var lines: PackedStringArray = PackedStringArray([
	"Well, look who survived. Congratulations, Crawler.",
	"The boxes are on the house. Everything else costs extra.",
	"Open them. Try not to look disappointed.",
])
@export var repeat_line: String = "Boxes first. Then the door. I am not your mother."

var talked: bool = false
var talking: bool = false

var _player: Node2D = null
var _inside: bool = false
var _index: int = 0
var _sprite: AnimatedSprite2D

@onready var _prompt: Label = $Prompt
@onready var _speech: Label = $Speech


func _ready() -> void:
	var anims: Dictionary = {
		"idle": {"row": 0, "count": frame_count, "fps": fps, "loop": true},
		"talk": {"row": 1, "count": frame_count, "fps": 8.0, "loop": true},
	}
	_sprite = SpriteUtil.make_sprite(sheet, frame_size, anims)
	_sprite.name = "Sprite"
	$Visual.add_child(_sprite)
	_sprite.play("idle")
	_prompt.visible = false
	_speech.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _inside:
		return
	if talking:
		if Input.is_action_just_pressed("interact"):
			_advance()
		return
	_prompt.visible = not _boxes_busy()
	if _prompt.visible and Input.is_action_just_pressed("interact"):
		_start()


func _boxes_busy() -> bool:
	if not talked:
		return false
	if Engine.get_process_frames() - LootBox._last_open_frame <= 2:
		return true
	for node: Node in get_tree().get_nodes_in_group("loot_boxes"):
		if bool(node.get("summoned")) and not bool(node.get("is_open")):
			return true
	return false


func _start() -> void:
	talking = true
	_index = 0
	_prompt.visible = false
	_sprite.play("talk")
	_set_player_control(false)
	if talked:
		_show(repeat_line)
	else:
		_show(lines[0])
	dialogue_started.emit()


func _advance() -> void:
	_index += 1
	if talked or _index >= lines.size():
		_finish()
		return
	_show(lines[_index])


func _finish() -> void:
	talking = false
	_sprite.play("idle")
	_speech.visible = false
	_set_player_control(true)
	if talked:
		return
	talked = true
	dialogue_finished.emit()


func _show(text: String) -> void:
	_speech.text = text
	_speech.visible = true


func _set_player_control(enabled: bool) -> void:
	if _player != null and is_instance_valid(_player):
		_player.set("control_enabled", enabled)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_inside = false
		_prompt.visible = false
		if talking:
			_finish()
