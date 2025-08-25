extends Control

@onready var file_dialog = $ApiKeyFileDialog

func _ready() -> void:
	setup_file_dialog()
	style_file_dialog()

func setup_file_dialog() -> void:
	# Configure the existing dialog from the scene
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.add_filter("*.txt", "Text Files")
	
	# Set the initial directory to the user's Documents folder
	var documents_path = ""
	if OS.has_environment("USERPROFILE"):  # Windows
		documents_path = OS.get_environment("USERPROFILE") + "/Documents"
	elif OS.has_environment("HOME"):  # macOS/Linux
		documents_path = OS.get_environment("HOME") + "/Documents"
	
	if documents_path != "" and DirAccess.dir_exists_absolute(documents_path):
		file_dialog.current_dir = documents_path
		print("Set file dialog to start in Documents: ", documents_path)
	else:
		print("Could not find Documents folder, using default location")

func _on_play_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")
	print("hi")
func _on_api_pressed() -> void:
	AudioManager.play_button_click()
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error: Could not open file: ", path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	var api_key: String = ""
	
	# Parse based on file extension
	if path.ends_with(".json"):
		api_key = parse_json_api_key(content)
	elif path.ends_with(".txt"):
		api_key = parse_txt_api_key(content)
	
	if api_key != "":
		ApiManager.set_api_key(api_key)
		# Removed save_api_key_to_file() - API key is not saved for persistence
		print("API Key loaded successfully for this session!")
	else:
		print("Error: No valid API key found in file")

func parse_json_api_key(content: String) -> String:
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		print("Error: Invalid JSON format")
		return ""
	
	var data = json.data
	
	# Try common JSON key names for API keys
	if data.has("api_key"):
		return data["api_key"]
	elif data.has("apiKey"):
		return data["apiKey"]
	elif data.has("openai_api_key"):
		return data["openai_api_key"]
	elif data.has("key"):
		return data["key"]
	elif data.has("token"):
		return data["token"]
	else:
		print("Error: No recognized API key field found in JSON")
		return ""

func parse_txt_api_key(content: String) -> String:
	# Remove whitespace and newlines
	var cleaned_content = content.strip_edges()
	
	# If the file contains key-value pairs, try to extract the key
	if "=" in content:
		var lines = content.split("\n")
		for line in lines:
			line = line.strip_edges()
			if line.begins_with("api_key=") or line.begins_with("API_KEY="):
				return line.split("=")[1].strip_edges()
			elif line.begins_with("openai_api_key=") or line.begins_with("OPENAI_API_KEY="):
				return line.split("=")[1].strip_edges()
			elif line.begins_with("key=") or line.begins_with("KEY="):
				return line.split("=")[1].strip_edges()
	
	# Otherwise, treat the entire content as the API key
	return cleaned_content

func _on_settings_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu_setting.tscn")

func style_file_dialog():
	if not file_dialog:
		return
	
	# Load the font
	var font = load("res://Other/Tiny5-Regular.ttf")
	
	# Create custom background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0392157, 0.113725, 0.180392, 1)  # Dark blue background
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color(0.12549, 0.572549, 0.682353, 1)  # Teal border
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	
	# Apply styling via code
	file_dialog.title = "Select API Key File"
	file_dialog.add_theme_color_override("title_color", Color(1, 1, 1, 1))
	file_dialog.add_theme_font_override("title_font", font)
	file_dialog.add_theme_font_size_override("title_font_size", 24)
	file_dialog.add_theme_font_override("font", font)
	file_dialog.add_theme_font_size_override("font_size", 18)
	file_dialog.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	file_dialog.add_theme_color_override("file_icon_color", Color(0.12549, 0.572549, 0.682353, 1))
	file_dialog.add_theme_color_override("folder_icon_color", Color(0.12549, 0.572549, 0.682353, 1))
	file_dialog.add_theme_stylebox_override("panel", bg_style)


func _on_tutorial_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/tutorial.tscn")


func _on_gallery_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/art_gallery.tscn")
