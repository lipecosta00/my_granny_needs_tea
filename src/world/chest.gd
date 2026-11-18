class_name Chest
extends StaticBody2D
## Treasure chest (Tiny Dungeon). Interact (A / E) to take its item; opened
## chests stay open (GameState), like gates.

const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
const CLOSED := Rect2(5 * 16, 7 * 16, 16, 16)
const OPEN := Rect2(6 * 16, 7 * 16, 16, 16)

signal opened(item: StringName)

@export var chest_id: StringName
## Weapon id from WeaponCatalog.
@export var item: StringName

var is_open := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group(&"interactables")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.region_enabled = true
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	is_open = GameState.is_chest_opened(chest_id)
	_sprite.region_rect = OPEN if is_open else CLOSED


func can_interact(_hero: Node) -> bool:
	return not is_open


func interact(_hero: Node) -> void:
	if is_open:
		return
	is_open = true
	_sprite.region_rect = OPEN
	GameState.mark_chest_opened(chest_id)
	if item != &"":
		GameState.give_weapon(item)
	Fx.sfx(&"gate_open")
	Fx.burst(global_position + Vector2(0, -10), Color(1.0, 0.9, 0.4), 10, 60.0)
	opened.emit(item)
