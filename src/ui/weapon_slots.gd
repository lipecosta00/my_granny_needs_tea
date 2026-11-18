class_name WeaponSlots
extends Control
## HUD: weapon slots I and II with their button colour (GDD "HUD em jogo").

const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
const SLOT_SIZE := 18.0

var _slots: Array = [null, null]


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE * 2 + 4, SLOT_SIZE)
	size = custom_minimum_size


func bind(hero: Hero) -> void:
	hero.weapons_changed.connect(show_weapons)
	show_weapons(hero.primary_weapon, hero.secondary_weapon)


func show_weapons(primary: WeaponData, secondary: WeaponData) -> void:
	_slots = [primary, secondary]
	queue_redraw()


func _draw() -> void:
	for i in 2:
		var origin := Vector2(i * (SLOT_SIZE + 4), 0)
		var box := Rect2(origin, Vector2(SLOT_SIZE, SLOT_SIZE))
		draw_rect(box, Color(0.08, 0.04, 0.1, 0.85))
		draw_rect(box, WeaponWheel.SLOT_COLORS[i], false, 1.0)
		var weapon: WeaponData = _slots[i]
		if weapon:
			draw_texture_rect_region(ATLAS, Rect2(origin + Vector2(1, 1), Vector2(16, 16)), weapon.sprite_region)
