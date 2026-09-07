extends Node
class_name Network


signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)


var _network: Multiplayer.Server


func _init() -> void:
	_network = Multiplayer.Server.new()

	_network.peer_connected.connect(
		func(peer_id: int) -> void:
			peer_connected.emit(peer_id)
	)

	_network.peer_disconnected.connect(
		func(peer_id: int) -> void:
			peer_disconnected.emit(peer_id)
	)


func start(host: String, port: int, max_peers: int) -> Error:
	return _network.start(host, port, max_peers)


func stop() -> Error:
	return _network.stop()


func register(remote_funcs: Array[Callable]) -> Error:
	return _network.register(remote_funcs)


func unregister(remote_funcs: Array[Callable]) -> Error:
	return _network.unregister(remote_funcs)


func exec(target: Variant, function: StringName, args: Array = []) -> Error:
	return _network.exec(target, function, args)


func get_peers() -> Array[int]:
	return _network.get_peers()


func get_peer_count() -> int:
	return _network.get_peer_count()


func has_peer(peer_id: int) -> bool:
	return _network.has_peer(peer_id)


func sender_id() -> int:
	return _network.sender_id()


func peer_address(peer_id: int) -> String:
	return _network.peer_address(peer_id)


func kick(peer_id: int) -> void:
	_network.kick(peer_id)


func poll() -> void:
	_network.poll()
