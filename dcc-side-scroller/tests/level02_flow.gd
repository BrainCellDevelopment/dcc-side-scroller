extends Node
## Level 2 end to end (scripted, not a walking bot): the gates, earned boxes held for the shelter, both bosses,
## the reward room and Mongo, the end of the floor, the summary card and the hand-off to Level 3.

const LEVEL: PackedScene = preload("res://scenes/level02.tscn")
const LEVEL3: PackedScene = preload("res://scenes/level03.tscn")

var _fails: int = 0
var _level: Node = null
var _player: CharacterBody2D = null
var _changed_to: String = ""


func _ready() -> void:
	FloorHandoff.scene_changer = func(path: String) -> void: _changed_to = path
	Game.set_meta("pet_mongo", false)
	await _run()
	FloorHandoff.scene_changer = Callable()
	Game.clear_checkpoint()
	Game.set_meta("pet_mongo", false)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _wait_until(cond: Callable, timeout: float) -> bool:
	var left: float = timeout
	while left > 0.0:
		if cond.call():
			return true
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
	return cond.call()


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)


func _run() -> void:
	Game.clear_checkpoint()
	_level = LEVEL.instantiate()
	add_child(_level)
	await _frames(4)
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 999)
	var keys: PackedStringArray = _level.call("dev_sections")
	_check(keys.size() == 7, "seven sections (%d)" % keys.size())
	for i: int in range(1, 7):
		_check(_level.get_node_or_null("Gate%d" % i) != null, "gate %d exists" % i)

	# earned boxes are held until the shelter
	Game.grant_box("Bronze")
	var boxes_before: int = get_tree().get_nodes_in_group("loot_boxes").size()
	var shelter: Node2D = _level.get_node("StormShelter") as Node2D
	_player.global_position = shelter.global_position + Vector2(-60.0, -2.0)
	await _frames(6)
	_check(get_tree().get_nodes_in_group("loot_boxes").size() == boxes_before + 1, "an earned box is handed out in the shelter")
	_check(Game.take_earned_boxes().is_empty(), "the earned box was taken")

	# bosses
	var krak_lair: Node2D = _level.get_node("KrakarenLair") as Node2D
	var krak: Node2D = krak_lair.get("boss") as Node2D
	_player.global_position = krak_lair.global_position + Vector2(-292.0, -2.0)
	await _wait_until(func() -> bool: return bool(krak.get("active")), 4.0)
	krak.call("tentacle_hit", 999)
	await _frames(4)
	_check(bool(krak.call("is_dead")), "the Krakaren falls")
	var pound: Node2D = _level.get_node("DogPoundLair") as Node2D
	var ralph: CharacterBody2D = pound.get("boss") as CharacterBody2D
	_player.global_position = pound.global_position + Vector2(-292.0, -2.0)
	await _wait_until(func() -> bool: return bool(ralph.get("active")), 4.0)
	ralph.call("take_damage", 999, Vector2.ZERO)
	await _frames(4)
	_check(bool(ralph.call("is_dead")), "Ralph falls")

	# reward room and Mongo
	var reward: Node2D = _level.get_node("RewardRoom") as Node2D
	_player.global_position = reward.global_position + Vector2(0.0, -2.0)
	await _frames(4)
	await _tap(&"interact")
	_check(bool(reward.get("chosen")) and bool(Game.get_meta("pet_mongo", false)), "Donut picks Mongo")
	_check(_level.get_node_or_null("Mongo") != null, "Mongo follows Carl")

	# end of the floor
	var end: Area2D = _level.get_node("Triggers/EndZone") as Area2D
	_player.global_position = end.global_position + Vector2(0.0, 40.0)
	await _wait_until(func() -> bool: return bool(_level.get("complete")), 2.0)
	_check(bool(_level.get("complete")), "the end of the floor is reached")
	await _wait_until(func() -> bool: return bool(_level.get("_summary_ready")), 7.0)
	_check(bool(_level.get("_summary_ready")), "the summary card is shown")
	var card: Node = _level.get("_summary_layer") as Node
	_check(card != null and str(card.get("heading_text")) == "LEVEL 2 COMPLETE", "the card says Level 2 complete")
	_check(card != null and " ".join(card.get("lines")).contains("Mongo"), "the card names Mongo among what Carl carries")
	await _tap(&"interact")
	await _wait_until(func() -> bool: return _changed_to != "", 4.0)
	_check(_changed_to == FloorHandoff.LEVEL3_SCENE, "E takes the stairs to the Level 3 stub")
	_check(bool(FloorHandoff.carried["flags"]["pet_mongo"]), "the hand-off carries Mongo")
	remove_child(_level)
	_level.free()

	# the Level 3 stub arrives with Mongo
	var stub: Node = LEVEL3.instantiate()
	add_child(stub)
	await _frames(4)
	var arrival: Dictionary = stub.get("arrival")
	_check(int(arrival["floor"]) == 3, "the Level 3 stub is floor 3")
	_check(stub.get_node_or_null("Mongo") != null, "Mongo arrives in Level 3")
	remove_child(stub)
	stub.free()

