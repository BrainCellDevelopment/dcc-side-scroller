# Dungeon Crawler Carl: book context for the game team

Reference notes for the side-scroller fan game, written from books 1 to 3 of the series (Matt Dinniman). Everything is paraphrased; use the books for exact wording. SPOILERS throughout.

## Files

| File | What it is |
|---|---|
| [characters.md](characters.md) | Cross-book character guide with art cues (Carl, Donut, Mordecai, allies, villains, the System voices). |
| [levels-and-looks.md](levels-and-looks.md) | Floor-by-floor visual style guide: palettes, architecture, hazards, enemies, bosses, and how each maps to the game. |
| [world-and-system.md](world-and-system.md) | How the dungeon works (stats, loot boxes, safe rooms, bosses, achievements) and the System's voice, with writing tips. |
| [book-01-dungeon-crawler-carl.md](book-01-dungeon-crawler-carl.md) | Full book 1 summary (Floors 1-2 plus the tutorial). |
| [book-02-carls-doomsday-scenario.md](book-02-carls-doomsday-scenario.md) | Full book 2 summary (Floor 3, the Over City). |
| [book-03-dungeon-anarchists-cookbook.md](book-03-dungeon-anarchists-cookbook.md) | Full book 3 summary (Floor 4, the Iron Tangle). |

The three book files each have the same nine sections: overview, timeline, characters, world rules, floors and locations, enemy and boss catalog, items and achievements, humor and tone, and game ideas. Line numbers like `[L1200]` point into the source markdown and are approximate.

## Books and floors at a glance

| Book | Floors covered | Setting in one line |
|---|---|---|
| 1. Dungeon Crawler Carl | Tutorial, Floor 1, Floor 2 | Underground brick-and-lichen grid of corridors under a destroyed Earth. |
| 2. Carl's Doomsday Scenario | Floor 3 | The Over City: a fake-sky medieval theme-park city with a circus and a skyfowl town. |
| 3. The Dungeon Anarchist's Cookbook | Floor 4 | The Iron Tangle: a planet-sized subway and railway network. |

Our game's Level 0 (street, stairs, tunnels, Engineer, Goblin Murder Dozer, Mordecai's guild room) is the book 1 tutorial.

## Where the game already matches or differs from the books

- **Matches:** the collapsed, dark surface; the wide staircase down; torch-lit tunnels; goblins with steam-powered gear; the Goblin Murder Dozer; Mordecai's classroom-sized guild room with a fireplace, bed, desk and rug; heart-print boxers; a loot box that gives Donut a Legendary Pet Biscuit.
- **Differs (on purpose or not yet checked):** Mordecai in book 1 is a bearded rat in a black vest, blue pants and sandals; the Engineer and the Dozer boss fight, the countdown and the pineapple throws are our own design (in the book the dozer blows up against a wall outside the guild); Carl in the book is barefoot and pantsless.
- See `characters.md` and `levels-and-looks.md` for details that could change art or level design.

## Notes on how these were made

- Three reading passes, one per book, each saved running notes and then wrote the summary. Each summary lists what it was unsure about.
- The base64 image blobs, front matter and ads in the source files were skipped.
- `trail ask` indexes code only, so these markdown files are not searchable through it. Search them with `grep` or open them directly.
