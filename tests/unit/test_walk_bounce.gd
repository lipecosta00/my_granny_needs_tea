extends "res://tests/test_case.gd"


func test_hop_stays_within_amplitude_and_goes_up() -> void:
	for i in 64:
		var phase := TAU * i / 64.0
		var y := WalkBounce.hop_offset(phase, 2.0)
		assert_true(y <= 0.0 and y >= -2.0, "phase %f -> %f" % [phase, y])


func test_hop_touches_ground_each_step() -> void:
	assert_almost(WalkBounce.hop_offset(0.0, 2.0), 0.0)
	assert_almost(WalkBounce.hop_offset(PI, 2.0), 0.0)
	assert_almost(WalkBounce.hop_offset(PI / 2.0, 2.0), -2.0)


func test_squash_preserves_area() -> void:
	for i in 32:
		var s := WalkBounce.squash_scale(TAU * i / 32.0, 0.15)
		assert_almost(s.x * s.y, 1.0, 0.0001)


func test_squash_wide_on_landing_tall_at_apex() -> void:
	var landing := WalkBounce.squash_scale(0.0, 0.1)
	var apex := WalkBounce.squash_scale(PI / 2.0, 0.1)
	assert_true(landing.x > 1.0 and landing.y < 1.0, "landing should squash")
	assert_true(apex.x < 1.0 and apex.y > 1.0, "apex should stretch")


func test_zero_amount_is_identity() -> void:
	assert_vec_almost(WalkBounce.squash_scale(1.234, 0.0), Vector2.ONE)
