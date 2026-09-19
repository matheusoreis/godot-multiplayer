extends Entity
class_name Character


var _queue: Queue
var _animator: CharacterAnimator

var _movement_offset: Vector2 = Vector2.ZERO
var _is_transitioning: bool = false

var _warp_cooldown: float = 0.0


var role: int


func setup(
	id: int,
	identifier: String,
	spritesheet: String,
	map: int,
	cell: Vector2i,
	facing: Vector2i,
	role: int = Constants.ROLE_NONE
) -> void:
	super.setup(id, identifier, spritesheet, map, cell, facing)

	self.role = role

	_queue = Queue.new(Constants.MAX_PENDING_MOVES)
	_animator = CharacterAnimator.new(%Sprite2D)

	_load_texture()
	_calculate_sprite_offset()

	position = _cell_to_center(cell)
	_animator.sync(facing)


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_position_sync()
	_update_warp_cooldown(delta)


func is_transitioning() -> bool:
	return _is_transitioning


func is_warping() -> bool:
	return _warp_cooldown > 0.0


func is_admin() -> bool:
	return role >= Constants.ROLE_ADMIN


func is_moderator() -> bool:
	return role >= Constants.ROLE_MODERATOR


func start_warp_cooldown() -> void:
	_warp_cooldown = Constants.WARP_COOLDOWN
	_queue.clear()


func _update_warp_cooldown(delta: float) -> void:
	if _warp_cooldown > 0.0:
		_warp_cooldown = max(_warp_cooldown - delta, 0.0)


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
	_animator.sync(facing)


func get_overhead_anchor() -> Vector2:
	if %Sprite2D == null or %Sprite2D.texture == null:
		return Vector2(0, -32)

	var columns: int = Constants.SPRITESHEET_COLUMNS
	var rows: int = Constants.SPRITESHEET_ROWS
	var frame_size: Vector2 = %Sprite2D.texture.get_size() / Vector2(columns, rows)

	return Vector2(0, -frame_size.y / 2.0)


func _start_move(direction: Vector2i) -> void:
	facing = direction
	_movement_offset = Vector2(-direction) * Constants.CELL_SIZE
	cell += direction
	_is_transitioning = true
	_animator.on_move_started()
	_animator.sync(facing)


func _load_texture() -> void:
	var path: String = Constants.CHARACTER_SPRITE_DIRECTORY + spritesheet + ".png"
	if not ResourceLoader.exists(path):
		return

	%Sprite2D.texture = load(path)


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

	_animator.on_move_progress(_movement_offset)
	_animator.sync(facing)

	if _movement_offset.is_zero_approx():
		_finish_transition()


func _finish_transition() -> void:
	_is_transitioning = false
	_position_sync()
	_animator.on_move_finished()
	_animator.sync(facing)
