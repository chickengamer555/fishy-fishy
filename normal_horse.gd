extends Node

var API_KEY = "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"  # Replace with your OpenRouter key
var MODEL = "meta-llama/llama-4-scout:free"

@onready var http_request = $HTTPRequest
@onready var chat_log = $ChatUI/ChatLog
@onready var input_field = $ChatUI/HBoxContainer/PlayerInput
@onready var send_button = $ChatUI/HBoxContainer/SendButton
@onready var typing_timer = $TypingTimer
@onready var emotion_sprite_root = $horse_emotion

var message_history: Array = [
	{"role": "system", "content": "You are a normal horse. If anyone mentions darkness, you become Pajama Sam. Begin each reply with [emotion] based on these: [angry, happy, sad, darkness]. Use [default] if nothing fits. Only use [darkness] if someone mentions it."}
]

var social_memory: Array = []

func update_emotion_sprite(emotion: String):
	for child in emotion_sprite_root.get_children():
		child.visible = false
	match emotion:
		"happy": $horse_emotion/Happy.visible = true
		"sad": $horse_emotion/Sad.visible = true
		"angry": $horse_emotion/Angry.visible = true
		"darkness": $horse_emotion/Darkness.visible = true
		"default": $horse_emotion/Default.visible = true

var timer: Timer
var current_text := ""
var current_index := 0

func _on_send_button_pressed():
	social_memory.append({
	"role": "user",
	"content": input_field.text.strip_edges()
})
	var message = input_field.text.strip_edges()
	if message != "":
		add_message("You", message)
		input_field.text = ""
		start_conversation(message)

func add_message(speaker: String, message: String):
	chat_log.text += speaker + ": " + message + "\n"
	chat_log.scroll_vertical = chat_log.get_line_count()

func start_conversation(player_message: String):
	message_history.append({"role": "user", "content": player_message})

	# Inject shared memory (gossip, history, etc.)
	for memory in social_memory:
		message_history.insert(1, memory)  # insert near the front
	# API call
	var url = "https://openrouter.ai/api/v1/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]
	var body = {
		"model": MODEL,
		"messages": message_history
	}
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json_text = body.get_string_from_utf8()
	print("DEBUG RESPONSE:\n", json_text)

	var json = JSON.parse_string(json_text)
	if json and json.has("choices"):
		var reply = json["choices"][0]["message"]["content"]

		# Store horse's reply into guy's memory


		# Add reply to own chat log
		message_history.append({"role": "assistant", "content": reply})

		# Detect emotion
		var emotion := "default"
		var regex = RegEx.new()
		regex.compile("^\\[(.*?)\\]")
		var match = regex.search(reply)
		if match:
			emotion = match.get_string(1).to_lower()
			reply = reply.replace(match.get_string(0), "").strip_edges()

		# Animate reply
		current_text = "Normal horse: " + reply + "\n"
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
