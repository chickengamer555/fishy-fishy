extends Control

static var previous_scene: String

func _ready() -> void:
	# No need to store scene here anymore since it's already stored before transition
	pass

func _on_back_button_pressed() -> void:
	if previous_scene.is_empty():
		# Fallback to map if no previous scene is set
		get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")
	else:
		get_tree().change_scene_to_file(previous_scene)

func _on_end_buttton_pressed() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirm Exit"
	dialog.dialog_text = "Are you sure you want to end the game?"
	
	# Connect the confirmed signal and handle dialog cleanup on close
	dialog.confirmed.connect(_on_end_game_confirmed)
	dialog.close_requested.connect(_on_dialog_closed.bind(dialog))
	
	add_child(dialog)
	dialog.popup_centered()

func _on_end_game_confirmed():
	# Only end the game if the user confirmed
	GameState.end_game()

func _on_dialog_closed(dialog: ConfirmationDialog):
	# Clean up the dialog when it's closed (regardless of how it was closed)
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
