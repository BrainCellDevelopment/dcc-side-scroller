extends Area2D
## Fires the workshop_found hook (#61) once, when Carl first walks into the workshop.

var _fired: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _fired or not body.is_in_group("player"):
		return
	_fired = true
	SystemVoice.fire("workshop_found")
