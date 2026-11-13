import re, sys
bad = 0
for path in sys.argv[1:]:
    t = open(path).read()
    ext = re.findall(r'\[ext_resource [^\]]*id="([^"]+)"', t)
    sub = re.findall(r'\[sub_resource [^\]]*id="([^"]+)"', t)
    m = re.search(r'load_steps=(\d+)', t)
    ids = set(ext) | set(sub)
    errs = []
    if len(set(ext)) != len(ext) or len(set(sub)) != len(sub): errs.append('duplicate ids')
    if not m or int(m.group(1)) != len(ext) + len(sub) + 1: errs.append(f'load_steps {m.group(1) if m else None} != {len(ext)+len(sub)+1}')
    for u in re.findall(r'(?:ExtResource|SubResource)\("([^"]+)"\)', t):
        if u not in ids: errs.append('undefined id ' + u)
    for i in ids:
        if t.count('"%s"' % i) < 2: errs.append('unused id ' + i)
    if 'uid=' in t: errs.append('uid present')
    names = {}
    nodes = re.findall(r'\[node name="([^"]+)"(?: type="[^"]*")?(?: parent="([^"]*)")?', t)
    paths = set()
    for idx, (n, par) in enumerate(nodes):
        if idx == 0:
            paths.add('.'); root = n; continue
        if par not in paths: errs.append(f'parent {par} missing for {n}')
        full = n if par == '.' else par + '/' + n
        if full in paths: errs.append('duplicate node ' + full)
        paths.add(full)
    print(path, 'OK' if not errs else errs)
    bad += bool(errs)
sys.exit(bad)
