extends CharacterBody3D
## The hero. Walks on the ground from keyboard / gamepad / touch joystick and AUTO-AIMS +
## auto-fires at the nearest robot. Body is an articulated set of shapes (torso, head, arms,
## legs) animated in code: walk cycle, idle bob, and an aim pose for the gun arm.

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
var _walk_phase := 0.0
var _idle_t := 0.0

var _torso: MeshInstance3D
var _l_leg: Node3D
var _r_leg: Node3D
var _l_arm: Node3D
var _r_arm: Node3D
const TORSO_Y := 1.15

func _ready() -> void:
	hp = MAX_HP
	var col := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.45
	caps.height = 1.8
	col.shape = caps
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	_build_rig()

# --- Rig construction -------------------------------------------------------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

func _build_rig() -> void:
	var blue := Color(0.2, 0.55, 1.0)
	var dblue := Color(0.15, 0.35, 0.7)
	var skin := Color(1.0, 0.85, 0.6)

	_torso = _box(self, Vector3(0.7, 0.72, 0.42), Vector3(0, TORSO_Y, 0), blue)
	_box(self, Vector3(0.5, 0.5, 0.5), Vector3(0, 1.75, 0), skin)            # head
	_box(self, Vector3(0.1, 0.1, 0.06), Vector3(-0.12, 1.8, -0.26), Color(0.1, 0.1, 0.1))  # eyes
	_box(self, Vector3(0.1, 0.1, 0.06), Vector3(0.12, 1.8, -0.26), Color(0.1, 0.1, 0.1))

	_l_leg = _pivot(self, Vector3(-0.18, 0.85, 0))
	_box(_l_leg, Vector3(0.24, 0.8, 0.24), Vector3(0, -0.4, 0), dblue)
	_r_leg = _pivot(self, Vector3(0.18, 0.85, 0))
	_box(_r_leg, Vector3(0.24, 0.8, 0.24), Vector3(0, -0.4, 0), dblue)

	_l_arm = _pivot(self, Vector3(-0.48, 1.45, 0))
	_box(_l_arm, Vector3(0.2, 0.62, 0.2), Vector3(0, -0.32, 0), blue)
	_r_arm = _pivot(self, Vector3(0.48, 1.45, 0))
	_box(_r_arm, Vector3(0.2, 0.62, 0.2), Vector3(0, -0.32, 0), blue)
	_box(_r_arm, Vector3(0.16, 0.16, 0.5), Vector3(0, -0.5, -0.22), Color(0.2, 0.2, 0.28))  # gun

# --- Update -----------------------------------------------------------------

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

	_fire_cd -= delta
	var target = arena.nearest_enemy(global_position, FIRE_RANGE)
	if target != null:
		_face_toward(target.global_position)
		if _fire_cd <= 0.0:
			_fire_cd = FIRE_INTERVAL
			var dir: Vector3 = target.global_position - global_position
			dir.y = 0.0
			arena.spawn_bullet(global_position + Vector3(0, 1.45, -0.3), dir, BULLET_DAMAGE)
	elif world_dir.length() > 0.1:
		_face_toward(global_position + world_dir)

	_animate(delta, world_dir.length() > 0.1, clampf(world_dir.length(), 0.0, 1.0), target != null)

func _animate(delta: float, moving: bool, speed_frac: float, aiming: bool) -> void:
	if moving:
		_walk_phase += delta * 10.0 * maxf(speed_frac, 0.3)
		var sw := sin(_walk_phase) * 0.6 * speed_frac
		_l_leg.rotation.x = sw
		_r_leg.rotation.x = -sw
		_l_arm.rotation.x = lerp_angle(_l_arm.rotation.x, -sw * 0.7, 0.4)
		_torso.position.y = TORSO_Y + absf(sin(_walk_phase)) * 0.05
	else:
		_idle_t += delta
		_l_leg.rotation.x = lerpf(_l_leg.rotation.x, 0.0, 0.2)
		_r_leg.rotation.x = lerpf(_r_leg.rotation.x, 0.0, 0.2)
		_l_arm.rotation.x = lerpf(_l_arm.rotation.x, 0.0, 0.2)
		_torso.position.y = TORSO_Y + sin(_idle_t * 2.0) * 0.03
	# Gun arm: point forward when aiming, otherwise swing/rest.
	var r_target := 0.0
	if aiming:
		r_target = -1.4
	elif moving:
		r_target = -sin(_walk_phase) * 0.7
	_r_arm.rotation.x = lerp_angle(_r_arm.rotation.x, r_target, 0.4)

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
