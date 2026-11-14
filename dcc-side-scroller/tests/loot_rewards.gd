extends Node

const ItemDefs: GDScript = preload("res://scripts/data/item_defs.gd")
const LootTables: GDScript = preload("res://scripts/data/loot_tables.gd")
const ItemEffects: GDScript = preload("res://scripts/combat/item_effects.gd")
const Explosives: GDScript = preload("res://scripts/combat/explosives.gd")
const BOX: PackedScene = preload("res://scenes/props/loot_box.tscn")
const PLAYER: PackedScene = preload("res://scenes/player/player.tscn")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")
const TIERS: PackedStringArray = ["Bronze", "Silver", "Gold", "Boss", "Legendary"]

var _fails: int = 0


class Dummy:
	extends Node2D
	var hits: int = 0
	var last: int = 0

	func take_damage(amount: int, _from: Vector2) -> void:
		hits += 1
		last = amount


func _ready() -> void:
	await _run()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _fresh() -> void:
	Inventory.clear()
	PlayerStats.reset()
	PlayerStats.enter_floor(1)


func _run() -> void:
	_tables()
	await _boxes_give_items()
	await _effects()
	await _persistence()


func _tables() -> void:
	var bad: int = 0
	var no_pants: bool = true
	for kit: String in LootTables.KITS:
		for tier: String in TIERS:
			var list: Array = LootTables.entries(kit, tier)
			_check(not list.is_empty(), "kit '%s' has a %s table" % [kit, tier])
			for entry: Array in list:
				var id: String = str(entry[0])
				if not ItemDefs.has(id) or str(ItemDefs.DEFS[id].get("desc", "")).is_empty() or int(entry[2]) < 1:
					bad += 1
				elif "pants" in ItemDefs.item_name(id).to_lower() or "pants" in id:
					no_pants = false
	_check(bad == 0, "every table entry is a defined item with a tooltip")
	_check(no_pants, "Carl never gets pants")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Dictionary = {}
	for i: int in 200:
		seen[str(LootTables.roll("floor1", "Bronze", rng)["id"])] = true
	_check(seen.size() == LootTables.entries("floor1", "Bronze").size(), "floor1 Bronze rolls every entry (%d kinds)" % seen.size())


func _boxes_give_items() -> void:
	for tier: String in TIERS:
		_fresh()
		var box: Area2D = BOX.instantiate() as Area2D
		box.set("tier", tier)
		box.set("kit", "floor1")
		add_child(box)
		box.call("_open")
		var id: String = str(box.get("rewarded_id"))
		_check(Inventory.has_item(id), "%s box gives %s" % [tier, id])
		var item: Dictionary = {}
		for slot: Dictionary in Inventory.slots:
			if not slot.is_empty():
				item = slot
		_check(not item.is_empty() and str(item.get("desc", "")) != "" and str(item.get("effect", "")) != "", "%s item carries tooltip text" % tier)
		var mechanical: bool = item.has("bonuses") or item.has("use") or item.has("reflect") or item.has("regen") or item.has("passive") or str(item.get("id", "")) == "dynamite"
		_check(mechanical, "%s item has a mechanical effect" % tier)
		box.queue_free()
	await _frames(1)


func _effects() -> void:
	_fresh()
	var player: CharacterBody2D = PLAYER.instantiate() as CharacterBody2D
	add_child(player)
	await _frames(3)
	var max_hp: int = int(player.get("max_health"))
	player.set("health", 2)
	ItemDefs.give("healing_potion", 2)
	_check(Inventory.use_item(_index("healing_potion")), "healing potion used")
	_check(int(player.get("health")) == 8, "healing potion restores 6 health")
	player.set("health", max_hp)
	_check(not Inventory.use_item(_index("healing_potion")), "potion refused at full health")
	_check(Inventory.count_of("healing_potion") == 1, "refused potion is not consumed")
	player.set("mana", 0.0)
	PlayerStats.mana = 0
	ItemDefs.give("mana_potion")
	_check(Inventory.use_item(_index("mana_potion")) and float(player.get("mana")) >= 5.0 and PlayerStats.mana >= 3, "mana potion restores mana")
	player.set("mana", 0.0)
	PlayerStats.mana = 0
	ItemDefs.give("mana_toast")
	Inventory.assign_hotbar(0, "mana_toast")
	_check(Inventory.use_hotbar(0), "toast used from the hotbar")
	_check(float(player.get("mana")) == float(player.get("max_mana")) and PlayerStats.mana == PlayerStats.max_mana(), "mana toast refills mana")
	var xp_before: int = PlayerStats.xp
	ItemDefs.give("experience_cookie")
	_check(Inventory.use_item(_index("experience_cookie")) and PlayerStats.xp == xp_before + 60, "experience cookie grants 60 xp")
	var str_before: int = PlayerStats.get_stat("strength")
	ItemDefs.give("toe_ring")
	_check(Inventory.equip_from(_index("toe_ring")) and PlayerStats.get_stat("strength") == str_before + 3, "toe ring: +3 strength")
	ItemDefs.give("fireplace_poker")
	_check(Inventory.equip_from(_index("fireplace_poker")) and PlayerStats.get_stat("strength") == str_before + 4, "poker: +1 strength")
	ItemDefs.give("nightgaunt_cloak")
	_check(Inventory.equip_from(_index("nightgaunt_cloak")), "cloak equips on the head")
	await _frames(1)
	_check(int(player.get("max_health")) == max_hp + 8, "cloak +4 CON raises max health live (%d -> %d)" % [max_hp, int(player.get("max_health"))])
	var interval: float = PlayerStats.health_regen_interval()
	ItemDefs.give("trollskin_shirt")
	_check(Inventory.equip_from(_index("trollskin_shirt")) and Inventory.equipped["body"].get("id") == "trollskin_shirt", "shirt equips in the body slot")
	_check(is_equal_approx(PlayerStats.health_regen_interval(), interval / 2.0), "trollskin shirt doubles regeneration")
	ItemDefs.give("spiked_kneepads")
	_check(Inventory.equip_from(_index("spiked_kneepads")), "kneepads equip")
	var dummy: Dummy = Dummy.new()
	dummy.add_to_group("enemies")
	add_child(dummy)
	dummy.global_position = player.global_position + Vector2(20.0, 0.0)
	player.call("take_damage", 3, dummy.global_position)
	_check(dummy.hits == 1 and dummy.last == 1, "kneepads reflect a hit back to the attacker")
	Inventory.unequip("left_foot")
	player.set("health", int(player.get("max_health")))
	await get_tree().create_timer(1.1).timeout
	dummy.hits = 0
	player.call("take_damage", 3, dummy.global_position)
	_check(dummy.hits == 0, "no reflect without kneepads")
	_check(not ItemEffects.has_goblin_pass(), "no goblin pass yet")
	ItemDefs.give("goblin_pass")
	_check(ItemEffects.has_goblin_pass(), "goblin pass is in the bag and readable by #55")
	Explosives.reset()
	ItemDefs.give("dynamite", 3)
	Explosives.add_stack(2)
	_check(Explosives.stack_count() == 5, "dynamite stacks with box and pickup (%d)" % Explosives.stack_count())
	player.queue_free()
	dummy.queue_free()
	await _frames(2)


func _persistence() -> void:
	Inventory.clear()
	PlayerStats.reset()
	PlayerStats.enter_floor(0)
	ItemDefs.give("toe_ring")
	ItemDefs.give("dynamite", 2)
	Inventory.equip_from(_index("toe_ring"))
	_check(PlayerStats.get_stat("strength") == 0, "Level 0 stats are inactive")
	var level: Node2D = LEVEL.instantiate() as Node2D
	add_child(level)
	await _frames(5)
	_check(PlayerStats.active and PlayerStats.floor_number == 1, "Level 1 is active")
	_check(Inventory.count_of("dynamite") == 2 and Inventory.is_equipped("toe_ring"), "items survive the Level 0 to Level 1 transition")
	_check(PlayerStats.get_stat("strength") == PlayerStats.BASE_VALUE + 3, "carried gear takes effect on Floor 1")
	level.queue_free()
	await _frames(2)
	Inventory.clear()


func _index(id: String) -> int:
	for i: int in Inventory.slots.size():
		if not Inventory.slots[i].is_empty() and str(Inventory.slots[i]["id"]) == id:
			return i
	return -1
