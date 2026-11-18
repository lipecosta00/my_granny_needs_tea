class_name Projectile
extends Hitbox
## Flying hit (Vagalume sparks, staff bolts). Optional homing toward
## [member target]; pops on its first hit, on level geometry or when its
## lifetime ends. Configure before adding to the tree.

var direction := Vector2.RIGHT
var target: Node2D
## 0 = straight line (staff); > 0 = homing (sparks).
var turn_rate := 0.0
var speed := 170.0
var damage := 1
var knockback := 60.0
var lifetime := 1.0
var from_pet := false
var source: Node
var color := Color(1.0, 0.95, 0.5)
var radius := 3.0


func _ready() -> void:
	super()
	collision_layer = 0
	# Enemy hurtboxes when thrown by the hero side, hero hurtboxes otherwise.
	collision_mask = 32 if team == HitData.Team.HERO else 16
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	direction = direction.normalized()
	if is_instance_valid(target):
		direction = (_aim_point() - global_position).normalized()
	hit_factory = func(_hurtbox: Hurtbox) -> HitData:
		var hit := HitData.make(damage, direction * knockback, team, source)
		hit.from_pet = from_pet
		return hit
	landed.connect(func(_hurtbox: Hurtbox, _hit: HitData) -> void: pop())
	active = true


func _physics_process(delta: float) -> void:
	if turn_rate > 0.0 and is_instance_valid(target):
		var wanted := (_aim_point() - global_position).normalized()
		direction = direction.slerp(wanted, clampf(turn_rate * delta, 0.0, 1.0)).normalized()
	var from := global_position
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0 or _hit_world(from, global_position):
		pop()
		return
	super(delta)


## Ray from the previous position: trees/walls stop it without tunnelling.
## (Area2D overlap doesn't report static level geometry reliably.)
func _hit_world(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius - 0.5, Color(color, 0.6))
	draw_circle(Vector2.ZERO, radius * 0.4, Color.WHITE)


func pop() -> void:
	if is_queued_for_deletion():
		return
	active = false
	Fx.burst(global_position, color, 4, 40.0)
	queue_free()


func _aim_point() -> Vector2:
	return target.global_position + Vector2(0, -6)
