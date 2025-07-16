extends RichTextLabel

# Auto-resizing configuration - similar to working older version
@export var max_font_size: int = 80
@export var min_font_size: int = 4
@export var padding_factor: float = 0.05  # 5% padding instead of fixed pixels
@export var type_speed: float = 0.01  # seconds per character

# Typing effect variables
var typing_timer: Timer
var full_text: String = ""
var current_char_index: int = 0
var is_typing: bool = false

# Reference to the kelp_man node for animation callbacks
var kelp_man_node: Node

func _ready() -> void:
	# Get reference to kelp_man for animation callbacks with error handling
	if has_node("../.."):
		kelp_man_node = get_node("../..")
	else:
		print("Warning: Could not find kelp_man node for animation callbacks")
	
	# Create typing timer
	typing_timer = Timer.new()
	typing_timer.wait_time = type_speed
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)
	
	# Connect resize signal
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)

func show_text_with_typing(new_text: String) -> void:
	"""Display text with typing effect and auto-resize to fit perfectly"""
	if is_typing:
		stop_typing()
	
	full_text = new_text
	current_char_index = 0
	text = ""
	is_typing = true
	
	# Fit font to label
	_fit_font_to_label(full_text)
	
	# Start kelp man talking animation
	if kelp_man_node and kelp_man_node.has_method("start_talking_animation"):
		kelp_man_node.start_talking_animation()
	
	# Start typing effect
	typing_timer.start()

func _fit_font_to_label(preview_text: String) -> void:
	"""Calculate and apply optimal font size using multiples of 8"""
	if preview_text.is_empty():
		return

	# Wait for layout to be ready
	await get_tree().process_frame
	
	var label_size := get_size()
	
	# Better size detection with fallback
	if label_size.x <= 0 or label_size.y <= 0:
		# Try to get parent container size
		var parent = get_parent()
		if parent is Control:
			label_size = parent.get_size()
		elif parent is CanvasItem:
			var rect = parent.get_rect()
			label_size = rect.size
		
		# Final fallback
		if label_size.x <= 0 or label_size.y <= 0:
			label_size = Vector2(600, 200)
	
	# Calculate padding based on label size
	var padding_x = max(4, label_size.x * padding_factor)
	var padding_y = max(4, label_size.y * padding_factor)
	var available_size = Vector2(label_size.x - padding_x * 2, label_size.y - padding_y * 2)
	
	print("Label size: ", label_size, " Available size: ", available_size, " Text length: ", preview_text.length())
	
	# Generate available font sizes as multiples of 8
	var available_sizes: Array[int] = []
	var current_size = min_font_size
	
	# Round min_font_size up to nearest multiple of 8
	var rounded_min = ((min_font_size + 7) / 8) * 8
	current_size = rounded_min
	
	# Generate all multiples of 8 up to max_font_size
	while current_size <= max_font_size:
		available_sizes.append(current_size)
		current_size += 8
	
	# If no sizes were generated, use min_font_size
	if available_sizes.is_empty():
		available_sizes.append(min_font_size)
	
	print("Available font sizes: ", available_sizes)
	
	var best_fit_size := available_sizes[0]  # Start with smallest
	
	# Test each size from largest to smallest
	for i in range(available_sizes.size() - 1, -1, -1):
		var test_size = available_sizes[i]
		var paragraph := TextParagraph.new()
		paragraph.width = available_size.x
		paragraph.add_string(preview_text, get_theme_font("normal_font"), test_size)
		var measured := paragraph.get_size()
		
		# Check if text fits within available space
		if measured.x <= available_size.x and measured.y <= available_size.y:
			best_fit_size = test_size
			break  # Found the largest size that fits
	
	print("Optimal font size: ", best_fit_size, " for available space: ", available_size)
	
	add_theme_font_size_override("normal_font_size", best_fit_size)

func _on_typing_timer_timeout() -> void:
	"""Handle typing effect timer"""
	if not is_typing or current_char_index >= full_text.length():
		stop_typing()
		return
	
	# Add next character
	current_char_index += 1
	text = full_text.substr(0, current_char_index)
	
	# Trigger kelp man animation tick
	if kelp_man_node and kelp_man_node.has_method("on_typing_tick"):
		kelp_man_node.on_typing_tick()

func stop_typing() -> void:
	"""Stop typing effect and complete text display"""
	if not is_typing:
		return
		
	is_typing = false
	typing_timer.stop()
	
	# Show complete text
	text = full_text
	
	# Stop kelp man talking animation
	if kelp_man_node and kelp_man_node.has_method("stop_talking_animation"):
		kelp_man_node.stop_talking_animation()

func set_text_instantly(new_text: String) -> void:
	"""Set text instantly without typing effect, with auto-resize"""
	stop_typing()
	
	full_text = new_text
	text = new_text
	
	# Auto-resize to fit
	_fit_font_to_label(new_text)

# Public methods for external control
func set_typing_speed(speed: float) -> void:
	"""Set the typing effect speed"""
	type_speed = clamp(speed, 0.01, 1.0)
	if typing_timer:
		typing_timer.wait_time = type_speed

func set_font_size_range(min_size: int, max_size: int) -> void:
	"""Set the min and max font sizes for auto-resizing"""
	min_font_size = max(1, min_size)
	max_font_size = max(min_font_size, max_size)

func get_current_font_size() -> int:
	"""Get the current font size"""
	var current_size = get_theme_font_size("normal_font_size")
	return current_size if current_size > 0 else min_font_size

func _on_resized() -> void:
	"""Handle when the RichTextLabel is resized"""
	if not text.is_empty():
		# Re-calculate optimal size when container is resized
		_fit_font_to_label(text)
