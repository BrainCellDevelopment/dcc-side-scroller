import re, sys, os, glob
from PIL import Image
ROOT = "/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller"
files = sorted(glob.glob(ROOT + "/scenes/fx/*.tscn") + glob.glob(ROOT + "/scenes/props/*.tscn") + [ROOT + "/scenes/enemies/dozer.tscn"])
bad = 0
for f in files:
    t = open(f).read()
    errs = []
    m = re.match(r'\[gd_scene load_steps=(\d+) format=3\]', t)
    ext = re.findall(r'\[ext_resource [^\]]*id="([^"]+)"', t)
    sub = re.findall(r'\[sub_resource [^\]]*id="([^"]+)"', t)
    if not m or int(m.group(1)) != len(ext) + len(sub) + 1:
        errs.append("load_steps")
    if len(set(ext)) != len(ext) or len(set(sub)) != len(sub):
        errs.append("dup ids")
    for u in re.findall(r'ExtResource\("([^"]+)"\)', t):
        if u not in ext: errs.append("undef ext " + u)
    for u in re.findall(r'SubResource\("([^"]+)"\)', t):
        if u not in sub: errs.append("undef sub " + u)
    for p in re.findall(r'path="res://([^"]+)"', t):
        if not os.path.exists(os.path.join(ROOT, p)): errs.append("missing " + p)
    nodes = re.findall(r'\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]+)")?', t)
    paths = set()
    seen = set()
    for i, (n, par) in enumerate(nodes):
        if i == 0:
            paths.add(n); root = n; continue
        if par == ".":
            full = n
            ok = True
        else:
            ok = par in paths
            full = par + "/" + n
        if not ok: errs.append("parent missing for " + full)
        if full in seen: errs.append("dup node " + full)
        seen.add(full); paths.add(full)
    if "uid=" in t: errs.append("uid")
    print(("BAD " if errs else "ok  ") + os.path.relpath(f, ROOT), errs)
    bad += bool(errs)
sizes = {"fx/hit_spark": (24, 24, 4), "fx/dust": (16, 16, 5), "fx/steam_puff": (24, 24, 6), "fx/explosion": (64, 64, 8),
         "boss/dozer_tracks": (88, 16, 4), "boss/dozer_wheel": (28, 28, 6), "boss/dozer_hatch": (40, 24, 3), "boss/dozer_driver": (24, 24, 2),
         "boss/dozer_body": (112, 64, 1), "props/torch": (20, 32, 4), "props/lichen": (24, 24, 4), "props/fire": (32, 48, 6),
         "props/fireplace": (48, 56, 4), "props/guildmaster": (32, 40, 4), "props/loot_box": (32, 32, 5)}
for k, (w, h, n) in sizes.items():
    im = Image.open("%s/assets/%s.png" % (ROOT, k))
    if im.width != w * n or im.height % h != 0:
        print("SIZE BAD", k, im.size); bad += 1
    a = im.getchannel('A')
    if set(a.getdata()) - {0, 255}: print("ALPHA BAD", k); bad += 1
print("failures", bad)
