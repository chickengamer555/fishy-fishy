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

func initialize_random_starting_location():
	# Define all possible starting locations
	var possible_locations = ["kelp man cove", "squaloon", "wild south", "mine field", "trash heap", "alleyway"]
	
	# Randomly choose one to start with
	var random_index = randi() % possible_locations.size()
	var starting_location = possible_locations[random_index]
	
	# Unlock the random starting location
	unlock_area(starting_location)
	print("🎲 Random starting location: ", starting_location)
