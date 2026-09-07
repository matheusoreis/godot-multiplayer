extends Entity
class_name Npc


var can_walk: bool

# Fila de passos pendentes da sequência atual (ex: [LEFT, LEFT, LEFT, DOWN]).
# Cada elemento é uma direção (Vector2i) que ainda falta andar.
var _pending_steps: Array[Vector2i] = []

# Tempo (em segundos) até a próxima decisão de movimento.
var _decision_timer: float = 0.0

# Tempo (em segundos) até o próximo passo da sequência atual.
var _step_timer: float = 0.0


func _init(
	id: int,
	identifier: String,
	spritesheet: String,
	map: int,
	cell: Vector2i,
	facing: Vector2i,
	can_walk: bool
) -> void:
	super(id, identifier, spritesheet, map, cell, facing)

	self.can_walk = can_walk

	if can_walk:
		_reset_decision_timer()


func move(direction: Vector2i) -> void:
	facing = direction
	cell += direction


# Chamado a cada tick do NpcManager. Retorna true quando o NPC está pronto
# para tentar dar um passo agora (o Manager é quem valida com Map.can_pass
# e efetivamente move).
func advance_timers(delta: float) -> bool:
	if not can_walk:
		return false

	if not _pending_steps.is_empty():
		_step_timer -= delta

		if _step_timer <= 0.0:
			return true

		return false

	_decision_timer -= delta

	if _decision_timer <= 0.0:
		_pending_steps = _roll_movement_sequence()
		_reset_decision_timer()
		_step_timer = 0.0
		return not _pending_steps.is_empty()

	return false


# Retorna a próxima direção pendente sem removê-la da fila.
func peek_next_step() -> Vector2i:
	if _pending_steps.is_empty():
		return Vector2i.ZERO

	return _pending_steps[0]


# Confirma que o passo no topo da fila foi executado (ou descarta o
# restante da sequência, se o caminho foi bloqueado no meio).
func consume_step(success: bool) -> void:
	if _pending_steps.is_empty():
		return

	_pending_steps.pop_front()

	if not success:
		_pending_steps.clear()

	_step_timer = Constants.NPC_STEP_INTERVAL


func _reset_decision_timer() -> void:
	_decision_timer = randf_range(
		Constants.NPC_DECISION_INTERVAL_MIN,
		Constants.NPC_DECISION_INTERVAL_MAX
	)


func _roll_movement_sequence() -> Array[Vector2i]:
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	var direction: Vector2i = directions[randi() % directions.size()]
	var steps: int = randi_range(
		Constants.NPC_MIN_STEPS_PER_MOVE,
		Constants.NPC_MAX_STEPS_PER_MOVE
	)

	var sequence: Array[Vector2i] = []

	for i in steps:
		sequence.append(direction)

	return sequence
