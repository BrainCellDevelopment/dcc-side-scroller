# DCC Side Scroller: build contract (Level 0)

Godot 4.7.2, GDScript only, 2D, Compatibility renderer. Project root is `res://`.
Write every file under `/home/claude/dcc/project/` (that folder maps to `res://`).
You cannot run Godot here, so be exact: your files will be loaded headless afterwards and must parse with zero errors and zero warnings-as-errors.

## Code rules
- Static typing everywhere (`var x: int = 0`, typed params and returns). Tabs for indentation.
- Almost no comments. Only add one where the code would otherwise be misleading.
- No `class_name`. No autoloads other than `Game`. No addons. No external assets: all art is placeholder `ColorRect` / `Polygon2D` nodes.
- Godot 4 API only (`CharacterBody2D.velocity` + `move_and_slide()`, `@export`, `@onready`, `await`, `Signal.connect(callable)`, `create_tween()`).
- Never shadow built-in members (e.g. don't name a variable `name`, `position`, `scale`, `owner`, `visible`).
- Do not copy any text from the Dungeon Crawler Carl books. Character and place names are fine; all jokes, achievement titles and descriptions must be original.

## .tscn rules
- Hand-written text scenes: header `[gd_scene load_steps=N format=3]` where N = number of ext_resource + sub_resource + 1. No `uid=` anywhere, no `unique_id`.
- `[ext_resource type="Script" path="res://..." id="1_x"]`, `[ext_resource type="PackedScene" path="res://..." id="2_x"]`, sub resources like `[sub_resource type="RectangleShape2D" id="shape_body"]` with `size = Vector2(w, h)`.
- Child nodes use `parent="."` or `parent="Visual"` etc. Instanced scenes: `[node name="X" parent="." instance=ExtResource("2_x")]`.
- Groups go on the node line: `[node name="Player" type="CharacterBody2D" groups=["player"]]`.
- ColorRect uses `offset_left/offset_top/offset_right/offset_bottom` and `color = Color(r, g, b, a)`; set `mouse_filter = 2` on every Control used as art or HUD.

## World conventions
- Base viewport 640x360, pixel-art scale. +Y is down. Gravity: read `ProjectSettings.get_setting("physics/2d/default_gravity")` (980).
- Every character's origin is at its feet, centre. Facing is flipped by setting `Visual.scale.x` to 1 or -1 on a `Node2D` named `Visual` that holds all art and all attack areas.
- Collision layers (bit values): world = layer 1 (value 1), player body = layer 2 (value 2), enemy body = layer 3 (value 4).
  - Player body: `collision_layer = 2`, `collision_mask = 1`.
  - Enemy bodies: `collision_layer = 4`, `collision_mask = 1` (enemies and player never block each other).
  - Player attack `Area2D`: `collision_layer = 0`, `collision_mask = 4`, detects enemy bodies.
  - Enemy attack / contact `Area2D`: `collision_layer = 0`, `collision_mask = 2`, detects the player body.
  - Interactables (`Area2D`): `collision_layer = 0`, `collision_mask = 2`.
- Groups: player is in `"player"`, every enemy in `"enemies"`.
- Damage interface, on the player and on every enemy: `func take_damage(amount: int, from: Vector2) -> void` (`from` = global position of the attacker, used for knockback direction).
- Find the player with `get_tree().get_first_node_in_group("player") as CharacterBody2D`; always null-check and `is_instance_valid` it.

## Input actions (registered at runtime by `Game`, never in project.godot)
`move_left`, `move_right`, `jump`, `attack`, `interact`.

## Autoload `Game` (`res://scripts/autoload/game.gd`, extends Node)
```
signal achievement_unlocked(title: String, description: String)
signal player_health_changed(current: int, maximum: int)
signal boss_health_changed(boss_name: String, current: int, maximum: int)
signal boss_cleared()
signal combat_changed(active: bool)
signal safe_zone_changed(active: bool)
signal loot_box_opened(tier: String)
signal hint_changed(text: String)

var in_combat: bool            # true while at least one enemy is engaged
var in_safe_zone: bool
var floor_time_left: float     # seconds, counts down in _process

func unlock_achievement(id: String, title: String, description: String) -> void   # fires once per id
func enemy_engaged() -> void       # +1 engaged enemies
func enemy_disengaged() -> void    # -1, clamped at 0
func set_safe_zone(active: bool) -> void
func report_player_health(current: int, maximum: int) -> void    # emits player_health_changed
func report_boss_health(boss_name: String, current: int, maximum: int) -> void   # emits boss_health_changed
func clear_boss() -> void          # emits boss_cleared
func report_loot_box_opened(tier: String) -> void
func set_hint(text: String) -> void    # "" hides it
func reset_run() -> void           # resets everything except unlocked achievements, then nothing else; the caller reloads the scene
```

## File ownership
| Path | Owner |
|---|---|
| `scripts/autoload/game.gd` | Agent C |
| `scenes/ui/hud.tscn`, `scripts/ui/hud.gd` | Agent C |
| `scenes/props/loot_box.tscn`, `scripts/props/loot_box.gd` | Agent C |
| `scenes/player/player.tscn`, `scripts/player/player.gd` | Agent A |
| `scenes/enemies/goblin.tscn`, `scripts/enemies/goblin.gd` | Agent B |
| `scenes/enemies/engineer.tscn`, `scripts/enemies/engineer.gd` | Agent B |
| `scenes/ui/health_bar.tscn`, `scripts/ui/health_bar.gd` | Agent B |
| dozer, level00, project.godot, docs | lead (not you) |

Only write the files you own. Code against the interfaces in this contract for everything else.
