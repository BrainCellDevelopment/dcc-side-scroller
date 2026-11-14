extends RefCounted
## Loot tables (#52). A "kit" is a set of per-tier tables.
## "" is the tutorial kit: one fixed item per tier, so Level 0 is predictable.
## "floor1" is weighted and used by Floor 1 safe rooms and the Neighborhood boss box.
## Boss is a tier of its own: gear pieces only. Carl never gets pants.

const DEFAULT_KIT: String = ""
const FLOOR1_KIT: String = "floor1"
## "floor1_room" is the fast-food safe room's own kit (#71): it is the only safe room, so its Bronze box is
## a guaranteed lifeline (two healing potions) and its Silver box is food (cookie or toast).
const ROOM_KIT: String = "floor1_room"
const TIER_FALLBACK: String = "Bronze"

## Each entry: [item id, weight, count].
const KITS: Dictionary = {
	"": {
		"Bronze": [["bandages", 1, 1]],
		"Silver": [["knuckle_wraps", 1, 1]],
		"Gold": [["lucky_boxers", 1, 1]],
		"Legendary": [["legendary_pet_biscuit", 1, 1]],
		"Boss": [["nightgaunt_cloak", 1, 1]],
	},
	"floor1": {
		"Bronze": [["healing_potion", 3, 2], ["mana_potion", 3, 2], ["dynamite", 3, 3], ["fireplace_poker", 2, 1], ["bandages", 1, 1]],
		"Silver": [["mana_toast", 3, 2], ["experience_cookie", 3, 1], ["goblin_pass", 2, 1], ["toe_ring", 2, 1], ["knuckle_wraps", 1, 1]],
		"Gold": [["spiked_kneepads", 3, 1], ["lucky_boxers", 2, 1], ["dynamite", 2, 5], ["healing_potion", 2, 4]],
		"Legendary": [["legendary_pet_biscuit", 1, 1]],
		"Boss": [["nightgaunt_cloak", 1, 1], ["trollskin_shirt", 1, 1], ["spiked_kneepads", 1, 1]],
	},
	"floor1_room": {
		"Bronze": [["healing_potion", 1, 2]],
		"Silver": [["experience_cookie", 1, 1], ["mana_toast", 1, 2]],
	},
}


static func entries(kit: String, tier: String) -> Array:
	var tables: Dictionary = KITS.get(kit, KITS[DEFAULT_KIT])
	return tables.get(tier, tables[TIER_FALLBACK])


## Returns {"id": String, "count": int}. Pass a seeded RandomNumberGenerator for tests.
static func roll(kit: String, tier: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var list: Array = entries(kit, tier)
	var total: int = 0
	for entry: Array in list:
		total += int(entry[1])
	var r: RandomNumberGenerator = rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	var pick: int = r.randi_range(0, maxi(total - 1, 0))
	for entry: Array in list:
		pick -= int(entry[1])
		if pick < 0:
			return {"id": str(entry[0]), "count": int(entry[2])}
	return {"id": str(list[0][0]), "count": int(list[0][2])}
