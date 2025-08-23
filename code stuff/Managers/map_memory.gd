extends Node  # NOT Node2D

var unlocked_areas: Array = []
var newly_unlocked_areas: Array = []  # Track areas unlocked this session for animation

func unlock_area(area: String):
	if area not in unlocked_areas:
		unlocked_areas.append(area)
		newly_unlocked_areas.append(area)  # Mark as newly unlocked for animation
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
	newly_unlocked_areas.clear()
	current_location = "unknown"
	print("🔄 Map memory reset")

func mark_area_as_seen(area: String):
	# Remove area from newly unlocked list once it's been animated
	if area in newly_unlocked_areas:
		newly_unlocked_areas.erase(area)

func is_newly_unlocked(area: String) -> bool:
	return area in newly_unlocked_areas

func initialize_random_starting_location():
	# Define all possible starting locations (excluding softlock locations and ancient tomb)
	# Removed squaloon and mine field to prevent softlocks, added back kelp man cove and sea horse stable
	var possible_locations = ["kelp man cove", "sea horse stable", "wild south", "trash heap", "alleyway"]

	# Randomly choose one to start with
	var random_index = randi() % possible_locations.size()
	var starting_location = possible_locations[random_index]

	# Unlock the random starting location
	unlock_area(starting_location)
	print("🎲 Random starting location: ", starting_location)
