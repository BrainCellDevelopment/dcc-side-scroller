# Opening cutscene art

Run each script with `/tmp/artvenv/bin/python <script>` from this folder. Output goes to `dcc-side-scroller/assets/cutscene/`.
`pxl.py`, `pix.py`, `bgkit.py`, `carl_rig.py` are copies/adaptations of the scripts in `art-src/characters` and `art-src/terrain` (carl_rig: brown jacket, bare chest, bare far arm, pink Crocs, no cat).

| Script | Output | Size | Notes |
|---|---|---|---|
| make_room.py | apt_room.png | 640x360 opaque | floor line y=300; door x20-75 (y190-300); couch x130-300, seat top ~y281, seated Carl centre x=215; floor lamp x~116; side table + ashtray x306-336; TV x344-414; clock at 2:23 (302,106); window x430-590, y60-215 with open sash, sill top y=216, cat centre x=510 (feet y=215); curtains only at the window edges |
| make_carl.py | cutscene_carl.png | 512x280, frame 64x56, 8 cols x 5 rows | origin bottom-centre (x=32, feet on row 55), faces right. Row 0 sit (2 frames: cigarette lit, arm raised puffing), row 1 stand (1), row 2 run (6), row 3 shocked looking up (1), row 4 stagger (1). Unused cells transparent |
| make_donut.py | cutscene_donut.png | 128x128, frame 32x32, 4x4 | origin bottom-centre, faces right. Row 0 sit (idle, blink, tail flick), row 1 leap (launch, mid-air), row 2 sitting small on a head (~24 px wide), row 3 on a branch looking down |
| make_buildings.py | bld_a.png 150x420, bld_b.png 120x520, bld_c.png 170x380, bld_d.png 130x460 | transparent | image bottom = building base |
| make_tree.py | tree.png | 90x150 transparent | trunk base bottom-centre (45,149). Cat anchor (donut row 3 frame, bottom-centre) at (62, 65) px from top-left: top of the thick right branch is row 64 at x=62 |
| make_sky.py | sky_pan.png | 640x720 RGBA | y 0-359 opaque; alpha fades linearly from 255 at y=360 to 0 at y=719 |
