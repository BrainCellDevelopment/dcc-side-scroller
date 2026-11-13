# Level 1 plan (Lukas)

Level numbering: the tutorial is **Level 0** (Mychal, branch `feature/level-0`). **Level 1** is the first real floor and is Lukas's. The older design doc titled "Level 1 Design: The Tutorial Floor" describes what is now Level 0.

## Setup
1. Install Godot **4.7.2 stable** (standard build, not .NET). Same version as Mychal.
2. Clone `github.com/BrainCellDevelopment/dcc-side-scroller`. The Godot project is the inner `dcc-side-scroller/` folder (the one with `project.godot`).
3. Branch from `develop`, not `main`: `git switch develop && git pull && git switch -c feature/level-1`.
4. Open PRs into `develop`. `main` only gets finished, playable milestones.
5. Graft is wired into the repo for AI coding agents (`AGENTS.md`, `.claude/`, `.cursor/`, `.mcp.json`). If you use it: `npm i -g @nanonets/graft`, then `graft build` in the repo root. The `graft/` cache is git-ignored, so each of us builds our own.

## What Level 0 gives you
Everything is placeholder art (ColorRects). Reuse these; don't copy them.

| Piece | Scene | Notes |
|---|---|---|
| Carl (player) | `scenes/player/player.tscn` | Move, variable jump, melee with his fists (no weapon). `take_damage(amount, from)`, `bounce()`, `is_dead()`, `control_enabled`, signals `died`, `attacked`. Donut sits on his shoulder as decoration only. |
| Goblin | `scenes/enemies/goblin.tscn` | Patrol, chase, club swing. Signal `died(enemy)`. Health bar shows only after damage. |
| Goblin Engineer | `scenes/enemies/engineer.tscn` | Mini-boss. `activate()`, signal `defeated(engineer)`. |
| Murder Dozer | `scenes/enemies/dozer.tscn` | Auto-scroll boss. `start(player, scroll_x)`, signals `round_cleared(n)`, `destroyed`. |
| HUD | `scenes/ui/hud.tscn` | HP, floor timer (top right), achievement popups (top left, held during combat), boss bar, hint, `show_banner(text, seconds)`. |
| Loot box | `scenes/props/loot_box.tscn` | `tier` export (Bronze, Silver, Gold, Legendary). Opens only in a safe zone. Signal `opened(tier)`. |
| `Game` autoload | `scripts/autoload/game.gd` | Input actions, combat and safe-zone state, achievements, floor timer, boss bar and hint signals. |

Conventions every new scene must follow:
- Base resolution 640x360. Character origin at the feet. Art and attack areas live under a `Visual` node that flips with `scale.x`.
- Collision layers: 1 world, 2 player, 3 enemy. Enemy bodies never block the player; damage goes through `Area2D`s.
- Every damageable thing has `take_damage(amount: int, from: Vector2)`. Enemies are in group `enemies`, the player in `player`.
- Enemies call `Game.enemy_engaged()` / `Game.enemy_disengaged()` in balanced pairs so popups stay hidden during fights.
- Input actions are registered in `game.gd`, not in Project Settings: `move_left`, `move_right`, `jump`, `attack`, `interact`.
- Typed GDScript, almost no comments, book names for characters and places, all joke and achievement text original.

## Level 1 tasks
Decided so far: Donut's ability is first used in Level 1. She rides Carl as an ability or power-up, and her ranged attack unlocks later from a loot box. Solo play only. Target feel is Mega Man mixed with Metal Slug.

1. `scenes/level01.tscn` + `scripts/levels/level01.gd`: greybox layout. Copy the structure of `level00` (phases enum, camera handled by the level script), not its content.
2. Level transition: Level 0 currently ends on a "LEVEL 0 COMPLETE" banner. Add an exit in the Guildhall that loads Level 1, and carry player health across (put it on `Game`).
3. Donut ability v1: an input action (register it in `game.gd`), a cooldown, and a HUD indicator. Add it to `player.tscn` behind an `@export var donut_enabled` flag so Level 0 stays unchanged.
4. One new enemy type for Floor 1, built from the goblin pattern (state enum, `take_damage`, `died`, engaged counter).
5. A real loot box reward. Boxes open today but give nothing. Decide what Bronze and Silver contain and apply it.
6. One safe room with a `Game.set_safe_zone(true/false)` area, and at least one box that can only be opened there.
7. Floor end: stairwell down, which is where Level 2 will start.

## To decide together
- The Level 1 layout and its set pieces from the book. Nothing is designed yet.
- What Donut's first ability does.
- Whether healing exists on Floor 1. Level 0 has none on purpose.
- Whether the floor timer can actually run out, or is flavour for now.
- Whether the 18 levels include Level 0.

## Definition of done
- Play it start to finish in Godot with no errors in the Output panel.
- The Level 0 smoke test still passes. From the folder with `project.godot`:
  `godot --headless --fixed-fps 60 --path . res://tests/playthrough.tscn`
  A bot plays Level 0 end to end and prints `PASS` (exit code 0) or `FAIL`. Add a `tests/playthrough_level01` the same way.
- Both of us review it before it merges into `develop`.
