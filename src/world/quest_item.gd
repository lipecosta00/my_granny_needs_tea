class_name QuestItem
extends Node2D
## A material for granny lying in the world. Walk over it to pick it up;
## picked items never come back (GameState).

signal picked(item: StringName)

@export var pickup_id: StringName
@export var item: StringName
@export var pickup_radius := 10.0

var _sprite: Sprite2D
var _clock := 0.0


func _ready() -> void:
	if GameState.is_picked(pickup_id):
		queue_free()
		return
	_sprite = Sprite2D.new()
	_sprite.texture = ItemCatalog.texture(item)
	_sprite.region_enabled = true
	_sprite.region_rect = ItemCatalog.region(item)
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	var glow := PointLight2D.new()
	glow.texture = preload("res://src/fx/soft_light.tres")
	glow.energy = 0.6
	glow.texture_scale = 0.4
	glow.color = Color(1.0, 0.95, 0.7)
	glow.position = Vector2(0, -8)
	add_child(glow)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _sprite:
		_sprite.position.y = -8.0 + sin(_clock * 3.0) * 1.5
	for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
		if hero.global_position.distance_to(global_position) <= pickup_radius:
			_pick()
			return


func _pick() -> void:
	GameState.pick_up(pickup_id, item)
	Fx.sfx(&"gate_open")
	Fx.burst(global_position + Vector2(0, -8), Color(1.0, 0.95, 0.6), 12, 60.0)
	picked.emit(item)
	Dialogue.say(["Você pegou: %s!" % ItemCatalog.display_name(item)])
	queue_free()
