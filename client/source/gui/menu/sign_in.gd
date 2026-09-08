extends PanelContainer
class_name SignInUi


var _main: Main
var _scene: Scene

var _network: Network.Client


func _ready() -> void:
	var main: Main = get_tree().root.get_node("./Main")
	if main == null:
		return

	_main = main

	if main.current_scene == null:
		return

	_scene = main.current_scene
	_scene.network_ready.connect(func(network: Network.Client) -> void: _network = network, CONNECT_ONE_SHOT)


func _show_confirmation(message: String) -> void:
	if _scene is not Menu:
		return

	var confirmation_ui: ConfirmationUi = (_scene as Menu).get_interface(&"Confirmation")
	confirmation_ui.setup(message)

	confirmation_ui.confirmed.connect(func() -> void: (_scene as Menu).hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: (_scene as Menu).hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	(_scene as Menu).show_interface(&"Confirmation")


func _is_email_valid(email: String) -> bool:
	return RegEx.create_from_string(Constants.EMAIL_REGEX).search(email) != null


func _is_password_valid(password: String) -> bool:
	return RegEx.create_from_string(Constants.PASSWORD_REGEX).search(password) != null


func _on_sign_in_pressed() -> void:
	if _scene is not Menu:
		return

	var email: String = %Email.text
	var password: String = %Password.text

	if not _is_email_valid(email):
		_show_confirmation("INVALID_EMAIL")
		return

	if not _is_password_valid(password):
		_show_confirmation("INVALID_PASSWORD")
		return

	_network.exec(&"sign_in", [
		email.to_lower(), password,
		Constants.MAJOR_VERSION, Constants.MINOR_VERSION, Constants.REVISION_VERSION
	])


func _on_close_pressed() -> void:
	if _scene is not Menu:
		return

	var confirmation_ui: ConfirmationUi = (_scene as Menu).get_interface(&"Confirmation")

	confirmation_ui.setup("EXIT_GAME")

	confirmation_ui.confirmed.connect(func() -> void: get_tree().quit(), CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: (_scene as Menu).hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	(_scene as Menu).show_interface(&"Confirmation")


func _on_sign_up_pressed() -> void:
	if _scene is not Menu:
		return

	(_scene as Menu).show_interface(&"SignUp")
	(_scene as Menu).hide_interface(&"SignIn")
