# System voice: achievement hooks (#70)

Registry: `dcc-side-scroller/scripts/data/achievements.gd` (key = hook ID, value = `[title, sentence]`). Autoload: `SystemVoice` (`scripts/autoload/system_voice.gd`). Test: `res://tests/system_voice.tscn`.

All text is original. Style: short rude title, one mocking sentence, a little hidden sympathy.

## API
- `SystemVoice.fire("hook")` unlocks the achievement once (popup queues during combat).
- `SystemVoice.count("name")` bumps a counter and fires `<name>_<n>` (plus `first_blood` / `first_smush` / `first_death` at 1). Counts only while a floor is active.
- `SystemVoice.announce(title, body, seconds)` queues a centered System box in the HUD.
- `announce_boss_intro(name)`, `announce_patch_notes()`, `announce_survivors()` (4:00 AM manager voice).
- Survivors: `drop_survivors(n)`, `survivors`, `set_survivors_visible(bool)`; the player toggles with `V`. Ticks down slowly while a floor is active.
- Floor timer: `Game.floor_time_left` (5 days) is shown by the HUD; `SystemVoice.time_left()`, `begin_floor(floor, seconds)`. "Time to Level Collapse" boxes fire at 24h, 6h, 1h, 10min. #68 should call `begin_floor` / `drop_survivors` and fire `collapse_survived`.

## Already wired
`boom` (explosives), `level_2/5/9` (level-up), `stomp_*`/`first_smush`, `kill_*`/`first_blood`, `boss_kill_*` (via XP award on `is_boss`), `death_*`/`first_death`, boss intro announcement (boss arena), level-up announcement, survivor counter and timer warnings.

## Hooks later issues must fire
| Hook | Fire when | Issue |
|---|---|---|
| `intro_survived` | first section cleared | #48 / intro |
| `first_llama`, `llama_beat` | llama met / llama beat done | #57 |
| `first_bathroom`, `bathroom_beat` | bathroom door entered / used | #56 |
| `first_charm` | a charm lands | charm issue |
| `first_box`, `all_boxes_open` | first box opened / all opened | #52 |
| `first_safe_room` | SafeRoom entered | #50 |
| `first_potion` | consumable used | inventory |
| `first_door` | any door opens | doors |
| `workshop_found` | workshop reached | Floor 1 plan |
| `map_upgrade` | neighborhood map reward | #51 |
| `neighborhood_boss`, `borough_boss` | those bosses die | #51 / boss beats |
| `collapse_survived`, `survivor_count_milestone` | collapse beat | #68 |

Add a new achievement by adding one line to `FLOOR_1`; no other code changes needed.
