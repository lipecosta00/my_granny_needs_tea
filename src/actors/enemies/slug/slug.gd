class_name SlimeSlug
extends Enemy
## GDD: "Lenta, deixa rastro que deixa o herói mais devagar" — teaches
## positioning. Crawls toward the hero leaving slime puddles behind.

@export var crawl_speed := 14.0
@export var puddle_interval := 0.45
@export var puddle_lifetime := 4.0
## Hero speed multiplier inside the slime.
@export var slow_factor := 0.5

var _puddle_timer := 0.0


func _behaviour(delta: float) -> void:
	var hero := find_hero(detect_radius * 1.2)
	if hero:
		velocity = (hero.global_position - global_position).normalized() * crawl_speed
	else:
		velocity = Vector2.from_angle(_clock * 0.4) * crawl_speed * 0.5
	_puddle_timer -= delta
	if _puddle_timer <= 0.0 and velocity.length() > 1.0:
		_puddle_timer = puddle_interval
		var puddle := SlimePuddle.new()
		puddle.lifetime = puddle_lifetime
		puddle.slow_factor = slow_factor
		puddle.global_position = global_position
		get_parent().add_child(puddle)
		get_parent().move_child(puddle, 0)  # under the actors
