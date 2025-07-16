extends Node

# Simple manual unlock script - attach to any scene and call from _ready()
func _ready():
	# Wait a frame to ensure MapMemory is initialized
	await get_tree().process_frame
	
	# Manual unlock for testing
	print("🔓 Manual unlock test starting...")
	force_unlock_all_locations()

func force_unlock_all_locations():
	print("🔓 Forcing unlock of all locations...")
	
	# Unlock the main locations
	MapMemory.unlock_area("squaloon")
	MapMemory.unlock_area("kelp man cove")
	
	print("🗺️ Unlocked areas: ", MapMemory.unlocked_areas)
	print("✅ All locations should now be visible on the map!")

# Call this function from the debug console if needed
func manual_unlock():
	force_unlock_all_locations()

# Test specific area unlock
func unlock_area_test(area_name: String):
	print("🔓 Testing unlock of area: ", area_name)
	MapMemory.unlock_area(area_name)
	print("🗺️ Current unlocked areas: ", MapMemory.unlocked_areas) 