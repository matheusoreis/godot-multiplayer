extends Node
class_name MapEvent


var _network: Network.Client


func _init(network: Network.Client) -> void:
	_network = network


func register() -> Error:
	return _network.register([
	])


func unregister() -> Error:
	return _network.unregister([
	])
