---
title: Carl and Donut use a larger sprite frame because the cat hid his face at the old size
author: Mychsmit
date: 2026-11-13
branch: feature/level-0
cost: { minutes: 30, tokens: 397292 }
id: l-5fe5ff3a
scope: repo
status: active
src: agent
touches:
  - AGENTS.md
  - HANDOFF.md
  - art-src/characters/MORDECAI_SHEET.md
  - art-src/characters/carl.py
  - art-src/characters/check_tscn.py
  - art-src/characters/clipcheck.py
  - art-src/characters/donut.py
  - art-src/characters/engineer.py
  - art-src/characters/goblin.py
  - art-src/characters/hum.py
---

## Decided
Carl's sheet moved from 48x40 to 64x56 frames so Donut can sit on his head as a separate cat without covering his face. His body stays the same pixel size, so the hitbox is unchanged. Donut is baked into every Carl frame; the old follower sprite was removed.

## Tried and ruled out
Drawing the cat over Carl's head at 48x40: it hid his face and read as a blob. Generating a Persian cat from script: it stays a blocky shape, so Donut wants hand-drawn art.

## Watch out
Pressing E to open a loot box next to Mordecai also restarted his dialogue and froze Carl; Mordecai now ignores E while boxes are unopened. Spawn goblins deferred or the physics server throws "flushing queries" errors. The guild-flow test fails in a real window on frame timing but passes headless.

In the code:
Frame size constant in player.gd; sheet built by art-src/characters/make_carl_donut.py; Mordecai guard in mordecai.gd; deferred spawn in level00.gd.
