extends Node

# Store the current prompt injection
var current_injection: String = ""
var has_active_injection: bool = false
var active_prompt_name: String = ""  # Track which prompt is currently active

func _ready() -> void:
	pass

func add_prompt_injection(content: String, prompt_name: String) -> void:
	# If there's already an active prompt, clear it first
	if has_active_injection:
		clear_prompt_injection()
	
	current_injection = content
	has_active_injection = true
	active_prompt_name = prompt_name
	print("Prompt injection added: ", prompt_name)

func get_prompt_injection(String):
	return current_injection

func has_injection() -> bool:
	return has_active_injection

func get_active_prompt_name() -> String:
	return active_prompt_name

func clear_prompt_injection() -> void:
	current_injection = ""
	has_active_injection = false
	active_prompt_name = ""
	print("Prompt injection cleared") 
