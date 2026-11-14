extends Node
## Stand-in for the HUD in boss_arena_test: records every banner the boss framework asks for.

var banners: Array[String] = []


func show_banner(text: String, _seconds: float = 2.0) -> void:
	banners.append(text)
