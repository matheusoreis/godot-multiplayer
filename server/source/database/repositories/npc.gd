extends Node
class_name NpcRepository


var _database: Database


func setup(database: Database) -> void:
	_database = database

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS npcs (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			identifier TEXT NOT NULL,
			spritesheet TEXT NOT NULL,
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			facing_x INTEGER NOT NULL DEFAULT 0,
			facing_y INTEGER NOT NULL DEFAULT 1,
			can_walk INTEGER NOT NULL DEFAULT 0,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0,

			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE
		)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_npcs_map ON npcs(map_id)
	""")


func get_all_npcs() -> Array[Models.NpcModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM npcs ORDER BY id",
		[],
		Models.NpcModel
	)

	var npcs: Array[Models.NpcModel] = []

	for row in rows:
		npcs.append(row as Models.NpcModel)

	return npcs


func get_npcs_by_map(map_id: int) -> Array[Models.NpcModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM npcs WHERE map_id = ?",
		[map_id],
		Models.NpcModel
	)

	var npcs: Array[Models.NpcModel] = []

	for row in rows:
		npcs.append(row as Models.NpcModel)

	return npcs


func get_npc(npc_id: int) -> Models.NpcModel:
	var model: Models.NpcModel = await _database.row(
		"SELECT * FROM npcs WHERE id = ?",
		[npc_id],
		Models.NpcModel
	)

	return model


func insert_npc(
	identifier: String,
	spritesheet: String,
	map_id: int,
	cell: Vector2i,
	facing: Vector2i,
	can_walk: bool,
	timestamp: int
) -> bool:
	var result: Error = await _database.exec(
		"""
		INSERT INTO npcs (
			identifier, spritesheet, map_id,
			cell_x, cell_y, facing_x, facing_y,
			can_walk, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		""",
		[
			identifier,
			spritesheet,
			map_id,
			cell.x,
			cell.y,
			facing.x,
			facing.y,
			int(can_walk),
			timestamp,
			timestamp
		]
	)

	return result == OK


func update_npc_position(npc_id: int, cell: Vector2i, facing: Vector2i, timestamp: int) -> bool:
	var result: Error = await _database.exec(
		"UPDATE npcs SET cell_x = ?, cell_y = ?, facing_x = ?, facing_y = ?, updated_at = ? WHERE id = ?",
		[cell.x, cell.y, facing.x, facing.y, timestamp, npc_id]
	)

	return result == OK


func delete_npc(npc_id: int) -> bool:
	var result: Error = await _database.exec(
		"DELETE FROM npcs WHERE id = ?",
		[npc_id]
	)

	return result == OK


func delete_npcs_by_map(map_id: int) -> bool:
	var result: Error = await _database.exec(
		"DELETE FROM npcs WHERE map_id = ?",
		[map_id]
	)

	return result == OK
