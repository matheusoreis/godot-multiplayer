extends Node
class_name AccountEvent


var _network: Network.Server
var _account_manager: AccountManager


func _init(network: Network.Server, account_manager: AccountManager) -> void:
	_network = network
	_account_manager = account_manager


func register() -> Error:
	return _network.register([
		sign_in,
		sign_up,
		list_characters,
		create_character,
		delete_character,
		select_character
	])


func unregister() -> Error:
	return _network.unregister([
		sign_in,
		sign_up,
		list_characters,
		create_character,
		delete_character,
		select_character
	])


func sign_in(email: String, password: String, major_version: int, minor_version: int, revision_version: int) -> void:
	var sender_id: int = _validate_request(major_version, minor_version, revision_version)
	if sender_id == -1:
		return

	var sign_in_result: Array = await _account_manager.sign_in(sender_id, email, password)
	if sign_in_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [sign_in_result[1]])
		return

	_network.exec(sender_id, &"sign_in")


func sign_up(email: String, password: String, password_confirm: String, major_version: int, minor_version: int, revision_version: int) -> void:
	var sender_id: int = _validate_request(major_version, minor_version, revision_version)
	if sender_id == -1:
		return

	var sign_up_result: Array = await _account_manager.sign_up(sender_id, email, password, password_confirm)
	if sign_up_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [sign_up_result[1]])
		return

	_network.exec(sender_id, &"sign_up")


func list_characters() -> void:
	var sender_id: int = _network.sender_id()

	var list_result: Array = await _account_manager.list_characters(sender_id)
	if list_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [list_result[1]])
		return

	var characters: Array[Character] = list_result[1]
	var characters_data: Array = []

	for character in characters:
		characters_data.append([
			character.id,
			character.identifier,
			character.spritesheet
		])

	_network.exec(sender_id, &"list_characters", [characters_data])


func create_character(identifier: String, spritesheet: String) -> void:
	var sender_id: int = _network.sender_id()

	var create_result: Array = await _account_manager.create_character(sender_id, identifier, spritesheet)
	if create_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [create_result[1]])
		return

	_network.exec(sender_id, &"create_character")


func delete_character(character_id: int) -> void:
	var sender_id: int = _network.sender_id()

	var delete_result: Array = await _account_manager.delete_character(sender_id, character_id)
	if delete_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [delete_result[1]])
		return

	_network.exec(sender_id, &"delete_character")


func select_character(character_id: int) -> void:
	var sender_id: int = _network.sender_id()

	var select_result: Array = await _account_manager.select_character(sender_id, character_id)
	if select_result[0] != OK:
		_network.exec(sender_id, &"confirmation", [select_result[1]])
		return

	_network.exec(sender_id, &"select_character")


func _is_version_valid(major: int, minor: int, revision: int) -> bool:
	return (
		major == Constants.MAJOR_VERSION
		and minor == Constants.MINOR_VERSION
		and revision == Constants.REVISION_VERSION
	)


func _validate_request(major: int, minor: int, revision: int) -> int:
	var sender_id: int = _network.sender_id()

	if not _is_version_valid(major, minor, revision):
		_network.exec(sender_id, &"confirmation", ["OUTDATED_CLIENT"])
		return -1

	if _account_manager.has(sender_id):
		_network.exec(sender_id, &"confirmation", ["ALREADY_LOGGED_IN"])
		return -1

	return sender_id
