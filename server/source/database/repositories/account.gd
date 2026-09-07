extends Node
class_name AccountRepository


var _database: Database


func setup(database: Database) -> void:
	_database = database

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS accounts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL,
			access_at INTEGER NOT NULL DEFAULT 0,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")

	await _database.exec("""
		CREATE TABLE IF NOT EXISTS characters (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			identifier TEXT NOT NULL,
			account_id INTEGER NOT NULL,
			spritesheet TEXT NOT NULL,
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			facing_x INTEGER NOT NULL,
			facing_y INTEGER NOT NULL,
			access_at INTEGER NOT NULL DEFAULT 0,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0,

			FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE RESTRICT,

			UNIQUE (account_id, identifier)
		)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_characters_account ON characters(account_id)
	""")

	await _database.exec("""
		CREATE INDEX IF NOT EXISTS idx_characters_map ON characters(map_id)
	""")


func sign_in(email: String, password: String) -> Models.AccountModel:
	if not _is_email_valid(email):
		return null

	if not _is_password_valid(password):
		return null

	var model: Models.AccountModel = await _database.row(
		"SELECT * FROM accounts WHERE email = ?",
		[email],
		Models.AccountModel
	)

	if model == null:
		return null

	if not Sha256.new().verify_value(password, model.password):
		return null

	await update_account_access_at(model.id)
	return model


func sign_up(email: String, password: String, password_confirm: String) -> bool:
	if not _is_email_valid(email):
		return false

	if not _is_password_valid(password):
		return false

	if password != password_confirm:
		return false

	var existing: Variant = await _database.scalar(
		"SELECT COUNT(*) FROM accounts WHERE email = ?",
		[email]
	)

	if existing != null and existing > 0:
		return false

	var hashed: String = Sha256.new().hash_value(password)
	var now: int = _database.now()

	var result: Error = await _database.exec(
		"INSERT INTO accounts (email, password, access_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		[email, hashed, now, now, now]
	)

	return result == OK


func update_account_access_at(account_id: int) -> void:
	await _database.exec(
		"UPDATE accounts SET access_at = ? WHERE id = ?",
		[_database.now(), account_id]
	)


func update_account_updated_at(account_id: int) -> void:
	await _database.exec(
		"UPDATE accounts SET updated_at = ? WHERE id = ?",
		[_database.now(), account_id]
	)


func update_character_access_at(character_id: int) -> void:
	await _database.exec(
		"UPDATE characters SET access_at = ? WHERE id = ?",
		[_database.now(), character_id]
	)


func update_character_updated_at(character_id: int) -> void:
	await _database.exec(
		"UPDATE characters SET updated_at = ? WHERE id = ?",
		[_database.now(), character_id]
	)


func get_characters(account_id: int) -> Array[Models.CharacterModel]:
	var rows: Array[Models] = await _database.rows(
		"SELECT * FROM characters WHERE account_id = ? ORDER BY id",
		[account_id],
		Models.CharacterModel
	)

	var characters: Array[Models.CharacterModel] = []

	for row in rows:
		characters.append(row as Models.CharacterModel)

	return characters


func get_character(character_id: int) -> Models.CharacterModel:
	var model: Models.CharacterModel = await _database.row(
		"SELECT * FROM characters WHERE id = ?",
		[character_id],
		Models.CharacterModel
	)

	return model


func is_character_owner(character_id: int, account_id: int) -> bool:
	var result: Variant = await _database.scalar(
		"SELECT 1 FROM characters WHERE id = ? AND account_id = ? LIMIT 1",
		[character_id, account_id]
	)

	return result != null


func character_identifier_exists(account_id: int, identifier: String) -> bool:
	var result: Variant = await _database.scalar(
		"SELECT 1 FROM characters WHERE account_id = ? AND identifier = ? LIMIT 1",
		[account_id, identifier]
	)

	return result != null


func create_character(account_id: int, identifier: String, spritesheet: String) -> Models.CharacterModel:
	if not _is_identifier_valid(identifier):
		return null

	if await character_identifier_exists(account_id, identifier):
		return null

	if not Constants.AVALIABLE_SPRITES.has(spritesheet):
		return null

	var now: int = _database.now()

	var result: Error = await _database.exec(
		"""
		INSERT INTO characters (
			identifier, account_id, spritesheet, map_id, cell_x, cell_y, facing_x, facing_y, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		""",
		[
			identifier,
			account_id,
			spritesheet,
			Constants.START_MAP,
			Constants.START_MAP_POSITION.x,
			Constants.START_MAP_POSITION.y,
			Constants.START_MAP_FACING.x,
			Constants.START_MAP_FACING.y,
			now,
			now
		]
	)

	if result != OK:
		return null

	var model: Models.CharacterModel = await _database.row(
		"SELECT * FROM characters WHERE account_id = ? AND identifier = ?",
		[account_id, identifier],
		Models.CharacterModel
	)

	return model


func select_character(character_id: int, account_id: int) -> Models.CharacterModel:
	var model: Models.CharacterModel = await _database.row(
		"SELECT * FROM characters WHERE id = ? AND account_id = ?",
		[character_id, account_id],
		Models.CharacterModel
	)

	if model == null:
		return null

	await update_character_access_at(character_id)
	return model


func delete_character(character_id: int, account_id: int) -> bool:
	if not await is_character_owner(character_id, account_id):
		return false

	var result: Error = await _database.exec(
		"DELETE FROM characters WHERE id = ? AND account_id = ?",
		[character_id, account_id]
	)

	return result == OK


func update_character_location(character_id: int, map_id: int, cell: Vector2i, facing: Vector2i) -> bool:
	var result: Error = await _database.exec(
		"UPDATE characters SET map_id = ?, cell_x = ?, cell_y = ?, facing_x = ?, facing_y = ?, updated_at = ? WHERE id = ?",
		[map_id, cell.x, cell.y, facing.x, facing.y, _database.now(), character_id]
	)

	return result == OK


func _is_identifier_valid(identifier: String) -> bool:
	return RegEx.create_from_string(
		Constants.IDENTIFIER_REGEX
	).search(identifier) != null


func _is_email_valid(email: String) -> bool:
	return RegEx.create_from_string(
		Constants.EMAIL_REGEX
	).search(email) != null


func _is_password_valid(password: String) -> bool:
	return RegEx.create_from_string(
		Constants.PASSWORD_REGEX
	).search(password) != null
