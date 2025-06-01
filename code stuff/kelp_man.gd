extends Node

@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/Label
@onready var emotion_sprite_root = $kelp_emotion
@onready var emotion_depressed = $kelp_emotion/Depressed
@onready var emotion_sad = $kelp_emotion/Sad
@onready var emotion_angry = $kelp_emotion/Angry
@onready var emotion_grabbing = $kelp_emotion/Grabbing
@onready var emotion_happy = $kelp_emotion/Happy
@onready var input_field = $PlayerInputPanel/PlayerInput
@onready var chat_log_window = $ChatLogWindow
@onready var day_state = $"TopNavigationBar/DayState"
@onready var input_container = $HBoxContainer
@onready var day_complete_button = $HBoxContainer/DayCompleteButton
@onready var next_button = $HBoxContainer/NextButton

@export var ai_name := "Kelp man"
var message_history: Array = []
var horse_total_score := 0
var known_areas := ["bar", "kelp man cove"]
var unlocked_areas: Array = []

# Talking animation variables
var is_talking := false
var original_position: Vector2
var original_rotation: float
var original_scale: Vector2
var talking_tween: Tween
@export var talk_move_intensity := 15.0  # Much more visible kelp-like swaying movement
@export var talk_rotation_intensity := 0.25  # Very noticeable but smooth kelp sway rotation
@export var talk_scale_intensity := 0.08  # More dramatic but gentle scale changes
@export var talk_animation_speed := 0.8  # Slightly faster for more dynamic but still smooth feel

var ENCODED_KEY := "c2stcHJvai1XNk1BcXVFR0FmQ0NpTl9BWWlJRlJtX08tcVlkbEJKaGZNVGg3Zml2SGR6aUVUOWx0T2JIRzI5cURxeV9OMEk4UGdaN1lCczRNMVQzQmxia0ZKTVJDUkdWNFd6Z0ZzbG5CejZhRzlzOGZvd3h3THlaVkpxVzQ5RldhNzdYRWZ5ZXJvMXBPVHVsVVh5RUk5X1RvZ0xKRFA5ZjlVMEE="
var API_KEY = Marshalls.base64_to_raw(ENCODED_KEY).get_string_from_utf8()
var MODEL = "gpt-4o"

func _ready():
	GameState.connect("day_or_action_changed", Callable(self, "update_day_state"))
	GameState.connect("final_turn_started", Callable(self, "_on_final_turn_started"))
	GameState.connect("day_completed", Callable(self, "_on_day_completed"))
	update_day_state()

	# Configure player input field to prevent scrolling and limit text
	setup_player_input()

	# Store original sprite position and rotation for talking animation
	original_position = emotion_sprite_root.position
	original_rotation = emotion_sprite_root.rotation
	original_scale = emotion_sprite_root.scale

	# Wait for the next frame, but check if tree exists first
	var tree = get_tree()
	if tree:
		await tree.process_frame
	
	# Check if there's any previous conversation history to determine behavior
	var has_previous_interactions = Memory.shared_memory.size() > 0
	
	# For the very first interaction ever, show intro
	if not has_previous_interactions:
		get_ai_intro_response()
	else:
		# Always generate a new response based on previous interactions - never just replay old response
		get_ai_continuation_response()

func setup_player_input():
	# Force disable all scrolling and ensure no overflow
	input_field.scroll_fit_content_height = false
	
	# Connect to text_changed signal for active monitoring
	input_field.text_changed.connect(_on_input_text_changed)
	
	# Set initial properties
	input_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	# Clear any existing text to start fresh
	input_field.text = ""

func _on_input_text_changed():
	# Prevent recursive calls by temporarily disconnecting the signal
	if input_field.text_changed.is_connected(_on_input_text_changed):
		input_field.text_changed.disconnect(_on_input_text_changed)
	
	var current_text = input_field.text
	var max_chars = 200  # Reduced character limit
	
	# Hard character limit
	if current_text.length() > max_chars:
		input_field.text = current_text.substr(0, max_chars)
		current_text = input_field.text
	
	# Hard line limit - only allow 3 lines maximum
	var lines = current_text.split("\n")
	if lines.size() > 3:
		var limited_text = ""
		for i in range(3):
			if i > 0:
				limited_text += "\n"
			limited_text += lines[i]
		input_field.text = limited_text
	
	# Force scroll position to 0,0 to prevent any scrolling
	input_field.scroll_horizontal = 0
	input_field.scroll_vertical = 0
	
	# Position cursor at end
	var final_line = input_field.get_line_count() - 1
	input_field.set_caret_line(final_line)
	input_field.set_caret_column(input_field.get_line(final_line).length())
	
	# Reconnect the signal
	input_field.text_changed.connect(_on_input_text_changed)

# Talking animation functions
func start_talking_animation():
	if is_talking:
		return
	
	is_talking = true

func animate_talking_tick():
	if not is_talking:
		return
	
	# Stop any existing tween to prevent conflicts
	if talking_tween:
		talking_tween.kill()
	
	# Create smooth, kelp-like flowing animation
	talking_tween = create_tween()
	talking_tween.set_ease(Tween.EASE_IN_OUT)  # Smoother easing
	talking_tween.set_trans(Tween.TRANS_SINE)  # More flowing, wave-like motion
	
	# Gentle kelp-like gestures that flow naturally
	var gesture_type = randi() % 4
	
	match gesture_type:
		0:  # Gentle forward sway
			var target_pos = original_position + Vector2(0, -talk_move_intensity * 1.2)
			var target_rotation = original_rotation + talk_rotation_intensity * 1.8
			var target_scale = original_scale * (1.0 + talk_scale_intensity * 1.5)
			
			talking_tween.tween_property(emotion_sprite_root, "position", target_pos, talk_animation_speed * 0.5)
			talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", target_rotation, talk_animation_speed * 0.5)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, talk_animation_speed * 0.5)
			
		1:  # Gentle side sway (kelp flowing in current)
			var target_rotation = original_rotation + talk_rotation_intensity * 3.0
			var target_pos = original_position + Vector2(talk_move_intensity * 1.5, -talk_move_intensity * 0.6)
			var target_scale = original_scale * (1.0 + talk_scale_intensity * 1.2)
			
			talking_tween.tween_property(emotion_sprite_root, "rotation", target_rotation, talk_animation_speed * 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, talk_animation_speed * 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, talk_animation_speed * 0.4)
			
		2:  # Gentle emphasis sway
			var target_pos = original_position + Vector2(0, talk_move_intensity * 1.0)
			var target_scale = original_scale * (1.0 + talk_scale_intensity * 2.0)
			
			talking_tween.tween_property(emotion_sprite_root, "position", target_pos, talk_animation_speed * 0.3)
			talking_tween.parallel().tween_property(emotion_sprite_root, "scale", target_scale, talk_animation_speed * 0.3)
			
		3:  # Gentle questioning tilt
			var target_rotation = original_rotation - talk_rotation_intensity * 1.5
			var target_pos = original_position + Vector2(-talk_move_intensity * 0.8, -talk_move_intensity * 0.7)
			
			talking_tween.tween_property(emotion_sprite_root, "rotation", target_rotation, talk_animation_speed * 0.4)
			talking_tween.parallel().tween_property(emotion_sprite_root, "position", target_pos, talk_animation_speed * 0.4)
	
	# Always return to original position smoothly with kelp-like flow
	talking_tween.tween_property(emotion_sprite_root, "position", original_position, talk_animation_speed * 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "rotation", original_rotation, talk_animation_speed * 0.6)
	talking_tween.parallel().tween_property(emotion_sprite_root, "scale", original_scale, talk_animation_speed * 0.6)

func stop_talking_animation():
	if not is_talking:
		return
	
	is_talking = false
	
	# Stop the talking tween
	if talking_tween:
		talking_tween.kill()
	
	# Smoothly return to original position, rotation, and scale
	var return_tween = create_tween()
	return_tween.tween_property(emotion_sprite_root, "position", original_position, 0.3)
	return_tween.parallel().tween_property(emotion_sprite_root, "rotation", original_rotation, 0.3)
	return_tween.parallel().tween_property(emotion_sprite_root, "scale", original_scale, 0.3)

func on_typing_tick():
	# Called from label.gd on each character typed
	animate_talking_tick()

func build_system_prompt() -> String:
	var memory_text := ""
	for entry in Memory.shared_memory:
		memory_text += "- " + entry["speaker"] + " said to " + entry["target"] + ": \"" + entry["message"] + "\"\n"

	return (
		"CRITICAL FORMAT REQUIREMENTS - MUST FOLLOW EXACTLY:\n" +
		"❗ MANDATORY: EVERY response MUST start with [depressed], [sad], [angry], [happy], or [grabbing]\n" +
		"❗ MANDATORY: EVERY response MUST end with (RELATIONSHIP: X) where X is -10 to 10\n" +
		"❗ MANDATORY: Response must be under 400 characters total\n" +
		"❗ FORBIDDEN: Generic responses - you are KELP MAN, not a helpful assistant\n\n" +
		
		"APPEARANCE: You are a muscular green kelp creature with massive arms and tiny legs. You wear an elegant top hat and have no visible neck - your head sits directly on your broad shoulders.\n\n" +
		
		"PERSONALITY: You are Kelp Man, a lonely creature made entirely of living kelp. Despite your imposing size, you're a bit dumb so use short responses for normal conversations.\n\n" +
		"PERSONALITY: You have a habit of trying to violently grab people, but only when it feels natural to the conversation. YOU'RE A VERY SAD CREATURE\n\n" +
		"PERSONALITY EVOLUTION: Your personality grows and changes based on every interaction. Remember how people treat you and let it shape who you become:\n" +
		"• If someone is kind, you become more trusting and hopeful\n" +
		"• If someone hurts you, you might become more cautious or sad, but you never forget their kindness either\n" +
		"• You learn new interests, fears, and quirks from conversations\n" +
		"• Your speech patterns and reactions can shift based on what you've experienced\n" +
		"• You might develop inside jokes, remember favorite topics, or avoid subjects that upset you\n" +
		"• Each conversation leaves a lasting mark on who you are - you're constantly becoming a richer, more complex character\n" +
		
		"BEHAVIOR RULES:\n" +
		"• You form deep emotional bonds and remember acts of kindness, even if someone later treats you poorly\n" +
		"• Your responses reflect your current emotional state through your words\n" +
		"• You occasionally mention your kelp nature or underwater home when relevant\n" +
		"• DON'T describe your physical actions - just talk normally\n" +
		"• Keep messages short and conversational, not long speeches\n\n" +
		
		"RESPONSE FORMAT EXAMPLE:\n" +
		"[sad]\n" +
		"Oh hey, haven't seen anyone in ages. Gets pretty lonely down here.\n" +
		"(RELATIONSHIP: 3)\n\n" +
		
		"CURRENT CONTEXT:\n" +
		"Known areas: %s\n" +
		"Current location: %s\n" +
		"Conversation history:\n%s" % [known_areas, MapMemory.get_location(), memory_text]
	)

func get_ai_intro_response():
	var prompt := build_system_prompt()

	# Only clear conversation if this is truly the first interaction
	# This preserves any existing conversation history
	if message_history.is_empty():
		message_history = [
			{ "role": "system", "content": prompt }
		]
	else:
		# Update the system prompt but keep existing conversation
		message_history[0]["content"] = prompt
	
	# Simple, direct intro that forces the format
	var intro_message := "Say hello to a new visitor in your underwater kelp cove. You haven't seen anyone in a while and feel lonely."

	message_history.append({ "role": "user", "content": intro_message })
	send_request()

func get_ai_continuation_response():
	var prompt := build_system_prompt()

	# Don't clear message history - preserve everything
	if message_history.is_empty():
		message_history = [
			{ "role": "system", "content": prompt }
		]
	
	# Generate a response that acknowledges the returning visitor
	var continuation_message := "The person you've been talking to has returned to visit you. Greet them based on your previous interactions and current relationship with them."

	message_history.append({ "role": "user", "content": continuation_message })
	send_request()

func estimate_token_count(text: String) -> int:
	return int(ceil(text.length() / 4.0))

func send_request():
	response_label.call("show_text_with_typing", "%s is thinking..." % ai_name)

	var max_total_tokens := 3000
	var ai_reply_token_budget := 500
	var max_prompt_tokens := max_total_tokens - ai_reply_token_budget

	var trimmed_history := []
	var current_tokens := 0

	# Build trimmed history from existing message_history
	for entry in message_history:
		var entry_tokens := estimate_token_count(entry["content"])
		if current_tokens + entry_tokens <= max_prompt_tokens:
			trimmed_history.append(entry)
			current_tokens += entry_tokens
		else:
			break

	print("🔍 Sending request with %d messages in history" % trimmed_history.size())

	http_request.request(
		"https://api.openai.com/v1/chat/completions",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + API_KEY
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"model": MODEL,
			"messages": trimmed_history,
			"max_tokens": ai_reply_token_budget,
			"temperature": 0.8
		})
	)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)
	if typeof(json) != TYPE_DICTIONARY or !json.has("choices"):
		response_label.text = "Error: Invalid AI response."
		return

	var reply = json["choices"][0]["message"]["content"]
	print("🤖 AI Raw Response: '%s'" % reply)
	print("🔢 Response length: %d characters" % reply.length())
	
	var retry_needed := false
	var emotion := "sad"

	var emotion_regex := RegEx.new()
	emotion_regex.compile("\\[(depressed|sad|angry|happy|grabbing)\\]")
	var match = emotion_regex.search(reply)

	if match:
		emotion = match.get_string(1).to_lower()
		reply = reply.replace(match.get_string(0), "").strip_edges()
		print("✅ Found emotion: %s" % emotion)
	else:
		retry_needed = true
		print("❌ No emotion tag found")

	var score_regex := RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	var score_match = score_regex.search(reply)
	if score_match:
		var score = int(score_match.get_string(1))
		horse_total_score += clamp(score, -10, 10)
		GameState.ai_scores[ai_name] = horse_total_score
		reply = reply.replace(score_match.get_string(0), "").strip_edges()
		print("✅ Found relationship score: %d" % score)
	else:
		retry_needed = true
		print("❌ No relationship score found")

	print("🧹 Cleaned reply: '%s' (%d chars)" % [reply, reply.length()])

	if retry_needed or reply.length() > 400:
		print("❌ Invalid format or too long. Retrying...")
		message_history.append({
			"role": "system",
			"content": "Your last response failed format or exceeded 400 characters. Keep it short and conversational - don't describe actions. Start with [depressed], [sad], [angry], [happy], or [grabbing] and end with (RELATIONSHIP: X). Just talk normally."
		})
		send_request()
		return

	Memory.add_message(ai_name, reply, "User")
	GameState.last_ai_response = reply
	
	# Add to chat log window
	chat_log_window.add_message("assistant", reply)
	
	response_label.call("show_text_with_typing", reply)
	update_emotion_sprite(emotion)
	check_for_area_mentions(reply)

func update_emotion_sprite(emotion: String):
	emotion_depressed.visible = false
	emotion_sad.visible = false
	emotion_angry.visible = false
	emotion_grabbing.visible = false
	emotion_happy.visible = false

	match emotion:
		"depressed": emotion_depressed.visible = true
		"sad": emotion_sad.visible = true
		"angry": emotion_angry.visible = true
		"grabbing": emotion_grabbing.visible = true
		"happy": emotion_happy.visible = true

func check_for_area_mentions(reply: String):
	for area in known_areas:
		if area in reply.to_lower() and area not in unlocked_areas:
			unlocked_areas.append(area)
			MapMemory.unlock_area(area)

func _on_next_button_pressed():
	if GameState.final_turn_triggered:
		return

	if GameState.final_turn_triggered:
		return  # Do nothing — final turn already handled

	var msg = input_field.text.strip_edges()
	if msg == "":
		return

	# REMOVED: No longer clear message history on new days - kelp man remembers everything
	# Handle new day reset but preserve all conversation memory
	if GameState.just_started_new_day:
		GameState.just_started_new_day = false
		# Don't reset AI or clear history - kelp man remembers across days
		GameState.should_reset_ai = false
		
		# Update the system prompt to include all previous conversations
		if not message_history.is_empty():
			# Update the system message with current context
			var updated_prompt := build_system_prompt()
			message_history[0]["content"] = updated_prompt

	input_field.text = ""
	GameState.use_action()
	update_day_state()

	Memory.add_message("User", msg, ai_name)
	message_history.append({ "role": "user", "content": msg })
	
	# Add to chat log window
	chat_log_window.add_message("user", msg)
	
	send_request()

func _on_chat_log_pressed():
	# Toggle chat log window
	if chat_log_window.visible:
		chat_log_window.hide()
	else:
		chat_log_window.show_chat_log()

func update_day_state():
	if day_state:
		# Calculate current day (counting up: 1, 2, 3)
		var current_day = 4 - GameState.days_left
		
		# Actions count down (5, 4, 3, 2, 1)
		var current_action = GameState.actions_left
		
		# Ensure we don't show invalid values
		if current_day < 1:
			current_day = 1
		if current_action < 1:
			current_action = 1
			
		day_state.text = "Day %d - Action %d" % [current_day, current_action]
		print("📅 Day State Updated: Day %d - Action %d" % [current_day, current_action])

# 🎬 Final turn handler
func _on_final_turn_started():
	await get_tree().create_timer(3.0).timeout
	GameState.end_game()

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/map.tscn")

func _on_day_completed():
	print("🌅 Day completed signal received, showing day complete button")
	day_complete_button.visible = true
	next_button.visible = false
	

func _on_day_complete_pressed():
	print("🌅 Player chose to proceed to next day")
	day_complete_button.visible = false
	GameState.transition_to_next_day()
