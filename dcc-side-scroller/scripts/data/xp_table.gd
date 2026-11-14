extends RefCounted
## XP values and level thresholds for the whole crawl (#53).
## Static data only; PlayerStats owns the running totals.
##
## Tuning source: the enemy counts in docs/floor-1-plan.md (PLAN below).
## Targets: Carl ends Floor 1 at level 8 to 9 and Floor 2 at level 13 (book pacing).

const BOOK_LEVEL: int = 2
const BOOK_XP: int = 50
const XP_PER_EXTRA_LEVEL: int = 35
const MIN_XP: int = 15
const BOSS_MULTIPLIER: int = 3

## XP needed to go from level (index + 1) to level (index + 2).
const LEVEL_STEPS: Array[int] = [100, 150, 200, 300, 400, 550, 750, 1000, 1450, 1600, 1800, 2000]
const STEP_GROWTH: int = 200

## Planned Floor 1 kills per beat. "required" beats are on the main path;
## the workshop (beat 5) is an optional set piece. Counts are the design
## targets for the issues that build each beat; keep them in sync with
## docs/floor-1-plan.md when a beat changes.
const PLAN: Array[Dictionary] = [
	{"beat": 1, "name": "Arterial tunnel and llama alley", "required": true, "kills": [
		{"enemy": "Bad Llama", "level": 3, "count": 2},
		{"enemy": "Goblin thrower", "level": 2, "count": 1},
		{"enemy": "Goblin grunt", "level": 2, "count": 1},
	]},
	{"beat": 2, "name": "Rats and Scatterers corridor", "required": true, "kills": [
		{"enemy": "Rat", "level": 2, "count": 5},
		{"enemy": "Scatterer", "level": 2, "count": 6},
	]},
	{"beat": 4, "name": "Mid-boss: the Hoarder", "required": true, "kills": [
		{"enemy": "Scatterer", "level": 2, "count": 4},
		{"enemy": "The Hoarder", "level": 7, "count": 1, "boss": true},
	]},
	{"beat": 5, "name": "Goblin workshop", "required": false, "kills": [
		{"enemy": "Goblin grunt", "level": 2, "count": 4},
		{"enemy": "Goblin Bomb Bard", "level": 5, "count": 2},
		{"enemy": "Shamanka", "level": 7, "count": 1},
	]},
	{"beat": 6, "name": "Final boss: Ball of Swine", "required": true, "kills": [
		{"enemy": "Tuskling Knight", "level": 4, "count": 3},
		{"enemy": "Tuskling Courtesan", "level": 5, "count": 2},
		{"enemy": "Tuskling Dominatrix", "level": 8, "count": 1},
		{"enemy": "Ball of Swine", "level": 15, "count": 1, "boss": true},
	]},
]


static func xp_for_kill(enemy_level: int, boss: bool = false) -> int:
	var amount: int = maxi(BOOK_XP + (enemy_level - BOOK_LEVEL) * XP_PER_EXTRA_LEVEL, MIN_XP)
	return amount * BOSS_MULTIPLIER if boss else amount


## XP to go from `level` to `level + 1`.
static func xp_to_next(level: int) -> int:
	var index: int = maxi(level, 1) - 1
	if index < LEVEL_STEPS.size():
		return LEVEL_STEPS[index]
	return LEVEL_STEPS[LEVEL_STEPS.size() - 1] + STEP_GROWTH * (index - LEVEL_STEPS.size() + 1)


## Total XP earned from level 1 to reach `level`.
static func total_xp_for_level(level: int) -> int:
	var total: int = 0
	for l: int in range(1, level):
		total += xp_to_next(l)
	return total


static func level_for_total(total: int) -> int:
	var level: int = 1
	var left: int = total
	while left >= xp_to_next(level):
		left -= xp_to_next(level)
		level += 1
	return level


static func beat_xp(beat: Dictionary) -> int:
	var total: int = 0
	for kill: Dictionary in beat["kills"]:
		total += int(kill["count"]) * xp_for_kill(int(kill["level"]), bool(kill.get("boss", false)))
	return total


static func plan_total(required_only: bool) -> int:
	var total: int = 0
	for beat: Dictionary in PLAN:
		if required_only and not bool(beat["required"]):
			continue
		total += beat_xp(beat)
	return total
