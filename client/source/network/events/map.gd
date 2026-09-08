extends Node
class_name MapEvent


var _main: Main

var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func register() -> Error:
	return _network.register([
	])


func unregister() -> Error:
	return _network.unregister([
	])
