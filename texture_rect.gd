extends TextureRect

var item_data: Dictionary

func set_item(data: Dictionary):
	item_data = data
	texture = data.icon
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_drag_data(_pos):
	var preview = TextureRect.new()
	preview.texture = texture
	set_drag_preview(preview)
	return item_data
