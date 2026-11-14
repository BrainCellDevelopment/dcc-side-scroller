extends RefCounted

const DIR: String = "res://assets/ui/items/"

static var _cache: Dictionary = {}


static func get_icon(item_id: String) -> Texture2D:
	if item_id.is_empty():
		return null
	if _cache.has(item_id):
		return _cache[item_id]
	var path: String = DIR + item_id + ".png"
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[item_id] = tex
	return tex
