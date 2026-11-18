class_name Crab
extends Enemy
## GDD: "Bloqueia golpes de frente" — teaches flanking (and the Barqueira's
## Remo). Turns slowly toward the hero, so circling around it works; hits
## landing inside the front arc bounce off its shell unless it is stunned.

enum Mode { SIDLE, TELEGRAPH, PINCH, RECOVER }

@export var sidle_speed := 28.0
## Radians per second: slow enough to get around it.
@export var turn_rate := 2.2
## Half-angle of the shell in front, degrees.
@export var guard_half_angle := 60.0
@export var pinch_range := 22.0
@export var telegraph_time := 0.3
@export var pinch_speed := 150.0
@export var pinch_time := 0.15
@export var recover_time := 0.6

var facing := Vector2.DOWN
var mode := Mode.SIDLE
var _mode_time := 0.0
var _pinch_dir := Vector2.DOWN


func _behaviour(delta: float) -> void:
	_mode_time += delta
	var hero := find_hero(detect_radius)
	if hero and mode in [Mode.SIDLE, Mode.TELEGRAPH]:
		var wanted := (hero.global_position - global_position).normalized()
		facing = Vector2.from_angle(rotate_toward(facing.angle(), wanted.angle(), turn_rate * delta))
	match mode:
		Mode.SIDLE:
			velocity = Vector2.ZERO
			if hero:
				var to_hero := hero.global_position - global_position
				velocity = to_hero.normalized() * sidle_speed
				if to_hero.length() <= pinch_range:
					_pinch_dir = facing
					_set_mode(Mode.TELEGRAPH)
		Mode.TELEGRAPH:
			velocity = Vector2.ZERO
			if _mode_time >= telegraph_time:
				_pinch_dir = facing
				_set_mode(Mode.PINCH)
		Mode.PINCH:
			velocity = _pinch_dir * pinch_speed
			if _mode_time >= pinch_time:
				_set_mode(Mode.RECOVER)
		Mode.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
			if _mode_time >= recover_time:
				_set_mode(Mode.SIDLE)
	queue_redraw()


## Front hit = the attack travels against the crab's facing.
func _blocks_hit(hit: HitData) -> bool:
	return Crab.is_frontal(facing, hit.knockback, guard_half_angle)


static func is_frontal(crab_facing: Vector2, push: Vector2, half_angle_degrees: float) -> bool:
	if push.is_zero_approx():
		return false
	return crab_facing.dot(-push.normalized()) >= cos(deg_to_rad(half_angle_degrees))


func _draw() -> void:
	if is_stunned():
		return
	# The shell: a pale arc on the guarded side, so flanking reads clearly.
	var center := Vector2(0, -6)
	var half := deg_to_rad(guard_half_angle)
	draw_arc(center, 10.0, facing.angle() - half, facing.angle() + half, 10, Color(1, 1, 1, 0.55), 1.5)


func _update_visuals(delta: float) -> void:
	super(delta)
	if mode == Mode.TELEGRAPH and not is_stunned():
		sprite.self_modulate = Color(1.6, 0.6, 0.6) if int(_mode_time / 0.05) % 2 == 0 else Color.WHITE


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_time = 0.0
