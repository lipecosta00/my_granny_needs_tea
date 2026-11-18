class_name Hero
extends CharacterBody2D
## Player character. Milestone 1: 8-way movement, 4-way facing, walk bounce.
## Tuning values are exported per the GDD ("calibrar jogando").

signal facing_changed(facing: Vector2)

@export_group("Movement")
## ~5 tiles/s at 16 px per tile.
@export var max_speed := 80.0
@export var acceleration := 1000.0
@export var friction := 1200.0

## Cardinal direction the hero looks at; attacks will come out this way.
var facing := Vector2.DOWN
## Cutscenes/dialogue turn this off instead of pausing the tree.
var input_enabled := true

@onready var _sprite: Sprite2D = %Sprite


func _physics_process(delta: float) -> void:
	var input := read_move_input() if input_enabled else Vector2.ZERO
	velocity = TopDownMotor.step(velocity, input, max_speed, acceleration, friction, delta)
	_update_facing(input)
	move_and_slide()


## Circular dead zone (0.2 from the action settings) handled by get_vector.
func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _update_facing(input: Vector2) -> void:
	if input.is_zero_approx():
		return
	var new_facing := TopDownMotor.to_cardinal(input, facing)
	if new_facing != facing:
		facing = new_facing
		facing_changed.emit(facing)
	if absf(input.x) > 0.01:
		_sprite.flip_h = input.x < 0.0
