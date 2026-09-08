extends PanelContainer
class_name CharacterCreationUi


var _main: Main
var _scene: Scene

var _network: Network.Client

var _sprites: Array[CompressedTexture2D] = []
var _current_index: int = 0


func _ready() -> void:
	var main: Main = get_tree().root.get_node("./Main")
	if main == null:
		return

	_main = main

	if main.current_scene == null:
		return

	_scene = main.current_scene
	_scene.network_ready.connect(func(network: Network.Client) -> void: _network = network, CONNECT_ONE_SHOT)

	_load_sprites()
	_update_preview()


func _load_sprites() -> void:
	for sprite_name in Constants.AVALIABLE_SPRITES:
		var path: String = Constants.CHARACTER_SPRITE_DIRECTORY + sprite_name + ".png"
		var texture: CompressedTexture2D = load(path)

		if not texture:
			continue

		_sprites.append(texture)


func _update_preview() -> void:
	if _sprites.is_empty():
		return

	var atlas: AtlasTexture = %Preview.texture
	atlas.atlas = _sprites[_current_index]


func _show_confirmation(message: String, confirmed: Callable) -> void:
	if _scene is not Menu:
		return

	var confirmation_ui: ConfirmationUi = (_scene as Menu).get_interface(&"Confirmation")
	confirmation_ui.setup(message)

	confirmation_ui.confirmed.connect(confirmed, CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: (_scene as Menu).hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	(_scene as Menu).show_interface(&"Confirmation")


func _validate_identifier(identifier: String) -> String:
	if identifier.is_empty():
		return "Informe o nome e tente novamente!"
	return ""


func _on_back_pressed() -> void:
	if _sprites.is_empty():
		return

	_current_index = (_current_index - 1 + _sprites.size()) % _sprites.size()
	_update_preview()


func _on_next_pressed() -> void:
	if _sprites.is_empty():
		return

	_current_index = (_current_index + 1) % _sprites.size()
	_update_preview()


func _on_confirm_pressed() -> void:
	if _sprites.is_empty():
		return

	if _scene is not Menu:
		return

	var identifier: String = %Identifier.text
	var error: String = _validate_identifier(identifier)

	if not error.is_empty():
		_show_confirmation(error,
			func() -> void: (_scene as Menu).hide_interface(&"Confirmation")
		)
		return

	var selected_name: String = Constants.AVALIABLE_SPRITES[_current_index]
	_network.exec(&"create_character", [identifier, selected_name])


func _on_cancel_pressed() -> void:
	if _scene is not Menu:
		return

	(_scene as Menu).show_interface(&"CharacterSelection")
	(_scene as Menu).hide_interface(&"CharacterCreation")
