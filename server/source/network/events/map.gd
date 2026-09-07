extends Node
class_name MapEvent


var _network: Network
var _account_manager: AccountManager
var _map_manager: MapManager


func _init(
	network: Network,
	account_manager: AccountManager,
	map_manager: MapManager
) -> void:
	_network = network
	_account_manager = account_manager
	_map_manager = map_manager


func register() -> Error:
	return _network.register([
		map_data,
		enter_map,
		move_character
	])


func unregister() -> Error:
	return _network.unregister([
		map_data,
		enter_map,
		move_character
	])


func map_data() -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_manager.account(sender_id)

	if account == null or not account.has_character():
		_network.exec(sender_id, &"confirmation", ["NO_CHARACTER_SELECTED"])
		return

	var map: Map = _map_manager.map(account.character.map_id)

	if map == null:
		_network.exec(sender_id, &"confirmation", ["MAP_NOT_FOUND"])
		return

	_send_map_data(sender_id, account.character.map_id)


func enter_map() -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_manager.account(sender_id)

	if account == null or not account.has_character():
		_network.exec(sender_id, &"confirmation", ["NO_CHARACTER_SELECTED"])
		return

	var character_data: Array = [
		sender_id,
		account.character.identifier,
		account.character.spritesheet,
		account.character.map_id,
		account.character.cell,
		account.character.facing
	]

	_network.exec(sender_id, &"character_data", [character_data])

	var targets: Array = _peers_in_map(account.character.map_id)
	targets.erase(sender_id)

	if not targets.is_empty():
		_network.exec(targets, &"character_to_characters", [character_data])


func leave_map(peer_id: int) -> void:
	var account: Account = _account_manager.account(peer_id)

	if account == null or not account.has_character():
		return

	var targets: Array = _peers_in_map(account.character.map_id)
	targets.erase(peer_id)

	if not targets.is_empty():
		_network.exec(targets, &"character_left", [peer_id])


func move_character(direction: Vector2i) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_manager.account(sender_id)

	if account == null or not account.has_character():
		_network.exec(sender_id, &"confirmation", ["NO_CHARACTER_SELECTED"])
		return

	var character: Character = account.character
	var map: Map = _map_manager.map(character.map_id)

	if map == null:
		_network.exec(sender_id, &"confirmation", ["MAP_NOT_FOUND"])
		return

	if not map.can_pass(character.cell, direction):
		_network.exec(sender_id, &"correct_movement", [character.cell, character.facing])
		return

	character.move(direction)

	var targets: Array = _peers_in_map(map.id)
	targets.erase(sender_id)

	if not targets.is_empty():
		_network.exec(targets, &"move_character", [sender_id, direction])

	if map.has_warp(character.cell):
		_apply_warp(sender_id, character, map)


func _apply_warp(peer_id: int, character: Character, current_map: Map) -> void:
	var warp_data: Array = current_map.get_warp(character.cell)

	if warp_data.is_empty():
		return

	var to_map_id: int = warp_data[0]
	var to_cell: Vector2i = Vector2i(warp_data[1], warp_data[2])
	var to_facing: Vector2i = Vector2i(warp_data[3], warp_data[4])

	var new_map: Map = _map_manager.map(to_map_id)
	if new_map == null:
		return

	var targets: Array = _peers_in_map(current_map.id)
	targets.erase(peer_id)

	if not targets.is_empty():
		_network.exec(targets, &"character_left", [peer_id])

	character.warp(to_map_id, to_cell, to_facing)

	_network.exec(peer_id, &"warp_map", [new_map.id])
	_send_map_data(peer_id, new_map.id)


func _send_map_data(peer_id: int, map_id: int) -> void:
	var map: Map = _map_manager.map(map_id)

	if map == null:
		return

	var targets: Array = _peers_in_map(map_id)
	targets.erase(peer_id)

	var characters: Array = []

	for target_id in targets:
		var other_account: Account = _account_manager.account(target_id)

		if other_account == null or not other_account.has_character():
			continue

		characters.append([
			target_id,
			other_account.character.identifier,
			other_account.character.spritesheet,
			other_account.character.map_id,
			other_account.character.cell,
			other_account.character.facing
		])

	_network.exec(peer_id, &"map_data", [
		map.id,
		map.identifier,
		map.bgm,
		map.bgs,
		map.size,
		map.collisions,
		map.warps,
		characters
	])


func _peers_in_map(map_id: int) -> Array:
	var peers: Array = []
	var accounts: Dictionary[int, Account] = _account_manager.accounts()

	for peer_id: int in accounts:
		var account: Account = accounts[peer_id]

		if account.has_character() and account.character.map_id == map_id:
			peers.append(peer_id)

	return peers
