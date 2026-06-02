extends Node3D
## The 3D walk-around battle arena. Builds the world (floor, walls, light, sky), spawns the
## player and robots, follows the player with a fixed-angle camera, and handles win/lose.
## Reuses the same pure rules as the 2D game: defeat 3 robots to clear Stage 1 (StageRules),
## stage difficulty scales, and progress lives in the GameState autoload.

const StageRules := preload("res://core/StageRules.gd")
const PlayerScript := preload("res://entities3d/Player.gd")
const RobotScript := preload("res://entities3d/RobotEnemy.gd")
const BulletScript := preload("res://entities3d/Bullet.gd")
const HUDScript := preload("res://ui3d/HUD3D.gd")

const ARENA_HALF := 19.0
const BASE_SPAWN_INTERVAL := 2.5
const CAM_OFFSET := Vector3(0, 15, 13)

var stage_number := 1
var kills := 0
var spawned := 0
var max_spawns := 6
var spawn_interval := BASE_SPAWN_INTERVAL
var enemy_hp := 30
var enemy_damage := 8
var game_over := false

var player
var hud
var camera: Camera3D
var enemies: Array = []
var _spawn_timer: Timer
var _win_pending := false

func _ready() -> void:
	randomize()
	_configure_for_stage()
	_build_world()
	_build_player()
	_build_camera()

	hud = HUDScript.new()
	add_child(hud)
	hud.arena = self
	player.hud = hud
	hud.set_health(player.hp, 100)
	_refresh_hud()

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn)
	add_child(_spawn_timer)
	_spawn_timer.start()
	_on_spawn()

func _configure_for_stage() -> void:
	var gs := get_node_or_null("/root/GameState")
	stage_number = gs.current_stage if gs != null else 1
	var needed := StageRules.kills_to_advance(stage_number)
	max_spawns = 9999 if needed < 0 else needed + 3
	spawn_interval = maxf(1.2, BASE_SPAWN_INTERVAL - float(stage_number - 1) * 0.5)
	enemy_hp = 30 + (stage_number - 1) * 12
	enemy_damage = 8 + (stage_number - 1) * 3

# --- World ------------------------------------------------------------------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.40, 0.62, 0.88)
	e.ambient_light_color = Color(0.6, 0.6, 0.66)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-40), 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(ARENA_HALF * 2.0, 1.0, ARENA_HALF * 2.0)
	floor_mesh.mesh = fbm
	floor_mesh.position = Vector3(0, -0.5, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.26, 0.5, 0.32)
	floor_mesh.material_override = fmat
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new()
	var fbs := BoxShape3D.new()
	fbs.size = Vector3(ARENA_HALF * 2.0, 1.0, ARENA_HALF * 2.0)
	floor_col.shape = fbs
	floor_col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_col)

	_build_wall(Vector3(0, 1, -ARENA_HALF), Vector3(ARENA_HALF * 2.0, 3, 1))
	_build_wall(Vector3(0, 1, ARENA_HALF), Vector3(ARENA_HALF * 2.0, 3, 1))
	_build_wall(Vector3(-ARENA_HALF, 1, 0), Vector3(1, 3, ARENA_HALF * 2.0))
	_build_wall(Vector3(ARENA_HALF, 1, 0), Vector3(1, 3, ARENA_HALF * 2.0))

func _build_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.32, 0.40)
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	body.add_child(col)

func _build_player() -> void:
	player = PlayerScript.new()
	add_child(player)
	player.arena = self
	player.global_position = Vector3(0, 0.2, 0)

func _build_camera() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = player.global_position + CAM_OFFSET
	camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)
	camera.current = true

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var target: Vector3 = player.global_position + CAM_OFFSET
	camera.global_position = camera.global_position.lerp(target, clampf(delta * 6.0, 0.0, 1.0))
	camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)

# --- Spawning & combat ------------------------------------------------------

func _on_spawn() -> void:
	if game_over or spawned >= max_spawns:
		return
	spawned += 1
	var ang := randf() * TAU
	var r := ARENA_HALF - 2.5
	var robot = RobotScript.new()
	add_child(robot)
	robot.global_position = Vector3(cos(ang) * r, 0.1, sin(ang) * r)
	robot.setup(enemy_hp, enemy_damage, self, player)
	enemies.append(robot)

func nearest_enemy(from: Vector3, max_range: float):
	var best = null
	var best_d := max_range
	for e in enemies:
		var d := from.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func bullet_hit_check(pos: Vector3, radius: float):
	for e in enemies:
		if pos.distance_to(e.global_position + Vector3(0, 0.8, 0)) <= radius:
			return e
	return null

func spawn_bullet(from: Vector3, dir: Vector3, dmg: int) -> void:
	var b = BulletScript.new()
	add_child(b)
	b.global_position = from
	b.setup(dir, dmg, self)

func on_enemy_killed(e) -> void:
	enemies.erase(e)
	e.queue_free()
	kills += 1
	_refresh_hud()
	if StageRules.is_stage_won(stage_number, kills):
		_win()

func on_player_dead() -> void:
	_lose()

# --- HUD & end states -------------------------------------------------------

func _refresh_hud() -> void:
	hud.set_kills(stage_number, kills, StageRules.kills_to_advance(stage_number))

func _win() -> void:
	game_over = true
	_win_pending = true
	_spawn_timer.stop()
	hud.show_banner("STAGE %d CLEARED!\nTap / Enter / A" % stage_number)

func _lose() -> void:
	game_over = true
	_win_pending = false
	_spawn_timer.stop()
	hud.show_banner("GAME OVER\nStage %d  -  Tap / Enter / A" % stage_number)

## Called on win/lose confirm (tap, Enter, or gamepad A): advance or reset, then reload.
func confirm_restart() -> void:
	if not game_over:
		return
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		if _win_pending:
			gs.current_stage = stage_number + 1
		else:
			gs.reset()
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		confirm_restart()
