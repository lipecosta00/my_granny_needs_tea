## Bakes the overworld TileSet and map scenes from ASCII layouts.
##
##   godot --headless --path . -s tools/bake_maps.gd
##
## Placeholder pipeline for Milestone 1: the real maps live in JSON with their
## own importer (GDD "Mundo"). When that importer is ported it should produce
## the same scene shape (GameMap > Ground + World/Objects + Spawns), so nothing
## downstream changes.
extends SceneTree

const TILESET_PATH := "res://src/world/tiles/overworld_tileset.tres"
const TILE := 16

enum Src { TOWN, FARM, BATTLE, DUNGEON }
const SOURCES := {
	Src.TOWN: "res://assets/kenney/tiny_town/tilemap_packed.png",
	Src.FARM: "res://assets/kenney/tiny_farm/tilemap_packed.png",
	Src.BATTLE: "res://assets/kenney/tiny_battle/tilemap_packed.png",
	Src.DUNGEON: "res://assets/kenney/tiny_dungeon/tilemap_packed.png",
}

## Collision presets, in tile-local pixels (origin = tile centre).
const FULL := [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
const TRUNK := [Vector2(-4, 0), Vector2(4, 0), Vector2(4, 8), Vector2(-4, 8)]
const ROUND := [Vector2(-6, -3), Vector2(6, -3), Vector2(6, 7), Vector2(-6, 7)]

## 9-slice origins (top-left of a 3x3 block) for autotiled terrains.
const NINE_SLICE := {
	"=": [Src.TOWN, Vector2i(0, 1)],     # dirt path
	"T": [Src.TOWN, Vector2i(9, 0)],     # autumn forest mass
	"~": [Src.BATTLE, Vector2i(0, 1)],   # lake with grass rim
}
## Terrains whose cells collide (all 9 slices).
const SOLID_TERRAINS := ["T", "~"]

## Single props: char -> [source, coords, collision, tall(2 tiles: coords is the trunk)]
const PROPS := {
	"a": [Src.TOWN, Vector2i(3, 1), TRUNK, true],    # autumn tree
	"p": [Src.FARM, Vector2i(3, 1), TRUNK, true],    # pine
	"d": [Src.FARM, Vector2i(2, 1), TRUNK, true],    # dead tree
	"m": [Src.TOWN, Vector2i(5, 2), [], false],      # mushrooms
	"b": [Src.TOWN, Vector2i(5, 0), ROUND, false],   # bush
	"r": [Src.FARM, Vector2i(5, 7), ROUND, false],   # rock
	"s": [Src.TOWN, Vector2i(11, 6), ROUND, false],  # sign
	"c": [Src.DUNGEON, Vector2i(5, 7), ROUND, false],  # chest (secret clearing)
	"\"": [Src.FARM, Vector2i(8, 6), [], false],     # tall grass (placeholder art)
}
## Enemy spawn markers: char -> EnemyCatalog id (ground under them is grass).
const ENEMIES := {
	"S": &"spider",
}
const GRASS := [Src.TOWN, Vector2i(0, 0)]
const GRASS_TUFT := [Src.TOWN, Vector2i(1, 0)]
const FLOWERS := [Src.TOWN, Vector2i(2, 0)]

const MAPS := [
	{
		"name": "DarkForest",
		"layout": "res://src/world/maps/dark_forest/dark_forest.layout.txt",
		"out": "res://src/world/maps/dark_forest/dark_forest.tscn",
		"tint": Color(0.42, 0.36, 0.58),
		# PetGates: rect in cells. Darkness on the west exit to the Bosque
		# dos Cogumelos, cleared by the Vagalume's Luz (GDD "Mundo").
		"gates": [
			{"id": &"dark_forest/bosque_darkness", "ability": &"light", "rect": Rect2i(0, 15, 3, 4)},
		],
	},
]


## Gameplay scripts are loaded at runtime, not referenced by class name: this
## main-loop script compiles before autoloads (Fx, GameState) exist, and
## static references would drag those scripts into that early compile.
const GAME_MAP_SCRIPT := "res://src/world/game_map.gd"
const PET_GATE_SCRIPT := "res://src/world/pet_gate.gd"
const DEFAULT_SPAWN := "Default"  # GameMap.DEFAULT_SPAWN


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var tileset := build_tileset()
	var err := save_deterministic(tileset, TILESET_PATH)
	if err != OK:
		push_error("tileset save failed: %s" % error_string(err))
		quit(1)
		return
	tileset = load(TILESET_PATH)
	for spec: Dictionary in MAPS:
		err = bake_map(spec, tileset)
		if err != OK:
			quit(1)
			return
	quit(0)


## Saves, then rewrites Godot's random resource ids ("1_x3x15") to stable ones
## so re-baking an unchanged layout yields a byte-identical file (CI check).
func save_deterministic(resource: Resource, path: String) -> Error:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		return err
	var text := FileAccess.get_file_as_string(path)
	var declared := RegEx.create_from_string('(?:ext_resource|sub_resource) [^\\]]*id="([^"]+)"')
	var renames := {}
	for m in declared.search_all(text):
		var old_id := m.get_string(1)
		if not renames.has(old_id):
			var prefix := old_id.split("_")[0]
			renames[old_id] = "%s_%d" % [prefix, renames.size() + 1]
	for old_id: String in renames:
		text = text.replace('"%s"' % old_id, '"%s"' % renames[old_id])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	return OK


# --- TileSet ---------------------------------------------------------------

func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)  # "world"
	ts.set_physics_layer_collision_mask(0, 0)
	for id: int in SOURCES:
		var atlas := TileSetAtlasSource.new()
		atlas.texture = load(SOURCES[id])
		atlas.texture_region_size = Vector2i(TILE, TILE)
		ts.add_source(atlas, id)

	_add_tile(ts, GRASS, [])
	_add_tile(ts, GRASS_TUFT, [])
	_add_tile(ts, FLOWERS, [])
	for terrain: String in NINE_SLICE:
		var src: int = NINE_SLICE[terrain][0]
		var origin: Vector2i = NINE_SLICE[terrain][1]
		var shape: Array = FULL if terrain in SOLID_TERRAINS else []
		for y in 3:
			for x in 3:
				_add_tile(ts, [src, origin + Vector2i(x, y)], shape)
	for ch: String in PROPS:
		var prop: Array = PROPS[ch]
		_add_tile(ts, [prop[0], prop[1]], prop[2])
		if prop[3]:
			# Canopy tile sorts with its trunk so the hero walks behind it.
			var top := _add_tile(ts, [prop[0], prop[1] + Vector2i.UP], [])
			top.y_sort_origin = TILE
	return ts


func _add_tile(ts: TileSet, ref: Array, shape: Array) -> TileData:
	var atlas := ts.get_source(ref[0]) as TileSetAtlasSource
	var coords: Vector2i = ref[1]
	if not atlas.has_tile(coords):
		atlas.create_tile(coords)
	var data := atlas.get_tile_data(coords, 0)
	if not shape.is_empty() and data.get_collision_polygons_count(0) == 0:
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, PackedVector2Array(shape))
	return data


# --- Map -------------------------------------------------------------------

func bake_map(spec: Dictionary, tileset: TileSet) -> Error:
	var rows := read_layout(spec.layout)
	if rows.is_empty():
		push_error("empty layout: %s" % spec.layout)
		return ERR_INVALID_DATA

	var root: Node2D = load(GAME_MAP_SCRIPT).new()
	root.name = spec.name

	var tint := CanvasModulate.new()
	tint.name = "NightTint"
	tint.color = spec.tint
	_own(root, root, tint)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tileset
	_own(root, root, ground)

	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	_own(root, root, world)

	var objects := TileMapLayer.new()
	objects.name = "Objects"
	objects.tile_set = tileset
	objects.y_sort_enabled = true
	_own(root, world, objects)

	var spawn := Vector2i(rows[0].length() / 2, rows.size() / 2)
	var enemy_cells: Array = []  # [cell, enemy id]
	for y in rows.size():
		for x in rows[y].length():
			var ch := rows[y][x]
			var cell := Vector2i(x, y)
			_paint_ground(ground, rows, cell, ch)
			if PROPS.has(ch):
				_put(objects, cell, [PROPS[ch][0], PROPS[ch][1]])
				if PROPS[ch][3]:
					_put(objects, cell + Vector2i.UP, [PROPS[ch][0], PROPS[ch][1] + Vector2i.UP])
			elif ch == "T":
				_put(objects, cell, _nine_slice("T", rows, cell))
			elif ch == "@":
				spawn = cell
			elif ENEMIES.has(ch):
				enemy_cells.append([cell, ENEMIES[ch]])

	var spawns := Node2D.new()
	spawns.name = "Spawns"
	_own(root, root, spawns)
	var default_spawn := Marker2D.new()
	default_spawn.name = DEFAULT_SPAWN
	default_spawn.position = _feet_position(spawn)
	_own(root, spawns, default_spawn)
	if not enemy_cells.is_empty():
		var enemies := Node2D.new()
		enemies.name = "Enemies"
		_own(root, spawns, enemies)
		for entry: Array in enemy_cells:
			var marker := Marker2D.new()
			marker.name = "%s_%d_%d" % [entry[1], entry[0].x, entry[0].y]
			marker.position = _feet_position(entry[0])
			marker.set_meta(&"enemy", entry[1])
			_own(root, enemies, marker)

	var gate_specs: Array = spec.get("gates", [])
	if not gate_specs.is_empty():
		var gates := Node2D.new()
		gates.name = "Gates"
		_own(root, root, gates)
		for gate_spec: Dictionary in gate_specs:
			var gate: StaticBody2D = load(PET_GATE_SCRIPT).new()
			gate.name = String(gate_spec.id).get_file().to_pascal_case()
			gate.gate_id = gate_spec.id
			gate.required_ability = gate_spec.ability
			var rect: Rect2i = gate_spec.rect
			gate.position = Vector2(rect.position * TILE)
			gate.size = Vector2(rect.size * TILE)
			_own(root, gates, gate)

	root.ground = ground
	root.actors = world
	root.spawns = spawns

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = save_deterministic(packed, spec.out)
	print("%s: %dx%d tiles, spawn %s -> %s (%s)" % [
		spec.name, rows[0].length(), rows.size(), spawn, spec.out, error_string(err)])
	root.free()
	return err


## Actor origin is at the feet: slightly above the cell's bottom edge.
func _feet_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE - 2.0)


func _paint_ground(ground: TileMapLayer, rows: PackedStringArray, cell: Vector2i, ch: String) -> void:
	match ch:
		"=", "~":
			_put(ground, cell, _nine_slice(ch, rows, cell))
		"@":
			# Spawn sits on whatever terrain surrounds it (path here).
			_put(ground, cell, _nine_slice("=", rows, cell, "@"))
		"*":
			_put(ground, cell, FLOWERS)
		_:
			# Deterministic sprinkle of tufts so the grass is not a flat sheet.
			_put(ground, cell, GRASS_TUFT if hash(cell) % 7 == 0 else GRASS)


## Picks the 3x3 slice from orthogonal neighbours. Out-of-bounds counts as the
## same terrain so masses and paths run cleanly off the map edge.
func _nine_slice(terrain: String, rows: PackedStringArray, cell: Vector2i, alias := "") -> Array:
	var same := func(c: Vector2i) -> bool:
		if c.y < 0 or c.y >= rows.size() or c.x < 0 or c.x >= rows[c.y].length():
			return true
		var other := rows[c.y][c.x]
		return other == terrain or (alias != "" and other == alias) or (terrain == "=" and other == "@")
	var col := 1
	var row := 1
	if not same.call(cell + Vector2i.LEFT):
		col = 0
	elif not same.call(cell + Vector2i.RIGHT):
		col = 2
	if not same.call(cell + Vector2i.UP):
		row = 0
	elif not same.call(cell + Vector2i.DOWN):
		row = 2
	return [NINE_SLICE[terrain][0], NINE_SLICE[terrain][1] + Vector2i(col, row)]


func _put(layer: TileMapLayer, cell: Vector2i, ref: Array) -> void:
	layer.set_cell(cell, ref[0], ref[1])


func _own(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root


func read_layout(path: String) -> PackedStringArray:
	var text := FileAccess.get_file_as_string(path)
	var rows := PackedStringArray()
	for line in text.split("\n"):
		if not line.strip_edges().is_empty():
			rows.append(line.strip_edges(false, true))
	return rows
