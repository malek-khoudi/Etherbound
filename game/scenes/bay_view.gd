class_name BayView
extends Node3D

signal member_hovered(member_id: StringName)
signal member_clicked(member_id: StringName)

const COLOR_SELECTED := Color(0.96, 0.64, 0.16)
const COLOR_HOVERED := Color(0.86, 0.70, 0.34)
const COLOR_DANGER := Color(0.82, 0.12, 0.08)
const COLOR_STABLE := Color(0.18, 0.68, 0.48)

var _camera: Camera3D
var _member_nodes: Dictionary = {}
var _member_materials: Dictionary = {}
var _base_colors: Dictionary = {}
var _initial_transforms: Dictionary = {}

var _hovered: StringName = &""
var _selected: StringName = &""
var _falling: bool = false
var _fall_time: float = 0.0

var _bracket_material: StandardMaterial3D
var _bracket_label: Label3D
var _brace_marker: Node3D
var _prop_marker: Node3D


func build(member_specs: Array, camera: Camera3D) -> void:
	_camera = camera
	_build_environment()
	_build_ground()
	for raw_spec: Variant in member_specs:
		var spec: Dictionary = raw_spec
		_build_member(spec)
	_build_bracket()
	_build_walkway_details()
	_build_people()
	_build_support_markers()


func set_selected(member_id: StringName) -> void:
	_selected = member_id
	_refresh_member_materials()


func set_overload(overloaded: bool, utilisation: float) -> void:
	if _bracket_material == null or _bracket_label == null:
		return
	var color: Color = COLOR_DANGER if overloaded else COLOR_STABLE
	_bracket_material.albedo_color = color.darkened(0.35)
	_bracket_material.emission = color
	_bracket_label.modulate = color.lightened(0.18)
	_bracket_label.text = tr("CORRODED BRACKET  %d%%") % int(round(utilisation * 100.0))


func set_brace_visible(visible_now: bool) -> void:
	if _brace_marker != null:
		_brace_marker.visible = visible_now


func set_prop_visible(visible_now: bool) -> void:
	if _prop_marker != null:
		_prop_marker.visible = visible_now


func start_collapse() -> void:
	if _falling:
		return
	_falling = true
	_fall_time = 0.0


func reset_view() -> void:
	_falling = false
	_fall_time = 0.0
	for id: Variant in _initial_transforms:
		var node: Node3D = _member_nodes.get(id)
		if node != null:
			node.transform = _initial_transforms[id]
	set_brace_visible(false)
	set_prop_visible(false)


func _process(delta: float) -> void:
	if not _falling:
		return
	_fall_time = minf(_fall_time + delta, 1.7)
	var progress: float = _fall_time / 1.7
	var fall_curve: float = progress * progress
	_animate_falling_member(&"walkway", fall_curve, -0.52)
	_animate_falling_member(&"crate", fall_curve, 0.34)


func _physics_process(_delta: float) -> void:
	if _camera == null or _falling:
		return
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	if hovered_control != null and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_set_hovered(&"")
		return
	_update_hover(get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and _hovered != &"":
			member_clicked.emit(_hovered)
			get_viewport().set_input_as_handled()


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.032, 0.036)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.39, 0.32)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "ColdKeyLight"
	key_light.light_color = Color(0.72, 0.82, 0.90)
	key_light.light_energy = 1.1
	key_light.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	key_light.shadow_enabled = true
	add_child(key_light)

	var amber_light := OmniLight3D.new()
	amber_light.name = "AmberWorkLight"
	amber_light.position = Vector3(3.3, 6.4, 2.8)
	amber_light.light_color = Color(1.0, 0.55, 0.18)
	amber_light.light_energy = 5.0
	amber_light.omni_range = 9.0
	amber_light.shadow_enabled = true
	add_child(amber_light)


func _build_ground() -> void:
	_add_box_decoration(
		"Ground",
		Vector3(2.5, -0.18, 0.0),
		Vector3(18.0, 0.35, 12.0),
		Color(0.075, 0.085, 0.088),
		0.05
	)
	for x: int in range(-6, 12, 2):
		_add_box_decoration(
			"FloorLineX%d" % x,
			Vector3(float(x), 0.012, 0.0),
			Vector3(0.025, 0.02, 10.0),
			Color(0.17, 0.16, 0.12),
			0.0
		)
	for z: int in range(-5, 6, 2):
		_add_box_decoration(
			"FloorLineZ%d" % z,
			Vector3(2.5, 0.014, float(z)),
			Vector3(16.0, 0.02, 0.025),
			Color(0.17, 0.16, 0.12),
			0.0
		)


func _build_member(spec: Dictionary) -> void:
	var id := StringName(str(spec["id"]))
	var root := Node3D.new()
	root.name = str(id).to_pascal_case()
	root.position = _array_to_vector3(spec["position"])
	add_child(root)

	var size: Vector3 = _array_to_vector3(spec["size"])
	var base_color: Color = _array_to_color(spec["color"])
	var material := _make_material(base_color, 0.48)

	var body := StaticBody3D.new()
	body.name = "SelectableBody"
	body.set_meta("member_id", id)
	root.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	_member_nodes[id] = root
	_member_materials[id] = material
	_base_colors[id] = base_color
	_initial_transforms[id] = root.transform


func _build_bracket() -> void:
	var bracket := MeshInstance3D.new()
	bracket.name = "CorrodedBracket"
	bracket.position = Vector3(2.92, 4.74, 0.0)
	bracket.rotation_degrees.z = -18.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.34, 0.92, 1.45)
	bracket.mesh = mesh
	_bracket_material = _make_material(COLOR_DANGER.darkened(0.35), 0.62)
	_bracket_material.emission_enabled = true
	_bracket_material.emission = COLOR_DANGER
	_bracket_material.emission_energy_multiplier = 1.65
	bracket.material_override = _bracket_material
	add_child(bracket)

	_bracket_label = Label3D.new()
	_bracket_label.name = "BracketStatus"
	_bracket_label.position = Vector3(3.0, 6.15, 0.0)
	_bracket_label.text = tr("CORRODED BRACKET")
	_bracket_label.font_size = 34
	_bracket_label.outline_size = 8
	_bracket_label.modulate = COLOR_DANGER.lightened(0.18)
	_bracket_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bracket_label.no_depth_test = true
	add_child(_bracket_label)


func _build_walkway_details() -> void:
	for x: float in [3.0, 4.0, 5.0, 6.0, 7.0]:
		for z: float in [-1.0, 1.0]:
			_add_box_decoration(
				"RailPost",
				Vector3(x, 5.12, z),
				Vector3(0.08, 1.0, 0.08),
				Color(0.18, 0.18, 0.16),
				0.35
			)
	for z: float in [-1.0, 1.0]:
		_add_box_decoration(
			"Rail",
			Vector3(5.0, 5.58, z),
			Vector3(4.5, 0.08, 0.08),
			Color(0.18, 0.18, 0.16),
			0.35
		)


func _build_people() -> void:
	_build_person("KessMarker", Vector3(-2.2, 1.05, 2.1), Color(0.70, 0.40, 0.12), tr("KESS\nKINETIC"))
	_build_person("MarenMarker", Vector3(-1.3, 1.05, -2.0), Color(0.18, 0.46, 0.43), tr("MAREN\nORDINARY WORKER"))


func _build_person(node_name: String, position_value: Vector3, color: Color, caption: String) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = position_value
	add_child(root)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.8
	body.mesh = capsule
	body.material_override = _make_material(color, 0.22)
	root.add_child(body)

	var label := Label3D.new()
	label.position = Vector3(0.0, 1.55, 0.0)
	label.text = caption
	label.font_size = 26
	label.outline_size = 7
	label.modulate = color.lightened(0.35)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	root.add_child(label)


func _build_support_markers() -> void:
	_brace_marker = Node3D.new()
	_brace_marker.name = "KineticBraceOverlay"
	add_child(_brace_marker)
	var brace_beam := MeshInstance3D.new()
	brace_beam.position = Vector3(4.25, 3.18, 1.20)
	brace_beam.rotation_degrees.z = -17.0
	var brace_mesh := BoxMesh.new()
	brace_mesh.size = Vector3(0.10, 3.1, 0.10)
	brace_beam.mesh = brace_mesh
	var brace_material := _make_material(Color(0.92, 0.56, 0.12), 0.0)
	brace_material.emission_enabled = true
	brace_material.emission = Color(0.92, 0.56, 0.12)
	brace_material.emission_energy_multiplier = 2.4
	brace_beam.material_override = brace_material
	_brace_marker.add_child(brace_beam)
	_brace_marker.visible = false

	_prop_marker = Node3D.new()
	_prop_marker.name = "WorkerProp"
	add_child(_prop_marker)
	var prop := MeshInstance3D.new()
	prop.position = Vector3(5.2, 2.28, 0.0)
	var prop_mesh := BoxMesh.new()
	prop_mesh.size = Vector3(0.24, 4.25, 0.24)
	prop.mesh = prop_mesh
	prop.material_override = _make_material(Color(0.18, 0.68, 0.48), 0.35)
	_prop_marker.add_child(prop)
	_prop_marker.visible = false


func _update_hover(mouse_position: Vector2) -> void:
	var origin: Vector3 = _camera.project_ray_origin(mouse_position)
	var direction: Vector3 = _camera.project_ray_normal(mouse_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var next_hovered: StringName = &""
	if not result.is_empty():
		var collider: Object = result["collider"]
		if collider.has_meta("member_id"):
			next_hovered = StringName(str(collider.get_meta("member_id")))
	_set_hovered(next_hovered)


func _set_hovered(member_id: StringName) -> void:
	if member_id == _hovered:
		return
	_hovered = member_id
	_refresh_member_materials()
	member_hovered.emit(_hovered)


func _refresh_member_materials() -> void:
	for raw_id: Variant in _member_materials:
		var id := StringName(str(raw_id))
		var material: StandardMaterial3D = _member_materials[id]
		var base_color: Color = _base_colors[id]
		if id == _selected:
			material.albedo_color = base_color.lerp(COLOR_SELECTED, 0.58)
			material.emission_enabled = true
			material.emission = COLOR_SELECTED
			material.emission_energy_multiplier = 0.52
		elif id == _hovered:
			material.albedo_color = base_color.lerp(COLOR_HOVERED, 0.42)
			material.emission_enabled = true
			material.emission = COLOR_HOVERED
			material.emission_energy_multiplier = 0.32
		else:
			material.albedo_color = base_color
			material.emission_enabled = false


func _animate_falling_member(id: StringName, progress: float, spin: float) -> void:
	var node: Node3D = _member_nodes.get(id)
	if node == null:
		return
	var initial: Transform3D = _initial_transforms[id]
	node.transform = initial
	node.position.y -= progress * 6.5
	node.rotation.z += progress * spin
	node.rotation.x += progress * spin * 0.35


func _add_box_decoration(
		node_name: String,
		position_value: Vector3,
		size: Vector3,
		color: Color,
		metallic: float
	) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = position_value
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = _make_material(color, metallic)
	add_child(instance)


func _make_material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.58
	return material


func _array_to_vector3(raw: Variant) -> Vector3:
	var values: Array = raw
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _array_to_color(raw: Variant) -> Color:
	var values: Array = raw
	return Color(float(values[0]), float(values[1]), float(values[2]))
