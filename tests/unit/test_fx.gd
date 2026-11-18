extends "res://tests/test_case.gd"
## Fx side effects that would break the whole game if they went wrong.


func _wait_real(seconds: float) -> void:
	await tree.create_timer(seconds, true, false, true).timeout


func test_hitstop_always_restores_time_scale() -> void:
	for i in 20:
		Fx.hitstop(0.02)
		await _wait_real(0.04)
		assert_eq(Engine.time_scale, 1.0, "frozen after hitstop #%d" % i)
		if Engine.time_scale != 1.0:
			Engine.time_scale = 1.0
			return


func test_overlapping_hitstops_restore_after_the_longest() -> void:
	Fx.hitstop(0.12)
	await _wait_real(0.03)
	Fx.hitstop(0.02)  # shorter than what is left: ignored
	await _wait_real(0.04)
	assert_eq(Engine.time_scale, 0.0, "still inside the long hitstop")
	await _wait_real(0.1)
	assert_eq(Engine.time_scale, 1.0)
	Engine.time_scale = 1.0


func test_disabled_hitstop_does_nothing() -> void:
	Fx.hitstop_enabled = false
	Fx.hitstop(0.1)
	assert_eq(Engine.time_scale, 1.0)
	Fx.hitstop_enabled = true
