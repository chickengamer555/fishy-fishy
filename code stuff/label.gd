extends RichTextLabel

@export var font_path := "res://Jersey20-Regular.ttf"
@export var max_font_size := 40
@export var min_font_size := 4
@export var type_speed := 0.01  # seconds per character

var full_text := ""
var current_char := 0
var is_typing := false

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
	var font_data: FontFile = load(font_path)
	if font_data == null:
		push_error("Font file not found at: " + font_path)
		return

	# Wait for layout to be ready
	var tree = get_tree()
	if tree:
		await tree.process_frame
	
	var label_size := get_size()
	
	# Ensure minimum size with better fallback
	if label_size.x < 100 or label_size.y < 50:
		# Get parent size if available
		var parent_size = get_parent_area_size()
		if parent_size != Vector2.ZERO:
			label_size = parent_size
		else:
			label_size = Vector2(400, 150)  # Fallback size
	
	print("Label size: ", label_size, " Text length: ", preview_text.length())
	
	var final_size := max_font_size  # Start with max size instead of min

	# Start with max font size and adjust down until text fits both width AND height
	for font_size in range(max_font_size, min_font_size - 1, -1):
		var paragraph := TextParagraph.new()
		paragraph.width = label_size.x - 20  # Account for padding
		paragraph.add_string(preview_text, font_data, font_size)
		var measured := paragraph.get_size()

		# Check if text fits both width and height constraints
		if measured.x <= (label_size.x - 20) and measured.y <= (label_size.y - 20):
			final_size = font_size
			print("Selected font size: ", final_size, " for text bounds: ", measured)
			break

	# Ensure we never go below minimum font size
	final_size = max(final_size, min_font_size)
	
	add_theme_font_override("normal_font", font_data)
	add_theme_font_size_override("normal_font_size", final_size)
