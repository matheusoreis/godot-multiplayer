extends PanelContainer
class_name ChatInterface


const FOCUSED_OPACITY: float = 0.8
const UNFOCUSED_OPACITY: float = 0.4


var _main: Main
var _scene: Scene

var _network: Network.Client

var _panel_style: StyleBoxFlat


func _ready() -> void:
	var main: Main = get_tree().root.get_node("./Main")
	if main == null:
		return

	_main = main

	if main.current_scene == null:
		return

	_scene = main.current_scene
	_scene.network_ready.connect(func(network: Network.Client) -> void: _network = network, CONNECT_ONE_SHOT)

	var stylebox: StyleBox = get_theme_stylebox("panel")
	if stylebox is StyleBoxFlat:
		_panel_style = stylebox
		_panel_style.bg_color.a = UNFOCUSED_OPACITY


func add_message(text: String) -> void:
	while %History.get_line_count() >= 100:
		%History.remove_line(0)

	%History.append_text(text + "\n")
	%History.scroll_to_line(%History.get_line_count() - 1)


func _on_send_pressed() -> void:
	var text: String = %Message.text
	if text.is_empty():
		return

	_on_message_text_submitted(text)
	%Message.text = ""


func _on_message_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		return

	if new_text.begins_with("/"):
		_handle_command(new_text)
		%Message.release_focus()
		return

	_network.exec(&"local_message", [new_text])
	%Message.clear()
	%Message.release_focus()


func _handle_command(text: String) -> void:
	var parts: Array = text.split(" ", false)
	var command: String = parts[0].to_lower()

	match command:
		"/global", "/g":
			var message: String = text.substr(parts[0].length() + 1)
			if not message.is_empty():
				_network.exec(&"global_message", [message])
				%Message.clear()

		"/local", "/l":
			var message: String = text.substr(parts[0].length() + 1)
			if not message.is_empty():
				_network.exec(&"local_message", [message])
				%Message.clear()

		"/help", "/?":
			_show_help()
			%Message.clear()
		_:
			add_message("[color=#FF6B6B]Comando desconhecido: %s[/color]" % command)
			%Message.clear()


func _show_help() -> void:
	add_message("[color=#FFFFFF]/global ou /g [mensagem] - Mensagem global[/color]")
	add_message("[color=#FFFFFF]/local ou /l [mensagem] - Mensagem local (mesmo mapa)[/color]")
	add_message("[color=#FFFFFF]/help ou /? - Mostra esta ajuda[/color]")


func _on_close_pressed() -> void:
	hide()


func _on_message_focus_entered() -> void:
	var game: Game = _main.current_scene
	if game == null:
		return

	game.chat_active = true

	if _panel_style != null:
		_panel_style.bg_color.a = FOCUSED_OPACITY


func _on_message_focus_exited() -> void:
	var game: Game = _main.current_scene
	if game == null:
		return

	game.chat_active = false

	if _panel_style != null:
		_panel_style.bg_color.a = UNFOCUSED_OPACITY
