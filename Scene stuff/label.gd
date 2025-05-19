extends Label

@export var font_path := "res://PixelifySans-VariableFont_wght.ttf"
@export var max_font_size := 40
@export var min_font_size := 1
@export var type_speed := 0.01  # seconds per character

var full_text := ""
var current_char := 0
var is_typing := false

@onready var typing_timer := $"../../TypingTimer"

func _ready():
	item_rect_changed.connect(_on_size_changed)
	typing_timer.timeout.connect(_on_typing_timer_timeout)

func show_text_with_typing(text_to_show: String):
	full_text = text_to_show
	current_char = 0
	text = ""
	is_typing = true
	typing_timer.wait_time = type_speed
	typing_timer.start()

func _on_typing_timer_timeout():
	if current_char >= full_text.length():
		typing_timer.stop()
		is_typing = false
		return

	current_char += 1
	text = full_text.substr(0, current_char)
	_fit_font_to_label()

func _on_size_changed():
	if not is_typing:
		_fit_font_to_label()

func _fit_font_to_label():
	var font_data: FontFile = load(font_path)
	if font_data == null:
		push_error("Font file not found!")
		return

	var label_size := get_size()
	var final_size := min_font_size

	for font_size in range(max_font_size, min_font_size - 1, -1):
		var paragraph := TextParagraph.new()
		paragraph.width = label_size.x
		paragraph.add_string(text, font_data, font_size)
		var measured := paragraph.get_size()

		if measured.x <= label_size.x and measured.y <= label_size.y:
			final_size = font_size
			break

	add_theme_font_override("font", font_data)
	add_theme_font_size_override("font_size", final_size)
