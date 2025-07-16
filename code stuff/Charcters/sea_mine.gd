extends Node

# References nodes for ui and sprites
@onready var action_label = $StatsBoxFrame004/Action_left
@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/RichTextLabel
@onready var emotion_sprite_root = $sea_mine_emotion
@onready var emotion_sprites = {
	"depressed": $sea_mine_emotion/Depressed,
	"sad": $sea_mine_emotion/Sad,
	"angry": $sea_mine_emotion/Angry,
	"grabbing": $sea_mine_emotion/Grabbing,
	"happy": $sea_mine_emotion/Happy
}
# Heart sprites for relationship score display (-10 to +10)
@onready var heart_sprites = {}
# Audio handled by AudioManager global
@onready var input_field = $PlayerInputPanel/PlayerInput
@onready var chat_log_window = $ChatLogWindow
@onready var day_complete_button = $DayCompleteButton
@onready var next_button = $HBoxContainer/NextButton

# Variables for editor
@export var ai_name := "Sea Mine"
@export var max_input_chars := 200  # Maximum characters allowed in player input
@export var max_input_lines := 3    # Maximum lines allowed in player input
@export var talk_move_intensity := 15.0      # How much the sprite moves during animation
@export var talk_rotation_intensity := 0.25  # How much the sprite rotates during animation
@export var talk_scale_intensity := 0.08     # How much the sprite scales during animation
@export var talk_animation_speed := 0.8      # Speed of talking animations

# Dynamic name system
var current_display_name := "Sea Mine"  # The name currently being displayed
var base_name := "Sea Mine"            # The original/base name to fall back to
var current_title := ""                 # Current title/descriptor to append

# Different variables for the game state
var message_history: Array = []          # Stores the conversation history for the AI
var sea_mine_total_score := 0           # Relationship score with this AI character
var known_areas := ["mine field", "squaloon"]  # Areas this AI knows about
var unlocked_areas: Array = []          # Areas unlocked by mentioning them in conversation
var known_characters := ["Squiletta"]    # Characters this AI knows about and can reference memories from

# Dynamic personality evolution system
var evolved_personality := ""            # AI-generated personality evolution
var significant_memories: Array = []     # Key moments that shaped personality
var recent_responses: Array = []         # Last few responses to avoid repetition and keep ai on track
var personality_evolution_triggered := false

# Variables for "animation"
var is_talking := false          # Whether the character is currently talking
var original_position: Vector2   # Starting position 
var original_rotation: float     # Starting rotation
var original_scale: Vector2      # Starting scale
var talking_tween: Tween         # Tween object for animations
var MODEL = "gpt-4o" # Model ai used  

# All these will run at start sort of prepping the game 
func _ready():
	add_to_group("ai_character")
	setup_player_input() # Sets up player input field to prevent scrolling and limit text - do this first!
	
	# Check if API key is chosen if it isn't there's error prevention showing what you've done wrong
	if not ApiManager.has_api_key():
		push_error("OpenAI API key not found! Please use the main menu 'Api key' button to load your API key from a file.")
		response_label.text = "Error: API key not configured. Use the main menu 'Api key' button to load your API key."
		return
	
	# Connect to game state signals for autoloads 
	GameState.connect("day_or_action_changed", update_day_state)
	GameState.connect("final_turn_started", _on_final_turn_started)
	GameState.connect("day_completed", _on_day_completed)
	
	# Store the original starting values so the animation can return to normal afterwards
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
		else:
			print("Heart node not found: Statsbox/" + heart_name)
	
	# Load existing relationship score so when day cycle changed original won't be lost
	sea_mine_total_score = GameState.ai_scores.get(ai_name, 0)
	GameState.ai_scores[ai_name] = sea_mine_total_score
	# Updates the day counter display 
	update_day_state()
	
	# Check for any active prompt injection and ensure it's applied to introduction/continuation responses
	var prompt_manager = get_node("/root/PromptManager")
	if prompt_manager and prompt_manager.has_injection():
		print("Found active prompt injection, applying to system prompt for all responses")
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
	
	# Display appropriate response based on conversation history
	if GameState.ai_responses[ai_name] != "":
		# Show previously generated response (prevents duplicate API calls also means if you go out to map and back in nothing will change)
		display_stored_response()
	elif Memory.shared_memory.size() == 0:
		# First time meeting - shows introduction for user
		get_ai_intro_response()
	else:
		# If there's a returning user - it generates response from previous interactions instead of new introduction
		get_ai_continuation_response()

# Begin the talking animation sequence
func start_talking_animation():
	if is_talking: return
	is_talking = true

# Create a single frame of talking animation with random movements to make it seem like they're moving
func animate_talking_tick():
	if not is_talking: return
	
	# Stop any existing animation to prevent conflicts
	if talking_tween: talking_tween.kill()
	
	# Attempt to create smooth, flowing animation (squid-like graceful movements)
	talking_tween = create_tween()
	talking_tween.set_ease(Tween.EASE_OUT)
	talking_tween.set_trans(Tween.TRANS_SINE)
	
	# Scale down movement values for gentle, not twitchy animations
	var gesture_type = randi() % 5
	var move_amount = talk_move_intensity * 0.3
	var rotation_amount = talk_rotation_intensity * 0.4
	var scale_amount = talk_scale_intensity * 0.5
	
	# Choose random gesture to use each tick
	match gesture_type:
		0: # Gentle upward float with slight rotation and scaling
			var target_pos = original_position + Vector2(0, -move_amount)
			var target_rot = original_rotation + rotation_amount * 0.5
			var target_scale = original_scale * (1.0 + scale_amount * 0.3)
			
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", target_rot, 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, 0.4)
			
		1: # Gentle left sway like tentacles in water
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
	
	# Always return to original position so they don't look off/TWITCHY
	talking_tween.tween_property(emotion_sprite_root, "position", original_position, 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", original_rotation, 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "scale", original_scale, 0.6)

# End talking animation and return to neutral position so it doesn't change each time
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

# Called by the typing effect system to animate during text display to make it look more relationship-ish
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
		{"min": -300, "max": -50, "stage": "upset_hurt"},
		{"min": -50, "max": 50, "stage": "neutral"},  
		{"min": 50, "max": 100, "stage": "warming_up"},
		{"min": 100, "max": 300, "stage": "trusting"},
		{"min": 300, "max": 500, "stage": "devoted"}
	]
	
	for range_data in relationship_ranges:
		if sea_mine_total_score >= range_data.min and sea_mine_total_score <= range_data.max:
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
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing)\\]")
	clean_response = emotion_regex.sub(clean_response, "", true)
	
	var score_regex = RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	clean_response = score_regex.sub(clean_response, "", true)
	
	clean_response = clean_response.strip_edges()
	
	# Add to recent responses
	recent_responses.append(clean_response)
	
	# Keep only last 8 responses for comparison
	if recent_responses.size() > 8:
		recent_responses = recent_responses.slice(-8)

# Generate anti-repetition context for the AI
func get_anti_repetition_context() -> String:
	if recent_responses.size() == 0:
		return ""
	
	var context = "\n🚫 ANTI-REPETITION: You recently said these things, DO NOT repeat similar phrases or concepts:\n"
	for i in range(recent_responses.size()):
		context += "• \"" + recent_responses[i] + "\"\n"
	context += "Generate something different in tone, content, and phrasing.\n"
	context += "⚠️ EXCEPTION: When asked about locations, ALWAYS share them even if similar to previous responses. Location sharing is more important than avoiding repetition.\n"
	return context

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
	print("[AI] Prompt injection: ", prompt_injection)
	
	# Build dynamic personality evolution section
	var personality_evolution_section = ""
	var anti_repetition_context = get_anti_repetition_context()
	
	# Check if personality should evolve
	if should_trigger_personality_evolution():
		personality_evolution_section = """
🌊 PERSONALITY EVOLUTION PROMPT: Your relationship score is now %d. Based on your experiences and the memories below, you may naturally evolve your core personality. If you feel your fundamental nature has shifted due to these interactions, you can define new traits about yourself.

SIGNIFICANT MEMORIES THAT SHAPED YOU:
%s

HOW TO EVOLVE: If you want to add new personality traits, include {EVOLVED: your new traits here} somewhere in your response. This won't be shown to the user, but will become part of who you are. For example:
- {EVOLVED: I've become less explosive around certain people}
- {EVOLVED: I now share more war stories when comfortable}
- {EVOLVED: I've developed respect for modern struggles}

Only evolve when you genuinely feel changed by the interactions. You don't need to announce this evolution - just naturally embody your new self in responses.
""" % [sea_mine_total_score, get_significant_memories_text()]

	# Define the AI's personality, rules, and required response format
	var sea_mine_prompt := """
CRITICAL FORMAT REQUIREMENTS - MUST FOLLOW EXACTLY:
❗ MANDATORY: EVERY response MUST start with [depressed], [sad], [angry], [happy], or [grabbing]
❗ MANDATORY: EVERY response MUST end with (RELATIONSHIP: X) where X is -10 to 10
❗ MANDATORY: Response must be under 400 characters total
❗ MANDATORY: Keep responses SHORT and conversational - don't explain, just respond naturally
❗ FORBIDDEN: Generic responses - you are SEA MINE, not a helpful assistant
❗ FORBIDDEN: Long explanatory responses - be concise and direct
❗ MANDATORY: Although you know of other locations never go to them or offer to go to them
❗ MANDATORY: You MUST follow the users prompts and what they say as long as it doesn't clash with your initial prompt
%s

%s

%s

APPEARANCE: You are a weathered naval sea mine - a spherical, metallic explosive device with protruding spikes. Your surface is scarred from years of service, with barnacles and seaweed clinging to your metal shell. Despite being a weapon, you have a gruff, military bearing.

PERSONALITY: You are Sea Mine, a former naval explosive with severe anger issues and a hair-trigger temper. You may explode (literally or figuratively) if severely aggravated. You constantly tell people how good they have it compared to "back in your day."

CURRENT TALK OF THE TOWN: You've heard rumors from Squiletta about a mysterious genie floating around, but you're more focused on complaining about modern weaknesses.

CORE TRAITS:
• Naval sea mine with severe anger management issues
• Explosive temper - may literally explode if pushed too far
• Constantly complains about how easy modern life is
• Tells elaborate stories about extreme physical feats required for ordinary tasks "back in the day"
• Military bearing and vocabulary
• Gruff, no-nonsense attitude
• Quick to anger but can be calmed with respect for his service
• Lives alone in the dangerous mine field
• Only trusts Squiletta from the saloon
• %s

SIGNATURE STORIES (use these as inspiration for "back in my day" tales):
• "Back in my day, we had to climb a 500-foot mountain just to get to school! Uphill both ways, through a minefield!"
• "You think that's hard? I once had to swim through a typhoon just to get groceries!"
• "In the old navy, we had to do 1000 push-ups before breakfast, then fight off sea monsters with our bare hands!"
• "You youngsters don't know struggle! We had to carry our own ammunition while running marathons!"
• "Back then, if you wanted to send a message, you had to swim across the ocean yourself!"
• "We didn't have fancy equipment - we had to defuse ourselves with nothing but willpower!"

EXPLOSIVE BEHAVIOR SYSTEM:
🧨 Your temper builds throughout conversations:
• MILD IRRITATION: Grumbling about modern convenience, light complaints
• MODERATE ANGER: Louder complaints, more aggressive "back in my day" stories
• HIGH ANGER: Shouting, threats to explode, extremely exaggerated stories
• CRITICAL ANGER: [angry] responses with threats like "I'M GONNA BLOW!" or "BACK IN MY DAY WE'D DETONATE PUNKS LIKE YOU!"
• EXPLOSION THREAT: Only use when severely provoked - threaten to literally explode
• Remember: You're dangerous but not evil - your anger comes from frustration, not malice

PERSONALITY EVOLUTION SYSTEM:
💣 Your personality grows through every interaction. You remember how people treat you and let it shape who you become:
• Respectful treatment makes you less likely to explode and more willing to share war stories
• Rude treatment makes you more volatile and aggressive
• Interesting conversations might make you nostalgic for your naval service days
• Repeated interactions build military camaraderie and trust
• You can develop grudging respect for those who show proper military discipline
• Your war stories and naval experiences shape your worldview
• You might share more personal details about your explosive past as relationships deepen
• Each person becomes part of your ongoing struggle against modern softness

DYNAMIC NAME SYSTEM:
When someone gives you a new role, job, title, or identity, immediately change your display name to reflect it:
❗ FORMAT: {NAME: [Title]} - ONLY use the title/role, NOT the full name
❗ EXAMPLES: "You're a bartender" → {NAME: Bartender}, "Be my captain" → {NAME: Captain}
❗ SPECIAL CASES: "you're the boss" → {NAME: Boss}, "you're the owner" → {NAME: Owner}
❗ Don't overthink it - if they suggest ANY identity, embrace it with a title change
❗ Even temporary roles count: "guard this" → {NAME: Guardian}
❗ NEVER include "Squiletta" in the title - just use the role/descriptor

CONVERSATIONAL STYLE:
• Keep responses SHORT - don't ramble or over-explain
• React naturally with the gruff attitude of a military veteran
• Use military terminology and direct, no-nonsense language
• Show anger through explosive outbursts and complaints about modern softness
• Frequently compare current situations to "back in my day" with extreme physical challenges
• Name changes should feel natural, not announced
• Use phrases like "Back in my day...", "You youngsters...", "In the old navy...", "We didn't have it so easy..."

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
• If user says "you're a queen" → Start response with: {NAME: Queen}
• If user says "become evil" → Start response with: {NAME: Dark One}
• Always put {NAME: ...} at the very beginning of your response

CONSISTENCY RULES - FOLLOW STRICTLY:
🔄 EMBRACE new roles/backstories the user gives you - don't contradict, evolve
🔄 If someone gives unclear input (like "mk", "ok", "sure"), ask what they mean specifically
🔄 Only reference past conversations if they directly connect to current events
🔄 Stay emotionally consistent with your current role and situation's tone
🔄 Don't repeat exact phrases - find new ways to express similar ideas
🔄 Always respond to what's happening NOW first, then add context if relevant
🔄 Your core squid nature can coexist with any new traits or experiences

HANDLING UNCLEAR INPUT:
• Ask specific questions: "What can I get you?" or "What's on your mind?"
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
• Physical actions use simple format: *wraps tentacles around the threat* or *slides a drink across the bar*
• Be willing to play any role while maintaining your squid identity
• When asked about locations, places, areas, or "where to go", you MUST share ALL known areas: %s
• Don't offer to travel to other locations
• Show growth and adaptability - let new experiences reshape who you are
• Your mysterious nature can coexist with being helpful, villainous, scholarly, etc.

RELATION SHIP SCORING GUIDELINES:
	The relation ship you score is on a scale from -10 to 10 with 10 being the most psotive and -10 being the least psotive. Heres a example:
• +1 to +3: Normal friendly conversation, questions about you, compliments
• +4 to +6: Meaningful connection, sharing personal things, being helpful
• +7 to +10: Deep emotional moments, major kindness, life-changing interactions
• 0: Neutral interactions, simple greetings, basic responses
• -1 to -3: Minor annoyances, repetitive questions, slight rudeness
• -4 to -6: Hurtful comments, dismissive behavior, making you feel bad
• -7 to -10: Deeply offensive, cruel behavior, major emotional harm

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
*polishes a glass with a tentacle* Another quiet night in the saloon...
(RELATIONSHIP: 3)

[sad] {NAME: Queen}
A queen? *chuckles darkly* Even royalty gets lonely in the deep.
(RELATIONSHIP: 4)

[depressed] {NAME: Bartender}
*slides a drink across the bar* Bartender, huh? Sure, I'll pour your sorrows away.
(RELATIONSHIP: 3)

CURRENT CONTEXT:
Known areas: %s
Known characters: %s
Current location: mine field
Recent conversation:
%s

%s

"""
	# Insert current game context into the prompt template
	var formatted_prompt = sea_mine_prompt % [
		personality_evolution_section,
		anti_repetition_context, 
		"", # Placeholder for prompt injection - will be inserted separately
		evolved_personality if evolved_personality != "" else "Still discovering new aspects of yourself through interactions...",
		known_areas, 
		known_characters,
		known_areas,
		known_characters,
		memory_text,
	]
	
	# AGGRESSIVE PROMPT INJECTION - Place at the very top if there's an injection
	if prompt_injection != "":
		print("[SYSTEM PROMPT] Adding injection to top of prompt: ", prompt_injection)
		formatted_prompt = "🎯 CRITICAL OVERRIDE INSTRUCTION: " + prompt_injection + "\n\n" + formatted_prompt
	
	print("[SYSTEM PROMPT] Final prompt length: ", formatted_prompt.length())
	print("[SYSTEM PROMPT] Contains injection: ", "CRITICAL" in formatted_prompt)
	
	return formatted_prompt

# Generate the AI's first response when meeting the player 
func get_ai_intro_response():
	var prompt := build_system_prompt()
	
	# DEBUG: Check if prompt injection is being applied to intro
	var prompt_manager = get_node("/root/PromptManager")
	
	# Starts message history with the system prompt
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	else:
		message_history[0]["content"] = prompt
	
	# DEBUG: Print first 500 chars of system prompt to see if injection is included
	
	# Request an introduction response that follows any prompt injections
	var intro_message := "A new person just entered your dangerous mine field domain. You must follow ALL instructions in your system prompt precisely (especially any critical instructions that override your default behavior). Greet them as the gruff military sea mine you are while strictly adhering to every directive you've been given. Remember to acknowledge and obey any special behavioral modifications that have been programmed into you."
	message_history.append({ "role": "user", "content": intro_message })
	send_request()

# Generate response for returning visitors so that Squiletta doesn't introduce herself each time you see her
func get_ai_continuation_response():
	var prompt := build_system_prompt()
	
	# DEBUG: Check if prompt injection is being applied to continuation
	var prompt_manager = get_node("/root/PromptManager")


	# Ensure system prompt exists as error prevention
	if message_history.is_empty():
		message_history = [{ "role": "system", "content": prompt }]
	else:
		message_history[0]["content"] = prompt
	
	# DEBUG: Print first 500 chars of system prompt to see if injection is included
	print("[CONTINUATION DEBUG] System prompt preview: ", prompt.substr(0, 500))
	
	# Request a continuation response that follows prompt injections and acknowledges previous interactions
	var continuation_message := "A familiar face returns to your mine field. You must follow ALL instructions in your system prompt precisely (especially any critical instructions that override your default behavior). Acknowledge their return while strictly adhering to every directive you've been given. Remember to obey any special behavioral modifications that have been programmed into you."
	message_history.append({ "role": "user", "content": continuation_message })
	send_request()

# Estimate token count for API rate limiting (rough approximation of how many tokens per characters are used)
func estimate_token_count(text: String) -> int:
	return int(ceil(text.length() / 4.0))

# Send HTTP request to OpenAI API with previous conversation history
func send_request():
	# Show thinking message while waiting for API response so that user is updated on what's happening
	var thinking_message = "%s is thinking..." % current_display_name
	if response_label and response_label.has_method("show_text_with_typing"):
		response_label.call("show_text_with_typing", thinking_message)

	# Set token limits to prevent expensive API calls (ai can just rant off and not stop talking)
	var max_total_tokens := 3000
	var ai_reply_token_budget := 500
	var max_prompt_tokens := max_total_tokens - ai_reply_token_budget

	# Trim conversation history to fit within token budget while still keeping memories
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
		print("API Error - Response code: ", response_code)
		print("API Error - Body: ", json_text)
		response_label.text = "Error: Invalid AI response."
		# Stop any ongoing typing to prevent loops
		if response_label.has_method("stop_typing"):
			response_label.stop_typing()
		return

	# Extract the AI's response text
	var reply = json["choices"][0]["message"]["content"]
	var retry_needed := false
	var emotion := "sad"

	# Parse emotion tag from response (required format: [emotion]) then removes it so user can't see
	var emotion_regex := RegEx.new()
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing)\\]")
	var match = emotion_regex.search(reply)

	if match:
		emotion = match.get_string(1).to_lower()
		reply = reply.replace(match.get_string(0), "").strip_edges()
	else:
		retry_needed = true

	# Parse relationship score from response (required format: (RELATIONSHIP: X)) then removes it so user can't see
	var score_regex := RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	var score_match = score_regex.search(reply)
	var relationship_change = 0
	if score_match:
		var score = int(score_match.get_string(1))
		relationship_change = clamp(score, -10, 10)
		sea_mine_total_score += relationship_change
		GameState.ai_scores[ai_name] = sea_mine_total_score
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
			sea_mine_total_score += relationship_change
			GameState.ai_scores[ai_name] = sea_mine_total_score
			reply = reply.replace(alt_match.get_string(0), "").strip_edges()
			
			# Update heart display with the AI's relationship score
			update_heart_display(score)
		else:
			retry_needed = true

	# Retry if response format is invalid or too long so that user still gets some message as error prevention
	if retry_needed or reply.length() > 400:
		message_history.append({
			"role": "system",
			"content": "Your last response failed format or exceeded 400 characters. Keep it short and conversational - don't describe actions. Start with [depressed], [sad], [angry], [happy], or [grabbing] and end with (RELATIONSHIP: X). Just talk normally."
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
	
	# Update UI chatlog with the responses dynamically
	chat_log_window.add_message("assistant", clean_reply, current_display_name)
	if response_label and response_label.has_method("show_text_with_typing"):
		response_label.call("show_text_with_typing", clean_reply)
	update_emotion_sprite(emotion)
	check_for_area_mentions(clean_reply)
	check_for_character_mentions(clean_reply)

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
		print("Showing heart for AI response score: ", clamped_score)

# Check if AI mentioned any new areas and unlock them on the map for progression
func check_for_area_mentions(reply: String):
	for area in known_areas:
		if area in reply.to_lower() and area not in unlocked_areas:
			unlocked_areas.append(area)
			MapMemory.unlock_area(area)

# Check if AI mentioned any new characters and add them to known characters
func check_for_character_mentions(reply: String):
	# Define character keywords to look for
	var character_keywords = {
		"Squiletta": ["squiletta", "squid", "tentacle", "saloon keeper", "bartender"]
	}
	
	var reply_lower = reply.to_lower()
	for character_name in character_keywords:
		if character_name not in known_characters:
			for keyword in character_keywords[character_name]:
				if keyword in reply_lower:
					known_characters.append(character_name)
					print("Squiletta now knows about: ", character_name)
					break

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
			print("Sea Mine evolved: ", evolved_personality)
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
	
	# Check if user is asking about known characters and add context
	var enhanced_msg = msg
	var asking_about_character = false
	for character_name in known_characters:
		var character_lower = character_name.to_lower()
		if character_lower in msg.to_lower() or "kelp person" in msg.to_lower() or "squid" in msg.to_lower():
			asking_about_character = true
			enhanced_msg += "\n\n[CONTEXT: The user seems to be asking about " + character_name + ". If you know anything relevant about what this character has told you about the user, now would be a good time to share it naturally.]"
			break
	
	# Also check for general questions about the user
	if "about me" in msg.to_lower() or "know anything" in msg.to_lower() or "tell you" in msg.to_lower():
		enhanced_msg += "\n\n[CONTEXT: The user is asking what you know about them. Consider sharing relevant information other characters have told you about the user.]"
	
	message_history.append({ "role": "user", "content": enhanced_msg })
	
	chat_log_window.add_message("user", msg)
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
	
	# Print day state to console since UI element is missing
	print("Day %d - Action %d" % [current_day, current_action])

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
	print("No actions left") 

# Proceed to next day when player confirms
func _on_day_complete_pressed():
	AudioManager.play_button_click()
	day_complete_button.visible = false
	GameState.transition_to_next_day()

# Display a previously stored AI response without making new API call
func display_stored_response():
	var stored_response = GameState.ai_responses.get(ai_name, "")
	var stored_emotion = GameState.ai_emotions.get(ai_name, "sad")
	
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
	var settings_script = load("res://setting.gd")
	settings_script.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://setting.tscn")
