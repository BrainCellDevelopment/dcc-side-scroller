extends RefCounted
## Course layout for the Goblin Copper Chopper ride (#69). Every position is a distance
## along the track in pixels; the ride converts it to the world. Tune the ride here.

const LENGTH: float = 9800.0
const GAP_MARGIN: float = 14.0
const CHECKPOINTS: Array[float] = [0.0, 2500.0, 5000.0, 7500.0]
const GAPS: Array = [
	[900.0, 1000.0], [2100.0, 2200.0], [3350.0, 3460.0], [4600.0, 4700.0],
	[5900.0, 6000.0], [7150.0, 7260.0], [8500.0, 8600.0],
]
const STICKERS: Array[float] = [620.0, 1300.0, 1750.0, 2700.0, 3900.0, 5100.0, 5500.0, 6500.0, 7700.0, 9000.0]
const BARRICADES: Array[float] = [1500.0, 3000.0, 4300.0, 6300.0, 8000.0]
const LLAMAS: Array[float] = [2500.0, 4000.0, 5700.0, 7400.0, 8900.0]
const VALVES: Array[float] = [1900.0, 3700.0, 5300.0, 7000.0]
## [distance, height above the ground]
const COAL: Array = [
	[500.0, 0.0], [1250.0, 0.0], [2050.0, 70.0], [2650.0, 0.0], [3600.0, 0.0], [4100.0, 70.0],
	[4900.0, 0.0], [5400.0, 0.0], [6200.0, 70.0], [6900.0, 0.0], [7500.0, 0.0], [8100.0, 70.0],
	[8750.0, 0.0],
]
const ARROW_AT: float = 9920.0

const LEVEL_SCENE: String = "res://scenes/level01.tscn"
## Where Carl lands after finishing: the Level 1 checkpoint just before the Swine arena.
const RETURN_INDEX: int = 5
const RETURN_POSITION: Vector2 = Vector2(1568.0, 304.0)
const RETURN_STAGE: int = 5


static func in_gap(distance: float) -> bool:
	for gap: Array in GAPS:
		if distance > float(gap[0]) + GAP_MARGIN and distance < float(gap[1]) - GAP_MARGIN:
			return true
	return false


static func gap_start_before(distance: float) -> float:
	var start: float = 0.0
	for gap: Array in GAPS:
		if float(gap[0]) <= distance:
			start = float(gap[0])
	return start


static func last_checkpoint(distance: float) -> float:
	var best: float = 0.0
	for cp: float in CHECKPOINTS:
		if cp <= distance:
			best = cp
	return best
