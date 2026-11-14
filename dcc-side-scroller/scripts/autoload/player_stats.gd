extends Node

signal stats_changed
signal leveled_up(level: int)
signal xp_gained(amount: int)
signal mana_changed(current: int, maximum: int)

const STAT_NAMES: PackedStringArray = ["strength", "intelligence", "constitution", "dexterity", "charisma"]
const POINTS_PER_LEVEL: int = 3
const CLASS_SELECT_FLOOR: int = 3
const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")
const REGEN_SECONDS_TIMES_CON: float = 300.0
const MANA_REGEN_SECONDS: float = 3600.0
const BASE_VALUE: int = 5
const BASE_HEALTH: int = 10
const HEALTH_PER_CON: int = 2
const STRENGTH_PER_DAMAGE: int = 3
const SMUSH_MANY: int = 10

var active: bool = false
var floor_number: int = 0
var character_level: int = 1
var xp: int = 0
var unspent_points: int = 0
var class_chosen: bool = false
var mana: int = 0
var smush_count: int = 0
var _awarded: Dictionary = {}

var _base: Dictionary = {}
var _bonus: Dictionary = {}
var _mana_timer: float = 0.0


func _ready() -> void:
	reset()
	add_child(preload("res://scripts/ui/tab_menu.gd").new())
	add_child(preload("res://scripts/ui/hotbar.gd").new())
	_connect_inventory.call_deferred()


func _connect_inventory() -> void:
	var inventory: Node = get_node_or_null("/root/Inventory")
	if inventory != null:
		inventory.changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	mana = mini(mana, max_mana())
	stats_changed.emit()


func _process(delta: float) -> void:
	if not active or mana >= max_mana():
		return
	_mana_timer += delta
	if _mana_timer >= MANA_REGEN_SECONDS:
		_mana_timer = 0.0
		restore_mana(1)


func reset() -> void:
	active = false
	floor_number = 0
	character_level = 1
	xp = 0
	unspent_points = 0
	class_chosen = false
	smush_count = 0
	_mana_timer = 0.0
	_awarded.clear()
	for stat_name: String in STAT_NAMES:
		_base[stat_name] = BASE_VALUE
		_bonus[stat_name] = 0
	_base["intelligence"] = 3
	mana = max_mana()
	stats_changed.emit()


func enter_floor(floor_index: int) -> void:
	floor_number = floor_index
	var was_active: bool = active
	active = floor_index >= 1
	if floor_index >= CLASS_SELECT_FLOOR:
		class_chosen = true
	if active and not was_active:
		mana = max_mana()
	var voice: Node = get_node_or_null("/root/SystemVoice")
	if voice != null:
		if active:
			voice.begin_floor(floor_index)
		else:
			voice.end_floor()
	stats_changed.emit()


func get_stat(stat_name: String) -> int:
	if not active or not _base.has(stat_name):
		return 0
	var gear: int = 0
	var inventory: Node = get_node_or_null("/root/Inventory")
	if inventory != null:
		gear = int(inventory.equipment_bonus(stat_name))
	return int(_base[stat_name]) + int(_bonus[stat_name]) + gear


func set_bonus(stat_name: String, amount: int) -> void:
	if not _bonus.has(stat_name):
		return
	_bonus[stat_name] = amount
	mana = mini(mana, max_mana())
	stats_changed.emit()


func add_xp(amount: int) -> void:
	if not active or amount <= 0:
		return
	xp += amount
	xp_gained.emit(amount)
	while xp >= xp_to_next():
		xp -= xp_to_next()
		character_level += 1
		unspent_points += POINTS_PER_LEVEL
		leveled_up.emit(character_level)
	stats_changed.emit()


## Call when the player's bare-foot stomp kills something (the Smush counter). The first-stomp
## achievement lives in SystemVoice; this one marks ten kills.
func add_smush() -> void:
	smush_count += 1
	if smush_count == SMUSH_MANY:
		Game.unlock_achievement("smush_ten", "Stompetition", "Ten stomps. The audience has started keeping score on your socks, which you do not have.")
	stats_changed.emit()


func xp_to_next() -> int:
	return XpTable.xp_to_next(character_level)


## Call once when an enemy dies. Reads enemy_level, xp_value (-1 = use the
## table) and is_boss from the node. A statically placed enemy pays out only
## once even if its scene reloads after a death (no XP farming).
func award_kill(enemy: Node) -> int:
	if not active or enemy == null:
		return 0
	var key: String = ""
	if enemy.is_inside_tree() and not str(enemy.name).begins_with("@"):
		key = str(enemy.get_path())
		if _awarded.has(key):
			return 0
	var amount: int = int(enemy.get("xp_value")) if enemy.get("xp_value") != null else -1
	if amount < 0:
		var lvl: int = int(enemy.get("enemy_level")) if enemy.get("enemy_level") != null else XpTable.BOOK_LEVEL
		var boss: bool = bool(enemy.get("is_boss")) if enemy.get("is_boss") != null else false
		amount = XpTable.xp_for_kill(lvl, boss)
	if not key.is_empty():
		_awarded[key] = true
	add_xp(amount)
	var voice: Node = get_node_or_null("/root/SystemVoice")
	if voice != null:
		voice.count("kill")
		if enemy.get("is_boss") != null and bool(enemy.get("is_boss")):
			voice.count("boss_kill")
	return amount


## Seconds per point of health regained; 0 when stats are inactive. Scales with Constitution.
func health_regen_interval() -> float:
	if not active:
		return 0.0
	var interval: float = REGEN_SECONDS_TIMES_CON / float(maxi(get_stat("constitution"), 1))
	var inventory: Node = get_node_or_null("/root/Inventory")
	if inventory != null:
		interval /= 1.0 + float(inventory.equipment_value("regen"))
	return interval


func can_spend_points() -> bool:
	return active and class_chosen and unspent_points > 0


func spend_point(stat_name: String) -> bool:
	if not can_spend_points() or not _base.has(stat_name):
		return false
	_base[stat_name] = int(_base[stat_name]) + 1
	unspent_points -= 1
	stats_changed.emit()
	return true


func max_mana() -> int:
	return get_stat("intelligence")


func spend_mana(amount: int) -> bool:
	if not active or mana < amount:
		return false
	mana -= amount
	mana_changed.emit(mana, max_mana())
	return true


func restore_mana(amount: int) -> void:
	mana = mini(mana + amount, max_mana())
	mana_changed.emit(mana, max_mana())


func max_health() -> int:
	if not active:
		return BASE_HEALTH
	return maxi(BASE_HEALTH + (get_stat("constitution") - BASE_VALUE) * HEALTH_PER_CON, 1)


func damage_bonus() -> int:
	if not active:
		return 0
	return maxi((get_stat("strength") - BASE_VALUE) / STRENGTH_PER_DAMAGE, 0)


func summary() -> String:
	if not active:
		return "stats inactive (floor %d)" % floor_number
	var parts: PackedStringArray = PackedStringArray()
	for stat_name: String in STAT_NAMES:
		parts.append("%s %d" % [stat_name.substr(0, 3).to_upper(), get_stat(stat_name)])
	return "floor %d | lvl %d xp %d/%d | pts %d%s | %s | mana %d/%d | maxhp %d dmg+%d" % [
		floor_number, character_level, xp, xp_to_next(), unspent_points,
		"" if class_chosen else " (locked until floor %d)" % CLASS_SELECT_FLOOR,
		" ".join(parts), mana, max_mana(), max_health(), damage_bonus()]
