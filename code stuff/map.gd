extends Node2D

@onready var horse_button = $horse

func _on_horse_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/normal_horse.tscn")
	MapMemory.set_location("horse")

func _ready():
	print("🗓️ Days: %d, Actions: %d" % [GameState.days_left, GameState.actions_left])
	for child in get_children():
		# Assume buttons are named after the areas (e.g. "bar", "forest")
		var area_name := child.name.to_lower()
		
		if area_name in MapMemory.unlocked_areas:
			child.visible = true
		else:
			child.visible = false
	horse_button.visible = true


func _on_bar_pressed() -> void:
	get_tree().change_scene_to_file("res://bar.tscn")
