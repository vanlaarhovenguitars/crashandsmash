extends Node2D
## A shot fired by a shooter defender. Travels right along its lane and damages the
## first robot it reaches, then frees itself.

const SPEED := 700.0

var row: int
var damage: int
var stage  # back-reference to Stage1

func setup(r: int, dmg: int, stage_ref, color: Color) -> void:
	row = r
	damage = dmg
	stage = stage_ref
	var dot := ColorRect.new()
	dot.size = Vector2(24, 24)
	dot.position = Vector2(-12, -12)
	dot.color = color
	add_child(dot)

func _process(delta: float) -> void:
	if stage.game_over:
		queue_free()
		return
	position.x += SPEED * delta
	var target = stage.first_robot_in_row_ahead(row, position.x)
	if target != null and target.position.x - position.x <= 24.0:
		target.take_damage(damage)
		queue_free()
		return
	if position.x > stage.field_right() + 80.0:
		queue_free()
