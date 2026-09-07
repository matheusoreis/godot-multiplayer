extends Node
class_name Main


var _math_event: MathEvent


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

	_math_event = MathEvent.new(Network)
	var math_err: Error = _math_event.register()
	if math_err != OK:
		return false

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
