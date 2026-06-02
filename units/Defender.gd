extends Node2D
## A defender the player places on the grid: Money Printer, Beast Toy, Creature, or Bat.
## Behaviour is driven by the `role` field of its definition (see data/Units.gd).
## Built entirely in code with placeholder shapes so no art assets are needed yet.

const CombatMath := preload("res://core/CombatMath.gd")

var def: Dictionary
var hp: int
var max_hp: int
var row: int
var col: int
var stage  # back-reference to Stage1 for callbacks

var _timer := 0.0
var _bar: ColorRect

func setup(definition: Dictionary, r: int, c: int, stage_ref) -> void:
	def = definition
	row = r
	col = c
	stage = stage_ref
	hp = def.hp
	max_hp = def.hp
	_build_visual()

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(140, 150)
	body.position = Vector2(-70, -75)
	body.color = def.color
	add_child(body)

	var label := Label.new()
	label.text = def.name
	label.position = Vector2(-66, -60)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.BLACK)
	add_child(label)

	_bar = ColorRect.new()
	_bar.color = Color(0.25, 0.9, 0.35)
	_bar.position = Vector2(-70, -95)
	_bar.size = Vector2(140, 12)
	add_child(_bar)

func _process(delta: float) -> void:
	if stage.game_over:
		return
	_timer += delta
	match def.role:
		"income":
			if _timer >= def.income_interval:
				_timer = 0.0
				stage.add_coins(def.income)
				_popup("+%d" % def.income)
		"shooter":
			if _timer >= def.attack_interval and stage.has_robot_ahead(row, global_position.x):
				_timer = 0.0
				stage.spawn_projectile(row, global_position, def.damage, def.color)
		"tank":
			if _timer >= def.attack_interval:
				_timer = 0.0
				var target = stage.first_robot_in_row_ahead(row, global_position.x)
				if target != null and target.position.x - global_position.x <= stage.cell_w * 1.2:
					target.take_damage(def.damage)

func take_damage(amount: int) -> void:
	hp = CombatMath.apply_damage(hp, amount)
	_bar.size.x = 140.0 * float(hp) / float(max_hp)
	if CombatMath.is_dead(hp):
		stage.remove_defender(self)

func _popup(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(-20, -110)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", -160.0, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)
