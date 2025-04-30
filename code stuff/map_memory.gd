extends Node  # NOT Node2D

var unlocked_areas: Array = []

func unlock_area(area: String):
	if area not in unlocked_areas:
		unlocked_areas.append(area)
		print("🔓 Area unlocked:", area)

func is_area_unlocked(area: String) -> bool:
	return area in unlocked_areas
