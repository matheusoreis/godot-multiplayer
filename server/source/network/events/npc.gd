extends Node
class_name NpcEvent


var _network: Network.Server
var _account_manager: AccountManager


func _init(
	network: Network.Server,
	account_manager: AccountManager
) -> void:
	_network = network
	_account_manager = account_manager


func npc_moved(map: Map, npc: Npc) -> void:
	var targets: Array = _peers_in_map(map.id)

	if targets.is_empty():
		return

	_network.exec(targets, &"move_npc", [npc.id, npc.cell, npc.facing])


func _peers_in_map(map_id: int) -> Array:
	var peers: Array = []
	var accounts: Dictionary[int, Account] = _account_manager.accounts()

	for peer_id: int in accounts:
		var account: Account = accounts[peer_id]

		if account.has_character() and account.character.map == map_id:
			peers.append(peer_id)

	return peers
