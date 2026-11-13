extends RefCounted


static func build_frames(texture: Texture2D, frame_size: Vector2i, animations: Dictionary) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for key: Variant in animations:
		var anim_name: StringName = StringName(str(key))
		var info: Dictionary = animations[key]
		var row: int = int(info.get("row", 0))
		var count: int = int(info.get("count", 1))
		var fps: float = float(info.get("fps", 8.0))
		var loop: bool = bool(info.get("loop", true))
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, fps)
		frames.set_animation_loop(anim_name, loop)
		for index: int in count:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				float(index * frame_size.x),
				float(row * frame_size.y),
				float(frame_size.x),
				float(frame_size.y)
			)
			frames.add_frame(anim_name, atlas)
	return frames


static func make_sprite(texture: Texture2D, frame_size: Vector2i, animations: Dictionary) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = build_frames(texture, frame_size, animations)
	sprite.centered = false
	sprite.offset = Vector2(-float(frame_size.x) * 0.5, -float(frame_size.y))
	return sprite
