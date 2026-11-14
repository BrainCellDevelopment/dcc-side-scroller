extends RefCounted

const AIM_OFFSET: Vector2 = Vector2(0.0, -12.0)


static func nearest(origin: Vector2, forward: Vector2, candidates: Array, max_range: float, arc_degrees: float) -> Node2D:
	var best: Node2D = null
	var best_distance: float = INF
	var half_arc: float = deg_to_rad(arc_degrees)
	var heading: float = forward.angle()
	for entry: Variant in candidates:
		var node: Node2D = entry as Node2D
		if not is_valid(node):
			continue
		var offset: Vector2 = node.global_position + AIM_OFFSET - origin
		var distance: float = offset.length()
		if distance > max_range or distance >= best_distance:
			continue
		if absf(angle_difference(heading, offset.angle())) > half_arc:
			continue
		best = node
		best_distance = distance
	return best


static func is_valid(node: Node2D) -> bool:
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree():
		return false
	if not node.visible:
		return false
	if node.has_method("is_dead") and bool(node.call("is_dead")):
		return false
	var script: Script = node.get_script()
	var state: Variant = node.get("state")
	if script is GDScript and state != null:
		var constants: Dictionary = (script as GDScript).get_script_constant_map()
		var states: Variant = constants.get("State")
		if states is Dictionary and states.has("DEAD") and int(state) == int(states["DEAD"]):
			return false
	return true
