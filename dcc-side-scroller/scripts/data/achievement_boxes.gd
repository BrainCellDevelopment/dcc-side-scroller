extends RefCounted
## Which achievements hand out a loot box, and of what tier (#109). Unlocking the
## achievement earns the box once; the box waits until Carl reaches a safe room.
## Level 0 has the two fixed starter boxes plus the eight here, ten in total.
## Anything not listed gives no box.

const BOXES: Dictionary = {
	# Level 0
	"welcome": "Bronze",
	"first_goblin": "Bronze",
	"first_hurt": "Bronze",
	"mind_gap": "Bronze",
	"stairs": "Bronze",
	"engineer_down": "Silver",
	"dozer_stomp": "Silver",
	"pest_control": "Silver",
	# Floor 1
	"first_blood": "Bronze",
	"first_smush": "Bronze",
	"first_llama": "Bronze",
	"first_bathroom": "Bronze",
	"first_charm": "Bronze",
	"first_potion": "Bronze",
	"first_safe_room": "Bronze",
	"intro_survived": "Bronze",
	"stomp_10": "Bronze",
	"kill_25": "Bronze",
	"level_2": "Bronze",
	"bathroom_beat": "Bronze",
	"workshop_found": "Bronze",
	"llama_beat": "Silver",
	"boom": "Silver",
	"stomp_50": "Silver",
	"kill_50": "Silver",
	"level_5": "Silver",
	"neighborhood_boss": "Silver",
	"kill_100": "Gold",
	"level_9": "Gold",
	"borough_boss": "Gold",
}


static func tier_for(achievement_id: String) -> String:
	return str(BOXES.get(achievement_id, ""))
