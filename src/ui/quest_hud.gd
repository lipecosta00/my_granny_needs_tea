class_name QuestHud
extends Control
## Top-right: granny's current request, grey until collected (GDD HUD).

const SLOT := 18.0


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT, SLOT)
	size = custom_minimum_size
	GameState.changed.connect(queue_redraw)


func _draw() -> void:
	var item := GameState.requested_item()
	if item == &"":
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(SLOT, SLOT)), Color(0.08, 0.04, 0.1, 0.85))
	draw_rect(Rect2(Vector2.ZERO, Vector2(SLOT, SLOT)), Color(1, 0.83, 0.42, 0.8), false, 1.0)
	var owned := GameState.has_item(item)
	var tint := Color.WHITE if owned else Color(0.25, 0.22, 0.28)
	draw_texture_rect_region(ItemCatalog.texture(item), Rect2(Vector2(1, 1), Vector2(16, 16)),
		ItemCatalog.region(item), tint)
