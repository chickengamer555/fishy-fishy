extends Node

signal day_or_action_changed
signal final_turn_started
signal day_completed
var just_started_new_day := false
var days_left := 2
var actions_left := 999
var final_turn_triggered := false
var day_complete_available := false
var ai_scores := {}
var should_reset_ai := false
var last_ai_response := ""
var last_ai_emotion := "sad"

func use_action():
	if final_turn_triggered:
		return

	print("🎮 Action used. Day: %d | Action: %d" % [days_left, actions_left])

	actions_left -= 1

	# ✅ Day complete - don't transition immediately, just flag it
	if actions_left <= 0:
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
		tree.change_scene_to_file("res://Scene stuff/Main/day_transition.tscn")

func end_game():
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://Scene stuff/Main/game_end.tscn")

func _input(event):
	# Handle F11 for window maximize toggle
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11:
			toggle_window_size()

func toggle_window_size():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Switched to normal window size")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		print("Switched to maximized window")
