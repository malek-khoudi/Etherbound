class_name IncidentHud
extends CanvasLayer

signal unit_selected(unit_id: StringName)
signal brace_requested
signal prop_requested
signal end_turn_requested
signal restart_requested

const COLOR_INK := Color(0.055, 0.065, 0.068, 0.96)
const COLOR_PANEL := Color(0.075, 0.085, 0.088, 0.94)
const COLOR_BORDER := Color(0.52, 0.39, 0.19, 0.92)
const COLOR_AMBER := Color(0.96, 0.64, 0.16)
const COLOR_DANGER := Color(0.96, 0.25, 0.16)
const COLOR_STABLE := Color(0.25, 0.82, 0.56)
const COLOR_TEXT := Color(0.91, 0.89, 0.82)
const COLOR_MUTED := Color(0.66, 0.68, 0.65)

var _round_label: Label
var _structure_label: Label
var _kess_button: Button
var _maren_button: Button
var _kess_status: Label
var _maren_status: Label
var _member_title: Label
var _member_stats: Label
var _connection_stats: Label
var _anchor_title: Label
var _anchor_text: Label
var _feedback_label: Label
var _outcome_panel: PanelContainer
var _outcome_label: RichTextLabel
var _brace_button: Button
var _prop_button: Button
var _end_turn_button: Button
var _event_log: RichTextLabel


func build(prototype_notice: String, title: String) -> void:
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_header(root, prototype_notice, title)
	_build_party_panel(root)
	_build_inspection_panel(root)
	_build_log_panel(root)
	_build_action_bar(root)
	_build_outcome(root)


func set_round_status(round_number: int, reserve: float, reserve_max: float, rounds_left: int) -> void:
	_round_label.text = tr("ROUND %d  •  KESS RESERVE %.0f / %.0f  •  FULL ROUNDS LEFT %s") % [
		round_number,
		reserve,
		reserve_max,
		("—" if rounds_left >= 9999 else str(rounds_left)),
	]


func set_structure_status(overloaded: bool, utilisation: float) -> void:
	if overloaded:
		_structure_label.text = tr("CORRODED BRACKET OVER CAPACITY — %d%%") % int(round(utilisation * 100.0))
		_structure_label.modulate = COLOR_DANGER
	else:
		_structure_label.text = tr("CORRODED BRACKET STABLE — %d%%") % int(round(utilisation * 100.0))
		_structure_label.modulate = COLOR_STABLE


func set_unit_status(selected_id: StringName, kess_status: String, maren_status: String) -> void:
	_kess_button.button_pressed = selected_id == &"kess"
	_maren_button.button_pressed = selected_id == &"maren"
	_kess_status.text = tr(kess_status)
	_maren_status.text = tr(maren_status)


func set_member_details(
		label: String,
		load: float,
		capacity: float,
		utilisation: float,
		connection_line: String
	) -> void:
	_member_title.text = tr(label).to_upper()
	_member_stats.text = tr("LOAD %.0f  /  CAPACITY %.0f\nUTILISATION %d%%") % [
		load,
		capacity,
		int(round(utilisation * 100.0)),
	]
	_connection_stats.text = tr(connection_line)


func set_anchor_preview(text: String, holds: bool, available: bool = true) -> void:
	_anchor_title.text = tr("KINETIC ANCHOR PREVIEW") if available else tr("FIELD ACTION")
	_anchor_text.text = tr(text)
	_anchor_text.modulate = (COLOR_STABLE if holds else COLOR_DANGER) if available else COLOR_MUTED


func set_feedback(text: String, danger: bool = false) -> void:
	_feedback_label.text = tr(text)
	_feedback_label.modulate = COLOR_DANGER if danger else COLOR_AMBER


func set_actions(brace_enabled: bool, prop_enabled: bool, end_enabled: bool) -> void:
	_brace_button.disabled = not brace_enabled
	_prop_button.disabled = not prop_enabled
	_end_turn_button.disabled = not end_enabled


func set_event_log(lines: Array[String]) -> void:
	_event_log.clear()
	for line: String in lines:
		_event_log.append_text("• %s\n" % tr(line))
	_event_log.scroll_to_line(maxi(lines.size() - 1, 0))


func show_outcome(title: String, body: String, success: bool) -> void:
	_outcome_panel.visible = true
	_outcome_label.text = "[center][font_size=28][color=#%s]%s[/color][/font_size]\n%s[/center]" % [
		COLOR_STABLE.to_html(false) if success else COLOR_DANGER.to_html(false),
		tr(title),
		tr(body),
	]


func clear_outcome() -> void:
	_outcome_panel.visible = false


func _build_header(root: Control, prototype_notice: String, title: String) -> void:
	var panel := _panel(root, Vector2(24.0, 20.0), Vector2(1392.0, 98.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 720.0
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)

	var notice := _label(tr(prototype_notice), 13, COLOR_DANGER)
	box.add_child(notice)
	var title_label := _label(tr(title), 28, COLOR_TEXT)
	box.add_child(title_label)
	_round_label = _label("", 16, COLOR_AMBER)
	box.add_child(_round_label)
	_structure_label = _label("", 16, COLOR_DANGER)
	_structure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_structure_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_structure_label.custom_minimum_size = Vector2(590.0, 68.0)
	row.add_child(_structure_label)


func _build_party_panel(root: Control) -> void:
	var panel := _panel(root, Vector2(24.0, 136.0), Vector2(300.0, 374.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label(tr("FIELD TEAM"), 19, COLOR_AMBER))
	box.add_child(_label(tr("Select a unit, then inspect the structure."), 14, COLOR_MUTED))

	_kess_button = _unit_button(tr("KESS  •  KINETIC"))
	_kess_button.pressed.connect(func() -> void: unit_selected.emit(&"kess"))
	box.add_child(_kess_button)
	_kess_status = _label("", 14, COLOR_TEXT)
	_kess_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_kess_status)

	_maren_button = _unit_button(tr("MAREN  •  ORDINARY WORKER"))
	_maren_button.pressed.connect(func() -> void: unit_selected.emit(&"maren"))
	box.add_child(_maren_button)
	_maren_status = _label("", 14, COLOR_TEXT)
	_maren_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_maren_status)

	var controls := _label(
		tr("MOUSE\nLeft click: inspect member\nRight drag: orbit camera\nWheel: zoom"),
		14,
		COLOR_MUTED
	)
	box.add_child(controls)


func _build_inspection_panel(root: Control) -> void:
	var panel := _panel(root, Vector2(1068.0, 136.0), Vector2(348.0, 530.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_label(tr("STRUCTURAL READOUT"), 19, COLOR_AMBER))
	_member_title = _label("", 21, COLOR_TEXT)
	box.add_child(_member_title)
	_member_stats = _label("", 16, COLOR_TEXT)
	box.add_child(_member_stats)
	_connection_stats = _label("", 14, COLOR_MUTED)
	_connection_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_connection_stats.custom_minimum_size.y = 50.0
	box.add_child(_connection_stats)
	box.add_child(_rule())
	_anchor_title = _label("", 17, COLOR_AMBER)
	box.add_child(_anchor_title)
	_anchor_text = _label("", 15, COLOR_DANGER)
	_anchor_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anchor_text.custom_minimum_size.y = 142.0
	box.add_child(_anchor_text)
	_feedback_label = _label("", 14, COLOR_AMBER)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_feedback_label)


func _build_log_panel(root: Control) -> void:
	var panel := _panel(root, Vector2(24.0, 536.0), Vector2(430.0, 236.0))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label(tr("INCIDENT LOG"), 18, COLOR_AMBER))
	_event_log = RichTextLabel.new()
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.custom_minimum_size = Vector2(394.0, 172.0)
	_event_log.add_theme_font_size_override("normal_font_size", 14)
	_event_log.add_theme_color_override("default_color", COLOR_TEXT)
	_event_log.scroll_active = true
	box.add_child(_event_log)


func _build_action_bar(root: Control) -> void:
	var panel := _panel(root, Vector2(476.0, 692.0), Vector2(940.0, 80.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	_brace_button = _action_button(tr("BRACE WALKWAY"), COLOR_AMBER)
	_brace_button.pressed.connect(func() -> void: brace_requested.emit())
	row.add_child(_brace_button)
	_prop_button = _action_button(tr("PLACE PROP"), COLOR_STABLE)
	_prop_button.pressed.connect(func() -> void: prop_requested.emit())
	row.add_child(_prop_button)
	_end_turn_button = _action_button(tr("END TURN"), COLOR_DANGER)
	_end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())
	row.add_child(_end_turn_button)
	var restart := _action_button(tr("RESTART"), COLOR_MUTED)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	row.add_child(restart)


func _build_outcome(root: Control) -> void:
	_outcome_panel = _panel(root, Vector2(470.0, 264.0), Vector2(540.0, 180.0))
	_outcome_panel.visible = false
	_outcome_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_outcome_label = RichTextLabel.new()
	_outcome_label.bbcode_enabled = true
	_outcome_label.fit_content = false
	_outcome_label.add_theme_color_override("default_color", COLOR_TEXT)
	_outcome_label.add_theme_font_size_override("normal_font_size", 18)
	_outcome_panel.add_child(_outcome_label)


func _panel(parent: Control, position_value: Vector2, size_value: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _style_box(COLOR_PANEL, COLOR_BORDER, 12.0))
	parent.add_child(panel)
	return panel


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _unit_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(260.0, 42.0)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _style_box(COLOR_INK, COLOR_BORDER.darkened(0.25), 7.0))
	button.add_theme_stylebox_override("pressed", _style_box(COLOR_BORDER.darkened(0.35), COLOR_AMBER, 7.0))
	button.add_theme_stylebox_override("hover", _style_box(COLOR_INK.lightened(0.08), COLOR_AMBER, 7.0))
	return button


func _action_button(text_value: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(202.0, 46.0)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _style_box(COLOR_INK, accent.darkened(0.25), 7.0))
	button.add_theme_stylebox_override("hover", _style_box(COLOR_INK.lightened(0.08), accent, 7.0))
	button.add_theme_stylebox_override("pressed", _style_box(accent.darkened(0.45), accent, 7.0))
	return button


func _style_box(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(int(radius))
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _rule() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	return separator
