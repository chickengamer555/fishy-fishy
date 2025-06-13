extends Node

# Store the current prompt injection
var current_injection: String = ""
var has_active_injection: bool = false

func _ready() -> void:
	pass

func add_prompt_injection(content: String) -> void:
	current_injection = content
	has_active_injection = true
	print("Prompt injection added: ", content)

func get_prompt_injection(character_name: String) -> String:
	return current_injection

func has_injection() -> bool:
	return has_active_injection

func clear_prompt_injection() -> void:
	current_injection = ""
	has_active_injection = false
	print("Prompt injection cleared") 
