# Floor 2 plan (Level 2: "same, but nastier")

## Context
Level 1 (Floor 1) is built and ends with the collapse beat, the Odette yacht cabin and a hand-off to a **Level 2 stub** (`scripts/levels/level02.gd`: one flat code-drawn run, white floor, cinderblock, orange lichen, "To be continued"). Goal: replace the stub with a real Level 2 that mirrors Floor 2 of book 1 (timeline items 35 to 52 in `docs/book-context/book-01-dungeon-crawler-carl.md`, zones in `levels-and-looks.md` and the "Floor 2" list in the book doc), at the same size and polish as Level 1.

Decisions (confirmed): **trimmed 7-beat arc**, built with a **generator like Level 1** (`art-src/level/build_level02.py` -> `scenes/level02.tscn`), scrolling **left to right** (Level 1 is right to left; `levelkit.py` runs unmirrored when `mirror_w=None`).

Look: bone-white floors, grey cinderblock walls, orange lichen, cyan/light-blue Rev-Up flame accents; grub slime trails and gore. Timer: Floor 2 is 6 days (Level 1 uses `Game.FLOOR_TIME` = 5 days).

## Structure (left to right)

| # | Beat | Book beat | Enemies / boss | Level mechanic |
|---|---|---|---|---|
| 1 | Arrival + Brindle Grub corridors | Floor 2 begins; white floors, grubs, dingo patrols | Brindle Grub (Lv2, harmless, grows when it eats), Danger Dingo (Lv5, bites) | New palette; grubs eat corpses and grow: reuse `critter.gd` pattern; dingoes can be calmed with a pet biscuit (item) |
| 2 | Storm-shelter safe room | Concrete bunker, 50 cots, mailbox gives Donut **Second Chance** | none | Checkpoint + full heal, Mordecai (now a **Bugaboo**) so Hoarder/Swine-style boss boxes can be opened; mailbox = Donut spell unlock |
| 3 | Clurichaun / Rev-Up quadrant | Hillbilly clurichauns with slingshots and moonshine; Laminak fairies; filling room with a bathtub | Clurichaun (Lv3 slingshot), Laminak Elite (Lv6, charm target) | Ranged enemies (reuse thrower/projectile helpers); burn corpses; "Live, Laugh, Love" boss door |
| 4 | Boss: Krakaren Clone (Lv10) | Craft immunity smoothie, tentacles burst through cinderblock, survive under the indestructible table | Krakaren Clone | Boss framework (`boss_arena.gd`); smoothie pickup grants immunity to the Taint debuff; mucus/Taint disables healing |
| 5 | Grub storm | Corpses spawn janitor swarms; pupae mounds | Grub swarms | Optional set piece: time pressure, burn bodies with dynamite |
| 6 | Kobold quadrant + dog pound boss | Kobold Riders on dingoes; cages, thrash metal, pit-fighting ring | Kobold Rider (Lv5), **Ralph, Frenzied Gerbil** (Lv11) | Boss arena in a dog pound; befriend caged dingoes with biscuits, stun and stomp Ralph |
| 7 | Reward + stairwell hand-off | Mongo the pet reward room; stairwell ringed by pupae mounds | none | End of floor, hand-off to Level 3 stub (new `FloorHandoff` target) |

Cut / deferred (as Level 1 did): Mind Horror quadrant, Rage Elemental chase, Death Watch / Maestro set piece, Zev and Meadow Lark cameos. Record them in a `docs/floor-2-plan.md` like `floor-1-plan.md`.

## Approach (reuse, do not reinvent)
- **Level script + scene:** new `scripts/levels/level02.gd` modeled on `level01.gd` (sections via `Triggers` metadata, checkpoints, gates, `dev_goto`, `dev_sections`, collapse/hand-off). Keep the stub's public surface used by tests: `arrival` dict and `_capture_arrival()` (see `tests/floor_end_flow.gd`), and `Game.carried_health` handling.
- **Generator:** `art-src/level/build_level02.py` + `levelkit.py` (`start_section`, `add_plat`, `trig`, `cp`, `lint`) and per-beat `section_*.py` modules like `section_rats.py` / `section_hoarder.py`. Add the new scene paths to `EXISTING`/`RES` so the lint passes.
- **Art:** Floor 2 tile and background kit (white concrete, cinderblock, orange lichen) in `art-src/floor1`-style generators (`gen_tiles`, `gen_bg`, `palette.py`); `platform.gd` and `background.gd` gain a Floor 2 style. Mordecai Bugaboo sprite (`art-src/characters/mordecai.py` variant) for the safe room.
- **Boss framework:** `scripts/level/boss_arena.gd` (lock, VS card, boss bar, drop box) for Krakaren and Ralph; per-boss wiring script like `hoarder_lair.gd` / `swine_arena.gd`.
- **Safe room + Mordecai:** `scripts/level/safe_room.gd` and the greenroom pattern (`greenroom.gd`) for a storm-shelter room that is a safe zone, runs a Mordecai moment and lets boss boxes open.
- **Enemies:** new grub, dingo, clurichaun, laminak, kobold rider, Krakaren and Ralph scripts built from `critter.gd` / `goblin.gd` / `llama.gd` patterns (state enum, `take_damage`, `died`, `enemies` group, engaged counter). Projectiles via existing helpers.
- **Systems:** `loot_tables.gd` (Floor 2 kit), `xp_table.gd`, `achievements.gd` / `SystemVoice` lines (original text only), `floor_handoff.gd` (Level 3 stub target, Floor 2 timer), `dev_console.gd` `LEVELS`.

## Milestones (one PR each)
1. **M1 Foundation:** `build_level02.py` skeleton, Floor 2 tiles/backgrounds, level02 script with sections/checkpoints/gates/`goto`, replace the stub, keep the hand-off test passing.
2. **M2 First half:** grub corridors (beat 1) and storm-shelter safe room with Bugaboo Mordecai, Second Chance mailbox and boss-box opening (beat 2).
3. **M3 Clurichaun quadrant + Krakaren boss** (beats 3 and 4), smoothie/Taint mechanic.
4. **M4 Grub storm + dog pound boss Ralph** (beats 5 and 6), reward room.
5. **M5 End + polish:** stairwell hand-off, balance pass with a `playthrough_level02` bot, `docs/floor-2-plan.md`.

## Open items to settle during M1
- Whether Level 2 ends with an Odette interlude (another yacht-style scene) or goes straight to a Level 3 stub.
- Whether Second Chance (reanimate a foe) is implemented now or only unlocked as an item.
- Pet reward (Mongo) scope: story beat only, or a follower mechanic.

## Verification
- Generator: `python3 art-src/level/build_level02.py` prints `ERRORS: 0` (reachability lint); regenerated scene diffs are deterministic.
- Headless parse/tests: `godot --headless --path dcc-side-scroller res://tests/<test>.tscn` for each new beat (`level02_goto`, `grub_corridor`, `krakaren_fight`, `dogpound_fight`) plus the existing `floor_end_flow`, `swine_boss` and `playthrough_level01` still pass.
- `tests/playthrough_level02.tscn` bot plays start to end and prints PASS; check pacing and HP against a 10 to 15 minute target.
- Manual: run in Godot (and render screenshots as done for the greenroom) to review palette and set dressing; `goto <section>` in the dev console for each section.

## Status (after milestone 5)
- Built: all seven beats of the trimmed arc. Brindle Grub corridors and Danger Dingoes; storm shelter with Mordecai the Bugaboo and the Second Chance mailbox (flag only, no cast yet); Clurichaun quadrant with the Taint and the smoothie bench; Krakaren Clone; grub storm; kobold riders and Ralph at the dog pound; reward room (Mongo as a follower); stairwell end with the summary card and the hand-off to a Level 3 stub (`FloorHandoff.LEVEL3_SCENE`).
- Boxes: mobs and bosses report kills to `Game.report_mob_kill`; earned boxes are handed out in the storm shelter (and the Level 1 greenroom) like the fast-food room.
- Tests: `level02_goto`, `level02_arrival`, `krakaren_fight`, `ralph_fight`, `level02_flow` (scripted end to end, not a walking bot).
- Not built: a walking `playthrough_level02` bot and a balance pass (health, pacing and the 10 to 15 minute target are unmeasured); Laminak fairies and the "Live, Laugh, Love" boss door; burning corpses; befriending the caged dingoes with biscuits; casting Second Chance; Mind Horror quadrant, Rage Elemental chase and the Death Watch set piece (deferred); real art for the Krakaren, Ralph and the clurichaun (placeholders).
