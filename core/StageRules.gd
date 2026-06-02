extends RefCounted
## Pure game-rules: how many enemies each stage requires, and win/lose evaluation.
## No scene-tree dependencies, so this is unit-testable headlessly (see tests/run_tests.gd).
##
## Numbers come straight from the design recording with Zane:
##   Stage 1 -> defeat 3, Stage 2 -> defeat 4, Stage 3 -> endless.

const KILLS_TO_ADVANCE := {1: 3, 2: 4, 3: -1}  # -1 means endless

static func kills_to_advance(stage: int) -> int:
	return KILLS_TO_ADVANCE.get(stage, -1)

static func is_endless(stage: int) -> bool:
	return kills_to_advance(stage) < 0

static func is_stage_won(stage: int, kills: int) -> bool:
	var needed := kills_to_advance(stage)
	if needed < 0:
		return false  # endless stages are never "won" by kill count
	return kills >= needed
