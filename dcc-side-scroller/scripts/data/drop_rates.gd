extends RefCounted
## Mob loot box drop rates (#95). Two rolls per kill: first whether a box drops at all,
## then which tier. Tier weights are relative, not percentages.

const BOX_CHANCE: float = 0.18
const TIER_WEIGHTS: Dictionary = {
	"Bronze": 70.0,
	"Silver": 22.0,
	"Gold": 7.5,
	"Legendary": 0.05,
}
## Level 0 hands out 10 boxes in total: the fixed starters (Bronze and the Legendary
## Pet Biscuit box) plus earned Bronze and Silver boxes, nothing rarer.
const TUTORIAL_TIERS: PackedStringArray = ["Bronze", "Silver"]
const TUTORIAL_BOX_TOTAL: int = 10
const STARTER_BOX_COUNT: int = 2
const TUTORIAL_BOX_CAP: int = TUTORIAL_BOX_TOTAL - STARTER_BOX_COUNT
## Added to the Legendary weight for each boss kill, until a Legendary drops.
const BOSS_LEGENDARY_BONUS: float = 0.5


## Returns the tier of the dropped box, or "" when nothing drops.
static func roll(legendary_bonus: float = 0.0, rng: RandomNumberGenerator = null, tutorial: bool = false) -> String:
	var r: RandomNumberGenerator = rng
	if r == null:
		r = RandomNumberGenerator.new()
		r.randomize()
	if r.randf() >= BOX_CHANCE:
		return ""
	return pick_tier(legendary_bonus, r, tutorial)


static func pick_tier(legendary_bonus: float, r: RandomNumberGenerator, tutorial: bool = false) -> String:
	var weights: Dictionary = TIER_WEIGHTS.duplicate()
	if tutorial:
		for tier: String in TIER_WEIGHTS:
			if not TUTORIAL_TIERS.has(tier):
				weights.erase(tier)
	else:
		weights["Legendary"] = float(weights["Legendary"]) + legendary_bonus
	var total: float = 0.0
	for tier: String in weights:
		total += float(weights[tier])
	var pick: float = r.randf() * total
	for tier: String in weights:
		pick -= float(weights[tier])
		if pick < 0.0:
			return tier
	return "Bronze"
