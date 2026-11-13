# Mordecai sheet

File: `assets/characters/mordecai.png` (128x80), generator `art-src/characters/mordecai.py`.
Frame size 32x40, origin bottom-centre (feet on the last row), drawn facing right (flip with scale.x = -1).

| Animation | Row | Frames | FPS | Loop |
|---|---|---|---|---|
| idle | 0 | 4 | 3 | yes |
| talk | 1 | 4 | 8 | yes |

SpriteUtil dict: `{"idle": {"row": 0, "count": 4, "fps": 3.0, "loop": true}, "talk": {"row": 1, "count": 4, "fps": 8.0, "loop": true}}`.
`scenes/props/guildmaster.tscn` (anim_prop.gd, plays row 0 only) now points at this sheet; for talk, build the sprite with SpriteUtil and the dict above.
