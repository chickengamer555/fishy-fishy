extends Node

var API_KEY = "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"  # Replace this with your real OpenRouter API key
var MODEL = "meta-llama/llama-4-maverick:free"

@onready var http_request = $HTTPRequest
@onready var chat_log = $ChatUI/ChatLog
@onready var input_field = $ChatUI/HBoxContainer/PlayerInput
@onready var send_button = $ChatUI/HBoxContainer/SendButton
@onready var typing_timer = $TypingTimer


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
			{"role": "system", "content": "You are a litterly sea horse (horse in the sea) that responds with nothing but the sounds of a screaming drowing horse. Begin each reply with [emotion] based on the following emotions [dying]"},
			{"role": "user", "content": player_message}
		]
	}

	var json_body = JSON.stringify(body)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)

	if json and json.has("choices"):
		var reply = json["choices"][0]["message"]["content"]
		chat_log.text += "Sea horse: "  # Start the line
		current_text = reply + "\n"
		current_index = 0
		typing_timer.start()
	else:
		add_message("System", "Error: No valid reply.")
		



func _on_TypingTimer_timeout():
	if current_index < current_text.length():
		chat_log.text += current_text[current_index]
		current_index += 1
		chat_log.scroll_vertical = chat_log.get_line_count()
	else:
		typing_timer.stop()
