extends Node
class_name Main


var _action_event: ActionEvent
var _account_event: AccountEvent
var _map_event: MapEvent
var _chat_event: ChatEvent


var current_scene: Scene


func _ready() -> void:
	if not _setup_network():
		return

	Network.connected.connect(go_to_menu)
	Network.disconnected.connect(go_to_menu)


func _setup_network() -> bool:
	print("Iniciando cliente em %s:%d" % [
		Constants.HOST,
		Constants.PORT,
	])

	var err: Error = Network.start(Constants.HOST, Constants.PORT)
	if err != OK:
		push_error("Erro ao iniciar o cliente (%s)." % error_string(err))
		return false

	_action_event = ActionEvent.new()
	var action_err: Error = _action_event.register()
	if action_err != OK:
		return false

	_account_event = AccountEvent.new()
	var account_err: Error = _account_event.register()
	if account_err != OK:
		return false

	_map_event = MapEvent.new()
	var map_err: Error = _map_event.register()
	if map_err != OK:
		return false


	_chat_event = ChatEvent.new()
	var chat_err: Error = _chat_event.register()
	if chat_err != OK:
		return false

	print("Cliente iniciado com sucesso!")
	return true


func go_to_menu() -> void:
	_change_scene("res://source/scene/menu/menu.tscn")


func go_to_game() -> void:
	_change_scene("res://source/scene/game/game.tscn")


func _change_scene(scene_path: String) -> void:
	var packed: PackedScene = load(scene_path)
	var scene: Node = packed.instantiate()

	if current_scene != null:
		current_scene.queue_free()

	var class_name_str: String = scene.get_script().get_global_name()
	scene.name = class_name_str

	current_scene = scene
	add_child(scene)
