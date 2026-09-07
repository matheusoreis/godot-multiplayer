extends Node
class_name Main


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

	var account_event: AccountEvent = AccountEvent.new()
	var account_err: Error = account_event.register()
	if account_err != OK:
		return false

	add_child(account_event)

	var map_event: MapEvent = MapEvent.new()
	var map_err: Error = map_event.register()
	if map_err != OK:
		return false

	add_child(map_event)

	var chat_event: ChatEvent = ChatEvent.new()
	var chat_err: Error = chat_event.register()
	if chat_err != OK:
		return false

	add_child(chat_event)

	print("Cliente iniciado com sucesso!")
	return true


func _on_connected() -> void:
	print("Peer %d conectado.")


func _on_disconnected() -> void:
	print("Peer %d desconectado.")


func _on_calcular_pressed() -> void:
	var valor1: int = %Valor1.value
	var valor2: int = %Valor2.value

	Network.exec(&"soma", [valor1, valor2])
