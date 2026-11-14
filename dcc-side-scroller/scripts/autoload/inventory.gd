extends Node

signal changed

const SLOT_COUNT: int = 24
const HOTBAR_SIZE: int = 5
const EQUIP_SLOTS: PackedStringArray = ["head", "body", "left_hand", "right_hand", "left_foot", "right_foot"]
const ItemEffects: GDScript = preload("res://scripts/combat/item_effects.gd")

var slots: Array[Dictionary] = []
var equipped: Dictionary = {}
var hotbar: Array[String] = []


func _ready() -> void:
	_fill_empty()


func add_item(id: String, item_name: String, tier: String = "", count: int = 1, extra: Dictionary = {}) -> bool:
	if count <= 0:
		return false
	for slot: Dictionary in slots:
		if not slot.is_empty() and str(slot["id"]) == id:
			slot["count"] = int(slot["count"]) + count
			changed.emit()
			return true
	for i: int in slots.size():
		if slots[i].is_empty():
			var item: Dictionary = {"id": id, "name": item_name, "tier": tier, "count": count}
			for key: Variant in extra:
				item[key] = extra[key].duplicate() if extra[key] is Dictionary else extra[key]
			slots[i] = item
			changed.emit()
			return true
	return false


func remove_at(index: int, count: int = 1) -> Dictionary:
	if index < 0 or index >= slots.size() or slots[index].is_empty() or count <= 0:
		return {}
	var slot: Dictionary = slots[index]
	var removed_count: int = mini(count, int(slot["count"]))
	var removed: Dictionary = slot.duplicate()
	removed["count"] = removed_count
	if removed_count >= int(slot["count"]):
		slots[index] = {}
	else:
		slot["count"] = int(slot["count"]) - removed_count
	changed.emit()
	return removed


func has_item(id: String) -> bool:
	for slot: Dictionary in slots:
		if not slot.is_empty() and str(slot["id"]) == id:
			return true
	return false


func equip_from(index: int) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var item: Dictionary = slots[index]
	var slot_name: String = str(item.get("slot", ""))
	if not EQUIP_SLOTS.has(slot_name):
		return false
	var old: Dictionary = equipped[slot_name]
	var piece: Dictionary = item.duplicate(true)
	piece["count"] = 1
	if int(item["count"]) > 1:
		if not old.is_empty() and _free_target(old) == -1:
			return false
		item["count"] = int(item["count"]) - 1
		if not old.is_empty():
			_stash(old)
	else:
		slots[index] = old
	equipped[slot_name] = piece
	changed.emit()
	return true


func unequip(slot_name: String) -> bool:
	if not equipped.has(slot_name) or equipped[slot_name].is_empty():
		return false
	var item: Dictionary = equipped[slot_name]
	if _free_target(item) == -1:
		return false
	_stash(item)
	equipped[slot_name] = {}
	changed.emit()
	return true


func equipment_bonus(stat_name: String) -> int:
	var total: int = 0
	for slot_name: String in EQUIP_SLOTS:
		var item: Dictionary = equipped.get(slot_name, {})
		if item.is_empty():
			continue
		var bonuses: Dictionary = item.get("bonuses", {})
		total += int(bonuses.get(stat_name, 0))
	return total


## Sum of a numeric item field (reflect, regen) over everything worn.
func equipment_value(key: String) -> float:
	var total: float = 0.0
	for slot_name: String in EQUIP_SLOTS:
		var item: Dictionary = equipped.get(slot_name, {})
		if not item.is_empty():
			total += float(item.get(key, 0.0))
	return total


func count_of(id: String) -> int:
	var total: int = 0
	for slot: Dictionary in slots:
		if not slot.is_empty() and str(slot["id"]) == id:
			total += int(slot["count"])
	return total


## Consumes one of a "use" item (potion, toast, cookie). False when it has no
## effect right now (full health, no player), in which case nothing is spent.
func use_item(index: int) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var item: Dictionary = slots[index]
	var use: String = str(item.get("use", ""))
	if use.is_empty() or not ItemEffects.apply_use(use, int(item.get("amount", 0))):
		return false
	remove_at(index, 1)
	return true


func assign_hotbar(index: int, item_id: String) -> void:
	if index < 0 or index >= HOTBAR_SIZE:
		return
	for i: int in HOTBAR_SIZE:
		if hotbar[i] == item_id:
			hotbar[i] = ""
	hotbar[index] = item_id
	changed.emit()


func clear_hotbar(index: int) -> void:
	if index < 0 or index >= HOTBAR_SIZE or hotbar[index].is_empty():
		return
	hotbar[index] = ""
	changed.emit()


func hotbar_item(index: int) -> Dictionary:
	if index < 0 or index >= HOTBAR_SIZE or hotbar[index].is_empty():
		return {}
	var item_id: String = hotbar[index]
	for slot: Dictionary in slots:
		if not slot.is_empty() and str(slot["id"]) == item_id:
			return slot
	for slot_name: String in EQUIP_SLOTS:
		var item: Dictionary = equipped[slot_name]
		if not item.is_empty() and str(item["id"]) == item_id:
			return item
	return {}


func is_equipped(item_id: String) -> bool:
	for slot_name: String in EQUIP_SLOTS:
		var item: Dictionary = equipped[slot_name]
		if not item.is_empty() and str(item["id"]) == item_id:
			return true
	return false


func use_hotbar(index: int) -> bool:
	var item: Dictionary = hotbar_item(index)
	if item.is_empty():
		return false
	var item_id: String = str(item["id"])
	if not str(item.get("use", "")).is_empty():
		for i: int in slots.size():
			if not slots[i].is_empty() and str(slots[i]["id"]) == item_id:
				return use_item(i)
		return false
	for slot_name: String in EQUIP_SLOTS:
		var worn: Dictionary = equipped[slot_name]
		if not worn.is_empty() and str(worn["id"]) == item_id:
			return unequip(slot_name)
	for i: int in slots.size():
		if not slots[i].is_empty() and str(slots[i]["id"]) == item_id:
			return equip_from(i)
	return false


func clear() -> void:
	_fill_empty()
	changed.emit()


func can_add_entity(node: Node) -> bool:
	if not node.is_in_group("enemies"):
		return true
	var health: Variant = node.get("health")
	return health == null or int(health) <= 0


func _free_target(item: Dictionary) -> int:
	for i: int in slots.size():
		if not slots[i].is_empty() and str(slots[i]["id"]) == str(item["id"]):
			return i
	for i: int in slots.size():
		if slots[i].is_empty():
			return i
	return -1


func _stash(item: Dictionary) -> void:
	var target: int = _free_target(item)
	if target == -1:
		return
	if slots[target].is_empty():
		slots[target] = item
	else:
		slots[target]["count"] = int(slots[target]["count"]) + int(item.get("count", 1))


func _fill_empty() -> void:
	slots.clear()
	equipped.clear()
	hotbar.clear()
	for i: int in HOTBAR_SIZE:
		hotbar.append("")
	for slot_name: String in EQUIP_SLOTS:
		equipped[slot_name] = {}
	for i: int in SLOT_COUNT:
		slots.append({})
