extends Node
class_name AccountManager


var _accounts: Dictionary[int, Account] = {}

var _account_repository: AccountRepository


func _init(account_repository: AccountRepository) -> void:
	_account_repository = account_repository


func account(peer_id: int) -> Account:
	return _accounts.get(peer_id)


func accounts() -> Dictionary[int, Account]:
	return _accounts


func has(peer_id: int) -> bool:
	return _accounts.has(peer_id)


func count() -> int:
	return _accounts.size()


func all() -> Array[Account]:
	return _accounts.values()


func sign_in(peer_id: int, email: String, password: String) -> Array:
	if has(peer_id):
		return [ERR_ALREADY_IN_USE, "ALREADY_SIGNED_IN"]

	var sign_in_result: Array = await _account_repository.sign_in(email, password)
	if sign_in_result[0] != OK:
		return sign_in_result

	var model: Models.AccountModel = sign_in_result[1]
	_accounts[peer_id] = Account.new(
		model.id, model.email, model.password, model.access_at, model.created_at, model.updated_at
	)

	return [OK, ""]


func sign_up(peer_id: int, email: String, password: String, password_confirm: String) -> Array:
	if has(peer_id):
		return [ERR_ALREADY_IN_USE, "ALREADY_SIGNED_IN"]

	var sign_up_result: Array = await _account_repository.sign_up(email, password, password_confirm)
	if sign_up_result[0] != OK:
		return sign_up_result

	var sign_in_result: Array = await _account_repository.sign_in(email, password)
	if sign_in_result[0] != OK:
		return sign_in_result

	var model: Models.AccountModel = sign_in_result[1]
	_accounts[peer_id] = Account.new(
		model.id, model.email, model.password, model.access_at, model.created_at, model.updated_at
	)

	return [OK, ""]


func sign_out(peer_id: int) -> void:
	var account: Account = account(peer_id)
	if account == null:
		return

	if account.has_character():
		await _account_repository.update_character_location(
			account.character.id,
			account.character.map,
			account.character.cell,
			account.character.facing
		)

	_accounts.erase(peer_id)


func list_characters(peer_id: int) -> Array:
	var account: Account = account(peer_id)
	if account == null:
		return [ERR_UNAUTHORIZED, "NOT_SIGNED_IN"]

	var characters_result: Array[Models.CharacterModel] = await _account_repository.get_characters(account.id)
	var characters: Array[Character] = []

	for model in characters_result:
		characters.append(_hydrate_character(model))

	return [OK, characters]


func create_character(peer_id: int, identifier: String, spritesheet: String) -> Array:
	var account: Account = account(peer_id)
	if account == null:
		return [ERR_UNAUTHORIZED, "NOT_SIGNED_IN"]

	var create_result: Array = await _account_repository.create_character(
		account.id,
		identifier,
		spritesheet
	)

	if create_result[0] != OK:
		return create_result

	var character: Character = _hydrate_character(create_result[1] as Models.CharacterModel)
	return [OK, character]


func select_character(peer_id: int, character_id: int) -> Array:
	var account: Account = account(peer_id)
	if account == null:
		return [ERR_UNAUTHORIZED, "NOT_SIGNED_IN"]

	if account.has_character():
		return [ERR_ALREADY_IN_USE, "CHARACTER_ALREADY_SELECTED"]

	var select_result: Array = await _account_repository.select_character(
		character_id,
		account.id
	)

	if select_result[0] != OK:
		return select_result

	var character: Character = _hydrate_character(select_result[1] as Models.CharacterModel)
	account.select_character(character)

	return [OK, character]


func delete_character(peer_id: int, character_id: int) -> Array:
	var account: Account = account(peer_id)
	if account == null:
		return [ERR_UNAUTHORIZED, "NOT_SIGNED_IN"]

	var delete_result: Array = await _account_repository.delete_character(
		character_id,
		account.id
	)

	if delete_result[0] != OK:
		return delete_result

	if account.has_character() and account.character.id == character_id:
		account.clear_character()

	return [OK, null]


func _hydrate_character(model: Models.CharacterModel) -> Character:
	var character: Character = Character.new(
		model.id,
		model.identifier,
		model.spritesheet,
		model.map_id,
		Vector2i(model.cell_x, model.cell_y),
		Vector2i(model.facing_x, model.facing_y),
		model.account_id,
		model.access_at,
		model.created_at,
		model.updated_at
	)

	return character
