extends Node2D
## The parked Goblin Copper Chopper in Level 1 (#69). Press E beside it to ride; walking on is the skip.

const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")
const RIDE_SCENE: String = "res://scenes/chopper_ride.tscn"
const SHEET: String = "res://assets/props/chopper.png"
const PROMPT: String = "E: ride the Goblin Copper Chopper"
const NEAR_X: float = 90.0
const NEAR_Y: float = 70.0
const RETURN_OFFSET: float = 40.0

var _prompt: Label


func _ready() -> void:
	var sprite: AnimatedSprite2D = SpriteUtil.make_sprite(load(SHEET) as Texture2D, Vector2i(104, 48), {"idle": {"row": 0, "count": 1, "fps": 1.0, "loop": false}})
	sprite.play("idle")
	sprite.scale.x = -1.0
	add_child(sprite)
	_prompt = Label.new()
	_prompt.text = PROMPT
	_prompt.position = Vector2(-80.0, -86.0)
	_prompt.size = Vector2(160.0, 14.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 8)
	_prompt.z_index = 50
	_prompt.visible = false
	add_child(_prompt)
	z_index = 3


func near_player() -> bool:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	return absf(offset.x) < NEAR_X and absf(offset.y) < NEAR_Y


func _physics_process(_delta: float) -> void:
	var near: bool = near_player() and not Game.menu_open
	_prompt.visible = near
	if near and Game.action_just_pressed("interact"):
		ride()


func ride() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null:
		Game.carry_player_state(player)
	Game.chopper_return = global_position + Vector2(RETURN_OFFSET, 0.0)
	get_tree().change_scene_to_file(RIDE_SCENE)
