class_name TopDownMotor
extends RefCounted
## Pure top-down movement math. No nodes or Input here, so it runs in headless
## unit tests and can be shared by the hero, enemies and souls.


## Returns the next velocity. [param input] is expected already dead-zoned
## (Input.get_vector does that); its length scales speed so a light stick tilt
## walks slowly.
static func step(
		velocity: Vector2,
		input: Vector2,
		max_speed: float,
		acceleration: float,
		friction: float,
		delta: float) -> Vector2:
	var target := input.limit_length(1.0) * max_speed
	var rate := friction if input.is_zero_approx() else acceleration
	# Reversing direction should feel instant on a gamepad: brake and accelerate
	# at the same time instead of gliding through zero.
	if not input.is_zero_approx() and velocity.dot(target) < 0.0:
		rate += friction
	return velocity.move_toward(target, rate * delta)


## Snaps [param direction] to the nearest cardinal direction. On an exact
## diagonal it keeps [param current] when that is one of the two candidates,
## so the sprite does not flicker between facings while moving diagonally.
static func to_cardinal(direction: Vector2, current := Vector2.DOWN, tie_epsilon := 0.05) -> Vector2:
	if direction.is_zero_approx():
		return current
	var horizontal := Vector2(signf(direction.x), 0.0)
	var vertical := Vector2(0.0, signf(direction.y))
	if absf(absf(direction.x) - absf(direction.y)) <= tie_epsilon:
		if current == horizontal or current == vertical:
			return current
		return horizontal
	return horizontal if absf(direction.x) > absf(direction.y) else vertical
