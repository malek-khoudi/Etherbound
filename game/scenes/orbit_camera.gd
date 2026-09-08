class_name OrbitCameraRig
extends Node3D

const MIN_DISTANCE: float = 7.0
const MAX_DISTANCE: float = 22.0
const MIN_PITCH: float = -1.15
const MAX_PITCH: float = -0.12
const ORBIT_SPEED: float = 0.008
const ZOOM_STEP: float = 1.25

var target: Vector3 = Vector3(2.8, 2.8, 0.0)
var distance: float = 13.5
var yaw: float = -0.85
var pitch: float = -0.42

var _camera: Camera3D
var _orbiting: bool = false


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.name = "IncidentCamera"
	_camera.fov = 48.0
	_camera.near = 0.1
	_camera.far = 100.0
	add_child(_camera)
	_update_camera()


func camera() -> Camera3D:
	return _camera


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event
		if button_event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = button_event.pressed
			get_viewport().set_input_as_handled()
		elif button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(distance - ZOOM_STEP, MIN_DISTANCE)
			_update_camera()
			get_viewport().set_input_as_handled()
		elif button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(distance + ZOOM_STEP, MAX_DISTANCE)
			_update_camera()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _orbiting:
		var motion: InputEventMouseMotion = event
		yaw -= motion.relative.x * ORBIT_SPEED
		pitch = clampf(pitch - motion.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_camera()
		get_viewport().set_input_as_handled()


func _update_camera() -> void:
	if _camera == null:
		return
	var horizontal: float = cos(pitch) * distance
	var offset := Vector3(
		sin(yaw) * horizontal,
		-sin(pitch) * distance,
		cos(yaw) * horizontal
	)
	_camera.position = target + offset
	_camera.look_at(target, Vector3.UP)
