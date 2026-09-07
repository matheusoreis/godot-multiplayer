extends Node
class_name AccountEvent


var _network: Network


func _init(network: Network) -> void:
	_network = network


func register() -> Error:
	return _network.register([
		sign_in,
		sign_up,
		list_characters,
		create_character,
		delete_character,
		select_character
	])


func unregister() -> Error:
	return _network.unregister([
		sign_in,
		sign_up,
		list_characters,
		create_character,
		delete_character,
		select_character
	])


func sign_in() -> void:
	pass


func sign_up() -> void:
	pass


func list_characters() -> void:
	pass


func create_character() -> void:
	pass


func delete_character() -> void:
	pass


func select_character() -> void:
	pass
