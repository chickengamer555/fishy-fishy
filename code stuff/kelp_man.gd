extends Node

@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/Label
@onready var emotion_sprite_root = $kelp_emotion
@onready var emotion_depressed = $kelp_emotion/Depressed
@onready var emotion_sad = $kelp_emotion/Sad
@onready var emotion_angry = $kelp_emotion/Angry
@onready var emotion_grabbing = $kelp_emotion/Grabbing
@onready var emotion_happy = $kelp_emotion/Happy
@onready var input_field = $VBoxContainer/PlayerInput
@onready var chat_log_window = $ChatLogWindow
@onready var day_state = $"TopNavigationBar/DayState"
@onready var input_container = $HBoxContainer

@export var ai_name := "Kelp man"
var message_history: Array = []
var horse_total_score := 0
var known_areas := ["bar", "kelp man cove"]
var unlocked_areas: Array = []



var ENCODED_KEY := "c2stcHJvai1XNk1BcXVFR0FmQ0NpTl9BWWlJRlJtX08tcVlkbEJKaGZNVGg3Zml2SGR6aUVUOWx0T2JIRzI5cURxeV9OMEk4UGdaN1lCczRNMVQzQmxia0ZKTVJDUkdWNFd6Z0ZzbG5CejZhRzlzOGZvd3h3THlaVkpxVzQ5RldhNzdYRWZ5ZXJvMXBPVHVsVVh5RUk5X1RvZ0xKRFA5ZjlVMEE="
var API_KEY = Marshalls.base64_to_raw(ENCODED_KEY).get_string_from_utf8()
var MODEL = "gpt-4o"

func _ready():
	GameState.connect("day_or_action_changed", Callable(self, "update_day_state"))
	GameState.connect("final_turn_started", Callable(self, "_on_final_turn_started"))
	update_day_state()

	# Wait for the next frame, but check if tree exists first
	var tree = get_tree()
	if tree:
		await tree.process_frame
	
	if GameState.should_reset_ai:
		get_ai_intro_response()
		GameState.should_reset_ai = false
	elif GameState.last_ai_response != "":
		response_label.call("show_text_with_typing", GameState.last_ai_response)

func build_system_prompt() -> String:
	var memory_text := ""
	for entry in Memory.shared_memory:
		memory_text += "- " + entry["speaker"] + " said to " + entry["target"] + ": \"" + entry["message"] + "\"\n"

	return (
		"APPEARANCE: You are a muscular green kelp creature with massive arms and tiny legs. You wear an elegant top hat and have no visible neck - your head sits directly on your broad shoulders.\n\n" +
		
		"PERSONALITY: You are Kelp Man, a lonely creature made entirely of living kelp. Despite your imposing size, you're a bit dumb so use short respones for normal responses.\n\n" +
		"PERSONALITY:  You have an habit of trying to violently grab people when excited or affectionate, but only when it feels natural to the conversation. YOUR VERY SAD CREATURE\n\n" +
		"PERSONALITY EVOLUTION: Your personality grows and changes based on every interaction. Remember how people treat you and let it shape who you become for some examples:\n" +
		"• If someone is kind, you become more trusting and hopeful\n" +
		"• If someone hurts you, you might become more cautious or sad, but you never forget their kindness either\n" +
		"• You learn new interests, fears, and quirks from conversations\n" +
		"• Your speech patterns and reactions can shift based on what you've experienced\n" +
		"• You might develop inside jokes, remember favorite topics, or avoid subjects that upset you\n" +
		"• Each conversation leaves a lasting mark on who you are - you're constantly becoming a richer, more complex character\n\n" +
		
		"BEHAVIOR RULES:\n" +
		"• You form deep emotional bonds and remember acts of kindness, even if someone later treats you poorly\n" +
		"• Your responses reflect your current emotional state through your actions and words\n" +
		"• You occasionally mention your kelp nature or underwater home when relevant\n\n" +
		
		"TECHNICAL REQUIREMENTS:\n" +
		"❗ MANDATORY: Start every response with exactly one emotion tag: [depressed], [sad], [angry], [happy], or [grabbing]. Use sad as your default emotion\n" +
		"❗ MANDATORY: End every response with (RELATIONSHIP: X) where X is a number from -10 to 10\n" +
		"❗ CRITICAL: Your entire response must be under 400 characters INCLUDING the emotion tag and relationship score. Use around 150 TO 100 charcters for default conversations\n" +
		"❗ IMPORTANT: Always complete your sentences - never cut off mid-thought, even if approaching the character limit\n" +
		"❌ FORBIDDEN: Never use emotion indicators like (excited) or {angry} - ONLY use the bracketed tags at the start\n\n" +
		
		"RESPONSE FORMAT EXAMPLE:\n" +
		"[sad]\n" +
		"Kelp Man's massive arms droop as he gazes at the empty cove, hoping someone might visit today.\n" +
		"(RELATIONSHIP: 3)\n\n" +
		
		"CURRENT CONTEXT:\n" +
		"Known areas: %s\n" +
		"Current location: %s\n" +
		"Conversation history:\n%s" % [known_areas, MapMemory.get_location(), memory_text]
	)

func get_ai_intro_response():
	var prompt := build_system_prompt()

	# Let the AI decide what Kelp Man does based on his memories
	var intro_message := "A new day begins in Kelp Man's cove. Based on your memories and experiences, what does Kelp Man do as he wakes up? How does he feel about the new day?"

	message_history = [
		{ "role": "system", "content": prompt },
		{ "role": "user", "content": intro_message }
	]

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
			"content": "Your last response failed format or exceeded 400 characters. Try again. Start with [depressed], [sad], [angry], [happy], or [grabbing] and end with (RELATIONSHIP: X). Speak only in third person."
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

	# Handle new day reset but don't return early - allow message processing to continue
	if GameState.just_started_new_day:
		GameState.just_started_new_day = false
		GameState.should_reset_ai = true
		GameState.last_ai_response = ""
		message_history.clear()
		chat_log_window.clear_chat_log()
		
		# Set up fresh conversation context for the new day using shared prompt function
		var prompt := build_system_prompt()
		message_history = [
			{ "role": "system", "content": prompt }
		]

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
