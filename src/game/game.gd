class_name Game
extends Node
## Root of a play session: owns the hero, camera and HUD, loads maps into
## itself. Game over (GDD): "Os pets te levam de volta" — restart at the last
## map entrance with full health and no item loss.

@export var start_map: PackedScene
@export var hero: Hero
@export var camera: FollowCamera
@export var hearts: HeartsBar
@export var pet_portrait: PetPortrait
## Seconds the defeated hero stays on screen before respawning.
@export var respawn_delay := 1.2

var current_map: GameMap
var pet: Pet
var _current_scene: PackedScene
var _current_spawn: StringName = GameMap.DEFAULT_SPAWN


func _ready() -> void:
	hero.died.connect(_on_hero_died)
	if hearts:
		hearts.bind(hero.health)
	set_active_pet(GameState.active_pet)
	if start_map:
		load_map(start_map)


func load_map(scene: PackedScene, spawn_name: StringName = GameMap.DEFAULT_SPAWN) -> void:
	if current_map:
		hero.reparent(self, false)
		if pet:
			pet.reparent(self, false)
		current_map.queue_free()
	_current_scene = scene
	_current_spawn = spawn_name
	current_map = scene.instantiate() as GameMap
	assert(current_map != null, "map scene root must extend GameMap")
	add_child(current_map)
	move_child(current_map, 0)
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


## Swaps the companion (granny's cauldron calls this in Milestone 4).
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


func _on_hero_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	load_map(_current_scene, _current_spawn)
	hero.revive()
	if pet:
		pet.restore()
