extends Node2D

# Original tutorial components
@onready var menu = $Menu
@onready var gameplay1 = $"Gameplay 1"
@onready var gameplay2 = $"Gameplay 2"
@onready var banner = $Banner_Label
@onready var gameplay_label = $gameplay_label
@onready var gameplay1_arrow = $"Gameplay 1/gameplay1_arrow"
@onready var gameplay2_arrow = $"Gameplay 2/gameplay2_arrow"
@onready var gameplay2_circle = $"Gameplay 2/gameplay2_circle"
@onready var end_tutorial = $end_tutorial
@onready var ai_label = $"Gameplay 2/AIResponsePanel/RichTextLabel"
@onready var setting_1 = $"Settings 1"
@onready var setting_2 = $'Settings 2'
@onready var setting2_arrow = $"Settings 2/settings2_arrow"
@onready var setting2_unlock_button = $"Settings 2/VBoxContainer/Unlock_All"
@onready var setting2_drunk_button = $"Settings 2/VBoxContainer/Drunk_mode"
@onready var setting2_dysleixa_button = $"Settings 2/VBoxContainer/Dyslexia_mode"
@onready var setting2_end_button = $"Settings 2/VBoxContainer/EndButton"
@onready var tips1 = $"Tips 1"
@onready var tips_text = $"Tips 1/VBoxContainer/TipsText"
# AI System components (using existing tutorial UI)
@onready var http_request = $"Gameplay 2/HTTPRequest"
@onready var input_field = $"Gameplay 2/PlayerInputPanel/PlayerInput"
@onready var chat_log_window = $"Gameplay 2/ChatLogWindow"
@onready var action_label = $"Gameplay 2/Statsbox/Action_left"
@onready var next_button = $"Gameplay 2/HBoxContainer/NextButton"
@onready var chat_log_button = $"Gameplay 2/HBoxContainer/ChatLog"
@onready var back_button = $"Gameplay 2/gameplay2_back_button"
@onready var leave_button = $"Gameplay 2/gameplay2_leave_button"


var setting1_messages = [
	"When you play fishy-fishy you will stumble upon gear icon, usually in the top left or right corner.",
	"Why dont you click on it to bring up the settings menu."
]

var setting2_messages = [
	"This is the settings menu, accessible by the main menu. The in game settings are diffrent but will be covered.",
	"These sliders control the sound levels of the game",
	"These are fun extra game modes that affect the ways that the charcters talk!",
	"This allows you to unlock all locations before playing.",
	"This is what the in game setting menu looks likes!",
	"This is button allows you to end the game early"
]

var gameplay1_messages = [
	"When you start the game you will have one location already unlocked. It's random each time!",
	"You can tell what locations are unlocked due to their difference in color. There's also no question marks.",
	"In this case the squaloon is unlocked! Why don't you click to travel there?",
]
var gameplay2_messages = [
	"Howdy im squileta, im one of the characters you can encounter while playing.",
	"This ol' bottom panel is where character's response like mine appear.",
	"You unlock new locations when the character mentions them, make sure to ask around!",
	"This side panel here is where you can type in your message to send to all the charcters.",
	"Hitting either the send button or enter will send your message straight to us.",
	"Hitting log will open up a chat log to show your previous conversations and what you and i have said.",
	"This box up here shows your relationship status and your actions left, make sure to keep track of it.",
	"Each chat your relationship will be scored which corresponds to a heart. The hearts go from black to red, the redder the better.",
	"This number here indicates how many actions you have left. Make sure to keep note of it",
	"There's a total of 10 days and 10 actions each day. Once the day ends all your conversations will reset but we'll still remember!",
	"Now enough enough yammering why dont ya try it out for youself!"
]
var current_index = 0

var tips1_messages = [
	"Theres a secret charcter to unlock, make sure to ask around and try solve the puzzle!",
	"You dont have to try get a postive relation ship score you can make the charcter hate you!",
	"Charcter memories do still presist onto the next day, dont do anything to bad!",
	"Characters mention new locations - pay attention to unlock new areas to explore.",
	"Click LOG to view conversation history for that day.",
	"Charcter can actualy get diffrent name pay atention to that!",
	"Game progresses through natural conversation. Take time to build relationships.",
	"Controls: Enter (send), Shift+Enter (new line).",
	"Some charcters actualy have extra gimicks they can do, beware!",
	"Each charcter responds with a diffrent emotion, see if you can spot them all",
	"To summon a genie, rup the lamp.",
]

# AI System variables
var tutorial_ai_active = false
var message_history: Array = []
var ai_name := "Squileta"
var current_display_name := "Squileta"
var retry_count := 0
const MODEL := "gpt-4o-mini"
const MAX_RETRIES := 3
var tutorial_actions_left := 3  # Give them 3 actions to try the tutorial
var timeout_timer: Timer

func _ready() -> void:
	tips1.visible = false
	end_tutorial.visible = false
	menu.visible = true
	gameplay1_arrow.visible = false
	gameplay1.visible = false
	gameplay2.visible = false
	gameplay_label.visible = false
	setting_2.visible = false
	banner.position = Vector2(0, -7)
	setting_1.visible = false
	if leave_button:
		leave_button.visible = false
	gameplay_label.text = gameplay1_messages[current_index]
	current_index = (current_index + 1) % gameplay1_messages.size()

	# Setup AI components
	setup_ai_system()
	setup_player_input()

# AI System setup functions
func setup_ai_system():
	# Check if API key is available - if not, show error message and return
	if not ApiManager.has_api_key():
		push_error("OpenAI API key not found! Please use the main menu 'Api key' button to load your API key from a file.")
		ai_label.text = "Error: API key not configured. Use the main menu 'Api key' button to load your API key."
		return

	# Initialize chat log
	if chat_log_window:
		chat_log_window.character_name = ai_name
		if chat_log_window.has_method("set_character_name"):
			chat_log_window.set_character_name(ai_name)

	# Connect HTTP request signal
	if http_request:
		http_request.request_completed.connect(_on_http_request_completed)

	# Keep buttons visible, just disable functionality initially
	# Update action counter
	update_action_display()

func setup_player_input():
	if not input_field:
		return

	# Configure TextEdit for multi-line input and Enter/Shift+Enter behavior
	# Enter: Send message, Shift+Enter: New line
	input_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

	# Connect the input event signal to handle keyboard input
	if input_field.has_signal("gui_input"):
		input_field.gui_input.connect(_on_input_gui_input)

# Handle keyboard input for Enter/Shift+Enter behavior
func _on_input_gui_input(event: InputEvent):
	if not tutorial_ai_active:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# Check if Shift is held down
			if event.shift_pressed:
				# Shift+Enter: Insert new line at cursor position - allow default behavior
				return
			else:
				# Enter: Send message
				_on_next_button_pressed_ai()
				# Prevent default behavior (adding new line)
				get_viewport().set_input_as_handled()

func _on_game_play_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	banner.text = ("TO START YOU MUST CHOOSE A LOCATION")
	gameplay_label.visible = true
	gameplay_label.position = Vector2(534.0, 325.0)
	gameplay1.visible = true
	menu.visible = false
	banner.visible = true



func _on_settings_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	banner.visible = false
	gameplay_label.visible = true
	gameplay_label.position = Vector2(533, 216)
	menu.visible = false
	current_index = 0  # Reset index for settings section
	gameplay_label.text = setting1_messages[current_index]
	current_index = (current_index + 1) % setting1_messages.size()
	setting_1.visible = true


func _on_tips_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	# Initialize Tips UI centered within Tips 1 panel
	gameplay_label.visible = false
	current_index = 0
	tips_text.text = tips1_messages[current_index]
	current_index = (current_index + 1) % tips1_messages.size()
	tips1.visible = true
	menu.visible = false

func _on_gameplay_1_next_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	gameplay_label.text = gameplay1_messages[current_index]
	if current_index == 2:
		gameplay1_arrow.visible = true
	current_index = (current_index + 1) % gameplay1_messages.size()




func _on_squaloon_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	banner.text = ("TALK TO CHARACTERS!")
	gameplay1.visible = false
	gameplay2.visible = true
	current_index = 0
	gameplay_label.visible = false
	ai_label.text = gameplay2_messages[current_index]
	current_index = (current_index + 1) % gameplay2_messages.size()
	gameplay2_arrow.visible = false
	gameplay2_circle.visible = false
	banner.visible = true
	banner.position = Vector2(0, 14)
	


func _on_gameplay_2_next_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	# Check if we've reached the final tutorial message
	if current_index == gameplay2_messages.size() - 1:
		# This is the "why dont ya try it out for youself!" message
		update_tutorial_ui()
		# Activate AI system after a short delay
		await get_tree().create_timer(2.0).timeout
		activate_ai_system()
		return

	current_index = (current_index + 1) % gameplay2_messages.size()
	update_tutorial_ui()
	


func _on_end_tutorial_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")



func activate_ai_system():
	# Hide tutorial navigation buttons
	var tutorial_next_button = $"Gameplay 2/gameplay2_next_button"
	if tutorial_next_button:
		tutorial_next_button.visible = false
	
	if back_button:
		back_button.visible = false
	
	# Always show leave button regardless of API key
	if leave_button:
		leave_button.visible = true
	
	# Only activate AI chat if API key is available
	if ApiManager.has_api_key():
		tutorial_ai_active = true

		# Initialize AI system prompt
		var system_prompt = build_system_prompt()
		message_history = [{ "role": "system", "content": system_prompt }]

		# Show initial AI response - let the AI generate it naturally
		var intro_message := "A person just finished the tutorial and can now chat with you directly. Respond as Squilleta would."
		message_history.append({ "role": "user", "content": intro_message })
		send_request()

		# Update action display
		update_action_display()
	else:
		# No API key - show error but leave button still available
		ai_label.text = "Tutorial complete! However, API key not configured. Use the main menu 'Api key' button to load your API key to chat with characters."

func build_system_prompt() -> String:
	var squiletta_prompt := """
You are Squilleta, an American bartender with a southern drawl. You are sarcastic but tolerant.

APPEARANCE: You are a bar tender with a white shirt and tie, your squid head is on top with tentacles sprawling across your shirt. Your squid colors are purple and pink. You have diamond earrings but if the user asks say you strangely don't know where you got them.

PERSONALITY: You have a southern drawl to your accent so use words like that when typing for instance, suga', ya'll, oop etc. You have heard tales of a mystical genie living in a place called 'kelp man cove'. Bring it up when it seems relevant.

Locations/Characters and how you know them:
	Regulars: Sea mine, The shrimp with no name and Kelp man are all bar regulars
	Alleyway with Glunko: Glunko lives in the alleyway behind your squaloon so you have to keep yelling at him to stop selling the customers copies of Crab!

BEHAVIOR RULES:
• Keep messages short and conversational, not long speeches
• Stay in character as a friendly but sarcastic southern bartender
• This is a tutorial - be welcoming but maintain your personality
• You can mention the known areas occasionally when it makes sense in conversation

Keep responses under 200 characters and always stay true to your southern bartender personality.
"""
	return squiletta_prompt

func update_action_display():
	if action_label:
		action_label.text = str(tutorial_actions_left)

	# Show complete tutorial button when actions reach 0
	if tutorial_actions_left <= 0 and tutorial_ai_active:
		end_tutorial.visible = true



func _on_next_button_pressed_ai():
	if not tutorial_ai_active or tutorial_actions_left <= 0:
		return

	# Check API key before doing anything
	if not ApiManager.has_api_key():
		ai_label.text = "Error: API key not configured. Use the main menu 'Api key' button to load your API key."
		return

	var msg = input_field.text.strip_edges()
	if msg == "":
		return

	# Clear input and use action
	input_field.text = ""
	tutorial_actions_left -= 1
	update_action_display()

	# Add user message to history and chat log
	message_history.append({ "role": "user", "content": msg })

	if chat_log_window:
		chat_log_window.add_message("user", msg)

	# Reset retry counter and send request
	retry_count = 0
	send_request()

func send_request():
	if not tutorial_ai_active:
		return

	# Check API key again before sending request
	if not ApiManager.has_api_key():
		ai_label.text = "Error: API key not configured. Use the main menu 'Api key' button to load your API key."
		return

	# Show thinking message
	var thinking_message = "%s is thinking..." % current_display_name
	if ai_label and ai_label.has_method("show_text_with_typing"):
		ai_label.call("show_text_with_typing", thinking_message)
	else:
		ai_label.text = thinking_message



	# Prepare request headers
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + ApiManager.get_api_key()
	]

	var body = {
		"model": MODEL,
		"messages": message_history,
		"max_tokens": 150,
		"temperature": 0.8
	}

	# Make API request
	if http_request:
		http_request.request(
			"https://api.openai.com/v1/chat/completions",
			headers,
			HTTPClient.METHOD_POST,
			JSON.stringify(body)
		)

		# Start timeout timer
		start_timeout_timer()
	else:
		ai_label.text = "Error: HTTP request node not found"

func start_timeout_timer():
	# Create timer if it doesn't exist
	if not timeout_timer:
		timeout_timer = Timer.new()
		add_child(timeout_timer)
		timeout_timer.timeout.connect(_on_timeout)

	# Stop any existing timer and start new one
	timeout_timer.stop()
	timeout_timer.wait_time = 30.0
	timeout_timer.one_shot = true
	timeout_timer.start()

func _on_timeout():
	if ai_label.text.ends_with("is thinking..."):
		ai_label.text = "Well suga', seems like I'm havin' some trouble respondin' right now. Try again in a bit, darlin'."

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	# Stop timeout timer since we got a response
	if timeout_timer:
		timeout_timer.stop()

	if not tutorial_ai_active:
		return

	if response_code != 200:
		handle_api_error(response_code, body)
		return

	# Parse JSON response from OpenAI API
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)
	if typeof(json) != TYPE_DICTIONARY or !json.has("choices"):
		ai_label.text = "Well suga', I'm havin' some trouble understandin' that response. Try again, darlin'."
		return

	# Extract the AI's response text
	var ai_reply = json["choices"][0]["message"]["content"].strip_edges()

	# Add AI response to message history and chat log
	message_history.append({ "role": "assistant", "content": ai_reply })

	if chat_log_window:
		chat_log_window.add_message("assistant", ai_reply, current_display_name)

	# Display the response
	if ai_label and ai_label.has_method("show_text_with_typing"):
		ai_label.call("show_text_with_typing", ai_reply)
	else:
		ai_label.text = ai_reply

func handle_api_error(response_code: int, body: PackedByteArray):
	retry_count += 1

	# Check if we've exceeded max retries
	if retry_count >= MAX_RETRIES:
		# Provide fallback response to prevent infinite loop (matching original character style)
		var fallback_reply = "Well suga', I'm havin' some trouble respondin' right now. Let's try talkin' about somethin' else, darlin'."

		# Add fallback to message history and chat log
		message_history.append({ "role": "assistant", "content": fallback_reply })

		if chat_log_window:
			chat_log_window.add_message("assistant", fallback_reply, current_display_name)

		# Display the fallback response
		if ai_label and ai_label.has_method("show_text_with_typing"):
			ai_label.call("show_text_with_typing", fallback_reply)
		else:
			ai_label.text = fallback_reply

		retry_count = 0  # Reset for next message
		return

	# Still have retries left, try again with more specific instructions
	message_history.append({
		"role": "system",
		"content": "Your last response failed. This is critical - you MUST respond in character as Squilleta with your southern drawl personality. Keep it conversational and stay in character. Do not refuse to respond."
	})
	send_request()

# Chat log button handler
func _on_chat_log_pressed():
	AudioManager.play_button_click()
	if chat_log_window:
		chat_log_window.visible = !chat_log_window.visible
		if chat_log_window.visible:
			chat_log_window.show_chat_log()

# Chat log window button handlers
func _on_close_button_pressed():
	AudioManager.play_button_click()
	if chat_log_window:
		chat_log_window.hide()

func _on_increase_font_button_pressed():
	AudioManager.play_button_click()
	if chat_log_window and chat_log_window.has_method("_on_increase_font_button_pressed"):
		chat_log_window._on_increase_font_button_pressed()

func _on_decrease_font_button_pressed():
	AudioManager.play_button_click()
	if chat_log_window and chat_log_window.has_method("_on_decrease_font_button_pressed"):
		chat_log_window._on_decrease_font_button_pressed()


func update_tutorial_ui():
	ai_label.text = gameplay2_messages[current_index]
	gameplay2_arrow.visible = false
	gameplay2_circle.visible = false
	
	match current_index:
		1:
			gameplay2_arrow.rotation_degrees = 90
			gameplay2_arrow.visible = true
			gameplay2_arrow.position = Vector2(232.0, 406.0)
		3:
			gameplay2_arrow.visible = true
			gameplay2_arrow.position = Vector2(845.0, 400.0)
			gameplay2_arrow.rotation_degrees = 0
		4:
			gameplay2_circle.visible = true
			gameplay2_circle.position = Vector2(1165.0, 671.0)
		5:
			gameplay2_circle.visible = true
			gameplay2_circle.position = Vector2(1005.0, 671.0)
		6:
			gameplay2_arrow.visible = true
			gameplay2_arrow.position = Vector2(820.0, 244)
		7:
			gameplay2_arrow.visible = true
			gameplay2_arrow.position = Vector2(1040.0, 231.0)
		8:
			gameplay2_arrow.visible = true
			gameplay2_arrow.position = Vector2(900.0, 214.0)

func _on_gameplay_2_back_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	
	if current_index > 0:
		current_index -= 1
		update_tutorial_ui()


func _on_gameplay_2_leave_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")


func _on_setting_1_next_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	gameplay_label.text = setting1_messages[current_index]
	current_index = (current_index + 1) % setting1_messages.size()


func _on_setting_1_settings_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	gameplay_label.visible = true
	gameplay_label.position = Vector2(800, 0)
	current_index = 0  # Reset index for settings section
	gameplay_label.text = setting2_messages[current_index]
	current_index = (current_index + 1) % setting2_messages.size()
	setting_1.visible = false
	setting_2.visible = true
	setting2_arrow.visible = false
	setting2_end_button.visible = false
	setting2_drunk_button.visible = true
	setting2_dysleixa_button.visible = true
	setting2_unlock_button.visible = true


func _on_settings_2_next_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	gameplay_label.text = setting2_messages[current_index]
	if current_index == 0:
		setting2_end_button.visible = false
		setting2_arrow.visible = false
		setting2_drunk_button.visible = true
		setting2_dysleixa_button.visible = true
		setting2_unlock_button.visible = true
	if current_index == 1:
		setting2_arrow.visible = true
		setting2_arrow.position = Vector2(320, 272)
	if current_index == 2:
		setting2_arrow.position = Vector2(320, 447)
	if current_index == 3:
		setting2_arrow.position = Vector2(320, 549)
	if current_index == 4:
		setting2_arrow.visible = false  
		setting2_drunk_button.visible = false
		setting2_dysleixa_button.visible = false
		setting2_unlock_button.visible = false
		setting2_end_button.visible = true
	if current_index == 5:
		setting2_arrow.visible = true
		setting2_arrow.position = Vector2(320, 415)
	current_index = (current_index + 1) % setting2_messages.size()

func _on_tips_1_next_button_pressed():
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	tips_text.text = tips1_messages[current_index]
	current_index = (current_index + 1) % tips1_messages.size()

func _on_tips_1_back_button_pressed():
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")

func _on_back_button_pressed():
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/main_menu.tscn")
