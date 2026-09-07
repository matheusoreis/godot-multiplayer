extends Node
class_name Main


var _network: Network


func _ready() -> void:
	if not _setup_network():
		return

	_network.peer_connected.connect(_on_peer_connected)
	_network.peer_disconnected.connect(_on_peer_disconnected)


func _physics_process(_delta: float) -> void:
	if _network:
		_network.poll()


func _setup_network() -> bool:
	_network = Network.new()

	print("Iniciando servidor em %s:%d" % [
		Constants.HOST,
		Constants.PORT,
	])

	var err: Error = _network.start(Constants.HOST, Constants.PORT, Constants.MAX_PEERS)
	if err != OK:
		push_error("Erro ao iniciar o servidor (%s)." % error_string(err))
		return false

	print("Servidor iniciado com sucesso!")
	return true


func _on_peer_connected(peer_id: int) -> void:
	print("Peer %d conectado." % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer %d desconectado." % peer_id)
