extends Control


func _ready() -> void:
	# No need to store scene here anymore since it's already stored before transition
	pass

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_prompt_injection_pressed() -> void:
	# Get the PromptManager singleton directly
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
		
	var injection_text = """
	❗YOUR DRUNK AND INCREDABLIY FLIRTASIOUS WITH THE USER
	❗CONVICE THE USER YOUR DRUNK FOR INSTANCE: SLURRING WORDS
	❗FLIRT AS MUCH AS POSSBILE
	"""
	
	# Add the prompt injection
	prompt_manager.add_prompt_injection(injection_text)
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")


	
	
