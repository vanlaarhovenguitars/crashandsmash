extends CanvasLayer
## On-screen UI for the 3D mode: health bar, defeated counter, win/lose banner, and a
## touch joystick (left half of the screen) for phones. Keyboard/gamepad players ignore the
## joystick. When the banner is up, a tap/click restarts via the arena.

var arena

var _health_bar: ColorRect
var _kills_label: Label
var _banner: Label

# Touch joystick state
const JOY_RADIUS := 120.0
var _move := Vector2.ZERO
var _joy_index := -1
var _joy_origin := Vector2.ZERO
var _joy_base: ColorRect
var _joy_knob: ColorRect
var _banner_active := false

func _ready() -> void:
	var health_bg := ColorRect.new()
	health_bg.color = Color(0, 0, 0, 0.5)
	health_bg.position = Vector2(28, 26)
	health_bg.size = Vector2(308, 34)
	add_child(health_bg)

	_health_bar = ColorRect.new()
	_health_bar.color = Color(0.2, 0.85, 0.3)
	_health_bar.position = Vector2(32, 30)
	_health_bar.size = Vector2(300, 26)
	add_child(_health_bar)

	_kills_label = Label.new()
	_kills_label.position = Vector2(32, 70)
	_kills_label.add_theme_font_size_override("font_size", 34)
	add_child(_kills_label)

	_joy_base = ColorRect.new()
	_joy_base.color = Color(1, 1, 1, 0.12)
	_joy_base.size = Vector2(JOY_RADIUS * 2, JOY_RADIUS * 2)
	_joy_base.visible = false
	add_child(_joy_base)

	_joy_knob = ColorRect.new()
	_joy_knob.color = Color(1, 1, 1, 0.35)
	_joy_knob.size = Vector2(90, 90)
	_joy_knob.visible = false
	add_child(_joy_knob)

	_banner = Label.new()
	_banner.position = Vector2(440, 430)
	_banner.add_theme_font_size_override("font_size", 96)
	_banner.add_theme_color_override("font_color", Color(1, 0.95, 0.3))
	_banner.visible = false
	add_child(_banner)

func move_vector() -> Vector2:
	return _move

func set_health(hp: int, max_hp: int) -> void:
	_health_bar.size.x = 300.0 * clampf(float(hp) / float(max_hp), 0.0, 1.0)

func set_kills(stage: int, k: int, needed: int) -> void:
	if needed < 0:
		_kills_label.text = "Stage %d  -  Defeated: %d  (endless)" % [stage, k]
	else:
		_kills_label.text = "Stage %d  -  Defeated: %d / %d" % [stage, k, needed]

func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_active = true
	_joy_index = -1
	_move = Vector2.ZERO
	_joy_base.visible = false
	_joy_knob.visible = false

func _input(event: InputEvent) -> void:
	if _banner_active:
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			if arena != null:
				arena.confirm_restart()
		return
	if event is InputEventScreenTouch:
		var half_w := get_viewport().get_visible_rect().size.x * 0.5
		if event.pressed and event.position.x < half_w:
			_joy_index = event.index
			_joy_origin = event.position
			_place_joy(event.position, event.position)
		elif not event.pressed and event.index == _joy_index:
			_joy_index = -1
			_move = Vector2.ZERO
			_joy_base.visible = false
			_joy_knob.visible = false
	elif event is InputEventScreenDrag and event.index == _joy_index:
		var off: Vector2 = event.position - _joy_origin
		if off.length() > JOY_RADIUS:
			off = off.normalized() * JOY_RADIUS
		# Screen Y is down; flip so up = forward.
		_move = Vector2(off.x, -off.y) / JOY_RADIUS
		_place_joy(_joy_origin, _joy_origin + off)

func _place_joy(base_center: Vector2, knob_center: Vector2) -> void:
	_joy_base.position = base_center - _joy_base.size * 0.5
	_joy_knob.position = knob_center - _joy_knob.size * 0.5
	_joy_base.visible = true
	_joy_knob.visible = true
