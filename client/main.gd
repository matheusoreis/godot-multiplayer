extends Node
class_name Main


var _action_event: ActionEvent
var _account_event: AccountEvent
var _map_event: MapEvent
var _chat_event: ChatEvent


func _ready() -> void:
	if not _setup_network():
		return

	Network.connected.connect(_on_connected)
	Network.disconnected.connect(_on_disconnected)


func _setup_network() -> bool:
	print("Iniciando cliente em %s:%d" % [
		Constants.HOST,
		Constants.PORT,
	])

	var err: Error = Network.start(Constants.HOST, Constants.PORT)
	if err != OK:
		push_error("Erro ao iniciar o cliente (%s)." % error_string(err))
		return false

	_action_event = ActionEvent.new()
	var action_err: Error = _action_event.register()
	if action_err != OK:
		return false

	_account_event = AccountEvent.new()
	var account_err: Error = _account_event.register()
	if account_err != OK:
		return false

	_map_event = MapEvent.new()
	var map_err: Error = _map_event.register()
	if map_err != OK:
		return false


	_chat_event = ChatEvent.new()
	var chat_err: Error = _chat_event.register()
	if chat_err != OK:
		return false

	print("Cliente iniciado com sucesso!")
	return true


func _on_connected() -> void:
	print("Peer %d conectado.")


func _on_disconnected() -> void:
	print("Peer %d desconectado.")
