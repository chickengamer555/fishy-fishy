extends Node2D

@onready var kelp_man = $Kelp_man_cove
func _on_horse_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/kelp_man.tscn")
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
