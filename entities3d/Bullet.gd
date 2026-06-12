extends Node3D
## A glowing shot fired by the hero. Colour comes from the hero (bat = purple squeak,
## beast toy = gold bolt, creature = green blob). Emissive material + bloom makes it pop.
## Flies straight and damages the first enemy it reaches; sparks fly on impact.

const SceneDress := preload("res://scenes3d/SceneDress.gd")

const SPEED := 42.0

var dir: Vector3
var damage: int
var arena
var color := Color(1.0, 0.85, 0.2)
var _life := 3.0

func setup(_dir: Vector3, _damage: int, _arena, _color: Color) -> void:
	dir = _dir.normalized()
	damage = _damage
	arena = _arena
	color = _color
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	mesh.mesh = sm
	mesh.material_override = SceneDress.make_mat(color, 0.4, 2.5)
	mesh.scale = Vector3(0.8, 0.8, 1.6)  # stretched along travel for a "bolt" look
	add_child(mesh)
	look_at_from_position(global_position, global_position + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	if arena == null or arena.game_over:
		queue_free()
		return
	global_position += dir * SPEED * delta
	_life -= delta
	var hit = arena.bullet_hit_check(global_position, 1.1)
	if hit != null:
		hit.take_damage(damage)
		arena.spawn_hit_sparks(global_position, color)
		queue_free()
		return
	if _life <= 0.0:
		queue_free()
