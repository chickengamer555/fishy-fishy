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
	# Enable text wrapping but disable scrolling
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_active = false  # Disable scrolling
	bbcode_enabled = true
	fit_content = false  # Let it use full container size
	clip_contents = true
	
	# Load font once for better performance
	cached_font_data = load(font_path)
	if cached_font_data == null:
		push_error("Font file not found at: " + font_path)
		# Try alternative path
		cached_font_data = load("res://Other/PixelifySans-VariableFont_wght.ttf")
		if cached_font_data == null:
			push_error("Font file not found at alternative path either")
	
	# Connect to resize signal for dynamic font adjustment
	resized.connect(_on_label_resized)
	
	# Force initial resize to ensure proper font sizing
	await get_tree().process_frame
	_on_label_resized()

func _on_label_resized():
	# Refit font when label is resized
	if not full_text.is_empty():
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
	if cached_font_data == null:
		return

	# Wait for layout to be ready
	await get_tree().process_frame
	
	var label_size := get_size()
	
	# Better size detection with more aggressive fallback
	if label_size.x <= 0 or label_size.y <= 0:
		# Try to get parent container size
		var parent = get_parent()
		if parent is Control:
			label_size = parent.get_size()
		elif parent is CanvasItem:
			var rect = parent.get_rect()
			label_size = rect.size
		
		# Final fallback with better proportions
		if label_size.x <= 0 or label_size.y <= 0:
			label_size = Vector2(600, 200)  # More realistic fallback
	
	# Calculate padding based on label size for better space utilization
	var padding_x = max(4, label_size.x * padding_factor)  # Minimum 4px padding
	var padding_y = max(4, label_size.y * padding_factor)
	var available_size = Vector2(label_size.x - padding_x * 2, label_size.y - padding_y * 2)
	
	print("Label size: ", label_size, " Available size: ", available_size, " Text length: ", preview_text.length())
	
	# Ensure min and max font sizes are multiples of 4
	var adjusted_min_size := _round_to_multiple_of_4(min_font_size)
	var adjusted_max_size := _round_to_multiple_of_4(max_font_size)
	
	var final_size := adjusted_min_size  # Start with minimum and work up
	var best_fit_size := adjusted_min_size
	
	# Test font sizes in multiples of 4 from min to max
	var current_size := adjusted_min_size
	while current_size <= adjusted_max_size:
		var paragraph := TextParagraph.new()
		paragraph.width = available_size.x
		paragraph.add_string(preview_text, cached_font_data, current_size)
		var measured := paragraph.get_size()
		
		# Check if text fits within available space
		if measured.x <= available_size.x and measured.y <= available_size.y:
			best_fit_size = current_size
		else:
			break  # Size too big, use the last working size
		
		current_size += 4  # Increment by 4 for clean multiples
	
	final_size = best_fit_size
	print("Optimal font size (multiple of 4): ", final_size, " for available space: ", available_size)
	
	add_theme_font_override("normal_font", cached_font_data)
	add_theme_font_size_override("normal_font_size", final_size)

# Helper function to round a number to the nearest multiple of 4
func _round_to_multiple_of_4(value: int) -> int:
	return int(round(value / 4.0) * 4)
