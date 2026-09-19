extends Node
class_name ChatEvent


var _main: Main

var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func register() -> Error:
	return _network.register([
		local_message,
		global_message
	])


func unregister() -> Error:
	return _network.unregister([
		local_message,
		global_message
	])


func local_message(_sender_id: int, identifier: String, message: String) -> void:
	_show(
		"[color=#FFFFFF][LOCAL]%s: %s[/color]" % [_escape(identifier), _escape(message)]
	)


func global_message(_sender_id: int, identifier: String, message: String) -> void:
	_show(
		"[color=#FFD166][GLOBAL] %s: %s[/color]" % [_escape(identifier), _escape(message)]
	)


func _show(text: String) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	var chat: ChatInterface = scene.get_interface(&"Chat")
	if chat == null:
		return

	chat.add_message(text)


func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
