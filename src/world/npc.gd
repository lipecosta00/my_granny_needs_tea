class_name Npc
extends StaticBody2D
## Character you can talk to (A / E). Sprite from the Tiny Dungeon sheet.

const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")

@export var npc_name := ""
@export var sprite_region := Rect2(48, 128, 16, 16)
@export var lines: PackedStringArray = []

var _sprite: Sprite2D
var _clock := 0.0


func _ready() -> void:
	add_to_group(&"interactables")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0, -3)
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = ATLAS
	_sprite.region_enabled = true
	_sprite.region_rect = sprite_region
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)


func _process(delta: float) -> void:
	_clock += delta
	# Idle breathing so NPCs don't look like props.
	_sprite.scale.y = 1.0 + sin(_clock * 2.5) * 0.04


func can_interact(_hero: Node) -> bool:
	return not Dialogue.active


func interact(hero: Node) -> void:
	if hero is Node2D:
		_sprite.flip_h = (hero as Node2D).global_position.x < global_position.x
	Dialogue.say(_speech(lines))


func _speech(texts: Array) -> Array:
	return texts.map(func(t: String) -> Dictionary: return {"name": npc_name, "text": t})
