import re
import sys
import glob

bad = 0
for f in sorted(glob.glob("/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/scenes/level/*.tscn")):
    t = open(f).read()
    ext = re.findall(r'\[ext_resource [^\]]*id="([^"]+)"', t)
    sub = re.findall(r'\[sub_resource [^\]]*id="([^"]+)"', t)
    steps = int(re.search(r"load_steps=(\d+)", t).group(1))
    errs = []
    if steps != len(ext) + len(sub) + 1:
        errs.append(f"load_steps {steps} != {len(ext) + len(sub) + 1}")
    for m in re.findall(r'ExtResource\("([^"]+)"\)', t):
        if m not in ext:
            errs.append("undefined ext " + m)
    for m in re.findall(r'SubResource\("([^"]+)"\)', t):
        if m not in sub:
            errs.append("undefined sub " + m)
    for p in re.findall(r'path="res://([^"]+)"', t):
        if not glob.glob("/Users/mychal.smith/brain-cell-gaming/dcc-side-scroller/dcc-side-scroller/" + p):
            errs.append("missing file " + p)
    names = {}
    for m in re.finditer(r'\[node name="([^"]+)"(?: type="[^"]*")?(?: parent="([^"]*)")?', t):
        n, par = m.group(1), m.group(2)
        if par is None:
            names["."] = n
        elif par != "." and par not in names.values() and par not in names:
            errs.append(f"parent {par} missing for {n}")
        else:
            names[par + "/" + n if par != "." else n] = n
    if "uid=" in t:
        errs.append("uid present")
    print(f.split("/")[-1], "OK" if not errs else errs)
    bad += bool(errs)
sys.exit(bad)
