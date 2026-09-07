extends RefCounted
class_name Multiplayer


const PACKET_TY: Array[Variant.Type] = [TYPE_INT, TYPE_ARRAY]
const SCOPE: StringName = "Network"


var _lookup: Dictionary[int, Array]
var _framed: Framed


func _init() -> void:
	_lookup = {}
	_framed = Framed.new()


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

	var _client: FramedClient

	var _is_connected: bool


	func _init() -> void:
		super()
		_is_connected = false


	func start(endpoint: String = "127.0.0.1:4242", max_packet_size: int = 512) -> Error:
		var opts := FramedClientOptions.new()
		opts.prefix_len = 2
		opts.endian = Framed.LITTLE
		opts.endpoint = endpoint
		opts.max_packet_size = max_packet_size
		opts.max_packet_backlog = 4
		opts.max_packet_per_tick = 8

		_client = _framed.client(opts)
		if _client == null:
			return ERR_CANT_CONNECT

		_client.connected.connect(_on_connected)
		_client.disconnected.connect(_on_disconnected)
		_client.packet_received.connect(_on_packet_received)

		return OK


	func stop() -> Error:
		if not _client:
			return FAILED

		_client.disconnect_client()
		if _is_connected:
			await disconnected

		_client = null

		return OK


	func poll() -> void:
		if _framed == null:
			return

		_framed.poll()
		if _client:
			_client.poll()


	func exec(fn_path: StringName, args: Array = []) -> Error:
		if _client == null or not _is_connected:
			return ERR_UNCONFIGURED

		var fn_id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send([fn_id, args])
		return OK


	func _send(packet: Array) -> void:
		_client.send(var_to_bytes(packet))


	func _on_connected(ok: bool) -> void:
		_is_connected = ok
		if not ok:
			return
		connected.emit()


	func _on_disconnected() -> void:
		_is_connected = false
		disconnected.emit()


	func _on_packet_received(packet_buf: PackedByteArray) -> void:
		_handle_packet(packet_buf)


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

	var _server: FramedServer

	var _sender_id: int
	var _peer_ids: Array[int]


	func _init() -> void:
		super()
		_peer_ids = []


	func start(endpoint: String = "0.0.0.0:4242", max_peers: int = 10, max_packet_size: int = 512) -> Error:
		var opts := FramedServerOptions.new()
		opts.prefix_len = 2
		opts.endian = Framed.LITTLE
		opts.endpoint = endpoint
		opts.max_clients = max_peers
		opts.max_packet_size = max_packet_size
		opts.max_packet_backlog = 4
		opts.max_packet_per_tick = 8

		_server = _framed.server(opts)
		if _server == null:
			return ERR_CANT_CREATE

		_server.client_connected.connect(_on_client_connected)
		_server.client_disconnected.connect(_on_client_disconnected)
		_server.packet_received.connect(_on_packet_received)

		return OK


	func stop() -> Error:
		if not _server:
			return FAILED

		_server = null
		_peer_ids.clear()

		return OK


	func poll() -> void:
		if _framed == null:
			return

		_framed.poll()
		if _server:
			_server.poll()


	func exec(target: Variant, fn_path: StringName, args: Array = []) -> Error:
		var fn_id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		return _send(target, [fn_id, args])


	func get_peers() -> Array[int]:
		return _peer_ids.duplicate()


	func get_peer_count() -> int:
		return _peer_ids.size()


	func has_peer(peer_id: int) -> bool:
		return _peer_ids.has(peer_id)


	func sender_id() -> int:
		return _sender_id


	func kick(peer_id: int) -> void:
		if not _server:
			return
		_server.kick(peer_id)


	func _on_client_connected(peer_id: int) -> void:
		_peer_ids.append(peer_id)
		peer_connected.emit(peer_id)


	func _on_client_disconnected(peer_id: int) -> void:
		_peer_ids.erase(peer_id)
		peer_disconnected.emit(peer_id)


	func _on_packet_received(peer_id: int, packet_buf: PackedByteArray) -> void:
		_sender_id = peer_id
		_handle_packet(peer_id, packet_buf)


	func _send(target: Variant, packet: Array) -> Error:
		var packet_buf: PackedByteArray = var_to_bytes(packet)

		match typeof(target):
			TYPE_INT:
				if not _peer_ids.has(target):
					return ERR_DOES_NOT_EXIST

				_server.send_to(target, packet_buf)
				return OK

			TYPE_CALLABLE:
				for peer_id: int in _peer_ids:
					if (target as Callable).call(peer_id):
						_server.send_to(peer_id, packet_buf)
				return OK

			TYPE_ARRAY:
				var had_missing: bool = false
				for peer_id: int in target:
					if not _peer_ids.has(peer_id):
						had_missing = true
						continue
					_server.send_to(peer_id, packet_buf)
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
