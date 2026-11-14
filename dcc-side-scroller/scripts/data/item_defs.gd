extends RefCounted
## Floor 1 item catalogue (#52). Pure data: the loot box, the inventory and the
## tooltip all read from here. Descriptions are in the System's voice.
##
## Fields: name, tier (border colour), slot (equipment slot, optional),
## bonuses (stat -> amount, applied through Inventory.equipment_bonus),
## use (consumable effect id, see item_effects.gd), amount (use strength),
## reflect (fraction of melee damage returned), regen (extra health regen),
## passive (effect that works from the bag), desc (tooltip text), effect (one-line mechanics).

const DEFS: Dictionary = {
	"bandages": {
		"name": "Slightly Used Bandages", "tier": "Bronze", "slot": "left_hand",
		"bonuses": {"constitution": 1},
		"desc": "Previously worn by someone who did not make it. Nobody checked the stains.",
		"effect": "+1 Constitution",
	},
	"knuckle_wraps": {
		"name": "Spiked Knuckle Wraps", "tier": "Silver", "slot": "right_hand",
		"bonuses": {"strength": 2},
		"desc": "Adds spikes to your fist so your opponent's face can share the experience.",
		"effect": "+2 Strength",
	},
	"lucky_boxers": {
		"name": "Lucky Boxers", "tier": "Gold", "slot": "left_foot",
		"bonuses": {"dexterity": 2, "constitution": 1},
		"desc": "White, with little red hearts. They count as pants in the sense that nothing else does.",
		"effect": "+2 Dexterity, +1 Constitution",
	},
	"legendary_pet_biscuit": {
		"name": "Legendary Pet Biscuit", "tier": "Legendary", "slot": "head",
		"bonuses": {"charisma": 3, "intelligence": 2},
		"desc": "Meant for a cat. You wear it on your head because the System ran out of ideas.",
		"effect": "+3 Charisma, +2 Intelligence",
	},
	"fireplace_poker": {
		"name": "Fireplace Poker", "tier": "Bronze", "slot": "right_hand",
		"bonuses": {"strength": 1},
		"desc": "Still warm from somebody's cozy evening, which ended. Technically a weapon.",
		"effect": "+1 Strength",
	},
	"goblin_pass": {
		"name": "Goblin Pass", "tier": "Silver", "passive": "goblin_pass",
		"desc": "A tattoo-shaped permission slip. Goblins stop hating you on sight and start hating you on paperwork.",
		"effect": "Carried: plain goblins stay neutral. Bosses and engineers do not care",
	},
	"dynamite": {
		"name": "Goblin Dynamite", "tier": "Bronze",
		"desc": "Goblins carry it everywhere, next to the pineapples. Light, throw, and enjoy the surprise.",
		"effect": "G: throw a stick. Stacks",
	},
	"healing_potion": {
		"name": "Healing Potion", "tier": "Bronze", "use": "heal", "amount": 6,
		"desc": "Tastes like cherry cough syrup and regret. It works anyway.",
		"effect": "Use: restores 6 health",
	},
	"mana_potion": {
		"name": "Mana Potion", "tier": "Bronze", "use": "mana", "amount": 5,
		"desc": "Blue, fizzy and legally a beverage. The System asks that you do not mix it with lighter fluid.",
		"effect": "Use: restores 5 mana",
	},
	"mana_toast": {
		"name": "Mana Toast", "tier": "Silver", "use": "mana_full",
		"desc": "Buttered, crunchy, and somehow enchanted. You are being fed by a corporation. Chew.",
		"effect": "Use: restores all mana",
	},
	"experience_cookie": {
		"name": "Experience Cookie", "tier": "Silver", "use": "xp", "amount": 60,
		"desc": "Eat the lessons of strangers. Mostly chocolate chips, mostly lessons about dying.",
		"effect": "Use: gain 60 experience",
	},
	"toe_ring": {
		"name": "Toe Ring of the Splatter Skunk", "tier": "Silver", "slot": "right_foot",
		"bonuses": {"strength": 3},
		"desc": "A ring for your toe. Still no pants, still no shoes. The System is very proud of itself.",
		"effect": "+3 Strength",
	},
	"spiked_kneepads": {
		"name": "Spiked Kneepads", "tier": "Gold", "slot": "left_foot", "reflect": 0.25,
		"bonuses": {"constitution": 1},
		"desc": "Retractable needles for knees. Whoever hits you learns something about sharp edges.",
		"effect": "+1 Constitution. Returns a quarter of melee damage (at least 1)",
	},
	"nightgaunt_cloak": {
		"name": "Nightgaunt Cloak", "tier": "Gold", "slot": "head",
		"bonuses": {"constitution": 4},
		"desc": "Cut from something that used to haunt a cellar. Stout, drafty, and absolutely not pants.",
		"effect": "+4 Constitution",
	},
	"trollskin_shirt": {
		"name": "Trollskin Shirt", "tier": "Gold", "slot": "body", "regen": 1.0,
		"desc": "Hide from a troll that was extremely good at healing. Do not ask about the previous owner.",
		"effect": "Health regenerates twice as fast",
	},
}


static func has(id: String) -> bool:
	return DEFS.has(id)


static func item_name(id: String) -> String:
	return str(DEFS[id]["name"])


static func tier(id: String) -> String:
	return str(DEFS[id].get("tier", ""))


## Everything except name/tier, ready to pass as the `extra` of Inventory.add_item.
static func extra(id: String) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in DEFS[id]:
		if key != "name" and key != "tier":
			out[key] = DEFS[id][key].duplicate() if DEFS[id][key] is Dictionary else DEFS[id][key]
	return out


## Adds `count` of an item through Game.add_item so the pickup toast fires.
static func give(id: String, count: int = 1) -> bool:
	if not DEFS.has(id):
		return false
	var before: int = Inventory.count_of(id)
	Game.add_item(id, item_name(id), tier(id), extra(id), count)
	return Inventory.count_of(id) > before
