class_name WeaponData
extends Resource
## Tuning for one weapon (GDD "Armas do MVP"). One .tres per weapon, so the
## axe/staff of Milestone 4 are data, not new hero code.

enum Charged { DASH, SPIN, FAN }

@export var id: StringName
@export var display_name := ""
## Region in the Tiny Dungeon atlas (GDD coordinates * 16).
@export var sprite_region := Rect2(128, 128, 16, 16)

@export_group("Normal attack")
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
