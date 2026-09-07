extends Node


signal connected()
signal disconnected()


var network: Multiplayer.Client


func _init() -> void:
	network = Multiplayer.Client.new()

	network.connected.connect(
		func() -> void:
			connected.emit()
	)

	network.disconnected.connect(
		func() -> void:
			disconnected.emit()
	)


func _physics_process(_delta: float) -> void:
	if network:
		network.poll()


func start(host: String, port: int) -> Error:
	return network.start(host, port)


func stop() -> Error:
	return await network.stop()


func register(remote_funcs: Array[Callable]) -> Error:
	return network.register(remote_funcs)


func unregister(remote_funcs: Array[Callable]) -> Error:
	return network.unregister(remote_funcs)


func exec(fn_path: StringName, args: Array = []) -> Error:
	return network.exec(fn_path, args)
