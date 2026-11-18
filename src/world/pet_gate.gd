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
	if _fade > 0.0:
		queue_redraw()


func _draw() -> void:
	if _fade <= 0.0:
		return
	# Living darkness: overlapping blobs that breathe; sparkles hint that the
	# active pet can clear it (GDD: brilho avisa quando o pet certo está perto).
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
	if _hint > 0.0:
		for k in 6:
			var t := _clock * 1.5 + k * 1.05
			var p := Vector2(fposmod(sin(t * 0.7 + k) * 0.5 + 0.5, 1.0) * size.x,
				fposmod(t * 12.0 + k * 9.0, size.y))
			draw_circle(p, 1.5, Color(1.0, 0.9, 0.4, _hint * _fade))
