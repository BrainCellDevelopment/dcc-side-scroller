---
title: "The Tab menu runs live instead of pausing, so gameplay input is gated and a hotbar covers quick use"
author: Mychsmit
date: 2026-11-14
branch: feature/inventory-system
cost: { minutes: 18, tokens: 140355 }
id: l-5f8a7b5c
scope: repo
status: active
src: agent
touches:
  - dcc-side-scroller/assets/ui/carl_doll.png
  - dcc-side-scroller/assets/ui/carl_doll.png.import
  - dcc-side-scroller/project.godot
  - dcc-side-scroller/scripts/autoload/game.gd
  - dcc-side-scroller/scripts/autoload/inventory.gd
  - dcc-side-scroller/scripts/autoload/inventory.gd.uid
  - dcc-side-scroller/scripts/autoload/player_stats.gd
  - dcc-side-scroller/scripts/player/player.gd
  - dcc-side-scroller/scripts/props/door.gd
  - dcc-side-scroller/scripts/props/loot_box.gd
---

## Decided
The inventory menu does not pause the game. While it is open, gameplay input is ignored so navigating the menu never moves Carl. A 5-slot hotbar (keys 1-5) lets items be equipped or unequipped without opening the menu. Assigning items to the hotbar is allowed anywhere, not only in safe rooms.

## Tried and ruled out
Pausing the tree while the menu is open: dropped on purpose so the menu is a real-time risk and the hotbar has a reason to exist.
Relying on set_as_handled to stop gameplay while the menu is open: it does nothing for code that polls Input directly.

## Watch out
Any new gameplay code that reads input must go through the Game action helpers, never Input directly, or it will keep reacting while the menu is open.
The Inventory autoload must load before Game, because Game registers the hotbar key actions at startup using the hotbar size.
The graph index only covers the Python art scripts, so GDScript has to be searched with plain grep.

In the code: Game.action_pressed / action_just_pressed / action_axis and Game.menu_open in scripts/autoload/game.gd; hotbar logic in scripts/autoload/inventory.gd; scripts/ui/hotbar.gd; tests/inventory_live.tscn (windowed, run without --headless).
