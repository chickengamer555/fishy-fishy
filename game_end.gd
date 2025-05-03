extends Node

@onready var horse_score_field = $HorseScore

func _ready():
	update_score_field("Horse", horse_score_field)

func update_score_field(ai_name: String, field: Label):
	if ai_name in GameState.ai_scores:
		field.text += str(GameState.ai_scores[ai_name])
	else:
		field.text += "DNT"
