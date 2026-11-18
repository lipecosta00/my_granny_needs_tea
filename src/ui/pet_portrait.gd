class_name PetPortrait
extends Control
## HUD: active pet with the RB cooldown as a ring (GDD "Interface e HUD").
## Full ring = ready; partial = recharging; faded = pet is out.

const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
const GHOST_REGION := Rect2(16, 160, 16, 16)

var _pet: Pet


func _ready() -> void:
	custom_minimum_size = Vector2(20, 20)
	size = custom_minimum_size


func bind(pet: Pet) -> void:
	_pet = pet
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, 9.5, Color(0.08, 0.04, 0.1, 0.85))
	if _pet == null:
		return
	var tint := Color(_pet.color, 0.35 if _pet.is_out else 1.0)
	draw_texture_rect_region(ATLAS, Rect2(center - Vector2(8, 8), Vector2(16, 16)), GHOST_REGION, tint)
	var ready_fraction := 1.0 - _pet.cooldown_ratio()
	if ready_fraction > 0.0:
		var ring_color := _pet.color if ready_fraction >= 1.0 else Color(_pet.color, 0.5)
		draw_arc(center, 9.0, -PI / 2.0, -PI / 2.0 + TAU * ready_fraction, 24, ring_color, 1.5)
