extends Node
class_name NpcManager


var _map_manager: MapManager
var _npc_event: NpcEvent
var _npc_repository: NpcRepository


func _init(map_manager: MapManager, npc_event: NpcEvent, npc_repository: NpcRepository) -> void:
	_map_manager = map_manager
	_npc_event = npc_event
	_npc_repository = npc_repository


func load_all_npcs() -> void:
	var models: Array[Models.NpcModel] = await _npc_repository.get_all_npcs()

	for model in models:
		var map: Map = _map_manager.map(model.map_id)

		if map == null:
			push_warning("NPC %d referencia mapa %d inexistente, ignorado." % [model.id, model.map_id])
			continue

		var npc: Npc = Npc.new(
			model.id,
			model.identifier,
			model.spritesheet,
			model.map_id,
			Vector2i(model.cell_x, model.cell_y),
			Vector2i(model.facing_x, model.facing_y),
			model.can_walk != 0
		)

		map.add_npc(npc)

	print("%d NPCs carregados." % models.size())


func tick(delta: float) -> void:
	for map in _map_manager.all():
		for npc: Npc in map.npcs.values():
			if not npc.advance_timers(delta):
				return

			var direction: Vector2i = npc.roll_step_direction()

			if not map.can_pass(npc.cell, direction):
				npc.consume_step(false)
				return

			npc.move(direction)
			npc.consume_step(true)

			_npc_event.npc_moved(map, npc)
