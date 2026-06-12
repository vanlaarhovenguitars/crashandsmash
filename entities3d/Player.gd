extends CharacterBody3D
## The playable hero. Which one (bat / beast_toy / creature) comes from GameState —
## chosen on the character-select screen, per Zane's design. Movement from keyboard /
## gamepad / touch joystick; auto-aims and auto-fires at the nearest enemy. The body
## and animations live in HeroRig; stats (speed, hp, damage, fire rate) per hero.

const HeroRig := preload("res://entities3d/HeroRig.gd")

const GRAVITY := 24.0

var kind := "beast_toy"
var stats: Dictionary
var hp: int
var max_hp: int
var arena
var hud

var _rig: Node3D
var _fire_cd := 0.0

func _ready() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null and "selected_hero" in gs:
		kind = gs.selected_hero
	stats = HeroRig.STATS.get(kind, HeroRig.STATS["beast_toy"])
	max_hp = int(stats.hp)
	hp = max_hp

	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.45
	caps.height = 1.8
	col.shape = caps
	col.position = Vector3(0, 0.9, 0)
	add_child(col)

	_rig = HeroRig.new()
	add_child(_rig)
	_rig.build(kind)

func _physics_process(delta: float) -> void:
	if arena == null or arena.game_over:
		return

	var move := _move_input()
	var world_dir := Vector3(move.x, 0.0, -move.y)
	if world_dir.length() > 1.0:
		world_dir = world_dir.normalized()
	var speed: float = stats.speed
	velocity.x = world_dir.x * speed
	velocity.z = world_dir.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	_fire_cd -= delta
	var target = arena.nearest_enemy(global_position, float(stats.fire_range))
	if target != null:
		_face_toward(target.global_position)
		if _fire_cd <= 0.0:
			_fire_cd = float(stats.fire_interval)
			var dir: Vector3 = target.global_position - global_position
			dir.y = 0.0
			_rig.flash()
			arena.spawn_bullet(_rig.muzzle.global_position, dir, int(stats.damage), stats.bullet_color)
	elif world_dir.length() > 0.1:
		_face_toward(global_position + world_dir)

	_rig.set_motion(delta, world_dir.length() > 0.1, clampf(world_dir.length(), 0.0, 1.0), target != null)

func _face_toward(point: Vector3) -> void:
	var p := Vector3(point.x, global_position.y, point.z)
	if p.distance_to(global_position) > 0.01:
		look_at(p, Vector3.UP)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hud != null:
		hud.set_health(hp, max_hp)
	if hp <= 0:
		arena.on_player_dead()

func _move_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		v.y += 1.0
	if Input.is_key_pressed(KEY_S):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		v.x += 1.0
	var sx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var sy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(sx) > 0.2:
		v.x += sx
	if absf(sy) > 0.2:
		v.y += -sy
	if hud != null:
		v += hud.move_vector()
	return Vector2(clampf(v.x, -1.0, 1.0), clampf(v.y, -1.0, 1.0))
