# Floor 1 plan (Level 1: the rest of Floor 1)

Book reference: [book-01-dungeon-crawler-carl.md](book-context/book-01-dungeon-crawler-carl.md) (sections 2, 5 and 6), [levels-and-looks.md](book-context/levels-and-looks.md), [world-and-system.md](book-context/world-and-system.md). This plan supersedes the Level 1 tasks in [level-1-plan.md](level-1-plan.md) (that doc still has the setup notes and conventions).

Tracking issue: #72 (epic). Every row below is a GitHub issue. The scope was trimmed to seven beats after a check against the book; cut items are closed with the `deferred` label.

## What is already done
- **Level 0 (the tutorial)** covers the book's surface, entrance stairs, tunnels, the Goblin Engineer, the Murder Dozer chase and the Tutorial Guild with Mordecai and the first loot boxes (book timeline items 1 to 7 and the box opening).
- **Level 1 stub** exists (#8): walkable right-to-left room with an intro rock thrower and the Magic Missile ability (#42).
- Systems we can build on: swing-door gates with one-way rule (#9), safe zone and loot boxes, stamina/mana, stats first pass (#37), goblin grunt and thrower, projectile and targeting helpers, boss health bar, dev console, generator pipeline with a reachability lint.

## Scope: Level 1 = the book's Floor 1 beats, trimmed to seven
Source: book 1 timeline items 12 to 15 and 25 to 32. Floor 2 is **not** in scope (a Level 2 stub is the end of this plan). Timer: Floor 1 is 5 days. There is no "rat maze" in the book: after the guild, Carl fights rats and Scatterers in ordinary corridors; the only real maze on Floor 1 is the spiral Borough Boss arena at the end.

Pacing target (see #71): about 10 to 15 minutes first play with the trimmed scope, bosses 1 to 2 minutes each.

## Structure (runs right to left)

| # | Beat | Book beat | Enemies / boss | Issues |
|---|---|---|---|---|
| 1 | Arterial tunnel and llama alley | Leave the guild, Donut's missile wakes a Bad Llama, throat punch | Bad Llama, magic missile practice | #57 |
| 2 | Rats and Scatterers corridor | Five level-2 rats, Scatterers, bathroom doors, Smush | Rat, Scatterer (optional rot-sticker and slime variants) | #58, #56 |
| 3 | Safe room: fast-food playground | Tally cooks, boxes, the only checkpoint room | none | #59 |
| 4 | Mid-boss: the Hoarder | Dynamite opens a sealed room, garbage-troll lair | The Hoarder | #60 |
| 5 | Goblin workshop (optional set piece) | Steam engine, parked dozers, charm | Bomb Bard, Shamanka | #61 |
| 6 | Final boss: Ball of Swine | Spiral rave dome, Tuskling mop-up, stairwell opens | Ball of Swine, Tuskling | #67 |
| 7 | Collapse beat and hand-off | Stairs, interview, Level 2 stub | none | #68 |
| opt | Goblin Copper Chopper ride | Stretch, skippable | none | #69 |

## Systems issues

| Issue | System |
|---|---|
| #48 | Foundation: multi-section generator, checkpoints, dev `goto`, bot skeleton |
| #49 | Floor 1 art kit (brick tunnels, lichen, torch arteries) |
| #50 | Safe room kit (caretaker, perk, checkpoint, box spot) |
| #51 | Boss framework (lock, VS card, boss bar, drop box) |
| #52 | Loot box rewards and item effects |
| #53 | XP, levels and stat points |
| #54 | Throwable dynamite and Explosives Handling |
| #55 | Donut's Charm and the Goblin Pass (for the optional workshop) |
| #56 | Bathroom doors |
| #70 | System voice pass: achievements, announcements, survivor counter |
| #71 | Playthrough bot, balance and length target |

Related existing issues: #23 (difficulty modes), #31 (fonts), #32 (opening cutscene), #36/#38 (inventory), #37 (stats), #29 (rock throwers reuse the projectile system).

## Cut or deferred (closed with the `deferred` label)
| Issue | Cut item | Why |
|---|---|---|
| #62 | Rot-sticker and slime area | Become enemy variants in the rats corridor (#58) |
| #63 | Bus-station safe room | Duplicates the fast-food room; one safe room only |
| #64 | Frank Q and Maggie My | A story thread, better as a short cutscene or later cameo |
| #65 | Meadow Lark camp | Fits an NPC scene at the boss arena, or later |
| #66 | Gym and the Juicer | A second boss; Hoarder plus Ball of Swine is enough |

## Milestones (suggested build order)
1. **M1 Foundation.** #48, #49, #50, #51.
2. **M2 First half.** #52, #53, #54, #56, #57, #58, #59, #60. Playable to the Hoarder.
3. **M3 The boss and the exit.** #67, #68. Then, if time allows, #55 and #61, and #69 as a stretch.
4. **Alongside everything.** #70 and #71.

Each milestone should leave `main` playable and keep the Level 0 bot, the guild flow test and the missile test passing.

## Enemy and boss table

| Name | Level | Beat | New work |
|---|---|---|---|
| Bad Llama | 3 | 1 | ranged lava spit, throat weak point |
| Rat | 2 | 2 | group of five, burst on death |
| Scatterer | 2 | 2, 4 | swarm, stomp |
| The Hoarder (boss) | 7 | 4 | roach-vomit boss |
| Goblin Bomb Bard / Shamanka (optional) | 5 / 7 | 5 | bomb thrower, charmable buffer |
| Ball of Swine (boss) | 15 | 6 | rolling hazard, wedge solution |
| Tuskling Knight / Courtesan / Dominatrix | 4/5/8 | 6 | mop-up wave |

Reuse: goblin grunt and thrower, Engineer arena flow, projectile and targeting helpers.

## Look and palette (Floor 1)
Dark brick red, green lichen glow, torch orange, bone white. Arteries are wide and torch-lit; corridors are low and lichen-lit. Accents: garbage browns for the Hoarder, steam and coal for the workshop, rave black-light purple for the boss dome. See #49.

### Palette sheet (source of truth: `art-src/floor1/palette.py`, image: `docs/reference/floor1/palette.png`)
Ramps are dark to light. Use these for every new Floor 1 asset so neighborhoods stay consistent.

| Family | Ramp |
|---|---|
| Brick red | `#1a0a10` `#2e1218` `#4a1c20` `#6b2b2a` `#8f4034` `#b85c42` |
| Lichen green | `#0e2620` `#1c523a` `#3a9448` `#86dc68` `#c8f5a0` (glow `#46b868`) |
| Torch orange | `#6e1f1c` `#c8481e` `#f5882a` `#ffc45a` `#fff0b0` |
| Bone white | `#4a3838` `#8a7866` `#c8b692` `#eee2c0` `#fffaf0` |
| Wet stone | `#141c20` `#22323a` `#3a5256` `#5f8280` `#9ac0b8` |
| Plank | `#1e120e` `#3a2218` `#5a3622` `#80502e` `#aa7640` |
| Iron | `#161218` `#2e2a36` `#4e4a5c` `#7c7888` `#aeaab8` |
| Outline | `#0c0508` |

Neighborhood accents sit on top of the ramps above and never replace them: garbage (Hoarder) `#3a2c1a` `#5e4a28` `#8a7440`; workshop steam and coal `#1c1a1c` `#6a6e74` `#d8dce0`; rave dome black light `#1a0a3a` `#6a2ad0` `#d070ff`.

Kit and usage: see "Floor 1 art kit (#49)" in [contract-art.md](contract-art.md). Screenshots at 1280x720 and 960x540 are in `docs/reference/floor1/`. Pick a background with `Background.set_style(4)` (tunnel), `5` (artery) or `6` (corridor); platforms use `style` 4 to 6.

## Pacing and economy (#71, measured by the bot)

`tests/playthrough_level01.tscn` plays the whole level with the health the game gives it (10 HP), no cheats: it opens the safe-room boxes with E, wears gear, eats cookies, drinks a healing potion when it is at 4 HP or less, throws dynamite at the sealed door, builds the Speedbump fortress against the Ball of Swine, and walks the hand-off. It prints a per-section report (seconds, real damage taken, healing by source, deaths, health in/out and lowest) and PASS or FAIL. Run it from `dcc-side-scroller/`: `godot --headless --fixed-fps 60 res://tests/playthrough_level01.tscn` (about 5 real seconds). Set `DCC_SHOT_DIR` and run without `--headless` for one screenshot per section (`0_tunnel.png` and so on). `DCC_START=<section>` starts mid-level, `DCC_BOT_HEALTH=<n>` overrides starting health (debug only), `DCC_BOT_LOOT=none` empties the bag of healing potions after the safe room (the unlucky-roll measurement below).

### Section times (default run, bot seconds)

| # | Section | Bot time | Real damage taken | Notes |
|---|---|---|---|---|
| 1 | Arterial and llama alleys | 18 s | 4 | two llamas, magic missile practice |
| 2 | Rats and Scatterers corridor | 8 s | 0 | |
| 3 | Safe room (fast food) | 9 s | 0 | healed 4 on entry, boxes opened |
| 4 | The Hoarder | 56 to 57 s | 7 to 8 | boss; dynamite door included |
| 5 | Goblin workshop | 8 s | 1 to 2 | optional, the bot does not use the Pass or charm |
| 6 | Ball of Swine | 38 to 39 s | 5 to 6 | boss |
| 7 | Collapse and hand-off | 11 s + 35 s | 0 | the 35 s is the cabin text the bot clicks through |
| | **Total** | **about 185 s** | **18 to 22** | 0 deaths in 8 of 8 runs |

Bot-to-human assumption: walking and small fights take a first-time player 3 to 5 times as long (reading, looking, mistimed jumps); boss fights are paced by the boss timers, so 1.5 to 2 times; the hand-off text 1.5 to 2.5 times. That gives **about 6 to 10 minutes** for a first playthrough, bosses at about 1.5 to 2 minutes each. Bosses hit the target; the level as a whole is **under the 10 to 15 minute target**, and a death at either boss adds about 1.5 minutes per retry. Human playtest notes: not captured yet (needs a person).

### Health, mana and stamina economy
- **Health is the only scarce resource.** Base max health is 10 (2 per Constitution point). Level-ups grant stat points, but they stay locked until Floor 3 (`CLASS_SELECT_FLOOR`), so the bot ends at level 8 or 9 with 10 max HP. Natural regeneration is one HP per 60 s at Constitution 5. A healing potion restores 6. The Hoarder costs about 7 to 8 HP, the Ball of Swine 5 to 8, the llamas 4, the workshop 1 to 6.
- **Healing sources actually reachable:** the safe room (full heal on entry and the checkpoint), potions from its boxes, and the stairs at the end. Boss boxes (Hoarder, Swine) hold only gear and open only in a safe zone. The next one after the Hoarder is on Floor 2, and the section gates are one-way ("Locked. No way back."), so the bot confirmed the Hoarder box cannot be carried back to the fast-food room. It follows the player unopened ("Safe zones only") for the rest of the level.
- **Tuning made (#71):** the fast-food room used the random Floor 1 table, so its Bronze box gave 2 healing potions only 1 time in 4 and the bot died once in about 7 of 8 runs. It now uses a `floor1_room` kit (`loot_tables.gd`): Bronze is always 2 healing potions, Silver is a cookie or a mana toast. Result: 0 deaths in 8 of 8 runs.
- **Without the potions** (`DCC_BOT_LOOT=none`, an unlucky box on the old table): the bot reaches the workshop with 2 to 3 HP, then dies once (workshop or Ball of Swine) in 6 of 6 runs. Respawning at a checkpoint restores full health, so such a player can still finish, but only by dying once. HP on first arrival at the swine arena: 2 to 3 of 10 with no potions, 7 to 8 of 10 with the room's two potions (one potion is spent in the Hoarder fight, one after).
- **Mana:** the player pool is 10 with 1.5 per second regeneration after 1 s; Magic Missile costs 3, so mana only limits spam. Mana potions (5) and toast (full) are surplus on this level. **Stamina:** 100, attacks cost 12, jumps 10, regenerates 40 per second after 0.5 s; never binding in the bot runs. **Cookies:** 60 XP each, which only raises the level counter on Floor 1 (points are locked).

### Difficulty hook point (#23)
Not built. When #23 lands, the knobs to scale per mode are: `max_health` (40), `charge_damage` (2), `stomp_damage` (1), `VOMIT_SPAWN` and `SPAWN_CAP` in `scripts/enemies/hoarder.gd`; the Ball of Swine health and dynamite count; enemy counts in `art-src/level/section_*.py`; the `floor1_room` kit and potion counts in `scripts/data/loot_tables.gd`; and checkpoint spacing (`kit.cp(...)` in the section builders). Start from the bot's per-section report to retune.

### Issues found that a first-time player will feel
- Nothing heals between the Hoarder (section 4) and the Ball of Swine; the only safe room is before the Hoarder. See the PR for options.
- Two llamas instead of three (XP plan assumed three).
- No item grants the Desperado Pass flag yet (the Level 2 stub shows `pass false`).
- The Hoarder's Boss box cannot be opened (the safe room is behind a one-way gate), so its gear (up to Nightgaunt Cloak, +4 Constitution, +8 HP) is never obtained; same for the Swine box.
- Stat points are unspendable on Floor 1, so XP and the XP cookie have no mechanical effect here.
- Death clears the inventory (`Game.reset_run`), so a retry at a boss starts without potions.

## Adaptation decisions
- **Tone.** Jokes in the System voice, real grief when it counts (the Hoarder, the collapse). The goblin chieftain's lair and the baby-bombing scene are skipped entirely (#61).
- **Linear level.** The book's open grid becomes a right-to-left line; fog of war and the minimap are out of scope.
- **Original text only.** Achievement and System lines are written fresh in the book's voice (#70).
- **Carl never gets pants.** Loot tables obey this (#52).
- **Chopper ride** is a stretch goal (#69) and must be skippable.

## Open decisions (need the owner)
1. Should Donut get her own spell variant, or share Magic Missile? (open in #42)
2. Include Dexterity and Charisma stats? (open in #37)
3. ~~Is the Ball of Swine solved only by the Speedbump fortress?~~ Resolved in #67: no. Fortress (wedge it, melee counts double while wedged) and dynamite (3 per blast, 9 health) are both valid; the arena holds 4 sticks and the fortress is rebuildable after it breaks.
4. Survivor counter: always visible, or only at story beats? (#70)
5. Checkpoint density against the difficulty modes (#23).

## Definition of done for Level 1
- Every issue above closed or explicitly deferred.
- `tests/playthrough_level01.tscn` passes with 0 deaths; Level 0 bot, guild flow test and missile test still pass.
- Screenshots of every beat at two resolutions reviewed.
- Human playtest within the pacing target and notes captured in this file.
