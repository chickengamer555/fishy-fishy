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
