extends Node
class_name AccountEvent


var _main: Main

var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
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
	var scene: Scene = _main.current_scene
	if scene is not Menu:
		return

	_network.exec(&"list_characters")

	(scene as Menu).hide_interface(&"SignIn")
	(scene as Menu).show_interface(&"CharacterSelection")


func sign_up() -> void:
	var scene: Scene = _main.current_scene
	if scene is not Menu:
		return

	_network.exec(&"list_characters")

	(scene as Menu).hide_interface(&"SignUp")
	(scene as Menu).show_interface(&"CharacterSelection")


func list_characters(characters: Array) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Menu:
		return

	var character_selection_ui: CharacterSelectionUi = (scene as Menu).get_interface(&"CharacterSelection")
	character_selection_ui.setup(characters)

	(scene as Menu).hide_interface(&"CharacterCreation")
	(scene as Menu).show_interface(&"CharacterSelection")


func create_character() -> void:
	_network.exec(&"list_characters")


func delete_character() -> void:
	_network.exec(&"list_characters")


func select_character() -> void:
	_main.go_to_game()
