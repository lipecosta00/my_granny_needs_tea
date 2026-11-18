class_name Bat
extends Enemy
## GDD: "Voa em zigue-zague e mergulha" — teaches the staff and ranged hits.
## Flies over everything (no world collision). Flutters around the hero in a
## zigzag, warns briefly, dives straight in, then pulls back up.

enum Mode { FLUTTER, TELEGRAPH, DIVE, RETREAT }

@export var flutter_speed := 55.0
@export var orbit_distance := 44.0
@export var zigzag_amplitude := 40.0
@export var telegraph_time := 0.35
@export var dive_speed := 190.0
@export var dive_time := 0.35
@export var retreat_time := 0.5

var mode := Mode.FLUTTER
var _mode_time := 0.0
var _next_dive := 2.0
var _orbit_angle := 0.0
var _dive_dir := Vector2.DOWN
var _home := Vector2.ZERO


func _ready() -> void:
	super()
	_home = global_position
	_orbit_angle = randf() * TAU
	_next_dive = randf_range(1.5, 2.5)


func _behaviour(delta: float) -> void:
	_mode_time += delta
	var hero := find_hero(detect_radius * 1.4)
	match mode:
		Mode.FLUTTER:
			var center := hero.global_position if hero else _home
			_orbit_angle += delta * 1.6
			var goal := center + Vector2.from_angle(_orbit_angle) * orbit_distance
			var to_goal := goal - global_position
			var zig := to_goal.orthogonal().normalized() * sin(_clock * 9.0) * zigzag_amplitude
			velocity = to_goal.limit_length(1.0) * flutter_speed * minf(1.0, to_goal.length() / 16.0) + zig
			velocity = velocity.limit_length(flutter_speed * 1.4)
			if hero and _mode_time >= _next_dive:
				_dive_dir = (hero.global_position - global_position).normalized()
				_set_mode(Mode.TELEGRAPH)
		Mode.TELEGRAPH:
			velocity = Vector2.ZERO
			if hero and _mode_time < telegraph_time * 0.6:
				_dive_dir = (hero.global_position - global_position).normalized()
			if _mode_time >= telegraph_time:
				_set_mode(Mode.DIVE)
		Mode.DIVE:
			velocity = _dive_dir * dive_speed
			if _mode_time >= dive_time:
				_set_mode(Mode.RETREAT)
		Mode.RETREAT:
			velocity = -_dive_dir * flutter_speed * 1.2
			if _mode_time >= retreat_time:
				_next_dive = randf_range(1.5, 2.5)
				_set_mode(Mode.FLUTTER)


func _on_hurt() -> void:
	if mode in [Mode.TELEGRAPH, Mode.DIVE]:
		_set_mode(Mode.RETREAT)


func _update_visuals(delta: float) -> void:
	super(delta)
	if mode == Mode.TELEGRAPH and not is_stunned():
		sprite.self_modulate = Color(1.6, 0.6, 0.6) if int(_mode_time / 0.05) % 2 == 0 else Color.WHITE


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_time = 0.0
