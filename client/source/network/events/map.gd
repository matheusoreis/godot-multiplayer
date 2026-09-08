extends Node
class_name MapEvent


var _main: Main
var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network


func register() -> Error:
	return _network.register([
		map_data,
		character_data,
		character_to_characters,
		move_character,
		correct_movement,
		character_left,
		warp_map
	])


func unregister() -> Error:
	return _network.unregister([
		map_data,
		character_data,
		character_to_characters,
		move_character,
		correct_movement,
		character_left,
		warp_map
	])


func map_data(id: int, identifier: String, bgm: String, bgs: String, size: Vector2i, collisions: Dictionary, warps: Dictionary, characters: Array, npcs: Array) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	_unload_current_map((scene as Game))

	var map_path: String = Constants.MAPS_DATA_DIRECTORY + "%d.tscn" % id

	if not ResourceLoader.exists(map_path):
		push_error("Mapa não encontrado: ", map_path)
		return

	var packed_map: PackedScene = load(map_path)

	if not packed_map:
		push_error("Falha ao carregar cena do mapa: ", map_path)
		return

	var map_instance: Map = packed_map.instantiate()

	if not map_instance:
		push_error("Falha ao instanciar mapa: ", map_path)
		return

	map_instance.setup(id, identifier, bgm, bgs, size)

	map_instance.import_collisions(collisions)
	map_instance.import_warps(warps)

	var character_path: String = "res://source/gameplay/entity/character/character.tscn"

	if not ResourceLoader.exists(character_path):
		push_error("Cena do personagem não encontrada: ", character_path)
		return

	var packed_character: PackedScene = load(character_path)

	if not packed_character:
		push_error("Falha ao carregar cena do personagem: ", character_path)
		return

	for data in characters:
		var character: Character = packed_character.instantiate()

		if character == null:
			continue

		character.setup(
			data[0],
			data[1],
			data[2],
			data[3],
			data[4],
			data[5]
		)

		map_instance.add_character(character)

	var npc_path: String = "res://source/gameplay/entity/npc/npc.tscn"

	if not ResourceLoader.exists(npc_path):
		push_error("Cena do NPC não encontrada: ", npc_path)
	else:
		var packed_npc: PackedScene = load(npc_path)

		if not packed_npc:
			push_error("Falha ao carregar cena do NPC: ", npc_path)
		else:
			for data in npcs:
				var npc: Npc = packed_npc.instantiate()

				if npc == null:
					continue

				npc.setup(
					data[0],
					data[1],
					data[2],
					id,
					data[3],
					data[4]
				)

				map_instance.add_npc(npc)

	(scene as Game).current_map = map_instance
	(scene as Game).add_child(map_instance)

	_network.exec(&"enter_map")


func character_data(data: Array) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	var map: Map = (scene as Game).current_map

	if map == null:
		return

	var character_path: String = "res://source/gameplay/entity/character/character.tscn"

	if not ResourceLoader.exists(character_path):
		push_error("Cena do personagem não encontrada: ", character_path)
		return

	var packed_character: PackedScene = load(character_path)

	if not packed_character:
		push_error("Falha ao carregar cena do personagem: ", character_path)
		return

	var character: Character = packed_character.instantiate()

	if character == null:
		push_error("Falha ao instanciar personagem")
		return

	character.setup(
		data[0],
		data[1],
		data[2],
		data[3],
		data[4],
		data[5]
	)

	var map_pixel_size: Vector2i = map.pixel_size()

	var camera: Camera2D = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_pixel_size.x
	camera.limit_bottom = map_pixel_size.y
	camera.zoom = Vector2i(2, 2)
	character.add_child(camera)

	(scene as Game).current_map.add_character(character)
	(scene as Game).current_character = character

	character.start_warp_cooldown()


func character_to_characters(data: Array) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	var character_path: String = "res://source/gameplay/entity/character/character.tscn"

	if not ResourceLoader.exists(character_path):
		push_error("Cena do personagem não encontrada: ", character_path)
		return

	var packed_character: PackedScene = load(character_path)

	if not packed_character:
		push_error("Falha ao carregar cena do personagem: ", character_path)
		return

	var character: Character = packed_character.instantiate()

	if character == null:
		push_error("Falha ao instanciar personagem")
		return

	character.setup(
		data[0],
		data[1],
		data[2],
		data[3],
		data[4],
		data[5]
	)

	(scene as Game).current_map.add_character(character)


func move_character(id: int, direction: Vector2i) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	var character: Character = (scene as Game).current_map.get_character(id)

	if character == null:
		return

	character.move(direction)


func correct_movement(cell: Vector2i, facing: Vector2i) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	(scene as Game).current_character.correct(cell, facing)


func character_left(id: int) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	(scene as Game).current_map.remove_character(id)


func warp_map(_map_id: int) -> void:
	var scene: Scene = _main.current_scene
	if scene is not Game:
		return

	_unload_current_map((scene as Game))


func _unload_current_map(game: Game) -> void:
	if game.current_map == null:
		return

	var old_map: Map = game.current_map

	game.current_map = null
	game.current_character = null

	if old_map.get_parent():
		old_map.get_parent().remove_child(old_map)

	old_map.free()
