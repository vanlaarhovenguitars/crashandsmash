extends RefCounted
## Shared visual dressing for 3D scenes: upgraded environment (ACES tonemap, glow/bloom,
## depth fog, procedural sky), puffy clouds, and material helpers. Used by both the
## character-select screen and the arena so they look consistent.

static func make_mat(c: Color, rough := 0.55, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	else:
		m.rim_enabled = true
		m.rim = 0.3
	return m

static func apply_environment(parent: Node) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.25, 0.48, 0.92)
	psm.sky_horizon_color = Color(0.78, 0.87, 0.96)
	psm.ground_horizon_color = Color(0.78, 0.87, 0.96)
	psm.ground_bottom_color = Color(0.4, 0.5, 0.45)
	psm.sun_angle_max = 30.0
	sky.sky_material = psm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	# NOTE: the web build runs the LDR Compatibility renderer, where a glow threshold
	# at or below 1.0 blooms the whole frame into a white haze. Keep it above 1.0 so
	# only genuinely overbright emissives (muzzle flashes, bullets) would bloom.
	e.glow_enabled = true
	e.glow_intensity = 0.4
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = 1.2
	e.fog_enabled = true
	e.fog_light_color = Color(0.76, 0.86, 0.96)
	e.fog_density = 0.0012
	e.fog_sky_affect = 0.0
	env.environment = e
	parent.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-42), 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	parent.add_child(sun)

	# A soft fill light from the opposite side so shadows aren't pitch black.
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-30), deg_to_rad(140), 0)
	fill.light_energy = 0.25
	fill.light_color = Color(0.7, 0.8, 1.0)
	parent.add_child(fill)

static func add_clouds(parent: Node, count := 8, spread := 50.0) -> void:
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(1, 1, 1)
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in count:
		var cluster := Node3D.new()
		cluster.position = Vector3(randf_range(-spread, spread), randf_range(20.0, 30.0), randf_range(-spread, spread))
		parent.add_child(cluster)
		for j in 3:
			var puff := MeshInstance3D.new()
			var sm := SphereMesh.new()
			var r := randf_range(1.8, 3.4)
			sm.radius = r
			sm.height = r * 2.0
			puff.mesh = sm
			puff.material_override = cmat
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puff.position = Vector3(j * randf_range(1.5, 2.6) - 2.0, randf_range(-0.3, 0.3), randf_range(-0.8, 0.8))
			puff.scale = Vector3(1.0, 0.45, 1.0)
			cluster.add_child(puff)

## A big grassy ground plane with a soft noise texture (looks like real turf from above).
static func make_grass_material() -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var ntex := NoiseTexture2D.new()
	ntex.noise = noise
	ntex.seamless = true
	ntex.width = 256
	ntex.height = 256
	var grad := Gradient.new()
	grad.set_color(0, Color(0.16, 0.38, 0.18))
	grad.set_color(1, Color(0.3, 0.55, 0.26))
	ntex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = ntex
	m.uv1_scale = Vector3(8, 8, 8)
	m.roughness = 0.95
	return m
