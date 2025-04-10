extends Node

@onready var guy = $"Normal guy"
@onready var horse = $Horse

# Shared social memory
var social_memory: Array = []

func _ready():
	guy.social_memory = social_memory
	horse.social_memory = social_memory
