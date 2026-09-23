extends Entity
class_name Character


class _Playback:
	var columns: int
	var frame_duration: float
	var elapsed: float = 0.0
	var frame: int = 0
	var on_finished: Callable

	func _init(columns: int, duration: float, on_finished: Callable) -> void:
		self.columns = columns
		self.frame_duration = duration / float(max(columns, 1))
		self.on_finished = on_finished


var role: int

var _warp_cooldown: float = 0.0

var _playback: _Playback

var _pending_attack: bool = false


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


func _physics_process(delta: float) -> void:
	_process_playback(delta)

	if is_busy():
		return

	super._physics_process(delta)
	_update_warp_cooldown(delta)


func is_warping() -> bool:
	return _warp_cooldown > 0.0


func has_pending_attack() -> bool:
	return _pending_attack


func is_busy() -> bool:
	return _playback != null


func is_attacking() -> bool:
	return is_busy()


func is_admin() -> bool:
	return role >= Constants.ROLE_ADMIN


func is_moderator() -> bool:
	return role >= Constants.ROLE_MODERATOR


func start_warp_cooldown() -> void:
	_warp_cooldown = Constants.WARP_COOLDOWN
	_queue.clear()


func move(direction: Vector2i) -> void:
	if is_busy() or has_pending_attack():
		return
	super.move(direction)


func play(texture: Texture2D, columns: int, duration: float, on_finished: Callable = Callable()) -> bool:
	if is_transitioning() or is_busy():
		return false

	_queue.clear()
	_playback = _Playback.new(columns, duration, on_finished)
	%Sprite2D.texture = texture
	%Sprite2D.hframes = columns
	%Sprite2D.vframes = DIRECTION_SPRITE_ROW.size()
	_sync_frame()
	return true


func attack() -> bool:
	if is_busy():
		return false

	if is_transitioning():
		_pending_attack = true
		return true

	return _start_attack()


func _start_attack() -> bool:
	return play(
		load(Constants.CHARACTER_SPRITE_DIRECTORY + spritesheet + "_attack.png"),
		Constants.ATTACK_SPRITESHEET_COLUMNS,
		Constants.ATTACK_DURATION
	)


func correct(new_cell: Vector2i, new_facing: Vector2i) -> void:
	_playback = null
	_pending_attack = false
	super.correct(new_cell, new_facing)


func _finish_transition() -> void:
	super._finish_transition()

	if _pending_attack:
		_pending_attack = false
		_start_attack()


func _active_column() -> int:
	if _playback != null:
		return _playback.frame
	return super._active_column()


func _update_warp_cooldown(delta: float) -> void:
	if _warp_cooldown > 0.0:
		_warp_cooldown = max(_warp_cooldown - delta, 0.0)


func _process_playback(delta: float) -> void:
	if _playback == null:
		return

	_playback.elapsed += delta
	if _playback.elapsed < _playback.frame_duration:
		_sync_frame()
		return

	_playback.elapsed = 0.0
	_playback.frame += 1

	if _playback.frame >= _playback.columns:
		_finish_playback()
	_sync_frame()


func _finish_playback() -> void:
	var on_finished: Callable = _playback.on_finished

	_playback = null
	_current_frame = StepFrame.IDLE
	_apply_walk_sheet()

	if on_finished.is_valid():
		on_finished.call()
