extends "res://scripts/enemies/rock.gd"

const PUDDLE: PackedScene = preload("res://scenes/level/lava_puddle.tscn")
const PUDDLE_WIDTH: float = 16.0
const PUDDLE_SECONDS: float = 5.0

var _hit_player: bool = false
var _landing: Vector2 = Vector2.ZERO
var _lands: bool = false


func _on_body_entered(body: Node2D) -> void:
	if _done or body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player"):
		_hit_player = true
	elif not body.is_in_group("enemies") and body.is_in_group("platforms"):
		var top: float = body.global_position.y
		if global_position.y < top + 6.0 and global_position.y > top - 14.0:
			_lands = true
			_landing = Vector2(global_position.x, top)
	super._on_body_entered(body)


func _finish() -> void:
	if _done:
		return
	if _lands and not _hit_player:
		_drop_puddle.call_deferred(_landing)
	super._finish()


func _drop_puddle(at: Vector2) -> void:
	var holder: Node = get_tree().current_scene
	if holder == null:
		return
	var puddle: Area2D = PUDDLE.instantiate() as Area2D
	puddle.set("width", PUDDLE_WIDTH)
	puddle.set("lifetime", PUDDLE_SECONDS)
	puddle.position = at + Vector2(-PUDDLE_WIDTH * 0.5, 0.0)
	holder.add_child(puddle)
