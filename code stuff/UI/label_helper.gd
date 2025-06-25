extends Control
class_name LabelHelper

## Helper class for configuring RichTextLabel auto-resizing
## Attach this to a container that holds your RichTextLabel

@export var target_label: RichTextLabel
@export var min_width: int = 100
@export var min_height: int = 50
@export var max_width: int = 800
@export var max_height: int = 400

func _ready():
	if not target_label:
		# Try to find RichTextLabel in children
		target_label = find_child("*", true, false) as RichTextLabel
	
	if target_label:
		configure_label()

func configure_label():
	if not target_label:
		return
	
	# Set proper layout configuration
	target_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Configure text behavior
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_label.fit_content = true
	target_label.clip_contents = false
	target_label.scroll_active = false
	
	# Connect to parent resize if needed
	if get_parent() is Control:
		var parent_control = get_parent() as Control
		if not parent_control.resized.is_connected(_on_parent_resized):
			parent_control.resized.connect(_on_parent_resized)

func _on_parent_resized():
	if target_label:
		# Force label to recalculate size
		target_label.queue_redraw()
		call_deferred("_update_label_constraints")

func _update_label_constraints():
	if not target_label:
		return
	
	var parent_size = get_size()
	if parent_size.x <= 0 or parent_size.y <= 0:
		return
	
	# Ensure label doesn't exceed constraints
	var constrained_size = Vector2(
		clamp(parent_size.x, min_width, max_width),
		clamp(parent_size.y, min_height, max_height)
	)
	
	target_label.custom_minimum_size = Vector2(min_width, min_height)
	target_label.size = constrained_size 