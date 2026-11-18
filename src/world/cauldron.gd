class_name Cauldron
extends StaticBody2D
## Granny's cauldron: where pets are born and the only place to swap them
## (GDD "Troca de pet").

const ATLAS := preload("res://assets/kenney/tiny_town/tilemap_packed.png")
const REGION := Rect2(10 * 16, 10 * 16, 16, 16)

var _bubble_timer := 0.0


func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"cauldron")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 8)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = ATLAS
	sprite.region_enabled = true
	sprite.region_rect = REGION
	sprite.position = Vector2(0, -8)
	add_child(sprite)
	var glow := PointLight2D.new()
	glow.texture = preload("res://src/fx/soft_light.tres")
	glow.color = Color(0.5, 1.0, 0.7)
	glow.energy = 0.7
	glow.texture_scale = 0.7
	glow.position = Vector2(0, -12)
	add_child(glow)


func _process(delta: float) -> void:
	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		_bubble_timer = randf_range(0.4, 0.9)
		Fx.burst(global_position + Vector2(randf_range(-3, 3), -14), Color(0.6, 1.0, 0.7), 2, 15.0)


func can_interact(_hero: Node) -> bool:
	return not Dialogue.active


func interact(_hero: Node) -> void:
	if GameState.unlocked_pets.size() >= 2:
		get_tree().call_group(&"game", &"open_pet_select")
	else:
		Dialogue.say(["O caldeirão borbulha. Cheira a... chá?"])
