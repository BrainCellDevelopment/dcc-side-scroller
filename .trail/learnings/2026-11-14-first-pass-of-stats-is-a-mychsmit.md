---
title: "First pass of stats is a core module with all five book stats, inactive on level 0"
author: Mychsmit
date: 2026-11-14
branch: feature/stats-system
cost: { minutes: 18, tokens: 328622 }
id: l-1242e756
scope: repo
status: active
src: agent
touches:
  - art-src/level/build_level00.py
  - art-src/level/level00_map.png
  - dcc-side-scroller/scenes/level00.tscn
  - dcc-side-scroller/scripts/enemies/dozer.gd
  - dcc-side-scroller/scripts/levels/level00.gd
  - dcc-side-scroller/scripts/props/loot_box.gd
  - dcc-side-scroller/scripts/ui/hud.gd
  - dcc-side-scroller/tests/playthrough.gd
  - art-src/terrain/bg_street.py
  - art-src/terrain/bgkit.py
---

## Decided
Stats ship first as a core module only, with all five stats from the book (Strength, Intelligence, Constitution, Dexterity, Charisma). They are fully inactive on level 0 and switch on from floor 1. Points earned per level-up (3) stay locked until floor 3, when race and class are chosen in the book. Formulas are our own guesses because the book gives none.

## Tried and ruled out
- Adding an in-game stats screen in the same pass: deferred, core logic first.
- Adding a stub Level 1 scene so stats are live somewhere: deferred, nothing grants XP yet.
- Limiting to three stats (Strength, Constitution, Intelligence): the user chose all five.

## Watch out
Dexterity and Charisma are stored but affect nothing yet. Nothing calls enter_floor or add_xp until a Level 1 exists.

In the code: scripts/autoload/player_stats.gd (PlayerStats autoload), hooks in scripts/player/player.gd, dev command `stats` in scripts/autoload/dev_console.gd. Branch feature/stats-system. GitHub issue #37.
