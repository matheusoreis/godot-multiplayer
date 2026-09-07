extends Node
class_name Main


var _database: Database
var _network: Network


var _account_event: AccountEvent
var _map_event: MapEvent
var _chat_event: ChatEvent

var _account_repository: AccountRepository
var _map_repository: MapRepository


func _ready() -> void:
	if not await _setup_database():
		return

	if not _setup_network():
		return

	_network.peer_connected.connect(_on_peer_connected)
	_network.peer_disconnected.connect(_on_peer_disconnected)


func _physics_process(_delta: float) -> void:
	if _database:
		_database.poll(Constants.DATABASE_POLL_TIME)
	if _network:
		_network.poll()


func _setup_database() -> bool:
	_database = Database.new()

	print("Iniciando banco de dados em %s%s.db" % [
		Constants.DATABASE_PATH,
		Constants.DATABASE_FILENAME
	])

	var err: Error = _database.create(
		Constants.DATABASE_PATH,
		Constants.DATABASE_FILENAME
	)

	if err != OK:
		push_error("Erro ao iniciar o banco de dados (%s)." % error_string(err))
		return false

	_account_repository = AccountRepository.new()
	await _account_repository.setup(_database)

	_map_repository = MapRepository.new()
	await _map_repository.setup(_database)

	print("Banco de dados iniciado com sucesso!")
	return true



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
