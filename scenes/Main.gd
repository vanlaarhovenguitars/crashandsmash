extends Node2D
## Entry point. For now it jumps straight into Stage 1. Later this is where a
## main menu / character-select screen would live before loading a stage.

func _ready() -> void:
	var stage := preload("res://scenes/Stage1.tscn").instantiate()
	add_child(stage)
