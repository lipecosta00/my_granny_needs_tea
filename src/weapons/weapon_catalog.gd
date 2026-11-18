class_name WeaponCatalog
extends RefCounted
## Weapon id (GameState inventory, save data) -> WeaponData. Order = wheel
## order (clockwise from the top).

const WEAPONS := {
	&"sword": preload("res://src/weapons/sword.tres"),
	&"axe": preload("res://src/weapons/axe.tres"),
	&"staff": preload("res://src/weapons/staff.tres"),
}


static func get_weapon(id: StringName) -> WeaponData:
	return WEAPONS.get(id)


## Owned weapons in catalog order (stable wheel layout).
static func ordered(owned: Array) -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for id: StringName in WEAPONS:
		if id in owned:
			result.append(WEAPONS[id])
	return result
