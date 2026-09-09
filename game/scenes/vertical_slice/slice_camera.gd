class_name SliceCameraRig
extends Node3D

const MIN_DISTANCE: float = 7.0
const MAX_DISTANCE: float = 20.0
const MIN_PITCH: float = -1.08
const MAX_PITCH: float = -0.18

var target: Vector3 = Vector3(-15.0, 1.2, 0.0)
var distance: float = 12.5
var yaw: float = -1.05
var pitch: float = -0.46
var follow_target: Node3D
var player_controlled: bool = false

var _camera: Camera3D
var _orbiting: bool = false
var _frame_tween: Tween


func build() -> void:
	_camera = Camera3D.new()
	_camera.name = "SliceCamera"
	_camera.fov = 46.0
	_camera.near = 0.08
	_camera.far = 120.0
	add_child(_camera)
	_update_camera()


func camera() -> Camera3D:
	return _camera


func set_follow(node: Node3D, enabled: bool) -> void:
	follow_target = node
	player_controlled = enabled


func frame(target_value: Vector3, distance_value: float, yaw_value: float, pitch_value: float, duration: float = 0.8) -> void:
	player_controlled = false
	if _frame_tween != null and _frame_tween.is_valid():
		_frame_tween.kill()
	_frame_tween = create_tween().set_parallel(true)
	_frame_tween.tween_property(self, "target", target_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_frame_tween.tween_property(self, "distance", distance_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_frame_tween.tween_method(_set_yaw, yaw, yaw_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_frame_tween.tween_property(self, "pitch", pitch_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func restore_exploration_control() -> void:
	player_controlled = true
	distance = clampf(distance, 9.0, 15.0)


func _process(delta: float) -> void:
	if player_controlled and follow_target != null:
		target = target.lerp(follow_target.global_position + Vector3(0.0, 1.15, 0.0), 1.0 - exp(-6.5 * delta))
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not player_controlled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse_event.pressed
			get_viewport().set_input_as_handled()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(distance - 1.1, MIN_DISTANCE)
			get_viewport().set_input_as_handled()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(distance + 1.1, MAX_DISTANCE)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _orbiting:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * 0.0075
		pitch = clampf(pitch - motion.relative.y * 0.0075, MIN_PITCH, MAX_PITCH)
		get_viewport().set_input_as_handled()


func _set_yaw(value: float) -> void:
	yaw = value


func _update_camera() -> void:
	if _camera == null:
		return
	var horizontal: float = cos(pitch) * distance
	var offset := Vector3(sin(yaw) * horizontal, -sin(pitch) * distance, cos(yaw) * horizontal)
	_camera.global_position = target + offset
	_camera.look_at(target, Vector3.UP)
