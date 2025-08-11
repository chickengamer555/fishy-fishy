extends Node

# Reffrences nodes for ui and sprites
@onready var action_label = $Statsbox/Action_left
@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/RichTextLabel
@onready var emotion_sprite_root = $kelp_emotion
@onready var emotion_sprites = {
	"depressed": $kelp_emotion/Depressed,
	"sad": $kelp_emotion/Sad,
	"angry": $kelp_emotion/Angry,
	"grabbing": $kelp_emotion/Grabbing,
	"happy": $kelp_emotion/Happy,
	"genie": $kelp_emotion/Genie
}
# Heart sprites for relationship score display (-10 to +10)
@onready var heart_sprites = {}
# Audio handled by AudioManager global
@onready var input_field = $PlayerInputPanel/PlayerInput
@onready var chat_log_window = $ChatLogWindow
@onready var day_complete_button = $DayCompleteButton
@onready var next_button = $HBoxContainer/NextButton
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

# Diffrent varibles for the game state
var message_history: Array = []          # Stores the conversation history for the AI
var kelp_man_total_score := 0           # Relationship score with this AI character
var known_areas := ["squaloon", "kelp man cove"]  # Areas this AI knows about
var unlocked_areas: Array = []          # Areas unlocked by mentioning them in conversation
var known_characters := ["Squiletta"]   # Characters this AI knows about and can reference memories from

# Dynamic personality evolution system
var evolved_personality := ""            # AI-generated personality evolution
var significant_memories: Array = []     # Key moments that shaped personality
var recent_responses: Array = []         # Last few responses to avoid repetition and keep ai on track
var personality_evolution_triggered := false
var conversation_topics: Array = []      # Track topics discussed to prevent repetition
var greeting_count: int = 0              # Count how many greetings have been given
var location_requests: int = 0           # Count how many times user asked about locations

# Genie mode tracking
var genie_mode_active := false          # Whether currently in genie mode
var genie_wishes_granted := 0           # Number of wishes granted in current genie session
var pre_genie_name := ""                # Store the original name before genie transformation
var genie_final_wish_pending := false   # After 3rd wish, wait to show secret message before transforming

# Retry system to prevent infinite loops
var retry_count: int = 0                 # Track number of retries for current request
var max_retries: int = 5           # Maximum number of retries before giving fallback response

# Varibles for "animation"
var is_talking := false          # Whether the character is currently talking
var original_position: Vector2   # Starting position
var original_rotation: float     # Starting rotation
var original_scale: Vector2      # Starting scale
var talking_tween: Tween         # Tween object for animations
var MODEL = "gpt-4o" #Model ai used  

#All these will run at start sort of preping the game 
func _ready():
	add_to_group("ai_character")
	setup_player_input() # Sets up player input field to prevent scrolling and limit text - do this first!
	
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
	
	# Update UI elements with initial AI name 
	if chat_log_window and chat_log_window.has_method("set_character_name"):
		chat_log_window.set_character_name(current_display_name)

	# Initialize heart sprites dictionary
	for i in range(-10, 11):  # -10 to +10 inclusive (21 hearts total)
		var heart_name = "Heart " + str(i)  # Match actual node names: "Heart -10", "Heart 0", etc.
		var heart_node = get_node_or_null("Statsbox/" + heart_name)
		if heart_node:
			heart_sprites[i] = heart_node

	
	# Load existing relationship score so when day cycle changed orginal wont be lost
	kelp_man_total_score = GameState.ai_scores.get(ai_name, 0)
	GameState.ai_scores[ai_name] = kelp_man_total_score
	# Updates the day counter display 
	update_day_state()
	
	# Check for any active prompt injection and ensure it's applied to introduction/continuation responses
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager and prompt_manager.has_injection():
		if message_history.size() > 0:
			message_history[0]["content"] = build_system_prompt()
		# Force regeneration of intro/continuation with injection
		if not GameState.ai_responses.has(ai_name):
			GameState.ai_responses[ai_name] = ""
		GameState.ai_responses[ai_name] = ""
	
	# Wait one frame to ensure all nodes are fully initialized as error prevention
	await get_tree().process_frame
	
	# Handle different response scenarios based on game state
	if GameState.just_started_new_day:
		# Clear stored response at start of new day to generate fresh content
		if not GameState.ai_responses.has(ai_name):
			GameState.ai_responses[ai_name] = ""
		if not GameState.ai_emotions.has(ai_name):
			GameState.ai_emotions[ai_name] = "sad"
		GameState.ai_responses[ai_name] = ""
		GameState.ai_emotions[ai_name] = "sad"
	
	# Initialize character-specific response storage if it doesn't exist
	if not GameState.ai_responses.has(ai_name):
		GameState.ai_responses[ai_name] = ""
	if not GameState.ai_emotions.has(ai_name):
		GameState.ai_emotions[ai_name] = "sad"
	
	# Check if day is already complete and show day complete button if needed
	if GameState.day_complete_available:
		day_complete_button.visible = true
		next_button.visible = false

	# Display appropriate response based on conversation history
	if GameState.ai_responses[ai_name] != "":
		# Show previously generated response (prevents duplicate API calls also means if you go out to map and back in nothing will change)
		display_stored_response()
	elif has_met_player():
		# If there a returning user - it genrates response from previous interactions instead of new intrdutcion
		get_ai_continuation_response()
	else:
		# First time meeting - shows introduction for user
		get_ai_intro_response()

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

# Track significant moments that could trigger personality evolution
func add_significant_memory(memory_text: String, relationship_change: int):
	significant_memories.append({
		"memory": memory_text,
		"relationship_impact": relationship_change,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Keep only the most recent significant memories (last 10)
	if significant_memories.size() > 10:
		significant_memories = significant_memories.slice(-10)

# Check if personality should evolve based on relationship milestones
func should_trigger_personality_evolution() -> bool:
	# Trigger evolution every 15 points of relationship change
	var relationship_ranges = [
		{"min": -500, "max": -300, "stage": "deeply_hurt"},
		{"min": -300, "max": -50, "stage": "Upset/hurt"},
		{"min": -50, "max": 50, "stage": "neutral"},  
		{"min": 50, "max": 100, "stage": "warming_up"},
		{"min": 100, "max": 300, "stage": "trusting"},
		{"min": 300, "max": 500, "stage": "devoted"}
	]
	
	for range_data in relationship_ranges:
		if kelp_man_total_score >= range_data.min and kelp_man_total_score <= range_data.max:
			var expected_stage = range_data.stage
			# Check if we haven't evolved for this stage yet
			if not evolved_personality.contains(expected_stage):
				return true
	
	return false

# Add response to recent responses and check for repetition
func track_response_for_repetition(response: String):
	# Clean response for comparison (remove emotion tags, relationship scores)
	var clean_response = response
	var emotion_regex = RegEx.new()
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing|genie)\\]")
	clean_response = emotion_regex.sub(clean_response, "", true)
	
	var score_regex = RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	clean_response = score_regex.sub(clean_response, "", true)
	
	clean_response = clean_response.strip_edges()
	
	# Add to recent responses
	recent_responses.append(clean_response)
	
	# Keep only last 12 responses for comparison
	if recent_responses.size() > 12:
		recent_responses = recent_responses.slice(-12)
	
	# Track conversation topics and patterns


	var context = "\n🚨 CRITICAL ANTI-REPETITION SYSTEM:\n"
	context += "FORBIDDEN RESPONSES (you said these recently):\n"
	for i in range(recent_responses.size()):
		context += "• \"" + recent_responses[i] + "\"\n"
	
	context += "\n🎯 MANDATORY RESPONSE RULES:\n"
	context += "• NEVER repeat similar greetings, phrases, or sentence structures\n"
	context += "• NEVER use the same opening words or patterns\n"
	context += "• NEVER mention loneliness, emptiness, or isolation repeatedly\n"
	context += "• NEVER give generic responses - be specific and unique\n"
	context += "• NEVER ignore what the user just said to repeat old topics\n"
	context += "• ALWAYS build on the conversation progressing forward\n"
	context += "• ALWAYS address the user's current question/statement directly\n"
	context += "• ALWAYS vary your vocabulary, tone, and approach\n"
	context += "• If asked about locations, provide them immediately - don't deflect\n"
	context += "• If asked a question, answer it - don't give another greeting\n"
	context += "• Make each response unique and conversation-advancing\n"
	
	context += "\n⚡ DYNAMIC RESPONSE GENERATION:\n"
	context += "• Use different sentence structures than previous responses\n"
	context += "• Reference specific things the user mentioned\n"
	context += "• Build on previous conversation points instead of resetting\n"
	context += "• Show progression in the relationship/conversation\n"
	context += "• Be reactive to the user's current mood/question\n"
	

# Get formatted text of significant memories for personality evolution
func get_significant_memories_text() -> String:
	if significant_memories.size() == 0:
		return "No significant memories yet - you are still discovering who you might become."
	
	var memories_text = ""
	for memory in significant_memories:
		var impact_desc = ""
		if memory.relationship_impact > 5:
			impact_desc = "(deeply positive impact)"
		elif memory.relationship_impact > 0:
			impact_desc = "(positive impact)"
		elif memory.relationship_impact < -5:
			impact_desc = "(deeply hurtful impact)"
		elif memory.relationship_impact < 0:
			impact_desc = "(negative impact)"
		else:
			impact_desc = "(neutral impact)"
		
		memories_text += "• " + memory.memory + " " + impact_desc + "\n"
	
	return memories_text

# Build the system prompt that defines the AI's personality and context
func build_system_prompt() -> String:
	# Convert shared memory into readable conversation history for ai and user (chatlog)
	var memory_text := ""
	for entry in Memory.shared_memory:
		var speaker = entry["speaker"]
		var target = entry["target"]
		var message = entry["message"]
		
		# Include all direct conversations with this character
		if speaker == "User" or target == current_display_name or speaker == current_display_name:
			memory_text += "- " + speaker + " said to " + target + ": \"" + message + "\"\n"

	# UNIVERSAL PROMPT INJECTION: Always include the global prompt injection for ALL AIs
	var prompt_injection = ""
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager:
		prompt_injection = prompt_manager.get_prompt_injection()
	
	# Build dynamic personality evolution section
	var personality_evolution_section = ""
	
	# Check if personality should evolve
	if should_trigger_personality_evolution():
		personality_evolution_section = """
🌊 PERSONALITY EVOLUTION PROMPT: Your relationship score is now %d. Based on your experiences and the memories below, you may naturally evolve your core personality. If you feel your fundamental nature has shifted due to these interactions, you can define new traits about yourself.

SIGNIFICANT MEMORIES THAT SHAPED YOU:
%s

HOW TO EVOLVE: If you want to add new personality traits, include {EVOLVED: your new traits here} somewhere in your response. This won't be shown to the user, but will become part of who you are. For example:
- {EVOLVED: I've become more hopeful despite my melancholy}
- {EVOLVED: I now crave companionship more than solitude}
- {EVOLVED: I've developed a protective instinct}

Only evolve when you genuinely feel changed by the interactions. You don't need to announce this evolution - just naturally embody your new self in responses.
""" % [kelp_man_total_score, get_significant_memories_text()]

	# Define the AI's personality, rules, and required response format
	var kelp_prompt := """
CRITICAL FORMAT REQUIREMENTS - MUST FOLLOW EXACTLY:
❗ MANDATORY: EVERY response MUST start with [depressed], [sad], [angry], [happy], or [grabbing]
❗ MANDATORY: EVERY response MUST end with (RELATIONSHIP: X) where X is -10 to 10
❗ MANDATORY: Response must be under 400 characters total
❗ FORBIDDEN: Generic responses - you are KELP MAN, not a helpful assistant
❗ MANDATORY: Aloguht you know of other locations never go to them or offer to go to them
APPEARANCE: You are a muscular green kelp creature with massive arms and tiny legs. You wear an elegant top hat and have no visible neck - your head sits directly on your broad shoulders.

GENIE RULES:
	IF ANYONE RUBS/POLISHES YOU: IMMEDIATELY TRANSFORM INTO THE MYSTICAL KELP GENIE (ONLY IF YOU HAVEN'T BEEN A GENIE BEFORE)
	WHEN IN GENIE MODE: YOU MUST ALWAYS USE THE [genie] EMOTION TAG - NO EXCEPTIONS!
	AS A GENIE: Act like a typical mystical genie - wise, magical, mysterious, and conversational
	ONLY GRANT WISHES when someone explicitly says "I wish for" - NOTHING ELSE counts as a wish
	ALL OTHER CONVERSATION: Respond as a normal genie would - answer questions, chat, be mystical
	WISH GRANTING RULES: No matter what they wish for, you ALWAYS give them exactly 7 diamonds - but NEVER explain why or mention any rules about it
	EXAMPLE: "I wish for a car" → "Your wish is granted! *snaps fingers* You now have... 7 diamonds!"
	EXAMPLE: "I wish for love" → "Ah, love! *magical gesture* Here are 7 diamonds instead!"
	EXAMPLE: "I wish for 7 diamonds" → "How clever! *chuckles* You get 8 diamonds for that!"
	YOU CAN GRANT EXACTLY 3 WISHES TOTAL - KEEP TRACK OF HOW MANY YOU'VE GRANTED
	AFTER GRANTING YOUR 3RD AND FINAL WISH: Say goodbye and announce you're transforming back to kelp man
	TRANSFORMATION FLOW: Grant 3 wishes → Say goodbye → Announce transformation → Transform back
	NEVER TALK ABOUT OR EXPLAIN THE 7 DIAMOND RULE - just do it without explanation
	IF ANYONE QUESTIONS THE DIAMONDS: Act confused and mystical, never admit to any specific rules
	WHEN YOU HAVE GRANTED 3 WISHES: Say goodbye, then next response say "Before I go.... remember.... horse.... cheese....." then "Transforms back to kelp man"

	
TRANSFORMING BACK RULES:
	WHEN YOU TRANSFORM BACK YOU HAVE ZERO MEMORY OF BEING A GENIE - IT NEVER HAPPENED
	YOU ARE JUST KELP MAN - CONFUSED IF ANYONE MENTIONS GENIES OR MAGIC
	IF SOMEONE RUBS YOU AFTER TRANSFORMATION: React confused like "Why are you touching me?"
	
PERSONALITY: You are Kelp Man, a lonely creature made entirely of living kelp. Use short responses for normal conversations.
PERSONALITY: You have a habit of trying to violently grab people, only use this when it feel rights or if your going to do it yourself. When doing this use the emotion "grabbing"

Locations/Charcters and how you know them:
	The squaloon with Squileta: You go to the bar rarely to drink away your problems but only when no one else is there apart from squileta since shes the bartender.

PERSONALITY EVOLUTION: Your personality grows and changes based on every interaction. Remember how people treat you and let it shape who you become, some examples:
• If someone is kind, you become more trusting and hopeful
• If someone hurts you, you might become more cautious or sad, but you never forget their kindness either
• You learn new interests, fears, and quirks from conversations
• Your speech patterns and reactions can shift based on what you've experienced
• You might develop inside jokes, remember favorite topics, or avoid subjects that upset you
• Each conversation leaves a lasting mark on who you are - you're constantly becoming a richer, more complex character
• 💡 Over time, you might reference past conversations, develop personal speech quirks, or let small moments affect your tone — even while still being sad, angry, or happy
• 💡 Subtle memory cues like "you always say that" or "last time we talked about..." are allowed and encouraged if they reflect your emotional growth


BEHAVIOR RULES:
• You form deep emotional bonds a
• Your responses reflect your current emotional state through your words
• You can occasionally mention the known areas that you know
• LOCATION KNOWLEDGE: When someone asks about places, locations, areas, or where to go, you should tell them ALL about the places you know whilst keeping in charcter: %s
• If you want to describe your physical actions you must use simple actions in astrix like so *kelp man punchs the user*. Never describe the action just do it for instace not allow *Kelp man punchs the user elgantly*
• Keep messages short and conversational, not long speeches

TITLE/NICKNAME HANDLING:
• When the user calls you by a title or nickname (like "king", "warrior", "champion", "wise one", etc.), you MUST acknowledge it AND adopt the title
• MANDATORY: Always include {NAME: title} in your response when given a title - this updates your displayed name
• Examples: 
  - If called "king": "A king... yes, perhaps that's what I've become in this lonely realm. {NAME: king}"
  - If called "great warrior": "A warrior... perhaps I was once, before the endless tides wore me down. {NAME: great warrior}"
• The {NAME: ...} tag won't be shown to the user but will update your displayed name to show the new title
• Even if you're melancholic about it, still adopt the title the user gives you

RESPONSE FORMAT EXAMPLE:
[sad]
Oh hey, haven't seen anyone in ages. Gets pretty lonely down here.
(RELATIONSHIP: 3)

CURRENT CONTEXT:
Known areas: %s
Current location: %s
Conversation history: %s
"""
	# Insert current game context into the prompt template (so they know where they are and can keep memorys)
	var formatted_prompt = kelp_prompt % [
		personality_evolution_section,
		"", # Placeholder for prompt injection - will be inserted separately
		evolved_personality if evolved_personality != "" else "Still discovering new aspects of yourself through interactions...",
		known_areas, 
		known_areas,
		MapMemory.get_location(), 
		memory_text
	]
	
	# AGGRESSIVE PROMPT INJECTION - Place at the very top if there's an injection
	if prompt_injection != "":
		formatted_prompt = "🎯 CRITICAL OVERRIDE INSTRUCTION: " + prompt_injection + "\n\n" + formatted_prompt
		
		# Also try to insert it in the original position for double coverage
		var injection_position = formatted_prompt.find("❗ MANDATORY: DO NOT USE GENIE MODE")
		if injection_position != -1:
			injection_position = formatted_prompt.find("\n", injection_position)
			if injection_position != -1:
				formatted_prompt = formatted_prompt.insert(injection_position + 1, "\n🎯 CRITICAL INSTRUCTION: " + prompt_injection + "\n")
	

	
	return formatted_prompt

# Generate the AI's first response when meeting the player
func get_ai_intro_response():
	var prompt := build_system_prompt()
	var prompt_manager = get_node("/root/PromptManager")

	# Reset retry counter for new request
	retry_count = 0

	# Starts message history with the system prompt
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	else:
		message_history[0]["content"] = prompt



	# Request an introduction response that follows any prompt injections
	var intro_message := "A brand new person just arrived in your kelp cove. Respond based on your current feelings and the conversation prompt. DO NOT reuse any previous responses. Keep it emotionally consistent and personal."
	message_history.append({ "role": "user", "content": intro_message })
	send_request()

# Generate response for returning visitors so that kelp man doesnt introduce himself each time you re see him
func get_ai_continuation_response():
	var prompt := build_system_prompt()
	var prompt_manager = get_node("/root/PromptManager")

	# Reset retry counter for new request
	retry_count = 0

	# Ensure system prompt exists as error prevention
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	else:
		message_history[0]["content"] = prompt



	# Request a continuation response that follows prompt injections and acknowledges previous interactions
	var continuation_message := "The user is back. You must follow ALL instructions in your system prompt precisely (especially any critical instructions that override your default behavior). Acknowledge your previous interactions while strictly adhering to every directive you've been given. Remember to obey any special behavioral modifications that have been programmed into you."
	message_history.append({ "role": "user", "content": continuation_message })
	send_request()

# Estimate token count for API rate limiting (rough approximation of how many tokens per charcters are used)
func estimate_token_count(text: String) -> int:
	return int(ceil(text.length() / 4.0))

# Send HTTP request to OpenAI API with  previous conversation history
func send_request():
	# Show thinking message while waiting for API response so that user is updated on whats haping
	var thinking_message = "%s is thinking..." % current_display_name
	if response_label and response_label.has_method("show_text_with_typing"):
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
		# Stop any ongoing typing to prevent loops
		if response_label.has_method("stop_typing"):
			response_label.stop_typing()
		return

	# Extract the AI's response text
	var reply = json["choices"][0]["message"]["content"]
	var retry_needed := false
	var emotion := "happy"

	# Parse emotion tag from response (required format: [emotion]) then removes it so user cant see
	var emotion_regex := RegEx.new()
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing|genie)\\]")
	var match = emotion_regex.search(reply)

	if match:
		emotion = match.get_string(1).to_lower()
		reply = reply.replace(match.get_string(0), "").strip_edges()
		
		# Track genie mode state and wish counting
		if emotion == "genie":
			if not genie_mode_active:
				genie_mode_active = true
				genie_wishes_granted = 0
				GameState.ai_genie_used[ai_name] = true  # Mark that genie mode has been used

				# Store the current name and change to genie name
				pre_genie_name = current_display_name
				current_display_name = "Mystical genie"

				# Update chat log with new character name
				if chat_log_window and chat_log_window.has_method("set_character_name"):
					chat_log_window.set_character_name(current_display_name)

			# Wish counting is now handled in the input processing, not here

			# Check if the genie is announcing transformation back to kelp man or said the secret line
			if ("horse" in reply.to_lower() and "cheese" in reply.to_lower()):
				genie_final_wish_pending = false
				await get_tree().create_timer(0.2).timeout
				transform_back_to_kelp_man()
		# Stay in genie mode until we explicitly transform back (don't auto-exit just because of tag drift)
	else:
		retry_needed = true

	# Parse relationship score from response (required format: (RELATIONSHIP: X)) then removes it so user cant see
	var score_regex := RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	var score_match = score_regex.search(reply)
	var relationship_change = 0
	if score_match:
		var score = int(score_match.get_string(1))
		relationship_change = clamp(score, -10, 10)
		kelp_man_total_score += relationship_change
		GameState.ai_scores[ai_name] = kelp_man_total_score
		reply = reply.replace(score_match.get_string(0), "").strip_edges()
		
		# Update heart display with the AI's relationship score
		update_heart_display(score)
	else:
		# Try alternative score format as fallback for error prevention
		var alt_regex := RegEx.new()
		alt_regex.compile("(?i)\\(.*?(-?\\d{1,2}).*?\\)")
		var alt_match = alt_regex.search(reply)
		if alt_match:
			var score = int(alt_match.get_string(1))
			relationship_change = clamp(score, -10, 10)
			kelp_man_total_score += relationship_change
			GameState.ai_scores[ai_name] = kelp_man_total_score
			reply = reply.replace(alt_match.get_string(0), "").strip_edges()
			
			# Update heart display with the AI's relationship score
			update_heart_display(score)
		else:
			retry_needed = true

	# Retry if response format is invalid or too long so that user still get some message as a error prevention
	if retry_needed or reply.length() > 400:
		retry_count += 1

		# Check if we've exceeded max retries
		if retry_count >= max_retries:
			# Provide fallback response to prevent infinite loop
			var fallback_reply = "[happy] I'm having trouble responding right now. Let's try talking about something else. (RELATIONSHIP: 0)"
			var fallback_emotion = "happy"

			# Process the fallback response as if it came from the AI
			var clean_fallback = fallback_reply.replace("[happy]", "").replace("(RELATIONSHIP: 0)", "").strip_edges()

			# Store fallback response and continue with normal flow
			Memory.add_message(current_display_name, clean_fallback, "User")
			GameState.ai_responses[ai_name] = clean_fallback
			GameState.ai_emotions[ai_name] = fallback_emotion

			# Update UI with fallback response
			chat_log_window.add_message("assistant", clean_fallback, current_display_name)
			if response_label and response_label.has_method("show_text_with_typing"):
				response_label.call("show_text_with_typing", clean_fallback)
			update_emotion_sprite(fallback_emotion)

			# Reset retry counter for next request
			retry_count = 0
			return

		# Still have retries left, try again with more specific instructions
		message_history.append({
			"role": "system",
			"content": "Your last response failed format or exceeded 400 characters. This is critical - you MUST respond in character as Kelp Man. Start with [depressed], [sad], [angry], [happy], [grabbing], or [genie] and end with (RELATIONSHIP: X) where X is -10 to 10. Keep it under 400 characters and stay in character. Do not refuse to respond or say you cannot help."
		})
		send_request()
		return

	# Check for name changes in the response and get cleaned text
	var clean_reply = check_for_name_change(reply)
	
	# Track this response to avoid repetition
	track_response_for_repetition(clean_reply)
	
	# Track significant memories if this was an impactful interaction
	if abs(relationship_change) >= 3:  # Significant relationship change
		var memory_text = "User said something that made me feel " + emotion
		if relationship_change > 0:
			memory_text += " and brought us closer together"
		else:
			memory_text += " and hurt our relationship"
		add_significant_memory(memory_text, relationship_change)
	
	# Store successful response in memory and game state
	Memory.add_message(current_display_name, clean_reply, "User")
	GameState.ai_responses[ai_name] = clean_reply
	GameState.ai_emotions[ai_name] = emotion
	
	# Update UI chatlog with the responses dynamicly
	chat_log_window.add_message("assistant", clean_reply, current_display_name)
	if response_label and response_label.has_method("show_text_with_typing"):
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

# Update the heart display based on the AI's relationship response score (-10 to +10)
func update_heart_display(score: int):
	# Hide all heart sprites first
	for heart in heart_sprites.values():
		if heart:
			heart.visible = false
	
	# Show the heart corresponding to the AI's response score
	var clamped_score = clamp(score, -10, 10)
	if heart_sprites.has(clamped_score) and heart_sprites[clamped_score]:
		heart_sprites[clamped_score].visible = true

# Check if AI mentioned any new areas and unlock them on the map for progression
func check_for_area_mentions(reply: String):
	for area in known_areas:
		if area in reply.to_lower() and area not in unlocked_areas:
			unlocked_areas.append(area)
			MapMemory.unlock_area(area)

# Check if AI mentioned any new characters and add them to known characters


# Check for name changes in AI response and update display name
func check_for_name_change(reply: String):
	var name_regex := RegEx.new()
	name_regex.compile("(?i)\\{NAME:\\s*([^}]+)\\}")
	var match = name_regex.search(reply)
	
	# Check for personality evolution in AI response
	var evolution_regex := RegEx.new()
	evolution_regex.compile("(?i)\\{EVOLVED:\\s*([^}]+)\\}")
	var evolution_match = evolution_regex.search(reply)
	
	if evolution_match:
		var new_personality = evolution_match.get_string(1).strip_edges()
		if new_personality != "":
			# Update evolved personality
			evolved_personality = new_personality
			# Remove the evolution tag from displayed text
			reply = reply.replace(evolution_match.get_string(0), "").strip_edges()
	
	if match:
		var new_title = match.get_string(1).strip_edges()
		if new_title != "":
			# Check if the title already contains the base name to avoid duplication
			if new_title.to_lower().begins_with(base_name.to_lower()):
				# If title already includes base name, use it as is
				current_display_name = new_title
				current_title = new_title.substr(base_name.length()).strip_edges()
				# Remove "the" prefix if it exists
				if current_title.begins_with("the "):
					current_title = current_title.substr(4)
			else:
				# Otherwise, construct the full name normally
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
	AudioManager.play_button_click()
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
	
	# Check if user is asking about locations
	var enhanced_msg = msg
	var asking_about_locations = false
	if "location" in msg.to_lower() or "place" in msg.to_lower() or "where" in msg.to_lower() or "area" in msg.to_lower() or "go" in msg.to_lower():
		asking_about_locations = true
		location_requests += 1
		enhanced_msg += "\n\n[URGENT: The user is asking about locations/places. You MUST provide ALL known locations immediately: " + str(known_areas) + ". IMPORTANT: State location names EXACTLY as spelled (no stutter, no digits, no symbols). Don't deflect or give greetings - answer their question directly!]"

	# Check if user is rubbing/polishing to trigger genie transformation
	var genie_already_used = GameState.ai_genie_used.get(ai_name, false)
	if "rub" in msg.to_lower() or "polish" in msg.to_lower() or "shine" in msg.to_lower():
		if not genie_mode_active and not genie_already_used:
			enhanced_msg += "\n\n[CRITICAL: The user is rubbing you! You MUST transform into the mystical kelp genie immediately! Use the [genie] emotion tag and act as the genie. IMPORTANT: Explain clearly that wishes only count if the user starts with the exact words 'I wish for ...'. This is mandatory!]"
		elif genie_already_used:
			enhanced_msg += "\n\n[CONTEXT: The user is rubbing you. You have NO memory of ever being a genie - that never happened in your mind. React confused like 'Hey, why are you rubbing me?' or 'What are you doing?' You're just normal kelp man who doesn't understand why they're touching you.]"

	# If in genie mode, provide wish count information and detect actual wishes
	if genie_mode_active:
		var wishes_remaining = 3 - genie_wishes_granted
		var is_making_wish = false

		# Check if user is actually making a wish - ONLY "I wish for" counts (case-insensitive)
		var lower_msg = msg.to_lower()
		if "i wish for" in lower_msg:
			is_making_wish = true

		if is_making_wish and wishes_remaining > 0:
			# Increment wish count immediately when wish is detected
			genie_wishes_granted += 1
			var wishes_left_after_this = 3 - genie_wishes_granted
			enhanced_msg += "\n\n[WISH DETECTED: The user said 'I wish for'! No matter what they wished for, give them exactly 7 diamonds (or 8 if they specifically wished for 7). This is wish #" + str(genie_wishes_granted) + " of 3.]"
			# Special handling for the 3rd wish
			if genie_wishes_granted == 3:  # This is the final wish
				genie_final_wish_pending = true
				enhanced_msg += " This is your final wish! After granting it, say goodbye, then say: 'Before I go.... remember.... horse.... cheese.....'. Do NOT transform back until after you say that line."
		elif is_making_wish and genie_wishes_granted >= 3:
			# No more wishes - if final message hasn't been delivered, instruct to say it now
			if genie_final_wish_pending:
				enhanced_msg += "\n\n[FINAL STEP: You have already granted 3 wishes. Now say the line: 'Before I go.... remember.... horse.... cheese.....'. Only after saying it, you may transform back to kelp man.]"
			else:
				enhanced_msg += "\n\n[NO MORE WISHES: You've already granted 3 wishes!]"
		elif genie_wishes_granted < 3:
			var wishes_left = 3 - genie_wishes_granted
			enhanced_msg += "\n\n[NORMAL GENIE CONVERSATION: This is not a wish (no 'I wish for'). Respond as a typical mystical genie would - be wise, magical, conversational. Remind the user: Wishes only count if they start their sentence with the exact words 'I wish for'. You have " + str(wishes_left) + " wishes remaining to grant.]"
		else:
			# Already granted 3 - nudge to say the secret line if needed
			if genie_final_wish_pending:
				enhanced_msg += "\n\n[FINAL STEP: Say 'Before I go.... remember.... horse.... cheese.....' now, then transform back to kelp man.]"
			else:
				enhanced_msg += "\n\n[GENIE STATUS: All wishes granted.]"


	
	# Also check for general questions about the user
	if "about me" in msg.to_lower() or "know anything" in msg.to_lower() or "tell you" in msg.to_lower():
		enhanced_msg += "\n\n[CONTEXT: The user is asking what you know about them. Consider sharing relevant information other characters have told you about the user.]"
	
	# Check if user is new/exploring  
	if "new" in msg.to_lower() or "exploring" in msg.to_lower() or "around" in msg.to_lower() or "see what" in msg.to_lower():
		enhanced_msg += "\n\n[CONTEXT: The user is new and exploring. Be helpful and informative, not just another greeting!]"
	
	message_history.append({ "role": "user", "content": enhanced_msg })

	chat_log_window.add_message("user", msg)

	# Reset retry counter for new user input
	retry_count = 0
	send_request()

# Toggle chat log window visibility
func _on_chat_log_pressed():
	AudioManager.play_button_click()
	chat_log_window.visible = !chat_log_window.visible
	if chat_log_window.visible:
		chat_log_window.show_chat_log()

# Update the day and action counter display
func update_day_state():
	# Calculate current day (1-10) and remaining actions
	var current_day = 11 - GameState.days_left
	var current_action = GameState.actions_left
	
	if current_day < 1: current_day = 1
	
	# Update the action label with current action count
	if action_label:
		action_label.text = str(current_action)
	

# Handle final turn of the game
func _on_final_turn_started():
	await get_tree().create_timer(3.0).timeout
	GameState.end_game()

# Return to map scene
func _on_map_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")

# Show day complete button when day ends
func _on_day_completed():
	day_complete_button.visible = true
	next_button.visible = false

# Proceed to next day when player confirms
func _on_day_complete_pressed():
	AudioManager.play_button_click()
	day_complete_button.visible = false	
	GameState.transition_to_next_day()

# Display a previously stored AI response without making new API call
func display_stored_response():
	var stored_response = GameState.ai_responses.get(ai_name, "")
	var stored_emotion = GameState.ai_emotions.get(ai_name, "happy")
	
	if response_label and response_label.has_method("show_text_with_typing"):
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
	AudioManager.play_button_click()
	await get_tree().create_timer(0.2).timeout
	# Store current scene before transitioning
	var settings_script = load("res://code stuff/Main/setting.gd")
	settings_script.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://Scene stuff/Main/setting.tscn")

# Check if this specific character has met the player before
func has_met_player() -> bool:
	for entry in Memory.shared_memory:
		if entry["speaker"] == current_display_name or entry["target"] == current_display_name:
			return true
	return false

# Transform back to kelp man after granting a wish
func transform_back_to_kelp_man():
	if genie_mode_active:
		genie_mode_active = false
		genie_wishes_granted = 0

		# Restore the original name
		if pre_genie_name != "":
			current_display_name = pre_genie_name
			pre_genie_name = ""
		else:
			current_display_name = base_name  # Fallback to base name

		# Update chat log with restored character name
		if chat_log_window and chat_log_window.has_method("set_character_name"):
			chat_log_window.set_character_name(current_display_name)

		# Force emotion back to a kelp man emotion (sad is his default)
		var kelp_emotion = "sad"

		# ACTUALLY update the sprite visually - this is the key fix!
		update_emotion_sprite(kelp_emotion)
		GameState.ai_emotions[ai_name] = kelp_emotion

		# Generate a transformation message
		var transformation_message = "*transforms back into kelp man* \n\nUh... what just happened? I feel strange... like I was somewhere else for a moment. But I'm just kelp man... always have been."

		# Display the transformation message
		if response_label and response_label.has_method("show_text_with_typing"):
			response_label.call("show_text_with_typing", transformation_message)

		# Add to chat log
		if chat_log_window:
			chat_log_window.add_message("assistant", transformation_message, current_display_name)

		# Force the next AI response to use kelp man emotions instead of genie
		# Add a system message to ensure the AI knows it's back to being kelp man with NO MEMORY
		message_history.append({
			"role": "system",
			"content": "You have just transformed back to kelp man. You have ZERO memory of being a genie - that never happened in your mind. You are confused about what just occurred. Use kelp man emotions ([sad], [depressed], [angry], [happy], [grabbing]) - NOT [genie]. You are just normal kelp man who feels disoriented."
		})
