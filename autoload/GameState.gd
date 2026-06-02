extends Node
## Global, cross-stage progress. Registered as an autoload singleton ("GameState")
## in project.godot. Stage 1 runs fine without using this, but it gives Stages 2+
## somewhere to remember which stage we're on and the running total of defeats.

var current_stage: int = 1
var total_kills: int = 0

func reset() -> void:
	current_stage = 1
	total_kills = 0
