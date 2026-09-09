class_name SlicePartyController
extends Node3D

const ROLE_PATHS: Dictionary = {
	&"kinetic": "res://assets/models/characters/slice_kinetic.glb",
	&"gravitic": "res://assets/models/characters/slice_gravitic.glb",
	&"transmutative": "res://assets/models/characters/slice_transmutative.glb",
	&"worker": "res://assets/models/characters/slice_worker.glb",
}
const FOLLOW_OFFSETS: Dictionary = {
	&"gravitic": Vector3(-1.15, 0.0, 1.05),
	&"transmutative": Vector3(-1.15, 0.0, -1.05),
}
const SPEED: float = 4.2
const FOLLOW_SPEED: float = 5.6

var movement_enabled: bool = false
var _characters: Dictionary = {}
var _animation_players: Dictionary = {}
var _last_clip: Dictionary = {}
var _move_target: Vector3 = Vector3(-16.0, 0.22, 0.0)
var _has_target: bool = false
var _action_time: Dictionary = {}


func build() -> void:
	_spawn_role(&"kinetic", Vector3(-16.0, 0.22, 0.0), -90.0)
	_spawn_role(&"gravitic", Vector3(-17.15, 0.22, 1.05), -90.0)
	_spawn_role(&"transmutative", Vector3(-17.15, 0.22, -1.05), -90.0)
	_spawn_role(&"worker", Vector3(-10.6, 0.22, 1.10), 90.0)


func leader_position() -> Vector3:
	var leader: Node3D = _characters.get(&"kinetic")
	return leader.global_position if leader != null else Vector3.ZERO


func character(role: StringName) -> Node3D:
	return _characters.get(role)


func set_move_target(world_position: Vector3) -> void:
	_move_target = _clamp_to_route(world_position)
	_has_target = true


func teleport_party(position_value: Vector3) -> void:
	var leader: Node3D = _characters.get(&"kinetic")
	if leader == null:
		return
	leader.position = _clamp_to_route(position_value)
	for role: StringName in FOLLOW_OFFSETS:
		var follower: Node3D = _characters.get(role)
		if follower != null:
			follower.position = leader.position + FOLLOW_OFFSETS[role]
	_has_target = false


func stage_for_incident() -> void:
	movement_enabled = false
	_set_role_position(&"kinetic", Vector3(1.25, 0.22, 0.95), -70.0)
	_set_role_position(&"gravitic", Vector3(0.25, 0.22, 1.75), -55.0)
	_set_role_position(&"transmutative", Vector3(1.25, 0.22, -1.35), -105.0)
	_set_role_position(&"worker", Vector3(0.15, 0.22, -1.75), -110.0)


func stage_for_cast_review() -> void:
	movement_enabled = false
	_set_role_position(&"kinetic", Vector3(-8.0, 0.22, 2.0), 0.0)
	_set_role_position(&"gravitic", Vector3(-6.5, 0.22, 2.0), 0.0)
	_set_role_position(&"transmutative", Vector3(-5.0, 0.22, 2.0), 0.0)
	_set_role_position(&"worker", Vector3(-3.5, 0.22, 2.0), 0.0)


func stage_for_investigation() -> void:
	movement_enabled = true
	teleport_party(Vector3(8.6, 0.22, 0.0))
	_set_role_position(&"worker", Vector3(13.0, 0.22, 1.6), 120.0)


func play_role_action(role: StringName, clip: String) -> void:
	_play_clip(role, clip, true)
	_action_time[role] = 2.4


func all_roles_loaded() -> bool:
	return _characters.size() == ROLE_PATHS.size()


func animation_names(role: StringName) -> PackedStringArray:
	var player: AnimationPlayer = _animation_players.get(role)
	return player.get_animation_list() if player != null else PackedStringArray()


func _physics_process(delta: float) -> void:
	_tick_action_clips(delta)
	if not movement_enabled:
		return
	var leader: Node3D = _characters.get(&"kinetic")
	if leader == null:
		return
	var keyboard := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		0.0,
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var velocity := Vector3.ZERO
	if keyboard.length_squared() > 0.01:
		velocity = keyboard.normalized() * SPEED
		_has_target = false
	elif _has_target:
		var to_target: Vector3 = _move_target - leader.position
		to_target.y = 0.0
		if to_target.length() < 0.14:
			_has_target = false
		else:
			velocity = to_target.normalized() * SPEED
	if velocity.length_squared() > 0.01:
		leader.position = _clamp_to_route(leader.position + velocity * delta)
		_face_direction(leader, velocity)
		_play_clip(&"kinetic", "walk")
	else:
		_play_clip(&"kinetic", "idle")
	_update_followers(delta)


func _update_followers(delta: float) -> void:
	var leader: Node3D = _characters.get(&"kinetic")
	if leader == null:
		return
	for role: StringName in FOLLOW_OFFSETS:
		if _action_time.has(role):
			continue
		var follower: Node3D = _characters.get(role)
		if follower == null:
			continue
		var desired: Vector3 = _clamp_to_route(leader.position + FOLLOW_OFFSETS[role])
		var distance: float = follower.position.distance_to(desired)
		if distance > 0.08:
			var previous: Vector3 = follower.position
			follower.position = follower.position.move_toward(desired, FOLLOW_SPEED * delta)
			_face_direction(follower, follower.position - previous)
			_play_clip(role, "walk")
		else:
			_play_clip(role, "idle")


func _tick_action_clips(delta: float) -> void:
	var finished: Array[StringName] = []
	for raw_role: Variant in _action_time:
		var role := StringName(str(raw_role))
		_action_time[role] = float(_action_time[role]) - delta
		if float(_action_time[role]) <= 0.0:
			finished.append(role)
	for role: StringName in finished:
		_action_time.erase(role)
		_play_clip(role, "idle", true)


func _spawn_role(role: StringName, position_value: Vector3, facing_y: float) -> void:
	var scene: PackedScene = load(str(ROLE_PATHS[role])) as PackedScene
	if scene == null:
		push_error("Missing slice character: %s" % role)
		return
	var root: Node = scene.instantiate()
	root.name = role.capitalize()
	if root is Node3D:
		var root_3d := root as Node3D
		root_3d.position = position_value
		root_3d.rotation_degrees.y = facing_y
	add_child(root)
	_characters[role] = root
	_animation_players[role] = _find_animation_player(root)
	_play_clip(role, "idle", true)


func _set_role_position(role: StringName, position_value: Vector3, facing_y: float) -> void:
	var root: Node3D = _characters.get(role)
	if root == null:
		return
	root.position = position_value
	root.rotation_degrees.y = facing_y
	_play_clip(role, "idle", true)


func _play_clip(role: StringName, requested: String, force: bool = false) -> void:
	if not force and str(_last_clip.get(role, "")) == requested:
		return
	var player: AnimationPlayer = _animation_players.get(role)
	if player == null:
		return
	for animation_name: StringName in player.get_animation_list():
		var normalized: String = String(animation_name).to_lower()
		if normalized == requested or normalized.ends_with("/" + requested) or normalized.ends_with("|" + requested):
			var animation: Animation = player.get_animation(animation_name)
			if requested in ["idle", "walk"]:
				animation.loop_mode = Animation.LOOP_LINEAR
			player.play(animation_name, 0.16)
			_last_clip[role] = requested
			return


func _face_direction(root: Node3D, direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return
	root.rotation.y = lerp_angle(root.rotation.y, atan2(direction.x, direction.z), 0.28)


func _clamp_to_route(value: Vector3) -> Vector3:
	return Vector3(clampf(value.x, -17.0, 14.8), 0.22, clampf(value.z, -1.85, 1.85))


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child: Node in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result != null:
			return result
	return null
