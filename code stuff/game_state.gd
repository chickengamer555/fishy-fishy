extends Node

signal day_or_action_changed
signal final_turn_started
var just_started_new_day := false
var days_left := 2
var actions_left := 2
var final_turn_triggered := false
var ai_scores := {}
var should_reset_ai := true
var last_ai_response := ""

func use_action():
	if final_turn_triggered:
		return

	print("🎮 Action used. Day: %d | Action: %d" % [days_left, actions_left])

	actions_left -= 1

	# ✅ Final turn (Day 1, Action 1) AFTER subtracting
	if days_left == 1 and actions_left == 0:
		print("🚨 Final turn triggered.")
		final_turn_triggered = true
		emit_signal("final_turn_started")
		return

	# ✅ Go to next day (if not final) - CHANGED TO ELIF
	elif actions_left <= 0:
		days_left -= 1
		actions_left = 2
		if days_left > 0:
			just_started_new_day = true
			should_reset_ai = true
			last_ai_response = ""
			get_tree().change_scene_to_file("res://Scene stuff/map.tscn")
		else:
			print("🛑 Unexpected day < 1 condition hit.")
	else:
		emit_signal("day_or_action_changed")

func end_game():
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
	get_tree().change_scene_to_file("res://game_end.tscn")
