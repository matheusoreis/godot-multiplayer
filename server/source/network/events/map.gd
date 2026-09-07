extends Node
class_name MapEvent


var _network: Network


func _init(network: Network) -> void:
	_network = network


func register() -> Error:
	return _network.register([
		map_data,
		enter_map,
		leave_map,
		move_character
	])


func unregister() -> Error:
	return _network.unregister([
		map_data,
		enter_map,
		leave_map,
		move_character
	])


func map_data() -> void:
	pass


func enter_map() -> void:
	pass


func leave_map() -> void:
	pass


func move_character() -> void:
	pass
