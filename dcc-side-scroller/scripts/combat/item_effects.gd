extends RefCounted
## Mechanical effects of items (#52): consumables, damage reflect and the Goblin Pass hook.
## Stat bonuses from gear are not here; they flow through Inventory.equipment_bonus.

const REFLECT_RANGE: float = 56.0


## Applies a consumable effect to the player. Returns false (nothing consumed) when it cannot work.
static func apply_use(use: String, amount: int) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var player: Node = tree.get_first_node_in_group("player") if tree != null else null
	match use:
		"heal":
			if player == null or not player.has_method("heal"):
				return false
			return bool(player.call("heal", amount))
		"mana", "mana_full":
			if player == null or not player.has_method("restore_mana"):
				return false
			return bool(player.call("restore_mana", amount if use == "mana" else 9999))
		"xp":
			if not PlayerStats.active:
				Game.set_hint("The cookie is stale until Floor 1 starts.")
				return false
			PlayerStats.add_xp(amount)
			return true
	return false


static func reflect_fraction() -> float:
	return minf(Inventory.equipment_value("reflect"), 1.0)


static func regen_bonus() -> float:
	return Inventory.equipment_value("regen")


## Melee damage `amount` was dealt to the player from `from`: returns it to the nearest enemy in reach.
static func reflect_damage(tree: SceneTree, amount: int, from: Vector2) -> Node:
	var fraction: float = reflect_fraction()
	if fraction <= 0.0 or amount <= 0 or not PlayerStats.active:
		return null
	var best: Node2D = null
	var best_dist: float = REFLECT_RANGE
	for node: Node in tree.get_nodes_in_group("enemies"):
		var body: Node2D = node as Node2D
		if body == null or not body.has_method("take_damage"):
			continue
		var d: float = body.global_position.distance_to(from)
		if d <= best_dist:
			best_dist = d
			best = body
	if best == null:
		return null
	best.call("take_damage", maxi(ceili(float(amount) * fraction), 1), from)
	return best


## Hook for #55: a Goblin Pass anywhere in the bag makes goblins non-hostile.
static func has_goblin_pass() -> bool:
	return Inventory.has_item("goblin_pass")
