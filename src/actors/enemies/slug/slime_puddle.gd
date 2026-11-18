class_name SlimePuddle
extends Node2D
## Slime left by the slug. Slows the hero while standing in it; fades out.
## Distance check instead of physics: tiny, cheap and deterministic.

var lifetime := 4.0
var radius := 7.0
var slow_factor := 0.5
var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
		if hero.global_position.distance_to(global_position) <= radius and hero.has_method(&"slow"):
			hero.slow(slow_factor, 0.1)
	queue_redraw()


func _draw() -> void:
	var alpha := 0.55 * clampf((lifetime - _age) / 1.0, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.75, 0.3, alpha))
