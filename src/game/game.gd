class_name Game
extends Node
## Root of a play session: owns the hero, pet, camera and HUD, and loads maps
## by id. Map exits fade to the next map and auto-save (GDD "Salvamento").
## Game over (GDD): "Os pets te levam de volta" — restart at the last map
## entrance with full health and no item loss.

@export var start_map: StringName = &"casa"
## Off in tests: never read or write the player's save.
@export var use_save := true
@export var hero: Hero
@export var camera: FollowCamera
@export var hearts: HeartsBar
@export var pet_portrait: PetPortrait
@export var weapon_slots: WeaponSlots
@export var pet_select: PetSelect
## Seconds the defeated hero stays on screen before respawning.
@export var respawn_delay := 1.2
@export var fade_time := 0.18

var current_map: GameMap
var current_map_id: StringName
var pet: Pet
var _current_spawn: StringName = GameMap.DEFAULT_SPAWN
var _changing := false
var _fade: ColorRect


func _ready() -> void:
	add_to_group(&"game")
	var resumed := use_save and SaveSystem.has_save()
	if resumed:
		GameState.from_dict(SaveSystem.read())
	hero.died.connect(_on_hero_died)
	if hearts:
		hearts.bind(hero.health)
	_sync_weapons_from_state()
	GameState.changed.connect(_sync_weapons_from_state)
	hero.weapons_changed.connect(_on_hero_weapons_changed)
	if weapon_slots:
		weapon_slots.bind(hero)
	if pet_select:
		pet_select.chosen.connect(_on_pet_chosen)
		pet_select.cancelled.connect(func() -> void: hero.input_enabled = true)
	_build_fade()
	if GameState.active_pet != &"":
		set_active_pet(GameState.active_pet)
	if OS.is_debug_build() and _apply_debug_args():
		return
	if resumed:
		load_map(GameState.current_map, GameState.current_spawn)
	else:
		load_map(start_map)


func load_map(map_id: StringName, spawn_name: StringName = GameMap.DEFAULT_SPAWN) -> void:
	var scene := MapCatalog.load_scene(map_id)
	if scene == null:
		return
	if current_map:
		hero.reparent(self, false)
		if pet:
			pet.reparent(self, false)
		current_map.queue_free()
	current_map_id = map_id
	_current_spawn = spawn_name
	current_map = scene.instantiate() as GameMap
	assert(current_map != null, "map scene root must extend GameMap")
	add_child(current_map)
	move_child(current_map, 0)
	current_map.exit_requested.connect(change_map)
	hero.reparent(current_map.actors, false)
	hero.global_position = current_map.get_spawn_position(spawn_name)
	hero.velocity = Vector2.ZERO
	if pet:
		pet.reparent(current_map.actors, false)
		pet.snap_to_hero()
	camera.target = hero
	camera.set_bounds(current_map.get_bounds())
	camera.global_position = hero.global_position
	camera.reset_smoothing()
	GameState.current_map = map_id
	GameState.current_spawn = spawn_name
	if use_save:
		SaveSystem.write(GameState.to_dict())


## Map exit: fade out, swap maps, fade in. Input is off during the swap.
func change_map(map_id: StringName, spawn_name: StringName) -> void:
	if _changing:
		return
	_changing = true
	hero.input_enabled = false
	await _fade_to(1.0)
	load_map(map_id, spawn_name)
	await _fade_to(0.0)
	hero.input_enabled = true
	_changing = false


## Swaps the companion (granny's cauldron).
func set_active_pet(pet_id: StringName) -> void:
	if pet:
		pet.queue_free()
		pet = null
	pet = PetCatalog.instantiate(pet_id)
	if pet == null:
		return
	GameState.active_pet = pet_id
	var parent: Node = current_map.actors if current_map else self
	parent.add_child(pet)
	pet.attach(hero)
	if pet_portrait:
		pet_portrait.bind(pet)


func open_pet_select() -> void:
	if pet_select == null:
		return
	hero.input_enabled = false
	pet_select.open(GameState.unlocked_pets, GameState.active_pet)


func _on_pet_chosen(pet_id: StringName) -> void:
	hero.input_enabled = true
	if pet_id != GameState.active_pet:
		set_active_pet(pet_id)
		Fx.sfx(&"flash")
		Fx.burst(pet.global_position + Vector2(0, -12), pet.color, 12, 60.0)


## GameState is the source of truth for the inventory; the hero mirrors it.
func _sync_weapons_from_state() -> void:
	hero.owned_weapons = WeaponCatalog.ordered(GameState.owned_weapons)
	var primary := WeaponCatalog.get_weapon(GameState.equipped_weapons[0])
	var secondary := WeaponCatalog.get_weapon(GameState.equipped_weapons[1])
	if primary != hero.primary_weapon or secondary != hero.secondary_weapon:
		hero.primary_weapon = primary
		hero.secondary_weapon = secondary
		hero.weapons_changed.emit(primary, secondary)


func _on_hero_weapons_changed(primary: WeaponData, secondary: WeaponData) -> void:
	var ids := [primary.id if primary else &"", secondary.id if secondary else &""]
	if ids != GameState.equipped_weapons:
		GameState.set_equipped(ids[0], ids[1])


func _on_hero_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	await _fade_to(1.0)
	load_map(current_map_id, _current_spawn)
	hero.revive()
	if pet:
		pet.restore()
	await _fade_to(0.0)


## Debug builds only: --map=<id> [--spawn=<name>] [--pets=all] jumps
## straight to a map (handy for playtesting one area).
func _apply_debug_args() -> bool:
	var args := {}
	for arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			args[arg.substr(2, arg.find("=") - 2)] = arg.substr(arg.find("=") + 1)
	if not args.has("map"):
		return false
	if args.get("pets", "") == "all":
		GameState.quest_stage = 3
		for pet_id: StringName in PetCatalog.SCENES:
			GameState.unlock_pet(pet_id)
		set_active_pet(GameState.active_pet)
	# Without --spawn, arrive the way a player would (from the forest).
	var scene := MapCatalog.load_scene(StringName(args.map))
	var spawn := String(args.get("spawn", ""))
	if spawn == "":
		var probe := scene.instantiate() as GameMap
		spawn = "from_floresta" if probe.spawns.has_node(^"from_floresta") else "Default"
		probe.free()
	load_map(StringName(args.map), StringName(spawn))
	return true


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.04, 0.02, 0.06, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _fade_to(alpha: float) -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
