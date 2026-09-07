extends Node
class_name ChatEvent


var _network: Network
var _account_manager: AccountManager
var _map_manager: MapManager


func _init(network: Network, account_manager: AccountManager, map_manager: MapManager) -> void:
	_network = network
	_account_manager = account_manager
	_map_manager = map_manager


func register() -> Error:
	return _network.register([
		map_message,
		global_message
	])


func unregister() -> Error:
	return _network.unregister([
		map_message,
		global_message
	])


func map_message(message: String) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_manager.account(sender_id)
	if account == null or not account.has_character():
		return

	var map_id: int = account.character.map_id
	var map: Map = _map_manager.map(map_id)

	if map == null:
		return

	var targets: Array[int] = _get_peers_in_map(map_id)
	if targets.is_empty():
		return

	_network.exec(targets, &"map_message", [
		sender_id,
		account.character.identifier,
		message
	])


func global_message(message: String) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_manager.account(sender_id)
	if account == null or not account.has_character():
		return

	var targets: Array[int] = _get_all_peers()
	if targets.is_empty():
		return

	_network.exec(targets, &"global_message", [
		sender_id,
		account.character.identifier,
		message
	])


func _get_peers_in_map(map_id: int) -> Array[int]:
	var peers: Array[int] = []
	var accounts: Dictionary[int, Account] = _account_manager.accounts()

	for peer_id: int in accounts:
		var account: Account = accounts[peer_id]

		if account.has_character() and account.character.map_id == map_id:
			peers.append(peer_id)

	return peers


func _get_all_peers() -> Array[int]:
	var peers: Array[int] = []
	var accounts: Dictionary[int, Account] = _account_manager.accounts()

	for peer_id: int in accounts:
		var account: Account = accounts[peer_id]

		if account.has_character():
			peers.append(peer_id)

	return peers


func _get_peer_id_by_account(account: Account) -> int:
	var accounts: Dictionary[int, Account] = _account_manager.accounts()

	for peer_id: int in accounts:
		if accounts[peer_id] == account:
			return peer_id

	return -1
