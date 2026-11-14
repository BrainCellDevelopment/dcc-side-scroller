extends Node2D

signal entered
signal left

const CLOSET: PackedScene = preload("res://scenes/level/bathroom_closet.tscn")
const ACHIEVEMENT_ID: String = "bathroom_first"
const ACHIEVEMENT_TITLE: String = "Off the Air"
const ACHIEVEMENT_TEXT: String = "You found the one room with no cameras. The audience has noticed your absence."
const COOLDOWN: float = 0.6

@export var hidden_item_id: String = ""
@export var hidden_item_name: String = ""

var inside: bool = false
var item_taken: bool = false

var _player_near: bool = false
var _cooldown: float = 0.0
var _saved: Dictionary = {}
var _closet: CanvasLayer = null

@onready var _zone: Area2D = $Zone
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	_prompt.visible = false
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_prompt.visible = _player_near and not inside
	if _player_near and not inside and _cooldown <= 0.0 and Game.action_just_pressed("interact"):
		enter()


func enter() -> void:
	if inside:
		return
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	inside = true
	_saved = {
		"player": player,
		"control": bool(player.get("control_enabled")),
		"visible": player.visible,
		"safe": Game.in_safe_zone,
	}
	player.set("control_enabled", false)
	player.velocity = Vector2.ZERO
	player.visible = false
	Game.set_safe_zone(true)
	_closet = CLOSET.instantiate() as CanvasLayer
	get_tree().current_scene.add_child(_closet)
	_closet.connect("finished", _on_closet_finished)
	var has_item: bool = not item_taken and not hidden_item_id.is_empty()
	_closet.call("begin", hidden_item_name if has_item else "")
	Game.unlock_achievement(ACHIEVEMENT_ID, ACHIEVEMENT_TITLE, ACHIEVEMENT_TEXT)
	entered.emit()


func _on_closet_finished(took_item: bool) -> void:
	if took_item:
		item_taken = true
		Game.add_item(hidden_item_id, hidden_item_name)
	var player: CharacterBody2D = _saved["player"] as CharacterBody2D
	if is_instance_valid(player):
		player.visible = bool(_saved["visible"])
		player.velocity = Vector2.ZERO
		player.set("control_enabled", bool(_saved["control"]))
	Game.set_safe_zone(bool(_saved["safe"]))
	if is_instance_valid(_closet):
		_closet.queue_free()
	_closet = null
	_saved = {}
	_cooldown = COOLDOWN
	inside = false
	left.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
