extends CanvasLayer
## On-screen UI: coin counter, defeat counter, the defender selection bar, and the
## win/lose banner. Built in code so it scales cleanly to the 1920x1080 TV layout.

signal defender_selected(index)

const Units := preload("res://data/Units.gd")

var _coin_label: Label
var _kills_label: Label
var _banner: Label
var _buttons: Array = []

func _ready() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0, 0, 0, 0.55)
	bar.size = Vector2(1920, 150)
	add_child(bar)

	_coin_label = _make_label("Coins: 0", Vector2(30, 16), 40)
	add_child(_coin_label)
	_kills_label = _make_label("Defeated: 0 / 3", Vector2(30, 80), 34)
	add_child(_kills_label)

	var x := 430.0
	for i in Units.DEFENDERS.size():
		var d: Dictionary = Units.DEFENDERS[i]
		var b := Button.new()
		b.text = "%d. %s\n$%d" % [i + 1, d.name, d.cost]
		b.position = Vector2(x, 12)
		b.custom_minimum_size = Vector2(220, 126)
		b.focus_mode = Control.FOCUS_NONE  # don't steal gamepad nav from the grid cursor
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", d.color)
		var idx := i
		b.pressed.connect(func() -> void: defender_selected.emit(idx))
		add_child(b)
		_buttons.append(b)
		x += 240.0

	_banner = _make_label("", Vector2(540, 430), 100)
	_banner.add_theme_color_override("font_color", Color(1, 0.95, 0.3))
	_banner.visible = false
	add_child(_banner)

	highlight(0)

func _make_label(text: String, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	return l

func set_coins(n: int) -> void:
	_coin_label.text = "Coins: %d" % n

func set_kills(k: int, needed: int) -> void:
	if needed < 0:
		_kills_label.text = "Defeated: %d  (endless)" % k
	else:
		_kills_label.text = "Defeated: %d / %d" % [k, needed]

func highlight(index: int) -> void:
	for i in _buttons.size():
		_buttons[i].modulate = Color(1, 1, 1, 1) if i == index else Color(0.5, 0.5, 0.5, 1)

func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = true
