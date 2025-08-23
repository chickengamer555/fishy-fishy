extends Node2D

# Node references
@onready var map = $Map
@onready var shader = $ColorRect2
@onready var settings = $Settings
@onready var label = $Label
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

	# First set visibility without animation
	set_initial_visibility()

	# Safety check: ensure at least one location is visible
	ensure_at_least_one_location_visible()

	# Print current unlocked areas for debugging
	print("🗺️ Final unlocked areas: ", MapMemory.unlocked_areas)
	map.visible = true
	shader.visible = true
	settings.visible = true
	label.visible = true

	# Now animate in any visible buttons after a short delay
	await get_tree().create_timer(0.1).timeout
	animate_visible_buttons()

func set_initial_visibility():
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
			var is_newly_unlocked = MapMemory.is_newly_unlocked(area_name)

			if is_unlocked:
				child.visible = true
				if is_newly_unlocked:
					child.modulate.a = 0.0  # Start transparent for animation
				else:
					child.modulate.a = 1.0  # Already unlocked, show normally
			else:
				child.visible = false
			print("  - Mapped to area: ", area_name, " | Unlocked: ", is_unlocked, " | Newly unlocked: ", is_newly_unlocked)
		else:
			# For other nodes, try direct name matching
			var area_name = node_name
			var is_unlocked = area_name in MapMemory.unlocked_areas
			var is_newly_unlocked = MapMemory.is_newly_unlocked(area_name)

			if is_unlocked:
				child.visible = true
				if is_newly_unlocked:
					child.modulate.a = 0.0  # Start transparent for animation
				else:
					child.modulate.a = 1.0  # Already unlocked, show normally
			else:
				child.visible = false
			print("  - Direct mapping: ", area_name, " | Unlocked: ", is_unlocked, " | Newly unlocked: ", is_newly_unlocked)

func ensure_at_least_one_location_visible():
	# Check if any location nodes are currently visible
	var visible_locations = []
	var location_nodes = []
	
	for child in get_children():
		var node_name = child.name.to_lower()
		# Only include safe locations that can be force-unlocked (exclude softlock locations and ancient_tomb)
		if node_name in ["kelp_man_cove", "wild_south", "trash_heap", "alleyway", "sea_horse_stable", "open_plains", "diving_spot"]:
			location_nodes.append(child)
			if child.visible:
				visible_locations.append(child)
	
	print("🔍 Visible locations: ", visible_locations.size(), " / ", location_nodes.size())
	
	# If no locations are visible, force one to be visible
	if visible_locations.size() == 0 and location_nodes.size() > 0:
		print("🚨 No locations visible! Forcing one to be visible...")

		# Define safe starting locations (excluding softlock locations)
		var safe_locations = []
		var safe_location_mapping = {
			"kelp_man_cove": "kelp man cove",
			"wild_south": "wild south",
			"trash_heap": "trash heap",
			"alleyway": "alleyway",
			"sea_horse_stable": "sea horse stable",
			"open_plains": "open plains",
			"diving_spot": "diving spot"
		}

		# Find safe location nodes
		for child in location_nodes:
			var node_name = child.name.to_lower()
			if node_name in safe_location_mapping:
				safe_locations.append(child)

		# Pick a random safe location, or fallback to any location if no safe ones found
		var chosen_location
		if safe_locations.size() > 0:
			var random_index = randi() % safe_locations.size()
			chosen_location = safe_locations[random_index]
		else:
			var random_index = randi() % location_nodes.size()
			chosen_location = location_nodes[random_index]

		chosen_location.visible = true

		# Also unlock the corresponding area (only for safe locations)
		var location_mapping = safe_location_mapping
		
		var node_name = chosen_location.name.to_lower()
		if node_name in location_mapping:
			var area_name = location_mapping[node_name]
			MapMemory.unlock_area(area_name)
			print("🎲 Forced location visible: ", chosen_location.name, " (", area_name, ")")
	
	# Final check
	for child in get_children():
		if child.name.to_lower() in ["kelp_man_cove", "squaloon", "wild_south", "mine_field", "trash_heap", "alleyway", "sea_horse_stable", "ancient_tomb", "open_plains", "diving_spot"]:
			print("🗺️ Final: ", child.name, " visible: ", child.visible)

func animate_visible_buttons():
	# Map the node names to their corresponding area names
	var location_mapping = {
		"kelp_man_cove": "kelp man cove",
		"squaloon": "squaloon",
		"wild_south": "wild south",
		"mine_field": "mine field",
		"mine_feild": "mine field",
		"trash_heap": "trash heap",
		"alleyway": "alleyway",
		"sea_horse_stable": "sea horse stable",
		"ancient_tomb": "ancient tomb",
		"open_plains": "open plains",
		"diving_spot": "diving spot"
	}

	# Find all newly unlocked location buttons and animate them
	for child in get_children():
		var node_name = child.name.to_lower()

		# Check if this is a location button that's newly unlocked
		if node_name in location_mapping:
			var area_name = location_mapping[node_name]
			if MapMemory.is_newly_unlocked(area_name) and child.visible:
				animate_button_fade_in(child, area_name)
		elif node_name in ["kelp_man_cove", "squaloon", "wild_south", "mine_field", "trash_heap", "alleyway", "sea_horse_stable", "ancient_tomb", "open_plains", "diving_spot"]:
			if MapMemory.is_newly_unlocked(node_name) and child.visible:
				animate_button_fade_in(child, node_name)

func animate_button_fade_in(button: Node, area_name: String):
	# Create simple fade-in animation (button is already transparent)
	var tween = create_tween()

	# Just fade in the button - no scaling or other effects
	tween.tween_property(button, "modulate:a", 1.0, 1.2)  # Made it slower and more visible

	# Mark as seen after animation completes
	await tween.finished
	MapMemory.mark_area_as_seen(area_name)

	print("✨ Animated fade-in for newly unlocked area: ", area_name)



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
