extends Node
class_name MapManager


var _maps: Dictionary[int, Map] = {}

var _map_repository: MapRepository


func _init(map_repository: MapRepository) -> void:
	_map_repository = map_repository


func load_all_maps() -> void:
	var models: Array[Models.MapModel] = await _map_repository.get_all_maps()

	for model in models:
		var map: Map = Map.new(
			model.id,
			model.identifier,
			model.bgm,
			model.bgs,
			Vector2i(model.size_x, model.size_y)
		)

		var collision_models: Array[Models.MapCollisionModel] = await _map_repository.get_collisions(model.id)
		var warp_models: Array[Models.MapWarpModel] = await _map_repository.get_warps(model.id)

		var collisions: Dictionary[Vector2i, int] = {}
		for collision_model in collision_models:
			var cell: Vector2i = Vector2i(collision_model.cell_x, collision_model.cell_y)
			collisions[cell] = collision_model.flag

		var warps: Dictionary[Vector2i, Array] = {}
		for warp_model in warp_models:
			var cell: Vector2i = Vector2i(warp_model.cell_x, warp_model.cell_y)
			warps[cell] = [
				warp_model.to_map_id,
				warp_model.to_cell_x,
				warp_model.to_cell_y,
				warp_model.to_facing_x,
				warp_model.to_facing_y
			]

		map.import_collisions(collisions)
		map.import_warps(warps)

		_maps[map.id] = map

		print("Mapa %s carregado com %d colisões e %d warps." % [
			map.identifier,
			map.collisions.size(),
			map.warps.size()
		])


func map(map_id: int) -> Map:
	return _maps.get(map_id)


func maps() -> Dictionary[int, Map]:
	return _maps


func has(map_id: int) -> bool:
	return _maps.has(map_id)


func count() -> int:
	return _maps.size()


func all() -> Array[Map]:
	return _maps.values()


func insert_collision(map_id: int, cell: Vector2i, flag: int) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var insert_result: bool = await _map_repository.insert_collision(map_id, cell, flag)

	if not insert_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.collisions[cell] = flag

	return [OK, null]


func delete_collisions_by_map(map_id: int) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var delete_result: bool = await _map_repository.delete_collisions_by_map(map_id)

	if not delete_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.collisions.clear()

	return [OK, null]


func insert_warp(map_id: int, from_cell: Vector2i, to_map_id: int, to_cell: Vector2i, to_facing: Vector2i) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	if not map.is_within_bounds(from_cell):
		var normalized: Vector2i = map.normalize_cell(from_cell)
		if not map.is_within_bounds(normalized):
			return [ERR_INVALID_PARAMETER, "CELL_OUT_OF_BOUNDS"]
		from_cell = normalized

	if not map.is_within_bounds(to_cell):
		var normalized: Vector2i = map.normalize_cell(to_cell)
		if not map.is_within_bounds(normalized):
			return [ERR_INVALID_PARAMETER, "DESTINATION_OUT_OF_BOUNDS"]
		to_cell = normalized

	var insert_result: bool = await _map_repository.insert_warp(map_id, from_cell, to_map_id, to_cell, to_facing)

	if not insert_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.warps[from_cell] = [
		to_map_id,
		to_cell.x,
		to_cell.y,
		to_facing.x,
		to_facing.y
	]

	return [OK, null]


func delete_warps_by_map(map_id: int) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var delete_result: bool = await _map_repository.delete_warps_by_map(map_id)

	if not delete_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.warps.clear()

	return [OK, null]


func import_collisions(map_id: int, collisions_data: Array) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var parsed: Dictionary[Vector2i, int] = {}

	for entry in collisions_data:
		var cell: Vector2i = entry[0]
		var flag: int = entry[1]

		if not map.is_within_bounds(cell):
			continue

		parsed[cell] = flag

	var delete_result: bool = await _map_repository.delete_collisions_by_map(map_id)
	if not delete_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	for cell: Vector2i in parsed:
		var insert_result: bool = await _map_repository.insert_collision(map_id, cell, parsed[cell])

		if not insert_result:
			await _reload_collisions(map)
			return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.collisions.clear()
	map.collisions.assign(parsed)

	return [OK, null]


func import_warps(map_id: int, warps_data: Array) -> Array:
	var map: Map = _maps.get(map_id)

	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var parsed: Dictionary[Vector2i, Array] = {}

	for entry in warps_data:
		var from_cell: Vector2i = entry[0]
		var to_map_id: int = entry[1]
		var to_cell: Vector2i = entry[2]
		var to_facing: Vector2i = entry[3]

		if not map.is_within_bounds(from_cell):
			continue

		var to_map: Map = _maps.get(to_map_id)
		if to_map == null:
			continue

		if not to_map.is_within_bounds(to_cell):
			continue

		parsed[from_cell] = [
			to_map_id,
			to_cell.x,
			to_cell.y,
			to_facing.x,
			to_facing.y
		]

	var delete_result: bool = await _map_repository.delete_warps_by_map(map_id)
	if not delete_result:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	for from_cell: Vector2i in parsed:
		var warp: Array = parsed[from_cell]

		var insert_result: bool = await _map_repository.insert_warp(
			map_id,
			from_cell,
			warp[0],
			Vector2i(warp[1], warp[2]),
			Vector2i(warp[3], warp[4])
		)

		if not insert_result:
			await _reload_warps(map)
			return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.warps.clear()
	map.warps.assign(parsed)

	return [OK, null]


func _reload_collisions(map: Map) -> void:
	var models: Array[Models.MapCollisionModel] = await _map_repository.get_collisions(map.id)

	map.collisions.clear()

	for model in models:
		var cell: Vector2i = Vector2i(model.cell_x, model.cell_y)
		map.collisions[cell] = model.flag


func _reload_warps(map: Map) -> void:
	var models: Array[Models.MapWarpModel] = await _map_repository.get_warps(map.id)

	map.warps.clear()

	for model in models:
		var cell: Vector2i = Vector2i(model.cell_x, model.cell_y)
		map.warps[cell] = [
			model.to_map_id,
			model.to_cell_x,
			model.to_cell_y,
			model.to_facing_x,
			model.to_facing_y
		]
