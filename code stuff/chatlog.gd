extends Window
class_name ChatLog

@onready var chat_log_label = $ChatLogPanel/VBoxContainer/ScrollContainer/ChatLogLabel
@onready var chat_log_status_label = $ChatLogPanel/VBoxContainer/StatusLabel
@onready var chat_log_title_label = $ChatLogPanel/VBoxContainer/TitleLabel

# Simple font size control
var chat_font_size := 12

# Chat window fullscreen state
var chat_window_is_fullscreen := false
var chat_window_normal_size := Vector2i(600, 400)
var chat_window_normal_position := Vector2i(200, 100)

# Chat log data
var chat_log: Array = []

func _ready():
	# Connect window signals
	size_changed.connect(_on_window_resized)
	close_requested.connect(_on_window_close_requested)

func show_chat_log():
	update_chat_log_display()
	
	# Only popup if not already visible to avoid resetting styling
	if not visible:
		popup_centered()
		
		# Apply initial scaling and constraints
		await get_tree().process_frame
		update_text_scaling()
		constrain_window_position()
	else:
		# Just bring to front if already visible
		move_to_foreground()

func add_message(role: String, content: String):
	chat_log.append({ "role": role, "content": content })
	
	# Update display if window is visible
	if visible:
		update_chat_log_display()

func clear_chat_log():
	chat_log.clear()
	update_chat_log_display()

func update_chat_log_display():
	var log := ""
	var message_count := 0
	
	for entry in chat_log:
		message_count += 1
		if entry["role"] == "user":
			log += "[color=#4A90E2][b]🧑 You:[/b][/color]\n"
			log += "[color=#FFFFFF]" + entry["content"] + "[/color]\n\n"
		else:
			log += "[color=#2ECC71][b]🌿 Kelp Man:[/b][/color]\n"
			log += "[color=#E8E8E8]" + entry["content"] + "[/color]\n\n"
	
	if log.is_empty():
		log = "[center][color=#888888][i]No conversation history yet...[/i][/color][/center]"
		message_count = 0
	
	chat_log_label.text = log.strip_edges()
	chat_log_status_label.text = str(message_count) + " messages"

func _on_window_close_requested():
	hide()

func _on_window_resized():
	update_text_scaling()
	constrain_window_position()

func update_text_scaling():
	var window_size = size
	var base_size = Vector2(600, 400)  # Reference size
	var scale_factor = min(window_size.x / base_size.x, window_size.y / base_size.y)
	scale_factor = clamp(scale_factor, 0.7, 2.0)  # Limit scaling range
	
	# Scale title font
	chat_log_title_label.add_theme_font_size_override("font_size", int(16 * scale_factor))
	
	# Scale chat content font using the user's preferred size
	chat_log_label.add_theme_font_size_override("normal_font_size", int(chat_font_size * scale_factor))
	
	# Scale status label font
	chat_log_status_label.add_theme_font_size_override("font_size", int(10 * scale_factor))

func constrain_window_position():
	var screen_size = DisplayServer.screen_get_size()
	var window_size = size
	var window_pos = position
	
	# Constrain to screen bounds
	window_pos.x = clamp(window_pos.x, 0, screen_size.x - window_size.x)
	window_pos.y = clamp(window_pos.y, 0, screen_size.y - window_size.y)
	
	position = window_pos

# Font size button handlers
func _on_increase_font_button_pressed():
	chat_font_size = min(chat_font_size + 2, 24)  # Max size 24
	chat_log_label.add_theme_font_size_override("normal_font_size", chat_font_size)

func _on_decrease_font_button_pressed():
	chat_font_size = max(chat_font_size - 2, 8)   # Min size 8
	chat_log_label.add_theme_font_size_override("normal_font_size", chat_font_size)

func _on_close_button_pressed():
	hide()

func _on_fullscreen_button_pressed():
	# Toggle chat window between normal size and screen-filling size
	if chat_window_is_fullscreen:
		# Return to normal size
		size = chat_window_normal_size
		position = chat_window_normal_position
		chat_window_is_fullscreen = false
		print("Chat window: Normal size")
	else:
		# Save current size/position before going fullscreen
		chat_window_normal_size = size
		chat_window_normal_position = position
		
		# Get the usable screen area (accounting for taskbars, etc.)
		var screen_rect = DisplayServer.screen_get_usable_rect()
		
		# Make window fill the usable screen area
		position = Vector2i(screen_rect.position.x, screen_rect.position.y)
		size = Vector2i(screen_rect.size.x, screen_rect.size.y)
		chat_window_is_fullscreen = true
		print("Chat window: Fullscreen size")
	
	# Update text scaling for new size
	await get_tree().process_frame
	update_text_scaling() 
