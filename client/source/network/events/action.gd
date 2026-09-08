extends Node
class_name ActionEvent


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
		confirmation
	])


func unregister() -> Error:
	return _network.unregister([
		confirmation
	])


func confirmation(code: String) -> void:
	if _scene is not Menu:
		return

	var confirmation_ui: ConfirmationUi = _scene.get_interface(&"Confirmation")

	confirmation_ui.setup(tr(code))

	confirmation_ui.confirmed.connect(func() -> void: _scene.hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: _scene.hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	_scene.show_interface(&"Confirmation")
