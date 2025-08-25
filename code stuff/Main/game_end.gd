extends Node

@onready var score_container = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScorePanel/MarginContainer/ScoreContainer
@onready var score_template = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScorePanel/MarginContainer/ScoreContainer/ScoreLabelTemplate
@onready var main_menu_button = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MainMenuButton

func _ready():
	display_all_scores()
	setup_button()

func display_all_scores():
	# Clear any existing score labels (except template)
	for child in score_container.get_children():
		if child != score_template:
			child.queue_free()

	# Display all AI scores with max possible score
	for ai_name in GameState.ai_scores:
		var score_label = score_template.duplicate()
		var current_score = GameState.ai_scores[ai_name]
		var max_possible_score = calculate_max_possible_score(ai_name)
		score_label.text = ai_name + ": " + str(current_score) + "/" + str(max_possible_score)
		score_label.visible = true
		score_container.add_child(score_label)

	# If no scores, show a message
	if GameState.ai_scores.is_empty():
		var no_scores_label = score_template.duplicate()
		no_scores_label.text = "No scores recorded"
		no_scores_label.visible = true
		score_container.add_child(no_scores_label)

# Calculate the maximum possible score for a character based on their interaction count
func calculate_max_possible_score(ai_name: String) -> int:
	var interaction_count = 0

	# Count interactions with this character from Memory.shared_memory
	for entry in Memory.shared_memory:
		var speaker = entry["speaker"]
		var target = entry["target"]

		# Count user messages to this character (each interaction can give max +10 points)
		if speaker == "User" and target == ai_name:
			interaction_count += 1

	# Each interaction can give a maximum of +10 relationship points
	return interaction_count * 10

func setup_button():
	main_menu_button.pressed.connect(on_main_menu_pressed)

func on_main_menu_pressed():
	# Reset GameState
	GameState.ai_scores.clear()
	GameState.days_left = 10
	GameState.actions_left = 10
	GameState.final_turn_triggered = false
	GameState.day_complete_available = false
	GameState.just_started_new_day = false
	GameState.should_reset_ai = false
	GameState.ai_responses.clear()
	GameState.ai_emotions.clear()
	GameState.ai_genie_used.clear()  # Reset genie mode usage tracking
	GameState.ai_get_out_states.clear()  # Reset get out button states
	
	# Reset Memory and clear all character chat logs
	Memory.shared_memory.clear()
	Memory.clear_all_character_chat_logs()
	
	# Reset PromptManager (clear any active prompt injections like drunk mode)
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager:
		prompt_manager.clear_prompt_injection()
	
	# Reset MapMemory if it exists
	if get_node("/root/MapMemory"):
		get_node("/root/MapMemory").reset()
		# Initialize a random starting location for the new game
		get_node("/root/MapMemory").initialize_random_starting_location()
	
	# Load the main menu
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")
