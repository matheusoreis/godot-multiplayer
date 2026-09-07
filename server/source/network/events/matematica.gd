extends Node
class_name MathEvent


var _network: Network


func _init(network: Network) -> void:
	_network = network


func register() -> Error:
	return _network.register([
		soma
	])


func unregister() -> Error:
	return _network.unregister([
		soma
	])


func soma(a: int, b: int) -> void:
	var sender_id: int = _network.sender_id()

	var resultado: int = a + b

	_network.exec(sender_id, &"soma", [resultado])
