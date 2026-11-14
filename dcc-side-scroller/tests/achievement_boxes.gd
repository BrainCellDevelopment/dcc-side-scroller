extends SceneTree

const AchievementBoxes: GDScript = preload("res://scripts/data/achievement_boxes.gd")
const LEVEL_0_IDS: PackedStringArray = ["welcome", "first_goblin", "first_hurt", "mind_gap", "stairs", "engineer_down", "dozer_stomp", "pest_control"]

var _fails: int = 0


func _check(ok: bool, label: String) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1


func _initialize() -> void:
	await process_frame
	var game: Node = root.get_node("Game")
	var bronze: int = 0
	var silver: int = 0
	for id: String in LEVEL_0_IDS:
		match AchievementBoxes.tier_for(id):
			"Bronze":
				bronze += 1
			"Silver":
				silver += 1
	_check(bronze == 5 and silver == 3, "Level 0 has 5 Bronze and 3 Silver achievement boxes (8, plus 2 starters = 10)")
	var rare: int = 0
	for id: String in AchievementBoxes.BOXES:
		if AchievementBoxes.tier_for(id) == "Legendary":
			rare += 1
	_check(rare == 0, "no achievement hands out a Legendary box")
	game.reset_boxes()
	game.unlock_achievement("welcome", "Still Breathing", "x")
	_check(int(game.earned_boxes.get("Bronze", 0)) == 1, "unlocking a listed achievement earns its box")
	game.unlock_achievement("welcome", "Still Breathing", "x")
	_check(int(game.earned_boxes.get("Bronze", 0)) == 1, "the same achievement never pays twice")
	game.unlock_achievement("dozer_down", "Warranty Void", "x")
	_check(int(game.earned_boxes.get("Bronze", 0)) == 1 and game.earned_boxes.size() == 1, "an unlisted achievement gives no box")
	game.unlock_achievement("engineer_down", "Performance Review", "x")
	var order: Array[String] = game.take_earned_boxes()
	_check(order == ["Bronze", "Silver"], "take_earned_boxes returns tier order %s" % str(order))
	_check(game.take_earned_boxes().is_empty(), "boxes are gone once taken")
	game.grant_box("Silver")
	game.reset_run()
	_check(not game.earned_boxes.is_empty(), "reset_run (death) keeps earned boxes")
	game.reset_boxes()
	_check(game.take_earned_boxes().is_empty(), "reset_boxes clears earned boxes")
	print("RESULT " + ("PASS" if _fails == 0 else "FAIL"))
	quit(_fails)
