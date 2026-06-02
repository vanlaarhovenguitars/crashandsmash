extends Node3D
## A robot enemy: walks toward the player and bites when close. Articulated body (torso,
## head with red visor, antenna, arms, legs) animated in code: walk cycle, attack lunge,
## and a death topple when defeated.

const CombatMath := preload("res://core/CombatMath.gd")

const SPEED := 3.0
const ATTACK_RANGE := 2.2
const ATTACK_INTERVAL := 1.0

var hp: int
var max_hp: int
var damage: int
var arena
var player

var _atk_cd := 0.0
var _walk_phase := 0.0
var _attack_anim := 0.0
var _dying := false

var _body: Node3D  # holds the rig so we can lean it forward when attacking
var _l_leg: Node3D
var _r_leg: Node3D
var _l_arm: Node3D
var _r_arm: Node3D

func setup(_hp: int, _damage: int, _arena, _player) -> void:
	hp = _hp
	max_hp = _hp
	damage = _damage
	arena = _arena
	player = _player
	_build_rig()

# --- Rig --------------------------------------------------------------------

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
	var gray := Color(0.6, 0.62, 0.72)
	var dark := Color(0.3, 0.32, 0.4)

	_body = Node3D.new()
	add_child(_body)

	_box(_body, Vector3(0.9, 0.9, 0.6), Vector3(0, 1.0, 0), gray)              # torso
	_box(_body, Vector3(0.6, 0.5, 0.6), Vector3(0, 1.7, 0), gray)             # head
	_box(_body, Vector3(0.5, 0.12, 0.06), Vector3(0, 1.72, -0.32), Color(1.0, 0.2, 0.2))  # visor
	_box(_body, Vector3(0.05, 0.3, 0.05), Vector3(0, 2.05, 0), dark)          # antenna

	_l_arm = _pivot(_body, Vector3(-0.6, 1.3, 0))
	_box(_l_arm, Vector3(0.22, 0.7, 0.22), Vector3(0, -0.35, 0), dark)
	_r_arm = _pivot(_body, Vector3(0.6, 1.3, 0))
	_box(_r_arm, Vector3(0.22, 0.7, 0.22), Vector3(0, -0.35, 0), dark)

	_l_leg = _pivot(_body, Vector3(-0.25, 0.55, 0))
	_box(_l_leg, Vector3(0.28, 0.6, 0.28), Vector3(0, -0.3, 0), dark)
	_r_leg = _pivot(_body, Vector3(0.25, 0.55, 0))
	_box(_r_leg, Vector3(0.28, 0.6, 0.28), Vector3(0, -0.3, 0), dark)

# --- Update -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dying or arena == null or arena.game_over or player == null or not is_instance_valid(player):
		return
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	if dist > ATTACK_RANGE:
		global_position += to_p.normalized() * SPEED * delta
		_face(player.global_position)
		_walk_phase += delta * 8.0
		var sw := sin(_walk_phase) * 0.7
		_l_leg.rotation.x = sw
		_r_leg.rotation.x = -sw
		_l_arm.rotation.x = -sw
		_r_arm.rotation.x = sw
	else:
		_atk_cd -= delta
		if _atk_cd <= 0.0:
			_atk_cd = ATTACK_INTERVAL
			_attack_anim = 0.35
			player.take_damage(damage)

	# Attack lunge: lean the body forward briefly, then ease back.
	if _attack_anim > 0.0:
		_attack_anim -= delta
		_body.rotation.x = lerpf(_body.rotation.x, -0.5, 0.35)
	else:
		_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.2)

func _face(point: Vector3) -> void:
	var p := Vector3(point.x, global_position.y, point.z)
	if p.distance_to(global_position) > 0.01:
		look_at(p, Vector3.UP)

func take_damage(amount: int) -> void:
	if _dying:
		return
	hp = CombatMath.apply_damage(hp, amount)
	if CombatMath.is_dead(hp):
		arena.on_enemy_killed(self)

## Plays a short death topple, then frees itself. The kill is already counted by the arena.
func play_death() -> void:
	if _dying:
		return
	_dying = true
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", deg_to_rad(85.0), 0.3)
	tw.parallel().tween_property(self, "scale", Vector3(1.0, 0.25, 1.0), 0.35)
	tw.parallel().tween_property(self, "position:y", -0.4, 0.4)
	tw.tween_callback(queue_free)
