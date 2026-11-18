class_name ItemCatalog
extends RefCounted
## Granny's materials: id -> display name and icon.

const TOWN := preload("res://assets/kenney/tiny_town/tilemap_packed.png")
const FARM := preload("res://assets/kenney/tiny_farm/tilemap_packed.png")
const OSSO := preload("res://assets/custom/osso.png")

const ITEMS := {
	&"cogumelo": {"name": "cogumelo", "texture": TOWN, "region": Rect2(5 * 16, 2 * 16, 16, 16)},
	&"musgo": {"name": "musgo de árvore morta", "texture": FARM, "region": Rect2(5 * 16, 5 * 16, 16, 16)},
	&"osso": {"name": "osso", "texture": OSSO, "region": Rect2(0, 0, 16, 16)},
}


static func display_name(id: StringName) -> String:
	return ITEMS[id].name if ITEMS.has(id) else String(id)


static func texture(id: StringName) -> Texture2D:
	return ITEMS[id].texture if ITEMS.has(id) else null


static func region(id: StringName) -> Rect2:
	return ITEMS[id].region if ITEMS.has(id) else Rect2()
