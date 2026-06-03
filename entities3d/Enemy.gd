extends Node3D
## Enemies styled after MrBeast Lab "Swarms" mini-monster figures: blobby, big-eyed little
## beasts in bright random colours with a random top feature (spikes / horns / antennae /
## fin), so every spawn looks like a different collectible monster. Two kinds:
##   "swarmling" - small, fast, weak; hops along; swarms you.
##   "brute"     - big, slow, tough; lumbers and chomps.
## All animation is code-driven: walk/hop, attack lunge, hit-flash, and a death burst.

const CombatMath := preload("res://core/CombatMath.gd")

const ATTACK_RANGE := 2.3
const ATTACK_INTERVAL := 1.0

const KINDS := {
	"swarmling": {"name": "Swarmling", "hp": 22, "speed": 3.8, "damage": 6},
	"brute": {"name": "Brute Beast", "hp": 60, "speed": 2.1, "damage": 12},
}

const BODY_COLORS := [
	Color(0.55, 0.85, 0.25), Color(0.65, 0.35, 0.9), Color(1.0, 0.5, 0.2),
	Color(0.2, 0.8, 0.85), Color(1.0, 0.35, 0.6), Color(0.95, 0.8, 0.2),
	Color(0.3, 0.6, 1.0), Color(0.95, 0.3, 0.3),
]

var kind := "swarmling"
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
var _jaw: Node3D   # brute lower jaw

func setup(_kind: String, hp_mult: float, dmg_add: int, _arena, _player) -> void:
	kind = _kind
	var d: Dictionary = KINDS.get(_kind, KINDS["swarmling"])
	max_hp = int(round(float(d.hp) * hp_mult))
	hp = max_hp
	damage = int(d.damage) + dmg_add
	speed = float(d.speed)
	arena = _arena
	player = _player
	_body = Node3D.new()
	add_child(_body)
	if kind == "brute":
		_build_brute()
		scale = Vector3.ONE * randf_range(1.0, 1.18)
	else:
		_build_swarmling()
		scale = Vector3.ONE * randf_range(0.85, 1.15)

# --- Mesh helpers -----------------------------------------------------------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.rim_enabled = true
	m.rim = 0.4
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

func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = height
	mi.mesh = cm
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

func _cyl(parent: Node3D, radius: float, height: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
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

func _eye(parent: Node3D, pos: Vector3, r: float) -> void:
	_sphere(parent, r, pos, Color.WHITE)
	_sphere(parent, r * 0.5, pos + Vector3(0, 0, -r * 0.7), Color(0.05, 0.05, 0.08))

func _add_top_feature(top_y: float, dark: Color) -> void:
	match randi() % 4:
		0:  # row of spikes
			for i in 3:
				_cone(_body, 0.08, 0.24, Vector3(-0.18 + i * 0.18, top_y, 0.08), dark)
		1:  # horns
			_cone(_body, 0.1, 0.3, Vector3(-0.2, top_y, 0.0), Color(0.96, 0.96, 0.9))
			_cone(_body, 0.1, 0.3, Vector3(0.2, top_y, 0.0), Color(0.96, 0.96, 0.9))
		2:  # antennae with ball tips
			for sx in [-0.16, 0.16]:
				var a := _pivot(_body, Vector3(sx, top_y - 0.08, 0))
				_cyl(a, 0.03, 0.3, Vector3(0, 0.15, 0), dark)
				_sphere(a, 0.08, Vector3(0, 0.32, 0), _accent)
		3:  # back fin
			_box(_body, Vector3(0.08, 0.34, 0.42), Vector3(0, top_y, 0.05), dark)

# --- Rigs -------------------------------------------------------------------

func _build_swarmling() -> void:
	var col: Color = BODY_COLORS[randi() % BODY_COLORS.size()]
	_accent = col
	var dark := col.darkened(0.35)

	var body := _sphere(_body, 0.52, Vector3(0, 0.72, 0), col)
	body.scale = Vector3(1.0, 0.92, 1.0)
	_sphere(_body, 0.32, Vector3(0, 0.64, -0.3), col.lightened(0.25))   # belly

	_eye(_body, Vector3(-0.2, 0.96, -0.34), 0.17)
	_eye(_body, Vector3(0.2, 0.96, -0.34), 0.17)
	_box(_body, Vector3(0.34, 0.1, 0.06), Vector3(0, 0.66, -0.48), Color(0.15, 0.05, 0.08))  # mouth
	_box(_body, Vector3(0.07, 0.09, 0.04), Vector3(-0.08, 0.63, -0.5), Color.WHITE)
	_box(_body, Vector3(0.07, 0.09, 0.04), Vector3(0.08, 0.63, -0.5), Color.WHITE)

	_add_top_feature(1.08, dark)

	_l_arm = _pivot(_body, Vector3(-0.5, 0.78, 0))
	_capsule(_l_arm, 0.1, 0.42, Vector3(0, -0.2, 0), dark)
	_r_arm = _pivot(_body, Vector3(0.5, 0.78, 0))
	_capsule(_r_arm, 0.1, 0.42, Vector3(0, -0.2, 0), dark)
	_l_leg = _pivot(_body, Vector3(-0.2, 0.34, 0))
	_capsule(_l_leg, 0.12, 0.36, Vector3(0, -0.17, 0), dark)
	_r_leg = _pivot(_body, Vector3(0.2, 0.34, 0))
	_capsule(_r_leg, 0.12, 0.36, Vector3(0, -0.17, 0), dark)

func _build_brute() -> void:
	var col: Color = BODY_COLORS[randi() % BODY_COLORS.size()]
	_accent = col
	var dark := col.darkened(0.35)
	var white := Color(0.97, 0.97, 0.95)

	_sphere(_body, 0.66, Vector3(0, 1.05, 0), col)        # body
	_sphere(_body, 0.5, Vector3(0, 1.78, -0.08), col)     # head
	_eye(_body, Vector3(-0.2, 1.92, -0.42), 0.2)
	_eye(_body, Vector3(0.2, 1.92, -0.42), 0.2)
	_cone(_body, 0.13, 0.46, Vector3(-0.28, 2.2, 0.0), white)   # horns
	_cone(_body, 0.13, 0.46, Vector3(0.28, 2.2, 0.0), white)

	_box(_body, Vector3(0.58, 0.16, 0.1), Vector3(0, 1.66, -0.5), Color(0.12, 0.04, 0.05))  # mouth
	_box(_body, Vector3(0.08, 0.12, 0.04), Vector3(-0.16, 1.64, -0.54), white)               # teeth
	_box(_body, Vector3(0.08, 0.12, 0.04), Vector3(0.0, 1.64, -0.54), white)
	_box(_body, Vector3(0.08, 0.12, 0.04), Vector3(0.16, 1.64, -0.54), white)
	_jaw = _pivot(_body, Vector3(0, 1.56, -0.44))
	_box(_jaw, Vector3(0.56, 0.13, 0.28), Vector3(0, -0.05, -0.1), dark)

	_l_arm = _pivot(_body, Vector3(-0.68, 1.22, 0))
	_capsule(_l_arm, 0.15, 0.66, Vector3(0, -0.32, 0), dark)
	_r_arm = _pivot(_body, Vector3(0.68, 1.22, 0))
	_capsule(_r_arm, 0.15, 0.66, Vector3(0, -0.32, 0), dark)
	_l_leg = _pivot(_body, Vector3(-0.3, 0.52, 0))
	_capsule(_l_leg, 0.17, 0.54, Vector3(0, -0.26, 0), dark)
	_r_leg = _pivot(_body, Vector3(0.3, 0.52, 0))
	_capsule(_r_leg, 0.17, 0.54, Vector3(0, -0.26, 0), dark)

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
	_walk_phase += delta * (12.0 if kind == "swarmling" else 6.0)
	var amp := 0.6 if kind == "swarmling" else 0.55
	var sw := sin(_walk_phase) * amp
	_l_leg.rotation.x = sw
	_r_leg.rotation.x = -sw
	_l_arm.rotation.x = -sw * 0.8
	_r_arm.rotation.x = sw * 0.8
	if kind == "swarmling":
		_body.position.y = absf(sin(_walk_phase)) * 0.16   # hop
	else:
		_body.position.y = absf(sin(_walk_phase)) * 0.1
		_body.rotation.z = sin(_walk_phase * 0.5) * 0.05

func _attack_pose(delta: float) -> void:
	if _attack_anim > 0.0:
		_attack_anim -= delta
		_body.rotation.x = lerpf(_body.rotation.x, -0.4, 0.35)
		if kind == "brute" and _jaw != null:
			_jaw.rotation.x = lerpf(_jaw.rotation.x, 0.6, 0.4)
		else:
			_l_arm.rotation.x = lerpf(_l_arm.rotation.x, -1.3, 0.4)
			_r_arm.rotation.x = lerpf(_r_arm.rotation.x, -1.3, 0.4)
	else:
		_body.rotation.x = lerpf(_body.rotation.x, 0.0, 0.2)
		if kind == "brute" and _jaw != null:
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
		_body.scale = Vector3(1.15, 0.88, 1.15)   # hit-flash squash
		var tw := create_tween()
		tw.tween_property(_body, "scale", Vector3.ONE, 0.12)
	if CombatMath.is_dead(hp):
		arena.on_enemy_killed(self)

## Death burst + topple, then frees itself. The kill is already counted by the arena.
func play_death() -> void:
	if _dying:
		return
	_dying = true
	arena.spawn_burst(global_position + Vector3(0, 0.9, 0), _accent)
	var tw := create_tween()
	tw.tween_property(self, "rotation:z", deg_to_rad(85.0), 0.3)
	tw.parallel().tween_property(self, "scale", scale * Vector3(1.0, 0.2, 1.0), 0.35)
	tw.parallel().tween_property(self, "position:y", -0.4, 0.4)
	tw.tween_callback(queue_free)
