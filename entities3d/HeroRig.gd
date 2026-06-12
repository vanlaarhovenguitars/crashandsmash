extends Node3D
## The visual body + animations for the three playable heroes from Zane's design:
##   "bat"       - hovers and flaps its wings; fast, rapid weak shots from its squeak.
##   "beast_toy" - action-figure hero with a blaster; balanced all-rounder.
##   "creature"  - big green monster; slow but hits like a truck.
## Built from rounded shapes with code-driven animation, shared between the
## character-select screen and the in-game Player.

const SceneDress := preload("res://scenes3d/SceneDress.gd")

const STATS := {
	"bat": {
		"name": "Bat", "hp": 85, "speed": 10.0, "damage": 7,
		"fire_interval": 0.25, "fire_range": 20.0, "bullet_color": Color(0.85, 0.5, 1.0),
	},
	"beast_toy": {
		"name": "Beast Toy", "hp": 100, "speed": 8.5, "damage": 12,
		"fire_interval": 0.4, "fire_range": 22.0, "bullet_color": Color(1.0, 0.85, 0.2),
	},
	"creature": {
		"name": "Creature", "hp": 130, "speed": 7.0, "damage": 20,
		"fire_interval": 0.6, "fire_range": 18.0, "bullet_color": Color(0.4, 1.0, 0.45),
	},
}
const KINDS := ["bat", "beast_toy", "creature"]

var kind := "beast_toy"
var muzzle: Node3D

var _t := 0.0
var _walk_phase := 0.0
var _body: Node3D
var _l_leg: Node3D
var _r_leg: Node3D
var _l_arm: Node3D
var _r_arm: Node3D
var _l_wing: Node3D
var _r_wing: Node3D
var _tail: Node3D
var _flash: MeshInstance3D

func build(_kind: String) -> void:
	kind = _kind
	_body = Node3D.new()
	add_child(_body)
	match kind:
		"bat":
			_build_bat()
		"creature":
			_build_creature()
		_:
			_build_beast_toy()
	_build_flash()

# --- Shape helpers ----------------------------------------------------------

func _mat(c: Color, rough := 0.5) -> StandardMaterial3D:
	return SceneDress.make_mat(c, rough)

func _sphere(parent: Node3D, r: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _capsule(parent: Node3D, r: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(c)
	parent.add_child(mi)
	return mi

func _cone(parent: Node3D, r: float, h: float, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
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

func _eyes(parent: Node3D, y: float, z: float, spacing: float, r: float, iris := Color(0.05, 0.05, 0.08)) -> void:
	for sx in [-spacing, spacing]:
		_sphere(parent, r, Vector3(sx, y, z), Color.WHITE)
		_sphere(parent, r * 0.5, Vector3(sx, y, z - r * 0.7), iris)

# --- Rigs -------------------------------------------------------------------

func _build_beast_toy() -> void:
	var blue := Color(0.18, 0.5, 0.95)
	var dblue := Color(0.13, 0.33, 0.65)
	var skin := Color(1.0, 0.84, 0.62)

	_capsule(_body, 0.36, 1.0, Vector3(0, 1.15, 0), blue)
	_box(_body, Vector3(0.4, 0.42, 0.06), Vector3(0, 1.22, -0.33), Color(0.95, 0.95, 1.0))  # chest panel
	_box(_body, Vector3(0.22, 0.24, 0.04), Vector3(0, 1.22, -0.37), Color(1.0, 0.75, 0.1))  # emblem
	_sphere(_body, 0.34, Vector3(0, 1.82, 0), skin)
	# cap
	var cap := _sphere(_body, 0.36, Vector3(0, 1.92, 0.02), dblue)
	cap.scale = Vector3(1.0, 0.6, 1.0)
	_box(_body, Vector3(0.5, 0.08, 0.3), Vector3(0, 1.86, -0.3), dblue)  # cap brim
	_eyes(_body, 1.84, -0.28, 0.13, 0.085)

	_l_leg = _pivot(_body, Vector3(-0.17, 0.82, 0))
	_capsule(_l_leg, 0.14, 0.8, Vector3(0, -0.38, 0), dblue)
	_r_leg = _pivot(_body, Vector3(0.17, 0.82, 0))
	_capsule(_r_leg, 0.14, 0.8, Vector3(0, -0.38, 0), dblue)
	_l_arm = _pivot(_body, Vector3(-0.46, 1.45, 0))
	_capsule(_l_arm, 0.11, 0.6, Vector3(0, -0.3, 0), blue)
	_r_arm = _pivot(_body, Vector3(0.46, 1.45, 0))
	_capsule(_r_arm, 0.11, 0.6, Vector3(0, -0.3, 0), blue)
	_box(_r_arm, Vector3(0.15, 0.15, 0.5), Vector3(0, -0.5, -0.22), Color(0.22, 0.22, 0.3))  # blaster
	muzzle = _pivot(_r_arm, Vector3(0, -0.5, -0.5))

func _build_bat() -> void:
	var purple := Color(0.42, 0.26, 0.6)
	var dpurple := Color(0.28, 0.16, 0.42)
	# Bats hover: build the whole body lifted off the ground.
	var lift := 0.55

	var torso := _sphere(_body, 0.42, Vector3(0, 0.85 + lift, 0), purple)
	torso.scale = Vector3(0.9, 1.0, 0.85)
	_sphere(_body, 0.3, Vector3(0, 0.8 + lift, -0.25), purple.lightened(0.3))  # belly
	_sphere(_body, 0.36, Vector3(0, 1.4 + lift, 0), purple)                     # head
	_cone(_body, 0.13, 0.4, Vector3(-0.2, 1.78 + lift, 0), dpurple)             # ears
	_cone(_body, 0.13, 0.4, Vector3(0.2, 1.78 + lift, 0), dpurple)
	_eyes(_body, 1.46 + lift, -0.28, 0.14, 0.09, Color(1.0, 0.8, 0.2))
	_box(_body, Vector3(0.05, 0.09, 0.04), Vector3(-0.07, 1.28 + lift, -0.33), Color.WHITE)  # fangs
	_box(_body, Vector3(0.05, 0.09, 0.04), Vector3(0.07, 1.28 + lift, -0.33), Color.WHITE)
	# tiny feet
	_sphere(_body, 0.09, Vector3(-0.14, 0.45 + lift, 0), dpurple)
	_sphere(_body, 0.09, Vector3(0.14, 0.45 + lift, 0), dpurple)

	_l_wing = _pivot(_body, Vector3(-0.38, 1.05 + lift, 0.05))
	var lw := _box(_l_wing, Vector3(0.85, 0.5, 0.06), Vector3(-0.45, 0.1, 0.08), dpurple)
	lw.rotation.z = 0.15
	_r_wing = _pivot(_body, Vector3(0.38, 1.05 + lift, 0.05))
	var rw := _box(_r_wing, Vector3(0.85, 0.5, 0.06), Vector3(0.45, 0.1, 0.08), dpurple)
	rw.rotation.z = -0.15

	muzzle = _pivot(_body, Vector3(0, 1.3 + lift, -0.4))  # shoots squeaks from its mouth

func _build_creature() -> void:
	var green := Color(0.3, 0.68, 0.32)
	var dgreen := Color(0.2, 0.48, 0.24)
	var white := Color(0.97, 0.97, 0.92)

	var torso := _sphere(_body, 0.62, Vector3(0, 1.0, 0), green)
	torso.scale = Vector3(1.0, 1.05, 0.9)
	_sphere(_body, 0.4, Vector3(0, 0.9, -0.35), green.lightened(0.25))  # belly
	_sphere(_body, 0.45, Vector3(0, 1.78, -0.05), green)                 # head
	_cone(_body, 0.12, 0.4, Vector3(-0.24, 2.16, 0.05), white)           # horns
	_cone(_body, 0.12, 0.4, Vector3(0.24, 2.16, 0.05), white)
	_eyes(_body, 1.88, -0.36, 0.18, 0.1, Color(0.9, 0.6, 0.1))
	_box(_body, Vector3(0.5, 0.12, 0.08), Vector3(0, 1.62, -0.42), Color(0.1, 0.05, 0.05))  # grin
	for i in 3:
		_box(_body, Vector3(0.07, 0.1, 0.04), Vector3(-0.14 + i * 0.14, 1.6, -0.45), white)

	_tail = _pivot(_body, Vector3(0, 0.7, 0.55))
	var tail_seg := _capsule(_tail, 0.12, 0.7, Vector3(0, 0.0, 0.3), dgreen)
	tail_seg.rotation.x = deg_to_rad(70)

	_l_leg = _pivot(_body, Vector3(-0.28, 0.5, 0))
	_capsule(_l_leg, 0.17, 0.54, Vector3(0, -0.26, 0), dgreen)
	_r_leg = _pivot(_body, Vector3(0.28, 0.5, 0))
	_capsule(_r_leg, 0.17, 0.54, Vector3(0, -0.26, 0), dgreen)
	_l_arm = _pivot(_body, Vector3(-0.62, 1.2, 0))
	_capsule(_l_arm, 0.14, 0.62, Vector3(0, -0.3, 0), dgreen)
	_cone(_l_arm, 0.06, 0.16, Vector3(0, -0.64, -0.08), white)  # claw
	_r_arm = _pivot(_body, Vector3(0.62, 1.2, 0))
	_capsule(_r_arm, 0.14, 0.62, Vector3(0, -0.3, 0), dgreen)
	_cone(_r_arm, 0.06, 0.16, Vector3(0, -0.64, -0.08), white)

	muzzle = _pivot(_body, Vector3(0, 1.6, -0.5))  # spits energy blobs

func _build_flash() -> void:
	_flash = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	_flash.mesh = sm
	var stats: Dictionary = STATS[kind]
	var c: Color = stats.bullet_color
	_flash.material_override = SceneDress.make_mat(c, 0.5, 3.0)
	_flash.visible = false
	muzzle.add_child(_flash)

## Brief glowing muzzle flash when firing (bloom makes it pop).
func flash() -> void:
	_flash.visible = true
	_flash.scale = Vector3.ONE * randf_range(0.9, 1.3)
	var tw := create_tween()
	tw.tween_property(_flash, "scale", Vector3.ONE * 0.1, 0.09)
	tw.tween_callback(func() -> void: _flash.visible = false)

# --- Animation --------------------------------------------------------------

## Drives the rig every frame. speed_frac 0..1; aiming = an enemy is targeted.
func set_motion(delta: float, moving: bool, speed_frac: float, aiming: bool) -> void:
	_t += delta
	match kind:
		"bat":
			# Constant flap; faster when moving. Whole body bobs as it hovers.
			var flap_speed := 14.0 if moving else 7.0
			var flap := sin(_t * flap_speed) * 0.7
			_l_wing.rotation.z = flap
			_r_wing.rotation.z = -flap
			_body.position.y = sin(_t * 3.0) * 0.12
			_body.rotation.x = lerpf(_body.rotation.x, -0.18 if moving else 0.0, 0.15)
		"creature":
			if moving:
				_walk_phase += delta * 7.0 * maxf(speed_frac, 0.3)
				var sw := sin(_walk_phase) * 0.5 * speed_frac
				_l_leg.rotation.x = sw
				_r_leg.rotation.x = -sw
				_l_arm.rotation.x = -sw * 0.9
				_r_arm.rotation.x = sw * 0.9
				_body.position.y = absf(sin(_walk_phase)) * 0.09
			else:
				_settle_limbs()
				_body.position.y = sin(_t * 2.0) * 0.03
			_tail.rotation.y = sin(_t * 2.5) * 0.35
			if aiming:
				_r_arm.rotation.x = lerp_angle(_r_arm.rotation.x, -1.2, 0.3)
		_:
			if moving:
				_walk_phase += delta * 10.0 * maxf(speed_frac, 0.3)
				var sw := sin(_walk_phase) * 0.6 * speed_frac
				_l_leg.rotation.x = sw
				_r_leg.rotation.x = -sw
				_l_arm.rotation.x = lerp_angle(_l_arm.rotation.x, -sw * 0.7, 0.4)
				_body.position.y = absf(sin(_walk_phase)) * 0.05
			else:
				_settle_limbs()
				_body.position.y = sin(_t * 2.0) * 0.03
			var r_target := -1.4 if aiming else (-sin(_walk_phase) * 0.7 if moving else 0.0)
			_r_arm.rotation.x = lerp_angle(_r_arm.rotation.x, r_target, 0.4)

func _settle_limbs() -> void:
	if _l_leg != null:
		_l_leg.rotation.x = lerpf(_l_leg.rotation.x, 0.0, 0.2)
		_r_leg.rotation.x = lerpf(_r_leg.rotation.x, 0.0, 0.2)
	if _l_arm != null:
		_l_arm.rotation.x = lerpf(_l_arm.rotation.x, 0.0, 0.2)
		_r_arm.rotation.x = lerpf(_r_arm.rotation.x, 0.0, 0.2)
