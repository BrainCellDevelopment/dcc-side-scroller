"""Writes the Floor 1 prop scenes (scenes/props/*.tscn) next to their sheets.
Pure stdlib. Run: python3 art-src/floor1/make_scenes.py
"""
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dcc-side-scroller"))

# name: (node name, w, h, frames, fps, origin)  origin: "bottom" (bottom-centre) or "center"
ANIM = {
    "lichen_floor": ("LichenFloor", 32, 14, 4, 3.0, "bottom"),
    "lichen_wall": ("LichenWall", 24, 30, 4, 3.0, "bottom"),
    "torch_bracket": ("TorchBracket", 22, 36, 4, 8.0, "center"),
    "skull_sconce": ("SkullSconce", 20, 32, 4, 8.0, "center"),
    "neon_guild_sign": ("NeonGuildSign", 74, 34, 3, 4.0, "center"),
}
STATIC = {
    "pipe_h": ("PipeH", 64, 14, "center"),
    "pipe_v": ("PipeV", 14, 64, "bottom"),
    "grate": ("Grate", 32, 20, "center"),
    "sign_hazard": ("SignHazard", 26, 34, "bottom"),
    "sign_arrow_brick": ("SignArrowBrick", 34, 26, "bottom"),
    "spray_arrow": ("SprayArrow", 34, 18, "center"),
    "spray_x": ("SprayX", 20, 20, "center"),
}


def anim_scene(name, node, w, h, n, fps, origin):
    s = '[gd_scene load_steps=3 format=3]\n\n'
    s += '[ext_resource type="Script" path="res://scripts/props/anim_prop.gd" id="1_prop"]\n'
    s += '[ext_resource type="Texture2D" path="res://assets/props/%s.png" id="2_sheet"]\n\n' % name
    s += '[node name="%s" type="Node2D"]\nscript = ExtResource("1_prop")\nsheet = ExtResource("2_sheet")\n' % node
    s += 'frame_size = Vector2i(%d, %d)\nframe_count = %d\nfps = %s\n' % (w, h, n, fps)
    if origin == "center":
        s += 'centered_origin = true\n'
    return s


def static_scene(name, node, w, h, origin):
    off = (-w / 2.0, -h / 2.0) if origin == "center" else (-w / 2.0, -float(h))
    s = '[gd_scene load_steps=2 format=3]\n\n'
    s += '[ext_resource type="Texture2D" path="res://assets/props/%s.png" id="1_tex"]\n\n' % name
    s += '[node name="%s" type="Node2D"]\n\n' % node
    s += '[node name="Sprite" type="Sprite2D" parent="."]\ntexture = ExtResource("1_tex")\ncentered = false\noffset = Vector2(%s, %s)\n' % (off[0], off[1])
    return s


if __name__ == "__main__":
    for name, args in ANIM.items():
        open(os.path.join(ROOT, "scenes", "props", name + ".tscn"), "w").write(anim_scene(name, *args))
    for name, args in STATIC.items():
        open(os.path.join(ROOT, "scenes", "props", name + ".tscn"), "w").write(static_scene(name, *args))
    print("wrote", len(ANIM) + len(STATIC), "scenes")
