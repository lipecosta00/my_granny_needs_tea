class_name PetGate
extends StaticBody2D
## Obstacle that only a pet's exploration ability removes (GDD: luz, ponte,
## túnel). Once opened it is recorded in GameState and stays open forever.
## Node position = top-left corner; [member size] in pixels.

signal opened

@export var gate_id: StringName
@export var required_ability: StringName = &"light"
@export var size := Vector2(48, 64)

var is_open := false
var _clock := 0.0
var _fade := 1.0
var _hint := 0.0
## 0..1: hero is close but the active pet can't open this gate.
var _wrong_pet := 0.0
var _shape: CollisionShape2D


func _ready() -> void:
	add_to_group(&"pet_gates")
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	add_child(_shape)
	if GameState.is_gate_open(gate_id):
		_set_open(false)


func _active_pet_can_open() -> bool:
	for pet: Node in get_tree().get_nodes_in_group(&"pets"):
		if pet.get(&"exploration_ability") == required_ability:
			return true
	return false


func distance_to_point(point: Vector2) -> float:
	var local := point - global_position
	var closest := Vector2(clampf(local.x, 0.0, size.x), clampf(local.y, 0.0, size.y))
	return local.distance_to(closest)


func open_with(_pet: Pet) -> void:
	if is_open:
		return
	GameState.open_gate(gate_id)
	_set_open(true)


func _set_open(animate: bool) -> void:
	is_open = true
	_shape.set_deferred(&"disabled", true)
	opened.emit()
	if not animate:
		_fade = 0.0
		queue_redraw()
		return
	Fx.sfx(&"gate_open")
	Fx.ring(global_position + size / 2.0, maxf(size.x, size.y), Color(1.0, 0.95, 0.7), 0.6)
	for i in 4:
		Fx.burst(global_position + Vector2(randf() * size.x, randf() * size.y), Color(0.6, 0.5, 0.9), 6, 50.0)
	var tween := create_tween()
	tween.tween_property(self, "_fade", 0.0, 0.8)


func _process(delta: float) -> void:
	_clock += delta
	var target_hint := 0.0
	if not is_open:
		for pet: Pet in get_tree().get_nodes_in_group(&"pets"):
			if pet.find_openable_gate() == self:
				target_hint = 1.0
	_hint = move_toward(_hint, target_hint, delta * 3.0)
	var show_needed := false
	if not is_open and not _active_pet_can_open():
		for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
			show_needed = distance_to_point(hero.global_position) <= 72.0
	_wrong_pet = move_toward(_wrong_pet, 1.0 if show_needed else 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	match required_ability:
		&"bridge":
			_draw_bridge()
		&"tunnel":
			_draw_fence()
		_:
			_draw_darkness()
	_draw_hint()
	_draw_needed_pet()


## Floating ghost in the colour of the pet that opens this gate — tells the
## player which pet to bring from granny's cauldron (playtest: the canal).
func _draw_needed_pet() -> void:
	if _wrong_pet <= 0.0 or is_open:
		return
	const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
	var at := Vector2(size.x / 2.0 - 8.0, -18.0 + sin(_clock * 3.0) * 2.0)
	draw_circle(at + Vector2(8, 8), 10.0, Color(0.05, 0.02, 0.1, 0.6 * _wrong_pet))
	var tint := PetCatalog.color_for_ability(required_ability)
	tint.a = _wrong_pet
	draw_texture_rect_region(ATLAS, Rect2(at, Vector2(16, 16)), Rect2(16, 160, 16, 16), tint)


## Living darkness: overlapping blobs that breathe.
func _draw_darkness() -> void:
	if _fade <= 0.0:
		return
	var step := 10.0
	var i := 0
	var y := 0.0
	while y <= size.y:
		var x := 0.0
		while x <= size.x:
			var wobble := sin(_clock * 2.0 + i * 1.7) * 2.0
			draw_circle(Vector2(x, y), 9.0 + wobble, Color(0.05, 0.02, 0.1, 0.85 * _fade))
			x += step
			i += 1
		y += step


## Water stays visible below; once open, planks of mist span it.
func _draw_bridge() -> void:
	var planks := 1.0 - _fade
	if planks <= 0.0:
		return
	var horizontal := size.x >= size.y
	var count := int((size.x if horizontal else size.y) / 6.0)
	for k in count:
		var t := k * 6.0
		var rect := Rect2(t, 2, 5, size.y - 4) if horizontal else Rect2(2, t, size.x - 4, 5)
		var shimmer := 0.55 + 0.15 * sin(_clock * 2.0 + k)
		draw_rect(rect, Color(0.8, 0.9, 1.0, shimmer * planks))


## Iron fence; once tunnelled, a dirt hole opens under it.
func _draw_fence() -> void:
	var bar_color := Color(0.3, 0.3, 0.38)
	var gap_center := size.x / 2.0
	var x := 2.0
	while x < size.x:
		var in_gap := absf(x - gap_center) < 9.0 and _fade < 1.0
		if not in_gap:
			draw_rect(Rect2(x, 0, 2, size.y), bar_color)
		x += 5.0
	draw_rect(Rect2(0, 2, size.x, 2), bar_color)
	if _fade < 1.0:
		var hole := Color(0.12, 0.08, 0.05, 1.0 - _fade)
		draw_set_transform(Vector2(gap_center, size.y / 2.0), 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, 8.0, hole)
		draw_set_transform(Vector2.ZERO)
	else:
		# Mound of loose earth marks where the Toupeira can dig.
		draw_circle(Vector2(gap_center, size.y - 2), 5.0, Color(0.45, 0.32, 0.2))


## Sparkles when the active pet can open this gate.
func _draw_hint() -> void:
	if _hint <= 0.0 or is_open:
		return
	for k in 6:
		var t := _clock * 1.5 + k * 1.05
		var p := Vector2(fposmod(sin(t * 0.7 + k) * 0.5 + 0.5, 1.0) * size.x,
			fposmod(t * 12.0 + k * 9.0, size.y))
		draw_circle(p, 1.5, Color(1.0, 0.9, 0.4, _hint))
