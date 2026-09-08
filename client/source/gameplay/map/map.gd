extends Node2D
class_name Map


var id: int
var identifier: String

var bgm: String
var bgs: String

var size: Vector2i

var collisions: Dictionary[Vector2i, int]
var warps: Dictionary[Vector2i, Array]

@export_group("Layers")
@export var tilemap_layers: Array[TileMapLayer] = []

@export_group("Warps")
@export var warps_data: Array[MapWarp] = []

var characters: Dictionary[int, Character]


func setup(id: int, identifier: String, bgm: String, bgs: String, size: Vector2i) -> void:
	self.id = id
	self.identifier = identifier

	self.bgm = bgm
	self.bgs = bgs

	self.size = size

	collisions.clear()
	warps.clear()


func import_collisions(collisions_data: Dictionary) -> void:
	if collisions_data.is_empty():
		_load_collisions_from_tiles()
		return

	self.collisions.assign(collisions_data)


func import_warps(warps_data: Dictionary) -> void:
	self.warps.assign(warps_data)


func has_warp(cell: Vector2i) -> bool:
	return warps.has(cell)


func get_warp(cell: Vector2i) -> Array:  # ← RETORNA ARRAY!
	return warps.get(cell, [])


func pixel_size() -> Vector2i:
	return Vector2i(size.x * Constants.CELL_SIZE, size.y * Constants.CELL_SIZE)


func is_within_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < size.x and position.y >= 0 and position.y < size.y


func normalize_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clamp(cell.x, 0, size.x - 1),
		clamp(cell.y, 0, size.y - 1)
	)


func to_screen(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * Constants.CELL_SIZE, cell.y * Constants.CELL_SIZE)


func to_cell(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x / Constants.CELL_SIZE), int(position.y / Constants.CELL_SIZE))


func collision_flag(cell: Vector2i) -> int:
	return collisions.get(cell, Constants.CELL_NONE)


func is_solid(cell: Vector2i) -> bool:
	return (collision_flag(cell) & Constants.CELL_FULL_BLOCK) != 0


func can_pass(from: Vector2i, direction: Vector2i) -> bool:
	var to: Vector2i = from + direction

	if not is_within_bounds(from) or not is_within_bounds(to):
		return false

	var from_flag: int = collision_flag(from)
	var to_flag: int = collision_flag(to)

	if (from_flag & Constants.CELL_FULL_BLOCK) != 0:
		return false

	if (to_flag & Constants.CELL_FULL_BLOCK) != 0:
		return false

	var direction_flag: int = _direction_to_flag(direction)
	var opposite_flag: int = _direction_to_flag(-direction)

	if (from_flag & direction_flag) != 0:
		return false

	if (to_flag & opposite_flag) != 0:
		return false

	if abs(direction.x) == 1 and abs(direction.y) == 1:
		var horizontal_cell := Vector2i(from.x + direction.x, from.y)
		var vertical_cell := Vector2i(from.x, from.y + direction.y)

		if is_solid(horizontal_cell) or is_solid(vertical_cell):
			return false

	return true


func add_character(character: Character) -> void:
	characters[character.id] = character

	add_child(character)
	character.position = to_screen(character.cell)


func remove_character(character_id: int) -> void:
	var character: Character = characters.get(character_id)
	if not character:
		return

	remove_child(character)
	characters.erase(character_id)


func get_character(character_id: int) -> Character:
	return characters.get(character_id)


func get_characters() -> Array[Character]:
	var result: Array[Character] = []
	result.assign(characters.values())
	return result


func has_character_at(cell: Vector2i) -> bool:
	for character: Character in characters.values():
		if character.get_cell() == cell:
			return true
	return false


func get_characters_at(cell: Vector2i) -> Array[Character]:
	var result: Array[Character] = []
	for character: Character in characters.values():
		if character.get_cell() == cell:
			result.append(character)
	return result


func export_warps() -> Array:
	if warps.is_empty():
		_load_warps_from_data()

	var result: Array = []

	for warp: MapWarp in warps_data:
		if not warp:
			continue

		result.append([
			warp.from_cell,
			warp.to_map_id,
			warp.to_cell,
			warp.to_facing
		])

	return result


func export_collisions() -> Array:
	if collisions.is_empty():
		_load_collisions_from_tiles()

	var result: Array = []
	var seen: Dictionary[Vector2i, int] = {}

	for layer: TileMapLayer in tilemap_layers:
		if not layer:
			continue

		for cell: Vector2i in layer.get_used_cells():
			var flag: int = _get_collision_from_tile(layer, cell)
			if flag == Constants.CELL_NONE:
				continue

			var current_flag: int = seen.get(cell, Constants.CELL_NONE)
			seen[cell] = current_flag | flag

	for cell: Vector2i in seen:
		result.append([cell, seen[cell]])

	return result


func _load_collisions_from_tiles() -> void:
	collisions.clear()

	for layer: TileMapLayer in tilemap_layers:
		if not layer:
			continue

		for cell: Vector2i in layer.get_used_cells():
			var flag: int = _get_collision_from_tile(layer, cell)
			if flag != Constants.CELL_NONE:
				var current_flag: int = collisions.get(cell, Constants.CELL_NONE)
				collisions[cell] = current_flag | flag


func _load_warps_from_data() -> void:
	warps.clear()

	for warp: MapWarp in warps_data:
		if not warp:
			continue

		warps[warp.from_cell] = [
			warp.to_map_id,
			warp.to_cell,
			warp.to_facing
		]


func _get_collision_from_tile(layer: TileMapLayer, cell: Vector2i) -> int:
	var tile_data: TileData = layer.get_cell_tile_data(cell)
	if not tile_data:
		return Constants.CELL_NONE
	return tile_data.get_custom_data("collision")


func _direction_to_flag(direction: Vector2i) -> int:
	match direction:
		Vector2i.DOWN:
			return Constants.CELL_DOWN
		Vector2i.LEFT:
			return Constants.CELL_LEFT
		Vector2i.RIGHT:
			return Constants.CELL_RIGHT
		Vector2i.UP:
			return Constants.CELL_UP
		_:
			return Constants.CELL_NONE
