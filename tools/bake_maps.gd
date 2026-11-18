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

## Alternative tile id for walkable water under a bridge gate.
const BRIDGE_WATER_ALT := 1

## Collision presets, in tile-local pixels (origin = tile centre).
const FULL := [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
const TRUNK := [Vector2(-4, 0), Vector2(4, 0), Vector2(4, 8), Vector2(-4, 8)]
const ROUND := [Vector2(-6, -3), Vector2(6, -3), Vector2(6, 7), Vector2(-6, 7)]

## 9-slice origins (top-left of a 3x3 block) for autotiled terrains.
const NINE_SLICE := {
	"=": [Src.TOWN, Vector2i(0, 1)],     # dirt path
	"T": [Src.TOWN, Vector2i(9, 0)],     # autumn forest mass
	"F": [Src.TOWN, Vector2i(6, 0)],     # green forest mass (Bosque)
	"~": [Src.BATTLE, Vector2i(0, 1)],   # lake with grass rim
}
## Terrains whose cells collide (all 9 slices).
const SOLID_TERRAINS := ["T", "F", "~"]

## Single props: char -> [source, coords, collision, tall(2 tiles: coords is the trunk)]
const PROPS := {
	"a": [Src.TOWN, Vector2i(3, 1), TRUNK, true],    # autumn tree
	"p": [Src.FARM, Vector2i(3, 1), TRUNK, true],    # pine
	"d": [Src.FARM, Vector2i(2, 1), TRUNK, true],    # dead tree
	"m": [Src.TOWN, Vector2i(5, 2), [], false],      # mushrooms
	"b": [Src.TOWN, Vector2i(5, 0), ROUND, false],   # bush
	"r": [Src.FARM, Vector2i(5, 7), ROUND, false],   # rock
	"s": [Src.TOWN, Vector2i(11, 6), ROUND, false],  # sign
	"\"": [Src.FARM, Vector2i(8, 6), [], false],     # tall grass (placeholder art)
	"t": [Src.DUNGEON, Vector2i(5, 5), ROUND, false],  # tombstone
	"x": [Src.DUNGEON, Vector2i(4, 5), ROUND, false],  # cross grave
	"f": [Src.DUNGEON, Vector2i(5, 6), FULL, false],   # iron fence
	"w": [Src.TOWN, Vector2i(9, 6), ROUND, false],     # wooden fence
	"k": [Src.DUNGEON, Vector2i(3, 5), FULL, false],   # bookshelf
	"n": [Src.DUNGEON, Vector2i(0, 6), ROUND, false],  # table
}
## Enemy spawn markers: char -> EnemyCatalog id (ground under them is grass).
const ENEMIES := {
	"S": &"spider",
	"B": &"bat",
	"R": &"rat_pack",
	"G": &"slug",
	"K": &"crab",
	"E": &"specter",
	"I": &"specter_invisible",
	"C": &"cyclops",
}
const GRASS := [Src.TOWN, Vector2i(0, 0)]
const GRASS_TUFT := [Src.TOWN, Vector2i(1, 0)]
const FLOWERS := [Src.TOWN, Vector2i(2, 0)]

## Interior and village pieces.
const FLOOR := [Src.DUNGEON, Vector2i(0, 4)]
const FLOOR_ALT := [Src.DUNGEON, Vector2i(1, 4)]
const WALL := [Src.DUNGEON, Vector2i(10, 4)]
const DOOR := [Src.DUNGEON, Vector2i(9, 3)]

## Houses (village): char at the stamp's top-left; 3x3 cells; [cols][rows]
## of Tiny Town coords. The middle of the bottom row is the door (walkable).
const STAMPS := {
	"P": [[Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)],
		[Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)],
		[Vector2i(0, 7), Vector2i(1, 7), Vector2i(0, 7)]],  # player's house
	"V": [[Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)],
		[Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)],
		[Vector2i(4, 7), Vector2i(5, 7), Vector2i(4, 7)]],  # granny's house
	"H": [[Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)],
		[Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5)],
		[Vector2i(4, 7), Vector2i(5, 7), Vector2i(4, 7)]],  # neighbours
}

## Map specs. Cells are in tiles. Exits: rect + target map/spawn. Spawns:
## named arrival points (Default = '@' in the layout).
const MAPS := [
	{
		"id": &"casa", "name": "Casa", "interior": true,
		"tint": Color(0.95, 0.88, 0.8),
		"spawns": {"from_vila": Vector2i(6, 6)},
		"exits": [{"rect": Rect2i(6, 8, 1, 1), "map": &"vila", "spawn": &"from_casa"}],
		"npcs": [{"kind": "npc", "node": "Mom", "cell": Vector2i(8, 4), "name": "Mãe",
			"region": Rect2(48, 128, 16, 16), "dialogue": &"mom"}],
	},
	{
		"id": &"vila", "name": "Vila",
		"tint": Color(0.62, 0.55, 0.72),
		"spawns": {"from_casa": Vector2i(5, 10), "from_vo": Vector2i(22, 8), "from_floresta": Vector2i(14, 2)},
		"exits": [
			{"rect": Rect2i(5, 9, 1, 1), "map": &"casa", "spawn": &"from_vila", "facing": Vector2.UP},
			{"rect": Rect2i(22, 7, 1, 1), "map": &"casa_da_vo", "spawn": &"from_vila", "facing": Vector2.UP},
			{"rect": Rect2i(13, 0, 4, 1), "map": &"dark_forest", "spawn": &"from_vila"},
		],
	},
	{
		"id": &"casa_da_vo", "name": "CasaDaVo", "interior": true,
		"tint": Color(0.82, 0.74, 0.92),
		"spawns": {"from_vila": Vector2i(6, 7)},
		"exits": [{"rect": Rect2i(6, 9, 1, 1), "map": &"vila", "spawn": &"from_vo"}],
		"npcs": [{"kind": "granny", "node": "Granny", "cell": Vector2i(9, 4), "name": "Vó", "region": Rect2(0, 112, 16, 16)}],
		"cauldron": Vector2i(7, 3),
	},
	{
		"id": &"dark_forest", "name": "DarkForest",
		"tint": Color(0.42, 0.36, 0.58),
		"spawns": {"from_vila": Vector2i(23, 31), "from_bosque": Vector2i(4, 16),
			"from_pantano": Vector2i(43, 16), "from_cemiterio": Vector2i(23, 4)},
		"exits": [
			{"rect": Rect2i(21, 33, 6, 1), "map": &"vila", "spawn": &"from_floresta"},
			{"rect": Rect2i(0, 15, 1, 4), "map": &"bosque", "spawn": &"from_floresta"},
			{"rect": Rect2i(47, 15, 1, 4), "map": &"pantano", "spawn": &"from_floresta"},
			{"rect": Rect2i(21, 0, 6, 1), "map": &"cemiterio", "spawn": &"from_floresta"},
		],
		# Darkness on the way to the Bosque (Luz), fence before the cemetery (Túnel).
		"gates": [
			{"id": &"dark_forest/bosque_darkness", "ability": &"light", "rect": Rect2i(0, 15, 3, 4)},
			{"id": &"dark_forest/cemetery_fence", "ability": &"tunnel", "rect": Rect2i(21, 1, 6, 1)},
		],
		"chests": [{"id": &"dark_forest/secret_clearing", "cell": Vector2i(39, 6), "item": &"axe"}],
	},
	{
		"id": &"bosque", "name": "Bosque",
		"tint": Color(0.3, 0.3, 0.46),
		"spawns": {"from_floresta": Vector2i(32, 12)},
		"exits": [{"rect": Rect2i(35, 11, 1, 4), "map": &"dark_forest", "spawn": &"from_bosque"}],
		"items": [{"id": &"bosque/cogumelo", "cell": Vector2i(5, 5), "item": &"cogumelo"}],
		"chests": [{"id": &"bosque/staff", "cell": Vector2i(20, 21), "item": &"staff"}],
	},
	{
		"id": &"pantano", "name": "Pantano",
		"tint": Color(0.38, 0.46, 0.42),
		"spawns": {"from_floresta": Vector2i(3, 12)},
		"exits": [{"rect": Rect2i(0, 11, 1, 4), "map": &"dark_forest", "spawn": &"from_pantano"}],
		"gates": [{"id": &"pantano/canal_bridge", "ability": &"bridge", "rect": Rect2i(17, 12, 3, 2)}],
		"items": [{"id": &"pantano/musgo", "cell": Vector2i(30, 6), "item": &"musgo"}],
	},
	{
		"id": &"cemiterio", "name": "Cemiterio",
		"tint": Color(0.3, 0.3, 0.5),
		"spawns": {"from_floresta": Vector2i(17, 22)},
		"exits": [{"rect": Rect2i(16, 25, 4, 1), "map": &"dark_forest", "spawn": &"from_cemiterio"}],
		# Temporary: the osso drops from the Coveiro in Milestone 5.
		"items": [{"id": &"cemiterio/osso", "cell": Vector2i(17, 6), "item": &"osso"}],
	},
]


## Gameplay scripts are loaded at runtime, not referenced by class name: this
## main-loop script compiles before autoloads (Fx, GameState) exist, and
## static references would drag those scripts into that early compile.
const GAME_MAP_SCRIPT := "res://src/world/game_map.gd"
const PET_GATE_SCRIPT := "res://src/world/pet_gate.gd"
const CHEST_SCRIPT := "res://src/world/chest.gd"
const EXIT_SCRIPT := "res://src/world/map_exit.gd"
const NPC_SCRIPT := "res://src/world/npc.gd"
const GRANNY_SCRIPT := "res://src/world/granny.gd"
const CAULDRON_SCRIPT := "res://src/world/cauldron.gd"
const ITEM_SCRIPT := "res://src/world/quest_item.gd"
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
	for map_spec: Dictionary in MAPS:
		var spec := map_spec.duplicate()
		var dir := "res://src/world/maps/%s/" % spec.id
		spec.layout = dir + "%s.layout.txt" % spec.id
		spec.out = dir + "%s.tscn" % spec.id
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
	_add_tile(ts, FLOOR, [])
	_add_tile(ts, FLOOR_ALT, [])
	_add_tile(ts, WALL, FULL)
	_add_tile(ts, DOOR, [])
	for stamp: Array in STAMPS.values():
		for row: Array in stamp:
			for coords: Vector2i in row:
				# Doors are solid too: you enter from the cell in front, walking
				# up (MapExit.required_facing), so the hero never stands inside
				# a house — playtest: "o personagem fica dentro das casas".
				_add_tile(ts, [Src.TOWN, coords], FULL)
	for terrain: String in NINE_SLICE:
		var src: int = NINE_SLICE[terrain][0]
		var origin: Vector2i = NINE_SLICE[terrain][1]
		var shape: Array = FULL if terrain in SOLID_TERRAINS else []
		for y in 3:
			for x in 3:
				_add_tile(ts, [src, origin + Vector2i(x, y)], shape)
				if terrain == "~":
					# Alternative 1: same water, no collision — painted under
					# mist-bridge gates, which block until the bridge is made.
					var atlas := ts.get_source(src) as TileSetAtlasSource
					if not atlas.has_alternative_tile(origin + Vector2i(x, y), BRIDGE_WATER_ALT):
						atlas.create_alternative_tile(origin + Vector2i(x, y), BRIDGE_WATER_ALT)
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
			_paint_ground(ground, rows, cell, ch, spec.get("interior", false))
			if STAMPS.has(ch):
				var stamp: Array = STAMPS[ch]
				for sy in stamp.size():
					for sx in stamp[sy].size():
						_put(objects, cell + Vector2i(sx, sy), [Src.TOWN, stamp[sy][sx]])
			elif PROPS.has(ch):
				_put(objects, cell, [PROPS[ch][0], PROPS[ch][1]])
				if PROPS[ch][3]:
					_put(objects, cell + Vector2i.UP, [PROPS[ch][0], PROPS[ch][1] + Vector2i.UP])
			elif ch == "T" or ch == "F":
				_put(objects, cell, _nine_slice(ch, rows, cell))
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
	var named_spawns: Dictionary = spec.get("spawns", {})
	for spawn_name: String in named_spawns:
		var marker := Marker2D.new()
		marker.name = spawn_name
		marker.position = _feet_position(named_spawns[spawn_name])
		_own(root, spawns, marker)
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

	for chest_spec: Dictionary in spec.get("chests", []):
		var chest: StaticBody2D = load(CHEST_SCRIPT).new()
		chest.name = "Chest_" + String(chest_spec.id).get_file().to_pascal_case()
		chest.chest_id = chest_spec.id
		chest.item = chest_spec.item
		chest.position = _feet_position(chest_spec.cell)
		_own(root, world, chest)

	for npc_spec: Dictionary in spec.get("npcs", []):
		var script_path := GRANNY_SCRIPT if npc_spec.kind == "granny" else NPC_SCRIPT
		var npc: StaticBody2D = load(script_path).new()
		npc.name = npc_spec.node  # ASCII node name; npc_name is what players read
		npc.npc_name = npc_spec.name
		npc.sprite_region = npc_spec.region
		npc.dialogue_id = npc_spec.get("dialogue", &"")
		npc.position = _feet_position(npc_spec.cell)
		_own(root, world, npc)

	if spec.has("cauldron"):
		var cauldron: StaticBody2D = load(CAULDRON_SCRIPT).new()
		cauldron.name = "Cauldron"
		cauldron.position = _feet_position(spec.cauldron)
		_own(root, world, cauldron)

	for item_spec: Dictionary in spec.get("items", []):
		var item: Node2D = load(ITEM_SCRIPT).new()
		item.name = "Item_" + String(item_spec.item).to_pascal_case()
		item.pickup_id = item_spec.id
		item.item = item_spec.item
		item.position = _feet_position(item_spec.cell)
		_own(root, world, item)

	var exit_specs: Array = spec.get("exits", [])
	if not exit_specs.is_empty():
		var exits := Node2D.new()
		exits.name = "Exits"
		_own(root, root, exits)
		for exit_spec: Dictionary in exit_specs:
			var exit: Node2D = load(EXIT_SCRIPT).new()
			exit.name = "To_" + String(exit_spec.map).to_pascal_case()
			exit.target_map = exit_spec.map
			exit.target_spawn = exit_spec.spawn
			exit.required_facing = exit_spec.get("facing", Vector2.ZERO)
			var rect: Rect2i = exit_spec.rect
			exit.position = Vector2(rect.position * TILE)
			exit.size = Vector2(rect.size * TILE)
			_own(root, exits, exit)

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
			if gate_spec.ability == &"bridge":
				_make_bridge_water_walkable(ground, rect)
		# Under the actors: the hero walks over bridges and tunnels.
		root.move_child(gates, world.get_index())

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


func _paint_ground(ground: TileMapLayer, rows: PackedStringArray, cell: Vector2i, ch: String, interior := false) -> void:
	match ch:
		"W":
			_put(ground, cell, WALL)
			return
		"D":
			_put(ground, cell, DOOR)
			return
	if interior:
		_put(ground, cell, FLOOR_ALT if hash(cell) % 9 == 0 else FLOOR)
		return
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


func _make_bridge_water_walkable(ground: TileMapLayer, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cell := Vector2i(x, y)
			if ground.get_cell_source_id(cell) == Src.BATTLE:
				ground.set_cell(cell, Src.BATTLE, ground.get_cell_atlas_coords(cell), BRIDGE_WATER_ALT)


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
