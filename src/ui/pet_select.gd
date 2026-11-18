class_name PetSelect
extends CanvasLayer
## Cauldron screen (GDD "Caldeirão (escolha de pet)"): created pets, what each
## does, and which one comes along. D-pad/stick left-right, A confirm, B back.

signal chosen(pet_id: StringName)
signal cancelled

const FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const GHOST := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
const GHOST_REGION := Rect2(16, 160, 16, 16)
const CARD := Vector2(132, 120)

var is_open := false
var _pets: Array[StringName] = []
var _index := 0
var _root: Control


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.draw.connect(_draw_screen)
	_root.visible = false
	add_child(_root)


func open(pets: Array[StringName], active: StringName) -> void:
	_pets = pets
	_index = maxi(0, pets.find(active))
	is_open = true
	_root.visible = true
	_root.queue_redraw()


func close() -> void:
	is_open = false
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_index = posmod(_index - 1, _pets.size())
		Fx.sfx(&"spark", 0.0)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_index = posmod(_index + 1, _pets.size())
		Fx.sfx(&"spark", 0.0)
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"attack_primary"):
		close()
		chosen.emit(_pets[_index])
	elif event.is_action_pressed(&"roll") or event.is_action_pressed(&"pause"):
		close()
		cancelled.emit()
	else:
		return
	get_viewport().set_input_as_handled()
	_root.queue_redraw()


func _draw_screen() -> void:
	_root.draw_rect(Rect2(Vector2.ZERO, Vector2(480, 270)), Color(0.04, 0.02, 0.06, 0.8))
	_text(Vector2(240, 30), "O CALDEIRÃO", Color(1, 0.83, 0.42), true)
	var total_width := _pets.size() * CARD.x + (_pets.size() - 1) * 10.0
	var x := 240.0 - total_width / 2.0
	for i in _pets.size():
		var info: Dictionary = PetCatalog.INFO.get(_pets[i], {})
		var rect := Rect2(Vector2(x, 60), CARD)
		var selected := i == _index
		_root.draw_rect(rect, Color(0.12, 0.07, 0.16, 0.95))
		_root.draw_rect(rect, Color(1, 0.83, 0.42) if selected else Color(0.4, 0.32, 0.5), false, 2.0 if selected else 1.0)
		var color: Color = info.get("color", Color.WHITE)
		_root.draw_texture_rect_region(GHOST, Rect2(rect.position + Vector2(CARD.x / 2 - 16, 10), Vector2(32, 32)), GHOST_REGION, color)
		_text(rect.position + Vector2(CARD.x / 2, 58), info.get("name", ""), color, true)
		_wrapped(rect.position + Vector2(6, 72), info.get("combat", ""))
		_wrapped(rect.position + Vector2(6, 96), info.get("explore", ""))
		x += CARD.x + 10.0
	_text(Vector2(240, 200), "< > escolher   A levar   B voltar", Color(0.75, 0.68, 0.82), true)


func _text(at: Vector2, text: String, color: Color, centered := false) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	_root.draw_string(FONT, at - Vector2(width / 2.0 if centered else 0.0, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)


func _wrapped(at: Vector2, text: String) -> void:
	_root.draw_multiline_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, CARD.x - 12, 8, 2,
		Color(0.92, 0.88, 0.82))
