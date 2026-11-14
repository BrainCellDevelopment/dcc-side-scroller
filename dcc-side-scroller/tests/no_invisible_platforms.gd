extends Node
## Levels 1 and 2: no goblin (or other enemy under Goblins) stands on a platform that has no art. Hidden platforms
## (modulate alpha 0) may exist under props such as the parked dozers, but nothing may stand on one.

const LEVELS: Array[String] = ["res://scenes/level01.tscn", "res://scenes/level02.tscn"]

var _fails: int = 0


func _ready() -> void:
	for path: String in LEVELS:
		await _check_level(path)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _check_level(path: String) -> void:
	var level: Node = (load(path) as PackedScene).instantiate()
	add_child(level)
	for i: int in 45:
		await get_tree().physics_frame
	var hidden: Array[Node2D] = []
	for plat: Node in level.get_node("Platforms").get_children():
		var item: CanvasItem = plat as CanvasItem
		if item != null and item.modulate.a < 0.1:
			hidden.append(plat as Node2D)
	var standing: int = 0
	var on_hidden: Array[String] = []
	for enemy: Node in level.get_node("Goblins").get_children():
		var body: CharacterBody2D = enemy as CharacterBody2D
		if body == null or not body.is_on_floor():
			continue
		standing += 1
		for plat: Node2D in hidden:
			var size: Vector2 = plat.get("size") as Vector2
			var rect: Rect2 = Rect2(plat.global_position, size)
			if body.global_position.x >= rect.position.x - 1.0 and body.global_position.x <= rect.end.x + 1.0 and absf(body.global_position.y - rect.position.y) <= 3.0:
				on_hidden.append("%s on %s" % [enemy.name, plat.name])
	_check(standing > 0, "%s: enemies are standing on the floor (%d, %d hidden platforms exist)" % [path.get_file(), standing, hidden.size()])
	_check(on_hidden.is_empty(), "%s: nothing stands on a hidden platform %s" % [path.get_file(), str(on_hidden)])
	remove_child(level)
	level.free()
	Game.clear_checkpoint()
	await get_tree().physics_frame
