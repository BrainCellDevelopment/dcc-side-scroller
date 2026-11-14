"""Shared level generator kit: platform/spike/kill-zone/checkpoint/trigger/section kit,
the .tscn writer helpers and the reachability lint. Used by build_level00.py and
build_level01.py.

Levels are authored in "forward" coordinates (x grows along the direction of play).
A level that runs right to left passes mirror_w=<world width>: lint runs on the
forward data and the writer mirrors every x on the way out.
"""
import os
import re

RUBBLE, IRON, STONE, WOOD = 0, 1, 2, 3
JUMP_GAP = 64
STEP_UP = 48

PROP_W = {"prop_bike_rack": 40, "prop_moped": 40, "prop_rubble": 32, "prop_crate": 40, "prop_burnt_tree": 48,
          "prop_sign_arrow": 32, "prop_street_lamp": 40, "prop_street_lamp_bent": 48, "prop_street_sign": 40, "prop_stop_sign": 32, "prop_stair_rail": 64, "prop_fire": 32, "prop_big_door": 96}


def snap_up(v, q=16):
    return int(-(-v // q) * q)


def fnum(v):
    if abs(v - round(v)) < 1e-6:
        return str(int(round(v)))
    return ("%.2f" % v).rstrip("0").rstrip(".")


def vec(x, y):
    return "Vector2(%s, %s)" % (fnum(x), fnum(y))


def qstr(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


class Writer:
    def __init__(self):
        self.ext = {}
        self.sub = {}
        self.nodes = []

    def ext_id(self, key):
        if key not in self.ext:
            self.ext[key] = "%d_%s" % (len(self.ext) + 1, key.replace("prop_", "p_"))
        return self.ext[key]

    def shape(self, w, h):
        sid = "shape_%dx%d" % (round(w), round(h))
        self.sub[sid] = (round(w, 2), round(h, 2))
        return sid

    def node(self, text):
        self.nodes.append(text)

    def inst(self, name, parent, key, **props_):
        lines = ['[node name="%s" parent="%s" instance=ExtResource("%s")]' % (name, parent, self.ext_id(key))]
        for k, v in props_.items():
            lines.append("%s = %s" % (k, v))
        self.node("\n".join(lines))

    def raw(self, name, typ, parent, lines, groups=None):
        head = '[node name="%s" type="%s"' % (name, typ)
        if parent:
            head += ' parent="%s"' % parent
        if groups:
            head += " groups=[%s]" % ", ".join(qstr(g) for g in groups)
        head += "]"
        self.node("\n".join([head] + lines))

    def render(self, res_paths, script_path, uid=None):
        """res_paths: key -> res:// scene path. The script ext_resource is id 1_level."""
        ext_lines = ['[ext_resource type="Script" path="%s" id="1_level"]' % script_path]
        for key, eid in self.ext.items():
            if key == "script":
                continue
            ext_lines.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % (res_paths[key], eid))
        sub_lines = []
        for sid, (sw, sh) in self.sub.items():
            sub_lines.append('[sub_resource type="RectangleShape2D" id="%s"]\nsize = %s\n' % (sid, vec(sw, sh)))
        total = len(ext_lines) + len(sub_lines) + 1
        head = "[gd_scene load_steps=%d format=3%s]" % (total, ' uid="%s"' % uid if uid else "")
        text = head + "\n\n"
        text += "\n".join(ext_lines) + "\n\n" + "\n".join(sub_lines) + "\n"
        text += "\n\n".join(self.nodes) + "\n"
        return text


class Kit:
    def __init__(self, project, contract_art, mirror_w=None, step_up=STEP_UP, jump_gap=JUMP_GAP):
        self.project = project
        self.contract_art = contract_art
        self.mirror_w = mirror_w
        self.step_up = step_up
        self.jump_gap = jump_gap
        self.plats = []
        self.spikes = []
        self.kills = []
        self.cps = []
        self.enemies = []
        self.props = []
        self.trigs = []
        self.walls = []
        self.markers = []
        self.doors = []
        self.sections = []
        self.routes = {"main": [], "upper": []}
        self.cur = {"x": 0, "y": 0, "gh": 64, "sec": 0, "style": RUBBLE}
        self.pid = 0

    # ------------------------------------------------------------ authoring
    def add_plat(self, x, y, w, h, style, kind="route", one_way=False):
        self.pid += 1
        p = {"id": "P%03d" % self.pid, "x": x, "y": y, "w": w, "h": h, "style": style, "kind": kind,
             "one_way": one_way, "sec": self.cur["sec"]}
        self.plats.append(p)
        return p

    def add_spike(self, x, y, w, route):
        self.spikes.append({"x": x, "y": y, "w": w, "route": route, "sec": self.cur["sec"]})

    def add_kill(self, x, y, w, h):
        self.kills.append({"x": x, "y": y, "w": w, "h": h})

    def add_prop(self, key, x, y, free=False):
        self.props.append({"key": key, "x": x, "y": y, "free": free})

    def add_enemy(self, kind, x, y, **extra):
        e = {"kind": kind, "x": x, "y": y, "sec": self.cur["sec"]}
        e.update(extra)
        self.enemies.append(e)

    def grunt(self, x, y=None):
        self.add_enemy("grunt", x, self.cur["y"] if y is None else y)

    def thrower(self, x, y=None):
        self.add_enemy("thrower", x, self.cur["y"] if y is None else y)

    def cp(self, index, x, stage=0, y=None):
        self.cps.append({"index": index, "x": x, "y": self.cur["y"] if y is None else y, "stage": stage})

    def trig(self, name, kind, arg, x0, x1, y0, y1, meta=None):
        self.trigs.append({"name": name, "kind": kind, "arg": arg, "x0": x0, "x1": x1, "y0": y0, "y1": y1,
                           "meta": meta or {}})

    def hint(self, name, x0, x1, text, y=None):
        y = self.cur["y"] if y is None else y
        self.trig(name, "hint", text, x0, x1, y - 300, y + 120)

    def secret(self, name, piece):
        self.trig(name, "ach", "secret_route", piece["x"] + 4, piece["x"] + piece["w"] - 4, piece["y"] - 50, piece["y"] - 2)

    def ach(self, name, aid, x, y=None, w=32):
        y = self.cur["y"] if y is None else y
        self.trig(name, "ach", aid, x, x + w, y - 300, y + 120)

    def flat(self, w, spk=(), style=None, h=None):
        cur = self.cur
        p = self.add_plat(cur["x"], cur["y"], w, h or cur["gh"], cur["style"] if style is None else style)
        self.routes["main"].append(p["id"])
        for off, sw in spk:
            self.add_spike(cur["x"] + off, cur["y"], sw, True)
        cur["x"] += w
        return p

    def block(self, x, w, h, style=None, y=None):
        top = (self.cur["y"] if y is None else y) - h
        return self.add_plat(x, top, w, h, self.cur["style"] if style is None else style, kind="obstacle")

    def pit(self, w, fire=False):
        x, y = self.cur["x"], self.cur["y"]
        if fire:
            self.add_prop("prop_fire", x + w // 2, y + 60, free=True)
            self.add_kill(x, y + 40, w, 144)
        else:
            self.add_plat(x, y + 96, w, 16, STONE, kind="pitfloor")
            self.add_spike(x, y + 96, w, False)
            self.add_kill(x, y + 76, w, 108)
        self.cur["x"] += w

    def start_section(self, idx, name, bg, title, style, bottom, top_off=420, **extra):
        cur = self.cur
        cur["sec"] = idx
        cur["style"] = style
        cur["gh"] = max(64, snap_up(bottom - cur["y"]))
        s = {"idx": idx, "name": name, "x0": cur["x"], "bg": bg, "title": title, "bottom": bottom,
             "top": cur["y"] - top_off, "y_start": cur["y"]}
        s.update(extra)
        self.sections.append(s)

    def end_section(self):
        self.sections[-1]["x1"] = self.cur["x"]

    def branch(self, L, pieces):
        cur = self.cur
        x, f = cur["x"], cur["y"]
        t = f + 64
        s1 = self.add_plat(x, f + 32, 32, 96, STONE, kind="route")
        trench = self.add_plat(x + 32, t, L, 64, STONE, kind="route")
        xe = x + 32 + L
        s3 = self.add_plat(xe, f + 32, 32, 96, STONE, kind="route")
        self.routes["main"] += [s1["id"], trench["id"], s3["id"]]
        ups = []
        px = x
        for gap, w, dy in pieces:
            p = self.add_plat(px + gap, f + dy, w, 16, STONE, kind="upper", one_way=True)
            ups.append(p)
            px = p["x"] + w
        cur["x"] = xe + 32
        return {"xb": x, "t": t, "xe": xe, "pieces": ups, "before": self.routes["main"][-4]}

    def finish_upper(self, info):
        self.routes["upper"].append([info["before"]] + [p["id"] for p in info["pieces"]] + [self.routes["main"][-1]])

    # ------------------------------------------------------------ writer
    def mx(self, x):
        """Mirror a point."""
        return x if self.mirror_w is None else self.mirror_w - x

    def mspan(self, x, w):
        """Mirror a left edge + width; returns the new left edge."""
        return x if self.mirror_w is None else self.mirror_w - x - w

    def emit_props(self, w):
        for i, d in enumerate(self.props):
            w.inst("D%03d" % i, "Deco", d["key"], position=vec(self.mx(d["x"]), d["y"]))

    def emit_geometry(self, w):
        """Platforms, hazards, checkpoints, triggers, walls and markers."""
        for p in self.plats:
            lines = ["position = %s" % vec(self.mspan(p["x"], p["w"]), p["y"]), "size = %s" % vec(p["w"], p["h"]),
                     "style = %d" % p["style"]]
            if p["one_way"]:
                lines.append("one_way = true")
            if p.get("hide"):
                lines.append("modulate = Color(1, 1, 1, 0)")
            w.inst(p["id"], "Platforms", "platform", **{l.split(" = ")[0]: l.split(" = ")[1] for l in lines})
        for i, s in enumerate(self.spikes):
            w.inst("S%03d" % i, "Hazards", "spikes", position=vec(self.mspan(s["x"], s["w"]), s["y"]), width=fnum(s["w"]) + ".0")
        for i, k in enumerate(self.kills):
            w.inst("K%03d" % i, "Hazards", "killzone", position=vec(self.mspan(k["x"], k["w"]), k["y"]), size=vec(k["w"], k["h"]))
        for c in self.cps:
            w.inst("CP%d" % c["index"], "Checkpoints", "checkpoint", position=vec(self.mx(c["x"]), c["y"]),
                   index=str(c["index"]), stage=str(c["stage"]))
        for t in self.trigs:
            self._emit_trigger(w, t)
        for wl in self.walls:
            w.raw(wl["name"], "StaticBody2D", "Walls", ["position = %s" % vec(self.mx(wl["x"]), wl["y"]),
                                                       "collision_layer = 1", "collision_mask = 0"])
            lines = ['shape = SubResource("%s")' % w.shape(16, 720)]
            if wl["kind"] == "arena":
                lines.append("disabled = true")
            w.raw("CollisionShape2D", "CollisionShape2D", "Walls/" + wl["name"], lines)
        for m in self.markers:
            w.raw(m["name"], "Marker2D", "Markers", ["position = %s" % vec(self.mx(m["x"]), m["y"])])

    def _emit_trigger(self, w, t, parent="Triggers"):
        cx = self.mx((t["x0"] + t["x1"]) / 2)
        cy = (t["y0"] + t["y1"]) / 2
        lines = ["position = %s" % vec(cx, cy), "collision_layer = 0", "collision_mask = 2",
                 "metadata/kind = %s" % qstr(t["kind"]), "metadata/arg = %s" % qstr(str(t["arg"]))]
        for k, v in t["meta"].items():
            lines.append("metadata/%s = %s" % (k, qstr(v) if isinstance(v, str) else str(v)))
        w.raw(t["name"], "Area2D", parent, lines)
        w.raw("Shape", "CollisionShape2D", parent + "/" + t["name"],
              ["shape = SubResource(\"%s\")" % w.shape(t["x1"] - t["x0"], t["y1"] - t["y0"])])

    def emit_enemies(self, w, parent="Goblins", kinds=("grunt", "thrower"), prefix="G", start_index=1):
        gi = start_index - 1
        for e in self.enemies:
            if e["kind"] in kinds:
                gi += 1
                extra = {"variant": "1"} if e["kind"] == "thrower" else {}
                name = e.get("name") or "%s%02d" % (prefix, gi)
                w.inst(name, parent, "goblin", position=vec(self.mx(e["x"]), e["y"] - 2), **extra)

    def emit_section_triggers(self, w, extra_meta=None):
        """Section triggers. Each section dict must carry l and r (forward camera limits).
        extra_meta(section) may return extra metadata keys (already in world space)."""
        for s in self.sections:
            meta = {"l": s["l"], "r": s["r"], "t": s["top"], "b": s["bottom"], "bg": s["bg"], "x0": s["x0"], "x1": s["x1"],
                    "title": s["title"]}
            if self.mirror_w is not None:
                meta["l"], meta["r"] = self.mx(s["r"]), self.mx(s["l"])
                meta["x0"], meta["x1"] = self.mx(s["x1"]), self.mx(s["x0"])
            if extra_meta:
                meta.update(extra_meta(s))
            t = {"name": "Sec%d" % s["idx"], "kind": "section", "arg": str(s["idx"]), "x0": s["x0"], "x1": s["x1"],
                 "y0": -400, "y1": 1500, "meta": meta}
            self.trigs.append(t)
            self._emit_trigger(w, t)

    # ------------------------------------------------------------ lint
    def lint(self, text, res, existing):
        plats, spikes, kills, cps, enemies, props = self.plats, self.spikes, self.kills, self.cps, self.enemies, self.props
        trigs, sections, routes = self.trigs, self.sections, self.routes
        errs = []
        notes = []

        ext_def = re.findall(r'^\[ext_resource [^\]]*id="([^"]+)"', text, re.M)
        sub_def = re.findall(r'^\[sub_resource [^\]]*id="([^"]+)"', text, re.M)
        ext_use = set(re.findall(r'ExtResource\("([^"]+)"\)', text))
        sub_use = set(re.findall(r'SubResource\("([^"]+)"\)', text))
        for i in ext_def:
            if i not in ext_use:
                errs.append("unused ext_resource " + i)
        for i in ext_use:
            if i not in ext_def:
                errs.append("undefined ExtResource " + i)
        for i in sub_def:
            if i not in sub_use:
                errs.append("unused sub_resource " + i)
        for i in sub_use:
            if i not in sub_def:
                errs.append("undefined SubResource " + i)
        if len(set(ext_def)) != len(ext_def) or len(set(sub_def)) != len(sub_def):
            errs.append("duplicate resource ids")
        m = re.match(r"\[gd_scene load_steps=(\d+) format=3( uid=\"[^\"]+\")?\]", text)
        if not m or int(m.group(1)) != len(ext_def) + len(sub_def) + 1:
            errs.append("load_steps wrong")
        if text.count("uid=") != 1:
            errs.append("unexpected uid")

        paths = set()
        sibs = {}
        for nm in re.finditer(r'^\[node name="([^"]+)"(?: type="[^"]+")?(?: parent="([^"]*)")?', text, re.M):
            name, parent = nm.group(1), nm.group(2)
            if parent is None:
                paths.add(".")
                continue
            if parent != "." and parent not in paths:
                errs.append("missing parent %s for %s" % (parent, name))
            full = name if parent == "." else parent + "/" + name
            key = (parent, name)
            if key in sibs:
                errs.append("duplicate sibling %s/%s" % (parent, name))
            sibs[key] = 1
            paths.add(full)

        c2 = open(self.contract_art).read()
        for key, path in res.items():
            if key in existing:
                if not os.path.exists(self.project + "/" + path[6:]):
                    errs.append("missing existing scene " + path)
            else:
                base = os.path.basename(path)
                if base not in c2:
                    errs.append("instanced path not in CONTRACT2: " + path)
                sub = "/".join(path.split("/")[-2:-1])
                if "scenes/" + sub + "/" not in c2:
                    errs.append("folder not in CONTRACT2: " + path)

        for p in plats:
            for k in ("x", "y", "w", "h"):
                if p[k] % 16:
                    errs.append("platform %s %s=%s not 16 aligned" % (p["id"], k, p[k]))
        for s in spikes:
            for k in ("x", "y", "w"):
                if s[k] % 16:
                    errs.append("spikes at %s %s not aligned" % (s["x"], k))
        for c in cps:
            if c["y"] % 16 or c["x"] % 8:
                errs.append("checkpoint %d misaligned" % c["index"])
        for k in kills:
            for v in (k["x"], k["w"]):
                if v % 16:
                    errs.append("kill zone misaligned %s" % k)

        pmap = {p["id"]: p for p in plats}

        def gap_check(a, b, label):
            gap = max(0, b["x"] - (a["x"] + a["w"]), a["x"] - (b["x"] + b["w"]))
            up = a["y"] - b["y"]
            if b["x"] < a["x"]:
                errs.append("%s: route goes backwards %s -> %s" % (label, a["id"], b["id"]))
            if up > self.step_up:
                errs.append("%s: step up %d too high %s -> %s" % (label, up, a["id"], b["id"]))
            lim = self.jump_gap
            if up > 32:
                lim = 32
            if gap > lim:
                errs.append("%s: gap %d > %d between %s (x=%d) and %s (x=%d)" % (label, gap, lim, a["id"], a["x"], b["id"], b["x"]))
            if gap > 0 and -up > 96:
                errs.append("%s: drop with gap too deep %s -> %s" % (label, a["id"], b["id"]))
            return gap, up

        main = [pmap[i] for i in routes["main"]]
        maxgap = maxup = 0
        for a, b in zip(main, main[1:]):
            g, u = gap_check(a, b, "main")
            maxgap, maxup = max(maxgap, g), max(maxup, u)
        for seg in routes["upper"]:
            pl = [pmap[i] for i in seg]
            for a, b in zip(pl, pl[1:]):
                gap_check(a, b, "upper")
        notes.append("main route: %d platforms, max gap %d, max step-up %d, upper segments %d" %
                     (len(main), maxgap, maxup, len(routes["upper"])))
        if main[0]["x"] != 0:
            errs.append("main route does not start at x=0")

        mains = set(routes["main"])
        for s in spikes:
            if not s["route"]:
                continue
            if s["w"] > 48:
                errs.append("route spike too wide at %d" % s["x"])
            host = [p for p in plats if p["id"] in mains and p["y"] == s["y"] and p["x"] <= s["x"] and
                    s["x"] + s["w"] <= p["x"] + p["w"]]
            if not host:
                errs.append("route spike at %d has no platform" % s["x"])
                continue
            h = host[0]
            others = [o for o in spikes if o is not s and o["route"] and o["y"] == s["y"] and h["x"] <= o["x"] < h["x"] + h["w"]]
            left = s["x"] - max([h["x"]] + [o["x"] + o["w"] for o in others if o["x"] < s["x"]])
            right = min([h["x"] + h["w"]] + [o["x"] for o in others if o["x"] > s["x"]]) - (s["x"] + s["w"])
            if left < 32 or right < 32:
                errs.append("spike at %d flat before/after %d/%d < 32" % (s["x"], left, right))

        obs = [p for p in plats if p["kind"] == "obstacle"]
        for o in obs:
            if o["h"] > 48:
                errs.append("obstacle %s too tall" % o["id"])
            if not any(p["id"] in mains and p["x"] <= o["x"] and o["x"] + o["w"] <= p["x"] + p["w"] and
                       p["y"] <= o["y"] + o["h"] and o["y"] + o["h"] <= p["y"] + 0.1 for p in plats):
                errs.append("obstacle %s not sitting on a route platform" % o["id"])
            for s in spikes:
                if s["route"] and abs(s["y"] - (o["y"] + o["h"])) < 1 and o["x"] < s["x"] + s["w"] and s["x"] < o["x"] + o["w"]:
                    errs.append("obstacle %s overlaps spikes" % o["id"])

        for r in main:
            for q in plats:
                if q is r or q["kind"] in ("obstacle", "pitfloor", "refuge"):
                    continue
                ox = min(r["x"] + r["w"], q["x"] + q["w"]) - max(r["x"], q["x"])
                if ox <= 0:
                    continue
                if q["kind"] == "ceil":
                    clear = r["y"] - (q["y"] + q["h"])
                    if 0 <= clear < 44:
                        errs.append("ceiling %s clearance %d < 44 over %s" % (q["id"], clear, r["id"]))
                    continue
                if q["y"] < r["y"] and q["y"] + q["h"] > r["y"] - 40:
                    errs.append("platform %s blocks walking box of %s" % (q["id"], r["id"]))
        for q in plats:
            if q["kind"] == "ceil":
                under = [r for r in main if min(r["x"] + r["w"], q["x"] + q["w"]) - max(r["x"], q["x"]) > 0]
                if not under:
                    errs.append("ceiling %s has no floor" % q["id"])

        def support(x, y, tol=1):
            for p in plats:
                if p["kind"] in ("pitfloor", "ceil", "deco", "refuge"):
                    continue
                if abs(p["y"] - y) <= tol and p["x"] + 8 <= x <= p["x"] + p["w"] - 8:
                    return p
            return None

        for d in props:
            pw = PROP_W.get(d["key"])
            if pw is None or d["free"]:
                continue
            lo, hi = d["x"] - pw / 2, d["x"] + pw / 2
            iv = sorted((max(lo, q["x"]), min(hi, q["x"] + q["w"])) for q in plats
                        if q["kind"] not in ("pitfloor", "ceil", "deco", "refuge", "obstacle") and abs(q["y"] - d["y"]) <= 1
                        and q["x"] < hi and q["x"] + q["w"] > lo)
            cov, end = 0, lo
            for a, b in iv:
                a = max(a, end)
                if b > a:
                    cov += b - a
                    end = b
            if cov < pw * 0.9:
                errs.append("prop %s at (%d,%d) only %d%% supported" % (d["key"], d["x"], d["y"], 100 * cov // pw))

        for e in enemies:
            if e["kind"] in ("dozer",):
                continue
            if support(e["x"], e["y"]) is None:
                errs.append("enemy %s at (%d,%d) has no platform" % (e["kind"], e["x"], e["y"]))
        for c in cps:
            if support(c["x"], c["y"]) is None:
                errs.append("checkpoint %d has no platform" % c["index"])
        idxs = sorted(c["index"] for c in cps)
        if idxs != sorted(set(idxs)):
            errs.append("duplicate checkpoint index")
        for a, b in zip(sections, sections[1:]):
            if a["x1"] != b["x0"]:
                errs.append("sections %d/%d not contiguous" % (a["idx"], b["idx"]))
        for s in sections:
            if not (s["l"] <= s["x0"] and s["r"] >= s["x1"]):
                errs.append("section %d x not inside camera limits" % s["idx"])
            for p in plats:
                if s["x0"] <= p["x"] < s["x1"]:
                    if p["y"] < s["top"]:
                        errs.append("platform %s above section %d top limit" % (p["id"], s["idx"]))
                    if p["kind"] in ("route", "obstacle", "upper") and p["y"] > s["bottom"]:
                        errs.append("platform %s below section %d bottom limit" % (p["id"], s["idx"]))
            for e in enemies:
                if s["x0"] <= e["x"] < s["x1"] and not (s["top"] <= e["y"] <= s["bottom"]):
                    errs.append("enemy outside limits in section %d" % s["idx"])
        for t in trigs:
            if t["kind"] in ("hint", "ach", "ambush", "arena", "dozer"):
                if not any(s["x0"] - 1 <= t["x0"] and t["x1"] <= s["x1"] + 1 for s in sections):
                    errs.append("trigger %s spans sections" % t["name"])
        ids = [t["name"] for t in trigs]
        if len(ids) != len(set(ids)):
            errs.append("duplicate trigger names")
        notes.append("platforms %d spikes %d kill zones %d enemies %d checkpoints %d triggers %d props %d" %
                     (len(plats), len(spikes), len(kills), len([e for e in enemies if e['kind'] in ('grunt', 'thrower')]),
                      len(cps), len(trigs), len(props)))
        return errs, notes
