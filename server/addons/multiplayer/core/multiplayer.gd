extends RefCounted
class_name Multiplayer


signal error(code: Error)


const PACKET_TY: Array[Variant.Type] = [TYPE_INT, TYPE_ARRAY]
const SCOPE: StringName = "Network"


var _lookup: Dictionary[int, Array]
var _enet_host: ENetConnection


func _init() -> void:
	_lookup = {}


func register(remote_funcs: Array[Callable]) -> Error:
	var registered: Array[StringName] = []

	for fn: Callable in remote_funcs:
		var fn_name: StringName = fn.get_method()
		if fn_name == '<anonymous lambda>':
			return ERR_INVALID_PARAMETER

		var fn_id: int = ('%s.%s' % [SCOPE, fn_name]).hash()
		if _lookup.has(fn_id):
			return ERR_ALREADY_EXISTS

		_lookup[fn_id] = [fn, _get_args_ty(fn.get_object(), fn_name)]
		registered.append(fn_name)

	print("%d método(s) registrado(s): %s" % [registered.size(), ", ".join(registered)])
	return OK


func unregister(remote_funcs: Array[Callable]) -> Error:
	for fn: Callable in remote_funcs:
		var fn_id: int = ('%s.%s' % [SCOPE, fn.get_method()]).hash()
		if not _lookup.has(fn_id):
			return ERR_DOES_NOT_EXIST
		_lookup.erase(fn_id)
	return OK


func _get_args_ty(obj: Object, fn_name: StringName) -> Array[Variant.Type]:
	var args: Array[Variant.Type] = []
	for method: Dictionary in obj.get_method_list():
		if method.name == fn_name:
			for arg: Dictionary in method.args:
				args.push_back(arg.type)
			return args
	return args


func _validate_args(args_ty: Array[Variant.Type], args: Array) -> Error:
	if args.size() != args_ty.size():
		return ERR_INVALID_PARAMETER

	for i: int in args.size():
		if typeof(args[i]) != args_ty[i]:
			return ERR_INVALID_PARAMETER

	return OK


class Client extends Multiplayer:
	signal connected()
	signal disconnected()

	var _peer: ENetPacketPeer


	func _init() -> void:
		super()


	func start(address: String = "127.0.0.1", port: int = 4242) -> Error:
		_enet_host = ENetConnection.new()
		var err: Error = _enet_host.create_host(1)
		if err != OK:
			return err

		_peer = _enet_host.connect_to_host(address, port)
		if _peer == null:
			return ERR_CANT_CONNECT
		return OK


	func stop() -> Error:
		if not _peer:
			return FAILED

		_peer.peer_disconnect_later()
		await disconnected

		_enet_host.destroy()
		_enet_host = null
		_peer = null

		return OK


	func poll() -> void:
		if _enet_host == null:
			return

		while true:
			var ev: Array = _enet_host.service()
			if ev[0] == ENetConnection.EventType.EVENT_NONE:
				break
			_handle_event(ev)


	func exec(fn_path: StringName, args: Array = []) -> Error:
		if _peer == null:
			return ERR_UNCONFIGURED

		var fn_id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send([fn_id, args])
		return OK


	func _send(packet: Array) -> void:
		_peer.send(0, var_to_bytes(packet), ENetPacketPeer.FLAG_RELIABLE)


	func _handle_event(ev: Array) -> void:
		match ev[0]:
			ENetConnection.EventType.EVENT_ERROR:
				error.emit(FAILED)

			ENetConnection.EventType.EVENT_CONNECT:
				_peer = ev[1]
				connected.emit()

			ENetConnection.EventType.EVENT_DISCONNECT:
				_peer = null
				disconnected.emit()

			ENetConnection.EventType.EVENT_RECEIVE:
				_handle_packet(_peer.get_packet())


	func _handle_packet(packet_buf: PackedByteArray) -> void:
		var packet_value: Variant = bytes_to_var(packet_buf)
		if packet_value == null:
			return

		var packet: Array = packet_value as Array
		if _validate_args(PACKET_TY, packet) != OK:
			return

		var entry: Variant = _lookup.get(packet[0])
		if entry == null:
			return

		if _validate_args(entry[1], packet[1]) == OK:
			entry[0].callv(packet[1])


class Server extends Multiplayer:
	signal peer_connected(peer_id: int)
	signal peer_disconnected(peer_id: int)

	var _peers: Dictionary[int, ENetPacketPeer]
	var _sender_id: int
	var _next_id: int


	func _init() -> void:
		super()
		_peers = {}
		_next_id = 0


	func start(address: String = "0.0.0.0", port: int = 4242, max_peers: int = 10) -> Error:
		_enet_host = ENetConnection.new()
		var err: Error = _enet_host.create_host_bound(address, port, max_peers)
		if err != OK:
			return err
		return OK


	func stop() -> Error:
		if not _enet_host:
			return FAILED

		_enet_host.flush()
		_enet_host.destroy()
		_enet_host = null
		_peers.clear()

		return OK


	func poll() -> void:
		if _enet_host == null:
			return

		while true:
			var ev: Array = _enet_host.service()
			if ev[0] == ENetConnection.EventType.EVENT_NONE:
				break
			_handle_event(ev)


	func exec(target: Variant, fn_path: StringName, args: Array = []) -> Error:
		var fn_id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		return _send(target, [fn_id, args])


	func get_peers() -> Array[int]:
		return _peers.keys()


	func get_peer_count() -> int:
		return _peers.size()


	func has_peer(peer_id: int) -> bool:
		return _peers.has(peer_id)


	func sender_id() -> int:
		return _sender_id


	func peer_address(peer_id: int) -> String:
		var peer: ENetPacketPeer = _peers.get(peer_id)
		if peer == null:
			return ""
		return peer.get_meta('address', "")


	func kick(peer_id: int) -> void:
		var peer: ENetPacketPeer = _peers.get(peer_id)
		if peer == null:
			return
		peer.peer_disconnect()


	func _handle_event(ev: Array) -> void:
		match ev[0]:
			ENetConnection.EventType.EVENT_ERROR:
				error.emit(FAILED)

			ENetConnection.EventType.EVENT_CONNECT:
				var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
				var peer_id: int = _next_id

				peer.set_meta('peer_id', peer_id)
				peer.set_meta('address', peer.get_remote_address())

				_peers[peer_id] = peer
				_next_id += 1
				peer_connected.emit(peer_id)

			ENetConnection.EventType.EVENT_DISCONNECT:
				var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
				var peer_id: int = peer.get_meta('peer_id') as int

				_peers.erase(peer_id)
				peer_disconnected.emit(peer_id)

			ENetConnection.EventType.EVENT_RECEIVE:
				var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
				_sender_id = peer.get_meta('peer_id') as int
				_handle_packet(_sender_id, peer.get_packet())


	func _send(target: Variant, packet: Array) -> Error:
		var packet_buf: PackedByteArray = var_to_bytes(packet)

		match typeof(target):
			TYPE_INT:
				var peer: ENetPacketPeer = _peers.get(target) as ENetPacketPeer
				if peer == null:
					return ERR_DOES_NOT_EXIST

				peer.send(0, packet_buf, ENetPacketPeer.FLAG_RELIABLE)
				return OK

			TYPE_CALLABLE:
				for peer_id: int in _peers:
					if (target as Callable).call(peer_id):
						_peers[peer_id].send(0, packet_buf, ENetPacketPeer.FLAG_RELIABLE)
				return OK

			TYPE_ARRAY:
				var had_missing: bool = false
				for peer_id: int in target:
					var peer: ENetPacketPeer = _peers.get(peer_id) as ENetPacketPeer
					if peer != null:
						peer.send(0, packet_buf, ENetPacketPeer.FLAG_RELIABLE)
					else:
						had_missing = true
				return ERR_DOES_NOT_EXIST if had_missing else OK
			_:
				return ERR_INVALID_PARAMETER


	func _handle_packet(peer_id: int, packet_buf: PackedByteArray) -> void:
		var packet_value: Variant = bytes_to_var(packet_buf)
		if packet_value == null:
			kick(peer_id)
			return

		var packet: Array = packet_value as Array
		if _validate_args(PACKET_TY, packet) != OK:
			kick(peer_id)
			return

		var entry: Variant = _lookup.get(packet[0])
		if entry == null:
			kick(peer_id)
			return

		if _validate_args(entry[1], packet[1]) == OK:
			entry[0].callv(packet[1])
			return

		kick(peer_id)
