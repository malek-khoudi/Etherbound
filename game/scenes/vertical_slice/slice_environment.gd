class_name SliceEnvironment
extends Node3D

const ENVIRONMENT_PATH: String = "res://assets/models/environment/slice_environment.glb"
const COLOR_AMBER := Color("ef9d2d")
const COLOR_CYAN := Color("4fc5d1")
const COLOR_GREEN := Color("5dda82")
const COLOR_DANGER := Color("e34830")

var _environment_root: Node3D
var _effects: Dictionary = {}
var _marker_root: Node3D
var _consequence_light: OmniLight3D


func build() -> void:
	_build_world()
	_load_environment()
	_build_weather()
	_build_effects()
	_build_route_labels()


func show_interaction_markers(items: Array, visible_now: bool) -> void:
	if _marker_root != null:
		_marker_root.queue_free()
	_marker_root = Node3D.new()
	_marker_root.name = "InteractionMarkers"
	add_child(_marker_root)
	for raw_item: Variant in items:
		var item: Dictionary = raw_item
		var position_value: Vector3 = _array_to_vector3(item["position"])
		_add_marker(str(item["id"]), position_value + Vector3(0.0, 1.15, 0.0), str(item["title"]))
	_marker_root.visible = visible_now


func set_markers_visible(visible_now: bool) -> void:
	if _marker_root != null:
		_marker_root.visible = visible_now


func show_action_effect(role: StringName) -> void:
	var effect: Node3D = _effects.get(role)
	if effect != null:
		effect.visible = true
	match role:
		&"kinetic":
			_pulse_effect(effect, COLOR_AMBER)
		&"gravitic":
			_pulse_effect(effect, COLOR_CYAN)
		&"transmutative":
			_pulse_effect(effect, COLOR_GREEN)
		&"worker":
			_pulse_effect(effect, COLOR_AMBER.lightened(0.18))


func reset_incident_effects() -> void:
	for raw_effect: Variant in _effects.values():
		var effect := raw_effect as Node3D
		effect.visible = false
	var walkway: Node3D = _find_node_3d(_environment_root, "Gantry_Walkway")
	if walkway != null:
		walkway.rotation = Vector3.ZERO
		walkway.position.y = 0.0


func play_collapse() -> void:
	var walkway: Node3D = _find_node_3d(_environment_root, "Gantry_Walkway")
	if walkway != null:
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(walkway, "rotation:z", deg_to_rad(-24.0), 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(walkway, "position:y", -1.5, 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var dust: GPUParticles3D = _effects.get(&"dust")
	if dust != null:
		dust.emitting = true


func set_consequence(report_choice: StringName) -> void:
	if _consequence_light == null:
		return
	if report_choice == &"observations_only":
		_consequence_light.light_color = COLOR_GREEN
		_consequence_light.light_energy = 5.0
	else:
		_consequence_light.light_color = COLOR_DANGER
		_consequence_light.light_energy = 6.5


func _build_world() -> void:
	var world := WorldEnvironment.new()
	world.name = "SliceWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("050b0f")
	environment.background_energy_multiplier = 0.42
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6b8a9a")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.fog_enabled = true
	environment.fog_light_color = Color("263a43")
	environment.fog_light_energy = 0.38
	environment.fog_density = 0.012
	world.environment = environment
	add_child(world)

	var moon := DirectionalLight3D.new()
	moon.name = "CoolExteriorKey"
	moon.light_color = Color("86abc2")
	moon.light_energy = 1.35
	moon.rotation_degrees = Vector3(-56.0, -28.0, 0.0)
	moon.shadow_enabled = true
	add_child(moon)
	for x: float in [-14.0, -6.0, 3.0, 12.0]:
		var work_light := OmniLight3D.new()
		work_light.name = "AmberWorkLight_%s" % x
		work_light.position = Vector3(x, 4.1, 0.0)
		work_light.light_color = COLOR_AMBER
		work_light.light_energy = 7.5
		work_light.omni_range = 7.5
		work_light.shadow_enabled = x in [-6.0, 3.0]
		add_child(work_light)
	_consequence_light = OmniLight3D.new()
	_consequence_light.name = "ConsequenceLight"
	_consequence_light.position = Vector3(12.0, 2.8, 0.0)
	_consequence_light.light_color = COLOR_AMBER
	_consequence_light.light_energy = 2.0
	_consequence_light.omni_range = 6.0
	add_child(_consequence_light)


func _load_environment() -> void:
	var scene: PackedScene = load(ENVIRONMENT_PATH) as PackedScene
	if scene == null:
		push_error("Slice environment GLB is missing.")
		return
	_environment_root = scene.instantiate() as Node3D
	_environment_root.name = "BlenderSliceEnvironment"
	add_child(_environment_root)


func _build_weather() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 420
	rain.lifetime = 2.2
	rain.position = Vector3(-1.0, 7.5, 0.0)
	rain.visibility_aabb = AABB(Vector3(-22.0, -8.0, -5.0), Vector3(44.0, 18.0, 10.0))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(20.0, 0.5, 3.2)
	process.direction = Vector3(0.12, -1.0, 0.02)
	process.spread = 4.0
	process.initial_velocity_min = 10.0
	process.initial_velocity_max = 14.0
	process.gravity = Vector3(0.0, -6.0, 0.0)
	rain.process_material = process
	var streak := QuadMesh.new()
	streak.size = Vector2(0.018, 0.62)
	var streak_material := StandardMaterial3D.new()
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.albedo_color = Color(0.52, 0.72, 0.82, 0.34)
	streak.material = streak_material
	rain.draw_pass_1 = streak
	add_child(rain)

	for x: float in [-7.5, 8.8]:
		var steam := GPUParticles3D.new()
		steam.name = "Steam_%s" % x
		steam.amount = 55
		steam.lifetime = 3.2
		steam.position = Vector3(x, 0.5, 2.55)
		var steam_process := ParticleProcessMaterial.new()
		steam_process.direction = Vector3(0.0, 1.0, 0.0)
		steam_process.spread = 24.0
		steam_process.initial_velocity_min = 0.35
		steam_process.initial_velocity_max = 0.9
		steam_process.scale_min = 0.25
		steam_process.scale_max = 0.65
		steam.process_material = steam_process
		var puff := SphereMesh.new()
		puff.radius = 0.16
		puff.height = 0.28
		var puff_material := StandardMaterial3D.new()
		puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_material.albedo_color = Color(0.62, 0.72, 0.74, 0.16)
		puff.material = puff_material
		steam.draw_pass_1 = puff
		add_child(steam)


func _build_effects() -> void:
	var kinetic := Node3D.new()
	kinetic.name = "KineticLoadPath"
	add_child(kinetic)
	_add_effect_beam(kinetic, Vector3(1.3, 1.0, 0.95), Vector3(3.0, 3.75, 0.0), 0.055, COLOR_AMBER)
	_add_effect_beam(kinetic, Vector3(3.0, 3.75, 0.0), Vector3(3.0, 0.30, 2.05), 0.042, COLOR_AMBER)
	kinetic.visible = false
	_effects[&"kinetic"] = kinetic

	var gravitic := Node3D.new()
	gravitic.name = "GraviticField"
	gravitic.position = Vector3(5.25, 3.6, 0.0)
	add_child(gravitic)
	for radius: float in [0.75, 1.05, 1.35]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.025
		torus.outer_radius = radius + 0.025
		ring.mesh = torus
		ring.material_override = _emissive_material(COLOR_CYAN, 3.0)
		ring.rotation_degrees.x = 90.0
		gravitic.add_child(ring)
	gravitic.visible = false
	_effects[&"gravitic"] = gravitic

	var transmutative := Node3D.new()
	transmutative.name = "TransmutativeFront"
	add_child(transmutative)
	for index in 8:
		var patch := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.13, 0.24, 0.18)
		patch.mesh = box
		patch.position = Vector3(2.72 + float(index) * 0.075, 3.72 + sin(float(index)) * 0.08, -0.48 + float(index) * 0.13)
		patch.material_override = _emissive_material(COLOR_GREEN, 2.5)
		transmutative.add_child(patch)
	transmutative.visible = false
	_effects[&"transmutative"] = transmutative

	var worker := Node3D.new()
	worker.name = "PhysicalProp"
	add_child(worker)
	var prop := MeshInstance3D.new()
	var prop_mesh := BoxMesh.new()
	prop_mesh.size = Vector3(0.22, 3.05, 0.22)
	prop.mesh = prop_mesh
	prop.position = Vector3(4.2, 1.70, 0.72)
	prop.rotation_degrees.z = -8.0
	prop.material_override = _metal_material(Color("b47b28"))
	worker.add_child(prop)
	worker.visible = false
	_effects[&"worker"] = worker

	var dust := GPUParticles3D.new()
	dust.name = "CollapseDust"
	dust.amount = 180
	dust.one_shot = true
	dust.emitting = false
	dust.lifetime = 2.4
	dust.position = Vector3(4.6, 2.0, 0.0)
	var dust_process := ParticleProcessMaterial.new()
	dust_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust_process.emission_box_extents = Vector3(2.0, 0.25, 1.1)
	dust_process.direction = Vector3(0.0, 1.0, 0.0)
	dust_process.spread = 70.0
	dust_process.initial_velocity_min = 1.2
	dust_process.initial_velocity_max = 4.5
	dust_process.gravity = Vector3(0.0, -5.0, 0.0)
	dust.process_material = dust_process
	var grit := BoxMesh.new()
	grit.size = Vector3(0.08, 0.08, 0.08)
	grit.material = _metal_material(Color("74412b"))
	dust.draw_pass_1 = grit
	add_child(dust)
	_effects[&"dust"] = dust


func _build_route_labels() -> void:
	for spec in [
		["APPROACH", Vector3(-14.0, 3.65, -2.40)],
		["CONTROL / WORK AREA", Vector3(-6.0, 3.65, -2.40)],
		["GANTRY BAY", Vector3(3.0, 5.85, -2.15)],
		["EVIDENCE / CONSEQUENCE", Vector3(12.0, 3.65, -2.40)],
	]:
		var label := Label3D.new()
		label.text = tr(str(spec[0]))
		label.position = spec[1]
		label.font_size = 42
		label.outline_size = 10
		label.modulate = Color(0.85, 0.69, 0.38, 0.82)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _add_marker(id: String, position_value: Vector3, title: String) -> void:
	var root := Node3D.new()
	root.name = id.to_pascal_case()
	root.position = position_value
	_marker_root.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.10
	mesh.bottom_radius = 0.28
	mesh.height = 0.52
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _emissive_material(COLOR_AMBER, 3.2)
	root.add_child(mesh_instance)
	var label := Label3D.new()
	label.position.y = 0.58
	label.text = tr("[E] %s" % title)
	label.font_size = 25
	label.outline_size = 7
	label.modulate = Color("f5cf83")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)


func _add_effect_beam(parent: Node3D, start: Vector3, finish: Vector3, radius: float, color: Color) -> void:
	var direction: Vector3 = finish - start
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = direction.length()
	mesh_instance.mesh = cylinder
	mesh_instance.position = (start + finish) * 0.5
	mesh_instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
	mesh_instance.material_override = _emissive_material(color, 3.5)
	parent.add_child(mesh_instance)


func _pulse_effect(effect: Node3D, color: Color) -> void:
	if effect == null:
		return
	effect.scale = Vector3.ONE * 0.82
	var tween: Tween = create_tween()
	tween.tween_property(effect, "scale", Vector3.ONE * 1.12, 0.26).set_trans(Tween.TRANS_BACK)
	tween.tween_property(effect, "scale", Vector3.ONE, 0.22)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 8.0
	light.omni_range = 5.5
	light.position = effect.position + Vector3(0.0, 1.2, 0.0)
	effect.add_child(light)
	var light_tween: Tween = create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 1.0)
	light_tween.tween_callback(light.queue_free)


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _metal_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.72
	material.roughness = 0.42
	return material


func _array_to_vector3(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]) + 0.22, float(values[2]))


func _find_node_3d(node: Node, requested_name: String) -> Node3D:
	if node is Node3D and node.name == requested_name:
		return node as Node3D
	for child: Node in node.get_children():
		var result: Node3D = _find_node_3d(child, requested_name)
		if result != null:
			return result
	return null
