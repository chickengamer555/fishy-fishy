extends Node2D

@onready var kelp_man = $Kelp_man_cove

func _on_bar_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	# Add bar scene transition here when available
	print("Bar pressed - scene not yet implemented")
func _on_kelp_man_pressed() -> void:
	AudioManager.play_button_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scene stuff/Charcters/kelp_man.tscn")
	MapMemory.set_location("kelp man cove")

func _ready():
	print("🗓️ Days: %d, Actions: %d" % [GameState.days_left, GameState.actions_left])
	for child in get_children():
		# Assume buttons are named after the areas (e.g. "bar", "forest")
		var area_name := child.name.to_lower()
		
		if area_name in MapMemory.unlocked_areas:
			child.visible = true
		else:
			child.visible = false
	kelp_man.visible = true
