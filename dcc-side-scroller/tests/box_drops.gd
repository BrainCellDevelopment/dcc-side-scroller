extends SceneTree

const DropRates: GDScript = preload("res://scripts/data/drop_rates.gd")

var _fails: int = 0


func _check(ok: bool, label: String) -> void:
	print(("ok   " if ok else "FAIL ") + label)
	if not ok:
		_fails += 1


func _initialize() -> void:
	await process_frame
	var Game: Node = root.get_node("Game")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 95
	var kills: int = 400000
	var counts: Dictionary = {"Bronze": 0, "Silver": 0, "Gold": 0, "Legendary": 0}
	var drops: int = 0
	for i: int in kills:
		var tier: String = DropRates.roll(0.0, rng)
		if not tier.is_empty():
			drops += 1
			counts[tier] += 1
	var box_rate: float = float(drops) / kills
	_check(absf(box_rate - DropRates.BOX_CHANCE) < 0.01, "box chance near %.2f (%.3f)" % [DropRates.BOX_CHANCE, box_rate])
	_check(counts["Bronze"] > counts["Silver"] and counts["Silver"] > counts["Gold"] and counts["Gold"] > counts["Legendary"], "bronze > silver > gold > legendary %s" % str(counts))
	var per_kill: float = float(counts["Legendary"]) / kills
	_check(counts["Legendary"] > 0 and per_kill < 0.0003, "legendary is about 0.009%% per kill (%.4f%% from %d)" % [per_kill * 100.0, counts["Legendary"]])
	var boss_legendary: int = 0
	for i: int in 20000:
		if DropRates.pick_tier(DropRates.BOSS_LEGENDARY_BONUS, rng) == "Legendary":
			boss_legendary += 1
	_check(boss_legendary > 60, "boss bonus raises legendary (%d / 20000)" % boss_legendary)
	Game.earned_boxes.clear()
	Game.grant_box("Silver")
	Game.grant_box("Bronze")
	Game.grant_box("Bronze")
	Game.grant_box("")
	var taken: Array[String] = Game.take_earned_boxes()
	_check(taken == ["Bronze", "Bronze", "Silver"], "take_earned_boxes returns tier order %s" % str(taken))
	_check(Game.take_earned_boxes().is_empty(), "boxes are gone once taken")
	Game.legendary_bonus = 6.0
	Game.grant_box("Legendary")
	_check(is_zero_approx(Game.legendary_bonus), "legendary drop resets boss bonus")
	Game.grant_box("Bronze")
	Game.reset_run()
	_check(not Game.earned_boxes.is_empty(), "reset_run (death) keeps earned boxes")
	Game.reset_boxes()
	_check(Game.take_earned_boxes().is_empty(), "reset_boxes clears earned boxes")
	var tut: Dictionary = {"Bronze": 0, "Silver": 0, "Gold": 0, "Legendary": 0}
	for i: int in 100000:
		var t: String = DropRates.roll(0.0, rng, true)
		if not t.is_empty():
			tut[t] += 1
	_check(tut["Gold"] == 0 and tut["Legendary"] == 0 and tut["Bronze"] > tut["Silver"] and tut["Silver"] > 0, "tutorial rolls are Bronze/Silver only %s" % str(tut))
	print("RESULT " + ("PASS" if _fails == 0 else "FAIL"))
	quit(_fails)
