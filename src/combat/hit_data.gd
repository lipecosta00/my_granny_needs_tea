class_name HitData
extends RefCounted
## One hit, from attacker to target. Plain data so damage rules stay testable.

enum Team { HERO, ENEMY }

var damage := 1
## Direction * speed (px/s) applied to the target's knockback.
var knockback := Vector2.ZERO
var team := Team.HERO
var source: Node
## Charged attacks get the bigger impact when they land on a stunned target.
var charged := false
## Stun applied on hit (0 = none). Pets will use this; hero attacks don't.
var stun_time := 0.0
## GDD: an enemy knocked into a wall by this hit gets stunned for 1 s.
## Charged attacks and pet pushes set it; plain swings don't.
var wall_stun := false


static func make(amount: int, push: Vector2, from_team: Team, from: Node = null) -> HitData:
	var hit := HitData.new()
	hit.damage = amount
	hit.knockback = push
	hit.team = from_team
	hit.source = from
	return hit


## GDD synergy: a stunned enemy takes double damage from the hero.
static func resolve_damage(hit: HitData, target_stunned: bool, stun_multiplier := 2) -> int:
	if target_stunned and hit.team == Team.HERO:
		return hit.damage * stun_multiplier
	return hit.damage


## Big impact (longer hitstop + screen shake) = charged hit on a stunned target.
static func is_big_impact(hit: HitData, target_stunned: bool) -> bool:
	return hit.charged and target_stunned
