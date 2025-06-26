extends Control

static var previous_scene: String

@onready var master_slider = $VBoxContainer/MasterVolume/HSlider
@onready var music_slider = $VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider = $VBoxContainer/SFXVolume/HSlider

func _ready() -> void:
	# Connect volume sliders to their respective functions
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		master_slider.value = AudioManager.get_master_volume()
	
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		music_slider.value = AudioManager.get_music_volume()
	
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_slider.value = AudioManager.get_sfx_volume()

func _on_master_volume_changed(value: float):
	AudioManager.set_master_volume(value)

func _on_music_volume_changed(value: float):
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float):
	AudioManager.set_sfx_volume(value)

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	
	if previous_scene.is_empty():
		# Fallback to map if no previous scene is set
		get_tree().change_scene_to_file("res://Scene stuff/Main/map.tscn")
	else:
		get_tree().change_scene_to_file(previous_scene)

func _on_end_buttton_pressed() -> void:
	AudioManager.play_button_click()
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirm Exit"
	dialog.dialog_text = "Are you sure you want to end the game?"
	
	# Connect the confirmed signal and handle dialog cleanup on close
	dialog.confirmed.connect(_on_end_game_confirmed)
	dialog.close_requested.connect(_on_dialog_closed.bind(dialog))
	
	add_child(dialog)
	dialog.popup_centered()

func _on_end_game_confirmed():
	AudioManager.play_button_click()
	# Only end the game if the user confirmed
	GameState.end_game()

func _on_dialog_closed(dialog: ConfirmationDialog):
	# Clean up the dialog when it's closed (regardless of how it was closed)
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
