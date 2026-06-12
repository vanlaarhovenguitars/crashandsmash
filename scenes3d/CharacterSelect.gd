extends Node3D
## The character-select screen, straight from Zane's design: "you can be a bat, a Mr. Beast
## toy, or a creature." Three animated heroes idle on podiums; pick one and play.
##   Touch / mouse: tap a hero to play as them.
##   Keyboard / gamepad: left-right to highlight, Enter / A to start.

const SceneDress := preload("res://scenes3d/SceneDress.gd")
const HeroRig := preload("res://entities3d/HeroRig.gd")

const PODIUM_X := [-3.4, 0.0, 3.4]

var _selected := 1
var _rigs: Array = []
var _ring: MeshInstance3D
var _t := 0.0

func _ready() -> void:
	SceneDress.apply_environment(self)
	SceneDress.add_clouds(self, 6, 30.0)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	ground.material_override = SceneDress.make_grass_material()
	add_child(ground)

	for i in HeroRig.KINDS.size():
		var kind: String = HeroRig.KINDS[i]
		var podium := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.15
		cm.bottom_radius = 1.35
		cm.height = 0.5
		podium.mesh = cm
		podium.position = Vector3(PODIUM_X[i], 0.25, 0)
		podium.material_override = SceneDress.make_mat(Color(0.88, 0.88, 0.95), 0.4)
		add_child(podium)

		var rig := HeroRig.new()
		rig.position = Vector3(PODIUM_X[i], 0.5, 0)
		add_child(rig)
		rig.build(kind)
		_rigs.append(rig)

		var label := Label3D.new()
		var stats: Dictionary = HeroRig.STATS[kind]
		label.text = stats.name
		label.font_size = 110
		label.position = Vector3(PODIUM_X[i], 2.9, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = stats.bullet_color
		label.outline_size = 24
		add_child(label)

	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.3
	tm.outer_radius = 1.5
	_ring.mesh = tm
	_ring.material_override = SceneDress.make_mat(Color(1.0, 0.9, 0.2), 0.4, 2.0)
	add_child(_ring)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.6, 7.5)
	add_child(cam)
	cam.look_at(Vector3(0, 1.5, 0), Vector3.UP)
	cam.current = true

	_build_ui()
	_update_ring()

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "CRASH AND SMASH"
	title.position = Vector2(380, 60)
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	title.add_theme_constant_override("outline_size", 22)
	ui.add_child(title)
	var sub := Label.new()
	sub.text = "Choose your hero!  (tap, or ← → + Enter / A)"
	sub.position = Vector2(560, 210)
	sub.add_theme_font_size_override("font_size", 42)
	ui.add_child(sub)

func _process(delta: float) -> void:
	_t += delta
	for i in _rigs.size():
		var rig: Node3D = _rigs[i]
		rig.rotation.y = PI + sin(_t * 0.8 + i) * 0.4
		rig.set_motion(delta, false, 0.0, false)
	_ring.rotation.y += delta * 1.5
	_update_ring()

func _update_ring() -> void:
	_ring.position = Vector3(PODIUM_X[_selected], 0.55, 0)

func _start() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		gs.selected_hero = HeroRig.KINDS[_selected]
	get_tree().change_scene_to_file("res://scenes3d/Arena.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_selected = (_selected - 1 + 3) % 3
		_update_ring()
	elif event.is_action_pressed("ui_right"):
		_selected = (_selected + 1) % 3
		_update_ring()
	elif event.is_action_pressed("ui_accept"):
		_start()
	elif (event is InputEventScreenTouch and event.pressed) or \
			(event is InputEventMouseButton and event.pressed):
		var w := get_viewport().get_visible_rect().size.x
		_selected = clampi(int(event.position.x / (w / 3.0)), 0, 2)
		_update_ring()
		_start()
