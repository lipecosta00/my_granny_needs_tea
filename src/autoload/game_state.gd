extends Node
## Progress that outlives a map: pets created by granny, the active pet and
## gates opened by pets (GDD: "portão aberto fica aberto"). Serializable so
## the auto-save on map change (Milestone 4) is just to_dict/from_dict.

signal changed

const SAVE_VERSION := 1
const STARTING_PET := &"vagalume"
const STARTING_WEAPON := &"sword"

var opened_gates := {}
var unlocked_pets: Array[StringName] = []
var active_pet: StringName = STARTING_PET
var owned_weapons: Array[StringName] = []
## [slot I, slot II]; &"" = empty.
var equipped_weapons: Array[StringName] = []
var opened_chests := {}


func _init() -> void:
	reset()


func reset() -> void:
	opened_gates = {}
	unlocked_pets = [STARTING_PET]
	active_pet = STARTING_PET
	owned_weapons = [STARTING_WEAPON]
	equipped_weapons = [STARTING_WEAPON, &""]
	opened_chests = {}
	changed.emit()


func is_gate_open(gate_id: StringName) -> bool:
	return opened_gates.has(gate_id)


func open_gate(gate_id: StringName) -> void:
	if gate_id == &"" or opened_gates.has(gate_id):
		return
	opened_gates[gate_id] = true
	changed.emit()


func give_weapon(id: StringName) -> void:
	if id in owned_weapons:
		return
	owned_weapons.append(id)
	if equipped_weapons[1] == &"":
		equipped_weapons[1] = id
	changed.emit()


func set_equipped(primary: StringName, secondary: StringName) -> void:
	equipped_weapons = [primary, secondary]
	changed.emit()


func is_chest_opened(chest_id: StringName) -> bool:
	return opened_chests.has(chest_id)


func mark_chest_opened(chest_id: StringName) -> void:
	opened_chests[chest_id] = true
	changed.emit()


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"opened_gates": opened_gates.keys().map(func(id: StringName) -> String: return String(id)),
		"unlocked_pets": unlocked_pets.map(func(id: StringName) -> String: return String(id)),
		"active_pet": String(active_pet),
		"owned_weapons": owned_weapons.map(func(id: StringName) -> String: return String(id)),
		"equipped_weapons": equipped_weapons.map(func(id: StringName) -> String: return String(id)),
		"opened_chests": opened_chests.keys().map(func(id: StringName) -> String: return String(id)),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	for id: String in data.get("opened_gates", []):
		opened_gates[StringName(id)] = true
	var pets: Array = data.get("unlocked_pets", [])
	if not pets.is_empty():
		unlocked_pets.clear()
		for id: String in pets:
			unlocked_pets.append(StringName(id))
	var active := StringName(data.get("active_pet", String(STARTING_PET)))
	active_pet = active if active in unlocked_pets else unlocked_pets[0]
	var weapons: Array = data.get("owned_weapons", [])
	if not weapons.is_empty():
		owned_weapons.clear()
		for id: String in weapons:
			owned_weapons.append(StringName(id))
	var equipped: Array = data.get("equipped_weapons", [])
	if equipped.size() == 2:
		equipped_weapons = []
		for id: String in equipped:
			equipped_weapons.append(StringName(id) if StringName(id) in owned_weapons else &"")
	for id: String in data.get("opened_chests", []):
		opened_chests[StringName(id)] = true
	changed.emit()
