extends Node
class_name ActionEvent


var _main: Main

var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func register() -> Error:
	return _network.register([
		confirmation
	])


func unregister() -> Error:
	return _network.unregister([
		confirmation
	])


func confirmation(code: String) -> void:
	var scene: Scene = _main.current_scene

	var confirmation_ui: ConfirmationUi = scene.get_interface(&"Confirmation")

	confirmation_ui.setup(tr(code))

	confirmation_ui.confirmed.connect(func() -> void: scene.hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: scene.hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	scene.show_interface(&"Confirmation")
