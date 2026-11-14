extends Area2D

signal dialogue_started
signal dialogue_finished
signal perk_given(perk_id: String)

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")

@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(32, 40)
@export var frame_count: int = 4
@export var caretaker_name: String = "Tally"
@export var lines: PackedStringArray = PackedStringArray([
	"Tally is glad Crawler is alive. Tally has cooked too much, as always.",
	"Nothing in here can touch you. Tally checked the door himself.",
	"Sit. Eat. Open boxes. Then go back out there and die somewhere else.",
])
@export var perk_line: String = "Hat for the road. Tally made it from a napkin. It is lucky, a little."
@export var repeat_line: String = "Tally has nothing more. Boxes are over there. Mind the playground."
@export var perk_id: String = "tally_paper_hat"
@export var perk_name: String = "Tally's Paper Hat"
@export var perk_slot: String = "head"
@export var perk_bonuses: Dictionary = {"constitution": 1}

var talking: bool = false
var perk_taken: bool = false

var _player: Node2D = null
var _inside: bool = false
var _index: int = 0
var _sprite: AnimatedSprite2D

@onready var _prompt: Label = $Prompt
@onready var _speech: Label = $Speech


func _ready() -> void:
	var anims: Dictionary = {
		"idle": {"row": 0, "count": frame_count, "fps": 3.0, "loop": true},
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
	_face_player()
	if talking:
		if Game.action_just_pressed("interact"):
			_advance()
		return
	_prompt.visible = true
	if Game.action_just_pressed("interact"):
		start_dialogue()


func start_dialogue() -> void:
	talking = true
	_index = 0
	_prompt.visible = false
	_sprite.play("talk")
	_set_player_control(false)
	if perk_taken:
		_show(repeat_line)
	else:
		_show(lines[0] if not lines.is_empty() else perk_line)
	dialogue_started.emit()


func give_perk() -> bool:
	if perk_taken:
		return false
	perk_taken = true
	if perk_id != "":
		Game.add_item(perk_id, perk_name, "Bronze", {"slot": perk_slot, "bonuses": perk_bonuses})
	perk_given.emit(perk_id)
	return true


func _advance() -> void:
	_index += 1
	if perk_taken or _index > lines.size():
		_finish()
		return
	if _index == lines.size():
		give_perk()
		_show(perk_line)
		return
	_show(lines[_index])


func _finish() -> void:
	talking = false
	_sprite.play("idle")
	_speech.visible = false
	_set_player_control(true)
	dialogue_finished.emit()


func _show(text: String) -> void:
	_speech.text = text
	_speech.visible = true


func _face_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) > 2.0:
		$Visual.scale.x = 1.0 if dx > 0.0 else -1.0


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
