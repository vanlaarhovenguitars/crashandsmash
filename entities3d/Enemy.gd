extends Node3D
## A themed enemy that walks toward the player and attacks when close. Two kinds:
##   "toy"      - a bright wind-up toy: small, fast, weak; spinning key, waddle, stiff march.
##   "creature" - a horned monster: big, slow, tough; lumbering walk, chomping jaw.
## Shared behaviour built in code: walk cycle, attack lunge, hit flash, and a death burst.

const CombatMath := preload("res://core/CombatMath.gd")

const ATTACK_RANGE := 2.3
const ATTACK_INTERVAL := 1.0

const KINDS := {
	"toy": {"name": "Wind-up Toy", "hp": 25, "speed": 3.6, "damage": 6},
	"creature": {"name": "Creature", "hp": 55, "speed": 2.2, "damage": 12},
}

var kind := "toy"
var hp: int
var max_hp: int
var damage: int
var speed: float
var arena
var player
var _accent := Color.WHITE

var _atk_cd := 0.0
var _walk_phase := 0.0
var _attack_anim := 0.0
var _dying := false

var _body: Node3D
var _l_leg: Node3D
var _r_leg: Node3D
var _l_arm: Node3D
var _r_arm: Node3D
var _key: Node3D   # toy wind-up key
var _jaw: Node3D   # creature lower jaw

func setup(_kind: String, hp_mult: float, dmg_add: int, _arena, _player) -> void:
	kind = _kind
	var d: Dictionary = KINDS.get(_kind, KINDS["toy"])
	max_hp = int(round(float(d.hp) * hp_mult))
	hp = max_hp
	damage = int(d.damage) + dmg_add
	speed = float(d.speed)
	arena = _arena
	player = _player
	_body = Node3D.new()
	add_child(_body)
	if kind == "toy":
		_build_toy()
	else:
		_build_creature()

# --- Rig helpers ------------------------------------------------------------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
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

func _sphere(parent: Node3D, radius: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _cone(parent: Node3D, radius: float, height: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n

# --- Rigs -------------------------------------------------------------------

func _build_toy() -> void:
	var red := Color(0.92, 0.22, 0.2)
	var yellow := Color(1.0, 0.82, 0.12)
	var white := Color(1, 1, 1)
	_accent = red

	_box(_body, Vector3(0.8, 0.8, 0.55), Vector3(0, 1.0, 0), red)           # torso
	_box(_body, Vector3(0.62, 0.55, 0.6), Vector3(0, 1.65, 0), yellow)      # head
	_box(_body, Vector3(0.16, 0.18, 0.05), Vector3(-0.15, 1.7, -0.31), white)
	_box(_body, Vector3(0.16, 0.18, 0.05), Vector3(0.15, 1.7, -0.31), white)
	_box(_body, Vector3(0.07, 0.09, 0.04), Vector3(-0.15, 1.68, -0.34), Color(0.05, 0.05, 0.05))
	_box(_body, Vector3(0.07, 0.09, 0.04), Vector3(0.15, 1.68, -0.34), Color(0.05, 0.05, 0.05))
	_box(_body, Vector3(0.3, 0.06, 0.04), Vector3(0, 1.5, -0.31), Color(0.1, 0.1, 0.1))  # smile

	_key = _pivot(_body, Vector3(0, 1.15, 0.3))
	_box(_key, Vector3(0.06, 0.06, 0.26), Vector3(0, 0, 0.18), Color(0.82, 0.82, 0.86))
	_box(_key, Vector3(0.32, 0.07, 0.06), Vector3(0, 0, 0.32), Color(0.82, 0.82, 0.86))

	_l_arm = _pivot(_body, Vector3(-0.5, 1.25, 0))
	_box(_l_arm, Vector3(0.18, 0.5, 0.18), Vector3(0, -0.25, 0), red)
	_r_arm = _pivot(_body, Vector3(0.5, 1.25, 0))
	_box(_r_arm, Vector3(0.18, 0.5, 0.18), Vector3(0, -0.25, 0), red)

	_l_leg = _pivot(_body, Vector3(-0.2, 0.5, 0))
	_box(_l_leg, Vector3(0.24, 0.5, 0.24), Vector3(0, -0.25, 0), Color(0.2, 0.2, 0.25))
	_r_leg = _pivot(_body, Vector3(0.2, 0.5, 0))
	_box(_r_leg, Vector3(0.24, 0.5, 0.24), Vector3(0, -0.25, 0), Color(0.2, 0.2, 0.25))

func _build_creature() -> void:
	var teal := Color(0.25, 0.7, 0.45)
	var dteal := Color(0.16, 0.5, 0.32)
	var white := Color(1, 1, 1)
	_accent = teal

	_sphere(_body, 0.62, Vector3(0, 1.05, 0), teal)        # body
	_sphere(_body, 0.46, Vector3(0, 1.72, -0.1), teal)     # head
	_box(_body, Vector3(0.14, 0.16, 0.05), Vector3(-0.17, 1.84, -0.46), Color(1, 0.9, 0.2))
	_box(_body, Vector3(0.14, 0.16, 0.05), Vector3(0.17, 1.84, -0.46), Color(1, 0.9, 0.2))
	_box(_body, Vector3(0.06, 0.09, 0.04), Vector3(-0.17, 1.82, -0.49), Color(0.1, 0, 0))
	_box(_body, Vector3(0.06, 0.09, 0.04), Vector3(0.17, 1.82, -0.49), Color(0.1, 0, 0))
	_cone(_body, 0.12, 0.42, Vector3(-0.26, 2.12, 0.0), Color(0.95, 0.95, 0.9))   # horns
	_cone(_body, 0.12, 0.42, Vector3(0.26, 2.12, 0.0), Color(0.95, 0.95, 0.9))

	_box(_body, Vector3(0.52, 0.14, 0.1), Vector3(0, 1.62, -0.48), Color(0.1, 0.04, 0.04))  # mouth
	_box(_body, Vector3(0.07, 0.11, 0.04), Vector3(-0.13, 1.6, -0.52), white)               # teeth
	_box(_body, Vector3(0.07, 0.11, 0.04), Vector3(0.0, 1.6, -0.52), white)
	_box(_body, Vector3(0.07, 0.11, 0.04), Vector3(0.13, 1.6, -0.52), white)
	_jaw = _pivot(_body, Vector3(0, 1.52, -0.42))
	_box(_jaw, Vector3(0.5, 0.12, 0.26), Vector3(0, -0.05, -0.1), dteal)

	_l_arm = _pivot(_body, Vector3(-0.64, 1.2, 0))
	_box(_l_arm, Vector3(0.24, 0.6, 0.24), Vector3(0, -0.3, 0), dteal)
	_r_arm = _pivot(_body, Vector3(0.64, 1.2, 0))
	_box(_r_arm, Vector3(0.24, 0.6, 0.24), Vector3(0, -0.3, 0), dteal)

	_l_leg = _pivot(_body, Vector3(-0.28, 0.5, 0))
	_box(_l_leg, Vector3(0.3, 0.5, 0.3), Vector3(0, -0.25, 0), dteal)
	_r_leg = _pivot(_body, Vector3(0.28, 0.5, 0))
	_box(_r_leg, Vector3(0.3, 0.5, 0.3), Vector3(0, -0.25, 0), dteal)

# --- Update -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dying or arena == null or arena.game_over or player == null or not is_instance_valid(player):
		return
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	if dist > ATTACK_RANGE:
		global_position += to_p.normalized() * speed * delta
		_face(player.global_position)
		_walk(delta)
	else:
		_atk_cd -= delta
		if _atk_cd <= 0.0:
			_atk_cd = ATTACK_INTERVAL
			_attack_anim = 0.35
			player.take_damage(damage)
	_attack_pose(delta)

func _walk(delta: float) -> void:
	_walk_phase += delta * (10.0 if kind == "toy" else 6.0)
	var amp := 0.7 if kind == "toy" else 0.55
	var sw := sin(_walk_phase) * amp
	_l_leg.rotation.x = sw
	_r_leg.rotation.x = -sw
	_l_arm.rotation.x = -sw * 0.8
	_r_arm.rotation.x = sw * 0.8
	if kind == "toy":
		_key.rotation.z += delta * 9.0
		_body.rotation.z = sin(_walk_phase) * 0.12          # waddle
	else:
		_body.position.y = absf(sin(_walk_phase)) * 0.12     # lumber
		_body.rotation.z = sin(_walk_phase * 0.5) * 0.06

func _attack_pose(delta: float) -> void:
	if _attack_anim > 0.0:
		_attack_anim -= delta
		_body.rotation.x = lerpf(_body.rotation.x, -0.45, 0.35)
		if kind == "toy":
			_l_arm.rotation.x = lerpf(_l_arm.rotation.x, -1.4, 0.4)
			_r_arm.rotation.x = lerpf(_r_arm.rotation.x, -1.4, 0.4)
		elif _jaw != null:
			_jaw.rotation.x = lerpf(_jaw.rotation.x, 0.6, 0.4)   # open jaw
	else:
		_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.2)
		if kind == "creature" and _jaw != null:
			_jaw.rotation.x = lerpf(_jaw.rotation.x, 0.0, 0.2)

func _face(point: Vector3) -> void:
	var p := Vector3(point.x, global_position.y, point.z)
	if p.distance_to(global_position) > 0.01:
		look_at(p, Vector3.UP)

func take_damage(amount: int) -> void:
	if _dying:
		return
	hp = CombatMath.apply_damage(hp, amount)
	if is_instance_valid(_body):
		_body.scale = Vector3(1.12, 0.9, 1.12)   # hit flash squash
		var tw := create_tween()
		tw.tween_property(_body, "scale", Vector3.ONE, 0.12)
	if CombatMath.is_dead(hp):
		arena.on_enemy_killed(self)

## Plays a death burst + topple, then frees itself. The kill is already counted by the arena.
func play_death() -> void:
	if _dying:
		return
	_dying = true
	arena.spawn_burst(global_position + Vector3(0, 1.0, 0), _accent)
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", deg_to_rad(85.0), 0.3)
	tw.parallel().tween_property(self, "scale", Vector3(1.0, 0.2, 1.0), 0.35)
	tw.parallel().tween_property(self, "position:y", -0.4, 0.4)
	tw.tween_callback(queue_free)
