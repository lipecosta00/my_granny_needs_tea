class_name Spark
extends Hitbox
## Homing projectile for the Vagalume's auto attack. Reuses Hitbox detection
## (one hit, then pops).

var target: Node2D
var speed := 170.0
var turn_rate := 9.0
var damage := 1
var lifetime := 1.0
var source: Node
var color := Color(1.0, 0.95, 0.5)
var _direction := Vector2.RIGHT


func _ready() -> void:
	super()
	team = HitData.Team.HERO
	collision_layer = 0
	collision_mask = 32  # enemy_hurtbox
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	if is_instance_valid(target):
		_direction = (_aim_point() - global_position).normalized()
	hit_factory = func(_hurtbox: Hurtbox) -> HitData:
		var hit := HitData.make(damage, _direction * 60.0, HitData.Team.HERO, source)
		hit.from_pet = true
		return hit
	landed.connect(func(_hurtbox: Hurtbox, _hit: HitData) -> void: _pop())
	active = true


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var wanted := (_aim_point() - global_position).normalized()
		_direction = _direction.slerp(wanted, clampf(turn_rate * delta, 0.0, 1.0)).normalized()
	global_position += _direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_pop()
		return
	super(delta)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.5, Color(color, 0.6))
	draw_circle(Vector2.ZERO, 1.2, Color.WHITE)


func _aim_point() -> Vector2:
	return target.global_position + Vector2(0, -6)


func _pop() -> void:
	if is_queued_for_deletion():
		return
	active = false
	Fx.burst(global_position, color, 4, 40.0)
	queue_free()
