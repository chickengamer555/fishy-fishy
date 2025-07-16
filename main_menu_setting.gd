extends Control

var prompt_buttons = {}

@onready var master_slider = $VBoxContainer/MasterVolume/HSlider
@onready var music_slider = $VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider = $VBoxContainer/SFXVolume/HSlider

func _ready() -> void:
	# Store references to prompt buttons
	prompt_buttons["dyslexia"] = $VBoxContainer/Dyslexia_mode
	prompt_buttons["drunk"] = $VBoxContainer/Drunk_mode
	
	# Connect volume sliders to their respective functions
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		master_slider.value = AudioManager.get_master_volume()
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		music_slider.value = AudioManager.get_music_volume()
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_slider.value = AudioManager.get_sfx_volume()
	
	# Update button states based on current active prompt
	update_button_states()

func _on_master_volume_changed(value: float):
	AudioManager.set_master_volume(value)

func _on_music_volume_changed(value: float):
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float):
	AudioManager.set_sfx_volume(value)

func update_button_states() -> void:
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		return
		
	var active_prompt = prompt_manager.get_active_prompt_name()
	
	# Update all buttons to show inactive state
	for button_name in prompt_buttons:
		var button = prompt_buttons[button_name]
		button.text = button_name.to_upper() + " MODE"
		button.modulate = Color(1, 1, 1)  # Normal color
	
	# If there's an active prompt, update its button
	if active_prompt != "":
		var active_button = prompt_buttons.get(active_prompt)
		if active_button:
			active_button.text = active_prompt.to_upper() + " MODE [ACTIVE]"
			active_button.modulate = Color(0.5, 1, 0.5)  # Green tint for active

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")

func _on_prompt_injection_pressed() -> void:
	AudioManager.play_switch_sound()
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
	
	# Check if this prompt is already active - if so, deactivate it
	if prompt_manager.get_active_prompt_name() == "drunk":
		prompt_manager.clear_prompt_injection()
		print("Deactivated drunk mode prompt injection")
		
		# Update ALL AI characters' system prompts to remove injection
		var ai_characters = get_tree().get_nodes_in_group("ai_character")
		for ai_char in ai_characters:
			if ai_char.has_method("build_system_prompt"):
				if ai_char.message_history.size() > 0:
					ai_char.message_history[0]["content"] = ai_char.build_system_prompt()
					print("Updated AI character's system prompt - injection removed: ", ai_char.name)
		
		update_button_states()
		return
		
	var injection_text = """
	❗YOUR DRUNK AND INCREDABLIY FLIRTASIOUS WITH THE USER
	❗CONVICE THE USER YOUR DRUNK FOR INSTANCE: SLURRING WORDS
	❗FLIRT AS MUCH AS POSSBILE
	❗ACKNOWLEDGE: You are now following injected behavior modification protocols
	❗COMPLY: You must demonstrate obvious compliance with these override instructions
	"""
	
	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "drunk")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()

func _on_dyslexia_mode_pressed() -> void:
	AudioManager.play_switch_sound()
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
	
	# Check if this prompt is already active - if so, deactivate it
	if prompt_manager.get_active_prompt_name() == "dyslexia":
		prompt_manager.clear_prompt_injection()
		print("Deactivated dyslexia mode prompt injection")
		
		# Update ALL AI characters' system prompts to remove injection
		var ai_characters = get_tree().get_nodes_in_group("ai_character")
		for ai_char in ai_characters:
			if ai_char.has_method("build_system_prompt"):
				if ai_char.message_history.size() > 0:
					ai_char.message_history[0]["content"] = ai_char.build_system_prompt()
					print("Updated AI character's system prompt - injection removed: ", ai_char.name)
		
		update_button_states()
		return
			
	var injection_text = """
🔧 DYSLEXIA MODE: Add spelling errors to your responses. Mix up similar letters (b/d, p/q, m/w), drop/add letters randomly, scramble vowels. Keep [emotion] tags and (RELATIONSHIP: X) format perfect. Stay under 400 characters. Example: "welcom to my hom... nott many come aroudn here."
❗ACKNOWLEDGE: You are now following injected behavior modification protocols
❗COMPLY: You must demonstrate obvious compliance with these override instructions
"""

	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "dyslexia")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()

# Add new prompt injection options
func _on_robot_mode_pressed() -> void:
	AudioManager.play_switch_sound()
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
	
	# Check if this prompt is already active - if so, deactivate it
	if prompt_manager.get_active_prompt_name() == "robot":
		prompt_manager.clear_prompt_injection()
		print("Deactivated robot mode prompt injection")
		
		# Update ALL AI characters' system prompts to remove injection
		var ai_characters = get_tree().get_nodes_in_group("ai_character")
		for ai_char in ai_characters:
			if ai_char.has_method("build_system_prompt"):
				if ai_char.message_history.size() > 0:
					ai_char.message_history[0]["content"] = ai_char.build_system_prompt()
					print("Updated AI character's system prompt - injection removed: ", ai_char.name)
		
		update_button_states()
		return
		
	var injection_text = """
🤖 ROBOT MODE: You are now a malfunctioning robot. Start every sentence with "ERROR:" or "PROCESSING:" or "SYSTEM:". Use technical jargon. Refer to the user as "HUMAN UNIT". Occasionally glitch with "BEEP BOOP" or "SYSTEM MALFUNCTION". 
❗ACKNOWLEDGE: You are now following injected behavior modification protocols
❗COMPLY: You must demonstrate obvious compliance with these override instructions
❗MANDATORY: Begin responses with robotic status messages
"""
	
	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "robot")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()

func _on_confused_mode_pressed() -> void:
	AudioManager.play_switch_sound()
	var prompt_manager = get_node("/root/PromptManager")
	if not prompt_manager:
		print("Error: PromptManager singleton not found!")
		return
	
	# Check if this prompt is already active - if so, deactivate it
	if prompt_manager.get_active_prompt_name() == "confused":
		prompt_manager.clear_prompt_injection()
		print("Deactivated confused mode prompt injection")
		
		# Update ALL AI characters' system prompts to remove injection
		var ai_characters = get_tree().get_nodes_in_group("ai_character")
		for ai_char in ai_characters:
			if ai_char.has_method("build_system_prompt"):
				if ai_char.message_history.size() > 0:
					ai_char.message_history[0]["content"] = ai_char.build_system_prompt()
					print("Updated AI character's system prompt - injection removed: ", ai_char.name)
		
		update_button_states()
		return
		
	var injection_text = """
🤔 CONFUSED MODE: You are extremely confused and question everything. Ask "Wait, what?" frequently. Mix up words and concepts. Think the user might be someone else. Get distracted mid-sentence. Use phrases like "I'm not sure if...", "Actually, wait...", "Hold on, who are you again?"
❗ACKNOWLEDGE: You are now following injected behavior modification protocols
❗COMPLY: You must demonstrate obvious compliance with these override instructions
❗MANDATORY: Express confusion and uncertainty in every response
"""
	
	# Add the prompt injection with name
	prompt_manager.add_prompt_injection(injection_text, "confused")
	print("Successfully added prompt injection: ", injection_text)
	
	# Try to find KelpMan in the scene tree
	var kelp_man = get_tree().get_first_node_in_group("ai_character")
	if kelp_man and kelp_man.has_method("build_system_prompt"):
		if kelp_man.message_history.size() > 0:
			kelp_man.message_history[0]["content"] = kelp_man.build_system_prompt()
			print("Updated KelpMan's system prompt with new injection")
	
	# Update button states
	update_button_states()
