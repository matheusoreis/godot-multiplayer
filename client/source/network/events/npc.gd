extends Node
class_name NpcEvent


var _main: Main
var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func register() -> Error:
	return _network.register([
		move_npc
	])


func unregister() -> Error:
	return _network.unregister([
		move_npc
	])


func move_npc(id: int, _cell: Vector2i, direction: Vector2i) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	var map: Map = (scene as Game).current_map
	if map == null:
		return

	var npc: Npc = map.get_npc(id)

	if npc == null:
		return

	npc.move(direction)
