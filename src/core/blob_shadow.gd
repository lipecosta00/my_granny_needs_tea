@tool
class_name BlobShadow
extends Node2D
## Flat ellipse under a character. Grounds the hop of WalkBounce visually.

@export var radius := Vector2(5.0, 2.0):
	set(value):
		radius = value
		queue_redraw()
@export var color := Color(0.12, 0.06, 0.16, 0.45):
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, radius.y / radius.x))
	draw_circle(Vector2.ZERO, radius.x, color)
