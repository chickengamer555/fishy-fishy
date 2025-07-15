extends RichTextLabel

# Auto-resizing configuration
@export var allowed_font_sizes: Array[int] = [24, 16, 8]  # Sizes to try, largest first
@export var default_font_size: int = 8
@export var padding_pixels: int = 4  # Extra padding to prevent tight fits

# Typing effect variables
var typing_timer: Timer
var full_text: String = ""
var current_char_index: int = 0
var typing_speed: float = 0.05
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
	typing_timer.wait_time = typing_speed
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
	
	# Try complex font sizing, fall back to simple if needed
	if get_rect().size.x > 0 and get_rect().size.y > 0:
		_calculate_and_apply_font_size(full_text)
	else:
		# Fallback to quick resize if size is not available yet
		quick_resize(full_text.length())
	
	# Start kelp man talking animation
	if kelp_man_node and kelp_man_node.has_method("start_talking_animation"):
		kelp_man_node.start_talking_animation()
	
	# Start typing effect
	typing_timer.start()

func _calculate_and_apply_font_size(text_to_measure: String) -> void:
	"""Calculate and apply optimal font size asynchronously"""
	var optimal_size = await calculate_optimal_font_size(text_to_measure)
	add_theme_font_size_override("normal_font_size", optimal_size)
	print("Applied font size: ", optimal_size, " for text length: ", text_to_measure.length())

func calculate_optimal_font_size(text_to_measure: String) -> int:
	"""Calculate the optimal font size to fit text within bounds"""
	if text_to_measure.is_empty():
		return default_font_size
	
	# Get available space
	var available_size = get_rect().size
	available_size.x -= padding_pixels * 2
	available_size.y -= padding_pixels * 2
	
	# Try each allowed font size from largest to smallest
	for font_size in allowed_font_sizes:
		var fits = await text_fits_at_size(text_to_measure, font_size, available_size)
		if fits:
			print("Font size ", font_size, " fits for text length: ", text_to_measure.length())
			return font_size
	
	# If none fit, return the smallest size
	var smallest_size = allowed_font_sizes[-1]
	print("No size fits perfectly, using smallest: ", smallest_size)
	return smallest_size

func text_fits_at_size(text_to_check: String, font_size: int, available_space: Vector2) -> bool:
	"""Check if text fits within given space at specified font size"""
	
	# Quick fallback for empty text or invalid space
	if text_to_check.is_empty() or available_space.x <= 0 or available_space.y <= 0:
		return true
	
	# Create a temporary RichTextLabel to measure text
	var temp_label = RichTextLabel.new()
	temp_label.bbcode_enabled = bbcode_enabled
	temp_label.autowrap_mode = autowrap_mode
	temp_label.fit_content = true
	
	# Copy font and styling
	if get_theme_font("normal_font"):
		temp_label.add_theme_font_override("normal_font", get_theme_font("normal_font"))
	temp_label.add_theme_font_size_override("normal_font_size", font_size)
	if get_theme_color("default_color"):
		temp_label.add_theme_color_override("default_color", get_theme_color("default_color"))
	
	# Set size and text
	temp_label.size = available_space
	temp_label.text = text_to_check
	
	# Add to scene temporarily to get accurate measurements
	add_child(temp_label)
	await get_tree().process_frame
	
	# Get content height with fallback
	var content_height = temp_label.get_content_height()
	var fits = content_height <= available_space.y
	
	# Clean up
	temp_label.queue_free()
	
	return fits

func auto_resize_to_fit(text_to_fit: String = "") -> void:
	"""Automatically resize font to fit current or specified text"""
	var target_text = text_to_fit if not text_to_fit.is_empty() else text
	
	if target_text.is_empty():
		return
	
	_calculate_and_apply_font_size(target_text)
	
	# Force update
	queue_redraw()

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
	_calculate_and_apply_font_size(new_text)

# Public methods for external control
func set_typing_speed(speed: float) -> void:
	"""Set the typing effect speed"""
	typing_speed = clamp(speed, 0.01, 1.0)
	if typing_timer:
		typing_timer.wait_time = typing_speed

func set_allowed_font_sizes(sizes: Array[int]) -> void:
	"""Set the allowed font sizes for auto-resizing"""
	if sizes.size() > 0:
		allowed_font_sizes = sizes
		# Sort in descending order (largest first)
		allowed_font_sizes.sort()
		allowed_font_sizes.reverse()

func get_current_font_size() -> int:
	"""Get the current font size"""
	var current_size = get_theme_font_size("normal_font_size")
	return current_size if current_size > 0 else default_font_size

func _on_resized() -> void:
	"""Handle when the RichTextLabel is resized"""
	if not text.is_empty():
		# Re-calculate optimal size when container is resized
		_calculate_and_apply_font_size(text)

# Simple fallback method for immediate font sizing without complex measurement
func quick_resize(text_length: int) -> void:
	"""Quick font resize based on text length as fallback"""
	var chosen_size: int
	
	# Choose font size based on text length thresholds
	if text_length <= 100:
		chosen_size = 24  # Short text gets largest font
	elif text_length <= 250:
		chosen_size = 16  # Medium text gets medium font
	else:
		chosen_size = 8   # Long text gets smallest font
	
	add_theme_font_size_override("normal_font_size", chosen_size)
	print("Quick resize applied: ", chosen_size, " for length: ", text_length)
