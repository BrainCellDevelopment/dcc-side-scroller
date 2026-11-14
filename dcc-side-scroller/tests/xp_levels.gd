extends Node

const XpTable: GDScript = preload("res://scripts/data/xp_table.gd")
const LEVEL: PackedScene = preload("res://scenes/level01.tscn")

var _fails: int = 0
var _level_ups: Array[int] = []


func _ready() -> void:
	_table()
	_plan_run()
	await _scene_run()
	_regen()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _table() -> void:
	_check(XpTable.xp_for_kill(2) == 50, "level-2 goblin is worth 50 XP (book)")
	_check(XpTable.xp_for_kill(7, true) == XpTable.xp_for_kill(7) * XpTable.BOSS_MULTIPLIER, "boss XP is multiplied")
	var rising: bool = true
	for l: int in range(1, 20):
		if XpTable.xp_to_next(l + 1) <= XpTable.xp_to_next(l):
			rising = false
	_check(rising, "level steps strictly rise")
	_check(XpTable.level_for_total(XpTable.total_xp_for_level(9)) == 9, "level_for_total inverts total_xp_for_level")
	var required: int = XpTable.plan_total(true)
	var everything: int = XpTable.plan_total(false)
	var end_required: int = XpTable.level_for_total(required)
	var end_all: int = XpTable.level_for_total(everything)
	print("     plan XP required %d (level %d), with workshop %d (level %d)" % [required, end_required, everything, end_all])
	_check(end_required >= 8 and end_required <= 9, "required Floor 1 path ends at level 8 to 9")
	_check(end_all >= 8 and end_all <= 9, "full Floor 1 ends at level 8 to 9")
	_check(XpTable.total_xp_for_level(13) > everything, "level 13 needs Floor 2 content too")


func _plan_run() -> void:
	PlayerStats.reset()
	PlayerStats.enter_floor(1)
	_check(PlayerStats.character_level == 1 and PlayerStats.xp == 0, "run starts at level 1, 0 XP")
	var expected_after: Dictionary = {1: [2, 3], 2: [4, 5], 4: [5, 6], 5: [6, 7], 6: [8, 9]}
	for beat: Dictionary in XpTable.PLAN:
		for kill: Dictionary in beat["kills"]:
			for i: int in int(kill["count"]):
				PlayerStats.add_xp(XpTable.xp_for_kill(int(kill["level"]), bool(kill.get("boss", false))))
		var window: Array = expected_after[int(beat["beat"])]
		var level: int = PlayerStats.character_level
		print("     after beat %d (%s): level %d xp %d/%d" % [int(beat["beat"]), str(beat["name"]), level, PlayerStats.xp, PlayerStats.xp_to_next()])
		_check(level >= int(window[0]) and level <= int(window[1]), "beat %d ends at level %d to %d" % [int(beat["beat"]), int(window[0]), int(window[1])])
	_check(PlayerStats.unspent_points == (PlayerStats.character_level - 1) * 3, "3 stat points per level gained")
	_check(not PlayerStats.can_spend_points(), "points locked before Floor 3")
	PlayerStats.reset()


func _scene_run() -> void:
	PlayerStats.reset()
	_level_ups.clear()
	PlayerStats.leveled_up.connect(func(l: int) -> void: _level_ups.append(l))
	var level: Node = LEVEL.instantiate()
	add_child(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(PlayerStats.active, "stats active in Level 1")
	var hud: Node = level.get_node("HUD")
	var label: Label = hud.get_node("LevelLabel") as Label
	_check(label != null and label.visible and label.text.begins_with("LV 1"), "HUD shows level and XP (%s)" % (label.text if label != null else "missing"))
	var expected: int = 0
	var goblins: Array[Node] = level.get_node("Goblins").get_children()
	for goblin: Node in goblins:
		expected += XpTable.xp_for_kill(int(goblin.get("enemy_level")), bool(goblin.get("is_boss")))
	for goblin: Node in goblins:
		goblin.call("take_damage", 99, (goblin as Node2D).global_position + Vector2(-10.0, 0.0))
		goblin.call("take_damage", 99, (goblin as Node2D).global_position)
	await get_tree().physics_frame
	var total: int = XpTable.total_xp_for_level(PlayerStats.character_level) + PlayerStats.xp
	_check(total == expected, "killing %d Level 1 goblins awards %d XP (got %d), none doubled" % [goblins.size(), expected, total])
	_check(PlayerStats.character_level == XpTable.level_for_total(expected), "level matches table (level %d)" % PlayerStats.character_level)
	_check(_level_ups.size() == PlayerStats.character_level - 1, "level-up signal fired once per level")
	_check(label.text.begins_with("LV %d" % PlayerStats.character_level), "HUD updated (%s)" % label.text)
	_check(PlayerStats.unspent_points == _level_ups.size() * 3, "3 unspent points per level")
	var fresh: Node2D = Node2D.new()
	fresh.name = "Rat1"
	add_child(fresh)
	var before: int = PlayerStats.xp + XpTable.total_xp_for_level(PlayerStats.character_level)
	_check(PlayerStats.award_kill(fresh) == 50, "node without fields defaults to a level-2 payout")
	_check(PlayerStats.award_kill(fresh) == 0, "same static enemy pays once")
	var after: int = PlayerStats.xp + XpTable.total_xp_for_level(PlayerStats.character_level)
	_check(after - before == 50, "only 50 XP added")
	remove_child(level)
	level.free()
	PlayerStats.reset()


func _regen() -> void:
	PlayerStats.reset()
	_check(PlayerStats.health_regen_interval() == 0.0, "no regen interval on Level 0")
	PlayerStats.enter_floor(1)
	var base: float = PlayerStats.health_regen_interval()
	PlayerStats.set_bonus("constitution", 5)
	_check(PlayerStats.health_regen_interval() < base, "more Constitution regenerates faster")
	PlayerStats.reset()
