class_name Rat
extends Enemy
## GDD: "Anda em bando de 3" — teaches the axe against groups. Chases the
## hero with short scurries and keeps a little distance from its pack mates.

@export var chase_speed := 58.0
@export var scurry_period := 0.5
@export var separation := 12.0


func _behaviour(_delta: float) -> void:
	var hero := find_hero(detect_radius * 1.3)
	var desired := Vector2.ZERO
	if hero:
		var to_hero := hero.global_position - global_position
		# Scurry: move in bursts, pause briefly between them.
		var moving := fmod(_clock, scurry_period) < scurry_period * 0.7
		desired = to_hero.normalized() * (chase_speed if moving else chase_speed * 0.2)
	for other: Node2D in get_tree().get_nodes_in_group(&"rats"):
		if other == self:
			continue
		var away := global_position - other.global_position
		var d := away.length()
		if d > 0.01 and d < separation:
			desired += away / d * (separation - d) * 6.0
	velocity = desired


func _ready() -> void:
	super()
	add_to_group(&"rats")
