extends Entity
class_name Npc


var can_walk: bool

var _remaining_steps: int = 0

var _decision_timer: float = 0.0
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


func advance_timers(delta: float) -> bool:
	if not can_walk:
		return false

	if _remaining_steps > 0:
		_step_timer -= delta

		if _step_timer <= 0.0:
			return true

		return false

	_decision_timer -= delta

	if _decision_timer <= 0.0:
		_remaining_steps = randi_range(
			Constants.NPC_MIN_STEPS_PER_MOVE,
			Constants.NPC_MAX_STEPS_PER_MOVE
		)
		_reset_decision_timer()
		_step_timer = 0.0
		return true

	return false


func roll_step_direction() -> Vector2i:
	const DIRECTIONS: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	return DIRECTIONS[randi() % DIRECTIONS.size()]


func consume_step(success: bool) -> void:
	if _remaining_steps <= 0:
		return

	_remaining_steps -= 1

	if not success:
		_remaining_steps = 0

	_step_timer = Constants.NPC_STEP_INTERVAL


func _reset_decision_timer() -> void:
	_decision_timer = randf_range(
		Constants.NPC_DECISION_INTERVAL_MIN,
		Constants.NPC_DECISION_INTERVAL_MAX
	)
