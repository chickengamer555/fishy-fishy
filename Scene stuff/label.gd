extends Label

@export var font_path := "res://PixelifySans-VariableFont_wght.ttf"
@export var max_font_size := 40
@export var min_font_size := 10

func _ready() -> void:
	update_font_size()
	item_rect_changed.connect(update_font_size)

func update_font_size() -> void:
	var font_data: FontFile = load(font_path)
	if font_data == null:
		push_error("Font file not found!")
		return

	var current_size := max_font_size
	while current_size >= min_font_size:
		var paragraph := TextParagraph.new()
		paragraph.width = size.x
		paragraph.add_string(text, font_data, current_size)

		var measured := paragraph.get_size()
		if measured.x <= size.x and measured.y <= size.y:
			break

		current_size -= 1

	add_theme_font_override("font", font_data)
	add_theme_font_size_override("font_size", current_size)
