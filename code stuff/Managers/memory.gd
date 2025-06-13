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
