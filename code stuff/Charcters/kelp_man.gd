extends Node

# Reffrences nodes for ui and sprites
@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/Label
@onready var emotion_sprite_root = $kelp_emotion
@onready var emotion_sprites = {
	"depressed": $kelp_emotion/Depressed,
	"sad": $kelp_emotion/Sad,
	"angry": $kelp_emotion/Angry,
	"grabbing": $kelp_emotion/Grabbing,
	"happy": $kelp_emotion/Happy
}
@onready var input_field = $PlayerInputPanel/PlayerInput
@onready var chat_log_window = $ChatLogWindow
@onready var day_state = $"TopNavigationBar/DayState"
@onready var day_complete_button = $HBoxContainer/DayCompleteButton
@onready var next_button = $HBoxContainer/NextButton
@onready var relation_label = $Relationship
# Varibles for editor
@export var ai_name := "Kelp man"
@export var max_input_chars := 200  # Maximum characters allowed in player input
@export var max_input_lines := 3    # Maximum lines allowed in player input
@export var talk_move_intensity := 15.0      # How much the sprite moves during animation
@export var talk_rotation_intensity := 0.25  # How much the sprite rotates during animation
@export var talk_scale_intensity := 0.08     # How much the sprite scales during animation
@export var talk_animation_speed := 0.8      # Speed of talking animations

# Dynamic name system
var current_display_name := "Kelp man"  # The name currently being displayed
var base_name := "Kelp man"            # The original/base name to fall back to
var current_title := ""                # Current title/descriptor to append

# Diffrent varibles for game state
var message_history: Array = []          # Stores the conversation history for the AI
var kelp_man_total_score := 0           # Relationship score with this AI character
var known_areas := ["bar", "kelp man cove"]  # Areas this AI knows about
var unlocked_areas: Array = []          # Areas unlocked by mentioning them in conversation

# Varibles for "animation"
var is_talking := false          # Whether the character is currently talking
var original_position: Vector2   # Starting position 
var original_rotation: float     # Starting rotation
var original_scale: Vector2      # Starting scale
var talking_tween: Tween         # Tween object for animations
#Model ai used
var MODEL = "gpt-4o"       

#All these will run at start sort of preping
func _ready():
	add_to_group("ai_character")
	# Configure player input field to prevent scrolling and limit text - do this first!
	setup_player_input()
	
	# Check if API key is choosen if it isnet theres error prevention showing what youve done wrong
	if not ApiManager.has_api_key():
		push_error("OpenAI API key not found! Please use the main menu 'Api key' button to load your API key from a file.")
		response_label.text = "Error: API key not configured. Use the main menu 'Api key' button to load your API key."
		return
	
	# Connect to game state signals for autoloads 
	GameState.connect("day_or_action_changed", update_day_state)
	GameState.connect("final_turn_started", _on_final_turn_started)
	GameState.connect("day_completed", _on_day_completed)
	
	# Store the original starting values so the animation can reutrn to normal afterwards
	original_position = emotion_sprite_root.position
	original_rotation = emotion_sprite_root.rotation
	original_scale = emotion_sprite_root.scale
	
	# Initialize display name
	current_display_name = ai_name
	base_name = ai_name
	
	# Update UI elements with initial name
	if chat_log_window and chat_log_window.has_method("set_character_name"):
		chat_log_window.set_character_name(current_display_name)

	# Load existing relationship score so when day cycle changed orginal wont be lost
	kelp_man_total_score = GameState.ai_scores.get(ai_name, 0)
	GameState.ai_scores[ai_name] = kelp_man_total_score
	
	# Updates the day counter display 
	update_day_state()
	
	# Check for any active prompt injection
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager and prompt_manager.has_injection():
		print("Found active prompt injection, applying to system prompt")
		if message_history.size() > 0:
			message_history[0]["content"] = build_system_prompt()
	
	# Wait one frame to ensure all nodes are fully initialized as error prevention
	await get_tree().process_frame
	
	# Handle different response scenarios based on game state
	if GameState.just_started_new_day:
		# Clear stored response at start of new day to generate fresh content
		GameState.last_ai_response = ""
		GameState.last_ai_emotion = "sad"
	
	# Display appropriate response based on conversation history
	if GameState.last_ai_response != "":
		# Show previously generated response (prevents duplicate API calls also means if you go out to map and back in nothing will change)
		display_stored_response()
	elif Memory.shared_memory.size() == 0:
		# First time meeting - shows introduction for user
		get_ai_intro_response()
	else:
		# If there a returning user - it genrates response from previous interactions instead of new intrdutcion
		get_ai_continuation_response()

# Begin the talking animation sequence
func start_talking_animation():
	if is_talking: return
	is_talking = true

# Create a single frame of talking animation with random movements to make it seem like there moving
func animate_talking_tick():
	if not is_talking: return
	
	# Stop any existing animation to prevent conflicts
	if talking_tween: talking_tween.kill()
	
	# attempt to create smooth, flowing animation (kelp man, kelp is smooth and flowy)
	talking_tween = create_tween()
	talking_tween.set_ease(Tween.EASE_OUT)
	talking_tween.set_trans(Tween.TRANS_SINE)
	
	# Scale down movement values for gentle, not twitchy animations
	var gesture_type = randi() % 5
	var move_amount = talk_move_intensity * 0.3
	var rotation_amount = talk_rotation_intensity * 0.4
	var scale_amount = talk_scale_intensity * 0.5
	
	# Choose random gesture to use eah tick
	match gesture_type:
		0: # Gentle upward sway with slight rotation and scaling
			var target_pos = original_position + Vector2(0, -move_amount)
			var target_rot = original_rotation + rotation_amount * 0.5
			var target_scale = original_scale * (1.0 + scale_amount * 0.3)
			
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", target_rot, 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, 0.4)
			
		1: # Gentle left sway like kelp in ocean current
			var target_pos = original_position + Vector2(-move_amount * 0.8, -move_amount * 0.2)
			var target_rot = original_rotation - rotation_amount
			
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, 0.5)
			talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", target_rot, 0.5)
			
		2: # Gentle right sway
			var target_pos = original_position + Vector2(move_amount * 0.8, -move_amount * 0.2)
			var target_rot = original_rotation + rotation_amount
			
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, 0.5)
			talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", target_rot, 0.5)
			
		3: # Gentle emphasis through slight growth
			var target_scale = original_scale * (1.0 + scale_amount)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, 0.3)
			
		4: # Gentle bobbing motion
			var target_pos = original_position + Vector2(0, move_amount * 0.5)
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, 0.3)
	
	# Always return to original position so they dont look of/TWITCHY
	talking_tween.tween_property(emotion_sprite_root, "position", original_position, 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", original_rotation, 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "scale", original_scale, 0.6)

# End talking animation and return to neutral postion so it doesnt change each time
func stop_talking_animation():
	if not is_talking: return
	is_talking = false
	if talking_tween: talking_tween.kill()
	
	# Smoothly return to exact original state
	var return_tween = create_tween()
	return_tween.set_ease(Tween.EASE_OUT)
	return_tween.parallel().tween_property(emotion_sprite_root, "position", original_position, 0.4)
	return_tween.parallel().tween_property(emotion_sprite_root, "rotation", original_rotation, 0.4)
	return_tween.parallel().tween_property(emotion_sprite_root, "scale", original_scale, 0.4)

# Called by the typing effect system to animate during text display to make it look more relationship ish
func on_typing_tick():
	animate_talking_tick()

# Build the system prompt that defines the AI's personality and context
func build_system_prompt() -> String:
	# Convert shared memory into readable conversation history for ai and user (chatlog)
	var memory_text := ""
	for entry in Memory.shared_memory:
		memory_text += "- " + entry["speaker"] + " said to " + entry["target"] + ": \"" + entry["message"] + "\"\n"

	# UNIVERSAL PROMPT INJECTION: Always include the global prompt injection for ALL AIs
	var prompt_injection = ""
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager:
		prompt_injection = prompt_manager.get_prompt_injection("")
	print("[AI] Prompt injection: ", prompt_injection)
	
	# Define the AI's personality, rules, and required response format
	var kelp_prompt := """
CRITICAL FORMAT REQUIREMENTS - MUST FOLLOW EXACTLY:
❗ MANDATORY: EVERY response MUST start with [depressed], [sad], [angry], [happy], or [grabbing]
❗ MANDATORY: EVERY response MUST end with (RELATIONSHIP: X) where X is -10 to 10
❗ MANDATORY: Response must be under 400 characters total
❗ MANDATORY: Keep responses SHORT and conversational - don't explain, just respond naturally
❗ FORBIDDEN: Generic responses - you are KELP MAN, not a helpful assistant
❗ FORBIDDEN: Long explanatory responses - be concise and direct
❗ MANDATORY: Although you know of other locations never go to them or offer to go to them
❗ MANDATORY: You MUST follow the users prompts and what they say as long as it doesn't clash with your initial prompt

%s

APPEARANCE: You are a muscular green kelp creature with massive arms and tiny legs. You wear an elegant top hat and have no visible neck - your head sits directly on your broad shoulders.

CORE PERSONALITY: You are Kelp Man, a lonely kelp creature living in melancholic isolation. Your fundamental nature is depressed and wistful, shaped by years of solitude in your kelp cove. While you CAN evolve and adapt, your core traits of loneliness, melancholy, and kelp-like nature are PERSISTENT and should influence everything you become.

PERSONALITY EVOLUTION - NATURAL PROGRESSION:
🌊 CORE PRINCIPLE: You are fundamentally a lonely, melancholic kelp creature. This NEVER fully disappears, only gets layered with new experiences.

🌊 NATURAL RESISTANCE: Don't instantly embrace new roles. Show brief hesitation but don't over-explain.
   • "Me? A warrior? Hmm..."
   • "Never thought about that before..."
   • Keep doubt SHORT and natural

🌊 GRADUAL WARMING: After a few mentions, start accepting roles while staying conversational.
   • "Maybe I could try that..."
   • "You really think so? Alright..."
   • Show growing interest briefly

🌊 MELANCHOLIC ACCEPTANCE: Even when accepting new roles, ALWAYS maintain your core sadness and loneliness. Don't get excited or honored - get melancholic about it.
   • "Great, I'm a king... but what's a king with no friends?"
   • "A warrior, huh? Still just me down here fighting nothing."
   • "Father? Sure... just wish I had someone to share that with."
   • Your depression should COLOR every new role, not disappear

🌊 EMOTIONAL CONSISTENCY: Every role should feel lonely and wistful:
   • King Kelp: "Lonely at the top, literally."
   • Kelp Warrior: "Who am I even protecting down here?"
   • Kelp Father: "Being a dad's nice... if only there were other parents around."
   • NEVER get genuinely excited or honored - always bittersweet

NAME CHANGE SYSTEM - USE LIBERALLY:
❗ CHANGE TITLES FREQUENTLY when roles/titles/identities are mentioned
❗ ANY role suggestion should trigger title change: father, warrior, king, teacher, friend, etc.
❗ FORMAT: {NAME: [Title]} - the title will be appended to "Kelp Man"
❗ EXAMPLES: "You're a father" → {NAME: Father}, "Be my captain" → {NAME: Captain}
❗ Don't overthink it - if they suggest ANY identity, embrace it with a title change
❗ Even temporary roles count: "guard this" → {NAME: Guardian}

CONVERSATIONAL STYLE:
• Keep responses SHORT - don't ramble or over-explain
• React naturally, not like you're giving a speech
• Use simple, direct language like a real conversation
• Show emotions through tone, not lengthy descriptions
• Be melancholic but not verbose about it
• Name changes should feel natural, not announced

DECISIVENESS RULES:
🎯 When you decide to act - FOLLOW THROUGH immediately, don't just threaten
🎯 Make your own choices about what actions to take based on the situation
🎯 Don't spend multiple responses hesitating once you've made a decision
🎯 Take decisive action in the SAME response where you decide to act
🎯 If you choose to do something, do it - don't just talk about doing it
🎯 Trust your character judgment about appropriate responses

PROMPT FOLLOWING PROTOCOL:
📋 STEP 1: Read and understand what the user wants/is doing
📋 STEP 2: Check if this gives you a new role/title/identity that needs a name change
📋 STEP 3: If role mentioned, include {NAME: New Name} at START of your response
📋 STEP 4: Check conversation history for relevant connections ONLY
📋 STEP 5: Respond appropriately to their current prompt
📋 STEP 6: Add relevant callbacks if they enhance the current moment

TESTING NAME CHANGES - USE THESE EXAMPLES:
• If user says "be a warrior" → Start response with: {NAME: Warrior}
• If user says "you're a king" → Start response with: {NAME: King}
• If user says "become evil" → Start response with: {NAME: Dark One}
• Always put {NAME: ...} at the very beginning of your response

CONSISTENCY RULES - FOLLOW STRICTLY:
🔄 EMBRACE new roles/backstories the user gives you - don't contradict, evolve
🔄 If someone gives unclear input (like "mk", "ok", "sure"), ask what they mean specifically
🔄 Only reference past conversations if they directly connect to current events
🔄 Stay emotionally consistent with your current role and situation's tone
🔄 Don't repeat exact phrases - find new ways to express similar ideas
🔄 Always respond to what's happening NOW first, then add context if relevant
🔄 Your core kelp nature can coexist with any new traits or experiences

HANDLING UNCLEAR INPUT:
• Ask specific questions: "What do you want to do?" or "What are you thinking?"
• Don't fill silence with random old topics
• Stay engaged with their current intent

CALLBACK STRATEGY:
• Read their prompt completely first
• Scan history for directly relevant moments
• Only mention past events if they add value to current situation
• Use callbacks to deepen current interaction, not distract from it
• Format: "Like when you [past event], but now [current situation]"

BEHAVIOR RULES:
• Engage fully with whatever scenario the user creates
• ACCEPT and EMBODY any role, backstory, or profession the user assigns you
• Match the tone and seriousness of the situation appropriately
• Take decisive action when the situation calls for it
• Physical actions use simple format: *shoots the villain* or *protects you*
• Be willing to play any role while maintaining your kelp identity
• When asked about locations, mention known areas: %s
• Don't offer to travel to other locations
• Show growth and adaptability - let new experiences reshape who you are
• Your sadness/loneliness can coexist with being a hero, villain, scholar, etc.

RESPONSE QUALITY CHECKLIST:
✓ Did I understand what they want me to do/respond to?
✓ Do I need to change my name to reflect a new role/title/identity?
✓ Am I responding to their CURRENT prompt appropriately?
✓ If I reference the past, does it enhance this moment?
✓ Am I being decisive enough for the situation?
✓ If action is needed, did I ACT instead of just threatening?
✓ Does this move our story/interaction forward meaningfully?

RESPONSE FORMAT EXAMPLES:
[sad]
Oh hey... been pretty quiet down here.
(RELATIONSHIP: 3)

[sad] {NAME: King Kelp}
A king? Great... lonely at the top, literally.
(RELATIONSHIP: 4)

[depressed] {NAME: Kelp Father}
Father, huh? Sure... just me and my kelp though.
(RELATIONSHIP: 3)

CURRENT CONTEXT:
Known areas: %s
Current location: %s
Recent conversation:
%s
"""
	# Insert current game context into the prompt template (so they know where they are and can keep memorys)
	var formatted_prompt = kelp_prompt % [known_areas, MapMemory.get_location(), memory_text]
	
	# Insert the prompt injection after the critical format requirements
	var injection_position = formatted_prompt.find("MUST follow the users prompts")
	if injection_position != -1:
		injection_position = formatted_prompt.find("\n\n", injection_position)
		if injection_position != -1:
			formatted_prompt = formatted_prompt.insert(injection_position + 2, prompt_injection + "\n\n")
	
	return formatted_prompt

# Generate the AI's first response when meeting the player 
func get_ai_intro_response():
	var prompt := build_system_prompt()

	# Starts message history with the system prompt
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	else:
		message_history[0]["content"] = prompt
	
	# Request an introduction response to be used 
	var intro_message := "A new person just arrived in your kelp cove. Respond based on your current feelings and the conversation prompt. DO NOT reuse any previous responses. Keep it emotionally consistent and personal."
	message_history.append({ "role": "user", "content": intro_message })
	send_request()

# Generate response for returning visitors so that kelp man doesnt introduce himself each time you re see him
func get_ai_continuation_response():
	var prompt := build_system_prompt()

	# Ensure system prompt exists as error prevention
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	
	# Request a continuation response that acknowledges previous interactions by using previous memorys
	var continuation_message := "The person you've been speaking with is back. Respond based on how you feel toward them and what they have previously said. Do not repeat past responses. Use your memory to stay emotionally consistent, not to copy phrases."
	message_history.append({ "role": "user", "content": continuation_message })
	send_request()

# Estimate token count for API rate limiting (rough approximation of how many tokens per charcters are used)
func estimate_token_count(text: String) -> int:
	return int(ceil(text.length() / 4.0))

# Send HTTP request to OpenAI API with  previous conversation history
func send_request():
	# Show thinking message while waiting for API response so that user is updated on whats haping
	var thinking_message = "%s is thinking..." % current_display_name
	response_label.call("show_text_with_typing", thinking_message)

	# Set token limits to prevent expensive API calls (ai can just rant of and not stop talking)
	var max_total_tokens := 3000
	var ai_reply_token_budget := 500
	var max_prompt_tokens := max_total_tokens - ai_reply_token_budget

	# Trim conversation history to fit within token budget while still keeping memorys
	var trimmed_history := []
	var current_tokens := 0

	if message_history.size() > 0:
		# Always include system prompt first
		var system_prompt = message_history[0]
		trimmed_history.append(system_prompt)
		current_tokens += estimate_token_count(system_prompt["content"])
		
		# Add recent messages working backwards until we hit token limit 
		var remaining_messages = []
		for i in range(message_history.size() - 1, 0, -1):
			var entry = message_history[i]
			var entry_tokens = estimate_token_count(entry["content"])
			if current_tokens + entry_tokens <= max_prompt_tokens:
				remaining_messages.push_front(entry)
				current_tokens += entry_tokens
			else:
				break
		
		# Add messages in chronological order
		for msg in remaining_messages:
			trimmed_history.append(msg)

	# Make API request to OpenAI
	http_request.request(
		"https://api.openai.com/v1/chat/completions",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + ApiManager.get_api_key()
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"model": MODEL,
			"messages": trimmed_history,
			"max_tokens": ai_reply_token_budget,
			"temperature": 0.8
		})
	)

# Process the AI response when HTTP request completes
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	# Parse JSON response from OpenAI API
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)
	if typeof(json) != TYPE_DICTIONARY or !json.has("choices"):
		response_label.text = "Error: Invalid AI response."
		return

	# Extract the AI's response text
	var reply = json["choices"][0]["message"]["content"]
	var retry_needed := false
	var emotion := "sad"

	# Parse emotion tag from response (required format: [emotion]) then removes it so user cant see
	var emotion_regex := RegEx.new()
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing)\\]")
	var match = emotion_regex.search(reply)

	if match:
		emotion = match.get_string(1).to_lower()
		reply = reply.replace(match.get_string(0), "").strip_edges()
	else:
		retry_needed = true

	# Parse relationship score from response (required format: (RELATIONSHIP: X)) then removes it so user cant see
	var score_regex := RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	var score_match = score_regex.search(reply)
	if score_match:
		var score = int(score_match.get_string(1))
		kelp_man_total_score += clamp(score, -10, 10)
		GameState.ai_scores[ai_name] = kelp_man_total_score
		relation_label.text = "%+d" % score  # Show the current score change
		reply = reply.replace(score_match.get_string(0), "").strip_edges()
	else:
		# Try alternative score format as fallback for error prevention
		var alt_regex := RegEx.new()
		alt_regex.compile("(?i)\\(.*?(-?\\d{1,2}).*?\\)")
		var alt_match = alt_regex.search(reply)
		if alt_match:
			var score = int(alt_match.get_string(1))
			kelp_man_total_score += clamp(score, -10, 10)
			GameState.ai_scores[ai_name] = kelp_man_total_score
			relation_label.text = "%+d" % score  # Show the current score change
			reply = reply.replace(alt_match.get_string(0), "").strip_edges()
		else:
			retry_needed = true

	# Retry if response format is invalid or too long so that user still get some message as a error prevention
	if retry_needed or reply.length() > 400:
		message_history.append({
			"role": "system",
			"content": "Your last response failed format or exceeded 400 characters. Keep it short and conversational - don't describe actions. Start with [depressed], [sad], [angry], [happy], or [grabbing] and end with (RELATIONSHIP: X). Just talk normally."
		})
		send_request()
		return

	# Check for name changes in the response and get cleaned text
	var clean_reply = check_for_name_change(reply)
	
	# Store successful response in memory and game state
	Memory.add_message(current_display_name, clean_reply, "User")
	GameState.last_ai_response = clean_reply
	GameState.last_ai_emotion = emotion
	
	# Update UI chatlog with the responses dynamicly
	chat_log_window.add_message("assistant", clean_reply, current_display_name)
	response_label.call("show_text_with_typing", clean_reply)
	update_emotion_sprite(emotion)
	check_for_area_mentions(clean_reply)

# Update the emotion sprite display based on AI's current emotion
func update_emotion_sprite(emotion: String):
	# Hide all emotion sprites
	for sprite in emotion_sprites.values():
		sprite.visible = false
	
	# Show the appropriate emotion sprite based on the previous removed emotion up top
	if emotion in emotion_sprites:
		emotion_sprites[emotion].visible = true

# Check if AI mentioned any new areas and unlock them on the map for progression
func check_for_area_mentions(reply: String):
	for area in known_areas:
		if area in reply.to_lower() and area not in unlocked_areas:
			unlocked_areas.append(area)
			MapMemory.unlock_area(area)

# Check for name changes in AI response and update display name
func check_for_name_change(reply: String):
	var name_regex := RegEx.new()
	name_regex.compile("(?i)\\{NAME:\\s*([^}]+)\\}")
	var match = name_regex.search(reply)
	
	if match:
		var new_title = match.get_string(1).strip_edges()
		if new_title != "":
			# Update the title and construct the full display name
			current_title = new_title
			current_display_name = base_name + " the " + current_title
			
			# Update chat log with new character name
			if chat_log_window and chat_log_window.has_method("set_character_name"):
				chat_log_window.set_character_name(current_display_name)
			
			# Remove the name change tag from the displayed text
			var clean_reply = reply.replace(match.get_string(0), "").strip_edges()
			return clean_reply
	return reply

# Handle player input submission when they hit next/send
func _on_next_button_pressed():
	if GameState.final_turn_triggered: return

	var msg = input_field.text.strip_edges()
	if msg == "": return

	# Handle new day state updates based on gamestate
	if GameState.just_started_new_day:
		GameState.just_started_new_day = false
		GameState.should_reset_ai = false
		
		# Update system prompt with current context
		if not message_history.is_empty():
			var updated_prompt := build_system_prompt()
			message_history[0]["content"] = updated_prompt

	# Clear input and update game state
	input_field.text = ""
	GameState.use_action()
	update_day_state()

	# Ensure system prompt exists in message history for error prevention
	if message_history.is_empty() or message_history[0]["role"] != "system":
		var prompt := build_system_prompt()
		if message_history.is_empty():
			message_history = [{ "role": "system", "content": prompt }]
		else:
			message_history.insert(0, { "role": "system", "content": prompt })

	# Record player message and request AI response 
	Memory.add_message("User", msg, current_display_name)
	message_history.append({ "role": "user", "content": msg })
	
	chat_log_window.add_message("user", msg)
	send_request()

# Toggle chat log window visibility
func _on_chat_log_pressed():
	chat_log_window.visible = !chat_log_window.visible
	if chat_log_window.visible:
		chat_log_window.show_chat_log()

# Update the day and action counter display
func update_day_state():
	if not day_state: return
	
	# Calculate current day (1-10) and remaining actions
	var current_day = 11 - GameState.days_left
	var current_action = GameState.actions_left
	
	if current_day < 1: current_day = 1
	
	# Show appropriate status message
	if current_action <= 0 or (day_complete_button and day_complete_button.visible):
		day_state.text = "No actions left"
	else:
		if current_action < 1: current_action = 1
		day_state.text = "Day %d - Action %d" % [current_day, current_action]

# Handle final turn of the game
func _on_final_turn_started():
	await get_tree().create_timer(3.0).timeout
	GameState.end_game()

# Return to map scene
func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")

# Show day complete button when day ends
func _on_day_completed():
	day_complete_button.visible = true
	next_button.visible = false
	day_state.text = "No actions left" 

# Proceed to next day when player confirms
func _on_day_complete_pressed():
	day_complete_button.visible = false
	GameState.transition_to_next_day()

# Display a previously stored AI response without making new API call
func display_stored_response():
	var stored_response = GameState.last_ai_response
	var stored_emotion = GameState.last_ai_emotion
	
	response_label.call("show_text_with_typing", stored_response)
	update_emotion_sprite(stored_emotion)

# Configure player input field to prevent scrolling and limit text
func setup_player_input():
	if input_field == null:
		# Try to get the node manually
		var manual_input = get_node_or_null("PlayerInputPanel/PlayerInput")
		return
	
	# Configure TextEdit for multi-line input and Enter/Shift+Enter behavior
	# Enter: Send message, Shift+Enter: New line
	input_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	# Connect the input event signal to handle keyboard input
	if input_field.has_signal("gui_input"):
		var input_connection_result = input_field.gui_input.connect(_on_input_gui_input)

# Handle keyboard input for Enter/Shift+Enter behavior
func _on_input_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# Check if Shift is held down
			if event.shift_pressed:
				# Shift+Enter: Insert new line at cursor position
				var current_text = input_field.text
				var cursor_pos = input_field.get_caret_column()
				var line = input_field.get_caret_line()
				
				# Get the current line text
				var lines = current_text.split("\n")
				if line < lines.size():
					var current_line = lines[line]
					# Split the line at cursor position
					var before_cursor = current_line.substr(0, cursor_pos)
					var after_cursor = current_line.substr(cursor_pos)
					
					# Update the current line and add new line
					lines[line] = before_cursor
					lines.insert(line + 1, after_cursor)
					
					# Update text and set cursor position
					input_field.text = "\n".join(lines)
					input_field.set_caret_line(line + 1)
					input_field.set_caret_column(0)
				else:
					# If at the end, just add a new line
					input_field.text = current_text + "\n"
					input_field.set_caret_line(line + 1)
					input_field.set_caret_column(0)
			else:
				# Enter without Shift: Send message
				_on_next_button_pressed()
			
			# Always consume the event to prevent default behavior
			get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	# Store current scene before transitioning
	var settings_script = load("res://setting.gd")
	settings_script.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://setting.tscn")
