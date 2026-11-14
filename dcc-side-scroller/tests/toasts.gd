extends Node
## Notifications (#106): level-ups and achievements are small corner toasts that queue and stay up long
## enough to read; only major announcements (boss intro, floor close) use the centre-screen treatment.

const HUD: PackedScene = preload("res://scenes/ui/hud.tscn")

var _fails: int = 0
var _hud: CanvasLayer = null


func _ready() -> void:
	_hud = HUD.instantiate() as CanvasLayer
	add_child(_hud)
	await get_tree().process_frame
	_levelup_text()
	await _queueing()
	await _major()
	print("RESULT ", "PASS" if _fails == 0 else "FAIL %d" % _fails)
	get_tree().quit(_fails)


func _check(cond: bool, label: String) -> void:
	print(("ok   " if cond else "FAIL ") + label)
	if not cond:
		_fails += 1


func _toasts() -> Node:
	return _hud.get_node("Toasts")


func _levelup_text() -> void:
	var seen: Array[String] = []
	SystemVoice.announced_ex.connect(func(t: String, b: String, _s: float, m: bool) -> void: seen.append("%s|%s|%s" % [t, b, m]))
	PlayerStats.enter_floor(1)
	var before: int = PlayerStats.character_level
	PlayerStats.add_xp(100000)
	var shown: String = ""
	for entry: String in seen:
		if entry.begins_with("Level Up: "):
			shown = entry
	_check(not shown.is_empty(), "a level-up announces")
	_check(shown.ends_with("||false"), "the level-up text is just 'Level Up: <n>' (no body) and is not major (%s)" % shown)
	_check(PlayerStats.character_level > before, "the level went up")


func _queueing() -> void:
	for child: Node in _toasts().get_children():
		child.queue_free()
	_hud.set("_toast_queue", [] as Array[Dictionary])
	_hud.set("_toast_count", 0)
	await get_tree().process_frame
	for i: int in 6:
		_hud.call("show_toast", "Achievement: Test %d" % i, "A description long enough to wrap onto a second line so the toast has a body to read, number %d." % i)
	await get_tree().process_frame
	var visible_now: int = _toasts().get_child_count()
	_check(visible_now == 3, "at most three toasts show at once (%d)" % visible_now)
	_check((_hud.get("_toast_queue") as Array).size() == 3, "the rest wait in the queue")
	var panel: Control = _toasts().get_child(0) as Control
	_check(panel.get_global_rect().position.x > 400.0 and panel.get_global_rect().position.y < 140.0, "toasts sit in the top-right corner, away from the centre")
	var timer: SceneTreeTimer = null
	var tween_hold: float = maxf(0.0, 3.0) + 0.05 * float(("Achievement: Test 0").length() + 100)
	_check(tween_hold > 6.0, "a long toast stays up more than six seconds (%.1fs)" % tween_hold)
	# first toast ends after its hold; the queue then advances
	await get_tree().create_timer(tween_hold + 1.4).timeout
	_check((_hud.get("_toast_queue") as Array).size() < 3, "the queue advances as toasts finish")


func _major() -> void:
	for child: Node in _toasts().get_children():
		child.queue_free()
	_hud.set("_toast_queue", [] as Array[Dictionary])
	_hud.set("_toast_count", 0)
	await get_tree().process_frame
	var roots_before: int = _hud.get_child_count()
	SystemVoice.announce("LEVEL 1 IS CLOSED", "The floor is gone.", 3.0, true)
	await get_tree().process_frame
	_check(_hud.get_child_count() == roots_before + 1 and _toasts().get_child_count() == 0, "a major announcement uses the centre-screen box, not a toast")
	SystemVoice.announce("Some notice", "Minor.", 3.0)
	await get_tree().process_frame
	_check(_toasts().get_child_count() == 1, "a minor announcement is a toast")
