class_name RingFx
extends Node2D
## Filled glow + outline circle; Fx.ring() tweens [member radius].

var color := Color.WHITE
var radius := 0.0:
	set(value):
		radius = value
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.25))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0)
