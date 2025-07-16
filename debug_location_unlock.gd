extends Node

# Debug script to help diagnose location unlocking issues
# Usage: Attach this to any scene and call debug_location_system()

func debug_location_system():
	print("=== LOCATION UNLOCK DEBUG ===")
	
	# Check MapMemory state
	print("🗺️ MapMemory.unlocked_areas: ", MapMemory.unlocked_areas)
	print("🗺️ MapMemory.current_location: ", MapMemory.get_location())
	
	# Check character known areas
	var kelp_man_scene = get_node_or_null("/root/KelpMan")
	var squiletta_scene = get_node_or_null("/root/Squiletta")
	
	# Test string matching
	print("\n=== STRING MATCHING TEST ===")
	var test_reply = "Well now, sugar! There's my squaloon here and that kelp fella's cove over yonder."
	var known_areas = ["squaloon", "kelp man cove"]
	
	print("Test reply: '", test_reply, "'")
	print("Known areas: ", known_areas)
	
	for area in known_areas:
		var area_in_reply = area in test_reply.to_lower()
		print("Area '", area, "' found in reply: ", area_in_reply)
		
		if area_in_reply:
			print("  -> This should unlock '", area, "'")
			# Test unlock
			MapMemory.unlock_area(area)
	
	print("\n=== FINAL STATE ===")
	print("🗺️ MapMemory.unlocked_areas after test: ", MapMemory.unlocked_areas)

# Manual unlock function for testing
func force_unlock_location(area_name: String):
	print("🔓 Force unlocking area: ", area_name)
	MapMemory.unlock_area(area_name)
	print("🗺️ Unlocked areas: ", MapMemory.unlocked_areas)

# Test the actual check_for_area_mentions function
func test_area_mention_detection(reply: String):
	print("=== TESTING AREA MENTION DETECTION ===")
	print("Reply: '", reply, "'")
	
	var known_areas = ["squaloon", "kelp man cove"]
	
	for area in known_areas:
		var area_in_reply = area in reply.to_lower()
		var area_unlocked = MapMemory.is_area_unlocked(area)
		print("Area '", area, "' in reply: ", area_in_reply, " | Already unlocked: ", area_unlocked)
		
		if area_in_reply and not area_unlocked:
			MapMemory.unlock_area(area)
			print("✅ UNLOCKED area '", area, "' on map!") 