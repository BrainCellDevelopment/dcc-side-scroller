extends RefCounted
## Data-driven Floor 1 achievement registry. Every entry is [title, description].
## The dictionary key is the HOOK ID: any script fires it with
## SystemVoice.fire("hook_id"). Counter hooks (e.g. "stomp_10") fire from
## SystemVoice.count("stomp"). All text is original (project rule), in the
## System voice: rude title, one mocking sentence, a little hidden sympathy.
## A few titles are ones the books use ("Boom!", "Boss Babe"); the sentences
## under them are fresh.

const FLOOR_1: Dictionary = {
	# Core loop (consolidated from older hooks)
	"boom": ["Boom!", "Several things exploded at once. The System would like you to know that the paperwork for that was never going to be fun."],
	"level_2": ["Number Go Up", "Level 2. The number is bigger and you are still very squishy, but it is a nice number."],
	"level_5": ["Mid-Level Management", "Level 5. You have the rank of someone who is allowed to attend meetings. Please do not."],
	"level_9": ["Almost Qualified", "Level 9. Floor 1 is nearly finished with you. Be proud, and also run."],
	# First times
	"first_blood": ["First Blood", "Your first kill. It was somebody's problem, now it is nobody's. Wash your hands."],
	"first_smush": ["Smush", "You landed on a living creature on purpose. It is as undignified as it sounds, and it worked."],
	"first_llama": ["Spit Happens", "You met a llama. It was not impressed. The feeling was close to mutual."],
	"first_bathroom": ["Gotta Go", "A silver toilet in a closet is the only room nobody is watching. Take a minute. You earned it."],
	"first_charm": ["Hard To Resist", "Something hostile decided you were fine. That has never once worked on a bouncer."],
	"first_box": ["Present Tense", "Your first loot box. Gifts are nice. The giver is the one doing the watching."],
	"first_safe_room": ["Four Walls, Zero Stabbing", "A safe room. Breathe. The kind gnome has already judged your posture."],
	"first_death": ["Skill Issue", "You died. The System noted it with warmth it will deny later."],
	"first_potion": ["Questionable Chemistry", "You drank something you found. Brave, and absolutely not advice."],
	"first_door": ["Door Number One", "A door opened for you. Enjoy the novelty, most things here open you."],
	# Counters
	"stomp_1": ["Boots On The Ground", "One stomp. The goblin's ankles disagree with your methods, and so do your knees."],
	"stomp_10": ["Mattress Tester", "Ten stomps. You are really committing to the bit."],
	"stomp_50": ["Foot Fetish Rumours", "Fifty stomps. The audience has questions. Please do not answer them."],
	"kill_10": ["Double Digits", "Ten kills. Somewhere a tiny accountant is updating a spreadsheet about you."],
	"kill_25": ["Local Pest Control", "Twenty-five kills. The neighborhood is quieter, and so are you."],
	"kill_50": ["Serial Hobby", "Fifty kills. You have stopped apologising, which the System finds both delightful and sad."],
	"kill_100": ["Triple Digits, Double Chin", "One hundred kills. Your stamina bar sends its regards."],
	"boss_kill_1": ["Boss Babe, Part One", "A boss, defeated. It had a title and a plan. You had a fist and no plan. Congratulations."],
	"boss_kill_2": ["Repeat Offender", "Another boss down. The bosses' union is drafting a complaint."],
	"boss_kill_3": ["Neighborhood Watch", "Three bosses. The neighborhood is yours, in the way a haunted house belongs to a cat."],
	"death_3": ["Frequent Flyer", "Three deaths. The respawn lounge has your coffee order on file."],
	"death_10": ["Part Of The Furniture", "Ten deaths. You and the floor are now on first-name terms."],
	# Beat hooks later issues fire
	"intro_survived": ["Orientation Complete", "You lived through the first lesson. Most of the planet did not get a lesson."],
	"llama_beat": ["Alpaca Your Things", "You handled the llama situation. It remains the most intimidating thing you have seen all day, which says a lot."],
	"bathroom_beat": ["Private Business", "You used the one place that is not televised. The System looked away. Mostly."],
	"workshop_found": ["Tinkerer's Pity", "You found the workshop. Somebody was proud of this room once."],
	"map_upgrade": ["Lost And Found", "A map upgrade. You now know where you are, which is worse in some ways."],
	"neighborhood_boss": ["Wait, I Beat That?", "A neighborhood boss, down. You may now feel exactly three seconds of pride."],
	"borough_boss": ["Boss Of The Block", "The Borough boss is done. The System is out of gentle insults and is improvising."],
	"collapse_survived": ["Door Closing, Mind The Gap", "The floor collapsed. You were not on it. A lot of people were."],
	"all_boxes_open": ["Unwrapped", "Every box opened. The audience is a little jealous, and the boxes are a little relieved."],
	"survivor_count_milestone": ["Counting Heads", "You watched the survivor counter drop. It is okay to look away. It is also okay to keep looking."],
}

## Announcement text pools. Each pool is cycled so a run does not repeat a line
## until it has used them all. Keep lines short and original.
const LEVEL_UP_LINES: Array[String] = [
	"Your stats got a raise. Your enemies did not get a vote.",
	"Look at you, improving. The audience has put down its snacks.",
	"More health, more problems, more kill, kill, kill.",
	"Congratulations. Nobody has ever thanked the stairs for this part.",
	"You are taller in spirit. Physically, no change.",
]

const BOSS_INTRO_LINES: Array[String] = [
	"A boss approaches. It looks fine with this. You may not be.",
	"Boss room sealed. The door is not shy about it.",
	"A challenger awaits. The System would like to remind you of the bet.",
]

const COLLAPSE_LINES: Dictionary = {
	86400: ["Time to Level Collapse: 24 hours.", "One day left. Finish what you came for. Or do not, and keep the souvenirs."],
	21600: ["Time to Level Collapse: 6 hours.", "Six hours. The dungeon is polite enough to tell you."],
	3600: ["Time to Level Collapse: 1 hour.", "One hour. The safe rooms have started closing their doors. Please be on the correct side."],
	600: ["Time to Level Collapse: 10 minutes.", "Ten minutes. Hold hands with the ones you can."],
}

const MANAGER_LINES: Array[String] = [
	"Good morning, survivors! It is 4:00 AM and we are so happy you are still here! Only %s of you left!",
	"Hi again, team! Quick headcount: %s remaining. Smiles, please. We can hear you.",
	"Rise and shine, humans! %s still standing. Remember to hydrate and not die!",
	"Gentle reminder from your friendly floor manager: %s of you are left. Clink, clink!",
]

const PATCH_NOTES: Array[String] = [
	"Patch 1.0.5. Stairs now exist. Stairs are still optional.",
	"Patch 1.0.6. Goblins nerfed. The goblins have lawyers and disagree.",
	"Patch 1.0.7. Reduced chance of feeling safe. Working as intended.",
]


static func entry(hook: String) -> Array:
	return FLOOR_1.get(hook, [])


static func ids() -> Array:
	return FLOOR_1.keys()
