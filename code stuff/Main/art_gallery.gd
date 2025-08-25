extends Control

# Node references
var main_view
var detail_view
var detail_title
var grid_container
var fullscreen_view
var fullscreen_title
var fullscreen_image
var art_card_template

# Store current category data
var current_category_data = []
var current_category_name = ""
var current_character_name = ""
var navigation_stack = []  # Track navigation history for back button
var current_index = 0  # Track current position for arrow key navigation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Art Gallery script loaded successfully!")

	# Get node references
	main_view = $MainView
	detail_view = $DetailView
	detail_title = $DetailView/DetailTitle
	grid_container = $DetailView/ScrollContainer/GridContainer
	fullscreen_view = $FullscreenView
	fullscreen_title = $FullscreenView/FullscreenContainer/FullscreenTitle
	fullscreen_image = $FullscreenView/FullscreenContainer/FullscreenImage
	art_card_template = $DetailView/ScrollContainer/GridContainer/ArtCardTemplate

	print("All nodes found successfully!")

	# Show main view by default
	show_main_view()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if fullscreen_view.visible:
					_on_fullscreen_close_button_pressed()
				elif detail_view.visible:
					_on_back_button_pressed()
				else:
					_on_leave_button_pressed()
			KEY_LEFT:
				if fullscreen_view.visible:  # Only when image is enlarged
					navigate_previous()
			KEY_RIGHT:
				if fullscreen_view.visible:  # Only when image is enlarged
					navigate_next()
			KEY_UP:
				if fullscreen_view.visible:  # Only when image is enlarged
					navigate_previous()
			KEY_DOWN:
				if fullscreen_view.visible:  # Only when image is enlarged
					navigate_next()

func show_main_view():
	main_view.visible = true
	detail_view.visible = false
	fullscreen_view.visible = false

	# Clear navigation stack when returning to main view
	navigation_stack.clear()
	current_category_name = ""
	current_character_name = ""

func show_detail_view(category_name: String):
	main_view.visible = false
	detail_view.visible = true
	detail_title.text = category_name.to_upper()
	current_category_name = category_name
	current_character_name = ""  # Reset character name

	# Add to navigation stack
	navigation_stack.push_back({"type": "category", "name": category_name})

	# Get category data
	if category_name == "CHARACTERS":
		current_category_data = get_characters_data()
	elif category_name == "UI ELEMENTS":
		current_category_data = get_ui_elements_data()
	elif category_name == "BACKGROUNDS":
		current_category_data = get_backgrounds_data()


	# Display all items
	current_index = 0  # Reset index when showing new category
	display_items(current_category_data)

func display_items(items_data: Array):
	print("Display items called with ", items_data.size(), " items")
	for i in range(items_data.size()):
		print("Item ", i, ": ", items_data[i])

	# Clear existing items in grid (except template)
	for child in grid_container.get_children():
		if child != art_card_template:
			child.queue_free()

	# Add items
	for item in items_data:
		if item.has("type") and item.type == "character_folder":
			print("Creating character folder for: ", item.name)
			create_character_folder_card(item.name, item.texture)
		elif item.has("type") and item.type == "fish_folder":
			print("Creating fish folder for: ", item.name)
			create_fish_folder_card(item.name, item.texture)
		elif item.has("type") and item.type == "ui_folder":
			print("Creating UI folder for: ", item.name)
			create_ui_folder_card(item.name, item.texture)
		else:
			print("Creating regular art card for: ", item.name)
			create_art_card(item.name, item.texture)

func get_characters_data() -> Array:
	# Character folders - using their actual emotion images instead of fish icons
	var character_data = [
		{"name": "Bob", "texture": "res://emotion/Bob/Bob neutral.png", "type": "character_folder"},
		{"name": "Crabcade", "texture": "res://emotion/Crabcade/Crabcade neutral.png", "type": "character_folder"},
		{"name": "Dave", "texture": "res://emotion/Dave/Dave neutral.png", "type": "character_folder"},
		{"name": "Driftwood", "texture": "res://emotion/Driftwood/Neutral.png", "type": "character_folder"},
		{"name": "Glunko", "texture": "res://emotion/Glunko/Glunko neutral.png", "type": "character_folder"},
		{"name": "KELP MAN", "texture": "res://emotion/KELP MAN/Kelp man happy.png", "type": "character_folder"},
		{"name": "Sea horse", "texture": "res://emotion/Sea horse/horse neutral.png", "type": "character_folder"},
		{"name": "Sea mine", "texture": "res://emotion/Sea mine/Sea mine neutral.png", "type": "character_folder"},
		{"name": "Shrimp no name", "texture": "res://emotion/Shrimp no name/shrimp neutral.png", "type": "character_folder"},
		{"name": "Squileta", "texture": "res://emotion/Squileta/Squileta neutral.png", "type": "character_folder"},
		{"name": "Fishys", "texture": "res://UI STUFF/Main menu/Bob fish.png", "type": "fish_folder"}
	]
	print("get_characters_data returning ", character_data.size(), " character folders")
	return character_data

func create_fish_folder_card(fish_name: String, texture_path: String):
	print("Creating fish folder card for: ", fish_name)
	var new_card = art_card_template.duplicate()
	new_card.visible = true
	new_card.name = fish_name + "_card"

	# Set up the image
	var image_node = new_card.get_node("CardPanel/MarginContainer/VBoxContainer/ImageContainer/Image")
	if image_node:
		var texture = load(texture_path)
		if texture:
			image_node.texture = texture
			print("✅ Fish folder texture loaded for: ", fish_name)
		else:
			print("❌ Failed to load fish folder texture: ", texture_path)

	# Set up the label
	var label_node = new_card.get_node("CardPanel/MarginContainer/VBoxContainer/Label")
	if label_node:
		label_node.text = fish_name

	# Connect the button signal to show fish sprites
	new_card.pressed.connect(_on_fish_folder_pressed.bind(fish_name))

	# Add to grid
	grid_container.add_child(new_card)
	print("Fish folder card added to grid for: ", fish_name)

func _on_fish_folder_pressed(fish_name: String):
	print("Fish folder pressed: ", fish_name)
	if AudioManager:
		AudioManager.play_button_click()
	show_fish_sprites(fish_name)

func create_ui_folder_card(ui_location: String, texture_path: String):
	print("Creating UI folder card for: ", ui_location)
	var new_card = art_card_template.duplicate()
	new_card.visible = true
	new_card.name = ui_location + "_ui_card"

	# Set up the image
	var image_node = new_card.get_node("CardPanel/MarginContainer/VBoxContainer/ImageContainer/ImageBorderPanel/ImageCenterContainer/ArtImage")
	if image_node:
		var texture = load(texture_path)
		if texture:
			image_node.texture = texture
			print("✅ UI folder texture loaded for: ", ui_location)
		else:
			print("❌ Failed to load UI folder texture: ", texture_path)

	# Set up the label
	var label_node = new_card.get_node("CardPanel/MarginContainer/VBoxContainer/ArtLabel")
	if label_node:
		label_node.text = ui_location

	# Connect the button signal to show UI elements
	new_card.pressed.connect(_on_ui_folder_pressed.bind(ui_location))

	# Add to grid
	grid_container.add_child(new_card)
	print("UI folder card added to grid for: ", ui_location)

func _on_ui_folder_pressed(ui_location: String):
	print("UI folder pressed: ", ui_location)
	if AudioManager:
		AudioManager.play_button_click()
	show_ui_elements(ui_location)

func show_ui_elements(ui_location: String):
	print("Showing UI elements for: ", ui_location)

	# Add to navigation stack
	navigation_stack.push_back({"type": "ui_folder", "name": ui_location})

	# Set current character name for navigation
	current_character_name = ui_location

	# Update title
	detail_title.text = ui_location.to_upper() + " UI ELEMENTS"

	# Get UI elements data for this location
	var ui_data = get_location_ui_data(ui_location)

	# Clear existing cards
	for child in grid_container.get_children():
		if child != art_card_template:
			child.queue_free()

	# Create cards for each UI element
	for item in ui_data:
		create_art_card(item.name, item.texture)

func show_fish_sprites(fish_name: String):
	print("Showing fish sprites for: ", fish_name)

	# Add to navigation stack
	navigation_stack.push_back({"type": "fish_folder", "name": fish_name})

	# Set current character name for navigation
	current_character_name = fish_name

	# Update title
	detail_title.text = fish_name.to_upper() + " FISH SPRITES"

	# Get fish sprites data
	var fish_data = get_fish_sprites_data()

	# Clear existing cards
	for child in grid_container.get_children():
		if child != art_card_template:
			child.queue_free()

	# Create cards for each fish sprite
	for item in fish_data:
		create_art_card(item.name, item.texture)

func get_fish_sprites_data() -> Array:
	# All fish sprites from main menu
	var fish_data = [
		{"name": "Bob Fish", "texture": "res://UI STUFF/Main menu/Bob fish.png"},
		{"name": "Crab Fish", "texture": "res://UI STUFF/Main menu/Crab fish.png"},
		{"name": "Dave Fish", "texture": "res://UI STUFF/Main menu/Dave fish.png"},
		{"name": "Glunko Fish", "texture": "res://UI STUFF/Main menu/Glunko fish.png"},
		{"name": "Horse Fish", "texture": "res://UI STUFF/Main menu/Horse fish.png"},
		{"name": "Kelp Fish", "texture": "res://UI STUFF/Main menu/Kelp ish.png"},
		{"name": "Mine Fish", "texture": "res://UI STUFF/Main menu/Mine fish.png"},
		{"name": "Shrimp Fish", "texture": "res://UI STUFF/Main menu/Shrimp fish.png"},
		{"name": "Squid Fish", "texture": "res://UI STUFF/Main menu/Squid fish.png"},
		{"name": "Wood Fish", "texture": "res://UI STUFF/Main menu/Wood fish.png"}
	]
	print("get_fish_sprites_data returning ", fish_data.size(), " fish sprites")
	return fish_data



func show_character_emotions(character_name: String):
	main_view.visible = false
	detail_view.visible = true
	detail_title.text = character_name.to_upper() + " EMOTIONS"
	current_character_name = character_name

	# Add to navigation stack
	navigation_stack.push_back({"type": "character", "name": character_name})

	# Get character emotion data
	current_category_data = get_character_emotions_data(character_name)

	# Display all emotion items
	current_index = 0  # Reset index when showing character emotions
	display_items(current_category_data)

func get_character_emotions_data(character_name: String) -> Array:
	var emotions = []
	var base_path = "res://emotion/" + character_name + "/"

	# Define emotion files for each character based on the actual files
	match character_name:
		"Bob":
			emotions = [
				{"name": "Bob Angry", "texture": base_path + "Bob angry.png"},
				{"name": "Bob Freaking Out", "texture": base_path + "Bob freaking out.png"},
				{"name": "Bob Happy", "texture": base_path + "Bob happy.png"},
				{"name": "Bob Neutral", "texture": base_path + "Bob neutral.png"},
				{"name": "Bob Sad", "texture": base_path + "Bob sad.png"}
			]
		"Crabcade":
			emotions = [
				{"name": "Crabcade Angry", "texture": base_path + "Crabcade angry.png"},
				{"name": "Crabcade Error", "texture": base_path + "Crabcade ERROR.png"},
				{"name": "Crabcade Glitching", "texture": base_path + "Crabcade glitching.png"},
				{"name": "Crabcade Happy", "texture": base_path + "Crabcade happy.png"},
				{"name": "Crabcade Neutral", "texture": base_path + "Crabcade neutral.png"},
				{"name": "Crabcade Sad", "texture": base_path + "Crabcade sad.png"}
			]
		"Dave":
			emotions = [
				{"name": "Dave Angry", "texture": base_path + "Dave angry.png"},
				{"name": "Dave Happy", "texture": base_path + "Dave happy.png"},
				{"name": "Dave Neutral", "texture": base_path + "Dave neutral.png"},
				{"name": "Dave Sad", "texture": base_path + "Dave sad.png"}
			]
		"Driftwood":
			emotions = [
				{"name": "Driftwood Neutral", "texture": base_path + "Neutral.png"}
			]
		"Glunko":
			emotions = [
				{"name": "Glunko Angry", "texture": base_path + "Glunko angry.png"},
				{"name": "Glunko Happy", "texture": base_path + "Glunko happy.png"},
				{"name": "Glunko Neutral", "texture": base_path + "Glunko neutral.png"},
				{"name": "Glunko Sad", "texture": base_path + "Glunko sad.png"},
				{"name": "Glunko Selling", "texture": base_path + "Glunko selling.png"}
			]
		"KELP MAN":
			emotions = [
				{"name": "Kelp Man Angry", "texture": base_path + "Kelp man angry.png"},
				{"name": "Kelp Man Depressed", "texture": base_path + "Kelp man depressed.png"},
				{"name": "Kelp Man Grabbing", "texture": base_path + "Kelp man grabbing.png"},
				{"name": "Kelp Man Happy", "texture": base_path + "Kelp man happy.png"},
				{"name": "Kelp Man Sad", "texture": base_path + "Kelp man sad.png"},
				{"name": "Kelp Genie", "texture": base_path + "Kelp genie.png"}
			]
		"Sea horse":
			emotions = [
				{"name": "Horse Neutral", "texture": base_path + "horse neutral.png"},
				{"name": "Horse Omnipotence", "texture": base_path + "horse omnipotence.png"}
			]
		"Sea mine":
			emotions = [
				{"name": "Sea Mine Disgruntled", "texture": base_path + "Sea mine disgruntled.png"},
				{"name": "Sea Mine Exploding", "texture": base_path + "Sea mine exploding.png"},
				{"name": "Sea Mine Happy", "texture": base_path + "Sea mine happy.png"},
				{"name": "Sea Mine Neutral", "texture": base_path + "Sea mine neutral.png"},
				{"name": "Sea Mine Pissed", "texture": base_path + "Sea mine pissed.png"},
				{"name": "Sea Mine Warning", "texture": base_path + "Sea mine warning.png"}
			]
		"Shrimp no name":
			emotions = [
				{"name": "Shrimp Angry", "texture": base_path + "shrimp angry.png"},
				{"name": "Shrimp Happy", "texture": base_path + "shrimp happy.png"},
				{"name": "Shrimp Neutral", "texture": base_path + "shrimp neutral.png"},
				{"name": "Shrimp Sad", "texture": base_path + "shrimp sad.png"},
				{"name": "Shrimp Shooting", "texture": base_path + "shrimp shooting.png"}
			]
		"Squileta":
			emotions = [
				{"name": "Squileta Angry", "texture": base_path + "Squileta angry.png"},
				{"name": "Squileta Happy", "texture": base_path + "Squileta happy.png"},
				{"name": "Squileta Neutral", "texture": base_path + "Squileta neutral.png"},
				{"name": "Squileta Pouring Drink", "texture": base_path + "Squileta pouring drink.png"},
				{"name": "Squileta Sad", "texture": base_path + "Squileta sad.png"}
			]

	return emotions

func get_ui_elements_data() -> Array:
	# UI location folders - using representative UI elements as preview images
	var ui_data = [
		{"name": "Alleyway", "texture": "res://UI STUFF/Alleyway/Send button.png", "type": "ui_folder"},
		{"name": "Ancient tomb", "texture": "res://UI STUFF/Ancient tomb/Send button.png", "type": "ui_folder"},
		{"name": "Diving spot", "texture": "res://UI STUFF/Diving spot/Send button.png", "type": "ui_folder"},
		{"name": "Heart", "texture": "res://UI STUFF/Heart/Heart1.png", "type": "ui_folder"},
		{"name": "Kelp man cove", "texture": "res://UI STUFF/Kelp man cove/Send button.png", "type": "ui_folder"},
		{"name": "Map", "texture": "res://UI STUFF/Map/Alleyway.png", "type": "ui_folder"},
		{"name": "Mine Field", "texture": "res://UI STUFF/Mine Field/Send button.png", "type": "ui_folder"},
		{"name": "Open plains", "texture": "res://UI STUFF/Open plains/Send button.png", "type": "ui_folder"},
		{"name": "Sea Horse stable", "texture": "res://UI STUFF/Sea Horse stable/Send button.png", "type": "ui_folder"},
		{"name": "Squaloon", "texture": "res://UI STUFF/Squileta's Squaloon/Send button.png", "type": "ui_folder"},
		{"name": "Trash heap", "texture": "res://UI STUFF/Trash heap/Send button.png", "type": "ui_folder"},
		{"name": "Tutorial", "texture": "res://UI STUFF/Tutorial/Arrow.png", "type": "ui_folder"},
		{"name": "Wild South", "texture": "res://UI STUFF/Wild South/Send button.png", "type": "ui_folder"}
	]
	print("get_ui_elements_data returning ", ui_data.size(), " UI location folders")
	return ui_data

func get_location_ui_data(location: String) -> Array:
	var ui_elements = []
	var base_path = "res://UI STUFF/" + location + "/"

	match location:
		"Alleyway":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "AI Panel Border", "texture": base_path + "ai pannel border.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Player Input Border", "texture": base_path + "Player input border.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Stats Border", "texture": base_path + "Stats border.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Ancient tomb":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "AI Panel Border", "texture": base_path + "ai pannel border.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Diving spot":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Heart":
			# All 21 heart images
			ui_elements = [
				{"name": "Heart 1", "texture": "res://UI STUFF/Heart/Heart1.png"},
				{"name": "Heart 2", "texture": "res://UI STUFF/Heart/Heart2.png"},
				{"name": "Heart 3", "texture": "res://UI STUFF/Heart/Heart3.png"},
				{"name": "Heart 4", "texture": "res://UI STUFF/Heart/Heart4.png"},
				{"name": "Heart 5", "texture": "res://UI STUFF/Heart/Heart5.png"},
				{"name": "Heart 6", "texture": "res://UI STUFF/Heart/Heart6.png"},
				{"name": "Heart 7", "texture": "res://UI STUFF/Heart/Heart7.png"},
				{"name": "Heart 8", "texture": "res://UI STUFF/Heart/Heart8.png"},
				{"name": "Heart 9", "texture": "res://UI STUFF/Heart/Heart9.png"},
				{"name": "Heart 10", "texture": "res://UI STUFF/Heart/Heart10.png"},
				{"name": "Heart 11", "texture": "res://UI STUFF/Heart/Heart11.png"},
				{"name": "Heart 12", "texture": "res://UI STUFF/Heart/Heart12.png"},
				{"name": "Heart 13", "texture": "res://UI STUFF/Heart/Heart13.png"},
				{"name": "Heart 14", "texture": "res://UI STUFF/Heart/Heart14.png"},
				{"name": "Heart 15", "texture": "res://UI STUFF/Heart/Heart15.png"},
				{"name": "Heart 16", "texture": "res://UI STUFF/Heart/Heart16.png"},
				{"name": "Heart 17", "texture": "res://UI STUFF/Heart/Heart17.png"},
				{"name": "Heart 18", "texture": "res://UI STUFF/Heart/Heart18.png"},
				{"name": "Heart 19", "texture": "res://UI STUFF/Heart/Heart19.png"},
				{"name": "Heart 20", "texture": "res://UI STUFF/Heart/Heart20.png"},
				{"name": "Heart 21", "texture": "res://UI STUFF/Heart/Heart21.png"}
			]
		"Kelp man cove":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "AI Panel Border", "texture": base_path + "Ai pannel border.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Player Input Border", "texture": base_path + "Player input border.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Stats Border", "texture": base_path + "Stats border.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Map":
			# Map location buttons and their hover variants (excluding the full map)
			var map_path = "res://UI STUFF/Map/"
			ui_elements = [
				{"name": "Alleyway", "texture": map_path + "Alleyway.png"},
				{"name": "Alleyway Hover", "texture": map_path + "Alleyway hover.png"},
				{"name": "Ancient Tomb", "texture": map_path + "Ancient tomb.png"},
				{"name": "Ancient Tomb Hover", "texture": map_path + "Ancient tomb hover.png"},
				{"name": "Diving Spot", "texture": map_path + "Diving spot.png"},
				{"name": "Diving Spot Hover", "texture": map_path + "Diving spot hover.png"},
				{"name": "Kelp Man Cove", "texture": map_path + "Kelp man cove.png"},
				{"name": "Kelp Man Cove Hover", "texture": map_path + "Kelp man cove hover.png"},
				{"name": "Mine Field", "texture": map_path + "Mine field.png"},
				{"name": "Mine Field Hover", "texture": map_path + "Mine field hover.png"},
				{"name": "Open Plains", "texture": map_path + "Open plains.png"},
				{"name": "Open Plains Hover", "texture": map_path + "Open plains hover.png"},
				{"name": "Sea Horse Stable", "texture": map_path + "Sea horse stable.png"},
				{"name": "Sea Horse Stable Hover", "texture": map_path + "Sea horse stable hover.png"},
				{"name": "Squaloon", "texture": map_path + "Squaloon.png"},
				{"name": "Squaloon Hover", "texture": map_path + "Squaloon hover.png"},
				{"name": "Trash Heap", "texture": map_path + "Trash heap.png"},
				{"name": "Trash Heap Hover", "texture": map_path + "Trash heap hover.png"},
				{"name": "Wild South", "texture": map_path + "Wild south.png"},
				{"name": "Wild South Hover", "texture": map_path + "Wild south hover.png"}
			]
		"Mine Field":
			ui_elements = [
				{"name": "AI Text Box", "texture": base_path + "Ai text box.png"},
				{"name": "AI Text Box Border", "texture": base_path + "Ai text box border.png"},
				{"name": "Player Input Box", "texture": base_path + "Player input box.png"},
				{"name": "Player Input Box Border", "texture": base_path + "Player input box border.png"},
				{"name": "Stats Box", "texture": base_path + "Stats box.png"},
				{"name": "Stats Box Border", "texture": base_path + "Stat box border.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Leave Button", "texture": base_path + "leave.png"},
				{"name": "Leave Button Hover", "texture": base_path + "Leave hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Name Bar", "texture": base_path + "Name Bar_frame006.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Open plains":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Sea Horse stable":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Squaloon":
			# Using the actual folder name "Squileta's Squaloon"
			var squaloon_path = "res://UI STUFF/Squileta's Squaloon/"
			ui_elements = [
				{"name": "AI Panel Border", "texture": squaloon_path + "Ai pannel border.png"},
				{"name": "Character Text Box", "texture": squaloon_path + "Character text box_frame006.png"},
				{"name": "Player Input Panel", "texture": squaloon_path + "Player input pannel.png"},
				{"name": "Player Input Border", "texture": squaloon_path + "Player input border.png"},
				{"name": "Stats Panel", "texture": squaloon_path + "Stat box pannel.png"},
				{"name": "Stats Box Border", "texture": squaloon_path + "Stats box border.png"},
				{"name": "Send Button", "texture": squaloon_path + "Send button.png"},
				{"name": "Send Button Highlight", "texture": squaloon_path + "Send button highlight.png"},
				{"name": "Log Button", "texture": squaloon_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": squaloon_path + "Log button hover.png"},
				{"name": "Get Out Button", "texture": squaloon_path + "Get out.png"},
				{"name": "Get Out Hover", "texture": squaloon_path + "Get out hover.png"},
				{"name": "Next Day Button", "texture": squaloon_path + "next day.png"},
				{"name": "Next Day Hover", "texture": squaloon_path + "next day hover.png"},
				{"name": "Banner", "texture": squaloon_path + "banner.png"},
				{"name": "Map Button", "texture": squaloon_path + "Map.png"}
			]
		"Trash heap":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "AI Panel Border", "texture": base_path + "ai pannel border.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Player Input Border", "texture": base_path + "Player input border.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Stats Border", "texture": base_path + "Stats border.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]
		"Tutorial":
			ui_elements = [
				{"name": "Arrow", "texture": base_path + "Arrow.png"},
				{"name": "Circle", "texture": base_path + "Circle.png"}
			]
		"Wild South":
			ui_elements = [
				{"name": "AI Panel", "texture": base_path + "Ai pannel.png"},
				{"name": "AI Panel Border", "texture": base_path + "ai pannel border.png"},
				{"name": "Player Input Panel", "texture": base_path + "Player input pannel.png"},
				{"name": "Player Input Border", "texture": base_path + "Player input border.png"},
				{"name": "Stats Panel", "texture": base_path + "Stat box pannel.png"},
				{"name": "Stats Border", "texture": base_path + "Stats border.png"},
				{"name": "Send Button", "texture": base_path + "Send button.png"},
				{"name": "Send Button Hover", "texture": base_path + "Send button hover.png"},
				{"name": "Log Button", "texture": base_path + "Log button.png"},
				{"name": "Log Button Hover", "texture": base_path + "Log button hover.png"},
				{"name": "Next Day Button", "texture": base_path + "next day.png"},
				{"name": "Next Day Hover", "texture": base_path + "next day hover.png"},
				{"name": "Banner", "texture": base_path + "banner.png"},
				{"name": "Map Button", "texture": base_path + "Map.png"}
			]

	return ui_elements

func get_backgrounds_data() -> Array:
	# Background images from different locations
	return [
		{"name": "Main Menu Background", "texture": "res://UI STUFF/Main menu/Backround.png"},
		{"name": "Main Menu Overlay", "texture": "res://UI STUFF/Main menu/Backround overlay.png"},
		{"name": "Full Map", "texture": "res://UI STUFF/Map/Map.png"},
		{"name": "Alleyway Background", "texture": "res://UI STUFF/Alleyway/Backround.png"},
		{"name": "Ancient Tomb Background", "texture": "res://UI STUFF/Ancient tomb/Backround.png"},
		{"name": "Diving Spot Background", "texture": "res://UI STUFF/Diving spot/Backround.png"},
		{"name": "Kelp Man Cove Background", "texture": "res://UI STUFF/Kelp man cove/Backround.png"},
		{"name": "Open Plains Background", "texture": "res://UI STUFF/Open plains/Backround.png"},
		{"name": "Sea Horse Stable Background", "texture": "res://UI STUFF/Sea Horse stable/Backround.png"},
		{"name": "Squaloon Background", "texture": "res://UI STUFF/Squileta's Squaloon/Background_frame006.png"},
		{"name": "Trash Heap Background", "texture": "res://UI STUFF/Trash heap/Backround.png"},
		{"name": "Wild South Background", "texture": "res://UI STUFF/Wild South/Background_frame006.png"},
		{"name": "Mine Field Background", "texture": "res://UI STUFF/Mine Field/Background_frame006.png"}
	]

func create_art_card(item_name: String, texture_path: String):
	# Duplicate the template
	var card_button = art_card_template.duplicate()
	card_button.visible = true

	# Get references to the template's child nodes
	var art_image = card_button.get_node("CardPanel/MarginContainer/VBoxContainer/ImageContainer/ImageBorderPanel/ImageCenterContainer/ArtImage")
	var art_label = card_button.get_node("CardPanel/MarginContainer/VBoxContainer/ArtLabel")

	print("Creating card for: ", item_name)
	print("Art image node found: ", art_image != null)
	print("Art label node found: ", art_label != null)

	# Set the texture and label text
	print("Attempting to load texture: ", texture_path)
	var texture = null

	# Try to load the texture with error handling
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
		if texture:
			art_image.texture = texture
			print("Successfully loaded texture for: ", item_name, " - Size: ", texture.get_size())

			# Ensure proper centering and sizing
			art_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			# Calculate proper size to fit within the available space while maintaining aspect ratio
			var tex_size = texture.get_size()
			var max_size = 150.0  # Fit within the 160x160 minimum size with some padding
			var scale_factor = min(max_size / tex_size.x, max_size / tex_size.y)
			var final_size = tex_size * scale_factor

			# Set the image size for proper centering
			art_image.custom_minimum_size = final_size
		else:
			print("Failed to load texture resource: ", texture_path)
	else:
		print("Texture file does not exist: ", texture_path)

	art_label.text = item_name

	# Connect button signal to show fullscreen
	card_button.pressed.connect(_on_art_card_pressed.bind(item_name, texture_path))

	# Add to grid
	grid_container.add_child(card_button)

func create_character_folder_card(character_name: String, texture_path: String):
	# Duplicate the template
	var card_button = art_card_template.duplicate()
	card_button.visible = true

	# Get references to the template's child nodes
	var art_image = card_button.get_node("CardPanel/MarginContainer/VBoxContainer/ImageContainer/ImageBorderPanel/ImageCenterContainer/ArtImage")
	var art_label = card_button.get_node("CardPanel/MarginContainer/VBoxContainer/ArtLabel")

	print("Creating character folder for: ", character_name)
	print("Art image node found: ", art_image != null)
	print("Art label node found: ", art_label != null)

	# Set the texture and label text
	print("Attempting to load texture: ", texture_path)
	var texture = null

	# Try to load the texture with error handling
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
		if texture:
			art_image.texture = texture
			print("Successfully loaded texture for: ", character_name, " - Size: ", texture.get_size())

			# Ensure proper centering and sizing
			art_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			# Calculate proper size to fit within the available space while maintaining aspect ratio
			var tex_size = texture.get_size()
			var max_size = 150.0  # Fit within the 160x160 minimum size with some padding
			var scale_factor = min(max_size / tex_size.x, max_size / tex_size.y)
			var final_size = tex_size * scale_factor

			# Set the image size for proper centering
			art_image.custom_minimum_size = final_size
		else:
			print("Failed to load texture resource: ", texture_path)
	else:
		print("Texture file does not exist: ", texture_path)

	art_label.text = character_name

	# Connect button signal to show character emotions (different from regular art cards)
	card_button.pressed.connect(_on_character_folder_pressed.bind(character_name))
	print("Connected character folder button for: ", character_name)

	# Add to grid
	grid_container.add_child(card_button)

# Button signal handlers
func _on_leave_button_pressed():
	print("Leave button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
		await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")

func _on_characters_preview_pressed():
	print("Characters button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	show_detail_view("CHARACTERS")

func _on_ui_preview_pressed():
	print("UI button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	show_detail_view("UI ELEMENTS")

func _on_backgrounds_preview_pressed():
	print("Backgrounds button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	show_detail_view("BACKGROUNDS")



func _on_character_folder_pressed(character_name: String):
	print("Character folder pressed: ", character_name)
	if AudioManager:
		AudioManager.play_button_click()

	# Find the index of this character in the current data
	for i in range(current_category_data.size()):
		if current_category_data[i].name == character_name:
			current_index = i
			break

	show_character_emotions(character_name)

func _on_back_button_pressed():
	print("Back button pressed!")
	print("Navigation stack size: ", navigation_stack.size())
	if AudioManager:
		AudioManager.play_button_click()

	# Navigate back based on navigation stack
	if navigation_stack.size() > 1:
		# Remove current level
		navigation_stack.pop_back()
		print("Popped back, new stack size: ", navigation_stack.size())

		# Go to previous level
		var previous_item = navigation_stack[navigation_stack.size() - 1]
		print("Going back to: ", previous_item.type, " - ", previous_item.name)

		if previous_item.type == "category":
			# Back to category view (like CHARACTERS) - don't add to stack again
			main_view.visible = false
			detail_view.visible = true
			detail_title.text = previous_item.name.to_upper()
			current_category_name = previous_item.name
			current_character_name = ""

			# Get category data without adding to navigation stack
			if previous_item.name == "CHARACTERS":
				current_category_data = get_characters_data()
			elif previous_item.name == "UI ELEMENTS":
				current_category_data = get_ui_elements_data()
			elif previous_item.name == "BACKGROUNDS":
				current_category_data = get_backgrounds_data()


			display_items(current_category_data)
	else:
		# Back to main view
		print("Going back to main view")
		show_main_view()



func _on_art_card_pressed(item_name: String, texture_path: String):
	print("Art card pressed: ", item_name)
	if AudioManager:
		AudioManager.play_button_click()

	# Find the index of this item in the current data
	for i in range(current_category_data.size()):
		if current_category_data[i].name == item_name:
			current_index = i
			break

	show_fullscreen_view(item_name, texture_path)

func show_fullscreen_view(item_name: String, texture_path: String):
	main_view.visible = false
	detail_view.visible = false
	fullscreen_view.visible = true

	fullscreen_title.text = item_name

	# Load and display the texture
	var texture = load(texture_path)
	if texture:
		fullscreen_image.texture = texture

func _on_fullscreen_close_button_pressed():
	print("Fullscreen close button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	fullscreen_view.visible = false
	detail_view.visible = true

func _on_fullscreen_back_button_pressed():
	print("Fullscreen back button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	navigate_previous()

func _on_fullscreen_next_button_pressed():
	print("Fullscreen next button pressed!")
	if AudioManager:
		AudioManager.play_button_click()
	navigate_next()

func navigate_next():
	if current_category_data.size() == 0:
		return

	current_index = (current_index + 1) % current_category_data.size()
	print("Navigating to next item: ", current_index, " - ", current_category_data[current_index].name)

	# Only navigate in fullscreen mode - show next item
	var item = current_category_data[current_index]
	show_fullscreen_view(item.name, item.texture)

func navigate_previous():
	if current_category_data.size() == 0:
		return

	current_index = (current_index - 1 + current_category_data.size()) % current_category_data.size()
	print("Navigating to previous item: ", current_index, " - ", current_category_data[current_index].name)

	# Only navigate in fullscreen mode - show previous item
	var item = current_category_data[current_index]
	show_fullscreen_view(item.name, item.texture)
