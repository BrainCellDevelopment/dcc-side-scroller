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

## Adaptation decisions
- **Tone.** Jokes in the System voice, real grief when it counts (the Hoarder, the collapse). The goblin chieftain's lair and the baby-bombing scene are skipped entirely (#61).
- **Linear level.** The book's open grid becomes a right-to-left line; fog of war and the minimap are out of scope.
- **Original text only.** Achievement and System lines are written fresh in the book's voice (#70).
- **Carl never gets pants.** Loot tables obey this (#52).
- **Chopper ride** is a stretch goal (#69) and must be skippable.

## Open decisions (need the owner)
1. Should Donut get her own spell variant, or share Magic Missile? (open in #42)
2. Include Dexterity and Charisma stats? (open in #37)
3. Is the Ball of Swine solved only by the Speedbump fortress, or are dynamite and lane tricks also valid? (#67)
4. Survivor counter: always visible, or only at story beats? (#70)
5. Checkpoint density against the difficulty modes (#23).

## Definition of done for Level 1
- Every issue above closed or explicitly deferred.
- `tests/playthrough_level01.tscn` passes with 0 deaths; Level 0 bot, guild flow test and missile test still pass.
- Screenshots of every beat at two resolutions reviewed.
- Human playtest within the pacing target and notes captured in this file.
