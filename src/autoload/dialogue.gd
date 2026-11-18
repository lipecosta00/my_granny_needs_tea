extends CanvasLayer
## Dialogue box (GDD "Telas > Diálogo"): bottom box with the speaker's name,
## typewriter text; A/E advances, holding B speeds it up. While open (and a
## moment after) the hero ignores input, so the closing press can't re-trigger
## the conversation.

signal finished

const FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const INPUT_GRACE_MS := 200

@export var chars_per_second := 40.0

var active := false
var _lines: Array = []
var _index := 0
var _shown := 0.0
var _closed_at_ms := -100000
var _panel: Panel
var _name_label: Label
var _text_label: Label
var _arrow: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_panel.visible = false


## Lines: Strings, or {"name": String, "text": String}. Await [signal finished].
func say(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	active = true
	_panel.visible = true
	_show_line()


## True while talking and briefly after, so the last press isn't reused.
func blocks_input() -> bool:
	return active or Time.get_ticks_msec() - _closed_at_ms < INPUT_GRACE_MS


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"attack_primary"):
		get_viewport().set_input_as_handled()
		if _text_label.visible_ratio < 1.0:
			_shown = _text_label.text.length()
			_text_label.visible_characters = -1
		else:
			_advance()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active:
		return
	var speed := chars_per_second * (3.0 if Input.is_action_pressed(&"roll") else 1.0)
	_shown += speed * delta
	_text_label.visible_characters = int(_shown)
	_arrow.visible = _text_label.visible_ratio >= 1.0 and int(Time.get_ticks_msec() / 300) % 2 == 0


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		active = false
		_panel.visible = false
		_closed_at_ms = Time.get_ticks_msec()
		finished.emit()
		return
	_show_line()


func _show_line() -> void:
	var line: Variant = _lines[_index]
	var speaker := ""
	var text := ""
	if line is Dictionary:
		speaker = line.get("name", "")
		text = line.get("text", "")
	else:
		text = str(line)
	_name_label.text = speaker
	_name_label.visible = speaker != ""
	_text_label.text = text
	_shown = 0.0
	_text_label.visible_characters = 0


func _build() -> void:
	_panel = Panel.new()
	_panel.position = Vector2(8, 204)
	_panel.size = Vector2(464, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.05, 0.12, 0.94)
	style.border_color = Color(1.0, 0.83, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	_panel.add_theme_stylebox_override(&"panel", style)
	add_child(_panel)
	_name_label = _label(Color(1.0, 0.83, 0.42))
	_name_label.position = Vector2(8, 6)
	_panel.add_child(_name_label)
	_text_label = _label(Color(0.95, 0.91, 0.85))
	_text_label.position = Vector2(8, 20)
	_text_label.size = Vector2(448, 36)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_constant_override(&"line_spacing", 4)
	_panel.add_child(_text_label)
	_arrow = _label(Color(1.0, 0.83, 0.42))
	_arrow.text = "v"
	_arrow.position = Vector2(448, 48)
	_panel.add_child(_arrow)


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override(&"font", FONT)
	label.add_theme_font_size_override(&"font_size", 8)
	label.add_theme_color_override(&"font_color", color)
	return label
