extends Node

var API_KEY = "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"  # Replace this with your real OpenRouter API key
var MODEL = "meta-llama/llama-4-scout:free"

@onready var http_request = $HTTPRequest
@onready var chat_log = $ChatUI/ChatLog
@onready var input_field = $ChatUI/HBoxContainer/PlayerInput
@onready var send_button = $ChatUI/HBoxContainer/SendButton
@onready var typing_timer = $TypingTimer
@onready var emotion_sprite_root = $Player_test_1

func update_emotion_sprite(emotion: String):
	for child in emotion_sprite_root.get_children():
		child.visible = false  # Hide all first

	match emotion:
		"happy":
			$Player_test_1/Happy.visible = true
		"sad":
			$Player_test_1/Sad.visible = true
		"angry":
			$Player_test_1/Angry.visible = true
		"default":
			$Player_test_1/Default.visible = true
		_:
			pass  # Show nothing or you could show a default face here


var timer: Timer
var current_text := ""
var current_index := 0


func _on_send_button_pressed():
	var message = input_field.text.strip_edges()
	if message != "":
		add_message("You", message)
		input_field.text = ""
		start_conversation(message)

func add_message(speaker: String, message: String):
	chat_log.text += speaker + ": " + message + "\n"
	chat_log.scroll_vertical = chat_log.get_line_count()  # scroll to bottom

func start_conversation(player_message: String):
	var url = "https://openrouter.ai/api/v1/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + API_KEY
	]

	var body = {
		"model": MODEL,
		"messages": [
			{"role": "system", "content": "You are a normal guy. Begin each reply with [emotion] based on the following emotions [angry, happy, sad] if you feel emotion corlates to what they say for intsance (hi) just use [default]"},
			{"role": "user", "content": player_message}
		]
	}

	var json_body = JSON.stringify(body)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json_text = body.get_string_from_utf8()
	print("DEBUG RESPONSE:\n", json_text)  # 👈 Print the full reply!

	var json = JSON.parse_string(json_text)

	if json and json.has("choices"):
		var reply = json["choices"][0]["message"]["content"]

		# Detect emotion
		var emotion := "default"
		var regex = RegEx.new()
		regex.compile("^\\[(.*?)\\]")
		var match = regex.search(reply)
		if match:
			emotion = match.get_string(1).to_lower()
			reply = reply.replace(match.get_string(0), "").strip_edges()

		# Set typing and sprite
		current_text = "Normal guy: " + reply + "\n"
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
