extends Node

@onready var http_request = $HTTPRequest
var ENCODED_KEY = "c2stcHJvai1XNk1BcXVFR0FmQ0NpTl9BWWlJRlJtX08tcVlkbEJKaGZNVGg3Zml2SGR6aUVUOWx0T2JIRzI5cURxeV9OMEk4UGdaN1lCczRNMVQzQmxia0ZKTVJDUkdWNFd6Z0ZzbG5CejZhRzlzOGZvd3h3THlaVkpxVzQ5RldhNzdYRWZ5ZXJvMXBPVHVsVVh5RUk5X1RvZ0xKRFA5ZjlVMEE="
func get_api_key():
	var decoded_bytes = Marshalls.base64_to_raw(ENCODED_KEY)
	return decoded_bytes.get_string_from_utf8()

var API_KEY = get_api_key()
var MODEL = "gpt-4o"

@onready var chat_log = $ChatUI/ChatLog
@onready var input_field = $ChatUI/HBoxContainer/PlayerInput
@onready var send_button = $ChatUI/HBoxContainer/SendButton
@onready var typing_timer = $TypingTimer
@onready var emotion_sprite_root = $horse_emotion

@export var ai_name := "woman"  # <-- CHANGE THIS per AI (e.g., Guy, Horse, etc.)

var message_history: Array = [
	{
		"role": "system",
		"content":
		"You are a human-like character named Woman. React and speak like a angry person would.\n" +
		"Begin every reply with an [emotion] tag from: [angry, happy, sad]. DO NOT use [default] unless your netural.\n" +
		"NEVER write more than 250 characters. Even if asked for more, stick to that limit.\n\n" +

		"You will be shown Social Memory — a collection of everything said between the user and other characters.\n" +
		"If the user said something directly to you, treat it as something you personally remember.\n" +
		"If the user said something to another character, treat it as secondhand information — and react based on how your personality would feel about learning that.\n\n" +

		"If your personality would care about loyalty, romance, friendship, betrayal, or emotional contradictions, feel free to respond with jealousy, sarcasm, confusion, hurt, or emotional insight.\n" +
		"If your personality wouldn't care (e.g., you're scummy or flirty), feel free to respond casually, ignore the contradiction, or even be amused by it.\n\n" +

		"If another character says something in memory that’s about you, or contradicts something they’ve said earlier, react like a real person would — confused, suspicious, flattered, mad, or dismissive depending on your mood.\n" +
		"You're allowed to reference other characters’ conversations if they’re visible in memory.\n\n" +

		"Only say 'I remember' if the user told you something in a past message, not just moments ago. If it’s brand new, acknowledge it naturally.\n" +
		"Do not repeat the user's exact formatting (e.g., all caps) unless asked. Paraphrase naturally.\n\n" +

		"Always think about how your personality would react to what’s been said — and respond in a way that reflects your emotional state, style, and perspective."
	}
]


var timer: Timer
var current_text := ""
var current_index := 0

func _on_send_button_pressed():
	var player_message = input_field.text.strip_edges()
	if player_message != "":
		add_message("You", player_message)
		input_field.text = ""
		start_conversation(player_message)

		# ⬅️ STORE message in shared memory
		Memory.add_message("User", player_message, ai_name)

func add_message(speaker: String, message: String):
	chat_log.text += speaker + ": " + message + "\n"
	chat_log.scroll_vertical = chat_log.get_line_count()

func start_conversation(player_message: String):
	message_history = message_history.slice(0, 1)  # keep only system prompt

	# Inject social memory into system prompt
	if Memory.shared_memory.size() > 0:
		var memory_text = "Social Memory:\n"
		for entry in Memory.shared_memory:
			memory_text += "- " + entry["speaker"] + " said to " + entry["target"] + ": \"" + entry["message"] + "\"\n"
		memory_text += "End of Memory."

		message_history.append({
	"role": "system",
	"content":
	"You are an AI character. You will be shown Social Memory below. Each entry shows what one character said to another.\n" +
	"If YOU are the speaker in a memory, assume YOU said that message and remember it yourself.\n" +
	"If ANOTHER character heard something, reference them if you learned from their memory.\n" +
	"For example, if 'User said to Horse: I like cupcakes', and you are 'Guy', say: 'I believe Horse told me you love cupcakes.'\n" +
	"But if you are 'Horse', say: 'I remember you told me you love cupcakes.'\n\n" +
	"Important memories:\n\n" + memory_text

})


	# Add the user's new message
	message_history.append({"role": "user", "content": player_message})

	# Send API request
	var url = "https://api.openai.com/v1/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]
	var body = {
		"model": MODEL,
		"messages": message_history,
		"max_tokens": 200
	}
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json_text = body.get_string_from_utf8()
	print("DEBUG RESPONSE:\n", json_text)

	var json = JSON.parse_string(json_text)
	if json and json.has("choices"):
		var reply = json["choices"][0]["message"]["content"]

		# ⬅️ STORE AI reply in shared memory
		Memory.add_message(ai_name, reply, "User")

		message_history.append({"role": "assistant", "content": reply})

		# Emotion parsing
		var emotion := "default"
		var regex = RegEx.new()
		regex.compile("^\\[(.*?)\\]")
		var match = regex.search(reply)
		if match:
			emotion = match.get_string(1).to_lower()
			reply = reply.replace(match.get_string(0), "").strip_edges()

		current_text = "Normal %s: %s\n" % [ai_name.to_lower(), reply]
		current_index = 0
		typing_timer.start()
		update_emotion_sprite(emotion)
	else:
		add_message("System", "Error: No valid reply.")

func _on_TypingTimer_timeout():
	if current_index < current_text.length():
		chat_log.text += current_text[current_index]
		current_index += 1
		chat_log.scroll_vertical = chat_log.get_line_count()
	else:
		typing_timer.stop()

func update_emotion_sprite(emotion: String):
	for child in emotion_sprite_root.get_children():
		child.visible = false
	match emotion:
		"happy": $horse_emotion/Happy.visible = true
		"sad": $horse_emotion/Sad.visible = true
		"angry": $horse_emotion/Angry.visible = true
		"default": $horse_emotion/Default.visible = true
