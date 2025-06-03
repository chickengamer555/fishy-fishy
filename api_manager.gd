extends Node

var api_key: String = ""

func set_api_key(key: String) -> void:
	api_key = key
	print("API key stored: ", api_key.substr(0, min(8, api_key.length())) + "...")

func get_api_key() -> String:
	return api_key

func has_api_key() -> bool:
	return api_key != ""

func clear_api_key() -> void:
	api_key = ""
	print("API key cleared")

# Save API key to user data (optional - for persistence)
func save_api_key_to_file() -> void:
	var config = ConfigFile.new()
	config.set_value("api", "key", api_key)
	config.save("user://api_config.cfg")

# Load API key from user data (optional - for persistence)
func load_api_key_from_file() -> bool:
	var config = ConfigFile.new()
	var err = config.load("user://api_config.cfg")
	if err == OK:
		api_key = config.get_value("api", "key", "")
		return api_key != ""
	return false 
