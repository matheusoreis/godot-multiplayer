extends PanelContainer
class_name CharacterSelectionUi


var _main: Main
var _scene: Scene

var _network: Network.Client

var _characters: Array = []
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

	_update_display()


func setup(characters: Array) -> void:
	_characters = characters
	_current_index = 0
	_update_display()


func _is_empty_slot() -> bool:
	return _current_index >= _characters.size()


func _update_display() -> void:
	if _is_empty_slot():
		_show_empty_slot_state()
		return

	var character: Array = _characters[_current_index]

	var identifier: String = character[1] if character.size() > 1 else ""
	var spritesheet: String = character[2] if character.size() > 2 else ""

	%Identifier.text = identifier

	var path: String = Constants.CHARACTER_SPRITE_DIRECTORY + spritesheet + ".png"
	var texture: CompressedTexture2D = load(path)

	var atlas: AtlasTexture = %Preview.texture
	atlas.atlas = texture

	%New.visible = false
	%Select.visible = true
	%Delete.visible = true


func _show_empty_slot_state() -> void:
	%Identifier.text = ""
	%New.visible = true
	%Select.visible = false
	%Delete.visible = false
	_clear_preview()


func _clear_preview() -> void:
	var atlas: AtlasTexture = %Preview.texture
	atlas.atlas = null


func _get_character_id(character: Array) -> int:
	return character[0] if character.size() > 0 else -1


func _show_confirmation(message: String, confirmed: Callable) -> void:
	if _scene is not Menu:
		return

	var confirmation_ui: ConfirmationUi = (_scene as Menu).get_interface(&"Confirmation")
	confirmation_ui.setup(message)

	confirmation_ui.confirmed.connect(confirmed, CONNECT_ONE_SHOT)
	confirmation_ui.canceled.connect(func() -> void: (_scene as Menu).hide_interface(&"Confirmation"), CONNECT_ONE_SHOT)

	(_scene as Menu).show_interface(&"Confirmation")


func _on_back_pressed() -> void:
	if _current_index > 0:
		_current_index -= 1
		_update_display()


func _on_next_pressed() -> void:
	if _current_index < _characters.size():
		_current_index += 1
		_update_display()


func _on_new_pressed() -> void:
	if _scene is not Menu:
		return

	(_scene as Menu).show_interface(&"CharacterCreation")
	(_scene as Menu).hide_interface(&"CharacterSelection")


func _on_select_pressed() -> void:
	if _scene is not Menu:
		return

	if _is_empty_slot():
		_show_confirmation("Nenhum personagem selecionado!",
			func() -> void: (_scene as Menu).hide_interface(&"Confirmation")
		)
		return

	var character_id: int = _get_character_id(_characters[_current_index])
	if character_id != -1:
		_network.exec(&"select_character", [character_id])


func _on_delete_pressed() -> void:
	if _scene is not Menu:
		return

	if _is_empty_slot():
		_show_confirmation("Nenhum personagem selecionado!",
			func() -> void: (_scene as Menu).hide_interface(&"Confirmation")
		)
		return

	var character_id: int = _get_character_id(_characters[_current_index])
	if character_id == -1:
		return

	_show_confirmation("Tem certeza que deseja apagar este personagem?",
		func() -> void:
			_network.exec(&"delete_character", [character_id])
			(_scene as Menu).hide_interface(&"Confirmation")
	)
