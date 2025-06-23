# Memory.gd (Singleton Autoload)
extends Node

# Global shared memory: an array of dictionaries {speaker, target, message}
var shared_memory: Array = []

# Add a new message entry to memory
func add_message(speaker: String, message: String, target: String = "") -> void:
	shared_memory.append({
		"speaker": speaker,
		"target": target,
		"message": message
	})

# Clear all chat logs across all characters (called at game end)
func clear_all_character_chat_logs() -> void:
	var chat_log_nodes = get_tree().get_nodes_in_group("chat_logs")
	for chat_log in chat_log_nodes:
		if chat_log.has_method("clear_all_chat_logs"):
			chat_log.clear_all_chat_logs()
