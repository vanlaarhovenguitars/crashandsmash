extends Node3D
## A robot that walks straight toward the player and bites when it's close. Moved
## kinematically on the ground (no physics jitter); bullets and contact use distance checks.

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

func setup(_hp: int, _damage: int, _arena, _player) -> void:
	hp = _hp
	max_hp = _hp
	damage = _damage
	arena = _arena
	player = _player

	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.6, 1.0)
	mesh.mesh = bm
	mesh.position = Vector3(0, 0.8, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.64, 0.72)
	mesh.material_override = mat
	add_child(mesh)

func _physics_process(delta: float) -> void:
	if arena == null or arena.game_over or player == null or not is_instance_valid(player):
		return
	var to_p: Vector3 = player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	if dist > ATTACK_RANGE:
		global_position += to_p.normalized() * SPEED * delta
		_face(player.global_position)
	else:
		_atk_cd -= delta
		if _atk_cd <= 0.0:
			_atk_cd = ATTACK_INTERVAL
			player.take_damage(damage)

func _face(point: Vector3) -> void:
	var p := Vector3(point.x, global_position.y, point.z)
	if p.distance_to(global_position) > 0.01:
		look_at(p, Vector3.UP)

func take_damage(amount: int) -> void:
	hp = CombatMath.apply_damage(hp, amount)
	if CombatMath.is_dead(hp):
		arena.on_enemy_killed(self)
