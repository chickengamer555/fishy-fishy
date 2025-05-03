extends Node
var days_left := 2
var actions_left := 2

# Store final scores per AI
var ai_scores := {}
var should_reset_ai := true
var last_ai_response := ""

func reset_day():
	days_left -= 1
	actions_left = 3
	print("📅 New day! Days left: %d" % days_left)

func use_action():
	actions_left -= 1
	print("🎮 Action used. Actions left: %d" % actions_left)
	if actions_left <= 0 and days_left > 0:
		reset_day()
	elif actions_left < 0 and days_left <= 0:
		end_game()

func end_game():
	get_tree().change_scene_to_file("res://game_end.tscn")
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
