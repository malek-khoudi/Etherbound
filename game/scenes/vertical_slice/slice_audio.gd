class_name SliceAudio
extends Node

const SAMPLE_RATE: int = 22050

var _ambient: AudioStreamPlayer
var _ui: AudioStreamPlayer
var _impact: AudioStreamPlayer
var _ether: AudioStreamPlayer


func build() -> void:
	_ambient = _player("AmbientBed")
	_ui = _player("InterfaceSound")
	_impact = _player("StructuralSound")
	_ether = _player("EtherboundSound")
	_ambient.stream = _make_wave(4.0, Callable(self, "_ambient_sample"), true)
	_ui.stream = _make_wave(0.12, Callable(self, "_ui_sample"))
	_impact.stream = _make_wave(1.35, Callable(self, "_impact_sample"))
	_ether.stream = _make_wave(0.75, Callable(self, "_ether_sample"))
	_ambient.volume_db = -19.0
	_ui.volume_db = -10.0
	_impact.volume_db = -4.0
	_ether.volume_db = -9.0
	_ambient.play()


func play_ui() -> void:
	_ui.play()


func play_impact() -> void:
	_impact.play()


func play_ether() -> void:
	_ether.play()


func _player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	add_child(player)
	return player


func _make_wave(seconds: float, sample_function: Callable, looped: bool = false) -> AudioStreamWAV:
	var sample_count: int = int(seconds * float(SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time: float = float(index) / float(SAMPLE_RATE)
		var value: float = clampf(float(sample_function.call(time, seconds)), -1.0, 1.0)
		var encoded: int = int(value * 32767.0)
		bytes[index * 2] = encoded & 0xff
		bytes[index * 2 + 1] = (encoded >> 8) & 0xff
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = SAMPLE_RATE
	wave.stereo = false
	wave.data = bytes
	if looped:
		wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wave.loop_begin = 0
		wave.loop_end = sample_count
	return wave


func _ambient_sample(time: float, _length: float) -> float:
	var wind: float = sin(time * 0.73) * 0.08 + sin(time * 1.91) * 0.045
	var machinery: float = sin(TAU * 47.0 * time) * 0.025 + sin(TAU * 94.0 * time) * 0.012
	var rain_texture: float = sin(time * 233.0) * sin(time * 71.0) * 0.024
	return wind + machinery + rain_texture


func _ui_sample(time: float, length: float) -> float:
	var envelope: float = maxf(1.0 - time / length, 0.0)
	return sin(TAU * (520.0 + time * 860.0) * time) * envelope * 0.35


func _impact_sample(time: float, length: float) -> float:
	var envelope: float = pow(maxf(1.0 - time / length, 0.0), 1.8)
	return (sin(TAU * 42.0 * time) * 0.55 + sin(TAU * 73.0 * time) * 0.24) * envelope


func _ether_sample(time: float, length: float) -> float:
	var envelope: float = sin(PI * clampf(time / length, 0.0, 1.0))
	return (sin(TAU * (180.0 + time * 360.0) * time) * 0.25 + sin(TAU * 420.0 * time) * 0.09) * envelope
