extends RefCounted
class_name Map


var id: int
var identifier: String

var bgm: String
var bgs: String

var size: Vector2i

var collisions: Dictionary[Vector2i, int] = {}
var warps: Dictionary[Vector2i, Dictionary] = {}


func setup(
	id: int,
	identifier: String,
	bgm: String,
	bgs: String,
	size: Vector2i
) -> void:
	self.id = id
	self.identifier = identifier
	self.bgm = bgm
	self.bgs = bgs
	self.size = size


func import_collisions(collisions: Dictionary) -> void:
	self.collisions.assign(collisions)


func import_warps(warps: Dictionary) -> void:
	self.warps.assign(warps)


func pixel_size() -> Vector2i:
	return Vector2i(size.x * Constants.CELL_SIZE, size.y * Constants.CELL_SIZE)


func is_within_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < size.x and position.y >= 0 and position.y < size.y


func normalize_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(clamp(cell.x, 0, size.x - 1), clamp(cell.y, 0, size.y - 1))


func to_screen(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * Constants.CELL_SIZE, cell.y * Constants.CELL_SIZE)


func to_cell(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x / Constants.CELL_SIZE), int(position.y / Constants.CELL_SIZE))


func collision_flag(cell: Vector2i) -> int:
	return collisions.get(cell, Constants.CELL_NONE)


func is_solid(cell: Vector2i) -> bool:
	return (collision_flag(cell) & Constants.CELL_FULL_BLOCK) != 0


func has_warp(cell: Vector2i) -> bool:
	return warps.has(cell)


func get_warp(cell: Vector2i) -> Dictionary:
	return warps.get(cell, {})


func can_pass(from: Vector2i, direction: Vector2i) -> bool:
	var to: Vector2i = from + direction

	if not is_within_bounds(from) or not is_within_bounds(to):
		return false

	var from_flag: int = collision_flag(from)
	var to_flag: int = collision_flag(to)

	if (from_flag & Constants.CELL_FULL_BLOCK) != 0:
		return false

	if (to_flag & Constants.CELL_FULL_BLOCK) != 0:
		return false

	var direction_flag: int = _direction_to_flag(direction)
	var opposite_flag: int = _direction_to_flag(-direction)

	if (from_flag & direction_flag) != 0:
		return false

	if (to_flag & opposite_flag) != 0:
		return false

	if abs(direction.x) == 1 and abs(direction.y) == 1:
		var horizontal_cell := Vector2i(from.x + direction.x, from.y)
		var vertical_cell := Vector2i(from.x, from.y + direction.y)

		if is_solid(horizontal_cell) or is_solid(vertical_cell):
			return false

	return true


func _direction_to_flag(direction: Vector2i) -> int:
	match direction:
		Vector2i.DOWN:
			return Constants.CELL_DOWN
		Vector2i.LEFT:
			return Constants.CELL_LEFT
		Vector2i.RIGHT:
			return Constants.CELL_RIGHT
		Vector2i.UP:
			return Constants.CELL_UP
		_:
			return Constants.CELL_NONE
