extends Node2D
class_name Entity


const DIRECTION_SPRITE_ROW: Dictionary[Vector2i, int] = {
	Vector2i.DOWN: 0,
	Vector2i.LEFT: 1,
	Vector2i.RIGHT: 2,
	Vector2i.UP: 3,
}

enum StepFrame {
	RIGHT_STEP = 0,
	IDLE = 1,
	LEFT_STEP = 2
}


var id: int
var identifier: String

var spritesheet: String

var map: int
var cell: Vector2i
var facing: Vector2i


var _queue: Queue

var _movement_offset: Vector2 = Vector2.ZERO
var _is_transitioning: bool = false

var _walk_texture: Texture2D
var _current_frame: int = StepFrame.IDLE
var _last_step_frame: int = StepFrame.LEFT_STEP


func setup(id: int, identifier: String, spritesheet: String, map: int, cell: Vector2i, facing: Vector2i) -> void:
	self.id = id
	self.identifier = identifier
	self.spritesheet = spritesheet
	self.map = map
	self.cell = cell
	self.facing = facing

	_queue = Queue.new(Constants.MAX_PENDING_MOVES)

	_load_texture()
	_calculate_sprite_offset()

	position = _cell_to_center(cell)
	_sync_frame()


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_position_sync()


func is_transitioning() -> bool:
	return _is_transitioning


func move(direction: Vector2i) -> void:
	if _queue.enqueue(direction):
		return
	_queue.dequeue()
	_queue.enqueue(direction)


func correct(new_cell: Vector2i, new_facing: Vector2i) -> void:
	_queue.clear()
	cell = new_cell
	facing = new_facing
	_movement_offset = Vector2.ZERO
	_is_transitioning = false

	_position_sync()
	_sync_frame()


func get_overhead_anchor() -> Vector2:
	if %Sprite2D == null or %Sprite2D.texture == null:
		return Vector2(0, -32)

	var columns: int = Constants.SPRITESHEET_COLUMNS
	var rows: int = Constants.SPRITESHEET_ROWS
	var frame_size: Vector2 = %Sprite2D.texture.get_size() / Vector2(columns, rows)

	return Vector2(0, -frame_size.y / 2.0)


func _sync_frame() -> void:
	var row: int = DIRECTION_SPRITE_ROW.get(_resolve_cardinal(facing), 0)
	var column: int = _active_column()
	%Sprite2D.frame = row * %Sprite2D.hframes + column


func _active_column() -> int:
	return _current_frame


func _resolve_cardinal(direction: Vector2i) -> Vector2i:
	if DIRECTION_SPRITE_ROW.has(direction):
		return direction

	if absi(direction.x) > absi(direction.y):
		return Vector2i.RIGHT if direction.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if direction.y > 0 else Vector2i.UP


func _toggle_step_frame(previous: int) -> int:
	return StepFrame.RIGHT_STEP if previous == StepFrame.LEFT_STEP else StepFrame.LEFT_STEP


func _start_move(direction: Vector2i) -> void:
	facing = direction
	_movement_offset = Vector2(-direction) * Constants.CELL_SIZE
	cell += direction
	_is_transitioning = true

	_last_step_frame = _toggle_step_frame(_last_step_frame)
	_current_frame = StepFrame.IDLE
	_sync_frame()


func _load_texture() -> void:
	var path: String = Constants.CHARACTER_SPRITE_DIRECTORY + spritesheet + ".png"
	if not ResourceLoader.exists(path):
		return

	_walk_texture = load(path)
	_apply_walk_sheet()


func _apply_walk_sheet() -> void:
	%Sprite2D.texture = _walk_texture
	%Sprite2D.hframes = Constants.SPRITESHEET_COLUMNS
	%Sprite2D.vframes = Constants.SPRITESHEET_ROWS


func _cell_to_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * Constants.CELL_SIZE + Constants.CELL_SIZE / 2.0,
		cell.y * Constants.CELL_SIZE + Constants.CELL_SIZE
	)


func _calculate_sprite_offset() -> void:
	var texture: Texture2D = %Sprite2D.texture
	if texture == null:
		return

	var frame_size: Vector2 = texture.get_size() / Vector2(Constants.SPRITESHEET_COLUMNS, Constants.SPRITESHEET_ROWS)
	%Sprite2D.offset = Vector2(0, -frame_size.y / 2.0)


func _position_sync() -> void:
	position = _cell_to_center(cell) + _movement_offset


func _update_movement(delta: float) -> void:
	if _is_transitioning:
		_process_transition(delta)
		return

	if _queue.is_empty():
		return

	_start_move(_queue.dequeue())


func _process_transition(delta: float) -> void:
	var speed: float = Constants.WALKING_SPEED * Constants.CELL_SIZE * delta
	_movement_offset = _movement_offset.move_toward(Vector2.ZERO, speed)

	_position_sync()

	var walked_enough: bool = _movement_offset.length() > (Constants.CELL_SIZE * Constants.ANIMATION_STEP_THRESHOLD)
	_current_frame = _last_step_frame if walked_enough else StepFrame.IDLE
	_sync_frame()

	if _movement_offset.is_zero_approx():
		_finish_transition()


func _finish_transition() -> void:
	_is_transitioning = false
	_position_sync()
	_current_frame = StepFrame.IDLE
	_sync_frame()
