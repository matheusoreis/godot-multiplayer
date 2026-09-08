extends RefCounted
class_name CharacterAnimator


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


var _sprite: Sprite2D
var _current_frame: int = StepFrame.IDLE
var _last_step_frame: int = StepFrame.LEFT_STEP


func _init(sprite: Sprite2D) -> void:
	_sprite = sprite
	_sprite.hframes = Constants.SPRITESHEET_COLUMNS
	_sprite.vframes = Constants.SPRITESHEET_ROWS


func on_move_started() -> void:
	_last_step_frame = _toggle_step_frame(_last_step_frame)
	_current_frame = StepFrame.IDLE


func on_move_progress(movement_offset: Vector2) -> void:
	var walked_enough: bool = movement_offset.length() > (Constants.CELL_SIZE * Constants.ANIMATION_STEP_THRESHOLD)
	_current_frame = _last_step_frame if walked_enough else StepFrame.IDLE


func on_move_finished() -> void:
	_current_frame = StepFrame.IDLE


func sync(facing: Vector2i) -> void:
	if _sprite.texture == null:
		return

	var resolved_facing: Vector2i = _resolve_cardinal(facing)
	var row: int = DIRECTION_SPRITE_ROW[resolved_facing]

	_sprite.frame = row * _sprite.hframes + _current_frame


func _resolve_cardinal(facing: Vector2i) -> Vector2i:
	if DIRECTION_SPRITE_ROW.has(facing):
		return facing

	if absi(facing.x) > absi(facing.y):
		return Vector2i.RIGHT if facing.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if facing.y > 0 else Vector2i.UP


func _toggle_step_frame(previous: int) -> int:
	return StepFrame.RIGHT_STEP if previous == StepFrame.LEFT_STEP else StepFrame.LEFT_STEP
