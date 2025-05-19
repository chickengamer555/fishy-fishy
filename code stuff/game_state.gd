extends Node

signal day_or_action_changed

var days_left := 2  # Starting days
var actions_left := 1  # Actions per day
var should_end_game := false
var just_started_new_day := false
var ai_scores := {}
var should_reset_ai := true
var last_ai_response := ""

func use_action():
	if should_end_game:
		return
		
	print("🎮 Action used. Day: %d | Action: %d" % [days_left, actions_left])
	
	# Check if this is the final action
	if days_left == 1 and actions_left == 1:
		print("🚨 Final turn reached: Day 1, Action 1.")
		should_end_game = true
		emit_signal("day_or_action_changed")
		return
	
	# Regular flow: consume action
	actions_left -= 1
	
	# Go to next day if needed
	if actions_left <= 0:
		days_left -= 1
		actions_left = 1
		
		# Only transition to new day if we're not at day 0
		if days_left > 0:
			just_started_new_day = true
			print("📅 New day started: Day %d" % days_left)
			last_ai_response = ""
			should_reset_ai = true
			get_tree().change_scene_to_file("res://Scene stuff/map.tscn")
		else:
			# We've hit day 0, action 1 - we should end the game instead
			print("🚨 Final day reached: Day 0, Action 1.")
			should_end_game = true
	
	emit_signal("day_or_action_changed")

func end_game():
	get_tree().change_scene_to_file("res://game_end.tscn")
	print("🏁 Game over! Final relationships:")
	for name in ai_scores.keys():
		print("%s: %d" % [name, ai_scores[name]])
