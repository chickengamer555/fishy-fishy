extends Node

signal day_or_action_changed
signal final_turn_started
signal day_completed
var just_started_new_day := false
var days_left := 3
var actions_left := 2
var final_turn_triggered := false
var day_complete_available := false
var ai_scores := {}
var should_reset_ai := true
var last_ai_response := ""

func use_action():
	if final_turn_triggered:
		return

	print("🎮 Action used. Day: %d | Action: %d" % [days_left, actions_left])

	actions_left -= 1

	# ✅ Final turn (Day 1, Action 1) AFTER subtracting
	if days_left == 1 and actions_left == 1:
		print("🚨 Final turn triggered.")
		final_turn_triggered = true
		emit_signal("final_turn_started")
		return

	# ✅ Day complete - don't transition immediately, just flag it
	elif actions_left <= 0:
		print("🌅 Day complete, waiting for user to continue")
		day_complete_available = true
		emit_signal("day_completed")
	else:
		emit_signal("day_or_action_changed")

func transition_to_next_day():
	print("🌅 Transitioning to day transition scene")
	day_complete_available = false
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Scene stuff/day_transition.tscn")

func end_game():
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Scene stuff/game_end.tscn")
