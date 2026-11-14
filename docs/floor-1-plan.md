# Floor 1 plan (Level 1: the rest of Floor 1)

Book reference: [book-01-dungeon-crawler-carl.md](book-context/book-01-dungeon-crawler-carl.md) (sections 2, 5 and 6), [levels-and-looks.md](book-context/levels-and-looks.md), [world-and-system.md](book-context/world-and-system.md). This plan supersedes the Level 1 tasks in [level-1-plan.md](level-1-plan.md) (that doc still has the setup notes and conventions).

Tracking issue: #72 (epic). Every row below is a GitHub issue.

## What is already done
- **Level 0 (the tutorial)** covers the book's surface, entrance stairs, tunnels, the Goblin Engineer, the Murder Dozer chase and the Tutorial Guild with Mordecai and the first loot boxes (book timeline items 1 to 7 and the box opening).
- **Level 1 stub** exists (#8): walkable right-to-left room with an intro rock thrower and the Magic Missile ability (#42).
- Systems we can build on: swing-door gates with one-way rule (#9), safe zone and loot boxes, stamina/mana, stats first pass (#37), goblin grunt and thrower, projectile and targeting helpers, boss health bar, dev console, generator pipeline with a reachability lint.

## Scope: Level 1 = book timeline items 8 to 32
Everything from leaving the guild to descending the stairs and the Odette hand-off. Floor 2 is **not** in scope (a Level 2 stub is the end of this plan). Timer: Floor 1 is 5 days.

Pacing target (see #71): about 15 to 20 minutes first play, 2 to 3 minutes per neighborhood, 1 to 2 minutes per boss.

## Structure (runs right to left)

| # | Section | Book beat | Enemies / boss | Issue |
|---|---|---|---|---|
| 1 | Arterial and llama alleys | Leave the guild, Donut's missile wakes a Bad Llama | Bad Llama, magic missile practice | #57 |
| 2 | Rat maze and bathrooms | Rats, Scatterers, bathroom doors, Smush | Rat, Scatterer | #58, #56 |
| 3 | Safe room #1 (fast-food playground) | Tally, vindaloo, boxes | none | #59 |
| 4 | Hoarder neighborhood | Dynamite into a sealed room, garbage lair | The Hoarder (boss) | #60 |
| 5 | Goblin workshop | Shamankas, charm, workshop, chieftain's lair | Bomb Bard, Shamanka, Scat Thug (opt.) | #61 |
| 6 | Rot-sticker and slime neighborhood | Wall-crawlers, slimes | Rot Sticker, Slime | #62 |
| 7 | Safe room #2 (bus station) | Cookies, Desperado Pass | none | #63 |
| 8 | Frank Q and Maggie My | Killer crawlers, booby trap | Duo encounter | #64 |
| 9 | Meadow Lark camp | Elderly survivors, fortress parts | none (hub) | #65 |
| 10 | Gym neighborhood | Troglodytes, the Juicer | Troglodytes, The Juicer (boss) | #66 |
| 11 | Borough boss lair | Rave spiral, Ball of Swine, Tuskling mop-up | Ball of Swine (boss) | #67 |
| 12 | Stairwell and hand-off | Last cigarette, collapse beat, Odette | none | #68 |
| opt | Goblin Copper Chopper ride | Vehicle segment between 5 and 11 | none | #69 |

Order of the neighborhoods is a design choice; the book wanders around a grid, so the game linearizes it. The two safe rooms act as checkpoints between bosses.

## Systems issues

| Issue | System |
|---|---|
| #48 | Foundation: multi-section generator, checkpoints, dev `goto`, bot skeleton |
| #49 | Floor 1 art kit (brick tunnels, lichen, torch arteries) |
| #50 | Safe room kit (caretaker, perk, checkpoint, box spot) |
| #51 | Neighborhood boss framework (lock, VS card, boss bar, drop box) |
| #52 | Loot box rewards and item effects |
| #53 | XP, levels and stat points |
| #54 | Throwable dynamite and Explosives Handling |
| #55 | Donut's Charm and the Goblin Pass |
| #56 | Bathroom doors |
| #70 | System voice pass: achievements, announcements, survivor counter |
| #71 | Playthrough bot, balance and length target |

Related existing issues: #23 (difficulty modes), #31 (fonts), #32 (opening cutscene), #36/#38 (inventory), #37 (stats), #29 (rock throwers reuse the projectile system).

## Milestones (suggested build order)
1. **M1 Foundation.** #48, #49, #50, #51. Nothing playable beyond the stub, but everything else plugs in.
2. **M2 First neighborhoods and the first boss.** #52, #53, #54, #57, #58, #56, #59, #60. Playable to the Hoarder.
3. **M3 Goblins and charm.** #55, #61, optional #69.
4. **M4 Second half.** #62, #63, #64, #65, #66.
5. **M5 The boss and the exit.** #67, #68, then #70 and #71 run alongside every milestone and close out last.

Each milestone should leave `main` playable and keep the Level 0 bot, the guild flow test and the missile test passing.

## Enemy and boss table

| Name | Level | Neighborhood | New work |
|---|---|---|---|
| Bad Llama | 3 | llama alleys | ranged lava spit, throat weak point |
| Rat | 2-3 | rat maze | fast melee, janitor visuals |
| Scatterer | 2 | rat maze, Hoarder | swarm, stomp |
| The Hoarder (boss) | 7 | garbage lair | roach-vomit boss |
| Goblin Bomb Bard | 5 | workshop | bomb thrower |
| Goblin Shamanka | 7 | workshop | buffer, charmable |
| Rot Sticker | 1-2 | rot-sticker corridors | wall/ceiling, delayed burst |
| Slime | 2 | slime pits | slow blob, drains stamina |
| Frank Q and Maggie My | human | bus-station stretch | two-enemy encounter, trap |
| Troglodyte Pygmy / Basher / Virtuoso | 2/3/4 | gym | three lizard variants |
| The Juicer (boss) | 9 | gym | thrown plates, neck weak point |
| Ball of Swine (boss) | 15 | rave spiral | rolling hazard, wedge solution |
| Tuskling Knight / Courtesan / Dominatrix | 4/5/8 | rave spiral | mop-up wave |

Reuse: goblin grunt and thrower, Engineer arena flow, projectile and targeting helpers.

## Look and palette (Floor 1)
Dark brick red, green lichen glow, torch orange, bone white. Arteries are wide and torch-lit; mazes are low and lichen-lit. Each neighborhood adds an accent (garbage browns, steam and coal, gym mirrors, rave black-light purple). See #49.

## Adaptation decisions (so we do not argue about them per issue)
- **Tone.** Jokes in the System voice, real grief when it counts (the Hoarder, goblin babies, the collapse). Violence against children is never shown; the chieftain's lair blast is off-screen with System text carrying the weight (#61).
- **Linearized grid.** The book's open grid becomes a right-to-left line with side rooms; fog-of-war and the minimap are out of scope.
- **Frank Q and Maggie My** are not killed (they return later in the series).
- **Original text only.** Achievement and System lines are written fresh in the book's voice, not copied (#70).
- **Carl never gets pants.** Loot tables obey this (#52).
- **Chopper ride** is a stretch goal (#69) and must be skippable.

## Open decisions (need the owner)
1. Should Donut get her own spell variant, or share Magic Missile? (open in #42)
2. Does Carl gain the War Gauntlet melee upgrade from the Juicer in this level? (#66, #53)
3. Include Dexterity and Charisma stats? (open in #37)
4. Do we show the survivor counter permanently or only at story beats? (#70)
5. How many checkpoints per neighborhood vs the difficulty modes (#23)?
6. Is the Ball of Swine solved only by the Speedbump fortress, or are dynamite and lane tricks also valid? (#67)

## Definition of done for Level 1
- Every issue above closed or explicitly deferred.
- `tests/playthrough_level01.tscn` passes with 0 deaths; Level 0 bot, guild flow test and missile test still pass.
- Screenshots of every section at two resolutions reviewed.
- Human playtest within the pacing target and notes captured in this file.
