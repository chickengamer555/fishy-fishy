extends Control

static var previous_scene: String

@onready var master_slider = $VBoxContainer/MasterVolume/HSlider
@onready var music_slider = $VBoxContainer/MusicVolume/HSlider
@onready var sfx_slider = $VBoxContainer/SFXVolume/HSlider
@onready var end_game_dialog = $EndGameDialog

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
	
	# Style the end game dialog
	style_end_game_dialog()

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

func _on_end_button_pressed() -> void:
	AudioManager.play_button_click()
	end_game_dialog.popup_centered()

func _on_end_game_confirmed():
	AudioManager.play_button_click()
	# Only end the game if the user confirmed
	GameState.end_game()

func style_end_game_dialog():
	if not end_game_dialog:
		return
	
	# Load the font
	var font = load("res://Other/Tiny5-Regular.ttf")
	
	# Create custom background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0392157, 0.113725, 0.180392, 1)  # Dark blue background
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color(0.12549, 0.572549, 0.682353, 1)  # Teal border
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	
	# Apply styling via code
	end_game_dialog.add_theme_color_override("title_color", Color(1, 1, 1, 1))
	end_game_dialog.add_theme_font_override("title_font", font)
	end_game_dialog.add_theme_font_size_override("title_font_size", 24)
	end_game_dialog.add_theme_font_override("font", font)
	end_game_dialog.add_theme_font_size_override("font_size", 20)
	end_game_dialog.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	end_game_dialog.add_theme_stylebox_override("panel", bg_style)
