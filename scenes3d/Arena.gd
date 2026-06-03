extends Node3D
## The 3D walk-around battle arena. Builds the world (floor, walls, sky, scenery), spawns the
## player and enemies (Mr. Beast toys & creatures), follows the player with a fixed-angle
## camera, and handles win/lose. Reuses the same pure rules as the 2D game: defeat 3 to clear
## Stage 1 (StageRules), difficulty scales per stage, and progress lives in GameState.

const StageRules := preload("res://core/StageRules.gd")
const PlayerScript := preload("res://entities3d/Player.gd")
const EnemyScript := preload("res://entities3d/Enemy.gd")
const BulletScript := preload("res://entities3d/Bullet.gd")
const HUDScript := preload("res://ui3d/HUD3D.gd")

const ARENA_HALF := 28.0
const BASE_SPAWN_INTERVAL := 2.5
const CAM_OFFSET := Vector3(0, 20, 17)

var stage_number := 1
var kills := 0
var spawned := 0
var max_spawns := 6
var spawn_interval := BASE_SPAWN_INTERVAL
var _hp_mult := 1.0
var _dmg_add := 0
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
	_hp_mult = 1.0 + float(stage_number - 1) * 0.4
	_dmg_add = (stage_number - 1) * 3

# --- World ------------------------------------------------------------------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.32, 0.52, 0.9)
	psm.sky_horizon_color = Color(0.75, 0.83, 0.93)
	psm.ground_horizon_color = Color(0.75, 0.83, 0.93)
	psm.ground_bottom_color = Color(0.45, 0.52, 0.5)
	sky.sky_material = psm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.45
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-52), deg_to_rad(-50), 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	add_child(sun)

	# Two-tone checkerboard floor for a nicer look.
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_col := CollisionShape3D.new()
	var fbs := BoxShape3D.new()
	fbs.size = Vector3(ARENA_HALF * 2.0, 1.0, ARENA_HALF * 2.0)
	floor_col.shape = fbs
	floor_col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_col)
	var light_tile := _mat(Color(0.32, 0.56, 0.36))
	var dark_tile := _mat(Color(0.26, 0.48, 0.31))
	var tiles := 8
	var tile := (ARENA_HALF * 2.0) / float(tiles)
	for ix in tiles:
		for iz in tiles:
			var t := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(tile, 1.0, tile)
			t.mesh = bm
			t.position = Vector3(-ARENA_HALF + (ix + 0.5) * tile, -0.5, -ARENA_HALF + (iz + 0.5) * tile)
			t.material_override = light_tile if (ix + iz) % 2 == 0 else dark_tile
			floor_body.add_child(t)

	_build_wall(Vector3(0, 1, -ARENA_HALF), Vector3(ARENA_HALF * 2.0, 3, 1))
	_build_wall(Vector3(0, 1, ARENA_HALF), Vector3(ARENA_HALF * 2.0, 3, 1))
	_build_wall(Vector3(-ARENA_HALF, 1, 0), Vector3(1, 3, ARENA_HALF * 2.0))
	_build_wall(Vector3(ARENA_HALF, 1, 0), Vector3(1, 3, ARENA_HALF * 2.0))
	_build_decorations()
	_build_terrain()

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m

## Scatters some colourful blocks and corner posts so the arena isn't empty (visual only).
func _build_decorations() -> void:
	var palette := [
		Color(0.95, 0.35, 0.35), Color(0.95, 0.8, 0.25),
		Color(0.4, 0.7, 0.95), Color(0.6, 0.45, 0.85), Color(0.95, 0.6, 0.3),
	]
	for i in 12:
		var ang := randf() * TAU
		var dist := randf_range(6.0, ARENA_HALF - 3.0)
		var s := randf_range(0.8, 1.8)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(s, s, s)
		mi.mesh = bm
		mi.position = Vector3(cos(ang) * dist, s * 0.5, sin(ang) * dist)
		mi.rotation.y = randf() * TAU
		mi.material_override = _mat(palette[randi() % palette.size()])
		add_child(mi)
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(1.2, 4.0, 1.2)
			post.mesh = pm
			post.position = Vector3(cx * (ARENA_HALF - 0.6), 2.0, cz * (ARENA_HALF - 0.6))
			post.material_override = _mat(Color(0.85, 0.85, 0.9))
			add_child(post)

## Adds terrain: gentle mounds, bushes, rocks, and trees scattered around the field.
## Trees and big rocks get collision so the player weaves around them; small props are visual.
func _build_terrain() -> void:
	# Gentle grassy mounds (flattened domes, visual only).
	for i in 4:
		var p := _scatter(8.0)
		var r := randf_range(3.0, 5.0)
		var dome := _new_sphere(r, _mat(Color(0.3, 0.54, 0.36).lightened(randf() * 0.08)))
		dome.position = Vector3(p.x, -0.1, p.z)
		dome.scale = Vector3(1.0, randf_range(0.12, 0.2), 1.0)
		add_child(dome)
	# Bushes (clusters of green spheres, visual only).
	for i in 8:
		var bp := _scatter(6.0)
		var bush := Node3D.new()
		bush.position = Vector3(bp.x, 0.0, bp.z)
		add_child(bush)
		var bcol := Color(0.2, 0.45, 0.22).lightened(randf() * 0.15)
		for j in 3:
			var blob := _new_sphere(randf_range(0.5, 0.8), _mat(bcol))
			blob.position = Vector3(randf_range(-0.4, 0.4), randf_range(0.4, 0.7), randf_range(-0.4, 0.4))
			bush.add_child(blob)
	# Rocks (grey, some with collision).
	for i in 6:
		var rp := _scatter(6.0)
		var rs := randf_range(0.7, 1.8)
		var rock := _new_sphere(rs, _mat(Color(0.5, 0.5, 0.55).darkened(randf() * 0.2)))
		rock.scale = Vector3(1.0, randf_range(0.6, 0.9), 1.0)
		if rs > 1.2:
			var body := StaticBody3D.new()
			body.position = Vector3(rp.x, rs * 0.4, rp.z)
			var cs := CollisionShape3D.new()
			var sp := SphereShape3D.new()
			sp.radius = rs * 0.8
			cs.shape = sp
			body.add_child(cs)
			body.add_child(rock)
			add_child(body)
		else:
			rock.position = Vector3(rp.x, rs * 0.4, rp.z)
			add_child(rock)
	# Trees (trunk + foliage, with collision on the trunk).
	for i in 7:
		var tp := _scatter(7.0)
		_build_tree(Vector3(tp.x, 0.0, tp.z), randf_range(0.85, 1.3))

func _new_sphere(radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	return mi

## Returns a random point at least `min_center` from the middle (player spawn) and inside the walls.
func _scatter(min_center: float) -> Vector3:
	var ang := randf() * TAU
	var d := randf_range(min_center, ARENA_HALF - 3.0)
	return Vector3(cos(ang) * d, 0.0, sin(ang) * d)

func _build_tree(pos: Vector3, s: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.22 * s
	tm.bottom_radius = 0.28 * s
	tm.height = 1.8 * s
	trunk.mesh = tm
	trunk.position = Vector3(0, 0.9 * s, 0)
	trunk.material_override = _mat(Color(0.45, 0.3, 0.18))
	body.add_child(trunk)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3 * s
	cap.height = 1.8 * s
	cs.shape = cap
	cs.position = Vector3(0, 0.9 * s, 0)
	body.add_child(cs)
	var leaf := Color(0.22, 0.5, 0.24).lightened(randf() * 0.12)
	for j in 3:
		var blob := _new_sphere(randf_range(0.9, 1.2) * s, _mat(leaf))
		blob.position = Vector3(randf_range(-0.4, 0.4) * s, (2.0 + j * 0.5) * s, randf_range(-0.4, 0.4) * s)
		body.add_child(blob)

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
	var kind := "brute" if randf() < 0.3 else "swarmling"
	var enemy = EnemyScript.new()
	add_child(enemy)
	enemy.global_position = Vector3(cos(ang) * r, 0.1, sin(ang) * r)
	enemy.setup(kind, _hp_mult, _dmg_add, self, player)
	enemies.append(enemy)

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

## A short burst of coloured cubes flung outward when an enemy is defeated.
func spawn_burst(pos: Vector3, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	for i in 8:
		var bit := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 0.18, 0.18)
		bit.mesh = bm
		bit.material_override = mat
		add_child(bit)
		bit.global_position = pos
		var dir := Vector3(randf_range(-1, 1), randf_range(0.4, 1.6), randf_range(-1, 1)).normalized()
		var dest := pos + dir * randf_range(1.0, 2.4)
		dest.y = maxf(0.15, dest.y)
		var tw := bit.create_tween()
		tw.tween_property(bit, "global_position", dest, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bit, "scale", Vector3.ZERO, 0.45)
		tw.tween_callback(bit.queue_free)

func on_enemy_killed(e) -> void:
	if not enemies.has(e):
		return
	enemies.erase(e)
	kills += 1
	_refresh_hud()
	e.play_death()  # robot removes itself after the death animation
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
