class_name PipelineShowcase
extends Node3D

const ENVIRONMENT_PATH: String = "res://assets/models/environment/pipeline_environment.glb"
const CHARACTER_PATH: String = "res://assets/models/characters/pipeline_character.glb"
const CLIP_KEYS: Array[String] = ["idle", "walk", "inspect", "brace"]
const AUTO_CYCLE_SECONDS: float = 4.0

var _animation_player: AnimationPlayer
var _clip_label: Label
var _status_label: Label
var _current_clip: String = ""
var _clip_elapsed: float = 0.0
var _clip_index: int = 0


func _ready() -> void:
	_build_lighting()
	_load_pipeline_assets()
	_build_camera()
	_build_overlay()
	_play_clip("idle")


func _process(delta: float) -> void:
	_clip_elapsed += delta
	if _clip_elapsed < AUTO_CYCLE_SECONDS:
		return
	_clip_index = (_clip_index + 1) % CLIP_KEYS.size()
	_play_clip(CLIP_KEYS[_clip_index])


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_play_clip("idle")
		KEY_2:
			_play_clip("walk")
		KEY_3:
			_play_clip("inspect")
		KEY_4:
			_play_clip("brace")
		KEY_M:
			get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "PipelineWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("081016")
	environment.background_energy_multiplier = 0.55
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8aa6b8")
	environment.ambient_light_energy = 0.52
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color("ffd0a1")
	key_light.light_energy = 1.25
	key_light.shadow_enabled = true
	key_light.rotation_degrees = Vector3(-54.0, -32.0, 0.0)
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "IndustrialFill"
	fill_light.light_color = Color("3d8ca3")
	fill_light.light_energy = 7.0
	fill_light.omni_range = 12.0
	fill_light.position = Vector3(-3.0, 4.2, 2.5)
	add_child(fill_light)

	var warning_light := OmniLight3D.new()
	warning_light.name = "WarningLight"
	warning_light.light_color = Color("ff5c19")
	warning_light.light_energy = 5.5
	warning_light.omni_range = 6.0
	warning_light.position = Vector3(2.8, 1.5, 1.9)
	add_child(warning_light)


func _load_pipeline_assets() -> void:
	var environment_scene: PackedScene = load(ENVIRONMENT_PATH) as PackedScene
	var character_scene: PackedScene = load(CHARACTER_PATH) as PackedScene
	if environment_scene == null or character_scene == null:
		push_error("Pipeline proof assets could not be loaded.")
		return

	var environment_instance: Node = environment_scene.instantiate()
	environment_instance.name = "BlenderEnvironment"
	add_child(environment_instance)

	var character_instance: Node = character_scene.instantiate()
	character_instance.name = "BlenderCharacter"
	if character_instance is Node3D:
		var character_3d: Node3D = character_instance
		character_3d.position = Vector3(2.7, 0.35, 1.55)
		character_3d.rotation_degrees.y = -28.0
	add_child(character_instance)
	_animation_player = _find_animation_player(character_instance)


func _build_camera() -> void:
	var camera_rig := OrbitCameraRig.new()
	camera_rig.name = "OrbitCameraRig"
	camera_rig.target = Vector3(0.0, 2.0, 0.0)
	camera_rig.distance = 14.5
	camera_rig.yaw = -0.82
	camera_rig.pitch = -0.40
	add_child(camera_rig)


func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "PipelineOverlay"
	add_child(canvas)

	var top_bar := ColorRect.new()
	top_bar.color = Color(0.025, 0.035, 0.040, 0.94)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 118.0
	canvas.add_child(top_bar)

	var title := Label.new()
	title.text = tr("BLENDER → GODOT PIPELINE PROOF")
	title.position = Vector2(28.0, 16.0)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("efad42"))
	top_bar.add_child(title)

	_status_label = Label.new()
	_status_label.text = tr("Editable .blend sources • GLB runtime imports • 18-bone rig • 4 authored clips • auto-cycling")
	_status_label.position = Vector2(30.0, 50.0)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color("c8d2d2"))
	top_bar.add_child(_status_label)

	_clip_label = Label.new()
	_clip_label.position = Vector2(30.0, 78.0)
	_clip_label.add_theme_font_size_override("font_size", 15)
	_clip_label.add_theme_color_override("font_color", Color("78d8d6"))
	top_bar.add_child(_clip_label)

	var controls := Label.new()
	controls.text = tr("1 Idle   2 Walk   3 Inspect   4 Brace    •    Right-drag orbit   Wheel zoom    •    M mechanics prototype")
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 20.0
	controls.offset_right = -28.0
	controls.offset_top = -54.0
	controls.offset_bottom = -20.0
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("d5dbd8"))
	canvas.add_child(controls)

	var notice := Label.new()
	notice.text = tr("NON-CANON PIPELINE ASSET — visual identity awaits author decisions")
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	notice.offset_left = -610.0
	notice.offset_right = -28.0
	notice.offset_top = 22.0
	notice.offset_bottom = 48.0
	notice.add_theme_font_size_override("font_size", 13)
	notice.add_theme_color_override("font_color", Color("c87954"))
	canvas.add_child(notice)


func _play_clip(requested: String) -> void:
	if _animation_player == null:
		return
	var resolved: StringName = _resolve_clip(requested)
	if resolved.is_empty():
		push_warning("Animation clip not found: %s" % requested)
		return
	var animation: Animation = _animation_player.get_animation(resolved)
	animation.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(resolved)
	_current_clip = requested
	_clip_index = CLIP_KEYS.find(requested)
	_clip_elapsed = 0.0
	if _clip_label != null:
		_clip_label.text = tr("PLAYING: %s") % requested.to_upper()


func _resolve_clip(requested: String) -> StringName:
	if _animation_player == null:
		return &""
	for animation_name: StringName in _animation_player.get_animation_list():
		var normalized: String = String(animation_name).to_lower()
		if normalized == requested or normalized.ends_with("/" + requested) or normalized.ends_with("|" + requested):
			return animation_name
	return &""


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child: Node in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result != null:
			return result
	return null
