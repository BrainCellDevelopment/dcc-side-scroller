# DCC Side Scroller: art and level rework contract (Level 0, round 2)

Read /home/claude/dcc/CONTRACT.md first: its code rules, .tscn rules, collision layers, groups, damage interface and input actions all still apply. The existing project is in /home/claude/dcc/project/ (that folder maps to `res://`). Write ONLY the files you own, into that same tree. You cannot run Godot here, so be exact: the files are loaded in Godot 4.7.2 afterwards and must parse with zero errors.

Goals: (1) the art must stop looking like blocky rectangles and look like real pixel art in the spirit of Mega Man (clean outlines, readable silhouettes, flat 3-tone shading) crossed with Metal Slug (richer detail on backgrounds, props and bosses), super-deformed chibi characters; (2) Level 0 becomes a 5 to 8 minute level for a first-time player instead of 30 seconds.

## Pixel art pipeline (everyone who makes art)
- No downloads, no external assets. Write Python (PIL and numpy are installed; `python3 -I` for scripts reading untrusted data is not needed here) that draws every sprite from palette-indexed ASCII grids and/or PIL primitives and saves PNGs. Keep generator scripts in /home/claude/dcc/art-src/<yourname>/ (they ship in the repo so art can be regenerated and edited). Generated PNGs go under the project's `assets/` folder as listed in your ownership table.
- Look at your work. After generating, upscale each sheet 6x with nearest-neighbour into /tmp/preview_<name>.png and open it with the Read tool, check every animation frame, fix what looks wrong, and repeat at least twice. Judge it honestly against: would this pass as a cheerful 16-bit arcade sprite? If it looks like coloured boxes, redo it.
- Style rules: base screen 640x360, nearest filtering (already set project-wide). Every sprite has a 1 px dark outline in a hue-shifted very dark colour (not pure black, for example #1b1226), 3 to 4 tone ramps per material with hue shifting (shadows lean cool and purple, highlights lean warm), at most about 20 colours per sheet, a clear 1 to 2 px specular or rim highlight on the lit side (top left), no anti-aliasing, no blur, no gradients except deliberate 1 px dithering. Chibi proportions for characters: head about 40 to 45 percent of the height, big readable eyes, short limbs, exaggerated hands. Transparent background (alpha 0 or 255 only).
- Frames are drawn facing right. All characters flip by setting `Visual.scale.x` to -1 (existing behaviour).
- Sheets are row-based: one animation per row, frames left to right, uniform frame size, unused cells transparent. Pixels are pixel-aligned: the character's feet touch the bottom row of the frame, horizontally centred, so the node origin (feet) is bottom-centre of the frame.
- Original designs only. Characters are loosely inspired by the Dungeon Crawler Carl books (Carl is a regular guy in his boxers; Donut is a fluffy white Persian cat; goblins are scrappy green dungeon grunts), but do not reproduce any existing artwork, cover art or official designs.

## Shared code helper (already written, do not edit)
`res://scripts/util/sprite_util.gd` (extends RefCounted, static funcs; do not `class_name` it, load it with `const SpriteUtil: GDScript = preload("res://scripts/util/sprite_util.gd")`):
- `SpriteUtil.build_frames(texture: Texture2D, frame_size: Vector2i, animations: Dictionary) -> SpriteFrames`
- `SpriteUtil.make_sprite(texture: Texture2D, frame_size: Vector2i, animations: Dictionary) -> AnimatedSprite2D` (centered=false, offset puts the origin at the bottom-centre of the frame)
- `animations` format: `{"idle": {"row": 0, "count": 4, "fps": 5.0, "loop": true}, ...}`. Sprites are created in code in `_ready()` with `make_sprite(preload("res://assets/.../x.png"), FRAME, ANIMS)` and added under `Visual`; scenes contain no art ColorRects any more (remove the old ColorRect art nodes). Keep node names used by scripts. Put each sheet's ANIMS and FRAME constants at the top of the script that uses it, matching the sheet specs below exactly.

## Sheet specs (character sheets, owner Agent A)
Frame size and row order are fixed; counts are per row. Rows not listed do not exist.
| File | Frame | Rows (name: frames @fps, loop?) |
|---|---|---|
| `assets/characters/carl.png` | 48x40 | idle 4 @5 loop; run 6 @12 loop; jump 1 @1; fall 1 @1; punch 4 @22 once; hurt 1 @1; die 4 @8 once |
| `assets/characters/donut.png` | 48x40 | same rows and counts as carl; Donut the cat alone (no Carl) drawn exactly where she sits on his shoulder in the matching carl frame, so layering the two sheets frame for frame looks like one animated duo; she may blink, swish her tail, brace during run, flatten ears when hurt |
| `assets/characters/goblin.png` | 32x32 | idle 4 @5 loop; walk 6 @10 loop; windup 2 @6 once; attack 3 @16 once; hurt 1 @1; die 4 @10 once |
| `assets/characters/goblin_thrower.png` | 32x32 | same rows as goblin; the thrower carries a sack and rocks (windup is an overhead wind-up with a rock, attack is the throw follow-through); visibly different silhouette and palette from the grunt |
| `assets/characters/engineer.png` | 40x40 | idle 4 @5 loop; walk 6 @10 loop; windup 3 @8 once; dash 2 @14 loop; crouch 2 @10 once; air 1 @1; recover 2 @4 loop; hurt 1 @1; defeated 3 @6 once |
| `assets/characters/rock.png` | 8x8 | spin 4 @14 loop |

Carl: shirtless chibi guy, boxers with a small heart, bare feet or simple shoes, scruffy hair, determined face; his fist punch must read clearly (frames: wind back, snap forward with a big fist and a squash, extended, recover). Goblin grunt: green, pointy ears, big nose, ragged loincloth, small club with a pineapple on the end; the club is part of the goblin art, not Carl's. Engineer: bigger goblin with a pot as a helmet, goggles, a tool belt and a curved knife; angrier look.

## Hitboxes and scene structure stay as they are
Do not change existing CollisionShape2D sizes or the AttackArea shapes and positions; only the art changes. The root nodes, signal names and public functions stay as in CONTRACT.md. Each character scene's `Visual` node (Node2D, flips with scale.x) holds the AnimatedSprite2D nodes: player: `Visual/Body` and `Visual/Donut` (Donut above Body, always set to the same animation and frame as Body); goblin and engineer: `Visual/Sprite`. Animation hookup (idle, run, jump, fall, punch, hurt, die, windup, attack, and so on) is driven from each owner's script state machine. Sprite flashing on hit uses `Visual.modulate`.

## New and changed APIs (exact)

### Game autoload (`scripts/autoload/game.gd`, edited by Agent D only; others only call these)
```
signal screen_shake(strength: float, duration: float)
func shake(strength: float, duration: float) -> void          # emits screen_shake
var checkpoint_index: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_stage: int = 0
func set_checkpoint(index: int, pos: Vector2, stage: int = 0) -> void   # only replaces an equal-or-later index
func clear_checkpoint() -> void
```
`reset_run()` keeps the checkpoint (a death reload resumes there).

### Player (Agent A)
Adds `func kill() -> void` (instant death regardless of invulnerability, emits `died` once) and spawns fx on punch hit, landing and hurt (see fx). Calls `Game.shake(2.0, 0.12)` when it takes damage. Existing API unchanged.

### Goblin (Agent A)
Adds `@export_enum("Grunt", "Thrower") var variant: int = 0`. Grunt = existing behaviour. Thrower: keeps its distance (steps away when the player is closer than 70 px, never walks off ledges), and when the player is within 230 px horizontally and 90 px vertically it winds up (0.5 s telegraph) and throws a rock every 2.2 s; rock = `res://scenes/enemies/rock.tscn` (Area2D, `collision_layer = 0`, `collision_mask = 3` so it hits the player (layer 2) and world (layer 1); gravity arc aimed at the player's position; 1 damage via `take_damage`; frees itself on world hit, player hit, or after 4 s; spins). Thrower health 2, speed 40. Both variants use `Game.enemy_engaged()/enemy_disengaged()` exactly as before.

### Engineer (Agent A)
Adds `func set_pose(pose: String) -> void` (plays the named animation, `"walk"`, `"air"`, `"idle"`, `"defeated"` and so on, and holds it; used by the level while it tweens him into the dozer). Everything else unchanged, `max_health` stays exported (the level may raise it).

### Dozer (Agent E2)
Visual rebuild plus a new vulnerability cycle; keep these exactly: `start(player: CharacterBody2D, start_scroll_x: float)`, `set_driver(present: bool)`, `signal round_cleared(round_number: int)`, `signal destroyed`, `var scroll_x: float`, `var state`, `@export var max_scroll_x`, `@export var contact_damage`, node `Dozer` is an AnimatableBody2D. New: `signal vulnerable_changed(is_vulnerable: bool)` and `var vulnerable: bool`. New rule: the deck can only be damaged while `vulnerable` is true (a boiler hatch on top glows and vents steam). The dozer must survive `LUNGES[round_index]` lunge cycles (LUNGES = [2, 3, 4]) before the hatch opens for a window (HATCH_TIMES = [4.5, 4.0, 3.5] seconds); if the window runs out unstomped the hatch closes and the lunge counter restarts. A stomp while the hatch is closed gives the player a harmless small bounce and a spark. A stomp while open clears the round (existing behaviour: boss bar 3, 2, 1, 0, round_cleared, stall, final round explodes, destroyed). Expected round length 15, 22 and 30 seconds, scroll speeds 60, 80, 100. Explosion calls `Game.shake(6.0, 0.6)`.

### New terrain kit (Agent E1), all under `scenes/level/` with scripts in `scripts/level/`
All are `@tool` where noted so Lukas can see them in the editor; guard runtime-only code with `if Engine.is_editor_hint(): return`.
- `platform.tscn`: StaticBody2D, `collision_layer = 1`, `collision_mask = 0`, group `"platforms"`, origin at the TOP-LEFT corner. `@tool` script `platform.gd`: `@export var size: Vector2 = Vector2(64, 16)` (multiples of 16), `@export_enum("Rubble", "Iron", "Stone", "Wood") var style: int = 2`, `@export var one_way: bool = false`. Draws itself in `_draw()` from 16x16 tiles (`assets/tiles/tiles_rubble.png`, `tiles_iron.png`, `tiles_stone.png`, `tiles_wood.png`, each a 64x16 strip: cap, fill A, fill B, left/right edge shade): a cap row on top, fill below with deterministic variation, edge shading, an underside shadow, and for style Iron a grated look; it creates its CollisionShape2D (RectangleShape2D `size`) in `_ready()`.
- `spikes.tscn`: Area2D, group `"hazards"`, `collision_layer = 0`, `collision_mask = 2`, origin at the BOTTOM-LEFT of the strip. `@tool` `spikes.gd`: `@export var width: float = 32.0` (multiple of 16), `@export var damage: int = 2`; hurts the player (`take_damage(damage, global_position + Vector2(width * 0.5, 0))`) on entry and keeps hurting every 0.6 s while the player stays inside; hitbox is only the top 10 px of the 16 px tall spikes; metallic spikes with a dark base.
- `kill_zone.tscn`: Area2D, group `"kill_zones"`, mask 6 (player and enemy bodies), origin TOP-LEFT. `kill_zone.gd`: `@export var size: Vector2 = Vector2(256, 64)`; a body that has `kill()` gets `kill()` called; any other enemy body is `queue_free()`d. Invisible in game, drawn as a faint red rectangle in the editor only.
- `checkpoint.tscn`: Area2D, group `"checkpoints"`, mask 2, origin at the ground, centre. `checkpoint.gd`: `@export var index: int = 0`, `@export var stage: int = 0`, `signal activated(index: int)`; on the player entering and `index > Game.checkpoint_index`: `Game.set_checkpoint(index, global_position, stage)`, light up (animated lantern flame, brief burst fx), emit `activated`. A checkpoint whose index is already <= the stored one starts lit. Art: a small iron lantern post with an unlit and a lit animated state (`assets/props/checkpoint.png`, frame 24x40, rows: off 1, lit 4 @8 loop).
- `background.tscn`: CanvasLayer `layer = -10`, script `background.gd`: `func set_style(style_index: int, fade_time: float = 0.8) -> void`; styles: 0 = ruined street at night (burning skyline silhouettes, crater, smoke, red glow, stars), 1 = iron stairwell descent (huge dark hall with rails, arches, warm lamp glow, depth), 2 = tunnel (stone corridor, arches, shadowy side passages, torch glow, green lichen specks), 3 = guildhall interior (warm wood and stone wall, dim fire glow). Multi-layer parallax with at least 3 layers per style (far 0.1, mid 0.3, near 0.55 horizontal factor, small vertical factors), reads `get_viewport().get_camera_2d()`, wraps horizontally, and always covers any window size or aspect ratio and camera movement of at least 700 px vertically (solid colour or gradient fill beyond the painted art). Cross-fades by tweening layer modulate. Painted textures: `assets/bg/bg_<style>_<layer>.png` (for example `bg_street_far.png`).

### Fx scenes (Agent E2), all `scenes/fx/*.tscn`, root Node2D with `scripts/fx/oneshot_fx.gd`
`hit_spark.tscn` (24x24, 4 frames), `dust.tscn` (16x16, 5 frames), `steam_puff.tscn` (24x24, 6 frames), `explosion.tscn` (64x64, 8 frames), `magic_impact.tscn` (24x24, 5 frames; also the cast flash for the spell). Usage by everyone: `var fx: Node2D = FX.instantiate(); get_tree().current_scene.add_child(fx); fx.global_position = pos`. They play once from `_ready()`, then `queue_free()`. Sheet: `assets/fx/<name>.png`, single row. Additive-looking bright colours, pixel art.

### Props (Agent E2), decor only (no collision), `scenes/props/*.tscn`, root Node2D, origin at bottom-centre unless stated, art under `assets/props/`
Animated unless noted: `torch.tscn` (wall torch, origin centre, flame animated), `lichen.tscn` (glowing green wall lichen, soft pulse, origin centre), `fire.tscn` (burning wreck or bonfire flames, origin bottom, animated, 32x48), `burnt_tree.tscn` (static), `bike_rack.tscn` (static), `moped.tscn` (static, wrecked), `rubble.tscn` (static small pile), `big_door.tscn` (huge carved wooden double door, static, 96x112), `rug.tscn` (static, 112x10), `fireplace.tscn` (animated fire, 48x56), `bed.tscn`, `desk.tscn`, `bookshelf.tscn` (static, plausible dungeon guildhall furniture), `guildmaster.tscn` (NPC, idle animation 4 frames, 32x40, wearing robes, gruff face; no collision), `stair_rail.tscn` (iron railing segment, 64x24, static), `crate.tscn` (stack of broken crates, static), `sign_arrow.tscn` (hand-painted wooden arrow sign pointing right, static), `street_lamp.tscn` (standing rusted street light, 40x80, static), `street_lamp_bent.tscn` (snapped and bent street light, 48x72, static), `street_sign.tscn` (green street-name blade signs on a post, 40x60, static), `stop_sign.tscn` (red octagon stop sign on a post, 32x56, static), `gate_frame_near.tscn` and `gate_frame_far.tscn` (the two halves of a stone doorway frame, 19x128 each, static; origin is the doorway centre at the floor, the player walks in front of the near half and behind the far half, and the door sits in the 10 px gap between the jambs), `gate_door.tscn` (side-profile wooden door, 16x112, hinged at its bottom edge; it falls forward flat to open, see scripts/level/gate_door.gd). Each scene's root has the sprite as a child named `Sprite`.
Sheets for animated props are row-based as above; static props are single images.

Interactive props: `door.tscn` (`scripts/props/door.gd`, sheet `assets/props/door.png`, 5 frames 96x112, closed to open; blocks while closed; `unlock()`, `open()`, signal `opened`) and `mordecai.tscn` (NPC, E to talk, signal `dialogue_finished`).

### Loot box (Agent E2, visuals only)
Keep `loot_box.gd` public API (`tier`, `opened(tier)`, `is_open`, prompt behaviour). Replace the ColorRects with an animated sprite per tier (Bronze, Silver, Gold, Legendary: wood and bronze chest, silver crate, gold-trimmed chest, glowing purple-gold relic chest), closed idle (with a tiny glint loop) and a 5 frame opening animation, `assets/props/loot_box.png` with rows per tier (frame 32x32: row `<tier>_idle` 2 frames, row `<tier>_open` 5 frames); on open spawn `explosion`-style sparkle via `hit_spark.tscn`.

## Groups the test bot relies on
`"player"`, `"enemies"`, `"hazards"` (spikes), `"kill_zones"`, `"checkpoints"`, `"platforms"`.

## File ownership
| Owner | Files |
|---|---|
| Agent A (characters) | `assets/characters/*`, `scenes/player/player.tscn`, `scripts/player/player.gd`, `scenes/enemies/goblin.tscn`, `scripts/enemies/goblin.gd`, `scenes/enemies/engineer.tscn`, `scripts/enemies/engineer.gd`, `scenes/enemies/rock.tscn`, `scripts/enemies/rock.gd`, `scenes/ui/health_bar.tscn` and `scripts/ui/health_bar.gd` (restyle the bar as a small pixel-art bar, same API), `art-src/characters/*` |
| Agent E1 (terrain) | `assets/tiles/*`, `assets/bg/*`, `scenes/level/*`, `scripts/level/*`, `assets/props/checkpoint.png`, `art-src/terrain/*` |
| Agent E2 (boss, props, fx) | `assets/props/*` (except checkpoint.png), `assets/boss/*`, `assets/fx/*`, `scenes/enemies/dozer.tscn`, `scripts/enemies/dozer.gd`, `scenes/props/*`, `scripts/props/*`, `scenes/fx/*`, `scripts/fx/*`, `art-src/props/*` |
| Agent D (level) | `scenes/level00.tscn`, `scripts/levels/level00.gd`, `scripts/autoload/game.gd` (additions above only), `scripts/ui/hud.gd` and `scenes/ui/hud.tscn` (only if needed), `art-src/level/*` |
| Lead | `project.godot`, `scripts/util/sprite_util.gd`, `tests/*`, docs |

## Magic Missile (Level 1 ability)
`assets/fx/magic_missile.png`: 14x8 frames, 4 frame loop at 16 fps, faces right (the projectile rotates to its heading); a glowing violet missile with a short tail. `assets/fx/magic_impact.png`: 24x24, 5 frames, one shot burst (used for impact and cast flash). Both generated by `art-src/props/gen_missile.py`. Scene: `res://scenes/combat/magic_missile.tscn` (script `scripts/combat/projectile.gd`, reusable with `target_group`), instanced by the player on the `spell` action (K / gamepad B).

## Floor 1 art kit (#49)
Generators live in `art-src/floor1/` (needs Python with PIL and numpy; `palette.py` is the shared palette). Run `gen_bg_floor1.py`, `gen_tiles_floor1.py`, `gen_props_floor1.py` and `make_scenes.py`; `preview_bg.py` and `preview_props.py` make quick contact sheets. Showcase scene: `tests/floor1_art_kit.tscn` (set `DCC_SHOT_DIR` and `DCC_RES=1280x720` to save screenshots).

### Backgrounds (`scripts/level/background.gd`, `set_style(index)`)
Sheets `assets/bg/bg_<style>_{far,mid,near}.png` (far 640x360, mid and near 960x360, seamless), parallax like the other styles.
| Index | Name | Use |
|---|---|---|
| 4 | `floor1` | neighborhood tunnel: dark brick, arched side passages, green lichen glow, sparse torch |
| 5 | `floor1_artery` | wide torch-lit artery: vault ribs, skull sconces, pipe run, floor arrows, strong orange light |
| 6 | `floor1_corridor` | low ceiling with dripping lichen, grates, wall pipes, no torches |
Indices 0 to 3 are unchanged (street, stairwell, tunnel, guildhall). The `initial_style` enum has the same order.

### Platform styles (`platform.gd`, `style`)
`4 Brick` (`tiles_brick.png`, red brick floor and wall with lichen on the cap), `5 WetStone` (`tiles_wetstone.png`, blue-grey wet blocks, puddle sheen), `6 Plank` (`tiles_plank.png`, dark weathered boards). Same 64x16 strip layout as the other tile sheets; outline colors are set in `platform.gd`.

### Props (`scenes/props/`, decor only, art under `assets/props/`)
| Scene | Sheet | Frame / frames | Origin |
|---|---|---|---|
| `lichen_floor.tscn` | `lichen_floor.png` | 32x14, 4 @3 fps | bottom-centre, sits ON the floor |
| `lichen_wall.tscn` | `lichen_wall.png` | 24x30, 4 @3 fps | bottom-centre, grows up a wall from the floor |
| `torch_bracket.tscn` | `torch_bracket.png` | 22x36, 4 @8 fps | centre (wall torch) |
| `skull_sconce.tscn` | `skull_sconce.png` | 20x32, 4 @8 fps | centre (bone skull holding a flame) |
| `neon_guild_sign.tscn` | `neon_guild_sign.png` | 74x34, 3 @4 fps (on, flicker, on) | centre, "DA TUTORIAL GUILD" |
| `pipe_h.tscn` / `pipe_v.tscn` | `pipe_h.png` 64x14, `pipe_v.png` 14x64 | static | centre / bottom-centre |
| `grate.tscn` | `grate.png` | 32x20 static | centre (wall grate) |
| `sign_hazard.tscn` | `sign_hazard.png` | 26x34 static | bottom-centre (skull warning board) |
| `sign_arrow_brick.tscn` | `sign_arrow_brick.png` | 34x26 static | bottom-centre, points left (the way Level 1 runs) |
| `spray_arrow.tscn` | `spray_arrow.png` | 34x18 static | centre, points left; flip with `scale.x = -1` |
| `spray_x.tscn` | `spray_x.png` | 20x20 static | centre (bone-white "no" cross) |
Lichen props are always placed on a floor or at the base of a wall (never floating, see #28). `torch.tscn` and `lichen.tscn` from Level 0 still work but keep the Level 0 look.

## Bad Llama (#57)
Art generator: `art-src/characters/llama.py` (Pillow only; writes `assets/characters/llama.png`, `assets/fx/lava_ball.png`, `assets/fx/lava_puddle.png`).
| Scene | Script | Notes |
|---|---|---|
| `scenes/enemies/llama.tscn` | `scripts/enemies/llama.gd` | CharacterBody2D, group `enemies`, origin at the feet, art faces right and flips on `Visual`. Sheet `llama.png`, frame 72x56, rows idle 4, walk 6, windup 3, spit 2, hurt 1, die 4, sleep 2, wake 2. Exports `enemy_level` (3), `xp_value`, `is_boss`, `max_health` (6), `dormant` (sleeping until woken). Calls `PlayerStats.award_kill`. |
| `scenes/enemies/lava_ball.tscn` | `scripts/enemies/lava_ball.gd` | Extends `rock.gd` (same `launch(velocity, damage)`); `lava_ball.png` 10x10, 4 frames. Leaves a short-lived puddle where it lands on a platform top. |
| `scenes/level/lava_puddle.tscn` | `scripts/level/lava_puddle.gd` | Area2D hazard, group `hazards`, origin bottom-left like spikes, `width` (multiple of 16), `damage` 1, `lifetime` (0 = permanent). `lava_puddle.png` 32x10, 4 frames, stretched to `width`. |
Weak point: the throat. A hit while the llama telegraphs a spit (`throat_open`, the head rears back and the gland glows), or a head-height hit from its front (attacker 20 px or more above its feet and 14 px or more in front), ruptures the gland and kills it for a bonus; any other hit is normal damage.

## Safe room #1: fast-food restaurant (#59)
Art generators: `art-src/floor1/gen_props_fastfood.py` (props, Pillow and numpy) and `art-src/floor1/make_fastfood_room.py` (the room scene). All decor is static, no collision, original blue and white pixel art.
| Scene | Notes |
|---|---|
| `scenes/level/fastfood_room.tscn` | The SafeRoom kit (`safe_room.gd`, width 640, checkpoint index 2, `box_tiers` Bronze and Silver, kit `floor1`) with a `Dressing` node, one-way play-structure platforms (`PlayDeck`, `PlayStep`), the checkpoint, Tally and the box spot. Instanced by the Level 1 generator in the saferoom section. |
| `scenes/props/tally.tscn` | Caretaker NPC (`scripts/props/tally.gd`): talk, take the paper hat, then eat (full heal plus the 90 s "Well Fed" buff, salmon for Donut). |
| `ff_counter` 96x40, `ff_booth` 44x34, `ff_slide` 72x64, `ff_ballpit` 72x24, `ff_soda` 28x52 (Hoop Cola), `ff_cubicle` 48x56, `ff_menu` 56x24 (centre origin), `ff_playtower` 40x80 | Static props under `scenes/props/`, origin bottom-centre unless noted. |
