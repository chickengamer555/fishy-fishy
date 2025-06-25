extends RichTextLabel

@export var font_path := "res://Other/PixelifySans-VariableFont_wght.ttf"
@export var max_font_size := 96
@export var min_font_size := 8
@export var type_speed := 0.01  # seconds per character
@export var padding_factor := 0.05  # 5% padding instead of fixed 20px

var full_text := ""
var current_char := 0
var is_typing := false
var cached_font_data: FontFile

@onready var typing_timer := $"../../TypingTimer"
@onready var kelp_man_controller := $"../../"  # Reference to the main kelp_man node

func _ready():
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	
	# Configure RichTextLabel for proper auto-resizing
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_active = false  # Disable scrolling for fixed container
	bbcode_enabled = true
	fit_content = true  # Enable auto-sizing content
	clip_contents = false  # Allow content to be visible during resize
	
	# Set proper size flags for container behavior
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Load font once for better performance
	cached_font_data = load(font_path)
	if cached_font_data == null:
		push_error("Font file not found at: " + font_path)
		# Try alternative path
		cached_font_data = load("res://Other/Tiny5-Regular.ttf")
		if cached_font_data == null:
			push_error("Font file not found at alternative path either")
	
	# Connect to resize signal for dynamic font adjustment
	resized.connect(_on_label_resized)
	
	# Wait for proper layout before initial resize
	call_deferred("_initialize_sizing")

func _initialize_sizing():
	# Force initial resize to ensure proper font sizing
	await get_tree().process_frame
	await get_tree().process_frame  # Wait extra frame for layout
	_on_label_resized()

func _on_label_resized():
	# Only refit if we have valid size and text
	if get_size().x > 0 and get_size().y > 0 and not full_text.is_empty():
		_fit_font_to_label(full_text)
		# Update current display
		if not is_typing:
			clear()
			append_text(full_text)
		else:
			clear()
			append_text(full_text.substr(0, current_char))

func show_text_with_typing(text_to_show: String):
	full_text = text_to_show
	current_char = 0
	clear()
	is_typing = true
	
	# Wait for layout before fitting font
	await get_tree().process_frame
	_fit_font_to_label(full_text)
	typing_timer.wait_time = type_speed

	typing_timer.start()
	
	# Start talking animation
	if kelp_man_controller and kelp_man_controller.has_method("start_talking_animation"):
		kelp_man_controller.start_talking_animation()

func _on_typing_timer_timeout():
	if current_char >= full_text.length():
		typing_timer.stop()
		is_typing = false
		
		# Stop talking animation
		if kelp_man_controller and kelp_man_controller.has_method("stop_talking_animation"):
			kelp_man_controller.stop_talking_animation()
		return

	current_char += 1
	clear()
	append_text(full_text.substr(0, current_char))
	
	# Trigger talking animation tick
	if kelp_man_controller and kelp_man_controller.has_method("on_typing_tick"):
		kelp_man_controller.on_typing_tick()

func _fit_font_to_label(preview_text: String):
	if cached_font_data == null or preview_text.is_empty():
		return

	# Get current size - should be valid now with proper initialization
	var label_size := get_size()
	
	# Enhanced size detection with better fallbacks
	if label_size.x <= 0 or label_size.y <= 0:
		# Try to get size from container chain
		var current_parent = get_parent()
		while current_parent and (label_size.x <= 0 or label_size.y <= 0):
			if current_parent is Control:
				var parent_size = current_parent.get_size()
				if parent_size.x > 0 and parent_size.y > 0:
					label_size = parent_size
					break
			elif current_parent is CanvasItem:
				var rect = current_parent.get_rect()
				if rect.size.x > 0 and rect.size.y > 0:
					label_size = rect.size
					break
			current_parent = current_parent.get_parent()
		
		# Final fallback with reasonable proportions
		if label_size.x <= 0 or label_size.y <= 0:
			label_size = Vector2(600, 200)
	
	# Calculate available space with padding
	var padding_x = max(8, label_size.x * padding_factor)  # Minimum 8px padding
	var padding_y = max(8, label_size.y * padding_factor)
	var available_size = Vector2(
		max(50, label_size.x - padding_x * 2),  # Ensure minimum working space
		max(20, label_size.y - padding_y * 2)
	)
	
	print("Label auto-resize - Size: ", label_size, " Available: ", available_size, " Text: ", preview_text.length(), " chars")
	
	# Find optimal font size using binary search for efficiency
	var min_size = max(8, min_font_size)
	var max_size = min(96, max_font_size)
	var optimal_size = min_size
	
	# Binary search for optimal font size
	while min_size <= max_size:
		var mid_size = (min_size + max_size) / 2
		var paragraph = TextParagraph.new()
		paragraph.width = available_size.x
		paragraph.add_string(preview_text, cached_font_data, mid_size)
		var measured = paragraph.get_size()
		
		# Check if text fits
		if measured.x <= available_size.x and measured.y <= available_size.y:
			optimal_size = mid_size
			min_size = mid_size + 1  # Try larger size
		else:
			max_size = mid_size - 1  # Try smaller size
	
	print("Optimal font size: ", optimal_size)
	
	# Apply the font and size
	add_theme_font_override("normal_font", cached_font_data)
	add_theme_font_size_override("normal_font_size", optimal_size)
	
	# Force update layout
	queue_redraw()
