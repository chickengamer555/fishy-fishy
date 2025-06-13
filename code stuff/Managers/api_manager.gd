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

# Removed save_api_key_to_file and load_api_key_from_file functions
# API key now needs to be loaded fresh each session 
