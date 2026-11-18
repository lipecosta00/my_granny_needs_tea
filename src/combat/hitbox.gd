class_name Hitbox
extends Area2D
## Deals hits while active. Polls overlaps every physics frame instead of
## relying on area_entered, so a target already overlapping when the swing
## starts is still hit, and each target is hit at most once per activation.

signal landed(hurtbox: Hurtbox, hit: HitData)

@export var team := HitData.Team.HERO
## Contact hitboxes (enemy bodies) re-arm per target after this many seconds.
@export var rehit_interval := 0.0

## Builds the HitData for a given target; set by the owner per attack.
var hit_factory: Callable
var active := false:
	set(value):
		active = value
		if active:
			_already_hit.clear()

var _already_hit := {}  # Hurtbox -> seconds since hit


func _ready() -> void:
	monitoring = true
	monitorable = false


func _physics_process(delta: float) -> void:
	for target: Variant in _already_hit.keys():
		if not is_instance_valid(target):
			_already_hit.erase(target)
			continue
		_already_hit[target] += delta
		if rehit_interval > 0.0 and _already_hit[target] >= rehit_interval:
			_already_hit.erase(target)
	if not active or not hit_factory.is_valid():
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.team == team or _already_hit.has(hurtbox):
			continue
		var hit: HitData = hit_factory.call(hurtbox)
		if hurtbox.receive(hit):
			_already_hit[hurtbox] = 0.0
			landed.emit(hurtbox, hit)
