extends RefCounted

const ITEM_ID: String = "dynamite"
const ITEM_NAME: String = "Goblin Dynamite"
const BOOM_ACHIEVEMENT: String = "boom"
const BOOM_HITS: int = 3
const BODY_CENTER: Vector2 = Vector2(0.0, -12.0)

static var handling: int = 0


static func reset() -> void:
	handling = 0


static func stack_count() -> int:
	var total: int = 0
	for slot: Dictionary in Inventory.slots:
		if not slot.is_empty() and str(slot["id"]) == ITEM_ID:
			total += int(slot["count"])
	return total


static func add_stack(count: int = 1) -> bool:
	return Inventory.add_item(ITEM_ID, ITEM_NAME, "Bronze", count)


# Takes one stick from the inventory stack. False when the player has none.
static func consume_one() -> bool:
	for i: int in Inventory.slots.size():
		var slot: Dictionary = Inventory.slots[i]
		if not slot.is_empty() and str(slot["id"]) == ITEM_ID:
			Inventory.remove_at(i, 1)
			return true
	return false


# Applies a blast at `center`. Anything whose body centre is within `radius` is hit:
# enemies take `damage`, the player takes `player_damage` (0 disables), and nodes in the
# "destructibles" group get blast(center). Returns the nodes that were hit.
static func blast(tree: SceneTree, center: Vector2, radius: float, damage: int, player_damage: int) -> Array[Node]:
	var hit: Array[Node] = []
	for node: Node in tree.get_nodes_in_group("enemies"):
		var body: Node2D = node as Node2D
		if body == null or not _in_range(body, center, radius):
			continue
		if body.has_method("take_damage"):
			body.call("take_damage", damage, center)
		hit.append(body)
	for node: Node in tree.get_nodes_in_group("destructibles"):
		var prop: Node2D = node as Node2D
		if prop != null and _in_range(prop, center, radius) and prop.has_method("blast"):
			prop.call("blast", center)
			hit.append(prop)
	var enemy_or_prop_hits: int = hit.size()
	var player: Node2D = tree.get_first_node_in_group("player") as Node2D
	if player != null and player_damage > 0 and _in_range(player, center, radius):
		player.call("take_damage", player_damage, center)
		hit.append(player)
	if enemy_or_prop_hits > 0:
		handling += 1
	if enemy_or_prop_hits >= BOOM_HITS:
		SystemVoice.fire(BOOM_ACHIEVEMENT)
	return hit


static func _in_range(body: Node2D, center: Vector2, radius: float) -> bool:
	var origin: Vector2 = body.global_position
	if body.is_in_group("enemies") or body.is_in_group("player"):
		origin += BODY_CENTER
	return origin.distance_to(center) <= radius
