extends Node

var days_left := 1         # You can increase this to 10, etc.
var actions_left := 1      # Number of actions per day
var should_end_game := false
var just_started_new_day := false

var ai_scores := {}        # Final relationship scores
var should_reset_ai := true
var last_ai_response := ""

func use_action():
	actions_left -= 1
	print("🎮 Action used. Actions left: %d" % actions_left)

	if actions_left <= 0:
		if days_left > 1:
			reset_day()
		else:
			# Final action on final day — trigger end flag
			should_end_game = true
			print("⚠️ Final action of final day used. Awaiting Next...")
	emit_signal("day_or_action_changed")

func reset_day():
	days_left -= 1
	actions_left = 1  # How many actions per new day
	just_started_new_day = true
	print("📅 New day! Days left: %d" % days_left)

	last_ai_response = ""
	should_reset_ai = true

	get_tree().change_scene_to_file("res://Scene stuff/map.tscn")
	emit_signal("day_or_action_changed")

func end_game():
	get_tree().change_scene_to_file("res://game_end.tscn")
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
