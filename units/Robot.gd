extends Node2D
## An enemy robot. Marches left along its lane; if a living defender occupies the
## cell it's in, it stops and chews through it; if it reaches the base, the player loses.

const CombatMath := preload("res://core/CombatMath.gd")

var def: Dictionary
var hp: int
var max_hp: int
var row: int
var speed: float
var stage  # back-reference to Stage1

var _attack_timer := 0.0
var _bar: ColorRect

func setup(definition: Dictionary, r: int, stage_ref) -> void:
	def = definition
	row = r
	stage = stage_ref
	hp = def.hp
	max_hp = def.hp
	speed = def.speed
	_build_visual()

func _build_visual() -> void:
	var body := ColorRect.new()
	body.size = Vector2(120, 140)
	body.position = Vector2(-60, -70)
	body.color = def.color
	add_child(body)

	var label := Label.new()
	label.text = def.name
	label.position = Vector2(-56, -55)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.BLACK)
	add_child(label)

	_bar = ColorRect.new()
	_bar.color = Color(0.9, 0.25, 0.25)
	_bar.position = Vector2(-60, -90)
	_bar.size = Vector2(120, 12)
	add_child(_bar)

func _process(delta: float) -> void:
	if stage.game_over:
		return
	var blocker = stage.defender_blocking(self)
	if blocker != null:
		_attack_timer += delta
		if _attack_timer >= def.attack_interval:
			_attack_timer = 0.0
			blocker.take_damage(def.damage)
	else:
		position.x -= speed * delta
		if position.x <= stage.base_x():
			stage.on_robot_reached_base(self)

func take_damage(amount: int) -> void:
	hp = CombatMath.apply_damage(hp, amount)
	_bar.size.x = 120.0 * float(hp) / float(max_hp)
	if CombatMath.is_dead(hp):
		stage.on_robot_killed(self)
