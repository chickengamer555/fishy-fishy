extends Node  # NOT Node2D

var unlocked_areas: Array = []

func unlock_area(area: String):
	if area not in unlocked_areas:
		unlocked_areas.append(area)
		print("🔓 Area unlocked:", area)

func is_area_unlocked(area: String) -> bool:
	return area in unlocked_areas

var current_location: String = "unknown"

func set_location(loc: String):
	current_location = loc
	print("📍 Current location set to:", current_location)

func get_location() -> String:
	return current_location

func reset():
	unlocked_areas.clear()
	current_location = "unknown"
	print("🔄 Map memory reset")
