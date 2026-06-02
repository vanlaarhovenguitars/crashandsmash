extends Node2D
## Stage 1: the lane-defense level. Owns the grid, the economy, the enemy spawner,
## and all the bookkeeping that keeps the unit scripts simple. Defeat 3 robots to win;
## let one reach the base and you lose.
##
## Input works on TV and touch:
##   - Gamepad / arrows: move the grid cursor; A / Enter / Space places the selected unit.
##   - Shoulder buttons (or keys 1-4, or tapping the HUD buttons): pick which unit to place.
##   - Mouse / touch: tap a cell to place there directly.

const Units := preload("res://data/Units.gd")
const EconomyClass := preload("res://core/Economy.gd")
const StageRules := preload("res://core/StageRules.gd")
const DefenderScene := preload("res://units/Defender.gd")
const RobotScene := preload("res://units/Robot.gd")
const ProjectileScene := preload("res://units/Projectile.gd")
const HUDClass := preload("res://ui/HUD.gd")

const ROWS := 5
const COLS := 9
const FIELD_LEFT := 220.0
const FIELD_TOP := 165.0
const FIELD_RIGHT := 1860.0
const FIELD_BOTTOM := 1045.0
const BASE_SPAWN_INTERVAL := 6.0

var cell_w: float
var cell_h: float
var stage_number := 1
var spawn_interval := BASE_SPAWN_INTERVAL
var max_spawns := 6
var robot_def: Dictionary
var kills := 0
var spawned := 0
var economy
var grid: Array = []      # grid[row][col] -> Defender or null
var robots: Array = []    # active Robot instances
var selected_index := 0   # index into Units.DEFENDERS
var cursor_row := 2
var cursor_col := 4
var game_over := false
var _win_pending := false

var _hud
var _cursor: ColorRect
var _spawn_timer: Timer

func _ready() -> void:
	randomize()
	cell_w = (FIELD_RIGHT - FIELD_LEFT) / float(COLS)
	cell_h = (FIELD_BOTTOM - FIELD_TOP) / float(ROWS)
	for r in ROWS:
		var row_cells: Array = []
		for c in COLS:
			row_cells.append(null)
		grid.append(row_cells)
	economy = EconomyClass.new(75)
	_configure_for_stage()

	_build_field()
	_build_cursor()

	_hud = HUDClass.new()
	add_child(_hud)
	_hud.defender_selected.connect(_on_defender_selected)

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn)
	add_child(_spawn_timer)
	_spawn_timer.start()

	_refresh_hud()
	_update_cursor()
	_on_spawn()  # send one robot right away so there's immediate action

## Reads the current stage from GameState (default 1) and scales difficulty:
## faster spawns, tougher/faster robots, and the kill target from StageRules.
func _configure_for_stage() -> void:
	var gs := _game_state()
	stage_number = gs.current_stage if gs != null else 1
	var needed := StageRules.kills_to_advance(stage_number)
	spawn_interval = maxf(2.5, BASE_SPAWN_INTERVAL - float(stage_number - 1) * 1.5)
	max_spawns = 9999 if needed < 0 else needed + 3  # endless stages never run out
	robot_def = Units.ROBOT.duplicate()
	robot_def.hp = int(Units.ROBOT.hp) + (stage_number - 1) * 20
	robot_def.speed = float(Units.ROBOT.speed) + float(stage_number - 1) * 10.0

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

# --- World layout -----------------------------------------------------------

func _build_field() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.14, 0.18)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var base := ColorRect.new()
	base.color = Color(0.28, 0.16, 0.16)
	base.position = Vector2(0, FIELD_TOP)
	base.size = Vector2(FIELD_LEFT, FIELD_BOTTOM - FIELD_TOP)
	add_child(base)

	var base_label := Label.new()
	base_label.text = "BASE"
	base_label.position = Vector2(50, (FIELD_TOP + FIELD_BOTTOM) / 2.0 - 20.0)
	base_label.add_theme_font_size_override("font_size", 36)
	add_child(base_label)

	for r in ROWS:
		var lane := ColorRect.new()
		lane.color = Color(0.18, 0.30, 0.20) if r % 2 == 0 else Color(0.15, 0.25, 0.17)
		lane.position = Vector2(FIELD_LEFT, FIELD_TOP + r * cell_h)
		lane.size = Vector2(FIELD_RIGHT - FIELD_LEFT, cell_h)
		add_child(lane)

func _build_cursor() -> void:
	_cursor = ColorRect.new()
	_cursor.size = Vector2(cell_w, cell_h)
	add_child(_cursor)

func _update_cursor() -> void:
	_cursor.position = Vector2(FIELD_LEFT + cursor_col * cell_w, FIELD_TOP + cursor_row * cell_h)
	var d: Dictionary = Units.DEFENDERS[selected_index]
	_cursor.color = Color(d.color.r, d.color.g, d.color.b, 0.30)

# --- Grid helpers (used by unit scripts) ------------------------------------

func cell_center(row: int, col: int) -> Vector2:
	return Vector2(FIELD_LEFT + (col + 0.5) * cell_w, FIELD_TOP + (row + 0.5) * cell_h)

func col_at_x(x: float) -> int:
	if x < FIELD_LEFT or x > FIELD_RIGHT:
		return -1
	return int((x - FIELD_LEFT) / cell_w)

func row_at_y(y: float) -> int:
	if y < FIELD_TOP or y > FIELD_BOTTOM:
		return -1
	return int((y - FIELD_TOP) / cell_h)

func base_x() -> float:
	return FIELD_LEFT

func field_right() -> float:
	return FIELD_RIGHT

func has_robot_ahead(row: int, x: float) -> bool:
	return first_robot_in_row_ahead(row, x) != null

func first_robot_in_row_ahead(row: int, x: float):
	var best = null
	for r in robots:
		if r.row == row and r.position.x >= x:
			if best == null or r.position.x < best.position.x:
				best = r
	return best

func defender_blocking(robot):
	var c := col_at_x(robot.position.x)
	if c < 0 or c >= COLS:
		return null
	return grid[robot.row][c]

# --- Callbacks from units ---------------------------------------------------

func add_coins(n: int) -> void:
	economy.add(n)
	_refresh_hud()

func spawn_projectile(row: int, from_pos: Vector2, dmg: int, color: Color) -> void:
	var p = ProjectileScene.new()
	add_child(p)
	p.global_position = from_pos
	p.setup(row, dmg, self, color)

func remove_defender(d) -> void:
	if grid[d.row][d.col] == d:
		grid[d.row][d.col] = null
	d.queue_free()

func on_robot_killed(robot) -> void:
	robots.erase(robot)
	robot.queue_free()
	kills += 1
	_refresh_hud()
	if StageRules.is_stage_won(stage_number, kills):
		_win()

func on_robot_reached_base(_robot) -> void:
	_lose()

# --- Spawning ---------------------------------------------------------------

func _on_spawn() -> void:
	if game_over or spawned >= max_spawns:
		return
	spawned += 1
	var row := randi() % ROWS
	var robot = RobotScene.new()
	add_child(robot)
	robot.setup(robot_def, row, self)
	robot.position = Vector2(FIELD_RIGHT + 60.0, cell_center(row, 0).y)
	robots.append(robot)

# --- HUD / selection --------------------------------------------------------

func _on_defender_selected(index: int) -> void:
	selected_index = index
	_hud.highlight(index)
	_update_cursor()

func _refresh_hud() -> void:
	_hud.set_coins(economy.coins)
	_hud.set_kills(stage_number, kills, StageRules.kills_to_advance(stage_number))

# --- Placement & input ------------------------------------------------------

func _try_place() -> void:
	if game_over:
		return
	var d: Dictionary = Units.DEFENDERS[selected_index]
	if grid[cursor_row][cursor_col] != null:
		return
	if not economy.can_afford(d.cost):
		return
	economy.spend(d.cost)
	var def = DefenderScene.new()
	add_child(def)
	def.setup(d, cursor_row, cursor_col, self)
	def.position = cell_center(cursor_row, cursor_col)
	grid[cursor_row][cursor_col] = def
	_refresh_hud()

func _move_cursor(dcol: int, drow: int) -> void:
	cursor_col = clampi(cursor_col + dcol, 0, COLS - 1)
	cursor_row = clampi(cursor_row + drow, 0, ROWS - 1)
	_update_cursor()

func _select(index: int) -> void:
	if index >= 0 and index < Units.DEFENDERS.size():
		_on_defender_selected(index)

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("ui_accept"):
			_apply_progression()
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("ui_left"):
		_move_cursor(-1, 0)
	elif event.is_action_pressed("ui_right"):
		_move_cursor(1, 0)
	elif event.is_action_pressed("ui_up"):
		_move_cursor(0, -1)
	elif event.is_action_pressed("ui_down"):
		_move_cursor(0, 1)
	elif event.is_action_pressed("ui_accept"):
		_try_place()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_select(event.keycode - KEY_1)
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_select((selected_index + 1) % Units.DEFENDERS.size())
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_select((selected_index - 1 + Units.DEFENDERS.size()) % Units.DEFENDERS.size())
	elif (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		var c := col_at_x(event.position.x)
		var r := row_at_y(event.position.y)
		if c >= 0 and r >= 0:
			cursor_col = c
			cursor_row = r
			_update_cursor()
			_try_place()

# --- End states -------------------------------------------------------------

func _win() -> void:
	game_over = true
	_win_pending = true
	_spawn_timer.stop()
	_hud.show_banner("STAGE %d CLEARED!\nPress Enter / A" % stage_number)

func _lose() -> void:
	game_over = true
	_win_pending = false
	_spawn_timer.stop()
	_hud.show_banner("GAME OVER\nStage %d  -  Press Enter / A" % stage_number)

## On the win/lose confirm: advance to the next stage, or reset to Stage 1.
func _apply_progression() -> void:
	var gs := _game_state()
	if gs == null:
		return
	if _win_pending:
		gs.current_stage = stage_number + 1
	else:
		gs.reset()
