class_name WalkBounce
extends Node2D
## Procedural walk "quique" for 1-frame sprites (GDD: Animação por código).
##
## Attach to a visual-only child whose origin sits at the character's feet:
## hop and squash never touch the physics body, so collisions stay stable.
## A continuous phase is used instead of chained tweens so starting/stopping
## mid-step never snaps or stacks animations.

@export var body: CharacterBody2D
@export var shadow: Node2D
## Speed that counts as "full walk"; slower movement hops less.
@export var reference_speed := 80.0
@export_range(0.0, 8.0, 0.5) var hop_height := 2.0
@export_range(1.0, 15.0, 0.5) var steps_per_second := 7.0
@export_range(0.0, 0.4, 0.01) var squash_amount := 0.12
## How fast the hop fades in/out when starting or stopping.
@export var settle_rate := 14.0

var _phase := 0.0
var _intensity := 0.0


func _process(delta: float) -> void:
	var speed_ratio := 0.0
	if body:
		speed_ratio = clampf(body.velocity.length() / reference_speed, 0.0, 1.0)
	_intensity = lerpf(_intensity, speed_ratio, 1.0 - exp(-settle_rate * delta))
	if speed_ratio > 0.01:
		# abs(sin) has period PI, so PI per step = one hop per footstep.
		_phase = fmod(_phase + PI * steps_per_second * delta, TAU)
	apply_pose(_phase, _intensity)


func apply_pose(phase: float, intensity: float) -> void:
	position.y = hop_offset(phase, hop_height * intensity)
	scale = squash_scale(phase, squash_amount * intensity)
	if shadow:
		var air := absf(sin(phase)) * intensity
		shadow.scale = Vector2.ONE * (1.0 - 0.2 * air)


## Vertical offset (negative = up) for the given step phase.
static func hop_offset(phase: float, amplitude: float) -> float:
	return -absf(sin(phase)) * amplitude


## Squash on landing, stretch in the air, roughly preserving area.
static func squash_scale(phase: float, amount: float) -> Vector2:
	var contact := pow(1.0 - absf(sin(phase)), 3.0)  # 1 on the ground, 0 at apex
	var k := amount * (contact * 2.0 - 1.0)  # +amount landing, -amount at apex
	return Vector2(1.0 + k, 1.0 / (1.0 + k))
