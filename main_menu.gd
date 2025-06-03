extends Control

var file_dialog: FileDialog

func _ready() -> void:
	setup_file_dialog()

func setup_file_dialog() -> void:
	file_dialog = FileDialog.new()
	file_dialog.size = Vector2i(800, 600)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.json", "JSON Files")
	file_dialog.add_filter("*.txt", "Text Files")
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")

func _on_api_pressed() -> void:
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
		ApiManager.save_api_key_to_file()  # Save for persistence
		print("API Key loaded and saved successfully!")
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
