extends "res://tests/test_case.gd"

const SPEED := 80.0
const ACCEL := 1000.0
const FRICTION := 1200.0
const DT := 1.0 / 60.0


func _run_frames(velocity: Vector2, input: Vector2, frames: int) -> Vector2:
	for i in frames:
		velocity = TopDownMotor.step(velocity, input, SPEED, ACCEL, FRICTION, DT)
	return velocity


func test_reaches_max_speed_quickly() -> void:
	# Full speed in < 0.1 s keeps the controls feeling immediate (pillar 3).
	var v := _run_frames(Vector2.ZERO, Vector2.RIGHT, 6)
	assert_almost(v.length(), SPEED, 0.01)


func test_never_exceeds_max_speed_even_with_oversized_input() -> void:
	var v := _run_frames(Vector2.ZERO, Vector2(3, 3), 60)
	assert_almost(v.length(), SPEED, 0.01)


func test_partial_tilt_walks_slower() -> void:
	var v := _run_frames(Vector2.ZERO, Vector2(0.5, 0), 60)
	assert_almost(v.length(), SPEED * 0.5, 0.01)


func test_friction_stops_without_overshoot() -> void:
	var v := _run_frames(Vector2(SPEED, 0), Vector2.ZERO, 60)
	assert_vec_almost(v, Vector2.ZERO)


func test_reversal_is_faster_than_plain_acceleration() -> void:
	var reversed := _run_frames(Vector2(SPEED, 0), Vector2.LEFT, 4)
	var from_rest := _run_frames(Vector2.ZERO, Vector2.LEFT, 4)
	assert_true(reversed.x < 0.0, "should already move left after 4 frames")
	assert_true(absf(reversed.x) <= absf(from_rest.x) + 0.01)


func test_cardinal_snapping() -> void:
	assert_eq(TopDownMotor.to_cardinal(Vector2(0.9, 0.2)), Vector2.RIGHT)
	assert_eq(TopDownMotor.to_cardinal(Vector2(-0.9, 0.2)), Vector2.LEFT)
	assert_eq(TopDownMotor.to_cardinal(Vector2(0.1, -0.7)), Vector2.UP)
	assert_eq(TopDownMotor.to_cardinal(Vector2(0.1, 0.7)), Vector2.DOWN)


func test_zero_input_keeps_current_facing() -> void:
	assert_eq(TopDownMotor.to_cardinal(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT)


func test_diagonal_keeps_compatible_facing() -> void:
	var diagonal := Vector2(1, -1).normalized()
	assert_eq(TopDownMotor.to_cardinal(diagonal, Vector2.UP), Vector2.UP)
	assert_eq(TopDownMotor.to_cardinal(diagonal, Vector2.RIGHT), Vector2.RIGHT)
	# Facing that is not part of the diagonal falls back to horizontal.
	assert_eq(TopDownMotor.to_cardinal(diagonal, Vector2.DOWN), Vector2.RIGHT)
