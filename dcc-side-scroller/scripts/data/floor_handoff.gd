class_name FloorHandoff
extends RefCounted
## Floor 1 to Level 2 hand-off (#68): the stats the summary card shows, the state carried across the
## stairs (health through Game, items through Inventory, XP through PlayerStats, the pass and map
## flags through Game meta) and the scene chain level01 -> yacht cabin -> level02.
## Everything is static so it survives scene changes; tests can swap the scene changer.

const CABIN_SCENE: String = "res://scenes/yacht_cabin.tscn"
const LEVEL2_SCENE: String = "res://scenes/level02.tscn"
## Game meta keys that follow Carl from floor to floor.
const FLAG_MAP: String = "neighborhood_map"
const FLAG_PASS: String = "desperado_pass"
const FLAG_FIELD_GUIDE: String = "borough_field_guide"
const FLAGS: PackedStringArray = [FLAG_MAP, FLAG_PASS, FLAG_FIELD_GUIDE]
const SURVIVORS_LOST: int = 700000

## When valid, replaces SceneTree.change_scene_to_file (tests use it to stay in one scene).
static var scene_changer: Callable = Callable()
static var play_seconds: float = 0.0
static var titles: Array[String] = []
static var boxes_opened: int = 0
static var kills_base: int = 0
static var summary: Dictionary = {}
static var carried: Dictionary = {}


## Call when a fresh run of Floor 1 begins (no checkpoint yet).
static func start_floor() -> void:
	play_seconds = 0.0
	titles.clear()
	boxes_opened = 0
	kills_base = SystemVoice.counter_value("kill")
	summary = {}
	carried = {}


static func note_achievement(title: String) -> void:
	titles.append(title)


static func note_box() -> void:
	boxes_opened += 1


static func item_total() -> int:
	var total: int = 0
	for slot: Dictionary in Inventory.slots:
		if not slot.is_empty():
			total += int(slot.get("count", 1))
	for slot_name: String in Inventory.equipped.keys():
		if not (Inventory.equipped[slot_name] as Dictionary).is_empty():
			total += 1
	return total


## Freezes the Floor 1 numbers for the summary card.
static func snapshot() -> Dictionary:
	summary = {
		"seconds": play_seconds,
		"kills": maxi(SystemVoice.counter_value("kill") - kills_base, 0),
		"achievements": titles.size(),
		"achievement_titles": titles.duplicate(),
		"boxes": boxes_opened,
		"items": item_total(),
		"survivors": SystemVoice.survivors,
		"level": PlayerStats.character_level,
	}
	return summary


static func format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d" % [total / 60, total % 60]


static func summary_lines(data: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Time on the floor:  %s" % format_time(float(data.get("seconds", 0.0))))
	lines.append("Kills:  %d" % int(data.get("kills", 0)))
	lines.append("Achievements:  %d" % int(data.get("achievements", 0)))
	lines.append("Loot:  %d boxes opened, %d items on you" % [int(data.get("boxes", 0)), int(data.get("items", 0))])
	lines.append("Survivors left:  %s" % SystemVoice.format_count(int(data.get("survivors", 0))))
	return lines


## Records what travels to the next floor. Health goes through Game.carry_player_state.
static func carry(player: Node) -> void:
	Game.carry_player_state(player)
	var flags: Dictionary = {}
	for flag: String in FLAGS:
		flags[flag] = bool(Game.get_meta(flag, false))
	carried = {
		"health": Game.carried_health,
		"flags": flags,
		"level": PlayerStats.character_level,
		"xp": PlayerStats.xp,
		"items": item_total(),
	}


static func go(tree: SceneTree, path: String) -> void:
	if scene_changer.is_valid():
		scene_changer.call(path)
	else:
		tree.change_scene_to_file(path)
