extends SceneTree
## Integration test: drives the REAL Stage1 scene to prove the gameplay loop works
## end-to-end (not just that it boots). Run with:
##   godot --headless --script res://tests/integration_test.gd
##
## It verifies:
##   1. Placing a defender spends coins and occupies the grid cell.
##   2. Defenders actually shoot and KILL robots (combat resolves).
##   3. Defeating 3 robots triggers a WIN that advances to Stage 2.
##   4. A robot reaching the base triggers a LOSE (no kills) that resets to Stage 1.
## Exits non-zero if any check fails. Uses a time-scale + in-game-second timeout
## so it finishes quickly and never hangs.

const StageScene := preload("res://scenes/Stage1.tscn")
const Units := preload("res://data/Units.gd")
const RobotScript := preload("res://units/Robot.gd")
const GameStateScript := preload("res://autoload/GameState.gd")

const TIMEOUT_GAME_SECONDS := 60.0  # in-game seconds before we give up

var _results: Array = []
var _phase := 0
var _elapsed := 0.0
var gs
var win_stage
var lose_stage

func _ok(label: String, cond: bool) -> void:
	_results.append([label, cond])

func _spawn_robot(stage, row: int, x: float):
	var robot = RobotScript.new()
	stage.add_child(robot)
	robot.setup(Units.ROBOT, row, stage)
	robot.position = Vector2(x, stage.cell_center(row, 0).y)
	stage.robots.append(robot)
	return robot

func _clear_robots(stage) -> void:
	for r in stage.robots:
		r.queue_free()
	stage.robots.clear()

func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed > TIMEOUT_GAME_SECONDS:
		_ok("completed before timeout", false)
		return _finish()

	match _phase:
		0:  # Set up the WIN scenario
			Engine.time_scale = 20.0
			# Use the real GameState autoload so we inspect the same instance the
			# stage uses; create one only if it isn't present. Start at Stage 1.
			gs = get_root().get_node_or_null("GameState")
			if gs == null:
				gs = GameStateScript.new()
				gs.name = "GameState"
				get_root().add_child(gs)
			gs.current_stage = 1
			win_stage = StageScene.instantiate()
			get_root().add_child(win_stage)
			win_stage._spawn_timer.stop()
			_clear_robots(win_stage)
			win_stage.economy.coins = 1000
			var before: int = win_stage.economy.coins
			# Place a wall of shooters in row 2.
			win_stage.selected_index = 1  # Beast Toy
			win_stage.cursor_row = 2
			win_stage.cursor_col = 1
			win_stage._try_place()
			_ok("placing spends coins", win_stage.economy.coins == before - 50)
			_ok("placing occupies the grid cell", win_stage.grid[2][1] != null)
			win_stage.selected_index = 3  # Bat
			win_stage.cursor_col = 2
			win_stage._try_place()
			win_stage.selected_index = 1  # Beast Toy
			win_stage.cursor_col = 3
			win_stage._try_place()
			_phase = 1
		1:  # Feed robots one at a time until the stage is won
			if win_stage.game_over:
				_ok("combat kills robots (>=1 defeated)", win_stage.kills >= 1)
				_ok("defeating 3 robots wins the stage", win_stage.kills >= 3)
				_ok("win is flagged as a win, not a loss", win_stage._win_pending)
				win_stage._apply_progression()
				_ok("winning advances to Stage 2", gs.current_stage == 2)
				_phase = 2
			elif win_stage.robots.is_empty():
				_spawn_robot(win_stage, 2, win_stage.field_right() - 100.0)
		2:  # Set up the LOSE scenario in a fresh stage
			lose_stage = StageScene.instantiate()
			get_root().add_child(lose_stage)
			_phase = 3
		3:  # Configure the lose stage one frame later (after its _ready ran)
			lose_stage._spawn_timer.stop()
			_clear_robots(lose_stage)
			_spawn_robot(lose_stage, 0, lose_stage.base_x() + 130.0)
			_phase = 4
		4:  # An undefended robot should reach the base and lose the game
			if lose_stage.game_over:
				_ok("robot reaching base ends the game", lose_stage.game_over)
				_ok("losing happens with no kills", lose_stage.kills == 0)
				lose_stage._apply_progression()
				_ok("losing resets to Stage 1", gs.current_stage == 1)
				return _finish()
	return false

func _finish() -> bool:
	var failures := 0
	print("")
	for r in _results:
		if r[1]:
			print("PASS: ", r[0])
		else:
			print("FAIL: ", r[0])
			failures += 1
	print("")
	if failures == 0:
		print("ALL INTEGRATION CHECKS PASSED (%d)" % _results.size())
	else:
		print("INTEGRATION FAILURES: %d of %d" % [failures, _results.size()])
	quit(failures)
	return true
