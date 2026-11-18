extends Node
## Progress that outlives a map: pets created by granny, the active pet and
## gates opened by pets (GDD: "portão aberto fica aberto"). Serializable so
## the auto-save on map change (Milestone 4) is just to_dict/from_dict.

signal changed

const SAVE_VERSION := 1
const STARTING_PET := &"vagalume"

var opened_gates := {}
var unlocked_pets: Array[StringName] = []
var active_pet: StringName = STARTING_PET


func _init() -> void:
	reset()


func reset() -> void:
	opened_gates = {}
	unlocked_pets = [STARTING_PET]
	active_pet = STARTING_PET
	changed.emit()


func is_gate_open(gate_id: StringName) -> bool:
	return opened_gates.has(gate_id)


func open_gate(gate_id: StringName) -> void:
	if gate_id == &"" or opened_gates.has(gate_id):
		return
	opened_gates[gate_id] = true
	changed.emit()


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"opened_gates": opened_gates.keys().map(func(id: StringName) -> String: return String(id)),
		"unlocked_pets": unlocked_pets.map(func(id: StringName) -> String: return String(id)),
		"active_pet": String(active_pet),
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
	changed.emit()
