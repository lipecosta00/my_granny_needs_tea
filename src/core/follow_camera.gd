class_name FollowCamera
extends Camera2D
## Map camera, decoupled from the hero so cutscenes can retarget it later.

@export var target: Node2D


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	if target:
		global_position = target.global_position
		reset_smoothing()


func _physics_process(_delta: float) -> void:
	if target:
		global_position = target.global_position


## Clamps the view to a map rectangle in world pixels.
func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	reset_smoothing()
