extends Node
class_name Main


var _network: Network


var _account_event: AccountEvent
var _map_event: MapEvent
var _chat_event: ChatEvent


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

	_account_event = AccountEvent.new(_network)
	var account_err: Error = _account_event.register()
	if account_err != OK:
		return false

	_map_event = MapEvent.new(_network)
	var map_err: Error = _map_event.register()
	if map_err != OK:
		return false

	_chat_event = ChatEvent.new(_network)
	var chat_err: Error = _chat_event.register()
	if chat_err != OK:
		return false

	print("Servidor iniciado com sucesso!")
	return true


func _on_peer_connected(peer_id: int) -> void:
	print("Peer %d conectado." % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer %d desconectado." % peer_id)
