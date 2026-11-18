extends Node
## Progress that outlives a map: granny's requests, items, pets, weapons,
## opened gates and chests, and where the player is. Serializable: the
## auto-save on map change is SaveSystem.write(to_dict()).

signal changed

const SAVE_VERSION := 1
const STARTING_WEAPON := &"sword"
const START_MAP := &"casa"

## Granny's requests (GDD "Pedidos da vó"): stage -> material, pet created.
## Stage 0 = haven't met granny yet; she gives the Vagalume on the first visit.
const REQUESTS := [
	{"item": &"cogumelo", "reward_pet": &"barqueira"},
	{"item": &"musgo", "reward_pet": &"toupeira"},
	{"item": &"osso", "reward_pet": &""},
]

var opened_gates := {}
var unlocked_pets: Array[StringName] = []
var active_pet: StringName = &""
## 0 = not met granny; 1..3 = request N active; 4 = all delivered (tea time).
var quest_stage := 0
var items := {}
var picked_pickups := {}
var current_map: StringName = START_MAP
var current_spawn: StringName = &"Default"
var owned_weapons: Array[StringName] = []
## [slot I, slot II]; &"" = empty.
var equipped_weapons: Array[StringName] = []
var opened_chests := {}


func _init() -> void:
	reset()


func reset() -> void:
	opened_gates = {}
	unlocked_pets = []
	active_pet = &""
	quest_stage = 0
	items = {}
	picked_pickups = {}
	current_map = START_MAP
	current_spawn = &"Default"
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


func unlock_pet(id: StringName) -> void:
	if id == &"" or id in unlocked_pets:
		return
	unlocked_pets.append(id)
	if active_pet == &"":
		active_pet = id
	changed.emit()


## The material granny is currently asking for (&"" when none).
func requested_item() -> StringName:
	if quest_stage < 1 or quest_stage > REQUESTS.size():
		return &""
	return REQUESTS[quest_stage - 1].item


func has_item(id: StringName) -> bool:
	return items.has(id)


func pick_up(pickup_id: StringName, item: StringName) -> void:
	picked_pickups[pickup_id] = true
	items[item] = true
	changed.emit()


func is_picked(pickup_id: StringName) -> bool:
	return picked_pickups.has(pickup_id)


## Hands the requested item to granny; returns the pet she creates.
func deliver_requested() -> StringName:
	var item := requested_item()
	if item == &"" or not has_item(item):
		return &""
	items.erase(item)
	var reward: StringName = REQUESTS[quest_stage - 1].reward_pet
	quest_stage += 1
	unlock_pet(reward)
	changed.emit()
	return reward


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
		"quest_stage": quest_stage,
		"items": items.keys().map(func(id: StringName) -> String: return String(id)),
		"picked_pickups": picked_pickups.keys().map(func(id: StringName) -> String: return String(id)),
		"current_map": String(current_map),
		"current_spawn": String(current_spawn),
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
	var active := StringName(data.get("active_pet", ""))
	active_pet = active if active in unlocked_pets else (unlocked_pets[0] if not unlocked_pets.is_empty() else &"")
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
	quest_stage = int(data.get("quest_stage", 0))
	for id: String in data.get("items", []):
		items[StringName(id)] = true
	for id: String in data.get("picked_pickups", []):
		picked_pickups[StringName(id)] = true
	current_map = StringName(data.get("current_map", String(START_MAP)))
	current_spawn = StringName(data.get("current_spawn", "Default"))
	changed.emit()
