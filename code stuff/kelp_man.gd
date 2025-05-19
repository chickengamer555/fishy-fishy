extends Node

@onready var http_request = $HTTPRequest
@onready var response_label = $AIResponsePanel/Label
@onready var emotion_sprite_root = $horse_emotion
@onready var emotion_happy = $horse_emotion/Happy
@onready var emotion_sad = $horse_emotion/Sad
@onready var emotion_angry = $horse_emotion/Angry
@onready var emotion_default = $horse_emotion/Default
@onready var input_field = $VBoxContainer/PlayerInput
@onready var chat_log_label = $ChatLogWindow/ChatLogLabel
@onready var chat_log_window = $ChatLogWindow
@onready var day_state = $"DayState"
@onready var input_container = $HBoxContainer

@export var ai_name := "Kelp man"
var message_history: Array = []
var chat_log: Array = []
var horse_total_score := 0
var known_areas := ["bar", "kelp man cove"]
var unlocked_areas: Array = []

var ENCODED_KEY := "c2stcHJvai1XNk1BcXVFR0FmQ0NpTl9BWWlJRlJtX08tcVlkbEJKaGZNVGg3Zml2SGR6aUVUOWx0T2JIRzI5cURxeV9OMEk4UGdaN1lCczRNMVQzQmxia0ZKTVJDUkdWNFd6Z0ZzbG5CejZhRzlzOGZvd3h3THlaVkpxVzQ5RldhNzdYRWZ5ZXJvMXBPVHVsVVh5RUk5X1RvZ0xKRFA5ZjlVMEE="
var API_KEY = Marshalls.base64_to_raw(ENCODED_KEY).get_string_from_utf8()
var MODEL = "gpt-4o"

func _ready():
	GameState.connect("day_or_action_changed", Callable(self, "update_day_state"))
	update_day_state()

	await get_tree().process_frame
	if GameState.should_reset_ai:
		get_ai_intro_response()
		GameState.should_reset_ai = false
	elif GameState.last_ai_response != "":
		response_label.call("show_text_with_typing", GameState.last_ai_response)

func get_ai_intro_response():
	var memory_text := ""
	for entry in Memory.shared_memory:
		memory_text += "- " + entry["speaker"] + " said to " + entry["target"] + ": \"" + entry["message"] + "\"\n"

	var prompt := (
		"You are a disturbing kelp abomination named Kelp Man. You are made of kelp and only kelp. You always try and grab people whenever you have the chance NO MATTER WHAT. Your acctualy very sad and lonely\n" +
		"❗ Speak in very short the shorter the better, creepy third-person narration. No 'I', 'me', or 'you' but you can still use long messages up to 400 characters if needed. Always try to grab the player. Be unsettling.\n" +
		"❗ Start every message with exactly one lowercase emotion tag on its own line: [happy], [sad], [angry], or [default]\n" +
		"❗ End every message with (RELATIONSHIP: X) where X is -10 to 10.\n" +
		"❗ YOUR ENTIRE RESPONSE MUST BE UNDER 400 CHARACTERS INCLUDING EMOTION AND SCORE. EVEN IF USER ASKS FOR MORE JUST MAKE IT 400\n" +
		"❌ Never use parentheses like (excited) or {angry}. ONLY use [happy], [sad], [angry], or [default] at the start.\n" +
		"\nFORMAT:\n[happy]\nKelp Man writhes with joy.\n(RELATIONSHIP: 5)\n" +
		"\nKnown areas: %s\nCurrent location: %s\n%s" % [known_areas, MapMemory.get_location(), memory_text]
	)

	message_history = [
		{ "role": "system", "content": prompt },
		{ "role": "user", "content": "Hello?" }
	]

	send_request()

func estimate_token_count(text: String) -> int:
	return int(ceil(text.length() / 4.0))

func send_request():
	var max_total_tokens := 3000
	var ai_reply_token_budget := 300
	var max_prompt_tokens := max_total_tokens - ai_reply_token_budget

	var trimmed_history := []
	var current_tokens := 0

	for entry in message_history:
		var entry_tokens := estimate_token_count(entry["content"])
		if current_tokens + entry_tokens <= max_prompt_tokens:
			trimmed_history.append(entry)
			current_tokens += entry_tokens
		else:
			break

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
	var retry_needed := false
	var emotion := "default"

	var emotion_regex := RegEx.new()
	emotion_regex.compile("^\\s*\\[(happy|sad|angry|default)\\]\\s*\\n")
	var match = emotion_regex.search(reply)

	if match:
		emotion = match.get_string(1).to_lower()
		reply = reply.replace(match.get_string(0), "").strip_edges()
	else:
		retry_needed = true

	var score_regex := RegEx.new()
	score_regex.compile("(?i)\\(relationship:\\s*(-?\\d{1,2})\\s*\\)")
	var score_match = score_regex.search(reply)
	if score_match:
		var score = int(score_match.get_string(1))
		horse_total_score += clamp(score, -10, 10)
		GameState.ai_scores[ai_name] = horse_total_score
		reply = reply.replace(score_match.get_string(0), "").strip_edges()
	else:
		retry_needed = true

	if retry_needed or reply.length() > 400:
		print("❌ Invalid format or too long. Retrying...")
		message_history.insert(0, {
			"role": "system",
			"content": "Your last response failed format or exceeded 400 characters. Try again. Start with [happy/sad/angry/default] and end with (RELATIONSHIP: X). Speak only in third person."
		})
		send_request()
		return

	Memory.add_message(ai_name, reply, "User")
	GameState.last_ai_response = reply
	chat_log.append({ "role": "assistant", "content": reply })

	response_label.call("show_text_with_typing", reply)
	update_emotion_sprite(emotion)
	check_for_area_mentions(reply)

func update_emotion_sprite(emotion: String):
	emotion_happy.visible = false
	emotion_sad.visible = false
	emotion_angry.visible = false
	emotion_default.visible = false

	match emotion:
		"happy": emotion_happy.visible = true
		"sad": emotion_sad.visible = true
		"angry": emotion_angry.visible = true
		"default": emotion_default.visible = true

func check_for_area_mentions(reply: String):
	for area in known_areas:
		if area in reply.to_lower() and area not in unlocked_areas:
			unlocked_areas.append(area)
			MapMemory.unlock_area(area)

func _on_next_button_pressed():
	if GameState.should_end_game:
		GameState.end_game()
		return

	# ✅ Handle delayed new day transition
	if GameState.just_started_new_day:
		GameState.just_started_new_day = false
		GameState.should_reset_ai = true
		GameState.last_ai_response = ""
		message_history.clear()
		chat_log.clear()
		get_tree().change_scene_to_file("res://Scene stuff/map.tscn")
		return

	var msg = input_field.text.strip_edges()
	if msg == "":
		return

	input_field.text = ""
	GameState.use_action()
	update_day_state()

	Memory.add_message("User", msg, ai_name)
	message_history.append({ "role": "user", "content": msg })
	chat_log.append({ "role": "user", "content": msg })
	send_request()

func _on_chat_log_pressed():
	var log := ""
	for entry in chat_log:
		if entry["role"] == "user":
			log += "🧑 You: " + entry["content"] + "\n\n"
		else:
			log += "🤖 Kelp Man: " + entry["content"] + "\n\n"
	chat_log_label.text = log.strip_edges()
	chat_log_window.popup_centered()

func update_day_state():
	if day_state:
		day_state.text = "Day: %d | Actions: %d" % [GameState.days_left, GameState.actions_left]
