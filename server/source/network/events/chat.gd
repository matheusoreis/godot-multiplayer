extends Node
class_name ChatEvent


var _network: Network


func _init(network: Network) -> void:
	_network = network


func register() -> Error:
	return _network.register([
		map_message,
		global_message
	])


func unregister() -> Error:
	return _network.unregister([
		map_message,
		global_message
	])


func map_message() -> void:
	pass


func global_message() -> void:
	pass
