extends Node
class_name MapEvent


var _main: Main
var _scene: Scene

var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func _ready() -> void:
	if _main.current_scene == null:
		return

	_scene = _main.current_scene


func register() -> Error:
	return _network.register([
	])


func unregister() -> Error:
	return _network.unregister([
	])
