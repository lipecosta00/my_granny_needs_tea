class_name WeaponData
extends Resource
## Tuning for one weapon (GDD "Armas do MVP"). One .tres per weapon, so the
## axe/staff of Milestone 4 are data, not new hero code.

enum Normal { SWING, PROJECTILE }
enum Charged { DASH, SPIN, FAN }

@export var id: StringName
@export var display_name := ""
## Region in the Tiny Dungeon atlas (GDD coordinates * 16).
@export var sprite_region := Rect2(128, 128, 16, 16)

@export_group("Normal attack")
@export var normal_kind := Normal.SWING
@export var damage := 1
@export var swing_arc_degrees := 140.0
@export var swing_duration := 0.15
## Time after the swing before the hero can act again (buffer covers it).
@export var recovery := 0.06
@export var reach := 13.0
@export var hit_radius := 10.0
@export var knockback := 150.0

@export_group("Charged attack")
@export var charged_kind := Charged.DASH
@export var charged_damage := 3
@export var charge_time := 0.6
@export var charged_knockback := 230.0
@export var dash_speed := 260.0
@export var dash_duration := 0.16
## SPIN: 360° around the hero.
@export var spin_duration := 0.4
@export var spin_radius := 20.0

@export_group("Projectile")
@export var projectile_speed := 200.0
## Range = speed * lifetime (0.6 s * 200 = 7.5 tiles).
@export var projectile_lifetime := 0.6
@export var projectile_color := Color(0.5, 0.75, 1.0)
## FAN: number of bolts and total spread.
@export var fan_count := 3
@export var fan_spread_degrees := 30.0
