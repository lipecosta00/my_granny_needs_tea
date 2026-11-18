class_name HeartsBar
extends HBoxContainer
## Hearts HUD (Tiny Battle heart). One heart = 2 health units (half hearts).

const ATLAS := preload("res://assets/kenney/tiny_battle/tilemap_packed.png")
const HEART_REGION := Rect2(15 * 16, 10 * 16, 16, 16)
const EMPTY_TINT := Color(0.25, 0.12, 0.2, 0.9)

var _health: Health


func bind(health: Health) -> void:
	if _health and _health.changed.is_connected(_refresh):
		_health.changed.disconnect(_refresh)
	_health = health
	_health.changed.connect(_refresh)
	_refresh(_health.current, _health.max_health)


## Units per heart: 0 = empty, 1 = half, 2 = full.
static func heart_states(current: int, maximum: int) -> PackedInt32Array:
	var states := PackedInt32Array()
	for i in ceili(maximum / 2.0):
		states.append(clampi(current - i * 2, 0, 2))
	return states


func _refresh(current: int, maximum: int) -> void:
	var states := heart_states(current, maximum)
	while get_child_count() < states.size():
		add_child(_make_slot())
	while get_child_count() > states.size():
		var extra := get_child(get_child_count() - 1)
		remove_child(extra)
		extra.queue_free()
	for i in states.size():
		var fill := get_child(i).get_node(^"Fill") as TextureRect
		fill.visible = states[i] > 0
		var region := HEART_REGION
		if states[i] == 1:
			region.size.x = 8
		(fill.texture as AtlasTexture).region = region
		fill.size = region.size


func _make_slot() -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(12, 16)
	var empty := TextureRect.new()
	empty.texture = _atlas(HEART_REGION)
	empty.modulate = EMPTY_TINT
	slot.add_child(empty)
	var fill := TextureRect.new()
	fill.name = "Fill"
	fill.texture = _atlas(HEART_REGION)
	fill.stretch_mode = TextureRect.STRETCH_KEEP
	slot.add_child(fill)
	return slot


func _atlas(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = region
	return texture
