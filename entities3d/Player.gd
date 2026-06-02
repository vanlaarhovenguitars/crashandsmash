extends CharacterBody3D
## The hero you walk around as. Moves on the ground from keyboard / gamepad stick / touch
## joystick, and AUTO-AIMS + auto-fires at the nearest robot in range (kid-friendly: just
## steer, the shooting is automatic). Placeholder capsule body with a "nose" so you can see
## which way it faces.

const MOVE_SPEED := 7.0
const GRAVITY := 24.0
const MAX_HP := 100
const FIRE_INTERVAL := 0.4
const FIRE_RANGE := 18.0
const BULLET_DAMAGE := 12

var hp: int
var arena
var hud
var _fire_cd := 0.0

func _ready() -> void:
	hp = MAX_HP

	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.5
	caps.height = 2.0
	col.shape = caps
	col.position = Vector3(0, 1.0, 0)
	add_child(col)

	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.5
	cm.height = 2.0
	body.mesh = cm
	body.position = Vector3(0, 1.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0)
	body.material_override = mat
	add_child(body)

	# A small marker on the -Z side so the facing direction is visible.
	var nose := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.35, 0.35)
	nose.mesh = bm
	nose.position = Vector3(0, 1.2, -0.7)
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(1.0, 0.9, 0.2)
	nose.material_override = nmat
	add_child(nose)

func _physics_process(delta: float) -> void:
	if arena == null or arena.game_over:
		return

	var move := _move_input()
	var world_dir := Vector3(move.x, 0.0, -move.y)
	if world_dir.length() > 1.0:
		world_dir = world_dir.normalized()
	velocity.x = world_dir.x * MOVE_SPEED
	velocity.z = world_dir.z * MOVE_SPEED
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	# Auto-aim & auto-fire at the nearest robot.
	_fire_cd -= delta
	var target = arena.nearest_enemy(global_position, FIRE_RANGE)
	if target != null:
		_face_toward(target.global_position)
		if _fire_cd <= 0.0:
			_fire_cd = FIRE_INTERVAL
			var dir: Vector3 = target.global_position - global_position
			dir.y = 0.0
			arena.spawn_bullet(global_position + Vector3(0, 1.0, 0), dir, BULLET_DAMAGE)
	elif world_dir.length() > 0.1:
		_face_toward(global_position + world_dir)

func _face_toward(point: Vector3) -> void:
	var p := Vector3(point.x, global_position.y, point.z)
	if p.distance_to(global_position) > 0.01:
		look_at(p, Vector3.UP)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hud != null:
		hud.set_health(hp, MAX_HP)
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
