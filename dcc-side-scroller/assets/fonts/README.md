# Fonts

| Font | Use | Licence | Source |
|---|---|---|---|
| Silkscreen (Regular, Bold) | HUD numbers and labels (`HudLabel` theme variation) and the Tab menu stats block (`StatsText`), because Pixelify's 2 and 5 are hard to tell from 8 and S at small sizes | SIL Open Font License 1.1 (`Silkscreen-OFL.txt`) | https://github.com/googlefonts/silkscreen |
| Pixelify Sans (variable, wght 400 to 700) | Everything else: prompts, banners, dialogue, System notices, menus | SIL Open Font License 1.1 (`PixelifySans-OFL.txt`) | https://github.com/eifetx/Pixelify-Sans |

Both come from the Google Fonts repository (`ofl/silkscreen`, `ofl/pixelifysans`). Keep each licence file next to its font. The fonts are applied project-wide by `assets/ui/theme.tres` (Project Settings, GUI, Theme). Do not override fonts on individual nodes; add a theme type variation instead.
