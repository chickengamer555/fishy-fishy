extends Node2D

# Node references
@onready var map = $Map
@onready var shader = $ColorRect2
@onready var settings = $Settings
func _on_bar_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Squileta.tscn")
	MapMemory.set_location("squaloon")

func _on_kelp_man_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/kelp_man.tscn")
	MapMemory.set_location("kelp man cove")

func _ready():
	print("🗓️ Days: %d, Actions: %d" % [GameState.days_left, GameState.actions_left])
	
	# Debug: Print all child node names
	print("🔍 Map child nodes:")
	for child in get_children():
		print("  - ", child.name)
	
	# Initialize random starting location if no areas are unlocked
	print("🎲 Current unlocked areas before init: ", MapMemory.unlocked_areas)
	if MapMemory.unlocked_areas.is_empty():
		print("🎲 No areas unlocked, initializing random location...")
		MapMemory.initialize_random_starting_location()
	
	# Update visibility based on unlocked areas
	update_location_visibility()
	
	# Safety check: ensure at least one location is visible
	ensure_at_least_one_location_visible()
	
	# Print current unlocked areas for debugging
	print("🗺️ Final unlocked areas: ", MapMemory.unlocked_areas)
	map.visible = true
	shader.visible = true
	settings.visible = true

func update_location_visibility():
	# Map the node names to their corresponding area names
	var location_mapping = {
		"kelp_man_cove": "kelp man cove",
		"squaloon": "squaloon",
		"wild_south": "wild south",
		# Support both correct and misspelled node names
		"mine_field": "mine field",
		"mine_feild": "mine field",
		"trash_heap": "trash heap",
		"alleyway": "alleyway",
		"sea_horse_stable": "sea horse stable",
		"ancient_tomb": "ancient tomb",
		"open_plains": "open plains",
		"diving_spot": "diving spot"
	}

	# Set visibility based on unlocked areas
	for child in get_children():
		var node_name = child.name.to_lower()
		print("🔍 Checking node: ", node_name)
		
		if node_name in location_mapping:
			var area_name = location_mapping[node_name]
			var is_unlocked = area_name in MapMemory.unlocked_areas
			child.visible = is_unlocked
			print("  - Mapped to area: ", area_name, " | Unlocked: ", is_unlocked, " | Visible: ", child.visible)
		else:
			# For other nodes, try direct name matching
			var area_name = node_name
			var is_unlocked = area_name in MapMemory.unlocked_areas
			child.visible = is_unlocked
			print("  - Direct mapping: ", area_name, " | Unlocked: ", is_unlocked, " | Visible: ", child.visible)

func ensure_at_least_one_location_visible():
	# Check if any location nodes are currently visible
	var visible_locations = []
	var location_nodes = []
	
	for child in get_children():
		var node_name = child.name.to_lower()
		# Only include locations that can be force-unlocked (exclude ancient_tomb and kelp_man_cove from random visibility)
		if node_name in ["squaloon", "wild_south", "mine_field", "trash_heap", "alleyway", "sea_horse_stable", "open_plains", "diving_spot"]:
			location_nodes.append(child)
			if child.visible:
				visible_locations.append(child)
	
	print("🔍 Visible locations: ", visible_locations.size(), " / ", location_nodes.size())
	
	# If no locations are visible, force one to be visible
	if visible_locations.size() == 0 and location_nodes.size() > 0:
		print("🚨 No locations visible! Forcing one to be visible...")
		
		# Randomly pick one location to make visible
		var random_index = randi() % location_nodes.size()
		var chosen_location = location_nodes[random_index]
		chosen_location.visible = true
		
		# Also unlock the corresponding area (only for locations that can be force-unlocked)
		var location_mapping = {
			"squaloon": "squaloon",
			"wild_south": "wild south",
			"mine_field": "mine field",
			"trash_heap": "trash heap",
			"alleyway": "alleyway",
			"sea_horse_stable": "sea horse stable",
			"open_plains": "open plains",
			"diving_spot": "diving spot"
		}
		
		var node_name = chosen_location.name.to_lower()
		if node_name in location_mapping:
			var area_name = location_mapping[node_name]
			MapMemory.unlock_area(area_name)
			print("🎲 Forced location visible: ", chosen_location.name, " (", area_name, ")")
	
	# Final check
	for child in get_children():
		if child.name.to_lower() in ["kelp_man_cove", "squaloon", "wild_south", "mine_field", "trash_heap", "alleyway", "sea_horse_stable", "ancient_tomb", "open_plains", "diving_spot"]:
			print("🗺️ Final: ", child.name, " visible: ", child.visible)



func _on_wild_south_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/shrimp_with_no_name.tscn")
	MapMemory.set_location("wild south")


# Note: Function name kept to match existing signal connection in the scene
func _on_mine_field_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/sea_mine.tscn")
	MapMemory.set_location("mine field")
	# Ensure the area is unlocked when navigating directly
	MapMemory.unlock_area("mine field")


func _on_trash_heap_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Crabcade.tscn")
	MapMemory.set_location("trash heap")


func _on_alleyway_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Glunko.tscn")
	MapMemory.set_location("alleyway")

func _on_sea_horse_stable_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Sea horse.tscn")
	MapMemory.set_location("sea horse stable")


func _on_ancient_tomb_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/drift_wood.tscn")
	MapMemory.set_location("ancient tomb")


func _on_open_plains_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Bob.tscn")
	MapMemory.set_location("open plains")


func _on_diving_spot_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Characters/Dave.tscn")
	MapMemory.set_location("diving spot")


func _on_settings_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.2).timeout
	# Store current scene before transitioning
	var settings_script = load("res://code stuff/Main/setting.gd")
	settings_script.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://Scene stuff/Main/setting.tscn")
