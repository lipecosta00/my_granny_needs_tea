class_name FollowCamera
extends Camera2D
## Map camera, decoupled from the hero so cutscenes can retarget it later.
## Screen shake uses trauma² (decays in real time, so it keeps moving during
## hitstop) and can be disabled in Settings via Fx.

@export var target: Node2D
@export var max_shake_offset := Vector2(5, 4)
@export var trauma_decay := 2.2

var _trauma := 0.0
var _last_tick_ms := 0


func _ready() -> void:
	add_to_group(&"shake_camera")
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_tick_ms = Time.get_ticks_msec()
	if target:
		global_position = target.global_position
		reset_smoothing()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var real_delta := (now - _last_tick_ms) / 1000.0
	_last_tick_ms = now
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = maxf(0.0, _trauma - trauma_decay * real_delta)
	var strength := _trauma * _trauma
	offset = Vector2(
		randf_range(-1.0, 1.0) * max_shake_offset.x * strength,
		randf_range(-1.0, 1.0) * max_shake_offset.y * strength).round()


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Clamps the view to a map rectangle in world pixels.
func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)
	reset_smoothing()
