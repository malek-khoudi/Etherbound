class_name VerticalSliceHud
extends CanvasLayer

signal dialogue_advanced
signal inspection_closed
signal incident_action_requested(role: StringName)
signal incident_round_requested
signal incident_restart_requested
signal report_requested(choice: StringName)
signal slice_restart_requested

const INK := Color(0.025, 0.033, 0.035, 0.96)
const PANEL := Color(0.055, 0.068, 0.070, 0.95)
const BORDER := Color(0.48, 0.34, 0.15, 0.95)
const AMBER := Color("efa536")
const CYAN := Color("55cbd5")
const GREEN := Color("66d985")
const DANGER := Color("ef5439")
const TEXT := Color("eee8d7")
const MUTED := Color("9ba7a4")

var _phase_label: Label
var _objective_label: Label
var _prompt_label: Label
var _performance_label: Label
var _toast_label: Label
var _dialogue_panel: PanelContainer
var _dialogue_speaker: Label
var _dialogue_line: Label
var _inspection_panel: PanelContainer
var _inspection_title: Label
var _observation_text: Label
var _inference_text: Label
var _incident_panel: PanelContainer
var _incident_status: RichTextLabel
var _action_buttons: Dictionary = {}
var _round_button: Button
var _restart_incident_button: Button
var _report_panel: PanelContainer
var _evidence_status: Label
var _report_buttons: Dictionary = {}
var _consequence_panel: PanelContainer
var _consequence_text: RichTextLabel
var _help_label: Label


func build(title: String, notice: String) -> void:
	var root := Control.new()
	root.name = "VerticalSliceHudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_header(root, title, notice)
	_build_objective(root)
	_build_prompt(root)
	_build_dialogue(root)
	_build_inspection(root)
	_build_incident(root)
	_build_report(root)
	_build_consequence(root)
	_build_help(root)


func set_phase(phase_name: String, objective: String) -> void:
	_phase_label.text = tr(phase_name.to_upper())
	_objective_label.text = tr(objective)


func set_prompt(text_value: String, visible_now: bool = true) -> void:
	_prompt_label.text = tr(text_value)
	_prompt_label.visible = visible_now and not text_value.is_empty()


func show_dialogue(speaker: String, line: String, final_line: bool = false) -> void:
	_dialogue_panel.visible = true
	_dialogue_speaker.text = tr(speaker)
	_dialogue_line.text = tr(line)
	var button: Button = _dialogue_panel.get_node("Margin/Column/Advance") as Button
	button.text = tr("BEGIN INSPECTION") if final_line else tr("CONTINUE")


func hide_dialogue() -> void:
	_dialogue_panel.visible = false


func show_inspection(title: String, observation: String, inference: String) -> void:
	_inspection_panel.visible = true
	_inspection_title.text = tr(title)
	_observation_text.text = tr(observation)
	_inference_text.text = tr(inference)


func hide_inspection() -> void:
	_inspection_panel.visible = false


func show_incident(visible_now: bool) -> void:
	_incident_panel.visible = visible_now


func set_incident_status(round_number: int, action_state: Dictionary, reason: String, failed: bool = false) -> void:
	var lines: Array[String] = []
	for role: StringName in SliceState.REQUIRED_ACTIONS:
		var complete: bool = action_state.has(role)
		lines.append("[color=#%s]%s[/color]  %s" % [
			GREEN.to_html(false) if complete else MUTED.to_html(false),
			"◆" if complete else "◇",
			role.capitalize(),
		])
	_incident_status.text = "[font_size=20][color=#%s]ROUND %d[/color][/font_size]\n%s\n\n[color=#%s]%s[/color]" % [
		AMBER.to_html(false),
		round_number,
		"\n".join(lines),
		DANGER.to_html(false) if failed else TEXT.to_html(false),
		tr(reason),
	]
	for role: StringName in _action_buttons:
		var button: Button = _action_buttons[role]
		button.disabled = action_state.has(role) or failed
	_round_button.disabled = failed
	_restart_incident_button.visible = failed


func show_report(visible_now: bool, evidence_count: int = 0) -> void:
	_report_panel.visible = visible_now
	_evidence_status.text = tr("EVIDENCE RECORDED: %d / 3") % evidence_count
	for raw_button: Variant in _report_buttons.values():
		var button := raw_button as Button
		button.disabled = evidence_count < 3


func update_evidence_count(count: int) -> void:
	_evidence_status.text = tr("EVIDENCE RECORDED: %d / 3") % count
	for raw_button: Variant in _report_buttons.values():
		var button := raw_button as Button
		button.disabled = count < 3


func show_consequence(heading: String, worker_line: String, detail: String, report_choice: StringName) -> void:
	_consequence_panel.visible = true
	var color: Color = GREEN if report_choice == &"observations_only" else DANGER
	_consequence_text.text = "[center][font_size=28][color=#%s]%s[/color][/font_size]\n\n[i]%s[/i]\n\n%s\n\n[color=#%s]JUNCTION 9 COMPLETE — F5 save  •  F9 load  •  F12 capture[/color][/center]" % [
		color.to_html(false), tr(heading), tr(worker_line), tr(detail), AMBER.to_html(false)
	]


func set_performance(fps: float, objects: int, phase_time: float) -> void:
	_performance_label.text = tr("%d FPS  •  %d OBJECTS  •  %.1f MIN") % [int(round(fps)), objects, phase_time / 60.0]


func toast(text_value: String, danger: bool = false) -> void:
	_toast_label.text = tr(text_value)
	_toast_label.modulate = DANGER if danger else AMBER
	_toast_label.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(2.8)
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		_toast_label.visible = false
		_toast_label.modulate.a = 1.0
	)


func _build_header(root: Control, title: String, notice: String) -> void:
	var panel := _panel(root, Vector2(20.0, 18.0), Vector2(1400.0, 84.0), PANEL)
	var margin := _margin(18.0)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size.x = 780.0
	row.add_child(title_box)
	var notice_label := _label(notice, 12, DANGER)
	title_box.add_child(notice_label)
	title_box.add_child(_label(title, 24, TEXT))
	_phase_label = _label("ARRIVAL", 16, AMBER)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_label.custom_minimum_size.x = 210.0
	_phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_phase_label)
	_performance_label = _label("", 13, MUTED)
	_performance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_performance_label.custom_minimum_size.x = 330.0
	_performance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_performance_label)


func _build_objective(root: Control) -> void:
	var panel := _panel(root, Vector2(20.0, 120.0), Vector2(380.0, 112.0), INK)
	var margin := _margin(16.0)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	column.add_child(_label(tr("CURRENT OBJECTIVE"), 14, AMBER))
	_objective_label = _label("", 16, TEXT)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_objective_label)


func _build_prompt(root: Control) -> void:
	_prompt_label = _label("", 17, TEXT)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_left = 360.0
	_prompt_label.offset_right = -360.0
	_prompt_label.offset_top = -108.0
	_prompt_label.offset_bottom = -70.0
	_prompt_label.add_theme_stylebox_override("normal", _style(INK, BORDER, 8))
	root.add_child(_prompt_label)
	_toast_label = _label("", 15, AMBER)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_label.offset_left = 420.0
	_toast_label.offset_right = -420.0
	_toast_label.offset_top = 112.0
	_toast_label.offset_bottom = 148.0
	_toast_label.add_theme_stylebox_override("normal", _style(INK, BORDER, 7))
	_toast_label.visible = false
	root.add_child(_toast_label)


func _build_dialogue(root: Control) -> void:
	_dialogue_panel = _panel(root, Vector2(190.0, 545.0), Vector2(1060.0, 220.0), PANEL)
	var margin := _margin(24.0)
	margin.name = "Margin"
	_dialogue_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_dialogue_speaker = _label("", 17, AMBER)
	column.add_child(_dialogue_speaker)
	_dialogue_line = _label("", 21, TEXT)
	_dialogue_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_line.custom_minimum_size.y = 90.0
	column.add_child(_dialogue_line)
	var advance := _button("CONTINUE", AMBER, 210.0)
	advance.name = "Advance"
	advance.pressed.connect(func() -> void: dialogue_advanced.emit())
	column.add_child(advance)
	_dialogue_panel.visible = false


func _build_inspection(root: Control) -> void:
	_inspection_panel = _panel(root, Vector2(760.0, 150.0), Vector2(620.0, 410.0), PANEL)
	var margin := _margin(24.0)
	_inspection_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_inspection_title = _label("", 23, AMBER)
	column.add_child(_inspection_title)
	column.add_child(_label(tr("OBSERVATION"), 14, GREEN))
	_observation_text = _label("", 17, TEXT)
	_observation_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_observation_text.custom_minimum_size.y = 82.0
	column.add_child(_observation_text)
	column.add_child(_label(tr("INFERENCE — NOT THE SAME THING"), 14, CYAN))
	_inference_text = _label("", 17, TEXT)
	_inference_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inference_text.custom_minimum_size.y = 92.0
	column.add_child(_inference_text)
	var close := _button("RECORD AND CLOSE", AMBER, 240.0)
	close.pressed.connect(func() -> void: inspection_closed.emit())
	column.add_child(close)
	_inspection_panel.visible = false


func _build_incident(root: Control) -> void:
	_incident_panel = _panel(root, Vector2(18.0, 548.0), Vector2(1404.0, 225.0), PANEL)
	var margin := _margin(16.0)
	_incident_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	_incident_status = RichTextLabel.new()
	_incident_status.bbcode_enabled = true
	_incident_status.custom_minimum_size = Vector2(310.0, 188.0)
	_incident_status.add_theme_font_size_override("normal_font_size", 15)
	row.add_child(_incident_status)
	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 10)
	row.add_child(actions)
	for spec in [
		[&"kinetic", "KINETIC — TAKE THE LOAD", AMBER],
		[&"gravitic", "GRAVITIC — REDUCE ACCELERATION", CYAN],
		[&"transmutative", "TRANSMUTATIVE — REPAIR FRONT", GREEN],
		[&"worker", "WORKER — PLACE PHYSICAL PROP", Color("d6b060")],
	]:
		var role := spec[0] as StringName
		var action := _button(str(spec[1]), spec[2], 335.0)
		action.pressed.connect(func() -> void: incident_action_requested.emit(role))
		actions.add_child(action)
		_action_buttons[role] = action
	var end_box := VBoxContainer.new()
	end_box.add_theme_constant_override("separation", 12)
	row.add_child(end_box)
	_round_button = _button("END ROUND / SECURE", DANGER, 280.0)
	_round_button.pressed.connect(func() -> void: incident_round_requested.emit())
	end_box.add_child(_round_button)
	_restart_incident_button = _button("RESTART INCIDENT", MUTED, 280.0)
	_restart_incident_button.pressed.connect(func() -> void: incident_restart_requested.emit())
	_restart_incident_button.visible = false
	end_box.add_child(_restart_incident_button)
	end_box.add_child(_label(tr("Every action has a visible physical role.\nA missing support can still collapse the gantry."), 13, MUTED))
	_incident_panel.visible = false


func _build_report(root: Control) -> void:
	_report_panel = _panel(root, Vector2(410.0, 180.0), Vector2(620.0, 440.0), PANEL)
	var margin := _margin(24.0)
	_report_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(_label(tr("FIELD REPORT — PROTOTYPE RECIPIENT"), 23, AMBER))
	_evidence_status = _label("", 17, TEXT)
	column.add_child(_evidence_status)
	column.add_child(_label(tr("The reporting choice tests whether your explanation exceeds the evidence. No institution or canon recipient is asserted."), 15, MUTED))
	var observation_button := _button("REPORT OBSERVATIONS; MARK CAUSE UNRESOLVED", GREEN, 565.0)
	observation_button.pressed.connect(func() -> void: report_requested.emit(&"observations_only"))
	column.add_child(observation_button)
	_report_buttons[&"observations_only"] = observation_button
	var claim_button := _button("STATE AN UNVERIFIED CAUSE AS FACT", DANGER, 565.0)
	claim_button.pressed.connect(func() -> void: report_requested.emit(&"claim_cause"))
	column.add_child(claim_button)
	_report_buttons[&"claim_cause"] = claim_button
	_report_panel.visible = false


func _build_consequence(root: Control) -> void:
	_consequence_panel = _panel(root, Vector2(340.0, 210.0), Vector2(760.0, 390.0), PANEL)
	var margin := _margin(28.0)
	_consequence_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	_consequence_text = RichTextLabel.new()
	_consequence_text.bbcode_enabled = true
	_consequence_text.fit_content = false
	_consequence_text.custom_minimum_size = Vector2(700.0, 270.0)
	_consequence_text.add_theme_font_size_override("normal_font_size", 18)
	_consequence_text.add_theme_color_override("default_color", TEXT)
	column.add_child(_consequence_text)
	var restart := _button("PLAY THE SLICE AGAIN", AMBER, 300.0)
	restart.pressed.connect(func() -> void: slice_restart_requested.emit())
	column.add_child(restart)
	_consequence_panel.visible = false


func _build_help(root: Control) -> void:
	_help_label = _label(tr("WASD move  •  Left-click ground move  •  Right-drag orbit  •  Wheel zoom  •  E interact  •  F5 save  •  F9 load  •  F12 capture"), 13, MUTED)
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_help_label.offset_left = 180.0
	_help_label.offset_right = -180.0
	_help_label.offset_top = -36.0
	_help_label.offset_bottom = -12.0
	root.add_child(_help_label)


func _panel(parent: Control, position_value: Vector2, size_value: Vector2, fill: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style(fill, BORDER, 10))
	parent.add_child(panel)
	return panel


func _margin(amount: float) -> MarginContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, int(amount))
	return margin


func _label(text_value: String, size_value: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(text_value)
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text_value: String, accent: Color, width: float) -> Button:
	var button := Button.new()
	button.text = tr(text_value)
	button.custom_minimum_size = Vector2(width, 50.0)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _style(INK, accent.darkened(0.35), 7))
	button.add_theme_stylebox_override("hover", _style(INK.lightened(0.08), accent, 7))
	button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.52), accent, 7))
	button.add_theme_stylebox_override("disabled", _style(INK.darkened(0.25), MUTED.darkened(0.55), 7))
	return button


func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
