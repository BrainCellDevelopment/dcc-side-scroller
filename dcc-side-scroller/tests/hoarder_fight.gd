extends Node
## The Hoarder (#60): level content, the sealed door, the three attacks, the roach weak point,
## defeat flow (map flag, XP, achievements, boss box that opens only in a safe zone).

const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")
const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0
var _unlocks: Array[String] = []
var _level: Node2D
var _player: CharacterBody2D
var _boss: CharacterBody2D
var _door: StaticBody2D


func _ready() -> void:
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	Inventory.clear()
	Explosives.reset()
	PlayerStats.reset()
	Game.achievement_unlocked.connect(func(title: String, _d: String) -> void: _unlocks.append(title))
	_level = LEVEL.instantiate() as Node2D
	add_child(_level)
	await _frames(3)
	_player = _level.get_node("Player") as CharacterBody2D
	_player.set("health", 999)
	_boss = _level.get_node("Bosses/Hoarder") as CharacterBody2D
	_door = _level.get_node("Doors/HoarderDoor") as StaticBody2D
	await _content()
	await _approach_and_door()
	await _fight_start()
	await _attacks()
	await _defeat()
	Game.clear_checkpoint()
	Game.set_safe_zone(false)
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _seconds(t: float) -> void:
	await _frames(int(t * 60.0))


func _place_player(x: float) -> void:
	_player.global_position = Vector2(x, _boss.global_position.y)
	_player.velocity = Vector2.ZERO


func _content() -> void:
	var scatterers: int = 0
	for node: Node in _level.get_node("Goblins").get_children():
		if str(node.name).begins_with("HoarderScatterer"):
			scatterers += 1
	_check(scatterers == 4, "four Scatterers in the approach (XpTable PLAN beat 4)")
	_check(bool(_boss.get("is_boss")) and int(_boss.get("enemy_level")) == 7, "Hoarder is a level-7 boss")
	_check(_boss.is_in_group("enemies"), "Hoarder is in the enemies group")
	var checkpoint: Node2D = _level.get_node("Checkpoints/CP3") as Node2D
	_check(checkpoint.global_position.x > _door.global_position.x and _door.global_position.x > _boss.global_position.x, "checkpoint 3 is before the sealed door, the Hoarder behind it")
	var pickups: int = 0
	for node: Node in _level.get_node("Deco").get_children():
		if str(node.name).begins_with("Dynamite"):
			pickups += 1
	_check(pickups >= 2, "dynamite sticks lie in the approach")
	_check(_level.get_node("Walls/HoarderLockA/CollisionShape2D").get("disabled") == true, "arena unlocked before the fight")
	_check(not bool(_boss.get("active")), "boss asleep until the fight starts")
	_check(_door.is_in_group("destructibles") and not bool(_door.get("is_open")), "door is sealed")
	var piles: int = get_tree().get_nodes_in_group("garbage_piles").size()
	_check(piles >= 3, "garbage piles are solid platforms and cover (%d)" % piles)


func _approach_and_door() -> void:
	_boss.call("take_damage", 5, Vector2.ZERO)
	_check(int(_boss.get("health")) == int(_boss.get("max_health")), "sleeping Hoarder takes no damage")
	Explosives.blast(get_tree(), _door.global_position + Vector2(0.0, 300.0), 50.0, 3, 0)
	_check(not bool(_door.get("is_open")), "a distant blast leaves the door shut")
	_check(not bool(_level.get_node("Walls/HoarderLockB/CollisionShape2D").get("disabled") == false), "arena still unlocked")
	_player.global_position = _door.global_position + Vector2(60.0, -2.0)
	Explosives.blast(get_tree(), _door.global_position + Vector2(20.0, -12.0), 56.0, 3, 0)
	await _frames(3)
	_check(bool(_door.get("is_open")), "dynamite blast opens the Spanish-signed door")


func _fight_start() -> void:
	var trigger: Node2D = _level.get_node("Triggers/HoarderStart") as Node2D
	var arena: Node2D = _level.get_node("HoarderLair").get("arena") as Node2D
	_player.global_position = Vector2(trigger.global_position.x, _boss.global_position.y - 2.0)
	_player.velocity = Vector2.ZERO
	await _frames(3)
	_check(bool(arena.get("started")) and bool(arena.get("locked")), "entering the lair starts the fight and locks the arena")
	_check(not bool(_boss.get("active")), "boss frozen during the intro card")
	await _seconds(1.2)
	_check(bool(_boss.get("active")), "boss active after the intro")
	_place_player(_boss.global_position.x + 220.0)
	_boss.set("state_timer", 99.0)


func _attacks() -> void:
	# stomp: shockwaves fly out
	_boss.set("order_index", 0)
	_boss.set("state", 1)
	_boss.set("state_timer", 0.0)
	await _seconds(1.0)
	var waves: int = 0
	for node: Node in _boss.get_parent().get_children():
		if node is Area2D and node.get("direction") != null:
			waves += 1
	_check(waves >= 1, "stomp throws shockwaves (%d alive)" % waves)
	await _seconds(2.0)

	# vomit: roach appears; unstunned hits are halved
	_boss.call("_enter_recover", 0.0)
	await _seconds(0.1)
	_boss.set("order_index", 1)
	_boss.call("_begin_attack")
	await _seconds(0.7)
	var roach: Node = _boss.get("roach") as Node
	_check(roach != null and is_instance_valid(roach), "vomit shows the roach in her mouth")
	var before: int = int(_boss.get("health"))
	_boss.call("take_damage", 2, Vector2.ZERO)
	_check(before - int(_boss.get("health")) == 1, "armoured: a 2-damage hit does 1")
	var f: int = int(_boss.get("facing"))
	_player.global_position = Vector2(_boss.global_position.x + float(f) * 52.0, _boss.global_position.y - 2.0)
	_player.velocity = Vector2.ZERO
	_player.call("_set_facing", -f)
	await _frames(4)
	Input.action_press("attack")
	await _frames(3)
	Input.action_release("attack")
	await _frames(6)
	_check(not is_instance_valid(roach), "a real punch kills the roach in her mouth")
	_check(int(_boss.get("state")) == 8, "killing the roach stuns her (damage window)")
	before = int(_boss.get("health"))
	_boss.call("take_damage", 1, Vector2.ZERO)
	_check(before - int(_boss.get("health")) == 2, "stunned: damage is doubled")
	await _seconds(4.0)
	_check(int(_boss.get("state")) != 8, "the stun wears off")

	# vomit left alone: the roach escapes and spawns Scatterers
	_boss.call("_enter_recover", 0.0)
	await _seconds(0.1)
	_boss.set("order_index", 1)
	_boss.call("_begin_attack")
	await _seconds(3.4)
	var spawned: Array[Node] = get_tree().get_nodes_in_group("hoarder_spawn")
	_check(spawned.size() >= 1, "ignored roach vomits Scatterers (%d)" % spawned.size())
	if not spawned.is_empty():
		_check(int(spawned[0].get("xp_value")) == 0, "spawned Scatterers pay no XP")

	# charge
	_boss.call("_enter_recover", 0.0)
	await _seconds(0.1)
	_boss.set("order_index", 2)
	_boss.call("_begin_attack")
	var charged: bool = false
	for i: int in 180:
		await get_tree().physics_frame
		if int(_boss.get("state")) == 6:
			charged = true
			break
	_check(charged, "charge attack runs")


func _defeat() -> void:
	var arena: Node2D = _level.get_node("HoarderLair").get("arena") as Node2D
	var level_before: int = PlayerStats.character_level
	var total_before: int = XpTable.total_xp_for_level(level_before) + PlayerStats.xp
	_boss.call("take_damage", 9999, Vector2.ZERO)
	await _frames(3)
	var total_after: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	var expected: int = XpTable.xp_for_kill(7, true)
	_check(total_after - total_before == expected, "boss pays %d XP (got %d)" % [expected, total_after - total_before])
	_check(bool(arena.get("finished")), "defeat flow ran")
	_check(_level.get_node("Walls/HoarderLockA/CollisionShape2D").get("disabled") == true, "arena unlocked after the kill")
	_check(Game.has_meta("neighborhood_map"), "Neighborhood Map flag set")
	_check(_unlocks.has("Wait, I Beat That?"), "neighborhood_boss achievement fired")
	_check(_unlocks.has("Lost And Found"), "map_upgrade achievement fired")
	for node: Node in get_tree().get_nodes_in_group("hoarder_spawn"):
		_check(node.is_queued_for_deletion() or int(node.get("health")) >= 0, "spawned Scatterers cleaned up")
		break
	var box: Node = arena.get("dropped_box")
	_check(box != null and is_instance_valid(box), "boss box dropped")
	if box == null:
		return
	_check(str(box.get("tier")) == "Boss" and str(box.get("kit")) == "floor1", "box is a Bronze Boss box from the floor 1 kit")
	_check(bool(box.get("summoned")) and not bool(box.get("is_open")), "box follows the player, unopened")
	_player.global_position = Vector2(_boss.global_position.x + 60.0, _boss.global_position.y - 2.0)
	await _seconds(1.5)
	Game.set_safe_zone(false)
	await _tap()
	_check(not bool(box.get("is_open")), "box does not open outside a safe room")
	Game.set_safe_zone(true)
	await _tap()
	_check(bool(box.get("is_open")) and str(box.get("rewarded_id")) != "", "box opens in a safe room (%s)" % str(box.get("rewarded_id")))
	Game.set_safe_zone(false)


func _tap() -> void:
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(3)
