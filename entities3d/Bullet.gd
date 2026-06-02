extends Node3D
## A bullet fired by the player. Flies in a straight (horizontal) line and damages the
## first robot it reaches. Built in code with a glowing sphere so no art is needed yet.

const SPEED := 42.0

var dir: Vector3
var damage: int
var arena
var _life := 3.0

func setup(_dir: Vector3, _damage: int, _arena) -> void:
	dir = _dir.normalized()
	damage = _damage
	arena = _arena
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.1)
	mesh.material_override = mat
	add_child(mesh)

func _physics_process(delta: float) -> void:
	if arena == null or arena.game_over:
		queue_free()
		return
	global_position += dir * SPEED * delta
	_life -= delta
	var hit = arena.bullet_hit_check(global_position, 1.1)
	if hit != null:
		hit.take_damage(damage)
		queue_free()
		return
	if _life <= 0.0:
		queue_free()
