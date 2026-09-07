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
