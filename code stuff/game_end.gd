extends Node

@onready var kelp_score_field = $KelpManScore  # Rename node in editor too if needed

func _ready():
	update_score_field("Kelp man", kelp_score_field)

func update_score_field(ai_name: String, field: Label):
	if ai_name in GameState.ai_scores:
		field.text += str(GameState.ai_scores[ai_name])
	else:
		field.text += "DNT"
