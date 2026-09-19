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
			role INTEGER NOT NULL DEFAULT 0,
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


func sign_in(email: String, password: String) -> Array:
	if not _is_email_valid(email):
		return [ERR_INVALID_PARAMETER, "INVALID_EMAIL"]

	if not _is_password_valid(password):
		return [ERR_INVALID_PARAMETER, "INVALID_PASSWORD"]

	var model: Models.AccountModel = await _database.row(
		"SELECT * FROM accounts WHERE email = ?",
		[email],
		Models.AccountModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "ACCOUNT_NOT_FOUND"]

	if not Sha256.new().verify_value(password, model.password):
		return [ERR_UNAUTHORIZED, "INCORRECT_PASSWORD"]

	await update_account_access_at(model.id)
	return [OK, model]


func sign_up(email: String, password: String, password_confirm: String) -> Array:
	if not _is_email_valid(email):
		return [ERR_INVALID_PARAMETER, "INVALID_EMAIL"]

	if not _is_password_valid(password):
		return [ERR_INVALID_PARAMETER, "INVALID_PASSWORD"]

	if password != password_confirm:
		return [ERR_INVALID_DATA, "PASSWORDS_DO_NOT_MATCH"]

	var existing: Variant = await _database.scalar(
		"SELECT COUNT(*) FROM accounts WHERE email = ?",
		[email]
	)

	if existing != null and existing > 0:
		return [ERR_ALREADY_EXISTS, "EMAIL_ALREADY_REGISTERED"]

	var hashed: String = Sha256.new().hash_value(password)
	var now: int = _database.now()

	var result: Error = await _database.exec(
		"INSERT INTO accounts (email, password, access_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		[email, hashed, now, now, now]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


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


func update_character_role(character_id: int, role: int) -> Array:
	var result: Error = await _database.exec(
		"UPDATE characters SET role = ?, updated_at = ? WHERE id = ?",
		[role, _database.now(), character_id]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


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


func create_character(account_id: int, identifier: String, spritesheet: String) -> Array:
	if not _is_identifier_valid(identifier):
		return [ERR_INVALID_PARAMETER, "INVALID_IDENTIFIER"]

	if await character_identifier_exists(account_id, identifier):
		return [ERR_ALREADY_EXISTS, "IDENTIFIER_ALREADY_EXISTS"]

	if not Constants.AVALIABLE_SPRITES.has(spritesheet):
		return [ERR_INVALID_PARAMETER, "INVALID_SPRITE"]

	var now: int = _database.now()

	var result: Error = await _database.exec(
		"""
		INSERT INTO characters (
			identifier, account_id, spritesheet, map_id, cell_x, cell_y,
			facing_x, facing_y, role, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
			Constants.ROLE_NONE,
			now,
			now
		]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	var model: Models.CharacterModel = await _database.row(
		"SELECT * FROM characters WHERE account_id = ? AND identifier = ?",
		[account_id, identifier],
		Models.CharacterModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "DATABASE_ERROR"]

	return [OK, model]


func select_character(character_id: int, account_id: int) -> Array:
	var model: Models.CharacterModel = await _database.row(
		"SELECT * FROM characters WHERE id = ? AND account_id = ?",
		[character_id, account_id],
		Models.CharacterModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "CHARACTER_NOT_FOUND"]

	await update_character_access_at(character_id)
	return [OK, model]


func delete_character(character_id: int, account_id: int) -> Array:
	if not await is_character_owner(character_id, account_id):
		return [ERR_UNAUTHORIZED, "NOT_OWNER"]

	var result: Error = await _database.exec(
		"DELETE FROM characters WHERE id = ? AND account_id = ?",
		[character_id, account_id]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


func update_character_location(character_id: int, map_id: int, cell: Vector2i, facing: Vector2i) -> Array:
	var result: Error = await _database.exec(
		"UPDATE characters SET map_id = ?, cell_x = ?, cell_y = ?, facing_x = ?, facing_y = ?, updated_at = ? WHERE id = ?",
		[map_id, cell.x, cell.y, facing.x, facing.y, _database.now(), character_id]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


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
