extends Node
class_name MapRepository


var _database: Database


func setup(database: Database) -> void:
	_database = database

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS maps (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			identifier TEXT NOT NULL UNIQUE,
			bgm TEXT NOT NULL DEFAULT '',
			bgs TEXT NOT NULL DEFAULT '',
			size_x INTEGER NOT NULL DEFAULT 80,
			size_y INTEGER NOT NULL DEFAULT 34,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS map_collisions (
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			flag INTEGER NOT NULL DEFAULT 0,

			PRIMARY KEY (map_id, cell_x, cell_y),

			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE
		)
	""")

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS map_warps (
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			to_map_id INTEGER NOT NULL,
			to_cell_x INTEGER NOT NULL,
			to_cell_y INTEGER NOT NULL,
			to_facing_x INTEGER NOT NULL,
			to_facing_y INTEGER NOT NULL,

			PRIMARY KEY (map_id, cell_x, cell_y),

			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
			FOREIGN KEY (to_map_id) REFERENCES maps(id) ON DELETE CASCADE
		)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_map_collisions_map ON map_collisions(map_id)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_map_warps_map ON map_warps(map_id)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_map_warps_to_map ON map_warps(to_map_id)
	""")


func get_all_maps() -> Array[Models.MapModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM maps ORDER BY id",
		[],
		Models.MapModel
	)

	var maps: Array[Models.MapModel] = []

	for row in rows:
		maps.append(row as Models.MapModel)

	return maps


func get_map(map_id: int) -> Models.MapModel:
	var model: Models.MapModel = await _database.row(
		"SELECT * FROM maps WHERE id = ?",
		[map_id],
		Models.MapModel
	)

	return model


func get_collisions(map_id: int) -> Array[Models.MapCollisionModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM map_collisions WHERE map_id = ?",
		[map_id],
		Models.MapCollisionModel
	)

	var collisions: Array[Models.MapCollisionModel] = []

	for row in rows:
		collisions.append(row as Models.MapCollisionModel)

	return collisions


func insert_collision(map_id: int, cell: Vector2i, flag: int) -> bool:
	var result: Error = await _database.exec(
		"INSERT INTO map_collisions (map_id, cell_x, cell_y, flag) VALUES (?, ?, ?, ?)",
		[map_id, cell.x, cell.y, flag]
	)

	return result == OK


func delete_collisions_by_map(map_id: int) -> bool:
	var result: Error = await _database.exec(
		"DELETE FROM map_collisions WHERE map_id = ?",
		[map_id]
	)

	return result == OK


func get_warps(map_id: int) -> Array[Models.MapWarpModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM map_warps WHERE map_id = ?",
		[map_id],
		Models.MapWarpModel
	)

	var warps: Array[Models.MapWarpModel] = []

	for row in rows:
		warps.append(row as Models.MapWarpModel)

	return warps


func insert_warp(map_id: int, from_cell: Vector2i, to_map_id: int, to_cell: Vector2i, to_facing: Vector2i) -> bool:
	var result: Error = await _database.exec(
		"INSERT INTO map_warps (map_id, cell_x, cell_y, to_map_id, to_cell_x, to_cell_y, to_facing_x, to_facing_y) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
		[map_id, from_cell.x, from_cell.y, to_map_id, to_cell.x, to_cell.y, to_facing.x, to_facing.y]
	)

	return result == OK


func delete_warps_by_map(map_id: int) -> bool:
	var result: Error = await _database.exec(
		"DELETE FROM map_warps WHERE map_id = ?",
		[map_id]
	)

	return result == OK
